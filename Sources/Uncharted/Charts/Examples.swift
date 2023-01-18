
#if DEBUG

import SwiftUI
import Toolbox

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

struct TimeSeriesPreviews: PreviewProvider {
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
            (date(from: "2023-01-01T00:00:00+0000"), 1),
            (date(from: "2023-01-02T00:00:00+0000"), 2),
            (date(from: "2023-01-03T00:00:00+0000"), 3),
            (date(from: "2023-01-04T00:00:00+0000"), 4),
            (date(from: "2023-01-05T00:00:00+0000"), 5),
            (date(from: "2023-01-06T00:00:00+0000"), 6),
            (date(from: "2023-01-07T00:00:00+0000"), 7),
            (date(from: "2023-01-08T00:00:00+0000"), 8),
            (date(from: "2023-01-09T00:00:00+0000"), 9),
            (date(from: "2023-01-10T00:00:00+0000"), 10),
            (date(from: "2023-03-10T00:00:00+0000"), 15),
        ]
        
        @State var currentScope: TimeSeriesScope = .init(rawValue: UserDefaults.standard.string(forKey: "_time_interval") ?? "") ?? .week {
            didSet {
                UserDefaults.standard.set(currentScope.rawValue, forKey: "_time_interval")
            }
        }
        
        @State var chartState: ChartStateProxy? = nil
        
        let source = InterpolatingTimeSeriesDataSource(data: Self.fullData)
        var body: some View {
           TimeSeriesView(source: source, scope: $currentScope) { timeSeriesData in
                let config = LineChartConfig(
                    xAxisConfig: .xAxis(step: .automatic(preferredSteps: 4),
                                        scrollingBehaviour: .continuous(visibleValueRange: 10),
                                        gridStyle: .defaultXAxisStyle,
                                        labelFormatter: currentScope.createDefaultFormatter(startDate:
                                                                                                timeSeriesData.interval.start)),
                    yAxisConfig: .yAxis(step: .automatic(preferredSteps: 5), gridStyle: .defaultYAxisStyle),
                    padding: .init(top: 0, leading: 0, bottom: 0, trailing: 0),
                    noDataAvailableText: "No Data")
               
                let chartData = ChartData(config: timeSeriesData.configure(config), series: [
                    DataSeries(name: "Series1", data: timeSeriesData.values, color: .solid(.red)),
                ])
                
                VStack {
//                    if let chartState {
                        HStack {
                            Text(verbatim: currentScope.formatTimeInterval(timeSeriesData.interval))
                                .foregroundColor(.primary.opacity(0.50))
                            Spacer()
                        }
                        .padding(.trailing)
//                    }
                    
                    LineChart(data: chartData, chartState: $chartState)
                        .frame(height: 300)
                    
                    TimeSeriesDefaultIntervalPickerView(currentScope: $currentScope)
                        .padding()
                }
                .padding()
            }
        }
    }
    
    static var previews: some View {
        PreviewView()
    }
}

#endif
