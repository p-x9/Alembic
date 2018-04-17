import class Foundation.JSONSerialization
import class Foundation.NSNull
import struct Foundation.Data

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import class Foundation.NSDictionary
    import class Foundation.NSArray
    private typealias AnyDictionary = NSDictionary
    private typealias AnyArray = NSArray
#else
    private typealias AnyDictionary = [String: Any]
    private typealias AnyArray = [Any]
#endif

public struct JSON {
    public let rawValue: Any
    
    public init(_ rawValue: Any) {
        self.rawValue = rawValue
    }
    
    public init(data: Data, options: JSONSerialization.ReadingOptions = .allowFragments) throws {
        do {
            let rawValue = try JSONSerialization.jsonObject(with: data, options: options)
            self.init(rawValue)
        } catch {
            throw JSON.Error.dataCorrupted(value: data, description: "The given data was not valid JSON data.")
        }
    }
    
    public init(
        string: String,
        encoding: String.Encoding = .utf8,
        allowLossyConversion: Bool = false,
        options: JSONSerialization.ReadingOptions = .allowFragments) throws {
        guard let data = string.data(using: encoding, allowLossyConversion: allowLossyConversion) else {
            throw JSON.Error.dataCorrupted(value: string, description: "The given string could not convert to data using a given encoding.")
        }
        
        do {
            try self.init(data: data, options: options)
        } catch {
            throw JSON.Error.dataCorrupted(value: data, description: "The given string was not valid JSON string.")
        }
    }
}

public extension JSON {
    func value<T: Parsable>(_ type: T.Type = T.self, for path: Path = []) throws -> T {
        let value = try retrive(with: path)
        
        do {
            return try .value(from: .init(value))
        } catch let JSON.Error.missing(path: missingPath) {
            throw JSON.Error.missing(path: path + missingPath)
        } catch let JSON.Error.typeMismatch(expected: expected, actualValue: actualValue, path: mismatchPath) {
            throw JSON.Error.typeMismatch(expected: expected, actualValue: actualValue, path: path + mismatchPath)
        } catch let JSON.Error.unexpected(value: value, path: unexpectedPath) {
            throw JSON.Error.unexpected(value: value, path: path + unexpectedPath)
        }
    }
    
    func option<T: Parsable>(_ type: T.Type = T.self, for path: Path = []) throws -> T? {
        do {
            return try value(for: path) as T
        } catch let JSON.Error.missing(path: missing) where missing == path {
            return nil
        }
    }
}

public extension JSON {
    func parse<T: Parsable>(_ type: T.Type = T.self, for path: Path = []) -> ThrowParser<T> {
        return .init(path: path) { try self.value(for: path) }
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

// MARK: - ExpressibleByArrayLiteral

extension JSON: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension JSON: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Any)...) {
        let dictionary = [String: Any](elements, uniquingKeysWith: { $1 })
        self.init(dictionary)
    }
}

// MARK: - private functions

private extension JSON {
    @inline(__always)
    func retrive(with path: Path) throws -> Any {
        var result = rawValue
        
        for pathElement in path {
            switch pathElement {
            case let .key(key):
                guard let dictionary = result as? AnyDictionary, let value = dictionary[key], !(value is NSNull) else {
                    throw JSON.Error.missing(path: path)
                }

                result = value
                
            case let .index(index):
                guard let array = result as? AnyArray, array.count > index else {
                    throw JSON.Error.missing(path: path)
                }
                
                let value = array[index]
                
                if value is NSNull {
                    throw JSON.Error.missing(path: path)
                }
                
                result = value
            }
        }
        
        return result
    }
}
