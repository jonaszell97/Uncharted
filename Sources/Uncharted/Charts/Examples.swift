
#if DEBUG

import SwiftUI
import Toolbox

internal final class PreviewUtility: ObservableObject {
    @Published var debugMessage: String? = nil
    static let shared = PreviewUtility()
    
    init() { }
}

struct BarChartPreviews {
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

struct LineChartPreviews {
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

struct RandomizableChart_Previews {
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

struct TimeSeriesPreviews {
    struct PreviewView: View {
        static let dateFormatter: Foundation.DateFormatter = {
            let dateFormatter = Foundation.DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateFormatter.timeZone = .utc
            
            return dateFormatter
        }()
        
        static func date(from string: String) -> Date {
            let date = dateFormatter.date(from: string)
            return date!
        }
        
        static let fullData: [(Date, Double)] = [
            (date(from: "2023-01-01T00:00:01+0000"), 10),
            (date(from: "2023-01-02T00:01:00+0000"), 6),
            (date(from: "2023-01-03T00:01:00+0000"), 1),
            (date(from: "2023-01-04T00:00:00+0000"), 13),
            (date(from: "2023-01-05T00:01:00+0000"), 5),
            (date(from: "2023-01-06T00:00:20+0000"), 19),
            (date(from: "2023-01-13T00:01:00+0000"), 25),
            (date(from: "2023-01-14T00:00:30+0000"), 1),
            (date(from: "2023-01-15T00:04:00+0000"), 6),
            (date(from: "2023-01-20T00:00:00+0000"), 5),
            (date(from: "2023-01-22T00:50:00+0000"), 3),
            (date(from: "2023-01-23T00:01:00+0000"), 17),
            (date(from: "2023-03-10T00:00:00+0000"), 15),
            (date(from: "2023-04-10T00:00:00+0000"), 16),
            (date(from: "2023-05-10T00:00:00+0000"), 17),
            (date(from: "2023-06-10T00:00:00+0000"), 18),
            (date(from: "2023-07-10T00:00:00+0000"), 19),
        ]
        
        @State var currentScope: TimeSeriesScope = .month
        @State var selectedDataPoint: DataPoint? = nil
        @State var chartState: ChartStateProxy? = nil
        @State var segmentIndex: Int = 0
        @ObservedObject var util: PreviewUtility = .shared
        
        let source = SummingTimeSeriesDataSource(data: Self.fullData)
        var body: some View {
            TimeSeriesView(source: source, scope: $currentScope) { timeSeriesData in
                let chartConfig = BarChartConfig(
                    maxBarWidth: 35,
                    centerBars: true,
                    xAxisConfig: .xAxis(step: .automatic(preferredSteps: 4),
                                        scrollingBehaviour: .continuous(visibleValueRange: 10),
                                        gridStyle: .defaultXAxisStyle,
                                        labelFormatter: currentScope.createDefaultFormatter(data: timeSeriesData)),
                    yAxisConfig: .yAxis(step: .automatic(preferredSteps: 5), gridStyle: .defaultYAxisStyle),
                    tapActions: [
                        .highlightSingle,
                        .custom { series, pt in
                            if let selectedDataPoint {
                                if selectedDataPoint == pt {
                                    self.selectedDataPoint = nil
                                    return
                                }
                            }
                            
                            self.selectedDataPoint = pt
                        }
                    ],
                    padding: .init(top: 0, leading: 0, bottom: 0, trailing: 0),
                    noDataAvailableText: "No Data")
                
                let chartData = ChartData(config: timeSeriesData.configure(chartConfig), series: [
                    DataSeries(name: "Series1", data: timeSeriesData.values, color: .solid(.red)),
                ])
                
                VStack {
                    HStack {
                        Spacer()
                        
                        if let debugMessage = util.debugMessage {
                            Text(verbatim: debugMessage)
                        }
                        else if let selectedDataPoint {
                            let label = chartConfig.xAxisConfig.labelFormatter(selectedDataPoint.x)
                            let value = chartConfig.yAxisConfig.labelFormatter(selectedDataPoint.y)
                            let index = Int(selectedDataPoint.x.rounded(.down))
                            
                            if timeSeriesData.dates.count > index, let date = timeSeriesData.dates[index] {
                                Text(verbatim: FormatToolbox.formatDate(date))
                            }
                            else {
                                Text(verbatim: label)
                            }
                            
                            Image(systemName: "circle.fill").font(.system(size: 5)).opacity(0.75)
                            Text(verbatim: value)
                        }
                        else {
                            Text(verbatim: timeSeriesData.scope.formatTimeInterval(timeSeriesData.interval, segmentIndex: self.segmentIndex))
                        }
                        
                        Spacer()
                    }
                    .font(.headline)
                    .foregroundColor(.init(uiColor: .secondaryLabel))
                    
                    BarChart(data: chartData)
                        .frame(height: 300)
                        .padding(.horizontal, 10)
                        .id(chartData.dataHash)
                    
                    TimeSeriesDefaultIntervalPickerView(currentScope: $currentScope)
                        .padding(10)
                }
                .observeChart { proxy in
                    self.segmentIndex = proxy.currentSegmentIndex
                }
            }
        }
    }
    
    static var previews: some View {
        PreviewView()
    }
}

struct Previews: PreviewProvider {
    static var previews: some View {
        RandomizableChart_Previews.previews
    }
}

#endif
