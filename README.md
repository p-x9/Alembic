<p align="center">
<img src="https://raw.githubusercontent.com/ra1028/Alembic/master/Assets/Alembic_Logo.png" alt="Alembic" width="70%">
</p>
<H4 align="center">Functional JSON Parser</H4>
</br>

<p align="center">
<a href="https://developer.apple.com/swift"><img alt="Swift4" src="https://img.shields.io/badge/language-swift4-orange.svg?style=flat"/></a>
<a href="https://travis-ci.org/ra1028/Alembic"><img alt="Build Status" src="https://travis-ci.org/ra1028/Alembic.svg?branch=master"/></a>
<a href="https://codebeat.co/projects/github-com-ra1028-alembic"><img alt="CodeBeat" src="https://codebeat.co/badges/09cc20c0-4cba-4c78-8e20-39f41d86c587"/></a>
</p>
</br>

<p align="center">
<a href="https://cocoapods.org/pods/Alembic"><img alt="CocoaPods" src="https://img.shields.io/cocoapods/v/Alembic.svg"/></a>
<a href="https://github.com/Carthage/Carthage"><img alt="Carthage" src="https://img.shields.io/badge/Carthage-compatible-yellow.svg?style=flat"/></a>
<a href="https://github.com/apple/swift-package-manager"><img alt="Swift Package Manager" src="https://img.shields.io/badge/SwiftPM-compatible-blue.svg"/></a>
</p>
</br>

<p align="center">
<a href="https://developer.apple.com/swift/"><img alt="Platform" src="https://img.shields.io/badge/platform-iOS%20%7C%20OSX%20%7C%20tvOS%20%7C%20watchOS%20%7C%20Linux-green.svg"/></a>
<a href="https://github.com/ra1028/Alembic/blob/master/LICENSE"><img alt="Lincense" src="http://img.shields.io/badge/license-MIT-000000.svg?style=flat"/></a>
</p>

---

## Feature
- Linux Ready
- Type-safe JSON parsing
- Functional value transformation
- Easy to parse nested value
- Dependency free
- No defined custom operators

---

## Requirements
- Swift4.1 or later
- OS X 10.9 or later
- iOS 9.0 or later
- watchOS 2.0 or later
- tvOS 9.0 or later
- Linux

---

## Installation

### [CocoaPods](https://cocoapods.org/)  
Add the following to your Podfile:  
```ruby
use_frameworks!

target 'TargetName' do
  pod 'Alembic'
end
```

### [Carthage](https://github.com/Carthage/Carthage)  
Add the following to your Cartfile:  
```ruby
github "ra1028/Alembic"
```

### [Swift Package Manager](https://github.com/apple/swift-package-manager)
Add the following to your Package.swift:  
```Swift
// swift-tools-version:4.0

let package = Package(
    name: "ProjectName",
    dependencies : [
        .package(url: "https://github.com/ra1028/Alembic.git", .upToNextMajor(from: "3"))
    ]
)
```

---

## Example  
In example, parse the following JSON:  
```json
{
    "teams": [
        {
            "name": "Team ra1028",
            "url": "https://github.com/ra1028",
            "members": [
                {
                    "name": "Ryo Aoyama",
                    "age": 23
                },
                {
                    "name": "John Doe",
                    "age": 30
                }
            ]
        }
    ]
}
```

#### Make the JSON instance from `Any`, `Data` or `String` type JSON object.
```swift
// from `Any` type JSON object
let json = JSON(object)
```
```swift
// from JSON Data
let json = try JSON(data: data)
```
```swift
// from JSON String
let json = try JSON(string: string)
```

#### Parse value from JSON:
__Parse the values type-safely__
```swift
let memberName: String = try json.value(for: ["teams", 0, "members", 0, "name"])
```
__Parse nullable value__
```swift
let missingText: String? = try json.option(for: "missingKey")
```

#### Parse value from JSON with transforming:
__Transform value using various monadic functions.__
```swift
let teamUrl: URL = try json.parse(String.self, for: ["teams", 0, "url"])
        .filterMap(URL.init(string:))
        .value()
```
__Transform nullable value if exist__
```swift
let missingUrl: URL? = try json.parse(String.self, for: "missingKey")
        .filterMap(URL.init(string:))
        .option()
```

#### Mapping to model from JSON:
__All types conforming to `Parsable` protocol and it's Array, Dictionary can be parsed.__  
```swift
struct Member: Parsable {
    let name: String
    let age: Int

    static func value(from json: JSON) throws -> Member {
        return try .init(
            name: json.value(for: "name"),
            age: json.value(for: "age")
        )
    }
}

extension URL: Parsable {
    public static func value(from json: JSON) throws -> URL {
        guard let url = try URL(string: json.value()) else {
            throw JSON.Error.dataCorrupted(value: json.rawValue, description: "The value was not valid url string.")
        }
        return url
    }
}

struct Team: Parsable {
    let name: String
    let url: URL
    let members: [Member]

    static func value(from json: JSON) throws -> Team {
        return try .init(
            name: json.value(for: "name"),
            url: json.value(for: "url"),
            members: json.value(for: "members")
        )
    }
}
```
```swift
let team: Team = try json.value(for: ["teams", 0])
```

---

## Tips
#### The types conformed to `Parsable` as default.  
```swift
JSON
String
Int
UInt
Double
Float
Bool
NSNumber
Int8
UInt8
Int16
UInt16
Int32
UInt32
Int64
UInt64
Decimal
Array where Element: Parsable
Dictionary where Key == String, Value: Parsable
Optional where Wrapped: Parsable
```

#### Conform to `Parsable` with initializer
```swift
struct Member: ParseInitializable {
    let name: String
    let age: Int

    init(with json: JSON) throws {
        name = try json.value(for: "name")
        age = try json.value(for: "age")
    }
}
```

#### Usage Reference Files
Functional operators for value transforming:
- [ParserProtocol.swift](./Sources/ParserProtocol.swift)
- [Parser.swift](./Sources/Parser.swift)
- [ThrowParser.swift](./Sources/ThrowParser.swift)

Errors
- [Error.swift](./Sources/Error.swift)

#### More Example
See the [Test files](./Tests/AlembicTests)

---

## Playground
1. Open Alembic.xcworkspace.
2. Build the Alembic for Mac.
3. Open Alembic playground in project navigator.

---

## Contribution
Welcome to fork and submit pull requests!

Before submitting pull request, please ensure you have passed the included tests.
If your pull request including new function, please write test cases for it.

---

## License
Alembic is released under the MIT License.

---
