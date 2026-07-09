import SwiftUI

/// BackupView displays a chronological list of historical profile backups, letting users restore profiles securely.
public struct BackupView: View {
    @Environment(ShellConfigService.self) private var service
    @State private var backups: [BackupMetadata] = []
    
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    
    // Safety confirmation dialog state
    @State private var selectedBackup: BackupMetadata? = nil
    @State private var showingRestoreConfirmation = false
    
    private let backupManager = BackupManager()
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header panel
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Safety Restores & Backups")
                        .font(.title)
                        .bold()
                    Text("Review automatically generated backups. Restore configurations safely via confirmation checks.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: refreshBackups) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Success & Error banners
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
            
            if let successMessage = successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(successMessage)
                        .font(.callout)
                        .foregroundColor(.green)
                    Spacer()
                    Button(action: { self.successMessage = nil }) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                Divider()
            }
            
            // Backups List
            if backups.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("No Restore Points Found")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text("Every time you save modifications to ~/.zshrc or environment variables, a safe timestamped copy will automatically appear here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(backups) { backup in
                        HStack(spacing: 16) {
                            Image(systemName: "doc.text.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(backup.filename)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                
                                HStack(spacing: 12) {
                                    Text(formatDate(backup.timestamp))
                                    Text("•")
                                    Text(formatFileSize(backup.fileSize))
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedBackup = backup
                                showingRestoreConfirmation = true
                            }) {
                                Label("Restore", systemImage: "arrow.counterclockwise")
                            }
                            .buttonStyle(.bordered)
                            .help("Restore configuration to this exact snapshot state")
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.inset)
            }
            
            // Footer status bar
            HStack {
                Text("\(backups.count) total backups logged")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Backups are safely indexed inside Library Application Support")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
        }
        .onAppear {
            refreshBackups()
        }
        .confirmationDialog(
            "Restore Configuration?",
            isPresented: $showingRestoreConfirmation,
            presenting: selectedBackup
        ) { backup in
            Button("Restore Configuration", role: .destructive) {
                performRestore(backup)
            }
            Button("Cancel", role: .cancel) {}
        } message: { backup in
            Text("This will replace your current configuration profile (~/.zshrc) with the snapshot \(backup.filename). This action will reload active layouts.")
        }
    }
    
    private func refreshBackups() {
        do {
            self.backups = try backupManager.listBackups()
        } catch {
            errorMessage = "Failed to list backups: \(error.localizedDescription)"
        }
    }
    
    private func performRestore(_ backup: BackupMetadata) {
        Task {
            do {
                try await service.restoreConfig(from: backup.url)
                await MainActor.run {
                    successMessage = "Successfully restored configuration to \(backup.filename) snapshot!"
                    errorMessage = nil
                    refreshBackups()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Restore failed: \(error.localizedDescription)"
                    successMessage = nil
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
