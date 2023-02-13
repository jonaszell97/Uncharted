
import SwiftUI

/// A named series of related data points that should be charted together.
public struct DataSeries {
    /// The name of this data series.
    public let name: String
    
    /// The data contained in this series.
    public let data: [DataPoint]
    
    /// The markers associated with this series.
    public let markers: [ChartMarker]
    
    /// The color of this series.
    public let color: ColorStyle
    
    /// The point style for this series.
    public let pointStyle: PointStyle?
    
    /// The line style for this series.
    public let lineStyle: LineStyle?
    
    /// The minimum data point of this series.
    internal let min: DataPoint
    
    /// The maximum data point of this series.
    internal let max: DataPoint
    
    /// Create a data series.
    ///
    /// - Parameters:
    ///   - name: The name of this data series.
    ///   - data: The data contained in this series.
    ///   - markers: The markers associated with this series.
    ///   - color: The color of this series.
    ///   - pointStyle: The point style for this series.
    ///   - lineStyle: The line style for this series.
    public init(name: String,
                data: [DataPoint],
                markers: [ChartMarker] = [],
                color: ColorStyle,
                pointStyle: PointStyle?,
                lineStyle: LineStyle?) {
        self.name = name
        self.data = data.sorted { $0.x < $1.x }
        self.markers = markers
        self.color = color
        self.pointStyle = pointStyle
        self.lineStyle = lineStyle
        
        let (min, max) = Self._minAndMax(of: data)
        self.min = min
        self.max = max
    }
    
    /// Create a data series with default line and point styles.
    ///
    /// - Parameters:
    ///   - name: The name of this data series.
    ///   - data: The data contained in this series.
    ///   - markers: The markers associated with this series.
    ///   - color: The color of this series.
    public init(name: String,
                data: [DataPoint],
                markers: [ChartMarker] = [],
                color: ColorStyle) {
        self.name = name
        self.data = data.sorted { $0.x < $1.x }
        self.markers = markers
        self.color = color
        self.pointStyle = .standard(color: color)
        self.lineStyle = .straight(color: color)
        
        let (min, max) = Self._minAndMax(of: data)
        self.min = min
        self.max = max
    }
    
    /// Create a data series from an array of y-values.
    ///
    /// - Parameters:
    ///   - name: The name of this data series.
    ///   - yValues: The y-values contained in this series.
    ///   - markers: The markers associated with this series.
    ///   - color: The color of this series.
    ///   - pointStyle: The point style for this series.
    ///   - lineStyle: The line style for this series.
    public init(name: String,
                yValues: [Double],
                markers: [ChartMarker] = [],
                color: ColorStyle,
                pointStyle: PointStyle?,
                lineStyle: LineStyle?) {
        self.name = name
        self.data = yValues.enumerated().map { .init(x: Double($0.offset), y: $0.element) }
        self.markers = markers
        self.color = color
        self.pointStyle = pointStyle
        self.lineStyle = lineStyle
        
        let (min, max) = Self._minAndMax(of: data)
        self.min = min
        self.max = max
    }
    
    /// Create a data series from an array of y-values with default line and point styles..
    ///
    /// - Parameters:
    ///   - name: The name of this data series.
    ///   - yValues: The y-values contained in this series.
    ///   - markers: The markers associated with this series.
    ///   - color: The color of this series.
    public init(name: String,
                yValues: [Double],
                markers: [ChartMarker] = [],
                color: ColorStyle) {
        self.name = name
        self.data = yValues.enumerated().map { .init(x: Double($0.offset), y: $0.element) }
        self.markers = markers
        self.color = color
        self.pointStyle = .standard(color: color)
        self.lineStyle = .straight(color: color)
        
        let (min, max) = Self._minAndMax(of: data)
        self.min = min
        self.max = max
    }
    
    /// The minimum data point of this series.
    private static func _minAndMax(of data: [DataPoint]) -> (DataPoint, DataPoint) {
        var minX = Double.infinity
        var minY = Double.infinity
        var maxX = -Double.infinity
        var maxY = -Double.infinity
        
        for pt in data {
            minX = Swift.min(minX, pt.x)
            minY = Swift.min(minY, pt.y)
            maxX = Swift.max(maxX, pt.x)
            maxY = Swift.max(maxY, pt.y)
        }
        
        return (.init(x: minX, y: minY), .init(x: maxX, y: maxY))
    }
}

public extension DataSeries {
    /// Whether or not this data series is empty.
    var isEmpty: Bool {
        data.isEmpty
    }
    
    /// Create a subset of this data series within the given range of x values.
    func subset<E>(xrange: E) -> DataSeries
        where E: RangeExpression, E.Bound == Double
    {
        let filteredData = self.data.filter { xrange.contains($0.x) }
        let filteredMarkers = self.markers.filter { $0.isLocatedInRange(xrange: xrange) }
        
        return .init(name: name,
                     data: filteredData,
                     markers: filteredMarkers,
                     color: color,
                     pointStyle: pointStyle,
                     lineStyle: lineStyle)
    }
    
    /// Get the y-value for a specific x-value.
    func yValue(for xValue: Double) -> Double? {
        data.first { $0.x.isEqual(to: xValue) }?.y
    }
    
    /// Whether or not this series contains any values in the given range.
    func containsAnyValue<E>(in xrange: E) -> Bool
        where E: RangeExpression, E.Bound == Double
    {
        data.first { xrange.contains($0.x) } != nil
    }
}

// MARK: DataSeries extensions

extension DataSeries: Codable {
    enum CodingKeys: String, CodingKey {
        case name, color, data, pointStyle, lineStyle
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(data, forKey: .data)
        try container.encode(color, forKey: .color)
        try container.encode(pointStyle, forKey: .pointStyle)
        try container.encode(lineStyle, forKey: .lineStyle)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decode(String.self, forKey: .name),
            data: try container.decode(Array<DataPoint>.self, forKey: .data),
            color: try container.decode(ColorStyle.self, forKey: .color),
            pointStyle: try container.decode(PointStyle.self, forKey: .pointStyle),
            lineStyle: try container.decode(LineStyle.self, forKey: .lineStyle)
        )
    }
}

extension DataSeries: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return (
            lhs.name == rhs.name
            && lhs.data == rhs.data
            && lhs.color == rhs.color
            && lhs.pointStyle == rhs.pointStyle
            && lhs.lineStyle == rhs.lineStyle
        )
    }
}

extension DataSeries: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(data)
        hasher.combine(color)
        hasher.combine(pointStyle)
        hasher.combine(lineStyle)
    }
}
