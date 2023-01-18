
import SwiftUI
import Toolbox
import Panorama

extension View {
    func colorId(_ string: String) -> some View {
        self.background(Color.random(seed: UInt64(bitPattern: Int64(string.djb2Hash))).opacity(0.1)).id(string)
    }
}

fileprivate struct LineChartTapView: View {
    /// The available space for the line chart.
    let size: CGSize
    
    /// The series this line represents.
    let series: DataSeries
    
    /// The x-axis configuration.
    let xAxisParams: ComputedChartAxisData
    
    /// The y-axis configuration.
    let yAxisParams: ComputedChartAxisData
    
    /// The points to draw.
    let points: [DataPoint]
    
    /// The animation progress percentage.
    @ObservedObject var state: ChartState
    
    init(size: CGSize,
         series: DataSeries,
         xAxisParams: ComputedChartAxisData,
         yAxisParams: ComputedChartAxisData,
         adjacentDataPoints: [DataPoint]?,
         state: ChartState) {
        self.size = size
        self.series = series
        self.xAxisParams = xAxisParams
        self.yAxisParams = yAxisParams
        self.state = state
        
        var points = series.data
        if let adjacentDataPoints {
            points.append(contentsOf: adjacentDataPoints)
        }
        
        self.points = points.sorted { $0.x < $1.x }
    }
    
    private struct LineChartPoint: Identifiable {
        let name: String
        let x: Double
        let y: Double
        let index: Int
        
        var id: String { "series_\(name)_\(x)_\(y)" }
    }
    
    private func getPointPosition(pt: LineChartPoint) -> CGSize {
        let relativeX = (pt.x - xAxisParams.lowerBound) / (xAxisParams.upperBound - xAxisParams.lowerBound)
        let relativeY = ((pt.y - yAxisParams.lowerBound) / (yAxisParams.upperBound - yAxisParams.lowerBound))
            * CGFloat(state.appearanceAnimationProgress)
        
        return .init(width: CGFloat(relativeX) * size.width - size.width * 0.5,
                     height: CGFloat(1-relativeY) * size.height - size.height * 0.5)
    }
    
    private func pointAndLineView(pt: LineChartPoint,
                                  previousPt: LineChartPoint?,
                                  nextPt: LineChartPoint?) -> some View {
        let ptPosition = getPointPosition(pt: pt)
        let highlighted = state.highlightedDataPoints.contains {
            $0.0 == series.name && $0.1.x == pt.x
        }
        
        return ZStack {
            if highlighted {
                let gridStyle = state.fullData.config.xAxisConfig.gridStyle
                LineShape(edge: .leading)
                    .stroke(series.color.swiftUIShapeStyle,
                            style: gridStyle.swiftUIStrokeStyle(lineWidth: gridStyle.lineWidth * 3))
                    .frame(width: gridStyle.lineWidth)
                    .offset(x: ptPosition.width)
            }
        }
    }
    
    var body: some View {
        let points = self.points.enumerated().map {
            LineChartPoint(name: series.name, x: $0.element.x, y: $0.element.y, index: $0.offset)
        }
        
        return ZStack {
            ForEach(points) { pt in
                self.pointAndLineView(pt: pt,
                                      previousPt: points.tryGet(pt.index - 1),
                                      nextPt: points.tryGet(pt.index + 1))
            }
        }
    }
}

fileprivate struct LineChartLineView: View {
    /// The available space for the line chart.
    let size: CGSize
    
    /// The series this line represents.
    let series: DataSeries
    
    /// The x-axis configuration.
    let xAxisParams: ComputedChartAxisData
    
    /// The y-axis configuration.
    let yAxisParams: ComputedChartAxisData
    
    /// The points to draw.
    let points: [DataPoint]
    
    /// The animation progress percentage.
    @ObservedObject var state: ChartState
    
    init(size: CGSize,
         series: DataSeries,
         xAxisParams: ComputedChartAxisData,
         yAxisParams: ComputedChartAxisData,
         adjacentDataPoints: [DataPoint]?,
         state: ChartState) {
        self.size = size
        self.series = series
        self.xAxisParams = xAxisParams
        self.yAxisParams = yAxisParams
        self.state = state
        
        var points = series.data
        if let adjacentDataPoints {
            points.append(contentsOf: adjacentDataPoints)
        }
        
        self.points = points.sorted { $0.x < $1.x }
    }
    
    var body: some View {
        series.lineStyle?.createLineView(points: points,
                                         xAxisParams: xAxisParams,
                                         yAxisParams: yAxisParams,
                                         animationProgress: $state.appearanceAnimationProgress)
            .opacity(state.highlightedDataPoints.isEmpty ? 1 : 0.75)
    }
}

fileprivate struct LineChartPointsView: View {
    /// The available space for the line chart.
    let size: CGSize
    
    /// The series this line represents.
    let series: DataSeries
    
    /// The x-axis configuration.
    let xAxisParams: ComputedChartAxisData
    
    /// The y-axis configuration.
    let yAxisParams: ComputedChartAxisData
    
    /// The points to draw.
    let points: [DataPoint]
    
    /// The animation progress percentage.
    @ObservedObject var state: ChartState
    
    init(size: CGSize,
         series: DataSeries,
         xAxisParams: ComputedChartAxisData,
         yAxisParams: ComputedChartAxisData,
         adjacentDataPoints: [DataPoint]?,
         state: ChartState) {
        self.size = size
        self.series = series
        self.xAxisParams = xAxisParams
        self.yAxisParams = yAxisParams
        self.state = state
        
        var points = series.data
        if let adjacentDataPoints {
            points.append(contentsOf: adjacentDataPoints)
        }
        
        self.points = points.sorted { $0.x < $1.x }
    }
    
    var body: some View {
        series.pointStyle?.createPointsView(points: points,
                                            xAxisParams: xAxisParams,
                                            yAxisParams: yAxisParams,
                                            animationProgress: $state.appearanceAnimationProgress)
            .opacity(state.highlightedDataPoints.isEmpty ? 1 : 0.75)
    }
}

public struct LineChart: View {
    /// The data to use for this chart.
    let fullData: ChartData
    
    /// Optional binding that is updated with the chart state.
    @Binding var chartState: ChartStateProxy?
    
    /// Default initializer.
    public init(data: ChartData, chartState: Binding<ChartStateProxy?> = .constant(nil)) {
        if !(data.config is LineChartConfig) {
            self.fullData = .init(config: LineChartConfig(config: data.config), series: data.series)
        }
        else {
            self.fullData = data
        }
        
        self._chartState = chartState
    }
    
    private struct LineChartPart: Identifiable {
        let name: String
        let minX: Double
        let maxX: Double
        let index: Int
        
        var id: String { "series_\(name)_\(minX)_\(maxX)_points" }
        var id2: String { "series_\(name)_\(minX)_\(maxX)_points2" }
    }
    
    private struct LineChartLine: Identifiable {
        let name: String
        let minX: Double
        let maxX: Double
        let index: Int
        
        var id: String { "series_\(name)_\(minX)_\(maxX)_line" }
    }
    
    public var body: some View {
        ChartBase(data: fullData) { state, data, size in
            let parts = data.series.enumerated().map {
                LineChartPart(name: $0.element.name, minX: $0.element.min.x, maxX: $0.element.max.x, index: $0.offset)
            }
            
            let lines = data.series.filter { $0.lineStyle != nil }.enumerated().map {
                LineChartLine(name: $0.element.name, minX: $0.element.min.x, maxX: $0.element.max.x, index: $0.offset)
            }
            
            ZStack {
                ForEach(lines) { line in
                    let series = data.series[line.index]
                    LineChartLineView(size: size,
                                      series: series,
                                      xAxisParams: data.computedParameters.xAxisParams,
                                      yAxisParams: data.computedParameters.yAxisParams,
                                      adjacentDataPoints: data.computedParameters.adjacentDataPoints[series.name],
                                      state: state)
                    .clipShape(Rectangle())
                    .frame(width: size.width, height: size.height)
                }
                
                ForEach(parts, id: \.id2) { part in
                    let series = data.series[part.index]
                    LineChartPointsView(size: size,
                                      series: series,
                                      xAxisParams: data.computedParameters.xAxisParams,
                                      yAxisParams: data.computedParameters.yAxisParams,
                                      adjacentDataPoints: data.computedParameters.adjacentDataPoints[series.name],
                                      state: state)
                    .clipShape(Rectangle())
                    .frame(width: size.width, height: size.height)
                }
                
                ForEach(parts) { part in
                    let series = data.series[part.index]
                    LineChartTapView(size: size,
                                     series: series,
                                     xAxisParams: data.computedParameters.xAxisParams,
                                     yAxisParams: data.computedParameters.yAxisParams,
                                     adjacentDataPoints: data.computedParameters.adjacentDataPoints[series.name],
                                     state: state)
                        .frame(width: size.width, height: size.height)
                }
            }
            .onAppear {
                self.chartState = .init(state: state)
            }
            .onChange(of: data.computedParameters.xAxisParams) { _ in
                self.chartState = .init(state: state)
            }
            .onTouch { tapPos in
                let xAxisParams = data.computedParameters.xAxisParams
                let yAxisParams = data.computedParameters.yAxisParams
                
                var closestXDistance = CGFloat.infinity
                var closestYDistance = CGFloat.infinity
                var closestPt: (String, DataPoint)? = nil
                
                for series in data.series {
                    for pt in series.data {
                        let relativeX = (pt.x - xAxisParams.lowerBound) / (xAxisParams.upperBound - xAxisParams.lowerBound)
                        let relativeY = ((pt.y - yAxisParams.lowerBound) / (yAxisParams.upperBound - yAxisParams.lowerBound))
                        
                        let ptPos = CGPoint(x: CGFloat(relativeX) * size.width,
                                            y: CGFloat(1-relativeY) * size.height)
                        
                        let xDistance = abs(ptPos.x - tapPos.x)
                        let yDistance = abs(ptPos.y - tapPos.y)
                        
                        if xDistance < closestXDistance {
                            closestXDistance = xDistance
                            closestYDistance = yDistance
                            closestPt = (series.name, pt)
                        }
                        else if xDistance == closestXDistance, yDistance < closestYDistance {
                            closestXDistance = xDistance
                            closestYDistance = yDistance
                            closestPt = (series.name, pt)
                        }
                    }
                }
                
                guard let (series, pt) = closestPt else {
                    return
                }
                
                state.runTapActions(for: pt, in: series)
            }
        }
    }
}
