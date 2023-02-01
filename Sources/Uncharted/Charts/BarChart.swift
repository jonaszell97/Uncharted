
import SwiftUI
import Toolbox
import Panorama

fileprivate struct BarChartComputedParams {
    let relativeYs: [Double]
    let totalRelativeY: Double
    let stops: [Gradient.Stop]
    let highlighted: Bool
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
fileprivate struct BarChartViewImpl: View {
    /// The complete data set.
    let data: ChartData
    
    /// The chart state.
    @ObservedObject var state: ObservedChartState
    
    /// Whether or not to stack the data.
    let isStacked: Bool
    
    /// The width of a single bar.
    let barWidth: CGFloat
    
    /// The x-value of this bar.
    let xValue: Double
    
    /// The bounds of the y-axis to use for this chart.
    let yBounds: (min: Double, max: Double)
    
    /// The data series of this line.
    let positiveValues: [(String, Double, ColorStyle)]
    
    /// The data series of this line.
    let negativeValues: [(String, Double, ColorStyle)]
    
    /// The percentage of vertical space taken up by positive values.
    let positiveSpacePercentage: CGFloat
    
    /// The percentage of vertical space taken up by negative values.
    let negativeSpacePercentage: CGFloat
    
    /// The positive chart params.
    let positiveParams: BarChartComputedParams
    
    /// The negative chart params.
    let negativeParams: BarChartComputedParams
    
    /// The computed view bounds.
    let size: CGSize
    
    /// The x-axis configuration.
    var xAxisParams: ComputedChartAxisData {
        data.computedParameters.xAxisParams
    }
    
    init(data: ChartData, state: ObservedChartState,
         isStacked: Bool,
         barWidth: CGFloat,
         xValue: Double,
         yBounds: (min: Double, max: Double),
         positiveValues: [(String, Double, ColorStyle)],
         negativeValues: [(String, Double, ColorStyle)],
         positiveSpacePercentage: CGFloat,
         negativeSpacePercentage: CGFloat,
         size: CGSize) {
        self.data = data
        self.state = state
        self.isStacked = isStacked
        self.barWidth = barWidth
        self.xValue = xValue
        self.yBounds = yBounds
        self.positiveValues = positiveValues
        self.negativeValues = negativeValues
        self.positiveSpacePercentage = positiveSpacePercentage
        self.negativeSpacePercentage = negativeSpacePercentage
        self.size = size
        
        self.positiveParams = Self.calculateStackedBarParams(state: state,
                                                             values: positiveValues,
                                                             xValue: xValue,
                                                             yBounds: (min: max(0, yBounds.min),
                                                                       max: yBounds.max))
        self.negativeParams = Self.calculateStackedBarParams(state: state,
                                                             values: negativeValues,
                                                             xValue: xValue,
                                                             yBounds: (min: abs((min(0, yBounds.max))),
                                                                       max: abs(yBounds.min)))
    }
    
    private struct BarChartPart: Identifiable {
        let seriesName: String
        let xValue: Double
        let yValue: Double
        let colorStyle: ColorStyle
        let index: Int
        var id: String { "bar_\(seriesName)_\(xValue)_\(yValue)_\(index)" }
    }
    
    static func calculateStackedBarParams(state: ObservedChartState,
                                          values: [(String, Double, ColorStyle)],
                                          xValue: Double,
                                          yBounds: (min: Double, max: Double)) -> BarChartComputedParams {
        var ydistance = yBounds.max - yBounds.min
        if ydistance.isZero {
            ydistance = 1
        }
        
        let relativeYs = values.map { min(1, ($0.1 - yBounds.min) / ydistance) }
        let totalRelativeY = relativeYs.reduce(0) { $0 + $1 }
        
        let highlighted = state.highlightedDataPoints.isEmpty || values.first { part in
            state.highlightedDataPoints.contains { $0.0 == part.0 && $0.1.x == xValue }
        } != nil
        
        var stops = [Gradient.Stop]()
        var sum: Double = 0
        
        for i in 0..<values.count {
            let (_, _, color) = values[i]
            let relativeY = relativeYs[values.count - i - 1]
            
            stops.append(.init(color: color.singleColor, location: sum / totalRelativeY))
            
            sum += relativeY
            stops.append(.init(color: color.singleColor, location: sum / totalRelativeY))
        }
        
        return .init(relativeYs: relativeYs, totalRelativeY: totalRelativeY,
                     stops: stops, highlighted: highlighted)
    }
    
    var stackedBarView: some View {
        let relativeX = (xValue - xAxisParams.lowerBound) / (xAxisParams.upperBound - xAxisParams.lowerBound)
        
        let horizontalSpacePerBar = size.width / CGFloat(xAxisParams.upperBound - xAxisParams.lowerBound)
        let centerBars = (data.config as? BarChartConfig)?.centerBars ?? false
        
        var horizontalOffset: CGFloat = 0.5 * horizontalSpacePerBar
        if !centerBars {
            horizontalOffset -= (horizontalSpacePerBar - barWidth) * 0.5
        }
        
        let highlighted = positiveParams.highlighted || negativeParams.highlighted
        return ZStack {
            // Positive values
            if positiveSpacePercentage > 0 {
                let barHeight = positiveParams.totalRelativeY * size.height * positiveSpacePercentage * CGFloat(state.appearanceAnimationProgress)
                let xOffset = relativeX * size.width - size.width * 0.5 + horizontalOffset
                
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: barWidth, height: max(0, size.height - barHeight))
                    Rectangle()
                        .fill(LinearGradient(stops: positiveParams.stops, startPoint: .bottom, endPoint: .top))
                        .frame(width: barWidth, height: barHeight)
                        .cornerRadius(barWidth * 0.20, corners: [.topLeft, .topRight])
                        .opacity(highlighted ? 1 : 0.50)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !positiveValues[0].1.isZero else { return }
                    state.runTapActions(for:
                            .init(x: xValue, y: positiveValues[0].1), in: positiveValues[0].0)
                }
                .offset(x: xOffset, y: -size.height * negativeSpacePercentage)
            }
            
            // Negative values
            if negativeSpacePercentage > 0 {
                let barHeight = negativeParams.totalRelativeY * size.height * negativeSpacePercentage * CGFloat(state.appearanceAnimationProgress)
                let xOffset = relativeX * size.width - size.width * 0.5 + horizontalOffset
                
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(LinearGradient(stops: negativeParams.stops, startPoint: .top, endPoint: .bottom))
                        .frame(width: barWidth, height: barHeight)
                        .cornerRadius(barWidth * 0.20, corners: [.bottomLeft, .bottomRight])
                        .opacity(highlighted ? 1 : 0.50)
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: barWidth, height: max(0, size.height - barHeight))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !negativeValues[0].1.isZero else { return }
                    state.runTapActions(for:
                            .init(x: xValue, y: negativeValues[0].1), in: negativeValues[0].0)
                }
                .offset(x: xOffset, y: size.height * positiveSpacePercentage)
            }
        }
    }
    
    var sideBySideBarView: some View {
        let relativeX = (xValue - xAxisParams.lowerBound) / (xAxisParams.upperBound - xAxisParams.lowerBound)
        
        let horizontalSpacePerBar = size.width / CGFloat(xAxisParams.upperBound - xAxisParams.lowerBound)
        let centerBars = (data.config as? BarChartConfig)?.centerBars ?? false
        
        var horizontalOffset: CGFloat = 0.5 * horizontalSpacePerBar
        if !centerBars {
            horizontalOffset -= (horizontalSpacePerBar - barWidth) * 0.5
        }
        
        let highlighted = positiveParams.highlighted || negativeParams.highlighted
        
        return ZStack {
            // Positive values
            HStack(spacing: 0) {
                ForEach(0..<positiveParams.relativeYs.count, id: \.self) { i in
                    let relativeY: Double = positiveParams.relativeYs[i]
                    let color: ColorStyle = positiveValues[i].2
                    let barHeight = relativeY * size.height * positiveSpacePercentage * CGFloat(state.appearanceAnimationProgress)
                    let xOffset = relativeX * size.width - size.width * 0.5 + horizontalOffset
                    
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: barWidth, height: max(0, size.height - barHeight))
                        Rectangle()
                            .fill(color.swiftUIShapeStyle)
                            .frame(width: barWidth, height: barHeight)
                            .cornerRadius(barWidth * 0.20, corners: [.topLeft, .topRight])
                            .opacity(highlighted ? 1 : 0.50)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !positiveValues[i].1.isZero else { return }
                        state.runTapActions(for:
                                .init(x: xValue, y: positiveValues[i].1), in: positiveValues[i].0)
                    }
                    .offset(x: xOffset, y: -size.height * negativeSpacePercentage)
                }
            }
            
            
            // Negative values
            HStack(spacing: 0) {
                ForEach(0..<negativeParams.relativeYs.count, id: \.self) { i in
                    let relativeY: Double = negativeParams.relativeYs[i]
                    let color: ColorStyle = negativeValues[i].2
                    let barHeight = relativeY * size.height * negativeSpacePercentage * CGFloat(state.appearanceAnimationProgress)
                    let xOffset = relativeX * size.width - size.width * 0.5 + horizontalOffset
                    
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(color.swiftUIShapeStyle)
                            .frame(width: barWidth, height: barHeight)
                            .cornerRadius(barWidth * 0.20, corners: [.bottomLeft, .bottomRight])
                            .opacity(highlighted ? 1 : 0.50)
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: barWidth, height: max(0, size.height - barHeight))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard !negativeValues[i].1.isZero else { return }
                        state.runTapActions(for:
                                .init(x: xValue, y: negativeValues[i].1), in: negativeValues[i].0)
                    }
                    .offset(x: xOffset, y: size.height * positiveSpacePercentage)
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            if isStacked {
                stackedBarView
            }
            else {
                sideBySideBarView
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
internal struct BarChart15: View {
    /// The chart state.
    @ObservedObject var state: ObservedChartState
    
    /// The data to use for this chart.
    let data: ChartData
    
    /// The chart size.
    let size: CGSize
    
    /// The positive values grouped by x-value.
    let positiveValues: [Double: [(String, Double, ColorStyle)]]
    
    /// The negative values grouped by x-value.
    let negativeValues: [Double: [(String, Double, ColorStyle)]]
    
    /// The percentage of vertical space taken up by positive values.
    let positiveSpacePercentage: CGFloat
    
    /// The percentage of vertical space taken up by negative values.
    let negativeSpacePercentage: CGFloat
    
    static func == (lhs: BarChart15, rhs: BarChart15) -> Bool {
        lhs.data.dataHash == rhs.data.dataHash
    }
    
    init(state: ObservedChartState, data: ChartData, size: CGSize) {
        self.state = state
        self.data = data
        self.size = size
        
        var positiveValues = [Double: [(String, Double, ColorStyle)]]()
        var negativeValues = [Double: [(String, Double, ColorStyle)]]()
        
        for xValue in data.computedParameters.sortedXValues {
            var positiveStack = [(String, Double, ColorStyle)]()
            var negativeStack = [(String, Double, ColorStyle)]()
            
            for series in data.series {
                let yValue = series.yValue(for: xValue) ?? 0
                if yValue >= 0 {
                    positiveStack.append((series.name, yValue, series.color))
                    negativeStack.append((series.name, 0, series.color))
                }
                else {
                    negativeStack.append((series.name, -yValue, series.color))
                    positiveStack.append((series.name, 0, series.color))
                }
            }
            
            positiveValues[xValue] = positiveStack
            negativeValues[xValue] = negativeStack
        }
        
        self.positiveValues = positiveValues
        self.negativeValues = negativeValues
        
        let total = (data.computedParameters.yAxisParams.upperBound - data.computedParameters.yAxisParams.lowerBound)
        self.positiveSpacePercentage = data.computedParameters.yAxisParams.upperBound / total
        self.negativeSpacePercentage = 1 - positiveSpacePercentage
    }
    
    /// The bar width to use.
    func barWidth(size: CGSize, isStacked: Bool) -> CGFloat {
        let availableWidth = size.width
        let barCount = CGFloat(data.computedParameters.xAxisParams.upperBound - data.computedParameters.xAxisParams.lowerBound)
        
        let minimumSpacing: CGFloat = (availableWidth / barCount) * 0.25
        
        var maximumBarWidth = ((availableWidth - (barCount - 1) * minimumSpacing) / barCount)
        if let maxWidth = (data.config as? BarChartConfig)?.maxBarWidth {
            maximumBarWidth = min(maxWidth, maximumBarWidth)
        }
        
        var preferredWidth = (data.config as? BarChartConfig)?.preferredBarWidth ?? maximumBarWidth
        
        if !isStacked {
            let minimumBarSpacing: CGFloat = 5
            preferredWidth *= CGFloat(data.series.count)
            preferredWidth += minimumBarSpacing * CGFloat(data.series.count-1)
            
            maximumBarWidth /= CGFloat(data.series.count)
            maximumBarWidth -= minimumBarSpacing * CGFloat(data.series.count-1)
        }
        
        let width = max(1, min(preferredWidth, maximumBarWidth))
        assert(width > 0)
        
        return width
    }
    
    func barsView(xValue: Double, isStacked: Bool, barWidth: CGFloat) -> some View {
        let positiveStack = self.positiveValues[xValue] ?? []
        let negativeStack = self.negativeValues[xValue] ?? []
        let yBounds = (min: data.computedParameters.yAxisParams.lowerBound,
                       max: data.computedParameters.yAxisParams.upperBound)
        
        return BarChartViewImpl(data: data,
                                state: state,
                                isStacked: isStacked,
                                barWidth: barWidth,
                                xValue: xValue,
                                yBounds: yBounds,
                                positiveValues: positiveStack,
                                negativeValues: negativeStack,
                                positiveSpacePercentage: positiveSpacePercentage,
                                negativeSpacePercentage: negativeSpacePercentage,
                                size: size)
    }
    
    var body: some View {
        let xValues = data.computedParameters.sortedXValues
        let isStacked: Bool
        if let config = data.config as? BarChartConfig {
            isStacked = config.isStacked
        }
        else {
            isStacked = true
        }
        
        let barWidth = self.barWidth(size: size, isStacked: isStacked)
        return ZStack {
            ForEach(0..<xValues.count, id: \.self) { i in
                self.barsView(xValue: xValues[i], isStacked: isStacked, barWidth: barWidth)
            }
        }
        .clipShape(Rectangle())
    }
}

public struct BarChart: View, Equatable {
    /// The data to use for this chart.
    let data: ChartData
    
    /// The chart state.
    @StateObject var state: ChartState = .init()
    
    /// Avoid unnecessary view updates.
    public static func ==(lhs: BarChart, rhs: BarChart) -> Bool {
        lhs.data.dataHash == rhs.data.dataHash
    }
    
    /// Default initializer
    public init(data: ChartData) {
        if !(data.config is BarChartConfig) {
            self.data = .init(config: BarChartConfig(config: data.config), series: data.series)
        }
        else {
            self.data = data
        }
    }
    
    public var body: some View {
        ChartBase(state: state, data: data) { state, currentData, size in
            BarChart15(state: state, data: currentData, size: size)
        }
    }
}
