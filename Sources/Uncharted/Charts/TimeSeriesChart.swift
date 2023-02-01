
import SwiftUI
import Toolbox

public enum ChartDataAggregationMethod {
    /// Use the arithmetic mean of the values in each interval.
    case arithmeticMean
    
    /// Show the values in each interval as a range.
    case range
}

fileprivate func offsetInterval(scope: TimeSeriesScope, interval: DateInterval, segmentIndex: Int) -> DateInterval {
    let offset: DateComponents
    let length: DateComponents
    
    switch scope {
    case .day:
        offset = .init(hour: 24 * segmentIndex)
        length = .init(hour: 24)
    case .week:
        offset = .init(day: 7 * segmentIndex)
        length = .init(day: 7)
    case .month:
        offset = .init(month: 1 * segmentIndex)
        length = .init(month: 1)
    case .threeMonths:
        offset = .init(month: 3 * segmentIndex)
        length = .init(month: 3)
    case .sixMonths:
        offset = .init(month: 6 * segmentIndex)
        length = .init(month: 6)
    case .year:
        offset = .init(year: 1 * segmentIndex)
        length = .init(year: 1)
    }
    
    let firstDate = Calendar.reference.date(byAdding: offset, to: interval.start)!
    let lastDate = Calendar.reference.date(byAdding: length, to: firstDate)!
    
    return DateInterval(start: firstDate, end: lastDate)
}

extension TimeSeriesScope {
    /// The date used as a sentinel value to pad months to equal length.
    static let sentinelDate: Date = Date(timeIntervalSinceReferenceDate: Date.distantFuture.timeIntervalSinceReferenceDate - 1)
    
    /// The dates within an interval for this scope.
    fileprivate func dates(in interval: DateInterval) -> ([Date?], DateInterval) {
        let firstDate: Date
        let lastDate: Date
        let step: DateComponents
        
        switch self {
        case .day:
            firstDate = interval.start.startOfDay
            lastDate = interval.end.endOfDay
            step = DateComponents(hour: 1)
        case .week:
            firstDate = interval.start.startOfWeek(weekStartsOn: .monday)
            lastDate = interval.end.endOfWeek(weekStartsOn: .monday)
            step = DateComponents(day: 1)
        case .month:
            firstDate = interval.start.startOfMonth
            lastDate = interval.end.endOfMonth
            step = DateComponents(day: 1)
        case .threeMonths:
            firstDate = interval.start.startOfQuarter
            lastDate = interval.end.endOfQuarter
            step = DateComponents(month: 1)
        case .sixMonths:
            firstDate = interval.start.startOfYearHalf
            lastDate = interval.end.endOfYearHalf
            step = DateComponents(month: 1)
        case .year:
            firstDate = interval.start.startOfYear
            lastDate = interval.end.endOfYear
            step = DateComponents(month: 1)
        }
        
        var dates = [Date?]()
        var currentDate = firstDate
        
        while currentDate <= lastDate {
            dates.append(currentDate)
            
            let currentMonth = Calendar.reference.component(.month, from: currentDate)
            currentDate = Calendar.reference.date(byAdding: step, to: currentDate)!
            
            let newMonth = Calendar.reference.component(.month, from: currentDate)
            if currentMonth != newMonth {
                // Pad months to 32 days
                while case .month = self, dates.count % 32 != 0 {
                    dates.append(nil)
                }
            }
        }
        
        let dateInterval = DateInterval(start: firstDate, end: lastDate)
        return (dates, dateInterval)
    }
    
    /// - returns: A string representing the selected interval in the given locale.
    public func formatTimeInterval(_ interval: DateInterval, segmentIndex: Int? = nil, locale: Locale? = nil) -> String {
        var interval = interval
        if let segmentIndex {
            interval = offsetInterval(scope: self, interval: interval, segmentIndex: segmentIndex)
        }
        
        switch self {
        case .day:
            return FormatToolbox.formatDate(interval.start)
        case .week:
            return "\(FormatToolbox.formatDate(interval.start)) - \(FormatToolbox.formatDate(interval.end))"
        case .month:
            let components = Calendar.reference.dateComponents([.month,.year], from: interval.start)
            return "\(longMonthFormat(month: components.month!, languageCode: locale?.languageCode)) \(components.year!)"
        case .threeMonths:
            let components = Calendar.reference.dateComponents([.month,.year], from: interval.start)
            let quarter: Int = Int((Double(components.month!) / 3).rounded(.awayFromZero))
            
            return "Q\(quarter) \(components.year!)"
        case .sixMonths:
            let components = Calendar.reference.dateComponents([.month,.year], from: interval.start)
            let half: Int = Int((Double(components.month!) / 6).rounded(.awayFromZero))
            
            return "H\(half) \(components.year!)"
        case .year:
            let year = Calendar.reference.component(.year, from: interval.start)
            return "\(year)"
        }
    }
    
    /// - returns: A default formatter for the given interval.
    public func createDefaultFormatter(data: TimeSeriesData, locale: Locale? = nil)
        -> CustomDataFormatter
    {
        switch self {
        case .day:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: self.dateComponents(times: Int(value)),
                    to: data.interval.start)!
                let hour = Calendar.reference.component(.hour, from: date)
                
                return "\(hour)"
            }
        case .week:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: self.dateComponents(times: Int(value)),
                    to: data.interval.start)!
                let weekday = Calendar.reference.component(.weekday, from: date)
                
                return "\(defaultWeekdayFormat(weekday: weekday, languageCode: locale?.languageCode))"
            }
        case .month:
            return CustomDataFormatter { value in
                guard let date = data.dates.tryGet(Int(value.rounded(.towardZero))), let date else {
                    return ""
                }
                
                let day = Calendar.reference.component(.day, from: date)
                if day <= 7 || value == 0 {
                    let month = Calendar.reference.component(.month, from: date)
                    if month == 1 {
                        let year = Calendar.reference.component(.year, from: date)
                        return "\(defaultMonthFormat(month: month, languageCode: locale?.languageCode)) \("\(year)".suffix(2))"
                    }
                    
                    return "\(defaultMonthFormat(month: month, languageCode: locale?.languageCode))"
                }
                
                return "\(day)"
            }
        case .year:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: self.dateComponents(times: Int(value)),
                    to: data.interval.start)!
                let month = Calendar.reference.component(.month, from: date)
                
                return "\(defaultMonthFormat(month: month, languageCode: locale?.languageCode).first!)"
            }
        case .threeMonths:
            fallthrough
        case .sixMonths:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: self.dateComponents(times: Int(value)),
                    to: data.interval.start)!
                let month = Calendar.reference.component(.month, from: date)
                
                return "\(defaultMonthFormat(month: month, languageCode: locale?.languageCode))"
            }
        }
    }
}

public struct TimeSeriesDefaultIntervalPickerView: View {
    /// The selected interval.
    @Binding var currentScope: TimeSeriesScope
    
    /// The supported time intervals.
    let supportedScopes: [TimeSeriesScope]
    
    /// Optional formatting function for time intervals.
    let scopeFormat: ChartScopeFormat
    
    /// Default initializer.
    public init(currentScope: Binding<TimeSeriesScope>,
                supportedScopes: [TimeSeriesScope] = TimeSeriesScope.allCases,
                scopeFormat: ChartScopeFormat = .short) {
        self._currentScope = currentScope
        self.supportedScopes = supportedScopes
        self.scopeFormat = scopeFormat
    }
    
    public var body: some View {
        Picker("Interval", selection: $currentScope) {
            ForEach(supportedScopes) { interval in
                Text(self.scopeFormat(interval))
            }
        }
        .pickerStyle(.segmented)
    }
}

public struct TimeSeriesData {
    /// The selected scope.
    public let scope: TimeSeriesScope
    
    /// The selected interval.
    public let interval: DateInterval
    
    /// The dates in the selected interval.
    public let dates: [Date?]
    
    /// The data series for the selected interval.
    public let values: [DataPoint]
    
    /// A function to configure the chart config appropriately for the current time series data.
    public let configure: (ChartConfig) -> ChartConfig
    
    /// The hash value of the current dataset.
    let hashValue: Int
    
    /// Memberwise initializer.
    internal init(scope: TimeSeriesScope,
                  interval: DateInterval,
                  dates: [Date?],
                  values: [DataPoint],
                  configure: @escaping (ChartConfig) -> ChartConfig) {
        self.scope = scope
        self.interval = interval
        self.dates = dates
        self.values = values
        self.configure = configure
        
        var hasher = Hasher()
        hasher.combine(scope)
        hasher.combine(values)
        
        self.hashValue = hasher.finalize()
    }
    
    /// - returns: The currently visible date interval based on the selected segment index.
    public func interval(forSegment segmentIndex: Int) -> DateInterval {
        offsetInterval(scope: scope, interval: interval, segmentIndex: segmentIndex)
    }
}

public struct TimeSeriesView<ChartContent: View>: View {
    /// The chart data.
    let source: TimeSeriesDataSource
    
    /// The chart builder.
    let buildChartView: (TimeSeriesData) -> ChartContent
    
    /// The current scope.
    @Binding var scope: TimeSeriesScope
    
    /// The time series data.
    @State var data: TimeSeriesData? = nil
    
    /// The chart state.
    @State var chartState: ChartStateProxy? = nil
    
    /// Default initializer.
    public init(source: TimeSeriesDataSource,
                scope: Binding<TimeSeriesScope>,
                @ViewBuilder buildChartView: @escaping (TimeSeriesData) -> ChartContent) {
        self.source = source
        self.buildChartView = buildChartView
        self._scope = scope
    }
    
    /// Create chart data for the currently selected time interval.
    func getChartData(for resolution: TimeSeriesScope) -> TimeSeriesData {
        let interval = source.interval
        let (dates, valueInterval) = resolution.dates(in: interval)
        let values = (0..<(dates.count-1))
            .map { (i: Int) -> (Int, Double?) in
                guard let currentDate = dates[i] else {
                    return (i, nil)
                }
                
                var nextIndex = i + 1
                while nextIndex < dates.count, dates[nextIndex] == nil {
                    nextIndex += 1
                }
                
                guard nextIndex < dates.count, let nextDate = dates[nextIndex] else {
                    return (i, nil)
                }
                
                return (i, source.combinedValue(in: DateInterval(start: currentDate, end: nextDate)))
            }
            .filter { $0.1 != nil }
            .map { DataPoint(x: Double($0.0), y: $0.1!) }
        
        let configure = { (config: ChartConfig) -> ChartConfig in
            config.xAxisConfig.baseline = .zero
            
            if let barChartConfig = config as? BarChartConfig {
                switch resolution {
                case .day:
                    fallthrough
                case .month:
                    barChartConfig.centerBars = false
                default:
                    barChartConfig.centerBars = true
                }
            }
            
            switch resolution {
            case .day:
                config.xAxisConfig.step = .fixed(6)
                config.xAxisConfig.scrollingBehaviour = .segmented(visibleValueRange: 4)
                config.xAxisConfig.visibleValueRange = 24
                config.xAxisConfig.topline = .clamp(lowerBound: 23)
            case .week:
                config.xAxisConfig.step = .fixed(1)
                config.xAxisConfig.scrollingBehaviour = .segmented(visibleValueRange: 7)
                config.xAxisConfig.visibleValueRange = 7
                config.xAxisConfig.topline = .clamp(lowerBound: 6)
            case .month:
                config.xAxisConfig.step = .fixed(8)
                config.xAxisConfig.scrollingBehaviour = .segmented(visibleValueRange: 4)
                config.xAxisConfig.visibleValueRange = 32
                config.xAxisConfig.topline = .clamp(lowerBound: 31)
            case .threeMonths:
                config.xAxisConfig.step = .fixed(1)
                config.xAxisConfig.scrollingBehaviour = .segmented(visibleValueRange: 3)
                config.xAxisConfig.visibleValueRange = 3
                config.xAxisConfig.topline = .clamp(lowerBound: 2)
            case .sixMonths:
                config.xAxisConfig.step = .fixed(1)
                config.xAxisConfig.scrollingBehaviour = .segmented(visibleValueRange: 6)
                config.xAxisConfig.visibleValueRange = 6
                config.xAxisConfig.topline = .clamp(lowerBound: 5)
            case .year:
                config.xAxisConfig.step = .fixed(1)
                config.xAxisConfig.scrollingBehaviour = .segmented(visibleValueRange: 12)
                config.xAxisConfig.visibleValueRange = 12
                config.xAxisConfig.topline = .clamp(lowerBound: 11)
            }
            // FIXME: clone
            return config
        }
        
        return TimeSeriesData(scope: resolution, interval: valueInterval,
                              dates: dates, values: values, configure: configure)
    }
    
    public var body: some View {
        ZStack {
            if let data {
                self.buildChartView(data)
                    .id(data.hashValue)
            }
        }
        .onAppear {
            self.data = self.getChartData(for: scope)
        }
        .onChange(of: self.scope) { scope in
            self.data = self.getChartData(for: scope)
        }
    }
}
