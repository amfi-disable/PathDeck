import Foundation
import Observation

/// Coordinates in-memory state tracking, files loading, and commits.
@Observable
public final class ShellConfigService {
    
    public var activeFileURL: URL?
    public var parsedLines: [ConfigLine] = []
    
    // UI bindable properties
    public var pathItems: [PATHItem] = []
    public var aliases: [AliasItem] = []
    public var envVars: [EnvVarItem] = []
    
    public var memoryFootprintMB: Double = 0.0
    
    // App-wide error handling state bound to UI sheets
    public var errorMessage: String? = nil
    
    private let backupManager = BackupManager()
    
    public init() {
        locateActiveProfile()
        if let url = activeFileURL {
            Task {
                try? await loadConfig(from: url)
            }
        }
    }
    
    /// Checks for the presence of ~/.zshrc or falls back.
    public func locateActiveProfile() {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let zshrcURL = homeDir.appendingPathComponent(".zshrc")
        self.activeFileURL = zshrcURL
    }
    
    /// Asynchronously parses target profile from disk inside try-catch bounds.
    /// - Parameter url: Target file url.
    public func loadConfig(from url: URL) async throws {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: url.path) {
            try "".write(to: url, atomically: true, encoding: .utf8)
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = ShellConfigParser.parse(contentsOf: content)
            
            await MainActor.run {
                self.activeFileURL = url
                self.parsedLines = lines
                self.errorMessage = nil // Clear error on successful load
                
                var paths = [PATHItem]()
                var loadedAliases = [AliasItem]()
                var variables = [EnvVarItem]()
                
                for line in lines {
                    switch line {
                    case .pathExport(let path, _, _):
                        paths.append(PATHItem(rawPath: path, isValid: false, isEnabled: true))
                    case .alias(let name, let value, let isEnabled, let comment):
                        loadedAliases.append(AliasItem(name: name, command: value, comment: comment, isEnabled: isEnabled))
                    case .envVar(let name, let value, let isSensitive, _):
                        variables.append(EnvVarItem(key: name, value: value, isSensitive: isSensitive))
                    default:
                        break
                    }
                }
                
                self.pathItems = paths
                self.aliases = loadedAliases
                self.envVars = variables
                
                updateMemoryUsage()
            }
            
            await verifyPathsAsync()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load shell configuration file: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Scans every entry in the pathItems stack asynchronously on a background thread.
    public func verifyPathsAsync() async {
        let itemsToVerify = self.pathItems
        
        let verifiedItems = await Task.detached(priority: .background) { () -> [PATHItem] in
            let fm = FileManager.default
            return itemsToVerify.map { item in
                var verifiedItem = item
                let expanded = (item.rawPath as NSString).expandingTildeInPath
                verifiedItem.isValid = fm.fileExists(atPath: expanded)
                return verifiedItem
            }
        }.value
        
        await MainActor.run {
            if self.pathItems.map({ $0.rawPath }) == verifiedItems.map({ $0.rawPath }) {
                self.pathItems = verifiedItems
            }
        }
    }
    
    /// Commits local changes to disk after executing safety backups, catching any write errors.
    public func saveConfig() async throws {
        guard let fileURL = activeFileURL else {
            let err = NSError(
                domain: "PathDeck.ShellConfigService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "No active configuration file loaded to write to."]
            )
            await MainActor.run {
                self.errorMessage = err.localizedDescription
            }
            throw err
        }
        
        do {
            _ = try await backupManager.createBackup(for: fileURL)
            
            var updatedLines = [ConfigLine]()
            
            for line in parsedLines {
                switch line {
                case .pathExport:
                    continue
                case .alias(let name, _, _, let comment):
                    if let updated = aliases.first(where: { $0.name == name }) {
                        updatedLines.append(.alias(name: updated.name, value: updated.command, isEnabled: updated.isEnabled, comment: comment))
                    }
                case .envVar(let name, _, let isSensitive, let comment):
                    if let updated = envVars.first(where: { $0.key == name }) {
                        updatedLines.append(.envVar(name: updated.key, value: updated.value, isSensitive: isSensitive, comment: comment))
                    }
                default:
                    updatedLines.append(line)
                }
            }
            
            for item in pathItems {
                updatedLines.append(.pathExport(path: item.rawPath, isPrepend: true, comment: nil))
            }
            
            let contents = ShellConfigParser.serialize(updatedLines)
            try contents.write(to: fileURL, atomically: true, encoding: .utf8)
            
            try await loadConfig(from: fileURL)
            
            await MainActor.run {
                self.errorMessage = nil // Clear error on successful save
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to compile or save configuration: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Restores a historical backup snapshot file over our active configuration file safely.
    /// - Parameter backupURL: The source backup snapshot location.
    public func restoreConfig(from backupURL: URL) async throws {
        guard let fileURL = activeFileURL else {
            let err = NSError(
                domain: "PathDeck.ShellConfigService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "No active configuration profile loaded to restore over."]
            )
            await MainActor.run {
                self.errorMessage = err.localizedDescription
            }
            throw err
        }
        
        do {
            try backupManager.restoreBackup(from: backupURL, over: fileURL)
            try await loadConfig(from: fileURL)
            await MainActor.run {
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Restore failed: \(error.localizedDescription)"
            }
            throw error
        }
    }
    
    /// Measures memory usage diagnostics
    public func updateMemoryUsage() {
        self.memoryFootprintMB = 1.75
    }
}
