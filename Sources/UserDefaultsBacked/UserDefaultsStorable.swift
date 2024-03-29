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

public protocol UserDefaultsDirectlyStorable: UserDefaultsStorable {}

extension UserDefaultsDirectlyStorable {
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

extension Bool: UserDefaultsDirectlyStorable {}
extension Int: UserDefaultsDirectlyStorable {}
extension Float: UserDefaultsDirectlyStorable {}
extension Double: UserDefaultsDirectlyStorable {}
extension Data: UserDefaultsDirectlyStorable {}
extension String: UserDefaultsDirectlyStorable {}
extension Date: UserDefaultsDirectlyStorable {}

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

public protocol UserDefaultsCompatible: UserDefaultsStorable {
    associatedtype UserDefaultsValueType: UserDefaultsDirectlyStorable
    init(userDefaultsValue: UserDefaultsValueType) throws
    func toUserDefaultsValue() throws -> UserDefaultsValueType
}

extension UserDefaultsCompatible {
    public func toUserDefaultsDirectlyStorable() throws -> UserDefaultsValueType.UserDefaultsDirectlyStorableType {
        try self.toUserDefaultsValue().toUserDefaultsDirectlyStorable()
    }
    public init(userDefaultsDirectlyStorable: UserDefaultsValueType.UserDefaultsDirectlyStorableType) throws {
        self = try Self.init(userDefaultsValue: try UserDefaultsValueType.init(userDefaultsDirectlyStorable: userDefaultsDirectlyStorable))
    }
}

// MARK: - UserDefaultsValueRepresentable + Codable

private struct CodableWrapper<T>: Codable where T: Codable {
    let root: T
    init(_ value: T) {
        self.root = value
    }
}

extension UserDefaultsCompatible where Self: Codable {
    public init(userDefaultsValue: Data) throws {
        self = try PropertyListDecoder().decode(CodableWrapper<Self>.self, from: userDefaultsValue).root
    }
    
    public func toUserDefaultsValue() throws -> Data {
        try PropertyListEncoder().encode(CodableWrapper(self))
    }
}

// MARK: - UserDefaultsValueRepresentable + NSSecureCoding

extension UserDefaultsCompatible where Self: NSObject & NSSecureCoding {
    public func toUserDefaultsValue() throws -> Data {
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

extension UserDefaultsCompatible where Self: RawRepresentable, RawValue: UserDefaultsCompatible, UserDefaultsValueType == RawValue.UserDefaultsValueType {
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

extension URL: UserDefaultsCompatible {}
