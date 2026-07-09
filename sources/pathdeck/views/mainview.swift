import SwiftUI

/// Navigation items representing sidebar destinations.
public enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case pathStack = "PATH Stack"
    case aliasStudio = "Alias Studio"
    case envVariables = "Environment Variables"
    case backups = "Backups"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .pathStack: return "arrow.up.and.down.square"
        case .aliasStudio: return "terminal"
        case .envVariables: return "lock.shield"
        case .backups: return "clock.arrow.circlepath"
        }
    }
}

/// Core interface split-navigation layout featuring premium macOS visual styling and placeholders for Phase 2 detail views.
public struct MainView: View {
    @Environment(ShellConfigService.self) private var service
    @State private var selection: NavigationItem? = .dashboard
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var saveError: String? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(service: service, selection: $selection)
                .frame(minWidth: 220, idealWidth: 260)
                .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        } detail: {
            Group {
                switch selection {
                case .dashboard, .none:
                    DashboardView()
                case .pathStack:
                    PathStackView()
                case .aliasStudio:
                    AliasStudioView()
                case .envVariables:
                    EnvVarView()
                case .backups:
                    BackupView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow))
        }
        .frame(minWidth: 800, minHeight: 500)
        .alert("Configuration Error", isPresented: Binding(
            get: { service.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    service.errorMessage = nil
                }
            }
        )) {
            Button("Dismiss", role: .cancel) {}
        } message: {
            if let errorMsg = service.errorMessage {
                Text(errorMsg)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                HStack(spacing: 8) {
                    Image(systemName: "terminal.fill")
                        .foregroundColor(.secondary)
                    Text(displayPath)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    // Revert / Discard Changes Button
                    Button(action: revertChanges) {
                        Label("Revert", systemImage: "arrow.counterclockwise.circle")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSaving)
                    .help("Discard unsaved UI changes and reload last state from disk")
                    
                    // Save Changes Button
                    Button(action: saveChanges) {
                        if isSaving {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Saving...")
                            }
                        } else if saveSuccess {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Saved")
                                    .foregroundColor(.green)
                            }
                        } else {
                            Label("Save Changes", systemImage: "square.and.arrow.down")
                        }
                    }
                    .disabled(isSaving)
                    .help("Save all workspace configurations to disk")
                }
            }
        }
    }
    
    private var displayPath: String {
        guard let url = service.activeFileURL else { return "~/.zshrc" }
        let path = url.path
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return path.replacingOccurrences(of: home, with: "~")
        }
        return path
    }
    
    private func saveChanges() {
        isSaving = true
        saveSuccess = false
        saveError = nil
        
        Task {
            do {
                try await service.saveConfig()
                isSaving = false
                saveSuccess = true
                // Reset success indicator after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                saveSuccess = false
            } catch {
                isSaving = false
                saveError = error.localizedDescription
            }
        }
    }
    
    private func revertChanges() {
        guard let url = service.activeFileURL else { return }
        Task {
            do {
                try await service.loadConfig(from: url)
            } catch {
                saveError = error.localizedDescription
            }
        }
    }
}




/// Generic helper to draw premium HIG-compliant placeholder view contents.
struct PlaceholderDetailView: View {
    let title: String
    let description: String
    let iconName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title)
                .bold()
                .foregroundColor(.primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
        }
        .padding()
    }
}
