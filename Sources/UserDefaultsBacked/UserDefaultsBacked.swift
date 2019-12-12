import Foundation

// MARK: - Error

internal enum Error: Swift.Error {
    case illegalValue(found: Any, for: Any.Type)
    case illegalUserDefaultsDirectlyStorableType(type: Any.Type)
}

@propertyWrapper public struct UserDefaultsBacked<Value> where Value: UserDefaultsStorable {
 
    public let key: String
    
    public let defaultValue: Value
    
    private let defaults: UserDefaults
    
    public var wrappedValue: Value {
        didSet {
            do {
                let defaultValue = try wrappedValue.toUserDefaultsDirectlyStorable()
                defaults.set(defaultValue, forKey: key)
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
    
    public init(key: String, `default`: Value, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = userDefaults
        self.defaultValue = `default`
        
        if let value = defaults.object(forKey: key) {
            do {
                if let v = value as? Value.UserDefaultsDirectlyStorableType {
                    self.wrappedValue = try Value.init(userDefaultsDirectlyStorable: v)
                } else {
                    throw Error.illegalValue(found: value, for: Value.UserDefaultsDirectlyStorableType.self)
                }
            } catch {
                assertionFailure(error.localizedDescription)
                self.wrappedValue = `default`
            }
        } else {
            //missing value
            self.wrappedValue = `default`
        }
    }
    
    public init<T>(key: String, userDefaults: UserDefaults = .standard) where Value == T? {
        self.init(key: key, default: nil, userDefaults: userDefaults)
    }
    
    public mutating func clear() {
        wrappedValue = defaultValue
        defaults.removeObject(forKey: key)
    }
}
