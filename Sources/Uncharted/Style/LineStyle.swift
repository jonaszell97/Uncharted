
import SwiftUI
import Toolbox
import Panorama

public struct LineStyle {
    public enum LineType: String, CaseIterable {
        /// A straight line from point to point.
        case straight
        
        /// A bezier curve from point to point.
        case curved
        
        /// A stepped line from point to point.
        case stepped
    }
    
    public enum LineFill: String, CaseIterable {
        case fill
        case stroke
        case fillAndStroke
    }
    
    /// The line type to use.
    public let type: LineType
    
    /// The fill type to use.
    public let fillType: LineFill
    
    /// The stroke to use.
    public let stroke: StrokeStyle
    
    /// The color of the line.
    public let color: ColorStyle
    
    /// Whether or not to ignore zero values.
    public let ignoreZero: Bool
    
    /// Whether or not to fill the shape.
    public let fillColor: ColorStyle
    
    /// Default initializer.
    public init(type: LineType, fillType: LineFill, stroke: StrokeStyle, color: ColorStyle, fillColor: ColorStyle, ignoreZero: Bool) {
        self.type = type
        self.fillType = fillType
        self.stroke = stroke
        self.color = color
        self.fillColor = fillColor
        self.ignoreZero = ignoreZero
    }
}

public extension LineStyle {
    /// The standard line style with a given color.
    static func straight(color: Color) -> LineStyle {
        .init(type: .straight, fillType: .stroke, stroke: .init(), color: .solid(color), fillColor: .solid(.clear), ignoreZero: false)
    }
    
    /// The standard line style with a given color.
    static func straight(color: ColorStyle) -> LineStyle {
        .init(type: .straight, fillType: .stroke, stroke: .init(), color: color, fillColor: .solid(.clear), ignoreZero: false)
    }
    
    /// The standard curved line style with a given color.
    static func curved(color: Color) -> LineStyle {
        .init(type: .curved, fillType: .stroke, stroke: .init(), color: .solid(color), fillColor: .solid(.clear), ignoreZero: false)
    }
    
    /// The standard curved line style with a given color.
    static func curved(color: ColorStyle) -> LineStyle {
        .init(type: .curved, fillType: .stroke, stroke: .init(), color: color, fillColor: .solid(.clear), ignoreZero: false)
    }
    
    /// The standard curved line style with a given color.
    static func stepped(color: Color) -> LineStyle {
        .init(type: .stepped, fillType: .stroke, stroke: .init(), color: .solid(color), fillColor: .solid(.clear), ignoreZero: false)
    }
    
    /// The standard curved line style with a given color.
    static func stepped(color: ColorStyle) -> LineStyle {
        .init(type: .stepped, fillType: .stroke, stroke: .init(), color: color, fillColor: .solid(.clear), ignoreZero: false)
    }
}

fileprivate struct LineStyleView: View {
    let style: LineStyle
    let points: [DataPoint]
    
    let xAxisParams: ComputedChartAxisData
    let yAxisParams: ComputedChartAxisData
    
    @Binding var animationProgress: Double
    @State var animationOffsetValues: [Double]
    @State var currentYBounds: (Double, Double)
    
    init(style: LineStyle,
         points: [DataPoint],
         xAxisParams: ComputedChartAxisData,
         yAxisParams: ComputedChartAxisData,
         animationProgress: Binding<Double>) {
        self.style = style
        self.points = points
        self.xAxisParams = xAxisParams
        self.yAxisParams = yAxisParams
        self._animationProgress = animationProgress
        self._animationOffsetValues = .init(initialValue: points.map { _ in 0.0 })
        self._currentYBounds = .init(initialValue: (yAxisParams.lowerBound, yAxisParams.upperBound))
    }
    
    var body: some View {
        ZStack {
            switch style.fillType {
            case .stroke:
                AnyLineShape(points: points, lineType: style.type,
                             xAxisParams: xAxisParams,
                             yBoundLower: currentYBounds.0,
                             yBoundUpper: currentYBounds.1,
                             isFilled: false,
                             animationProgress: animationProgress,
                             animationOffsets: animationOffsetValues)
                    .stroke(style.color.swiftUIShapeStyle, style: style.stroke)
            case .fill:
                AnyLineShape(points: points, lineType: style.type,
                             xAxisParams: xAxisParams,
                             yBoundLower: currentYBounds.0,
                             yBoundUpper: currentYBounds.1,
                             isFilled: true,
                             animationProgress: animationProgress,
                             animationOffsets: animationOffsetValues)
                    .fill(style.fillColor.swiftUIShapeStyle)
            case .fillAndStroke:
                AnyLineShape(points: points, lineType: style.type,
                             xAxisParams: xAxisParams,
                             yBoundLower: currentYBounds.0,
                             yBoundUpper: currentYBounds.1,
                             isFilled: true,
                             animationProgress: animationProgress,
                             animationOffsets: animationOffsetValues)
                    .fill(style.fillColor.swiftUIShapeStyle)
                AnyLineShape(points: points, lineType: style.type,
                             xAxisParams: xAxisParams,
                             yBoundLower: currentYBounds.0,
                             yBoundUpper: currentYBounds.1,
                             isFilled: false,
                             animationProgress: animationProgress,
                             animationOffsets: animationOffsetValues)
                    .stroke(style.color.swiftUIShapeStyle, style: style.stroke)
            }
        }
        .onChange(of: yAxisParams) { yAxisParams in
            var offsets = animationOffsetValues
            for i in 0..<points.count {
                let previousHeight = (points[i].y - currentYBounds.0) / (currentYBounds.1 - currentYBounds.0)
                let newHeight = (points[i].y - yAxisParams.lowerBound) / (yAxisParams.upperBound - yAxisParams.lowerBound)
                
                offsets[i] = newHeight - previousHeight
            }
            
            let sequence = AnimationSequence()
            sequence.append(animation: ChartState.chartTransitionAnimation,
                            duration: ChartState.chartTransitionAnimationDuration) {
                animationOffsetValues = offsets
            }
            sequence.append {
                currentYBounds = (yAxisParams.lowerBound, yAxisParams.upperBound)
                animationOffsetValues = points.map { _ in 0.0 }
            }
            
            sequence.execute()
        }
    }
}

internal extension LineStyle {
    func createLineView(points: [DataPoint],
                        xAxisParams: ComputedChartAxisData,
                        yAxisParams: ComputedChartAxisData,
                        animationProgress: Binding<Double>) -> some View {
        LineStyleView(style: self, points: points, xAxisParams: xAxisParams, yAxisParams: yAxisParams,
                      animationProgress: animationProgress)
    }
}

// MARK: LineStyle.LineType extensions

extension LineStyle.LineType: Codable {
    enum CodingKeys: String, CodingKey {
        case straight, curved, stepped
    }
    
    var codingKey: CodingKeys {
        switch self {
        case .straight: return .straight
        case .curved: return .curved
        case .stepped: return .stepped
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .straight:
            try container.encodeNil(forKey: .straight)
        case .curved:
            try container.encodeNil(forKey: .curved)
        case .stepped:
            try container.encodeNil(forKey: .stepped)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .straight:
            _ = try container.decodeNil(forKey: .straight)
            self = .straight
        case .curved:
            _ = try container.decodeNil(forKey: .curved)
            self = .curved
        case .stepped:
            _ = try container.decodeNil(forKey: .stepped)
            self = .stepped
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

extension LineStyle.LineType: Equatable {
    public static func ==(lhs: LineStyle.LineType, rhs: LineStyle.LineType) -> Bool {
        guard lhs.codingKey == rhs.codingKey else {
            return false
        }
        
        return true
    }
}

extension LineStyle.LineType: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codingKey.rawValue)
    }
}

// MARK: LineStyle.LineFill extensions

extension LineStyle.LineFill: Codable {
    enum CodingKeys: String, CodingKey {
        case fill, stroke, fillAndStroke
    }
    
    var codingKey: CodingKeys {
        switch self {
        case .fill: return .fill
        case .stroke: return .stroke
        case .fillAndStroke: return .fillAndStroke
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fill:
            try container.encodeNil(forKey: .fill)
        case .stroke:
            try container.encodeNil(forKey: .stroke)
        case .fillAndStroke:
            try container.encodeNil(forKey: .fillAndStroke)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .fill:
            _ = try container.decodeNil(forKey: .fill)
            self = .fill
        case .stroke:
            _ = try container.decodeNil(forKey: .stroke)
            self = .stroke
        case .fillAndStroke:
            _ = try container.decodeNil(forKey: .fillAndStroke)
            self = .fillAndStroke
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

extension LineStyle.LineFill: Equatable {
    public static func ==(lhs: LineStyle.LineFill, rhs: LineStyle.LineFill) -> Bool {
        guard lhs.codingKey == rhs.codingKey else {
            return false
        }
        
        return true
    }
}

extension LineStyle.LineFill: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codingKey.rawValue)
        
    }
}

// MARK: LineStyle extensions

extension LineStyle: Codable {
    enum CodingKeys: String, CodingKey {
        case type, fillType, stroke, color, fillColor, ignoreZero
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(fillType, forKey: .fillType)
        try container.encode(stroke, forKey: .stroke)
        try container.encode(color, forKey: .color)
        try container.encode(fillColor, forKey: .fillColor)
        try container.encode(ignoreZero, forKey: .ignoreZero)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            type: try container.decode(LineType.self, forKey: .type),
            fillType: try container.decode(LineFill.self, forKey: .fillType),
            stroke: try container.decode(StrokeStyle.self, forKey: .stroke),
            color: try container.decode(ColorStyle.self, forKey: .color),
            fillColor: try container.decode(ColorStyle.self, forKey: .fillColor),
            ignoreZero: try container.decode(Bool.self, forKey: .ignoreZero)
        )
    }
}

extension LineStyle: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return (
            lhs.type == rhs.type
            && lhs.stroke == rhs.stroke
            && lhs.color == rhs.color
            && lhs.ignoreZero == rhs.ignoreZero
        )
    }
}

extension LineStyle: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(stroke)
        hasher.combine(color)
        hasher.combine(ignoreZero)
    }
}


