import SwiftUI

/// Renders the path priority list with native drag-and-drop reordering, disk presence validation, and persistence bindings.
public struct PathStackView: View {
    @Environment(ShellConfigService.self) private var service
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    
    public init() {}
    
    public var body: some View {
        @Bindable var service = service
        
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PATH Stack Studio")
                        .font(.title)
                        .bold()
                    Text("Drag directories to adjust priorities. Toggle directories to control search path discovery.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: savePaths) {
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
            }
            
            // List with drag reordering
            List {
                ForEach($service.pathItems) { $item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 12) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .padding(.trailing, 4)
                            
                            // Visual status bubble
                            Image(systemName: item.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(item.isValid ? .green : .orange)
                                .font(.system(size: 16))
                            
                            Text(item.rawPath)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(item.isEnabled ? .primary : .secondary)
                                .strikethrough(!item.isEnabled, color: .secondary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $item.isEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        
                        // Warning card layout if path is invalid/broken
                        if !item.isValid {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                Text("Directory warning: The path '\(item.rawPath)' does not exist on this machine. Shell lookups in this folder will fail.")
                                    .font(.caption2)
                            }
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(4)
                            .foregroundColor(.orange)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.vertical, 6)
                }
                .onMove { indices, newOffset in
                    service.pathItems.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
            .listStyle(.inset)
            
            // Status bar
            HStack {
                Text("\(service.pathItems.count) total stack items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Changes are committed directly to ~/.zshrc")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
        }
    }
    
    private func savePaths() {
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
