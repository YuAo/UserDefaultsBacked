import XCTest
@testable import UserDefaultsBacked

final class UserDefaultsBackedTests: XCTestCase {
    
    @UserDefaultsBacked(key: "string", default: "default")
    var stringProperty: String
    
    func testExample() {
        
        self._stringProperty.clear()
        XCTAssertEqual(stringProperty, "default")
        self.stringProperty = "hello"
        XCTAssertEqual(stringProperty, "hello")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
