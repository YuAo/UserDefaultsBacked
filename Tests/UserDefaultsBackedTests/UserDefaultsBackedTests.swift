import XCTest
@testable import UserDefaultsBacked

struct TestData: Codable, Equatable {
    var identifier: String
}

extension TestData: UserDefaultsCompatible {}

final class UserDefaultsBackedTests: XCTestCase {
    
    @UserDefaultsBacked(key: "string", default: "default")
    var stringProperty: String
    
    @UserDefaultsBacked(key: "data")
    var testData: TestData?
    
    func testExample() {
        
        self._stringProperty.clear()
        XCTAssertEqual(stringProperty, "default")
        self.stringProperty = "hello"
        XCTAssertEqual(stringProperty, "hello")
        
        self._testData.clear()
        XCTAssertEqual(self.testData, nil)
        self.testData = TestData(identifier: "hey")
        XCTAssertEqual(UserDefaultsBacked<TestData?>(key: "data").wrappedValue, TestData(identifier: "hey"))
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
