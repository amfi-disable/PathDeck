import SwiftUI

/// DashboardView displays real-time health diagnostics, PATH folder verification checklist, and system load stats.
public struct DashboardView: View {
    @Environment(ShellConfigService.self) private var service
    @State private var updater = UpdaterService()
    
    public init() {}
    
    private var brokenPathsCount: Int {
        service.pathItems.filter { !$0.isValid }.count
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Developer Dashboard")
                        .font(.title)
                        .bold()
                    Text("Real-time profile statistics and environment stack health verification diagnostics.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Update Available Banner (Checks GitHub Releases API dynamically)
                if updater.isUpdateAvailable, let latest = updater.latestVersion {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("New Update Available: \(latest)")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Text("A newer version of PathDeck is available on GitHub. You can download the latest package to update your app.")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                if let url = URL(string: "https://github.com/amfi-disable/PathDeck/releases/latest") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Label("Download \(latest) Release", systemImage: "arrow.down.doc.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Alert Banner if there are broken paths
                if brokenPathsCount > 0 {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PATH Stack Alerts Detected")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Text("Found \(brokenPathsCount) broken or dead directories in your PATH stack. Terminals spend extra time searching non-existent directories, causing minor latency during tab expansions.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PATH Stack Healthy")
                                .font(.headline)
                                .foregroundColor(.green)
                            Text("All directory entries exist on disk and resolve correctly. Shell launches are fully optimized.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Statistics Cards Grid (3 Columns)
                Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                    GridRow {
                        StatCard(
                            title: "PATH Stack",
                            value: "\(service.pathItems.count)",
                            subtitle: "Directories Configured",
                            iconName: "arrow.up.and.down.square",
                            accentColor: .blue
                        )
                        
                        StatCard(
                            title: "Alias Studio",
                            value: "\(service.aliases.filter { $0.isEnabled }.count)",
                            subtitle: "Active Shortcuts",
                            iconName: "terminal",
                            accentColor: .purple
                        )
                        
                        StatCard(
                            title: "Secure Env",
                            value: "\(service.envVars.filter { $0.isSensitive }.count)",
                            subtitle: "Sensitive Variables",
                            iconName: "lock.shield",
                            accentColor: .orange
                        )
                    }
                }
                
                // PATH Folder Verification Checklist
                VStack(alignment: .leading, spacing: 12) {
                    Text("Directory Path Checklist")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 0) {
                        if service.pathItems.isEmpty {
                            Text("No directories configured in PATH stack.")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(service.pathItems) { item in
                                HStack {
                                    Text(item.rawPath)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(item.isEnabled ? .primary : .secondary)
                                    
                                    Spacer()
                                    
                                    // Status tag badge
                                    HStack(spacing: 4) {
                                        Image(systemName: item.isValid ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                            .font(.caption)
                                        Text(item.isValid ? "Resolves" : "Offline")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .foregroundColor(item.isValid ? .green : .red)
                                    .background(item.isValid ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                    .cornerRadius(12)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                                
                                if item.id != service.pathItems.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .onAppear {
            Task {
                await updater.checkForUpdates()
            }
        }
    }
}

/// A premium visual card presenting a single diagnostic statistic.
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let iconName: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(accentColor)
            }
            
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}
