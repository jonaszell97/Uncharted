
import SwiftUI
import Toolbox

public enum ChartDataAggregationMethod {
    /// Use the arithmetic mean of the values in each interval.
    case arithmeticMean
    
    /// Show the values in each interval as a range.
    case range
}

extension TimeSeriesScope {
    /// The dates within an interval for this scope.
    func dates(in interval: DateInterval) -> [Date] {
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
        
        var dates = [Date]()
        var currentDate = firstDate
        
        while currentDate < lastDate {
            dates.append(currentDate)
            currentDate = Calendar.reference.date(byAdding: step, to: currentDate)!
        }
        
        return dates
    }
    
    /// - returns: A string representing the selected interval in the given locale.
    public func formatTimeInterval(_ interval: DateInterval, locale: Locale? = nil) -> String {
        switch self {
        case .day:
            return FormatToolbox.formatDate(interval.start)
        case .week:
            return "\(FormatToolbox.formatDate(interval.start)) - \(FormatToolbox.formatDate(interval.end))"
        case .month:
            let components = Calendar.reference.dateComponents([.month,.year], from: interval.start)
            return "\(longMonthFormat(month: components.month!, languageCode: locale?.languageCode)) \(components.year!)"
        case .threeMonths:
            fallthrough
        case .sixMonths:
            fallthrough
        case .year:
            let year = Calendar.reference.component(.year, from: interval.start)
            return "\(year)"
        }
    }
    
    /// - returns: A default formatter for the given interval.
    public func createDefaultFormatter(startDate: Date, locale: Locale? = nil, dataCount: Int? = nil)
        -> CustomDataFormatter
    {
        switch self {
        case .day:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: self.dateComponents(times: Int(value)),
                    to: startDate)!
                let hour = Calendar.reference.component(.hour, from: date)
                
                return "\(hour)"
            }
        case .week:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: self.dateComponents(times: Int(value)),
                    to: startDate)!
                let weekday = Calendar.reference.component(.weekday, from: date)
                
                return "\(defaultWeekdayFormat(weekday: weekday, languageCode: locale?.languageCode))"
            }
        case .month:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: self.dateComponents(times: Int(value)),
                    to: startDate)!
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
                    to: startDate)!
                let month = Calendar.reference.component(.month, from: date)
                
                return "\(defaultMonthFormat(month: month, languageCode: locale?.languageCode).first!)"
            }
        case .threeMonths:
            fallthrough
        case .sixMonths:
            return CustomDataFormatter { value in
                let date = Calendar.reference.date(
                    byAdding: self.dateComponents(times: Int(value)),
                    to: startDate)!
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
    public let dates: [Date]
    
    /// The data series for the selected interval.
    public let values: [DataPoint]
    
    /// A function to configure the chart config appropriately for the current time series data.
    public let configure: (ChartConfig) -> ChartConfig
    
    /// The hash value of the current dataset.
    let hashValue: Int
    
    /// Memberwise initializer.
    internal init(scope: TimeSeriesScope, interval: DateInterval,
                  dates: [Date], values: [DataPoint],
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
}

public struct TimeSeriesView<ChartContent: View>: View {
    /// The chart data.
    let source: TimeSeriesDataSource
    
    /// The chart builder.
    let buildChartView: (TimeSeriesData) -> ChartContent
    
    /// The time series data.
    @State var data: TimeSeriesData? = nil
    
    /// The current scope.
    @Binding var scope: TimeSeriesScope
    
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
        let dates = resolution.dates(in: interval)
        
        let visibleInterval = DateInterval(start: dates.first!, end: dates.last!)
        let values = dates
            .enumerated()
            .map { ($0.offset, source.value(on: $0.element)) }
            .filter { $0.1 != nil }
            .map { DataPoint(x: Double($0.0) + 0.5, y: $0.1!) }
        
        let configure = { (config: ChartConfig) -> ChartConfig in
            config.xAxisConfig.baseline = .zero
            
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
                config.xAxisConfig.step = .fixed(7)
                config.xAxisConfig.scrollingBehaviour = .segmented(visibleValueRange: 4)
                config.xAxisConfig.visibleValueRange = 28
                config.xAxisConfig.topline = .clamp(lowerBound: 27)
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
        
        return TimeSeriesData(scope: resolution, interval: visibleInterval, dates: dates,
                              values: values, configure: configure)
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
