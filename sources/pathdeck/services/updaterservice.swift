import Foundation
import Observation

/// Handles checking GitHub Releases API for new updates.
@Observable
public final class UpdaterService {
    
    public var isUpdateAvailable: Bool = false
    public var latestVersion: String? = nil
    public var isChecking: Bool = false
    public var errorMessage: String? = nil
    
    // Default current version
    public let currentVersion = "V1.0.0"
    
    public init() {}
    
    /// Queries GitHub Releases API asynchronously to check for newer version tags.
    public func checkForUpdates() async {
        guard !isChecking else { return }
        
        await MainActor.run {
            self.isChecking = true
            self.errorMessage = nil
        }
        
        let urlString = "https://api.github.com/repos/amfi-disable/PathDeck/releases/latest"
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.isChecking = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("PathDeck-App-Updater", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                await MainActor.run {
                    self.isChecking = false
                }
                return
            }
            
            struct ReleaseResponse: Decodable {
                let tag_name: String
            }
            
            let release = try JSONDecoder().decode(ReleaseResponse.self, from: data)
            let latestTag = release.tag_name.trimmingCharacters(in: .whitespacesAndNewlines)
            
            await MainActor.run {
                self.isChecking = false
                self.latestVersion = latestTag
                
                // Compare tags case-insensitively
                if latestTag.lowercased() != currentVersion.lowercased() {
                    self.isUpdateAvailable = true
                } else {
                    self.isUpdateAvailable = false
                }
            }
        } catch {
            await MainActor.run {
                self.isChecking = false
                self.errorMessage = "Check failed: \(error.localizedDescription)"
            }
        }
    }
}
