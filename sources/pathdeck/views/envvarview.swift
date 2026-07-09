import SwiftUI

/// Ledger list displaying environment variables, enabling secrets masking, and featuring Touch ID secure unlock.
public struct EnvVarView: View {
    @Environment(ShellConfigService.self) private var service
    
    // Header inputs for adding variables
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var newIsSensitive = false
    
    // UI state parameters
    @State private var searchText = ""
    @State private var unlockedIds: Set<UUID> = []
    
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    
    public init() {}
    
    private var filteredVariables: Binding<[EnvVarItem]> {
        Binding(
            get: {
                if searchText.isEmpty {
                    return service.envVars
                } else {
                    let query = searchText.lowercased()
                    return service.envVars.filter {
                        $0.key.lowercased().contains(query) ||
                        $0.value.lowercased().contains(query)
                    }
                }
            },
            set: { newValue in
                for item in newValue {
                    if let index = service.envVars.firstIndex(where: { $0.id == item.id }) {
                        service.envVars[index] = item
                    }
                }
            }
        )
    }
    
    public var body: some View {
        @Bindable var service = service
        
        VStack(alignment: .leading, spacing: 0) {
            // Title Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Environment Variables")
                        .font(.title)
                        .bold()
                    Text("Manage system configurations. Secure tokens, keys, and credentials behind biometrics.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: saveVariables) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Save Changes", systemImage: "arrow.down.doc.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
            .padding()
            
            Divider()
            
            // Add Variable Panel
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Environment Variable")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    TextField("Name (e.g. API_KEY)", text: $newKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                    
                    TextField("Value", text: $newValue)
                        .textFieldStyle(.roundedBorder)
                    
                    Toggle(isOn: $newIsSensitive) {
                        Label("Sensitive", systemImage: "lock.shield")
                    }
                    .toggleStyle(.checkbox)
                    
                    Button(action: addNewVariable) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .disabled(newKey.isEmpty || newValue.isEmpty)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            
            Divider()
            
            // Error panel if any
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundColor(.red)
                    Spacer()
                    Button(action: { self.errorMessage = nil }) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                Divider()
            }
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search variables by name...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(6)
            .padding([.horizontal, .top])
            
            // Variables List
            List {
                ForEach(filteredVariables) { $item in
                    HStack(spacing: 16) {
                        if item.isSensitive {
                            Image(systemName: unlockedIds.contains(item.id) ? "lock.open.fill" : "lock.fill")
                                .foregroundColor(unlockedIds.contains(item.id) ? .green : .orange)
                                .font(.system(size: 14))
                                .frame(width: 16)
                                .onTapGesture {
                                    didTapSecureField(for: item)
                                }
                        } else {
                            Image(systemName: "capsule")
                                .foregroundColor(.secondary)
                                .font(.system(size: 10))
                                .frame(width: 16)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.key)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            if item.isSensitive && !unlockedIds.contains(item.id) {
                                Text("••••••••")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        didTapSecureField(for: item)
                                    }
                            } else {
                                Text(item.value)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                        
                        // Masking toggle
                        Toggle("", isOn: $item.isSensitive)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    .padding(.vertical, 6)
                    .onDisappear {
                        // Re-lock the secret variable row securely when it leaves the screen
                        unlockedIds.remove(item.id)
                    }
                }
                .onDelete(perform: deleteVariable)
            }
            .listStyle(.inset)
            
            // Footer Info
            HStack {
                Text("\(service.envVars.count) variables loaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Lock icons denote biometric protection variables")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
        }
    }
    
    private func addNewVariable() {
        let key = newKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let val = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !key.isEmpty, !val.isEmpty else { return }
        
        let newItem = EnvVarItem(
            key: key,
            value: val,
            isSensitive: newIsSensitive
        )
        
        service.envVars.append(newItem)
        
        // Reset fields
        newKey = ""
        newValue = ""
        newIsSensitive = false
    }
    
    private func deleteVariable(at offsets: IndexSet) {
        service.envVars.remove(atOffsets: offsets)
    }
    
    /// Biometric credential unlock action hook calling local authentication asynchronously.
    private func didTapSecureField(for item: EnvVarItem) {
        if unlockedIds.contains(item.id) {
            // Lock again instantly
            unlockedIds.remove(item.id)
        } else {
            // Asynchronously request Touch ID authentication
            Task {
                let reason = "Verify identity to reveal sensitive variable '\(item.key)'"
                let success = await TouchIDService.shared.authenticateUser(reason: reason)
                if success {
                    _ = await MainActor.run {
                        unlockedIds.insert(item.id)
                    }
                }
            }
        }
    }
    
    private func saveVariables() {
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                try await service.saveConfig()
                isSaving = false
            } catch {
                errorMessage = "Failed to commit changes: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}
