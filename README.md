# UserDefaultsBacked

Type-safe property wrapper for reading and writing UserDefaults.


## Usage

```Swift

struct CustomData: Codable {
    var identifier: String = ""
    var count: Int = 0
}

/// Anything conforms to `Codable`, `NSSecureCoding`, `RawRepresentable` can be UserDefaultsCompatible.
extension CustomData: UserDefaultsCompatible {}

struct YourApp {
    @UserDefaultsBacked(key: "app.url")
    var url: URL?

    @UserDefaultsBacked(key: "app.name", default: "Awesome")
    var name: String

    @UserDefaultsBacked(key: "app.data", default: CustomData())
    var customData: CustomData
}

```
