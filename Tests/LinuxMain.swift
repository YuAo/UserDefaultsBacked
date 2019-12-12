import XCTest

import UserDefaultsBackedTests

var tests = [XCTestCaseEntry]()
tests += UserDefaultsBackedTests.allTests()
XCTMain(tests)
