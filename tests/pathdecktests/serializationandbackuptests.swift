import XCTest
@testable import PathDeck

/// Test suite validating path block consolidation, writer serialization, and automated backup operations.
final class SerializationAndBackupTests: XCTestCase {
    
    /// Tests that the serialization engine groups loose path configurations into the PathDeck block at the first path's index.
    func testSerializationConsolidatesPaths() throws {
        let originalText = """
# Start Profile
export PATH="/usr/local/bin:$PATH" # Local binaries
alias gs="git status"
export PATH="$PATH:/Users/even/.cargo/bin"
export DOCKER_HOST="tcp://localhost:2375"
"""
        
        let parsed = ShellConfigParser.parse(contentsOf: originalText)
        let serialized = ShellConfigParser.serialize(parsed)
        
        // Verify boundaries
        XCTAssertTrue(serialized.contains("# >>> PathDeck PATH Section >>>"))
        XCTAssertTrue(serialized.contains("# <<< PathDeck PATH Section <<<"))
        
        let lines = serialized.components(separatedBy: .newlines)
        
        // Verify inline replacement at the first path export position (index 1)
        XCTAssertEqual(lines[0], "# Start Profile")
        XCTAssertEqual(lines[1], "# >>> PathDeck PATH Section >>>")
        XCTAssertEqual(lines[2], "export PATH=\"/usr/local/bin:$PATH\" # Local binaries")
        XCTAssertEqual(lines[3], "export PATH=\"$PATH:/Users/even/.cargo/bin\"")
        XCTAssertEqual(lines[4], "# <<< PathDeck PATH Section <<<")
        XCTAssertEqual(lines[5], "alias gs=\"git status\"")
        XCTAssertEqual(lines[6], "export DOCKER_HOST=\"tcp://localhost:2375\"")
    }
    
    /// Tests that the BackupManager generates a duplicated file in a isolated mock backups directory.
    func testBackupManagerCopiesFileInTempDir() async throws {
        let fileManager = FileManager.default
        let suiteTempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let backupsDir = suiteTempDir.appendingPathComponent("backups", isDirectory: true)
        
        defer {
            try? fileManager.removeItem(at: suiteTempDir)
        }
        
        // Setup mock environment
        let targetFile = suiteTempDir.appendingPathComponent(".zshrc")
        try fileManager.createDirectory(at: suiteTempDir, withIntermediateDirectories: true)
        let fileContent = "export API_KEY=\"xyz\"\n"
        try fileContent.write(to: targetFile, atomically: true, encoding: .utf8)
        
        // Trigger backup
        let manager = BackupManager(backupsDirectory: backupsDir)
        let backupURL = try await manager.createBackup(for: targetFile)
        
        // Validate existence and name structure
        XCTAssertTrue(fileManager.fileExists(atPath: backupURL.path))
        XCTAssertTrue(backupURL.lastPathComponent.hasPrefix(".zshrc_backup_"))
        
        let backupContent = try String(contentsOf: backupURL, encoding: .utf8)
        XCTAssertEqual(backupContent, fileContent)
    }
    
    /// Tests that the BackupManager returns appropriate error code wrapper when restricted path is accessed.
    func testBackupManagerPermissionFallback() async {
        let fileManager = FileManager.default
        let manager = BackupManager()
        
        let invalidPath = fileManager.temporaryDirectory.appendingPathComponent("ghost_zshrc_file")
        
        do {
            _ = try await manager.createBackup(for: invalidPath)
            XCTFail("Backup creation must throw an error for non-existent targets.")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "PathDeck.BackupManager")
            XCTAssertEqual(nsError.code, 404)
            XCTAssertTrue(nsError.localizedDescription.contains("Restricted permissions"))
        }
    }
    
    /// Tests that the BackupManager correctly restores a source backup snapshot over an active configuration target.
    func testBackupManagerRestore() throws {
        let fileManager = FileManager.default
        let suiteTempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        defer {
            try? fileManager.removeItem(at: suiteTempDir)
        }
        
        let targetFile = suiteTempDir.appendingPathComponent(".zshrc")
        let backupFile = suiteTempDir.appendingPathComponent(".zshrc_backup")
        
        try fileManager.createDirectory(at: suiteTempDir, withIntermediateDirectories: true)
        
        // Initial setup
        try "original content".write(to: targetFile, atomically: true, encoding: .utf8)
        try "backup content".write(to: backupFile, atomically: true, encoding: .utf8)
        
        let manager = BackupManager(backupsDirectory: suiteTempDir)
        try manager.restoreBackup(from: backupFile, over: targetFile)
        
        let restoredContent = try String(contentsOf: targetFile, encoding: .utf8)
        XCTAssertEqual(restoredContent, "backup content")
    }
}
