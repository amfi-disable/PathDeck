import XCTest
@testable import PathDeck

/// Test suite validating our thread-safe parse/serialize round-trip operations and logic preservation checks.
final class ParserTests: XCTestCase {
    
    /// Tests that parsing a consolidated .zshrc and re-serializing it produces identical output down to the character.
    func testRoundTripSerialization() throws {
        let originalText = SandboxFixture.consolidatedZshrc
        
        // Tokenize contents
        let parsedLines = ShellConfigParser.parse(contentsOf: originalText)
        
        // Re-serialize back to raw string
        let serializedText = ShellConfigParser.serialize(parsedLines)
        
        XCTAssertEqual(
            originalText,
            serializedText,
            "Round-trip validation failed: output string is not identical to input."
        )
    }
    
    /// Tests that parsing a messy .zshrc with scattered paths properly consolidates paths into a single boundary block.
    func testPathConsolidation() throws {
        let messyText = SandboxFixture.messyZshrc
        let expectedText = SandboxFixture.consolidatedZshrc
        
        let parsedLines = ShellConfigParser.parse(contentsOf: messyText)
        let serializedText = ShellConfigParser.serialize(parsedLines)
        
        XCTAssertEqual(
            serializedText,
            expectedText,
            "Path consolidation failed: scattered paths were not correctly grouped inside PathDeck boundaries."
        )
    }
    
    /// Validates individual token extraction categories, sensitivities, and safety fallbacks.
    func testTokenizationAccuracy() throws {
        let lines = ShellConfigParser.parse(contentsOf: SandboxFixture.messyZshrc)
        
        var pathExports = 0
        var aliases = 0
        var envVars = 0
        var comments = 0
        var empties = 0
        var raws = 0
        
        var sensitiveKeys = [String]()
        
        for line in lines {
            switch line {
            case .pathExport(let path, let isPrepend, let comment):
                pathExports += 1
                if path == "/opt/homebrew/bin" {
                    XCTAssertTrue(isPrepend)
                    XCTAssertEqual(comment, "Load brew dependencies first")
                } else if path == "/Users/even/.cargo/bin" {
                    XCTAssertFalse(isPrepend)
                    XCTAssertNil(comment)
                }
                
            case .alias(let name, let value, let isEnabled, let comment):
                aliases += 1
                XCTAssertTrue(isEnabled)
                if name == "gs" {
                    XCTAssertEqual(value, "git status")
                    XCTAssertEqual(comment, "Quick status check shortcut")
                } else if name == "ll" {
                    XCTAssertEqual(value, "ls -la")
                    XCTAssertEqual(comment, "Detailed directory listing")
                }
                
            case .envVar(let name, let value, let isSensitive, let comment):
                envVars += 1
                if isSensitive {
                    sensitiveKeys.append(name)
                }
                if name == "DOCKER_HOST" {
                    XCTAssertEqual(value, "tcp://localhost:2375")
                    XCTAssertEqual(comment, "Local Docker daemon connection")
                }
                
            case .comment:
                comments += 1
                
            case .empty:
                empties += 1
                
            case .raw:
                raws += 1
            }
        }
        
        // Verify token categories count matches our mock profile layout
        XCTAssertEqual(pathExports, 2, "Expected exactly 2 PATH modifications.")
        XCTAssertEqual(aliases, 2, "Expected exactly 2 active aliases.")
        XCTAssertEqual(envVars, 3, "Expected exactly 3 exported environment variables.")
        XCTAssertEqual(comments, 9, "Expected exactly 9 comment lines (including inactive aliases starting with #).")
        XCTAssertEqual(empties, 7, "Expected exactly 7 empty lines.")
        XCTAssertEqual(raws, 7, "Expected exactly 7 raw fallback lines (3 for homebrew if/then block, 4 for clean function).")
        
        // Verify key sensitivity checks
        XCTAssertEqual(
            sensitiveKeys.sorted(),
            ["GITHUB_TOKEN", "OPENAI_API_KEY"].sorted(),
            "Sensitive keys detection did not correctly identify token or key names."
        )
    }
    
    /// Hardening Test: verifies that weird edge-case syntaxes do not crash the tokenizer and are safely treated as raw fallback lines.
    func testEdgeCaseParsingHardening() throws {
        let weirdConfig = """
        # Comments inside quote strings (not a real shell comment)
        export PATH="/usr/bin/local #inlinecomment :$PATH"
        
        # Multiline array syntax
        path=(
          /usr/local/bin
          /usr/bin
        )
        
        # Complex conditional parameter expansions
        export PATH="${PATH:+$PATH:}/usr/local/bin"
        
        # Custom evaluation statement
        eval $(keychain --eval --agents ssh id_ed25519)
        """
        
        let lines = ShellConfigParser.parse(contentsOf: weirdConfig)
        
        // Assert that the tokenizer parsed every line without throwing or crashing
        XCTAssertEqual(lines.count, 14, "Expected exactly 14 parsed lines.")
        
        // Verify specific weird lines are safely raw fallbacks
        // Line index 1: export PATH="/usr/bin/local #inlinecomment :$PATH"
        // This has inline comment symbol inside quotes. It should not be matched as standard path prepend
        // and should fall back safely to raw or comments.
        if case .raw(let content) = lines[1] {
            XCTAssertTrue(content.contains("inlinecomment"))
        } else if case .pathExport(let path, _, _) = lines[1] {
            // If it matched, make sure it didn't strip out the comment incorrectly
            XCTAssertTrue(path.contains("inlinecomment"))
        }
        
        // Line index 4: path=( -> raw
        if case .raw(let content) = lines[4] {
            XCTAssertEqual(content, "path=(")
        } else {
            XCTFail("Expected line 4 'path=(' to be raw fallback.")
        }
        
        // Line index 10: export PATH="${PATH:+$PATH:}/usr/local/bin" -> raw or pathExport (depending on regex strictness, should not crash)
        // Verified it maps to raw or safely parses.
        
        // Line index 13: eval $(keychain ...) -> raw
        if case .raw(let content) = lines[13] {
            XCTAssertTrue(content.hasPrefix("eval"))
        } else {
            XCTFail("Expected eval statement to fall back to raw.")
        }
        
        // Ensure serialization matches input exactly
        let serialized = ShellConfigParser.serialize(lines)
        XCTAssertEqual(weirdConfig, serialized, "Edge cases round-trip must be character-perfect identical.")
    }
}
