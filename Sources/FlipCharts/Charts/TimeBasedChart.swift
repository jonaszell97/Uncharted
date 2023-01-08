
import SwiftUI
import Toolbox

public enum ChartDataAggregationMethod {
    /// Use the arithmetic mean of the values in each interval.
    case arithmeticMean
    
    /// Show the values in each interval as a range.
    case range
}

public struct TimeBasedChartData {
    /// The base chart data in hourly resolution with 0-based x indices.
    let baseData: ChartData
    
    /// The interval that the data is in.
    let dataInterval: DateComponents
    
    /// The start date of the base data.
    let baseStartDate: Date
    
    /// Default initializer.
    public init(baseData: ChartData,
                baseStartDate: Date,
                baseInterval: DateComponents) {
        self.baseData = baseData
        self.dataInterval = baseInterval
        self.baseStartDate = baseStartDate
    }
    
    func data(interval: DateComponents, aggregationMethod: ChartDataAggregationMethod) -> ChartData {
        return .init(config: baseData.config, series: baseData.series.map {
            self.series(interval: interval, series: $0, aggregationMethod: aggregationMethod)
        })
    }
    
    func series(interval: DateComponents, series: DataSeries, aggregationMethod: ChartDataAggregationMethod) -> DataSeries {
        let nextTargetDate = Calendar.reference.date(byAdding: interval, to: baseStartDate)!
        let nextDataDate = Calendar.reference.date(byAdding: dataInterval, to: baseStartDate)!
        
        guard nextTargetDate != nextDataDate else {
            return series
        }
        
        var transformedData = [DataPoint]()
        
        // Desired interval > given interval -> aggregate data
        if nextTargetDate > nextDataDate {
            var currentDate = baseStartDate
            var nextDate = Calendar.reference.date(byAdding: interval, to: baseStartDate)!
            
            var xValue = 0.0
            var i = 0
            
            while i < series.data.count {
                var currentAggregatedData = [Double]()
                while currentDate < nextDate, i < series.data.count {
                    currentAggregatedData.append(series.data[i].y)
                    currentDate = Calendar.reference.date(byAdding: dataInterval, to: currentDate)!
                    
                    i += 1
                }
                
                switch aggregationMethod {
                case .arithmeticMean:
                    transformedData.append(.init(x: xValue, y: currentAggregatedData.mean ?? 0))
                case .range:
                    fatalError("unimplemented!")
                }
                
                xValue += 1
                nextDate = Calendar.reference.date(byAdding: interval, to: nextDate)!
            }
        }
        // Desired interval < given interval -> repeat data
        else {
            var currentDate = baseStartDate
            var nextDate = Calendar.reference.date(byAdding: dataInterval, to: baseStartDate)!
            var xValue = 0.0
            
            for dp in series.data {
                while currentDate < nextDate {
                    transformedData.append(.init(x: xValue, y: dp.y))
                    currentDate = Calendar.reference.date(byAdding: interval, to: currentDate)!
                    xValue += 1
                }
                
                currentDate = nextDate
                nextDate = Calendar.reference.date(byAdding: dataInterval, to: nextDate)!
            }
        }
        
        return .init(name: series.name, data: transformedData, color: series.color,
                     pointStyle: series.pointStyle, lineStyle: series.lineStyle)
    }
    
    /// Create a formatter for the given interval.
    public static func createDefaultFormatter(for resolution: TimeBasedChartScope,
                                              startDate: Date,
                                              locale: Locale? = nil,
                                              dataCount: Int? = nil) -> CustomDataFormatter {
        switch resolution {
        case .day:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: resolution.dateComponents(times: Int(value)),
                    to: startDate)!
                let hour = Calendar.reference.component(.hour, from: date)
                
                return "\(hour)"
            }
        case .week:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: resolution.dateComponents(times: Int(value)),
                    to: startDate)!
                let weekday = Calendar.reference.component(.weekday, from: date)
                
                return "\(defaultWeekdayFormat(weekday: weekday, languageCode: locale?.languageCode))"
            }
        case .month:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: resolution.dateComponents(times: Int(value)),
                    to: startDate)!
                let day = Calendar.reference.component(.day, from: date)
                
                if day <= 7 || value == 0 {
                    let month = Calendar.reference.component(.month, from: date)
                    if month == 1 {
                        let year = Calendar.reference.component(.year, from: date)
                        return "\(year)"
                    }
                    
                    return "\(defaultMonthFormat(month: month, languageCode: locale?.languageCode))"
                }
                
                return "\(day)"
            }
        case .year:
            fallthrough
        case .threeMonths:
            fallthrough
        case .sixMonths:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: resolution.dateComponents(times: Int(value)),
                    to: startDate)!
                let month = Calendar.reference.component(.month, from: date)
                
                if case .year = resolution, dataCount == nil || dataCount! > 6 {
                    return "\(defaultMonthFormat(month: month, languageCode: locale?.languageCode).first!)"
                }
                else {
                    return "\(defaultMonthFormat(month: month, languageCode: locale?.languageCode))"
                }
            }
        }
    }
    
}

public struct TimeBasedChartDefaultIntervalPickerView: View {
    /// The selected interval.
    @Binding var currentTimeInterval: TimeBasedChartScope
    
    /// The supported time intervals.
    let supportedTimeIntervals: [TimeBasedChartScope]
    
    /// Optional formatting function for time intervals.
    let timeIntervalFormat: ChartTimeIntervalFormat
    
    /// Default initializer.
    public init(currentTimeInterval: Binding<TimeBasedChartScope>,
                supportedTimeIntervals: [TimeBasedChartScope] = TimeBasedChartScope.allCases,
                timeIntervalFormat: ChartTimeIntervalFormat = .short) {
        self._currentTimeInterval = currentTimeInterval
        self.supportedTimeIntervals = supportedTimeIntervals
        self.timeIntervalFormat = timeIntervalFormat
    }
    
    public var body: some View {
        Picker("Interval", selection: $currentTimeInterval) {
            ForEach(supportedTimeIntervals) { interval in
                Text(self.timeIntervalFormat(interval))
            }
        }
        .pickerStyle(.segmented)
    }
}

public func formatCurrentTimeInterval(baseDate: Date,
                                      data: ChartData,
                                      resolution: TimeBasedChartScope) -> String {
    let startDate = Calendar.reference.date(
        byAdding: resolution.dateComponents(times: Int(data.computedParameters.xAxisParams.lowerBound)),
        to: baseDate)!
    let endDate = Calendar.reference.date(
        byAdding: resolution.dateComponents(times: Int(data.computedParameters.xAxisParams.upperBound)),
        to: baseDate)!
    let tz = Calendar.reference.timeZone
    
    switch resolution {
    case .day:
        return "\(FormatToolbox.formatDate(startDate)) \(FormatToolbox.formatTime(startDate, timeZone: tz, timeStyle: .short)) - \(FormatToolbox.formatTime(endDate, timeZone: tz, timeStyle: .short))"
    case .week:
        fallthrough
    case .month:
        fallthrough
    case .threeMonths:
        fallthrough
    case .sixMonths:
        fallthrough
    case .year:
        return "\(FormatToolbox.formatDate(startDate)) - \(FormatToolbox.formatDate(endDate))"
    }
}

public struct TimeBasedChartView<ChartContent: View>: View {
    /// The chart data.
    let data: TimeBasedChartData
    
    /// The selected interval.
    @Binding var currentTimeInterval: TimeBasedChartScope
    
    /// The aggregation method to use when combining values.
    let dataAggregationMethod: ChartDataAggregationMethod
    
    /// An optional custom data formatter.
    let buildXAxisLabelFormatter: Optional<(TimeBasedChartScope, [DataSeries]) -> any DataFormatter>
    
    /// The chart builder.
    let buildChartView: (ChartData) -> ChartContent
    
    /// The current chart data.
    @State var currentChartData: ChartData? = nil
    
    /// Whether or not to start at the end of the chart.
    let scrollToEnd: Bool
    
    /// Default initializer.
    public init(data: TimeBasedChartData,
                currentTimeInterval: Binding<TimeBasedChartScope>,
                dataAggregationMethod: ChartDataAggregationMethod = .arithmeticMean,
                scrollToEnd: Bool = false,
                buildXAxisLabelFormatter: Optional<(TimeBasedChartScope, [DataSeries]) -> any DataFormatter> = nil,
                @ViewBuilder buildChartView: @escaping (ChartData) -> ChartContent) {
        self.data = data
        self.dataAggregationMethod = dataAggregationMethod
        self.scrollToEnd = scrollToEnd
        self.buildXAxisLabelFormatter = buildXAxisLabelFormatter
        self.buildChartView = buildChartView
        self._currentTimeInterval = currentTimeInterval
    }
    
    /// Create a formatter for the given interval.
    func createDefaultFormatter(for resolution: TimeBasedChartScope) -> CustomDataFormatter {
        TimeBasedChartData.createDefaultFormatter(for: resolution, startDate: data.baseStartDate, locale: .autoupdatingCurrent)
    }
    
    /// Create chart data for the currently selected time interval.
    func getChartData(for resolution: TimeBasedChartScope) -> ChartData {
        let transformedData = data.baseData.series.map {
            self.getDataSeries(series: $0, in: resolution)
        }
        
        var xAxisConfig = data.baseData.config.xAxisConfig
        if let buildXAxisLabelFormatter {
            xAxisConfig.labelFormatter = buildXAxisLabelFormatter(resolution, transformedData)
        }
        else {
            xAxisConfig.labelFormatter = self.createDefaultFormatter(for: resolution)
        }
        
        let config = data.baseData.config
        config.xAxisConfig = xAxisConfig
        
        if self.scrollToEnd {
            if let maxXValue = (transformedData.max {
                ($0.data.last?.x ?? 0) < ($1.data.last?.x ?? 0)
            }?.data.last?.x) {
                config.initialXValue = maxXValue
            }
        }
        
        switch resolution {
        case .day:
            xAxisConfig.step = .fixed(6)
            xAxisConfig.visibleValueRange = 24
        case .week:
            xAxisConfig.step = .fixed(1)
            xAxisConfig.visibleValueRange = 7
        case .month:
            xAxisConfig.step = .fixed(7)
            xAxisConfig.visibleValueRange = 28
        case .threeMonths:
            xAxisConfig.step = .fixed(4)
            xAxisConfig.visibleValueRange = 12
        case .sixMonths:
            xAxisConfig.step = .fixed(2)
            xAxisConfig.visibleValueRange = 12
        case .year:
            xAxisConfig.step = .fixed(1)
            xAxisConfig.visibleValueRange = 12
        }
        
        return .init(config: config, series: transformedData)
    }
    
    func getDataSeries(series: DataSeries, in resolution: TimeBasedChartScope) -> DataSeries {
        self.data.series(interval: resolution.dateComponents,
                         series: series,
                         aggregationMethod: dataAggregationMethod)
    }
    
    public var body: some View {
        ZStack {
            if let currentChartData = self.currentChartData {
                self.buildChartView(currentChartData)
                    .id(currentChartData.computedParameters.xAxisParams.labels.hashValue)
            }
        }
        .onAppear {
            self.currentChartData = self.getChartData(for: self.currentTimeInterval)
        }
        .onChange(of: self.currentTimeInterval) { interval in
            self.currentChartData = self.getChartData(for: interval)
        }
    }
}
