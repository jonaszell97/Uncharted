
import SwiftUI
import Toolbox
import Panorama

public struct ChartStateProxy {
    /// The chart state.
    internal var state: ChartState
    
    /// The complete dataset.
    public var completeData: ChartData { state.fullData }
    
    /// The currently visible data segment.
    public var currentSegmentData: ChartData
    
    /// The index of the currently visible data subset.
    public var currentSegmentIndex: Int
    
    /// Internal initializer.
    internal init(state: ChartState) {
        self.state = state
        self.currentSegmentData = state.currentDataSubset
        self.currentSegmentIndex = state.currentSubsetIndex
    }
}

public struct ChartStateReader<Content: View>: View {
    /// The content view.
    let content: (ChartStateProxy?) -> Content
    
    /// The chart state.
    @State var chartStateProxy: ChartStateProxy? = nil
    
    /// Memberwise initializer.
    public init(content: @escaping (ChartStateProxy?) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content(chartStateProxy)
            .onPreferenceChange(ChartStateProxyKey.self) { chartStateProxy in
                self.chartStateProxy = chartStateProxy
            }
    }
}

/// Properties of the chart state that are relevant to child views.
internal class ObservedChartState: ObservableObject {
    /// The base state.
    var state: ChartState? = nil
    
    /// The animation progress percentage.
    @Published var appearanceAnimationProgress: Double = 0
    
    /// The x-value of the highlighted data point, if any.
    @Published var highlightedDataPoints: [(String, DataPoint)] = []
    
    /// Execute the tap actions for a given data point.
    internal func runTapActions(for pt: DataPoint, in seriesName: String) {
        guard let state else {
            return
        }
        
        guard let series = (state.currentDataSubset.series.first { $0.name == seriesName }) else {
            fatalError("series \(seriesName) does not exist")
        }
        
        for action in state.fullData.config.tapActions {
            switch action {
            case .highlightSingle:
                if highlightedDataPoints.isEmpty {
                    highlightedDataPoints.append((seriesName, pt))
                }
                else if highlightedDataPoints[0].0 == seriesName && highlightedDataPoints[0].1 == pt {
                    highlightedDataPoints = []
                }
                else {
                    highlightedDataPoints = [(seriesName, pt)]
                }
            case .highlightMultiple:
                if (highlightedDataPoints.contains { $0.0 == seriesName && $0.1 == pt }) {
                    highlightedDataPoints.removeAll { $0.0 == seriesName && $0.1 == pt }
                }
                else {
                    highlightedDataPoints.append((seriesName, pt))
                }
            case .custom(let callback):
                callback(series, pt)
            }
        }
    }
}

internal class ChartState: ObservableObject {
    /// The  chart state passed to subviews.
    let observedState: ObservedChartState
    
    /// The full data set of this chart.
    var fullData: ChartData
    
    /// Whether or not the state is initialized.
    @Published var initialized: Bool
    
    /// The current chart offset.
    @Published var currentSubsetIndex: Int
    
    /// The current data subset.
    @Published var currentDataSubset: ChartData
    
    /// The next data subset.
    @Published var nextDataSubset: ChartData
    
    /// The previous data subset.
    @Published var previousDataSubset: ChartData
    
    /// The current chart offset.
    @Published var currentChartOffset: CGSize
    
    /// The y-axis labels, used for animations.
    @Published var yAxisParams: ComputedChartAxisData?
    
    /// Whether or not we're currently transitioning to another subset.
    @Published var isTransitioning: Bool = false
    
    /// The calculated size of the chart content and x-axis area.
    @Published var chartAreaSize: CGSize = .zero
    
    /// Cached data subsets.
    var dataSubsets: [Int: ChartData]
    
    /// The step size used for the x-axis.
    var xAxisRange: Double = .zero
    
    /// The longest label on the y-axis.
    var longestYLabel: String = ""
    
    /// The chart transition animation parameters.
    static let chartTransitionAnimation = Animation.easeInOut(duration: 0.35)
    static let chartTransitionAnimationDuration = 0.35
    
    /// The height of the x-axis.
    static func xAxisHeight(for config: ChartAxisConfig) -> CGFloat {
        config.size ?? 15
    }
    
    /// Size of the chart area with padding.
    var chartAreaSizeWithPadding: CGSize {
        .init(width: chartAreaSize.width - fullData.config.padding.leading - fullData.config.padding.trailing,
              height: chartAreaSize.height - fullData.config.padding.top - fullData.config.padding.bottom)
    }
    
    /// Size of the chart area and x-axis without padding.
    var chartAndxAxisAreaSize: CGSize {
        .init(width: chartAreaSize.width, height: chartAreaSize.height + Self.xAxisHeight(for: fullData.config.xAxisConfig))
    }
    
    /// Default initializer.
    internal init() {
        self.fullData = .empty
        self.initialized = false
        self.currentSubsetIndex = 0
        self.dataSubsets = [:]
        self.currentDataSubset = .empty
        self.nextDataSubset = .empty
        self.previousDataSubset = .empty
        self.currentChartOffset = .zero
        self.yAxisParams = nil
        self.observedState = .init()
        
        self.observedState.state = self
    }
    
    /// Assign data to this state.
    internal func initialize(data: ChartData) {
        self.fullData = data
        self.currentSubsetIndex = 0
        self.currentChartOffset = .zero
        self.initialized = true
        
        if data.config.isHorizontallySegmented {
            let uncachedFirstSubset = getSubset(for: 0, cacheResult: false, copyYAxisFrom: nil)
            self.xAxisRange = uncachedFirstSubset.computedParameters.xAxisParams.upperBound - uncachedFirstSubset.computedParameters.xAxisParams.lowerBound
            self.longestYLabel = Self.findLongestYAxisLabel(fullData: data, firstSubset: uncachedFirstSubset)
            
            let firstSubset = getSubset(for: 0, cacheResult: true, copyYAxisFrom: nil)
            self.currentDataSubset = firstSubset
            self.previousDataSubset = getSubset(for: -1, cacheResult: false, copyYAxisFrom: firstSubset.computedParameters)
            self.nextDataSubset = getSubset(for: 1, cacheResult: false, copyYAxisFrom: firstSubset.computedParameters)
        }
        else if data.config.isContinuouslyHorizontallyScrollable {
            let uncachedFirstSubset = getSubset(for: 0, cacheResult: false, copyYAxisFrom: nil)
            let fullSubset = ChartData(config: data.config, series: data.series)
            fullSubset.computedParameters = getSubsetParameters(xStart: data.computedParameters.xAxisParams.lowerBound,
                                                                xEnd: data.computedParameters.xAxisParams.upperBound,
                                                                copyXAxisFrom: uncachedFirstSubset.computedParameters,
                                                                copyYAxisFrom: fullSubset.computedParameters,
                                                                sortedXValues: fullSubset.computedParameters.sortedXValues,
                                                                adjacentDataPoints: [:])
            
            self.currentDataSubset = fullSubset
        }
        else {
            self.currentDataSubset = data
        }
        
        if let initialValue = data.config.initialXValue, case .segmented = data.config.xAxisConfig.scrollingBehaviour {
            self.ensureVisible(xValue: initialValue)
        }
        
        self.yAxisParams = self.currentDataSubset.computedParameters.yAxisParams
    }
    
    /// Find the longest y axis label.
    static func findLongestYAxisLabel(fullData: ChartData, firstSubset: ChartData) -> String {
        let step = firstSubset.computedParameters.yAxisParams.stepSize
        
        var current = fullData.computedParameters.yAxisParams.lowerBound
        guard step > 0 else {
            return fullData.config.yAxisConfig.labelFormatter(current)
        }
        
        let end = fullData.computedParameters.yAxisParams.upperBound
        
        var longestLabelCount = 0
        var longestLabel: String = ""
        
        while current < end {
            let label = fullData.config.yAxisConfig.labelFormatter(current)
            if label.count > longestLabelCount {
                longestLabelCount = label.count
                longestLabel = label
            }
            
            current += step
        }
        
        return longestLabel
    }
    
    /// Get the data subset for a given index.
    func getSubset(for index: Int, cacheResult: Bool, copyYAxisFrom: ComputedChartData?) -> ChartData {
        if cacheResult, let subset = self.dataSubsets[index] {
            return subset
        }
        
        guard var visibleValueRange = fullData.config.xAxisConfig.visibleValueRange else {
            fatalError("no subsets available")
        }
        
        if self.xAxisRange > 0 {
            visibleValueRange = self.xAxisRange
        }
        
        let start = Double(index) * visibleValueRange
        let end = start + visibleValueRange
        let range = start..<end
        
        var adjacentDataPoints: [String: [DataPoint]] = [:]
        var foundAdjacentPoint = false
        
        if fullData.config.isHorizontallySegmented, fullData.config.considerNextDataPointForYBounds {
            for series in fullData.series {
                var adjacentPoints = [DataPoint]()
                
                if let previousPt = (series.data.last { $0.x < start }) {
                    adjacentPoints.append(previousPt)
                }
                
                var end = end
                if self.xAxisRange > 0 {
                    let axisEnd = start + xAxisRange
                    if !axisEnd.isEqual(to: end) {
                        adjacentPoints.append(contentsOf: series.data.filter {
                            $0.x >= end && $0.x < axisEnd
                        })

                        end = axisEnd
                    }
                }
                
                if let nextPt = (series.data.first { $0.x >= end }) {
                    adjacentPoints.append(nextPt)
                }
                
                adjacentDataPoints[series.name] = adjacentPoints
                
                if !adjacentPoints.isEmpty {
                    foundAdjacentPoint = true
                }
            }
        }
        
        let subset = fullData.subset(xrange: range, adjacentDataPoints: adjacentDataPoints)
        if let firstSubset = dataSubsets[0] {
            // Copy the x-axis step from the first subset and the y-axis of the surrounding datasets
            subset.computedParameters = getSubsetParameters(xStart: start,
                                                            xEnd: end,
                                                            copyXAxisFrom: firstSubset.computedParameters,
                                                            copyYAxisFrom: copyYAxisFrom ?? subset.computedParameters,
                                                            sortedXValues: subset.computedParameters.sortedXValues,
                                                            adjacentDataPoints: adjacentDataPoints)
        }
        else if foundAdjacentPoint {
            subset.computedParameters = getSubsetParameters(xStart: start,
                                                            xEnd: end,
                                                            copyXAxisFrom: subset.computedParameters,
                                                            copyYAxisFrom: copyYAxisFrom ?? subset.computedParameters,
                                                            sortedXValues: subset.computedParameters.sortedXValues,
                                                            adjacentDataPoints: adjacentDataPoints)
        }
        
        if cacheResult {
            self.dataSubsets[index] = subset
        }
        
        return subset
    }
    
    /// Get the axis parameters for a subset.
    func getSubsetParameters(xStart: Double, xEnd: Double,
                             copyXAxisFrom: ComputedChartData,
                             copyYAxisFrom: ComputedChartData,
                             sortedXValues: [Double],
                             adjacentDataPoints: [String: [DataPoint]]) -> ComputedChartData {
        let min = copyYAxisFrom.min
        let max = copyYAxisFrom.max
        
        let xAxisStepSize = copyXAxisFrom.xAxisParams.stepSize
        let xAxisParams: ComputedChartAxisData = .init(lowerBound: xStart,
                                                       upperBound: xEnd,
                                                       stepSize: xAxisStepSize,
                                                       labels: fullData.config.xAxisConfig._axisLabels(lowerBound: xStart,
                                                                                                       upperBound: xEnd - xAxisStepSize,
                                                                                                       stepSize: xAxisStepSize))
        
        let yAxisParams = copyYAxisFrom.yAxisParams
        
        return ComputedChartData(min: min,
                                 max: max,
                                 xAxisParams: xAxisParams,
                                 yAxisParams: yAxisParams,
                                 sortedXValues: sortedXValues,
                                 adjacentDataPoints: adjacentDataPoints)
    }
    
    /// Move the chart to make the given x-value visible.
    func ensureVisible(xValue: Double) {
        guard let visibleValueRange = fullData.config.xAxisConfig.visibleValueRange else {
            return
        }
        
        let subsetIndex = Int((xValue / visibleValueRange).rounded(.down))
        let subset = self.getSubset(for: subsetIndex, cacheResult: true, copyYAxisFrom: nil)
        
        self.yAxisParams = subset.computedParameters.yAxisParams
        self.nextDataSubset = subset
        self.currentSubsetIndex = subsetIndex
        self.isTransitioning = false
        self.currentChartOffset = .zero
        self.chartAreaSize = .zero
        
        self.previousDataSubset = self.getSubset(for: subsetIndex - 1, cacheResult: false, copyYAxisFrom: subset.computedParameters)
        self.currentDataSubset = subset
        self.nextDataSubset = self.getSubset(for: subsetIndex + 1, cacheResult: false, copyYAxisFrom: subset.computedParameters)
    }
    
    /// Initiate a scroll to the next data subset.
    func initiateForwardScroll() {
        guard fullData.config.xAxisConfig.visibleValueRange != nil else {
            return
        }
        
        let subset = self.getSubset(for: self.currentSubsetIndex + 1, cacheResult: true, copyYAxisFrom: nil)
        let sequence = AnimationSequence()
        
        defer {
            sequence.execute()
        }
        
        self.isTransitioning = true
        
        guard !subset.isEmpty else {
            sequence.append(animation: .easeInOut) {
                self.currentChartOffset = .zero
                self.isTransitioning = false
            }
            
            return
        }
        
        sequence.append(animation: .easeInOut(duration: 0.3), duration: 0.3) {
            self.currentChartOffset = .init(width: -self.chartAreaSize.width, height: 0)
        }
        
        sequence.append(animation: Self.chartTransitionAnimation, duration: Self.chartTransitionAnimationDuration) {
            self.yAxisParams = subset.computedParameters.yAxisParams
            self.nextDataSubset = subset
        }
        
        sequence.append {
            let newIndex = self.currentSubsetIndex + 1
            self.currentSubsetIndex = newIndex
            self.isTransitioning = false
            self.currentChartOffset = .zero
            self.chartAreaSize = .zero
            
            self.previousDataSubset = self.getSubset(for: newIndex - 1, cacheResult: false, copyYAxisFrom: subset.computedParameters)
            self.currentDataSubset = subset
            self.nextDataSubset = self.getSubset(for: newIndex + 1, cacheResult: false, copyYAxisFrom: subset.computedParameters)
        }
    }
    
    /// Initiate a scroll to the previous data subset.
    func initiateBackwardScroll() {
        guard fullData.config.xAxisConfig.visibleValueRange != nil else {
            return
        }
        
        let subset = self.getSubset(for: self.currentSubsetIndex - 1, cacheResult: true, copyYAxisFrom: nil)
        let sequence = AnimationSequence()
        
        defer {
            sequence.execute()
        }
        
        self.isTransitioning = true
        
        guard !subset.isEmpty else {
            sequence.append(animation: .easeInOut) {
                self.currentChartOffset = .zero
                self.isTransitioning = false
            }
            
            return
        }
        
        sequence.append(animation: .easeInOut(duration: 0.3), duration: 0.3) {
            self.currentChartOffset = .init(width: self.chartAreaSize.width, height: 0)
        }
        
        sequence.append(animation: Self.chartTransitionAnimation, duration: Self.chartTransitionAnimationDuration) {
            self.yAxisParams = subset.computedParameters.yAxisParams
            self.previousDataSubset = subset
        }
        
        sequence.append {
            let newIndex = self.currentSubsetIndex - 1
            self.currentSubsetIndex = newIndex
            self.isTransitioning = false
            self.currentChartOffset = .zero
            self.chartAreaSize = .zero
            
            self.previousDataSubset = self.getSubset(for: newIndex - 1, cacheResult: false, copyYAxisFrom: subset.computedParameters)
            self.currentDataSubset = subset
            self.nextDataSubset = self.getSubset(for: newIndex + 1, cacheResult: false, copyYAxisFrom: subset.computedParameters)
        }
    }
}

// MARK: ChartState Observation

internal struct ChartStateProxyKey: PreferenceKey {
    typealias Value = ChartStateProxy?
    static var defaultValue: ChartStateProxy? = nil
    
    static func reduce(value: inout ChartStateProxy?, nextValue: () -> ChartStateProxy?) {
        let nextValue = nextValue()
        guard nextValue != nil else { return }
        value = nextValue
    }
}

public extension View {
    /// Observe changes to the state of chart subviews.
    func observeChart(_ callback: @escaping (ChartStateProxy) -> Void) -> some View {
        self.onPreferenceChange(ChartStateProxyKey.self) { proxy in
            guard let proxy else { return }
            callback(proxy)
        }
    }
}

extension ChartStateProxy: Hashable {
    public static func ==(lhs: ChartStateProxy, rhs: ChartStateProxy) -> Bool {
        ObjectIdentifier(lhs.state) == ObjectIdentifier(rhs.state)
            && lhs.currentSegmentIndex == rhs.currentSegmentIndex
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self.state))
        hasher.combine(self.currentSegmentIndex)
    }
}
