
import SwiftUI

/// Defines the appearance of a chart's background grid for a single axis.
public struct GridStyle {
    /// The color of the grid lines.
    public let lineColor: Color
    
    /// The width of the grid lines.
    public let lineWidth: CGFloat
    
    /// The dash width of the grid lines.
    public let dash: [CGFloat]
    
    /// The dash phase of the grid lines.
    public let dashPhase: CGFloat
    
    /// Create a grid style.
    ///
    /// - Parameters:
    ///   - lineColor: The color of the grid lines.
    ///   - lineWidth: The width of the grid lines.
    ///   - dash: The dash width of the grid lines.
    ///   - dashPhase: The dash phase of the grid lines.
    public init(lineColor: Color,
                lineWidth: CGFloat,
                dash: [CGFloat],
                dashPhase: CGFloat) {
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.dash = dash
        self.dashPhase = dashPhase
    }
}

public extension GridStyle {
    /// Default x-axis grid style.
    static let defaultXAxisStyle: GridStyle = .init(lineColor: .primary.opacity(0.20),
                                                    lineWidth: 0.75,
                                                    dash: [2],
                                                    dashPhase: 0)
    
    /// Default y-axis grid style.
    static let defaultYAxisStyle: GridStyle = .init(lineColor: .primary.opacity(0.20),
                                                    lineWidth: 0.75,
                                                    dash: [],
                                                    dashPhase: 0)
    
    /// Hidden grid style.
    static let hidden: GridStyle = .init(lineColor: .clear, lineWidth: 0, dash: [], dashPhase: 0)
}

internal extension GridStyle {
    var swiftUIStrokeStyle: SwiftUI.StrokeStyle {
        .init(lineWidth: lineWidth, dash: dash, dashPhase: dashPhase)
    }
    
    func swiftUIStrokeStyle(lineWidth: CGFloat) -> SwiftUI.StrokeStyle {
        .init(lineWidth: lineWidth, dash: dash, dashPhase: dashPhase)
    }
}

// MARK: GridStyle extensions

extension GridStyle: Codable {
    enum CodingKeys: String, CodingKey {
        case lineColor, lineWidth, dash, dashPhase
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lineColor, forKey: .lineColor)
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encode(dash, forKey: .dash)
        try container.encode(dashPhase, forKey: .dashPhase)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            lineColor: try container.decode(Color.self, forKey: .lineColor),
            lineWidth: try container.decode(CGFloat.self, forKey: .lineWidth),
            dash: try container.decode(Array<CGFloat>.self, forKey: .dash),
            dashPhase: try container.decode(CGFloat.self, forKey: .dashPhase)
        )
    }
}

extension GridStyle: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return (
            lhs.lineColor == rhs.lineColor
            && lhs.lineWidth == rhs.lineWidth
            && lhs.dash == rhs.dash
            && lhs.dashPhase == rhs.dashPhase
        )
    }
}

extension GridStyle: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(lineColor)
        hasher.combine(lineWidth)
        hasher.combine(dash)
        hasher.combine(dashPhase)
    }
}
