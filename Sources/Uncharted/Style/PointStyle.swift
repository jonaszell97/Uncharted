
import SwiftUI
import Toolbox
import Panorama

/// Defines the appearance of a point marker.
public struct PointStyle {
    /// Defines the point's fill and stroke.
    public enum PointType: String, CaseIterable {
        /// Fill but do not stroke.
        case fill
        
        /// Stroke but do not fill.
        case stroke
        
        /// Apply both fill and stroke.
        case fillAndStroke
    }
    
    /// Defines the point's shape.
    public enum PointShape {
        /// A circle shape.
        case circle
        
        /// A square shape.
        case square
        
        /// A rounded square shape.
        case roundedSquare
        
        /// A diamond shape.
        case diamond
        
        /// A customizable shape.
        case custom(shape: any Shape)
    }
    
    /// Overall size of the point.
    public let pointSize: CGFloat
    
    /// Color of the border. Ignored if ``PointStyle/pointType-swift.property`` is ``PointStyle/PointType-swift.enum/fill``.
    public let borderColor: Color
    
    /// Fill color. Ignored if ``PointStyle/pointType-swift.property`` is ``PointStyle/PointType-swift.enum/stroke``.
    public let fillColor: Color
    
    /// Width of the stroke. Ignored if ``PointStyle/pointType-swift.property`` is ``PointStyle/PointType-swift.enum/fill``.
    public let lineWidth: CGFloat
    
    /// The point's fill and stroke style.
    public let pointType: PointType
    
    /// The point's shape.
    public let pointShape: PointShape
    
    /// Create a point style.
    ///
    /// - Parameters:
    ///   - pointSize: Overall size of the point.
    ///   - borderColor: Color of the border. Ignored if ``PointStyle/pointType-swift.property`` is ``PointStyle/PointType-swift.enum/fill``.
    ///   - fillColor: Fill color. Ignored if ``PointStyle/pointType-swift.property`` is ``PointStyle/PointType-swift.enum/stroke``.
    ///   - lineWidth: Width of the stroke. Ignored if ``PointStyle/pointType-swift.property`` is ``PointStyle/PointType-swift.enum/fill``.
    ///   - pointType: The point's fill and stroke style.
    ///   - pointShape: The point's shape.
    public init(pointSize: CGFloat = 5,
                borderColor: Color = .primary,
                fillColor: Color = Color(.gray),
                lineWidth: CGFloat = 3,
                pointType: PointType = .stroke,
                pointShape: PointShape = .circle) {
        self.pointSize = pointSize
        self.borderColor = borderColor
        self.fillColor = fillColor
        self.lineWidth = lineWidth
        self.pointType = pointType
        self.pointShape = pointShape
    }
}

extension PointStyle.PointShape: Shape {
    public func path(in rect: CGRect) -> Path {
        switch self {
        case .circle:
            return Circle().path(in: rect)
        case .square:
            return Rectangle().path(in: rect)
        case .roundedSquare:
            return RoundedRectangle(cornerRadius: rect.width * 0.25).path(in: rect)
        case .diamond:
            var path = Path()
            path.move(to: .init(x: rect.minX + rect.width * 0.5, y: rect.minY))
            path.addLine(to: .init(x: rect.minX + rect.width, y: rect.minY + rect.height * 0.5))
            path.addLine(to: .init(x: rect.minX + rect.width * 0.5, y: rect.minY + rect.height))
            path.addLine(to: .init(x: rect.minX, y: rect.minY + rect.height * 0.5))
            path.closeSubpath()
            
            return path
        case .custom(let shape):
            return shape.path(in: rect)
        }
    }
}

public extension PointStyle {
    /// A View for this point style.
    var view: some View {
        ZStack {
            switch self.pointType {
            case .fill:
                self.pointShape.fill(self.fillColor)
            case .stroke:
                self.pointShape.stroke(self.borderColor, style: self.swiftUIStrokeStyle)
            case .fillAndStroke:
                self.pointShape.fill(self.fillColor)
                    .border(self.borderColor, width: self.lineWidth)
            }
        }
        .frame(width: self.pointSize, height: self.pointSize)
    }
}

fileprivate struct PointStyleView: View {
    let style: PointStyle
    let points: [DataPoint]
    
    let xAxisParams: ComputedChartAxisData
    let yAxisParams: ComputedChartAxisData
    
    @Binding var animationProgress: Double
    @State var animationOffsetValues: [Double]
    @State var currentYBounds: (Double, Double)
    
    init(style: PointStyle,
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
            switch style.pointType {
            case .stroke:
                AnyPointsShape(points: points,
                               pointShape: style.pointShape,
                               pointSize: style.pointSize,
                               xAxisParams: xAxisParams,
                               yBoundLower: currentYBounds.0,
                               yBoundUpper: currentYBounds.1,
                               animationProgress: animationProgress,
                               animationOffsets: animationOffsetValues)
                .stroke(style.borderColor, style: style.swiftUIStrokeStyle)
            case .fill:
                AnyPointsShape(points: points, pointShape: style.pointShape,
                               pointSize: style.pointSize,
                               xAxisParams: xAxisParams,
                               yBoundLower: currentYBounds.0,
                               yBoundUpper: currentYBounds.1,
                               animationProgress: animationProgress,
                               animationOffsets: animationOffsetValues)
                .fill(style.fillColor)
            case .fillAndStroke:
                AnyPointsShape(points: points, pointShape: style.pointShape,
                               pointSize: style.pointSize,
                               xAxisParams: xAxisParams,
                               yBoundLower: currentYBounds.0,
                               yBoundUpper: currentYBounds.1,
                               animationProgress: animationProgress,
                               animationOffsets: animationOffsetValues)
                .fill(style.fillColor)
                AnyPointsShape(points: points, pointShape: style.pointShape,
                               pointSize: style.pointSize,
                               xAxisParams: xAxisParams,
                               yBoundLower: currentYBounds.0,
                               yBoundUpper: currentYBounds.1,
                               animationProgress: animationProgress,
                               animationOffsets: animationOffsetValues)
                .stroke(style.borderColor, style: style.swiftUIStrokeStyle)
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

internal extension PointStyle {
    func createPointsView(points: [DataPoint],
                          xAxisParams: ComputedChartAxisData,
                          yAxisParams: ComputedChartAxisData,
                          animationProgress: Binding<Double>) -> some View {
        PointStyleView(style: self, points: points, xAxisParams: xAxisParams,
                       yAxisParams: yAxisParams,
                       animationProgress: animationProgress)
    }
}

public extension PointStyle {
    /// The standard point style with a given color.
    static func standard(color: Color) -> PointStyle {
        .init(fillColor: color, pointType: .fill)
    }
    
    /// The standard point style with a given color.
    static func standard(color: ColorStyle) -> PointStyle {
        .init(fillColor: color.singleColor, pointType: .fill)
    }
    
    /// The SwiftUI stroke style for this point style.
    var swiftUIStrokeStyle: SwiftUI.StrokeStyle {
        .init(lineWidth: self.lineWidth)
    }
}

// MARK: PointStyle.PointType extensions

extension PointStyle.PointType: Codable {
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

extension PointStyle.PointType: Equatable {
    public static func ==(lhs: PointStyle.PointType, rhs: PointStyle.PointType) -> Bool {
        guard lhs.codingKey == rhs.codingKey else {
            return false
        }
        
        
        
        return true
    }
}

extension PointStyle.PointType: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codingKey.rawValue)
        
    }
}

// MARK: PointStyle.PointShape extensions

extension PointStyle.PointShape: Codable {
    enum CodingKeys: String, CodingKey {
        case circle, square, roundedSquare, diamond, custom
    }
    
    var codingKey: CodingKeys {
        switch self {
        case .circle: return .circle
        case .square: return .square
        case .roundedSquare: return .roundedSquare
        case .diamond: return .diamond
        case .custom: return .custom
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .circle:
            try container.encodeNil(forKey: .circle)
        case .square:
            try container.encodeNil(forKey: .square)
        case .roundedSquare:
            try container.encodeNil(forKey: .roundedSquare)
        case .diamond:
            try container.encodeNil(forKey: .diamond)
        case .custom(let shape):
            try container.encode(CodableShape(shape: shape), forKey: .custom)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .circle:
            _ = try container.decodeNil(forKey: .circle)
            self = .circle
        case .square:
            _ = try container.decodeNil(forKey: .square)
            self = .square
        case .roundedSquare:
            _ = try container.decodeNil(forKey: .roundedSquare)
            self = .roundedSquare
        case .diamond:
            _ = try container.decodeNil(forKey: .diamond)
            self = .diamond
        case .custom:
            let shape = try container.decode(CodableShape.self, forKey: .custom)
            self = .custom(shape: shape)
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

extension PointStyle.PointShape: Equatable {
    public static func ==(lhs: PointStyle.PointShape, rhs: PointStyle.PointShape) -> Bool {
        guard lhs.codingKey == rhs.codingKey else {
            return false
        }
        
        switch lhs {
        case .custom(let shape):
            guard case .custom(let shape_) = rhs else { return false }
            guard shape.path(in: .init(x: 0, y: 0, width: 1, height: 1)).description
                    == shape_.path(in: .init(x: 0, y: 0, width: 1, height: 1)).description
            else {
                return false
            }
        default: break
        }
        
        return true
    }
}

extension PointStyle.PointShape: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codingKey.rawValue)
        switch self {
        case .custom(let shape):
            hasher.combine(shape.path(in: .init(x: 0, y: 0, width: 1, height: 1)).cgPath)
        default: break
        }
    }
}

// MARK: PointStyle extensions

extension PointStyle: Codable {
    enum CodingKeys: String, CodingKey {
        case pointSize, borderColor, fillColor, lineWidth, pointType, pointShape
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pointSize, forKey: .pointSize)
        try container.encode(borderColor, forKey: .borderColor)
        try container.encode(fillColor, forKey: .fillColor)
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encode(pointType, forKey: .pointType)
        try container.encode(pointShape, forKey: .pointShape)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            pointSize: try container.decode(CGFloat.self, forKey: .pointSize),
            borderColor: try container.decode(Color.self, forKey: .borderColor),
            fillColor: try container.decode(Color.self, forKey: .fillColor),
            lineWidth: try container.decode(CGFloat.self, forKey: .lineWidth),
            pointType: try container.decode(PointType.self, forKey: .pointType),
            pointShape: try container.decode(PointShape.self, forKey: .pointShape)
        )
    }
}

extension PointStyle: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return (
            lhs.pointSize == rhs.pointSize
            && lhs.borderColor == rhs.borderColor
            && lhs.fillColor == rhs.fillColor
            && lhs.lineWidth == rhs.lineWidth
            && lhs.pointType == rhs.pointType
            && lhs.pointShape == rhs.pointShape
        )
    }
}

extension PointStyle: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pointSize)
        hasher.combine(borderColor)
        hasher.combine(fillColor)
        hasher.combine(lineWidth)
        hasher.combine(pointType)
        hasher.combine(pointShape)
    }
}
