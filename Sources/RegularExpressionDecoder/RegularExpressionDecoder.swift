import Foundation

/**

 */
@available(OSX 10.13, iOS 11, *)
final public class RegularExpressionDecoder<T: Decodable> {
    private(set) var regularExpression: NSRegularExpression
    
    public enum Error: Swift.Error {
        case noMatches
        case tooManyMatches
    }

    public init<CodingKeys>(pattern: RegularExpressionPattern<T, CodingKeys>, options: NSRegularExpression.Options = []) throws {
        self.regularExpression = try NSRegularExpression(pattern: pattern.description, options: options)
    }

    public func decode(_ type: T.Type, from string: String, options: NSRegularExpression.MatchingOptions = []) throws -> T {
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        let matches = self.regularExpression.matches(in: string, options: options, range: range)
        
        switch matches.count {
        case 0:
            throw Error.noMatches
        case 1:
            let decoder = _RegularExpressionDecoder(string: string, matches: matches)
            return try T(from: decoder)
        default:
            throw Error.tooManyMatches
        }
    }
    
    public func decode(_ type: [T].Type, from string: String, options: NSRegularExpression.MatchingOptions = []) throws -> [T] {
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        let matches = self.regularExpression.matches(in: string, options: options, range: range)
        
        switch matches.count {
        case 0:
            return []
        default:
            let decoder = _RegularExpressionDecoder(string: string, matches: matches)
            return try [T](from: decoder)
        }
    }
}

@available(OSX 10.13, iOS 11, *)
final class _RegularExpressionDecoder {
    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey: Any] = [:]

    var container: RegularExpressionDecodingContainer?
    fileprivate var string: String
    fileprivate var matches: [NSTextCheckingResult]

    init(string: String, matches: [NSTextCheckingResult]) {
        self.string = string
        self.matches = matches
    }
}

@available(OSX 10.13, iOS 11, *)
extension _RegularExpressionDecoder: Decoder {
    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }
    
    func singleValueContainer() -> SingleValueDecodingContainer {
        assertCanCreateContainer()
        
        let container = SingleValueContainer(string: self.string, match: self.matches.first, codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container
        
        return container
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key> where Key : CodingKey {
        assertCanCreateContainer()

        let container = KeyedContainer<Key>(string: self.string, match: self.matches.first, codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedDecodingContainer {
        assertCanCreateContainer()

        let container = UnkeyedContainer(string: self.string, matches: self.matches, codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return container
    }
}

@available(OSX 10.13, iOS 11, *)
protocol RegularExpressionDecodingContainer: class {}
