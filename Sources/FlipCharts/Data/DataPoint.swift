
import SwiftUI

public struct DataPoint {
    /// The x-axis value of this data point.
    public var x: Double
    
    /// The y-axis value of this data point.
    public var y: Double
    
    /// Default initializer.
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

extension DataPoint: VectorArithmetic {
    public static var zero: DataPoint {
        .init(x: 0, y: 0)
    }
    
    public mutating func scale(by rhs: Double) {
        x = x * rhs
        y = y * rhs
    }
    
    public var magnitudeSquared: Double {
        Double((x*x) + (y*y))
    }
    
    // Vector addition
    public static func + (left: DataPoint, right: DataPoint) -> DataPoint {
        return DataPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    // Vector subtraction
    public static func - (left: DataPoint, right: DataPoint) -> DataPoint {
        return DataPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    // Vector addition assignment
    public static func += (left: inout DataPoint, right: DataPoint) {
        left = left + right
    }
    
    // Vector subtraction assignment
    public static func -= (left: inout DataPoint, right: DataPoint) {
        left = left - right
    }
    
    // Vector negation
    public static prefix func - (vector: DataPoint) -> DataPoint {
        return DataPoint(x: -vector.x, y: -vector.y)
    }
}

// MARK: DataPoint extensions

extension DataPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            x: try container.decode(Double.self, forKey: .x),
            y: try container.decode(Double.self, forKey: .y)
        )
    }
}

extension DataPoint: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return (
            lhs.x == rhs.x
            && lhs.y == rhs.y
        )
    }
}

extension DataPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
