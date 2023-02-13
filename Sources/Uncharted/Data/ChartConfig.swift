
import SwiftUI
import Toolbox

/// Defines how the lowest value of a chart axis is determined.
public enum ChartAxisBaseline {
    /// Always use zero as a baseline.
    case zero
    
    /// Use the minimum value of the chart as the baseline.
    case minimumValue
    
    /// Choose the maximum of the given value and the minimum value of the dataset.
    case clamp(upperBound: Double)
}

/// Defines how the highest value of a chart axis is determined.
public enum ChartAxisTopline {
    /// Use the maximum value of the dataset as the topline.
    case maximumValue
    
    /// Choose the minimum of the given value and the maximum value of the dataset.
    case clamp(lowerBound: Double)
}

/// Defines the step size between two data points on a single axis.
public enum ChartAxisStep {
    /// Use a fixed step size for the axis labels.
    case fixed(Double)
    
    /// Automatically determine the appropriate step size based on the axis values.
    case automatic(preferredSteps: Int = 4)
}

/// Defines a chart's segmentation and scrolling behaviour.
public enum ChartScrollingBehaviour {
    /// No scrolling, all data is displayed at once.
    case noScrolling
    
    /// Segmented scrolling with pages that can be swiped between.
    case segmented(visibleValueRange: Double)
    
    /// Continuous scrolling.
    case continuous(visibleValueRange: Double)
}

/// Configure the appearance and behaviour of a chart's axes.
public struct ChartAxisConfig {
    /// The title of this axis.
    public var title: String?
    
    /// Whether or not this axis is visible.
    public var visible: Bool
    
    /// How the lower bound of this axis is determined.
    public var baseline: ChartAxisBaseline
    
    /// How the upper bound of this axis is determined.
    public var topline: ChartAxisTopline
    
    /// The step of this axis.
    public var step: ChartAxisStep
    
    /// Whether scrolling is contiguous or paged.
    public var scrollingBehaviour: ChartScrollingBehaviour
    
    /// The vertical translation threshold for scrolling between pages.
    public var scrollingThresholdTranslation: Double
    
    /// The title font of this axis.
    public var titleFont: Font
    
    /// The font color of the title of this axis.
    public var titleFontColor: Color
    
    /// The label font of this axis.
    public var labelFont: Font
    
    /// The font color of the labels on this axis.
    public var labelFontColor: Color
    
    /// The size of this axis.
    public var size: CGFloat?
    
    /// The grid style of this axis.
    public var gridStyle: GridStyle
    
    /// The formatter for data labels.
    public var labelFormatter: DataFormatter
    
    /// Default initializer.
    private init(title: String? = nil,
                 visible: Bool = true,
                 baseline: ChartAxisBaseline = .minimumValue,
                 topline: ChartAxisTopline = .maximumValue,
                 step: ChartAxisStep = .automatic(),
                 scrollingBehaviour: ChartScrollingBehaviour = .noScrolling,
                 scrollingThresholdTranslation: Double = 50,
                 titleFont: Font = .title,
                 titleFontColor: Color = .primary,
                 labelFont: Font = .caption,
                 labelFontColor: Color = .primary.opacity(0.5),
                 size: CGFloat? = nil,
                 gridStyle: GridStyle = .defaultXAxisStyle,
                 labelFormatter: DataFormatter = FloatingPointFormatter.standard) {
        self.title = title
        self.visible = visible
        self.baseline = baseline
        self.topline = topline
        self.step = step
        self.scrollingBehaviour = scrollingBehaviour
        self.scrollingThresholdTranslation = scrollingThresholdTranslation
        self.titleFont = titleFont
        self.titleFontColor = titleFontColor
        self.labelFont = labelFont
        self.labelFontColor = labelFontColor
        self.size = size
        self.gridStyle = gridStyle
        self.labelFormatter = labelFormatter
    }
    
    
    /// The default range of values to display at a time on this axis.
    public var visibleValueRange: Double? {
        get {
            switch scrollingBehaviour {
            case .noScrolling:
                return nil
            case .segmented(let visibleValueRange):
                return visibleValueRange
            case .continuous(let visibleValueRange):
                return visibleValueRange
            }
        }
        set {
            guard let newValue else {
                self.scrollingBehaviour = .noScrolling
                return
            }
            
            switch scrollingBehaviour {
            case .noScrolling:
                return
            case .segmented:
                self.scrollingBehaviour = .segmented(visibleValueRange: newValue)
            case .continuous:
                self.scrollingBehaviour = .continuous(visibleValueRange: newValue)
            }
        }
    }
    
    /// Create an X-axis configuration.
    ///
    /// - Parameters:
    ///   - title: The title of this axis.
    ///   - visible: Whether or not this axis is visible.
    ///   - baseline: How the lower bound of this axis is determined.
    ///   - topline: How the upper bound of this axis is determined.
    ///   - step: The step of this axis.
    ///   - scrollingBehaviour: Whether scrolling is contiguous or paged.
    ///   - scrollingThresholdTranslation: The vertical translation threshold for scrolling between pages.
    ///   - titleFont: The title font of this axis.
    ///   - titleFontColor: The font color of the title of this axis.
    ///   - labelFont: The label font of this axis.
    ///   - labelFontColor: The font color of the labels on this axis.
    ///   - size: The size of this axis.
    ///   - gridStyle:  The grid style of this axis.
    ///   - labelFormatter: The formatter for data labels.
    /// - Returns: The axis configuration.
    public static func xAxis(title: String? = nil,
                             visible: Bool = true,
                             baseline: ChartAxisBaseline = .minimumValue,
                             topline: ChartAxisTopline = .maximumValue,
                             step: ChartAxisStep = .automatic(),
                             scrollingBehaviour: ChartScrollingBehaviour = .noScrolling,
                             scrollingThresholdTranslation: Double = 50,
                             titleFont: Font = .title,
                             titleFontColor: Color = .primary,
                             labelFont: Font = .caption,
                             labelFontColor: Color = .primary.opacity(0.5),
                             size: CGFloat? = nil,
                             gridStyle: GridStyle = .defaultXAxisStyle,
                             labelFormatter: DataFormatter = FloatingPointFormatter.standard) -> ChartAxisConfig {
        return .init(title: title, visible: visible, baseline: baseline, topline: topline, step: step,
                     scrollingBehaviour: scrollingBehaviour,
                     scrollingThresholdTranslation: scrollingThresholdTranslation,
                     titleFont: titleFont, titleFontColor: titleFontColor,
                     labelFont: labelFont, labelFontColor: labelFontColor,
                     size: size, gridStyle: gridStyle,
                     labelFormatter: labelFormatter)
    }
    
    /// Create a Y-axis configuration.
    ///
    /// - Parameters:
    ///   - title: The title of this axis.
    ///   - visible: Whether or not this axis is visible.
    ///   - baseline: How the lower bound of this axis is determined.
    ///   - topline: How the upper bound of this axis is determined.
    ///   - step: The step of this axis.
    ///   - titleFont: The title font of this axis.
    ///   - titleFontColor: The font color of the title of this axis.
    ///   - labelFont: The label font of this axis.
    ///   - labelFontColor: The font color of the labels on this axis.
    ///   - size: The size of this axis.
    ///   - gridStyle:  The grid style of this axis.
    ///   - labelFormatter: The formatter for data labels.
    /// - Returns: The axis configuration.
    public static func yAxis(title: String? = nil,
                             visible: Bool = true,
                             baseline: ChartAxisBaseline = .zero,
                             topline: ChartAxisTopline = .maximumValue,
                             step: ChartAxisStep = .automatic(),
                             titleFont: Font = .title,
                             titleFontColor: Color = .primary,
                             labelFont: Font = .caption,
                             labelFontColor: Color = .primary.opacity(0.5),
                             size: CGFloat? = nil,
                             gridStyle: GridStyle = .defaultYAxisStyle,
                             labelFormatter: DataFormatter = FloatingPointFormatter.standard) -> ChartAxisConfig {
        return .init(title: title, visible: visible, baseline: baseline, topline: topline, step: step,
                     scrollingBehaviour: .noScrolling,
                     titleFont: titleFont, titleFontColor: titleFontColor,
                     labelFont: labelFont, labelFontColor: labelFontColor,
                     size: size, gridStyle: gridStyle,
                     labelFormatter: labelFormatter)
    }
}

/// An action that is performed when the user taps on a chart.
public enum ChartTapAction {
    /// Highlight only the closest datapoint.
    case highlightSingle
    
    /// Toggle highlighting for the closest datapoint.
    case highlightMultiple
    
    /// Invoke a custom callback with the closest data point.
    case custom(callback: (DataSeries, DataPoint) -> Void)
}

/// Common configuration for all chart types.
public class ChartConfig {
    /// The x-axis configuration.
    public var xAxisConfig: ChartAxisConfig
    
    /// The y-axis configuration.
    public var yAxisConfig: ChartAxisConfig
    
    /// Actions that are invoked when the user taps a data point.
    public var tapActions: [ChartTapAction]
    
    /// The padding to apply to the chart.
    public var padding: EdgeInsets
    
    /// The animation that is used for chart transitions.
    public var animation: Animation?
    
    /// The text that is displayed when no data is available.
    public var noDataAvailableText: String
    
    /// The x-value that is initially visible.
    public var initialXValue: Double?
    
    /// Create a chart configuration.
    ///
    /// - Parameters:
    ///   - xAxisConfig: The x-axis configuration.
    ///   - yAxisConfig: The y-axis configuration.
    ///   - tapActions: Actions that are invoked when the user taps a data point.
    ///   - initialXValue: The x-value that is initially visible.
    ///   - padding: The padding to apply to the chart.
    ///   - animation: The animation that is used for chart transitions.
    ///   - noDataAvailableText: The text that is displayed when no data is available.
    public init(xAxisConfig: ChartAxisConfig = .xAxis(),
                yAxisConfig: ChartAxisConfig = .yAxis(),
                tapActions: [ChartTapAction] = [.highlightSingle],
                initialXValue: Double? = nil,
                padding: EdgeInsets = .init(),
                animation: Animation? = .easeInOut,
                noDataAvailableText: String = "-") {
        self.xAxisConfig = xAxisConfig
        self.yAxisConfig = yAxisConfig
        self.tapActions = tapActions
        self.initialXValue = initialXValue
        self.padding = padding
        self.animation = animation
        self.noDataAvailableText = noDataAvailableText
    }
    
    /// Whether or not the data for this chart is accumulated by its x-value.
    internal var cumulateYValuesPerSeries: Bool { false }
    
    /// Whether or not the first data point of the next subset should be considered for axis bounds calculations, e.g. for line graphs.
    internal var considerNextDataPointForYBounds: Bool { false }
    
    /// Whether or not this chart is segmented in the x direction.
    internal var isHorizontallySegmented: Bool {
        guard case .segmented = xAxisConfig.scrollingBehaviour else {
            return false
        }
        
        return true
    }
    
    /// Whether or not this chart is continuously scrollable in the x direction.
    internal var isContinuouslyHorizontallyScrollable: Bool {
        guard case .continuous = xAxisConfig.scrollingBehaviour else {
            return false
        }
        
        return true
    }
}

public extension ChartAxisStep {
    /// A fixed step size of one.
    static let one = Self.fixed(1)
}

internal extension ChartAxisConfig {
    /// Calculate the axis range for a given set of values.
    func _axisParameters(minimumValue: Double, maximumValue: Double) -> ComputedChartAxisData {
        var labels: [String] = []
        
        let lowerBound: Double
        switch self.baseline {
        case .zero:
            lowerBound = min(0, minimumValue)
        case .minimumValue:
            lowerBound = minimumValue
        case .clamp(let upperBound):
            lowerBound = min(minimumValue, upperBound)
        }
        
        let upperBound: Double
        switch self.topline {
        case .maximumValue:
            upperBound = maximumValue
        case .clamp(let lowerBound):
            upperBound = max(maximumValue, lowerBound)
        }
        
        let stepSize: Double
        switch self.step {
        case .fixed(let step):
            stepSize = step
        case .automatic(let preferredSteps):
            let preferredSteps = max(1, preferredSteps)
            let distance = upperBound.isEqual(to: lowerBound) ? 1 : upperBound - lowerBound
            let upperMagnitude = Int(log10(distance).rounded(.down))
            
            let possibleSteps: [Double] = [0.1, 0.5, 1, 2, 2.5, 5, 10].map { $0 * pow(10, Double(upperMagnitude)) }
            
            var closestStep: Double = 1
            var smallestDelta: Double = .infinity
            
            for step in possibleSteps {
                let newLowerBound = lowerBound.roundedDown(toMultipleOf: step)
                
                var newUpperBound = upperBound.roundedUp(toMultipleOf: step)
                if upperBound.truncatingRemainder(dividingBy: step).isZero {
                    newUpperBound += step
                }
                
                let distance = newUpperBound - newLowerBound
                
                let requiredSteps = (distance / step).rounded(.up)
                let delta = abs(Double(preferredSteps) - requiredSteps)
                
                if delta < smallestDelta {
                    closestStep = step
                    smallestDelta = delta
                }
                else if delta.isEqual(to: smallestDelta), step < closestStep {
                    closestStep = step
                    smallestDelta = delta
                }
            }
            
            stepSize = closestStep
        }
        
        var current = lowerBound.roundedDown(toMultipleOf: stepSize)
        
        let first = current
        let end = upperBound.roundedUp(toMultipleOf: stepSize)
        
        while current <= end {
            labels.append(self.labelFormatter(current))
            current += stepSize
        }
        
        if upperBound.truncatingRemainder(dividingBy: stepSize).isZero {
            labels.append(self.labelFormatter(current))
            return .init(lowerBound: first, upperBound: current, stepSize: stepSize, labels: labels)
        }
        
        return .init(lowerBound: first, upperBound: end, stepSize: stepSize, labels: labels)
    }
    
    /// Calculate the labels for given lower and upper bounds.
    func _axisLabels(lowerBound: Double, upperBound: Double, stepSize: Double) -> [String] {
        var labels: [String] = []
        
        var current = lowerBound.roundedDown(toMultipleOf: stepSize)
        let end = upperBound.roundedUp(toMultipleOf: stepSize)
        
        while current <= end {
            labels.append(self.labelFormatter(current))
            current += stepSize
        }
        
        if upperBound.truncatingRemainder(dividingBy: stepSize).isZero {
            labels.append(self.labelFormatter(current))
        }
        
        return labels
    }
}

// MARK: ChartAxisBaseline extensions

extension ChartAxisBaseline: Codable {
    enum CodingKeys: String, CodingKey {
        case zero, minimumValue, clamp
    }
    
    var codingKey: CodingKeys {
        switch self {
        case .zero: return .zero
        case .minimumValue: return .minimumValue
        case .clamp: return .clamp
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .zero:
            try container.encodeNil(forKey: .zero)
        case .minimumValue:
            try container.encodeNil(forKey: .minimumValue)
        case .clamp(let upperBound):
            try container.encode(upperBound, forKey: .clamp)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .zero:
            _ = try container.decodeNil(forKey: .zero)
            self = .zero
        case .minimumValue:
            _ = try container.decodeNil(forKey: .minimumValue)
            self = .minimumValue
        case .clamp:
            let upperBound = try container.decode(Double.self, forKey: .clamp)
            self = .clamp(upperBound: upperBound)
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
extension ChartAxisBaseline: Equatable {
    public static func ==(lhs: ChartAxisBaseline, rhs: ChartAxisBaseline) -> Bool {
        guard lhs.codingKey == rhs.codingKey else {
            return false
        }
        
        switch lhs {
        case .clamp(let upperBound):
            guard case .clamp(let upperBound_) = rhs else { return false }
            guard upperBound == upperBound_ else { return false }
        default:
            break
        }
        
        return true
    }
}

extension ChartAxisBaseline: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codingKey.rawValue)
        switch self {
        case .clamp(let upperBound):
            hasher.combine(upperBound)
        default:
            break
        }
    }
}

// MARK: ChartAxisTopline extensions

extension ChartAxisTopline: Codable {
    enum CodingKeys: String, CodingKey {
        case maximumValue, clamp
    }
    
    var codingKey: CodingKeys {
        switch self {
        case .maximumValue: return .maximumValue
        case .clamp: return .clamp
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .maximumValue:
            try container.encodeNil(forKey: .maximumValue)
        case .clamp(let lowerBound):
            try container.encode(lowerBound, forKey: .clamp)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .maximumValue:
            _ = try container.decodeNil(forKey: .maximumValue)
            self = .maximumValue
        case .clamp:
            let lowerBound = try container.decode(Double.self, forKey: .clamp)
            self = .clamp(lowerBound: lowerBound)
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

extension ChartAxisTopline: Equatable {
    public static func ==(lhs: ChartAxisTopline, rhs: ChartAxisTopline) -> Bool {
        guard lhs.codingKey == rhs.codingKey else {
            return false
        }
        
        switch lhs {
        case .clamp(let lowerBound):
            guard case .clamp(let lowerBound_) = rhs else { return false }
            guard lowerBound == lowerBound_ else { return false }
        default: break
        }
        
        return true
    }
}

extension ChartAxisTopline: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codingKey.rawValue)
        switch self {
        case .clamp(let lowerBound):
            hasher.combine(lowerBound)
        default: break
        }
    }
}

// MARK: ChartAxisStep extensions

extension ChartAxisStep: Codable {
    enum CodingKeys: String, CodingKey {
        case fixed, automatic
    }
    
    var codingKey: CodingKeys {
        switch self {
        case .fixed: return .fixed
        case .automatic: return .automatic
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fixed(let value):
            try container.encode(value, forKey: .fixed)
        case .automatic(let preferredSteps):
            try container.encode(preferredSteps, forKey: .automatic)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .fixed:
            let value = try container.decode(Double.self, forKey: .fixed)
            self = .fixed(value)
        case .automatic:
            let preferredSteps = try container.decode(Int.self, forKey: .automatic)
            self = .automatic(preferredSteps: preferredSteps)
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

extension ChartAxisStep: Equatable {
    public static func ==(lhs: ChartAxisStep, rhs: ChartAxisStep) -> Bool {
        guard lhs.codingKey == rhs.codingKey else {
            return false
        }
        
        switch lhs {
        case .fixed(let value):
            guard case .fixed(let value_) = rhs else { return false }
            guard value == value_ else { return false }
        case .automatic(let preferredSteps):
            guard case .automatic(let preferredSteps_) = rhs else { return false }
            guard preferredSteps == preferredSteps_ else { return false }
            
        }
        
        return true
    }
}

extension ChartAxisStep: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codingKey.rawValue)
        switch self {
        case .fixed(let value):
            hasher.combine(value)
        case .automatic(let preferredSteps):
            hasher.combine(preferredSteps)
            
        }
    }
}

// MARK: ChartScrollingBehaviour extensions

extension ChartScrollingBehaviour: Codable {
    enum CodingKeys: String, CodingKey {
        case noScrolling, segmented, continuous
    }
    
    var codingKey: CodingKeys {
        switch self {
        case .noScrolling: return .noScrolling
        case .segmented: return .segmented
        case .continuous: return .continuous
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .noScrolling:
            try container.encodeNil(forKey: .noScrolling)
        case .segmented(let visibleValueRange):
            try container.encode(visibleValueRange, forKey: .segmented)
        case .continuous(let visibleValueRange):
            try container.encode(visibleValueRange, forKey: .continuous)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch container.allKeys.first {
        case .noScrolling:
            _ = try container.decodeNil(forKey: .noScrolling)
            self = .noScrolling
        case .segmented:
            let visibleValueRange = try container.decode(Double.self, forKey: .segmented)
            self = .segmented(visibleValueRange: visibleValueRange)
        case .continuous:
            let visibleValueRange = try container.decode(Double.self, forKey: .continuous)
            self = .continuous(visibleValueRange: visibleValueRange)
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

extension ChartScrollingBehaviour: Equatable {
    public static func ==(lhs: ChartScrollingBehaviour, rhs: ChartScrollingBehaviour) -> Bool {
        guard lhs.codingKey == rhs.codingKey else {
            return false
        }
        
        switch lhs {
        case .segmented(let visibleValueRange):
            guard case .segmented(let visibleValueRange_) = rhs else { return false }
            guard visibleValueRange == visibleValueRange_ else { return false }
        case .continuous(let visibleValueRange):
            guard case .continuous(let visibleValueRange_) = rhs else { return false }
            guard visibleValueRange == visibleValueRange_ else { return false }
        default: break
        }
        
        return true
    }
}

extension ChartScrollingBehaviour: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codingKey.rawValue)
        switch self {
        case .segmented(let visibleValueRange):
            hasher.combine(visibleValueRange)
        case .continuous(let visibleValueRange):
            hasher.combine(visibleValueRange)
        default: break
        }
    }
}


