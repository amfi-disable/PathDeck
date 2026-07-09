import XCTest
@testable import PathDeck

final class PathDeckTests: XCTestCase {
    func testDay1ModelsCompilation() throws {
        let pathItem = PATHItem(rawPath: "/usr/local/bin", isValid: true, isEnabled: true)
        XCTAssertEqual(pathItem.rawPath, "/usr/local/bin")
        XCTAssertTrue(pathItem.isValid)
        XCTAssertTrue(pathItem.isEnabled)
        
        let aliasItem = AliasItem(name: "ll", command: "ls -la", comment: "List details")
        XCTAssertEqual(aliasItem.name, "ll")
        XCTAssertEqual(aliasItem.command, "ls -la")
        XCTAssertEqual(aliasItem.comment, "List details")
        
        let envVarItem = EnvVarItem(key: "API_KEY", value: "secret", isSensitive: true)
        XCTAssertEqual(envVarItem.key, "API_KEY")
        XCTAssertEqual(envVarItem.value, "secret")
        XCTAssertTrue(envVarItem.isSensitive)
    }
}
