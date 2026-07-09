import Foundation

/// Represents a single directory entry in the PATH variable stack.
public struct PATHItem: Identifiable, Equatable, Hashable {
    public let id: UUID
    /// The raw folder path string (e.g., "/usr/local/bin" or "~/bin").
    public var rawPath: String
    /// Indicates whether the path points to an existing directory on the physical disk.
    public var isValid: Bool
    /// Indicates whether this path export is active or commented out.
    public var isEnabled: Bool
    
    public init(id: UUID = UUID(), rawPath: String, isValid: Bool = false, isEnabled: Bool = true) {
        self.id = id
        self.rawPath = rawPath
        self.isValid = isValid
        self.isEnabled = isEnabled
    }
}

/// Represents a shell shortcut command alias (e.g., alias gs="git status").
public struct AliasItem: Identifiable, Equatable, Hashable {
    public let id: UUID
    /// The trigger keyword (e.g., "gs").
    public var name: String
    /// The target command executed by the shortcut (e.g., "git status").
    public var command: String
    /// An optional annotation or description comment.
    public var comment: String?
    /// Indicates whether this alias is active or commented out.
    public var isEnabled: Bool
    
    public init(id: UUID = UUID(), name: String, command: String, comment: String? = nil, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.command = command
        self.comment = comment
        self.isEnabled = isEnabled
    }
}

/// Represents an environment variable definition (e.g., export GITHUB_TOKEN="ghp_xxx").
public struct EnvVarItem: Identifiable, Equatable, Hashable {
    public let id: UUID
    /// The name of the environment variable (e.g., "GITHUB_TOKEN").
    public var key: String
    /// The value of the environment variable.
    public var value: String
    /// Indicates whether the value should be hidden behind Touch ID biometrics.
    public var isSensitive: Bool
    
    public init(id: UUID = UUID(), key: String, value: String, isSensitive: Bool = false) {
        self.id = id
        self.key = key
        self.value = value
        self.isSensitive = isSensitive
    }
}

/// An AST representation of a single parsed line in the shell profile script.
public enum ConfigLine: Identifiable, Equatable, Hashable {
    case pathExport(path: String, isPrepend: Bool, comment: String?)
    case alias(name: String, value: String, isEnabled: Bool, comment: String?)
    case envVar(name: String, value: String, isSensitive: Bool, comment: String?)
    case comment(text: String)
    case empty
    case raw(content: String)
    
    /// Stable hashable identifier for SwiftUI List rendering stability
    public var id: String {
        switch self {
        case .pathExport(let path, let isPrepend, let comment):
            return "path-\(path)-\(isPrepend)-\(comment ?? "")"
        case .alias(let name, let value, let isEnabled, let comment):
            return "alias-\(name)-\(value)-\(isEnabled)-\(comment ?? "")"
        case .envVar(let name, let value, let isSensitive, let comment):
            return "envVar-\(name)-\(value)-\(isSensitive)-\(comment ?? "")"
        case .comment(let text):
            return "comment-\(text)"
        case .empty:
            return "empty"
        case .raw(let content):
            return "raw-\(content)"
        }
    }
}
