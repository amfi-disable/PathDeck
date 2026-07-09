import SwiftUI

/// Sidebar select routes mapping sidebar selections to their respective workspaces.
public struct SidebarView: View {
    @Bindable var service: ShellConfigService
    @Binding public var selection: NavigationItem?
    
    public init(service: ShellConfigService, selection: Binding<NavigationItem?>) {
        self.service = service
        self._selection = selection
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                Section("Developer Studio") {
                    ForEach(NavigationItem.allCases) { item in
                        NavigationLink(value: item) {
                            HStack(spacing: 12) {
                                Image(systemName: item.iconName)
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.rawValue)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(subtitle(for: item))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            
            Divider()
            
            // Standard Semantic Versioning UI reference display label
            HStack {
                Spacer()
                Text("V1.0.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                Spacer()
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
        }
    }
    
    private func subtitle(for item: NavigationItem) -> String {
        switch item {
        case .dashboard:
            return "System Health & Specs"
        case .pathStack:
            let count = service.pathItems.count
            return "\(count) Active " + (count == 1 ? "Path" : "Paths")
        case .aliasStudio:
            let count = service.aliases.count
            return "\(count) Custom " + (count == 1 ? "Alias" : "Aliases")
        case .envVariables:
            let count = service.envVars.count
            return "\(count) System " + (count == 1 ? "Variable" : "Variables")
        case .backups:
            return "Safety Restore Points"
        }
    }
}
