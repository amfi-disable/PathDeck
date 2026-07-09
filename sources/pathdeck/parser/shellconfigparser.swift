import Foundation

/// A thread-safe, line-preserving tokenizer engine for parsing and serializing shell configuration files.
public final class ShellConfigParser {
    
    // Thread safety lock
    private static let lock = NSLock()
    
    // Regular Expressions with capture groups for optional inline trailing comments
    private static let pathPrependRegex = try! NSRegularExpression(
        pattern: #"^\s*export\s+PATH=(["']?)([^"':#]*?):\$PATH\1\s*(?:#\s*(.*))?$"#,
        options: []
    )
    
    private static let pathAppendRegex = try! NSRegularExpression(
        pattern: #"^\s*export\s+PATH=(["']?)\$PATH:([^"':#]*?)\1\s*(?:#\s*(.*))?$"#,
        options: []
    )
    
    private static let aliasRegex = try! NSRegularExpression(
        pattern: #"^\s*alias\s+([a-zA-Z0-9_\.\-]+)\s*=\s*(["'])(.*?)\2\s*(?:#\s*(.*))?$"#,
        options: []
    )
    
    private static let envVarRegex = try! NSRegularExpression(
        pattern: #"^\s*export\s+([a-zA-Z0-9_]+)\s*=\s*(["'])(.*?)\2\s*(?:#\s*(.*))?$"#,
        options: []
    )
    
    /// Parses a shell configuration string line-by-line into structured AST `ConfigLine` elements.
    /// - Parameter string: The raw configuration file contents.
    /// - Returns: An array of tokenized `ConfigLine` structures.
    public static func parse(contentsOf string: String) -> [ConfigLine] {
        lock.lock()
        defer { lock.unlock() }
        
        let rawLines = string.components(separatedBy: .newlines)
        var parsedLines = [ConfigLine]()
        
        for line in rawLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // 1. Match Empty Line
            if trimmed.isEmpty {
                parsedLines.append(.empty)
                continue
            }
            
            // 2. Match Pure Comment (Starts with #)
            if trimmed.hasPrefix("#") {
                parsedLines.append(.comment(text: line))
                continue
            }
            
            let nsString = line as NSString
            let range = NSRange(location: 0, length: nsString.length)
            
            // 3. Match PATH Prepend (export PATH="/dir:$PATH")
            if let match = pathPrependRegex.firstMatch(in: line, options: [], range: range) {
                let pathVal = nsString.substring(with: match.range(at: 2))
                let commentVal = match.range(at: 3).location != NSNotFound ? nsString.substring(with: match.range(at: 3)) : nil
                parsedLines.append(.pathExport(path: pathVal, isPrepend: true, comment: commentVal))
                continue
            }
            
            // 4. Match PATH Append (export PATH="$PATH:/dir")
            if let match = pathAppendRegex.firstMatch(in: line, options: [], range: range) {
                let pathVal = nsString.substring(with: match.range(at: 2))
                let commentVal = match.range(at: 3).location != NSNotFound ? nsString.substring(with: match.range(at: 3)) : nil
                parsedLines.append(.pathExport(path: pathVal, isPrepend: false, comment: commentVal))
                continue
            }
            
            // 5. Match Alias (alias name="value")
            if let match = aliasRegex.firstMatch(in: line, options: [], range: range) {
                let nameVal = nsString.substring(with: match.range(at: 1))
                let cmdVal = nsString.substring(with: match.range(at: 3))
                let commentVal = match.range(at: 4).location != NSNotFound ? nsString.substring(with: match.range(at: 4)) : nil
                parsedLines.append(.alias(name: nameVal, value: cmdVal, isEnabled: true, comment: commentVal))
                continue
            }
            
            // 6. Match Environment Variables (export NAME="value")
            if let match = envVarRegex.firstMatch(in: line, options: [], range: range) {
                let keyVal = nsString.substring(with: match.range(at: 1))
                let valVal = nsString.substring(with: match.range(at: 3))
                let commentVal = match.range(at: 4).location != NSNotFound ? nsString.substring(with: match.range(at: 4)) : nil
                
                let uppercaseKey = keyVal.uppercased()
                let sensitiveKeywords = ["KEY", "TOKEN", "PASSWORD", "SECRET", "AUTH", "PASS"]
                let isSensitive = sensitiveKeywords.contains { uppercaseKey.contains($0) }
                
                parsedLines.append(.envVar(name: keyVal, value: valVal, isSensitive: isSensitive, comment: commentVal))
                continue
            }
            
            // 7. Safety Fallback: treat as raw line to preserve loops, conditionals, or custom commands
            parsedLines.append(.raw(content: line))
        }
        
        return parsedLines
    }
    
    /// Re-serializes a list of structured `ConfigLine` tokens back into a single shell profile string.
    /// Consolidated PATH block overrides duplicate loose paths and replaces the first PATH export position.
    /// - Parameter lines: The token list to serialize.
    /// - Returns: A round-trip formatted configuration text.
    public static func serialize(_ lines: [ConfigLine]) -> String {
        lock.lock()
        defer { lock.unlock() }
        
        // 1. Extract all PATH exports to bundle them cleanly
        var pathExports = [ConfigLine]()
        for line in lines {
            if case .pathExport = line {
                pathExports.append(line)
            }
        }
        
        // 2. Find the index of the first PATH export line to insert our consolidated block
        var firstPathExportIndex: Int? = nil
        for (index, line) in lines.enumerated() {
            if case .pathExport = line {
                firstPathExportIndex = index
                break
            }
        }
        
        var serializedLines = [String]()
        
        // Helper to output the consolidated PATH stack block
        let appendPathBlock = {
            if !pathExports.isEmpty {
                serializedLines.append("# >>> PathDeck PATH Section >>>")
                for pathLine in pathExports {
                    if case .pathExport(let path, let isPrepend, let comment) = pathLine {
                        let commentSuffix = comment != nil ? " # \(comment!)" : ""
                        if isPrepend {
                            serializedLines.append("export PATH=\"\(path):$PATH\"\(commentSuffix)")
                        } else {
                            serializedLines.append("export PATH=\"$PATH:\(path)\"\(commentSuffix)")
                        }
                    }
                }
                serializedLines.append("# <<< PathDeck PATH Section <<<")
            }
        }
        
        var pathBlockInserted = false
        
        for (index, line) in lines.enumerated() {
            switch line {
            case .pathExport:
                // Replace the first PATH export with the consolidated block, and skip subsequent ones
                if !pathBlockInserted {
                    if let firstIdx = firstPathExportIndex, index == firstIdx {
                        appendPathBlock()
                        pathBlockInserted = true
                    }
                }
                
            case .alias(let name, let value, let isEnabled, let comment):
                let commentSuffix = comment != nil ? " # \(comment!)" : ""
                if isEnabled {
                    serializedLines.append("alias \(name)=\"\(value)\"\(commentSuffix)")
                } else {
                    serializedLines.append("# alias \(name)=\"\(value)\"\(commentSuffix)")
                }
                
            case .envVar(let name, let value, _, let comment):
                let commentSuffix = comment != nil ? " # \(comment!)" : ""
                serializedLines.append("export \(name)=\"\(value)\"\(commentSuffix)")
                
            case .comment(let text):
                // Filter out any pre-existing PathDeck marker comments to avoid duplicates
                let trimmed = text.trimmingCharacters(in: .whitespaces)
                if trimmed == "# >>> PathDeck PATH Section >>>" || trimmed == "# <<< PathDeck PATH Section <<<" {
                    continue
                }
                serializedLines.append(text)
                
            case .empty:
                serializedLines.append("")
                
            case .raw(let content):
                serializedLines.append(content)
            }
        }
        
        // If there were no PATH exports in the original file, append the consolidated block at the end
        if !pathBlockInserted && !pathExports.isEmpty {
            serializedLines.append("")
            appendPathBlock()
        }
        
        return serializedLines.joined(separator: "\n")
    }
}
