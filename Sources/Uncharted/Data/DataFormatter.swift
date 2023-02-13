
import Foundation
import Toolbox

/// Protocol for types that can format values for display in a chart.
public protocol DataFormatter {
    /// Format the given value as a readable string.
    func callAsFunction(_ value: Double) -> String
    
    /// Encode this formatter.
    func encode(to encoder: Encoder) throws
    
    /// Decode this formatter.
    init(from decoder: Decoder) throws
    
    /// Hash this formatter.
    func hash(into hasher: inout Hasher)
}

/// Formatter for integer values.
public struct IntegerFormatter: DataFormatter {
    /// The rounding rule to apply to the value.
    public let rule: FloatingPointRoundingRule
    
    /// The threshold above which to apply scientific notation.
    public let scientificNotationThreshold: Double
    
    /// Create an integer formatter with a rounding rule.
    ///
    /// - Parameters:
    ///   - rule: The rounding rule to apply to the value.
    ///   - scientificNotationThreshold: The threshold above which to apply scientific notation.
    public init(rule: FloatingPointRoundingRule, scientificNotationThreshold: Double = 1_000_000) {
        self.rule = rule
        self.scientificNotationThreshold = scientificNotationThreshold
    }
    
    public func callAsFunction(_ value: Double) -> String {
        if abs(value) >= scientificNotationThreshold {
            let isNegative = value < 0
            
            var value = abs(value)
            let magnitude = log10(value).rounded(.down)
            value = value / pow(10, magnitude)
            
            return "\(isNegative ? "-" : "")\(FormatToolbox.format(value, decimalPlaces: 2, minDecimalPlaces: 1))E\(Int(magnitude))"
        }
        
        return "\(FormatToolbox.format(value.rounded(rule)))"
    }
}

public extension IntegerFormatter {
    /// The default integer formatter.
    static let standard = IntegerFormatter(rule: .toNearestOrAwayFromZero)
}

/// Formatter for floating-point values.
public struct FloatingPointFormatter: DataFormatter {
    /// The minimum number of decimal places to show.
    public let minDecimalPlaces: Int
    
    /// The maximum number of decimal places to show.
    public let maxDecimalPlaces: Int
    
    /// Whether or not the sign should always be visible.
    public let alwaysDisplaySign: Bool
    
    /// The threshold above which to apply scientific notation.
    public let scientificNotationThreshold: Double
    
    /// Create a floating point formatter.
    ///
    /// - Parameters:
    ///   - minDecimalPlaces: The minimum number of decimal places to show.
    ///   - maxDecimalPlaces: The maximum number of decimal places to show.
    ///   - alwaysDisplaySign: Whether or not the sign should always be visible.
    ///   - scientificNotationThreshold: The threshold above which to apply scientific notation.
    public init(minDecimalPlaces: Int,
                maxDecimalPlaces: Int,
                alwaysDisplaySign: Bool,
                scientificNotationThreshold: Double = 1_000_000) {
        self.minDecimalPlaces = minDecimalPlaces
        self.maxDecimalPlaces = maxDecimalPlaces
        self.alwaysDisplaySign = alwaysDisplaySign
        self.scientificNotationThreshold = scientificNotationThreshold
    }
    
    public func callAsFunction(_ value: Double) -> String {
        if abs(value) >= scientificNotationThreshold {
            let isNegative = value < 0
            
            var value = abs(value)
            let magnitude = log10(value).rounded(.down)
            value = value / pow(10, magnitude)
            
            return "\(isNegative ? "-" : "")\(FormatToolbox.format(value, decimalPlaces: 2, minDecimalPlaces: 1))E\(Int(magnitude))"
        }
        
        return "\(FormatToolbox.format(value, decimalPlaces: maxDecimalPlaces, minDecimalPlaces: minDecimalPlaces, alwaysShowSign: alwaysDisplaySign))"
    }
}

public extension FloatingPointFormatter {
    /// The default floating point formatter.
    static let standard = FloatingPointFormatter(minDecimalPlaces: 0, maxDecimalPlaces: 2, alwaysDisplaySign: false)
}

/// A formatter for dates.
public struct DateFormatter: DataFormatter {
    /// The date style to use for formatting.
    public let dateStyle: Foundation.DateFormatter.Style
    
    /// The time style to use for formatting.
    public let timeStyle: Foundation.DateFormatter.Style
    
    /// Create a date formatter.
    ///
    /// - Parameters:
    ///   - dateStyle: The date style to use for formatting.
    ///   - timeStyle: The time style to use for formatting.
    init(dateStyle: Foundation.DateFormatter.Style, timeStyle: Foundation.DateFormatter.Style) {
        self.dateStyle = dateStyle
        self.timeStyle = timeStyle
    }
    
    public func callAsFunction(_ value: Double) -> String {
        let formatter = Foundation.DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = self.dateStyle
        formatter.timeStyle = self.timeStyle
        
        return formatter.string(from: Date(timeIntervalSinceReferenceDate: value))
    }
}

public extension DateFormatter {
    /// The default date formatter.
    static let standardDate: DateFormatter = {
        .init(dateStyle: .long, timeStyle: .none)
    }()
    
    /// The default time formatter.
    static let standardTime: DateFormatter = {
        .init(dateStyle: .none, timeStyle: .short)
    }()
    
    /// The default date time formatter.
    static let standardDateTime: DateFormatter = {
        .init(dateStyle: .long, timeStyle: .short)
    }()
}

/// A formatter that invokes a custom callback.
public struct CustomDataFormatter: DataFormatter {
    /// The callback to invoke for formatting.
    let formatCallback: (Double) -> String
    
    /// Create a custom formatter.
    ///
    /// - Parameter formatCallback: The callback to invoke for formatting.
    public init(formatCallback: @escaping (Double) -> String) {
        self.formatCallback = formatCallback
    }
    
    public func callAsFunction(_ value: Double) -> String {
        formatCallback(value)
    }
}

// MARK: IntegerDataFormatter extensions

extension IntegerFormatter: Codable {
    enum CodingKeys: String, CodingKey {
        case rule, scientificNotationThreshold
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rule, forKey: .rule)
        try container.encode(scientificNotationThreshold, forKey: .scientificNotationThreshold)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            rule: try container.decode(FloatingPointRoundingRule.self, forKey: .rule),
            scientificNotationThreshold: try container.decode(Double.self, forKey: .scientificNotationThreshold)
        )
    }
}

extension IntegerFormatter: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return (
            lhs.rule == rhs.rule
            && lhs.scientificNotationThreshold == rhs.scientificNotationThreshold
        )
    }
}

extension IntegerFormatter: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rule)
        hasher.combine(scientificNotationThreshold)
    }
}

// MARK: FloatingPointDataFormatter extensions

extension FloatingPointFormatter: Codable {
    enum CodingKeys: String, CodingKey {
        case minDecimalPlaces, maxDecimalPlaces, alwaysDisplaySign, scientificNotationThreshold
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minDecimalPlaces, forKey: .minDecimalPlaces)
        try container.encode(maxDecimalPlaces, forKey: .maxDecimalPlaces)
        try container.encode(alwaysDisplaySign, forKey: .alwaysDisplaySign)
        try container.encode(scientificNotationThreshold, forKey: .scientificNotationThreshold)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            minDecimalPlaces: try container.decode(Int.self, forKey: .minDecimalPlaces),
            maxDecimalPlaces: try container.decode(Int.self, forKey: .maxDecimalPlaces),
            alwaysDisplaySign: try container.decode(Bool.self, forKey: .alwaysDisplaySign),
            scientificNotationThreshold: try container.decode(Double.self, forKey: .scientificNotationThreshold)
        )
    }
}

extension FloatingPointFormatter: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return (
            lhs.minDecimalPlaces == rhs.minDecimalPlaces
            && lhs.maxDecimalPlaces == rhs.maxDecimalPlaces
            && lhs.alwaysDisplaySign == rhs.alwaysDisplaySign
            && lhs.scientificNotationThreshold == rhs.scientificNotationThreshold
        )
    }
}

extension FloatingPointFormatter: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(minDecimalPlaces)
        hasher.combine(maxDecimalPlaces)
        hasher.combine(alwaysDisplaySign)
        hasher.combine(scientificNotationThreshold)
    }
}

// MARK: CustomDataFormatter extensions

extension CustomDataFormatter {
    public static func == (lhs: CustomDataFormatter, rhs: CustomDataFormatter) -> Bool {
        fatalError("CustomDataFormatters do not support equality comparison")
    }
    
    public func hash(into hasher: inout Hasher) {
        fatalError("CustomDataFormatters do not support hashing")
    }
    
    public func encode(to encoder: Encoder) throws {
        fatalError("CustomDataFormatters do not support coding")
    }
    
    public init(from decoder: Decoder) throws {
        fatalError("CustomDataFormatters do not support coding")
    }
}

// MARK: DateFormatter extensions

extension DateFormatter: Codable {
    enum CodingKeys: String, CodingKey {
        case dateStyle, timeStyle
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dateStyle.rawValue, forKey: .dateStyle)
        try container.encode(timeStyle.rawValue, forKey: .timeStyle)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let dateStyle = Foundation.DateFormatter.Style(rawValue: try container.decode(UInt.self, forKey: .dateStyle)) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unable to decode DateFormatter.Style"
                )
            )
        }
        guard let timeStyle = Foundation.DateFormatter.Style(rawValue: try container.decode(UInt.self, forKey: .dateStyle)) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unable to decode DateFormatter.Style"
                )
            )
        }
        
        self.init(
            dateStyle: dateStyle,
            timeStyle: timeStyle
        )
    }
}

extension DateFormatter: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return (
            lhs.dateStyle == rhs.dateStyle
            && lhs.timeStyle == rhs.timeStyle
        )
    }
}

extension DateFormatter: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(dateStyle)
        hasher.combine(timeStyle)
    }
}

