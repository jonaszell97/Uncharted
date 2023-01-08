
import SwiftUI

internal struct ComputedChartAxisData {
    /// The lower bound of this axis.
    let lowerBound: Double
    
    /// The upper bound of this axis.
    let upperBound: Double
    
    /// The steps size of this axis.
    let stepSize: Double
    
    /// The axis labels.
    let labels: [String]
    
    /// Default initializer.
    init(lowerBound: Double, upperBound: Double, stepSize: Double, labels: [String]) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.stepSize = stepSize
        self.labels = labels
    }
}

internal struct ComputedChartData {
    /// The minimum data point of all series in this dataset.
    let min: DataPoint
    
    /// The maximum data point of all series in this dataset.
    let max: DataPoint
    
    /// The x-axis configuration.
    let xAxisParams: ComputedChartAxisData
    
    /// The y-axis configuration.
    let yAxisParams: ComputedChartAxisData
    
    /// All x values contained in the data set, sorted by magnitude.
    let sortedXValues: [Double]
    
    /// The first data point of the next subset for each series, used for drawing connecting lines between subsets.
    let adjacentDataPoints: [String: [DataPoint]]
}

public class ChartData {
    /// The configuration of this chart.
    public let config: ChartConfig
    
    /// The data series to use for this chart.
    public let series: [DataSeries]
    
    /// The computed chart parameters.
    internal var computedParameters: ComputedChartData
    
    /// Default initializer.
    public init(config: ChartConfig = .init(), series: [DataSeries]) {
        self.config = config
        self.series = series
        self.computedParameters = Self.computeInternalParameters(config: config, series: series)
    }
    
    internal init(config: ChartConfig, series: [DataSeries], adjacentDataPoints: [String: [DataPoint]]) {
        self.config = config
        self.series = series
        self.computedParameters = Self.computeInternalParameters(config: config, series: series, adjacentDataPoints: adjacentDataPoints)
    }
}

public extension ChartData {
    /// Empty chart data instance used for uninitialized charts.
    static let empty = ChartData(series: [])
    
    /// The default colors.
    static let defaultColors: [Color] = [
        .red, .blue, .green, .orange, .purple, .brown, .pink, .cyan, .indigo, .mint
    ]
}

public extension ChartData {
    /// Whether or not this data set is empty.
    var isEmpty: Bool {
        series.allSatisfy { $0.isEmpty }
    }
    
    /// Create a subset of this chart data within the given range of x values..
    func subset<E>(xrange: E) -> ChartData
        where E: RangeExpression, E.Bound == Double
    {
        .init(config: config, series: series.map { $0.subset(xrange: xrange) })
    }
    
    /// Create a subset of this chart data within the given range of x values..
    internal func subset<E>(xrange: E, adjacentDataPoints: [String: [DataPoint]]) -> ChartData
        where E: RangeExpression, E.Bound == Double
    {
        .init(config: config, series: series.map { $0.subset(xrange: xrange) }, adjacentDataPoints: adjacentDataPoints)
    }
    
    /// Whether or not this series contains any values in the given range.
    func containsAnyValue<E>(in xrange: E) -> Bool
        where E: RangeExpression, E.Bound == Double
    {
        series.first { $0.containsAnyValue(in: xrange) } != nil
    }
}

extension ChartData {
    /// Compute the internal chart parameters.
    static internal func computeInternalParameters(config: ChartConfig, series: [DataSeries],
                                                   adjacentDataPoints: [String: [DataPoint]]? = nil) -> ComputedChartData {
        guard (series.first { !$0.isEmpty }) != nil else {
            return .init(min: .zero, max: .zero,
                         xAxisParams: .init(lowerBound: 0, upperBound: 0, stepSize: 0, labels: []),
                         yAxisParams: .init(lowerBound: 0, upperBound: 0, stepSize: 0, labels: []),
                         sortedXValues: [],
                         adjacentDataPoints: adjacentDataPoints ?? [:])
        }
        
        var minX = Double.infinity
        var minY = Double.infinity
        var maxX = -Double.infinity
        var maxY = -Double.infinity
        
        var xValues = Set<Double>()
        for series in series {
            for dataPoint in series.data {
                xValues.insert(dataPoint.x)
            }
            
            minX = Swift.min(minX, series.min.x)
            minY = Swift.min(minY, series.min.y)
            maxX = Swift.max(maxX, series.max.x)
            maxY = Swift.max(maxY, series.max.y)
        }
        
        if let adjacentDataPoints {
            for (_, adjacentPoints) in adjacentDataPoints {
                for next in adjacentPoints {
                    guard next.x >= minX else {
                        continue
                    }
                    
                    minY = Swift.min(minY, next.y)
                    maxY = Swift.max(maxY, next.y)
                }
            }
        }
        
        if config.cumulateYValuesPerSeries {
            for xValue in xValues {
                var ySumPositive = 0.0
                var ySumNegative = 0.0
                
                for series in series {
                    if let yValue = series.yValue(for: xValue) {
                        if yValue > 0 {
                            ySumPositive += yValue
                        }
                        else {
                            ySumNegative += yValue
                        }
                    }
                }
                
                if ySumPositive > 0 {
                    maxY = max(maxY, ySumPositive)
                }
                
                if ySumNegative < 0 {
                    minY = min(minY, ySumNegative)
                }
            }
        }
        
        let (min, max) = (DataPoint(x: minX, y: minY), DataPoint(x: maxX, y: maxY))
        let xAxisParams = config.xAxisConfig._axisParameters(minimumValue: min.x, maximumValue: max.x)
        let yAxisParams = config.yAxisConfig._axisParameters(minimumValue: min.y, maximumValue: max.y)
        
        return ComputedChartData(min: min, max: max,
                                 xAxisParams: xAxisParams,
                                 yAxisParams: yAxisParams,
                                 sortedXValues: xValues.map { $0 }.sorted(),
                                 adjacentDataPoints: adjacentDataPoints ?? [:])
    }
}

// MARK: ChartData extensions

public extension ChartData {
    /// Hash value of this chart's data.
    var dataHash: Int {
        var hasher = Hasher()
        for series in self.series {
            hasher.combine(series)
        }
        
        return hasher.finalize()
    }
}

// MARK: ComputedChartAxisData extensions

extension ComputedChartAxisData: Codable {
    enum CodingKeys: String, CodingKey {
        case lowerBound, upperBound, stepSize, labels
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lowerBound, forKey: .lowerBound)
        try container.encode(upperBound, forKey: .upperBound)
        try container.encode(stepSize, forKey: .stepSize)
        try container.encode(labels, forKey: .labels)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            lowerBound: try container.decode(Double.self, forKey: .lowerBound),
            upperBound: try container.decode(Double.self, forKey: .upperBound),
            stepSize: try container.decode(Double.self, forKey: .stepSize),
            labels: try container.decode(Array<String>.self, forKey: .labels)
        )
    }
}

extension ComputedChartAxisData: Equatable {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return (
            lhs.lowerBound == rhs.lowerBound
            && lhs.upperBound == rhs.upperBound
            && lhs.stepSize == rhs.stepSize
            && lhs.labels == rhs.labels
        )
    }
}

extension ComputedChartAxisData: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(lowerBound)
        hasher.combine(upperBound)
        hasher.combine(stepSize)
        hasher.combine(labels)
    }
}
