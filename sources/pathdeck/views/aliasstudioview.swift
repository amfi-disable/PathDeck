import SwiftUI

/// A searchable shortcut command studio enabling alias addition, status toggling, and comment editing.
public struct AliasStudioView: View {
    @Environment(ShellConfigService.self) private var service
    
    // Header inputs
    @State private var newName = ""
    @State private var newCommand = ""
    @State private var newComment = ""
    
    // Search query
    @State private var searchText = ""
    
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    
    public init() {}
    
    private var filteredAliases: Binding<[AliasItem]> {
        Binding(
            get: {
                if searchText.isEmpty {
                    return service.aliases
                } else {
                    let query = searchText.lowercased()
                    return service.aliases.filter {
                        $0.name.lowercased().contains(query) ||
                        $0.command.lowercased().contains(query) ||
                        ($0.comment?.lowercased().contains(query) ?? false)
                    }
                }
            },
            set: { newValue in
                // Sync back mutations to the source array matching by id
                for item in newValue {
                    if let index = service.aliases.firstIndex(where: { $0.id == item.id }) {
                        service.aliases[index] = item
                    }
                }
            }
        )
    }
    
    public var body: some View {
        @Bindable var service = service
        
        VStack(alignment: .leading, spacing: 0) {
            // Header panel
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alias Studio")
                        .font(.title)
                        .bold()
                    Text("Toggle shortcuts to comment them out without deleting. Add new commands instantly.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: saveAliases) {
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
            
            // Add New Alias Panel
            VStack(alignment: .leading, spacing: 8) {
                Text("Add New Shortcut")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    TextField("Name (e.g. gs)", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                    
                    TextField("Target Command (e.g. git status)", text: $newCommand)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Comment (optional)", text: $newComment)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                    
                    Button(action: addNewAlias) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .disabled(newName.isEmpty || newCommand.isEmpty)
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
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search aliases by name or command...", text: $searchText)
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
            
            // Aliases list
            List {
                ForEach(filteredAliases) { $item in
                    HStack(spacing: 16) {
                        // Status light
                        Circle()
                            .fill(item.isEnabled ? Color.blue : Color.gray)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(item.name)
                                    .font(.headline)
                                    .foregroundColor(item.isEnabled ? .primary : .secondary)
                                
                                Text("→")
                                    .foregroundColor(.secondary)
                                
                                Text(item.command)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(item.isEnabled ? .primary : .secondary)
                            }
                            
                            if let comment = item.comment, !comment.isEmpty {
                                Text("# \(comment)")
                                    .font(.caption)
                                    .italic()
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $item.isEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteAlias)
            }
            .listStyle(.inset)
            
            // Footer Info
            HStack {
                Text("\(service.aliases.count) aliases loaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Swipe or delete rows to remove")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
        }
    }
    
    private func addNewAlias() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cmd = newCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        let comment = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !name.isEmpty, !cmd.isEmpty else { return }
        
        let newItem = AliasItem(
            name: name,
            command: cmd,
            comment: comment.isEmpty ? nil : comment,
            isEnabled: true
        )
        
        service.aliases.append(newItem)
        
        // Reset inputs
        newName = ""
        newCommand = ""
        newComment = ""
    }
    
    private func deleteAlias(at offsets: IndexSet) {
        service.aliases.remove(atOffsets: offsets)
    }
    
    private func saveAliases() {
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
