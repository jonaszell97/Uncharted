
import SwiftUI
import Toolbox
import Panorama

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
fileprivate struct BarChartViewImpl: View {
    /// The complete data set.
    let data: ChartData
    
    /// The chart state.
    @ObservedObject var state: ChartState
    
    /// Whether or not to stack the data.
    let isStacked: Bool
    
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
    
    /// The computed view bounds.
    let size: CGSize
    
    /// The x-axis configuration.
    var xAxisParams: ComputedChartAxisData {
        data.computedParameters.xAxisParams
    }
    
    private struct BarChartPart: Identifiable {
        let seriesName: String
        let xValue: Double
        let yValue: Double
        let colorStyle: ColorStyle
        let index: Int
        var id: String { "bar_\(seriesName)_\(xValue)_\(yValue)_\(index)" }
    }
    
    /// The bar width to use.
    func barWidth(size: CGSize) -> CGFloat {
        let availableWidth = size.width
        let barCount = CGFloat(data.computedParameters.sortedXValues.count)
    
        var minimumSpacing: CGFloat = 10
        while ((barCount - 1) * minimumSpacing) >= availableWidth {
            minimumSpacing /= 2
        }
        
        var maximumBarWidth = ((availableWidth - (barCount - 1) * minimumSpacing) / barCount)
        var preferredWidth = (data.config as? BarChartConfig)?.preferredBarWidth ?? 10
        
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
    
    func calculateStackedBarParams(values: [(String, Double, ColorStyle)],
                                   yBounds: (min: Double, max: Double))
        -> (relativeYs: [Double], totalRelativeY: Double, stops: [Gradient.Stop], highlighted: Bool)
    {
        var ydistance = yBounds.max - yBounds.min
        if ydistance.isZero {
            ydistance = 1
        }
        
        let relativeYs = values.map { ($0.1 - yBounds.min) / ydistance }
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
        
        return (relativeYs: relativeYs, totalRelativeY: totalRelativeY,
                stops: stops, highlighted: highlighted)
    }
    
    var stackedBarView: some View {
        let barWidth = self.barWidth(size: size)
        let relativeX = (xValue - xAxisParams.lowerBound)
            / (xAxisParams.upperBound - xAxisParams.lowerBound)
        
        let horizontalSpacePerBar = size.width / CGFloat(data.computedParameters.xAxisParams.visibleValueCount)
        let horizontalOffset = ((data.config as? BarChartConfig)?.centerBars ?? false) ? horizontalSpacePerBar * 0.5 : barWidth * 0.5
        
        let (_, positiveTotalY, positiveStops, positiveHighlighted)
            = self.calculateStackedBarParams(values: positiveValues,
                                             yBounds: (min: max(0, yBounds.min),
                                                       max: yBounds.max))
        let (_, negativeTotalY, negativeStops, negativeHighlighted)
            = self.calculateStackedBarParams(values: negativeValues,
                                             yBounds: (min: abs((min(0, yBounds.max))),
                                                       max: abs(yBounds.min)))
        
        let highlighted = positiveHighlighted || negativeHighlighted
        
        return ZStack {
            // Positive values
            if positiveSpacePercentage > 0 {
                Rectangle()
                    .fill(LinearGradient(stops: positiveStops, startPoint: .bottom, endPoint: .top))
                    .frame(width: barWidth, height: positiveTotalY * size.height * positiveSpacePercentage)
                    .cornerRadius(barWidth * 0.20, corners: [.topLeft, .topRight])
                    .offset(x: relativeX * size.width - size.width * 0.5 + horizontalOffset,
                            y: (1 - positiveTotalY) * (size.height * positiveSpacePercentage * 0.5)
                            - size.height * negativeSpacePercentage * 0.5)
                    .opacity(highlighted ? 1 : 0.50)
                    .onTapGesture {
                        state.runTapActions(for:
                                .init(x: xValue, y: positiveValues[0].1), in: positiveValues[0].0)
                    }
            }
            
            // Negative values
            if negativeSpacePercentage > 0 {
                Rectangle()
                    .fill(LinearGradient(stops: negativeStops, startPoint: .top, endPoint: .bottom))
                    .frame(width: barWidth, height: negativeTotalY * size.height * negativeSpacePercentage)
                    .cornerRadius(barWidth * 0.20, corners: [.bottomLeft, .bottomRight])
                    .offset(x: relativeX * size.width - size.width * 0.5 + horizontalOffset,
                            y: -(1 - negativeTotalY) * (size.height * negativeSpacePercentage * 0.5)
                            + size.height * positiveSpacePercentage * 0.5)
                    .opacity(highlighted ? 1 : 0.50)
                    .onTapGesture {
                        state.runTapActions(for:
                                .init(x: xValue, y: negativeValues[0].1), in: negativeValues[0].0)
                    }
            }
        }
    }
    
    var sideBySideBarView: some View {
        let barWidth = self.barWidth(size: size)
        let relativeX = (xValue - xAxisParams.lowerBound)
            / (xAxisParams.upperBound - xAxisParams.lowerBound)
        
        let horizontalSpacePerBar = size.width / CGFloat(data.computedParameters.xAxisParams.visibleValueCount)
        let horizontalOffset = ((data.config as? BarChartConfig)?.centerBars ?? false) ? horizontalSpacePerBar * 0.5 : barWidth * 0.5
        
        let (positiveRelativeYs, _, _, positiveHighlighted)
            = self.calculateStackedBarParams(values: positiveValues,
                                             yBounds: (min: max(0, yBounds.min),
                                                       max: yBounds.max))
        let (negativeRelativeYs, _, _, negativeHighlighted)
            = self.calculateStackedBarParams(values: negativeValues,
                                             yBounds: (min: abs((min(0, yBounds.max))),
                                                       max: abs(yBounds.min)))
        
        let highlighted = positiveHighlighted || negativeHighlighted
        
        return ZStack {
            // Positive values
            HStack(spacing: 0) {
                ForEach(0..<positiveRelativeYs.count, id: \.self) { i in
                    let relativeY: Double = positiveRelativeYs[i]
                    let color: ColorStyle = positiveValues[i].2
                    
                    Rectangle()
                        .fill(color.swiftUIShapeStyle)
                        .frame(width: barWidth, height: relativeY * size.height * positiveSpacePercentage)
                        .cornerRadius(barWidth * 0.20, corners: [.topLeft, .topRight])
                        .offset(x: relativeX * size.width - size.width * 0.5 + horizontalOffset,
                                y: (1 - relativeY) * (size.height * positiveSpacePercentage * 0.5)
                                - size.height * negativeSpacePercentage * 0.5)
                        .opacity(highlighted ? 1 : 0.50)
                        .onTapGesture {
                            state.runTapActions(for:
                                    .init(x: xValue, y: positiveValues[i].1), in: positiveValues[i].0)
                        }
                }
            }
            
            
            // Negative values
            HStack(spacing: 0) {
                ForEach(0..<negativeRelativeYs.count, id: \.self) { i in
                    let relativeY: Double = negativeRelativeYs[i]
                    let color: ColorStyle = negativeValues[i].2
                    
                    Rectangle()
                        .fill(color.swiftUIShapeStyle)
                        .frame(width: barWidth, height: relativeY * size.height * negativeSpacePercentage)
                        .cornerRadius(barWidth * 0.20, corners: [.bottomLeft, .bottomRight])
                        .offset(x: relativeX * size.width - size.width * 0.5 + horizontalOffset,
                                y: -(1 - relativeY) * (size.height * negativeSpacePercentage * 0.5)
                                + size.height * positiveSpacePercentage * 0.5)
                        .opacity(highlighted ? 1 : 0.50)
                        .onTapGesture {
                            state.runTapActions(for:
                                    .init(x: xValue, y: negativeValues[i].1), in: negativeValues[i].0)
                        }
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
    @ObservedObject var state: ChartState
    
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
    
    init(state: ChartState, data: ChartData, size: CGSize) {
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
    
    func barsView(xValue: Double) -> some View {
        let isStacked: Bool
        if let config = data.config as? BarChartConfig {
            isStacked = config.isStacked
        }
        else {
            isStacked = true
        }
        
        let positiveStack = self.positiveValues[xValue] ?? []
        let negativeStack = self.negativeValues[xValue] ?? []
        let yBounds = (min: data.computedParameters.yAxisParams.lowerBound,
                       max: data.computedParameters.yAxisParams.upperBound)
        
        return BarChartViewImpl(data: data,
                                state: state,
                                isStacked: isStacked,
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
        return ZStack {
            ForEach(0..<xValues.count, id: \.self) { i in
                self.barsView(xValue: xValues[i])
            }
        }
        .clipShape(Rectangle())
    }
}

public struct BarChart: View {
    /// The data to use for this chart.
    let data: ChartData
    
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
        ChartBase(data: data) { state, currentData, size in
            BarChart15(state: state, data: currentData, size: size)
        }
    }
}
