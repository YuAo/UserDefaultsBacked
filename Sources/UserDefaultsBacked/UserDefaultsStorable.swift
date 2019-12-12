//
//  File.swift
//  
//
//  Created by Yu Ao on 2019/12/11.
//

import Foundation

// MARK: - UserDefaultsStorable

public protocol UserDefaultsStorable {
    associatedtype UserDefaultsDirectlyStorableType
    func toUserDefaultsDirectlyStorable() throws -> UserDefaultsDirectlyStorableType
    init(userDefaultsDirectlyStorable: UserDefaultsDirectlyStorableType) throws
}

// MARK: - UserDefaultsValue

public protocol UserDefaultsCompatible: UserDefaultsStorable {}

extension UserDefaultsCompatible {
    private func typeCheck() throws {
        guard self is Bool ||
            self is Int ||
            self is Float ||
            self is Double ||
            self is Data ||
            self is String ||
            self is Date else {
            throw Error.illegalUserDefaultsDirectlyStorableType(type: Self.self)
        }
    }
    
    public func toUserDefaultsDirectlyStorable() throws -> Self {
        try self.typeCheck()
        return self
    }
    
    public init(userDefaultsDirectlyStorable: Self) throws {
        try userDefaultsDirectlyStorable.typeCheck()
        self = userDefaultsDirectlyStorable
    }
}

extension Bool: UserDefaultsCompatible {}
extension Int: UserDefaultsCompatible {}
extension Float: UserDefaultsCompatible {}
extension Double: UserDefaultsCompatible {}
extension Data: UserDefaultsCompatible {}
extension String: UserDefaultsCompatible {}
extension Date: UserDefaultsCompatible {}

// MARK: - Containers

extension Array: UserDefaultsStorable where Element: UserDefaultsStorable {
    public typealias UserDefaultsDirectlyStorableType = [Element.UserDefaultsDirectlyStorableType]
    
    public init(userDefaultsDirectlyStorable: UserDefaultsDirectlyStorableType) throws {
        if let array = userDefaultsDirectlyStorable as? Self {
            self = array
        } else {
            self = try userDefaultsDirectlyStorable.map(Element.init(userDefaultsDirectlyStorable:))
        }
    }
    
    public func toUserDefaultsDirectlyStorable() throws -> UserDefaultsDirectlyStorableType {
        return try (self as? UserDefaultsDirectlyStorableType) ?? (try self.map { try $0.toUserDefaultsDirectlyStorable() })
    }
}

extension Dictionary: UserDefaultsStorable where Key == String, Value: UserDefaultsStorable {
    public typealias UserDefaultsDirectlyStorableType = [String: Value.UserDefaultsDirectlyStorableType]
    
    public init(userDefaultsDirectlyStorable: UserDefaultsDirectlyStorableType) throws {
        if let dictionary = userDefaultsDirectlyStorable as? Self {
            self = dictionary
        } else {
            self = try userDefaultsDirectlyStorable.mapValues(Value.init(userDefaultsDirectlyStorable:))
        }
    }
    
    public func toUserDefaultsDirectlyStorable() throws -> UserDefaultsDirectlyStorableType {
        return try (self as? UserDefaultsDirectlyStorableType) ?? (try self.mapValues({ try $0.toUserDefaultsDirectlyStorable() }))
    }
}

extension Optional: UserDefaultsStorable where Wrapped: UserDefaultsStorable {
    public typealias UserDefaultsDirectlyStorableType = [Wrapped.UserDefaultsDirectlyStorableType]
    
    public init(userDefaultsDirectlyStorable: UserDefaultsDirectlyStorableType) throws {
        if userDefaultsDirectlyStorable.count < 2 {
            if let v = userDefaultsDirectlyStorable.first {
                self = try Wrapped.init(userDefaultsDirectlyStorable: v)
            } else {
                self = nil
            }
        } else {
            throw Error.illegalValue(found: userDefaultsDirectlyStorable, for: Self.self)
        }
    }
    
    public func toUserDefaultsDirectlyStorable() throws -> UserDefaultsDirectlyStorableType {
        if let value = self {
            return [try value.toUserDefaultsDirectlyStorable()]
        } else {
            return []
        }
    }
}

// MARK: - UserDefaultsValueRepresentable

public protocol UserDefaultsValueRepresentable: UserDefaultsStorable {
    associatedtype UserDefaultsValueType: UserDefaultsCompatible
    init(userDefaultsValue: UserDefaultsValueType) throws
    func toUserDefaultsValue() throws -> UserDefaultsValueType
}

extension UserDefaultsValueRepresentable {
    public func toUserDefaultsDirectlyStorable() throws -> UserDefaultsValueType.UserDefaultsDirectlyStorableType {
        try self.toUserDefaultsValue().toUserDefaultsDirectlyStorable()
    }
    public init(userDefaultsDirectlyStorable: UserDefaultsValueType.UserDefaultsDirectlyStorableType) throws {
        self = try Self.init(userDefaultsValue: try UserDefaultsValueType.init(userDefaultsDirectlyStorable: userDefaultsDirectlyStorable))
    }
}

// MARK: - UserDefaultsValueRepresentable + Codable

extension UserDefaultsValueRepresentable where Self: Codable {
    public init(userDefaultsValue: Data) throws {
        self = try PropertyListDecoder().decode(Self.self, from: userDefaultsValue)
    }
    
    public func toUserDefaultsValue() throws -> Data {
        try PropertyListEncoder().encode(self)
    }
}

// MARK: - UserDefaultsValueRepresentable + NSSecureCoding

extension UserDefaultsValueRepresentable where Self: NSObject & NSSecureCoding {
    public func toUserDefaultValue() throws -> Data {
        if #available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
            return try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
        } else {
            return NSKeyedArchiver.archivedData(withRootObject: self)
        }
    }
    
    public init(userDefaultsValue: Data) throws {
        let object: Self?
        if #available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
            object = try NSKeyedUnarchiver.unarchivedObject(ofClass: Self.self, from: userDefaultsValue)
        } else {
            object = NSKeyedUnarchiver.unarchiveObject(with: userDefaultsValue) as? Self
        }
        if let object = object {
            self = object
        } else {
            throw Error.illegalValue(found: userDefaultsValue, for: Self.self)
        }
    }
}

// MARK: - UserDefaultsValueRepresentable + RawRepresentable

extension UserDefaultsValueRepresentable where Self: RawRepresentable, RawValue: UserDefaultsValueRepresentable, UserDefaultsValueType == RawValue.UserDefaultsValueType {
    public init(userDefaultsValue: UserDefaultsValueType) throws {
        let raw = try RawValue.init(userDefaultsValue: userDefaultsValue)
        guard let value = Self.init(rawValue: raw) else {
            throw Error.illegalValue(found: userDefaultsValue, for: Self.self)
        }
        self = value
    }
    
    public func toUserDefaultsValue() throws -> UserDefaultsValueType {
        try rawValue.toUserDefaultsValue()
    }
}

// MARK: - Extensions

extension URL: UserDefaultsValueRepresentable {}

#if os(macOS)
extension NSColor: UserDefaultsValueRepresentable {}
#else
extension UIColor: UserDefaultsValueRepresentable {}
#endif
