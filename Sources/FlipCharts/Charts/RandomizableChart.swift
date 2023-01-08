
import SwiftUI
import Toolbox

public struct RandomizableChart<ChartView: View>: View {
    /// Callback that is invoked to create a chart view from the current chart data.
    let createChart: (ChartData) -> ChartView
    
    /// The current chart data.
    @State var chartData: ChartData
    
    /// The current seed.
    @State var seed: UInt64
    
    /// The shared RNG for this session..
    @State var rng: ARC4RandomNumberGenerator
    
    /// Memberwise initializer.
    public init(seed: UInt64? = nil, createChart: @escaping (ChartData) -> ChartView) {
        self.createChart = createChart
        
        let seed = seed ?? UInt64(bitPattern: Int64(Date().timeIntervalSinceReferenceDate))
        self._seed = .init(initialValue: seed)
        
        var rng = ARC4RandomNumberGenerator(seed: seed)
        self._chartData = .init(initialValue: Self.createRandomChartData(using: &rng))
        self._rng = .init(initialValue: rng)
    }
    
    /// Create randomized chart data.
    static func createRandomChartData(using rng: inout ARC4RandomNumberGenerator) -> ChartData {
        if Bool.random(using: &rng) {
            return createRandomBarChartChartData(using: &rng)
        }
        else {
            return createRandomLineChartChartData(using: &rng)
        }
    }
    
    /// Create a random point style.
    static func randomPointStyle(color: Color, using rng: inout ARC4RandomNumberGenerator) -> PointStyle {
        .init(
            pointSize: 5,
            borderColor: color,
            fillColor: color,
            lineWidth: 2,
            pointType: .allCases.randomElement(using: &rng)!,
            pointShape: [PointStyle.PointShape.circle, .roundedSquare,
                         .square, .diamond].randomElement(using: &rng)!
        )
    }
    
    /// Create a random line style.
    static func randomLineStyle(color: Color, using rng: inout ARC4RandomNumberGenerator) -> LineStyle {
        return .init(
            type: .allCases.randomElement(using: &rng)!,
            fillType: .allCases.randomElement(using: &rng)!,
            stroke: .init(
                lineWidth: 2,
                dash: Bool.random(using: &rng) ? [.random(in: 1...5, using: &rng)] : []
            ),
            color: .solid(color),
            fillColor: .solid(color.opacity(0.50)),
            ignoreZero: false
        )
    }
    
    /// Create randomized chart data for a bar chart.
    static func createRandomBarChartChartData(using rng: inout ARC4RandomNumberGenerator) -> ChartData {
        let seriesCount = (1...3).randomElement(using: &rng)!
        let magnitude = (0...7).randomElement(using: &rng)!
        let valueCount = (10...100).randomElement(using: &rng)!
        let power = pow(10.0, Double(magnitude))
        
        var series: [DataSeries] = []
        for i in 0..<seriesCount {
            let maxValue = power
            let maxStep = power * 0.4
            let minStep = -power * 0.4
            let allPositive = Bool.random(using: &rng)
            
            var currentValue: Double
            if allPositive {
                currentValue = Double.random(in: 0..<maxValue, using: &rng)
            }
            else {
                currentValue = Double.random(in: -(maxValue*0.5)..<(maxValue*0.5), using: &rng)
            }
            
            var yValues: [Double] = [currentValue]
            for _ in 0..<valueCount {
                let step = Double.random(in: minStep...maxStep, using: &rng)
                if allPositive {
                    currentValue = max(0, currentValue + step)
                }
                else {
                    currentValue += step
                }
                
                yValues.append(currentValue)
            }
            
            let color = Color.random(using: &rng)
            series.append(.init(
                name: "Series\(i)",
                yValues: yValues,
                color: .solid(color),
                pointStyle: randomPointStyle(color: color, using: &rng),
                lineStyle: randomLineStyle(color: color, using: &rng)
            ))
        }
        
        let scrollingBehaviour: ChartScrollingBehaviour
        if Bool.random(using: &rng) {
            if Bool.random(using: &rng) {
                scrollingBehaviour = .continuous(visibleValueRange: Double.random(in: 3...10, using: &rng))
            }
            else {
                scrollingBehaviour = .segmented(visibleValueRange: Double.random(in: 3...10, using: &rng))
            }
        }
        else {
            scrollingBehaviour = .noScrolling
        }
        
        let config = ChartConfig(
            xAxisConfig: .xAxis(
                baseline: .zero,
                topline: .maximumValue,
                step: .automatic(),
                scrollingBehaviour: scrollingBehaviour,
                labelFormatter: FloatingPointFormatter.standard
            ),
            yAxisConfig: .yAxis(
                baseline: .zero,
                topline: .maximumValue,
                step: .automatic(),
                labelFormatter: FloatingPointFormatter.standard
            ),
            tapActions: [[ChartTapAction.highlightSingle, .highlightMultiple].randomElement(using: &rng)!],
            animation: .easeInOut(duration: 0.35)
        )
        
        return ChartData(config: config, series: series)
    }
    
    /// Create randomized chart data for a line chart.
    static func createRandomLineChartChartData(using rng: inout ARC4RandomNumberGenerator) -> ChartData {
        let data = createRandomBarChartChartData(using: &rng)
        let config = BarChartConfig(
            isStacked: Bool.random(using: &rng),
            preferredBarWidth: [5, 10, 25, 50].randomElement(using: &rng)!,
            config: data.config
        )
        
        return ChartData(config: config, series: data.series)
    }
    
    /// Creates the randomize button.
    var randomizeButton: some View {
        Button(action: {
            self.seed = .random(in: UInt64.min...UInt64.max, using: &rng)
            self.rng = .init(seed: seed)
            
            withAnimation(chartData.config.animation) {
                self.chartData = Self.createRandomChartData(using: &rng)
            }
        }) {
            Image(systemName: "clock.arrow.2.circlepath")
                .font(.body)
                .foregroundColor(.primary)
        }
    }
    
    public var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Text(verbatim: "\(seed)")
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.3))
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                    
                    Spacer()
                    
                    randomizeButton
                }
                .frame(height: geometry.size.height * 0.25)
                
                createChart(chartData)
                    .frame(height: geometry.size.height * 0.75)
                    .id(chartData.dataHash)
            }
        }
    }
}
