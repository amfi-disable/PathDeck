import SwiftUI

/// HelpView displays the interactive user manual for PathDeck.
public struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)
                Text("PathDeck User Manual")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(VisualEffectView(material: .headerView, blendingMode: .behindWindow))
            
            Divider()
            
            // Scrollable manual contents
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Welcome
                    HelpSection(
                        title: "1. Welcome to PathDeck",
                        icon: "hand.wave.fill",
                        color: .green,
                        content: "PathDeck is a native macOS developer studio designed to visually manage, prioritize, and back up shell profiles (~/.zshrc and ~/.bash_profile). It replaces manual terminal text editing with a responsive, biometrically secured SwiftUI interface."
                    )
                    
                    // PATH Stack
                    HelpSection(
                        title: "2. Managing the PATH Stack",
                        icon: "arrow.up.and.down.square.fill",
                        color: .blue,
                        content: "• Drag & Drop: Drag rows to change search precedence. Top directories are searched first by your shell.\n• Active Verification: Directories are checked asynchronously in the background. Offline paths show orange warnings.\n• Disable Toggles: Temporarily exclude paths from export statements without deleting them."
                    )
                    
                    // Alias Studio
                    HelpSection(
                        title: "3. Alias Studio shortcuts",
                        icon: "terminal.fill",
                        color: .purple,
                        content: "• Register Shortcuts: Add new shell command triggers in the header inputs instantly.\n• Safe comment-outs: Toggling off an alias comments it out in your profile file rather than deleting it, allowing you to reactivate it later with no loss of data."
                    )
                    
                    // Secrets Lock
                    HelpSection(
                        title: "4. Sensitive Variables (Touch ID)",
                        icon: "lock.shield.fill",
                        color: .orange,
                        content: "• Visibility Masking: Sensitive keys (API keys, secrets) are masked as bullets (••••••••).\n• Biometrics prompt: Click the padlock icon to trigger Apple's Touch ID authentication sheet (or system passcode fallback) to reveal values.\n• Auto-relocking: Visible secrets automatically lock back when they disappear from the screen viewport."
                    )
                    
                    // Rollbacks
                    HelpSection(
                        title: "5. Automated Backups & Restores",
                        icon: "clock.arrow.circlepath",
                        color: .cyan,
                        content: "• Pre-save backups: PathDeck automatically duplicates your active file to Library Application Support folders before committing edits.\n• 1-Click Restore: Open the Backups tab, review timestamped restore points, and confirm to roll back configurations."
                    )
                }
                .padding(24)
            }
            .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
        }
        .frame(minWidth: 500, minHeight: 450)
    }
}

/// Helper subview for displaying help sections.
struct HelpSection: View {
    let title: String
    let icon: String
    let color: Color
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
        }
    }
}
