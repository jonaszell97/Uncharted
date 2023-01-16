
#if DEBUG

import SwiftUI
import Toolbox

struct BarChartPreviews: PreviewProvider {
    static let seed: UInt64 = 1234
    internal static func createExampleData() -> ChartData {
        let data: ChartData = .init(
            config: BarChartConfig(
                isStacked: true,
                preferredBarWidth: 30,
                centerBars: true,
                xAxisConfig: .xAxis(step: .fixed(1),
                                    scrollingBehaviour: .segmented(visibleValueRange: 4),
                                    gridStyle: .defaultXAxisStyle),
                yAxisConfig: .yAxis(baseline: .zero, step: .automatic(preferredSteps: 5), gridStyle: .defaultYAxisStyle),
                padding: .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            ),
            series: [
                .init(name: "Series1", yValues: [3, 2, -2, 2, 1, 8, 4], color: .solid(.teal)),
            ]
        )
        
        return data
    }
    
    static var previews: some View {
        let data = createExampleData()
        return ScrollView {
            
            BarChart(data: data)
                .padding()
                .frame(height: 300)
        }
    }
}

struct LineChartPreviews: PreviewProvider {
    internal static let seed: UInt64 = 685_546_733
    internal static func createExampleData() -> ChartData {
        let data: ChartData = .init(
            config: LineChartConfig(
                xAxisConfig: .xAxis(step: .fixed(1),
                                    scrollingBehaviour: .continuous(visibleValueRange: 5),
                                    gridStyle: .defaultXAxisStyle),
                yAxisConfig: .yAxis(step: .automatic(preferredSteps: 5), gridStyle: .defaultYAxisStyle),
                padding: .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            ),
            series: [
                .init(name: "Series2", yValues: (0...10).map { Double($0) },
                      markers: [
                        .point(style: .standard(color: .red), position: .init(x: 10, y: 12)),
                        .line(style: StrokeStyle(lineWidth: 2), color: .blue, start: .init(x: 10, y: 5), end: .init(x: 20, y: 15)),
                        .label("Hello", font: .body, foregroundColor: .orange, position: .init(x: 7, y: 3)),
                        .view(AnyView(Rectangle().fill(Color.red).frame(width: 20, height: 20)), position: .init(x: 13, y: 10))
                      ],
                      color: .solid(.mint)),
            ]
        )
        
        return data
    }
    
    static var previews: some View {
        let data = createExampleData()
        return VStack {
            Text("\(seed)")
            
            LineChart(data: data)
                .padding()
                .frame(height: 300)
        }
    }
}

struct RandomizableChart_Previews: PreviewProvider {
    static var previews: some View {
        let bounds = UIScreen.main.bounds.size
        
        return VStack {
            RandomizableChart { data in
                BarChart(data: data)
            }
            .frame(height: bounds.height * 0.35)
            .padding()
            
            RandomizableChart(seed: 686038741) { data in
                LineChart(data: data)
            }
            .frame(height: bounds.height * 0.35)
            .padding()
        }
    }
}

struct TimeBasedChartPreviews: PreviewProvider {
    internal static let seed: UInt64 = 685_546_733
    internal static func createExampleData() -> ChartData {
        let data: ChartData = .init(
            config: LineChartConfig(
                xAxisConfig: .xAxis(step: .automatic(preferredSteps: 4),
                                    scrollingBehaviour: .continuous(visibleValueRange: 10),
                                    gridStyle: .defaultXAxisStyle),
                yAxisConfig: .yAxis(step: .automatic(preferredSteps: 5), gridStyle: .defaultYAxisStyle),
                padding: .init(top: 0, leading: 0, bottom: 0, trailing: 0),
                noDataAvailableText: "No Data"
            ),
            series: [
                .init(name: "Series2", yValues: (0...22).map { Double($0) }, color: .solid(.mint)),
            ]
        )
        
        return data
    }
    
    struct PreviewView: View {
        @State var currentTimeInterval: TimeBasedChartScope = .week
        @State var visibleData: ChartData? = nil
        
        let data = createExampleData()
        
        var body: some View {
            let baseDate = Date().startOfDay
            return TimeBasedChartView(data: .init(baseData: data, baseStartDate: baseDate, baseInterval: .init()),
                                      currentTimeInterval: $currentTimeInterval,
                                      dataAggregationMethod: .arithmeticMean,
                                      buildXAxisLabelFormatter: nil) { data in
                VStack {
                    if let visibleData {
                        HStack {
                            Text(verbatim: formatCurrentTimeInterval(baseDate: baseDate, data: visibleData,
                                                                     resolution: currentTimeInterval))
                            .foregroundColor(.primary.opacity(0.50))
                            Spacer()
                        }
                        .padding(.trailing)
                    }
                    
                    LineChart(data: data, visibleChartData: $visibleData)
                        .frame(height: 300)
                    
                    TimeBasedChartDefaultIntervalPickerView(currentTimeInterval: $currentTimeInterval)
                        .padding()
                }
                .padding()
            }
        }
    }
    
    static var previews: some View {
        return VStack {
            Text("\(seed)")
            PreviewView()
        }
    }
}

#endif
