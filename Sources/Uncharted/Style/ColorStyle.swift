
import SwiftUI
import Toolbox

/// Defines the fill style for shapes.
public enum ColorStyle {
    /// Solid, single-color fill.
    case solid(_ color: Color)
    
    /// Linear gradient fill.
    case gradient(stops: [Gradient.Stop])
}

internal extension ColorStyle {
    var singleColor: Color {
        switch self {
        case .solid(let color):
            return color
        case .gradient(let stops):
            return stops.first!.color
        }
    }
}

internal extension ColorStyle {
    var swiftUIShapeStyle: AnyShapeStyle {
        switch self {
        case .solid(let color):
            return .init(color)
        case .gradient(let stops):
            return .init(LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing))
        }
    }
}

// MARK: ColorStyle extensions

extension ColorStyle: Codable {
    enum CodingKeys: String, CodingKey {
        case solid, gradient
    }
    
    var codingKey: CodingKeys {
        switch self {
        case .solid: return .solid
        case .gradient: return .gradient
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .solid(let color):
            try container.encode(color, forKey: .solid)
        case .gradient(let stops):
            try container.encode(stops, forKey: .gradient)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .solid:
            let color = try container.decode(Color.self, forKey: .solid)
            self = .solid(color)
        case .gradient:
            let stops = try container.decode(Array<Gradient.Stop>.self, forKey: .gradient)
            self = .gradient(stops: stops)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode enum."
                )
            )
        }
    }
}

extension ColorStyle: Equatable {
    public static func ==(lhs: ColorStyle, rhs: ColorStyle) -> Bool {
        guard lhs.codingKey == rhs.codingKey else {
            return false
        }
        
        switch lhs {
        case .solid(let color):
            guard case .solid(let color_) = rhs else { return false }
            guard color == color_ else { return false }
        case .gradient(let stops):
            guard case .gradient(let stops_) = rhs else { return false }
            guard stops == stops_ else { return false }
        }
        
        return true
    }
}

extension ColorStyle: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codingKey.rawValue)
        switch self {
        case .solid(let color):
            hasher.combine(color)
        case .gradient(let stops):
            hasher.combine(stops)
        }
    }
}


