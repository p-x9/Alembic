import class Foundation.JSONSerialization
import class Foundation.NSNull
import struct Foundation.Data

public final class JSON {
    public let rawValue: Any
    
    public init(_ rawValue: Any) {
        self.rawValue = rawValue
    }
    
    public convenience init(data: Data, options: JSONSerialization.ReadingOptions = .allowFragments) throws {
        do {
            let rawValue = try JSONSerialization.jsonObject(with: data, options: options)
            self.init(rawValue)
        } catch {
            throw DecodeError.serializeFailed(value: data)
        }
    }
    
    public convenience init(
        string: String,
        encoding: String.Encoding = .utf8,
        allowLossyConversion: Bool = false,
        options: JSONSerialization.ReadingOptions = .allowFragments) throws {
        guard let data = string.data(using: encoding, allowLossyConversion: allowLossyConversion) else {
            throw DecodeError.serializeFailed(value: string)
        }
        
        do {
            try self.init(data: data, options: options)
        } catch DecodeError.serializeFailed {
            throw DecodeError.serializeFailed(value: string)
        }
    }
}

public extension JSON {
    func value<T: Decodable>(for path: Path = []) throws -> T {
        let object: Any = try retrive(with: path)
        
        do {
            return try .value(from: .init(object))
        } catch let DecodeError.missing(path: missing) {
            throw DecodeError.missing(path: path + missing)
        } catch let DecodeError.typeMismatch(value: value, expected: expected, path: mismatchPath) {
            throw DecodeError.typeMismatch(value: value, expected: expected, path: path + mismatchPath)
        }
    }
    
    func value<T: Decodable>(for path: Path = []) throws -> [T] {
        return try .value(from: value(for: path))
    }
    
    func value<T: Decodable>(for path: Path = []) throws -> [String: T] {
        return try .value(from: value(for: path))
    }
    
    func option<T: Decodable>(for path: Path = []) throws -> T? {
        do {
            return try value(for: path) as T
        } catch let DecodeError.missing(path: missing) where missing == path {
            return nil
        }
    }
    
    func option<T: Decodable>(for path: Path = []) throws -> [T]? {
        return try option(for: path).map([T].value(from:))
    }
    
    func option<T: Decodable>(for path: Path = []) throws -> [String: T]? {
        return try option(for: path).map([String: T].value(from:))
    }
}

public extension JSON {
    func decodeValue<T: Decodable>(for path: Path = [], as: T.Type = T.self) -> ThrowableDecoded<T> {
        return .init { try self.value(for: path) }
    }
    
    func decodeValue<T: Decodable>(for path: Path = [], as: [T].Type = [T].self) -> ThrowableDecoded<[T]> {
        return .init { try self.value(for: path) }
    }
    
    func decodeValue<T: Decodable>(for path: Path = [], as: [String: T].Type = [String: T].self) -> ThrowableDecoded<[String: T]> {
        return .init { try self.value(for: path) }
    }
    
    func decodeOption<T: Decodable>(for path: Path = [], as: T?.Type = T?.self) -> ThrowableDecoded<T?> {
        return .init { try self.option(for: path) }
    }
    
    func decodeOption<T: Decodable>(for path: Path = [], as: [T]?.Type = [T]?.self) -> ThrowableDecoded<[T]?> {
        return .init { try self.option(for: path) }
    }
    
    func decodeOption<T: Decodable>(for path: Path = [], as: [String: T]?.Type = [String: T]?.self) -> ThrowableDecoded<[String: T]?> {
        return .init { try self.option(for: path) }
    }
}

// MARK: - CustomStringConvertible

extension JSON: CustomStringConvertible {
    public var description: String {
        return "JSON(\(rawValue))"
    }
}

// MARK: - CustomDebugStringConvertible

extension JSON: CustomDebugStringConvertible {
    public var debugDescription: String {
        return description
    }
}

// MARK: - private functions

private extension JSON {
    func retrive<T>(with path: Path) throws -> T {
        func cast<T>(_ value: Any) throws -> T {
            guard let castedValue = value as? T else {
                throw DecodeError.typeMismatch(value: value, expected: T.self, path: path)
            }
            return castedValue
        }
        
        func retrive(from value: Any, with elements: ArraySlice<Path.Element>) throws -> Any {
            guard let first = elements.first else { return value }
            
            switch first {
            case let .key(key):
                let dictionary: [String: Any] = try cast(value)
                
                guard let value = dictionary[key], !(value is NSNull) else {
                    throw DecodeError.missing(path: path)
                }
                
                return try retrive(from: value, with: elements.dropFirst())
                
            case let .index(index):
                let array: [Any] = try cast(value)
                
                guard array.count > index else {
                    throw DecodeError.missing(path: path)
                }
                
                let value = array[index]
                
                if value is NSNull {
                    throw DecodeError.missing(path: path)
                }
                
                return try retrive(from: value, with: elements.dropFirst())
            }
        }
        
        let elements = ArraySlice(path.elements)
        return try cast(retrive(from: rawValue, with: elements))
    }
}
