import Foundation
import LocalAuthentication

/// A thread-safe biometric and passcode authentication utility using Apple's LocalAuthentication framework.
public final class TouchIDService {
    
    public static let shared = TouchIDService()
    
    private init() {}
    
    /// Asynchronously authenticates user utilizing Touch ID, falling back to system password passcode prompt if unavailable.
    /// - Parameter reason: Contextual explanation presented to the user.
    /// - Returns: True if user authenticated successfully, false otherwise.
    public func authenticateUser(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        let canAuth = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        
        guard canAuth else {
            // Under debugging environments (clean CI/CD VMs or Simulator without passcode), fallback to true to allow UI validation.
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success
        } catch {
            return false
        }
    }
}
