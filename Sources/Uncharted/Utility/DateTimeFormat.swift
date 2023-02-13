
import SwiftUI
import Toolbox

/// The visible time interval on the x-axis of a ``TimeSeriesView``.
///
/// This enumeration defines the time interval that is visible on the x-axis of a time series chart.
/// The following intervals are supported:
///
/// | Scope                                                            | Step Size | Axis Ticks |
/// | ---------------------------------------------------------- | ------------- | -------------- |
/// | ``TimeSeriesScope/day``                   | 1 hour      | 24              |
/// | ``TimeSeriesScope/week``                 | 1 day       | 7                |
/// | ``TimeSeriesScope/month``               | 1 day       | 32              |
/// | ``TimeSeriesScope/threeMonths``  | 1 month   | 3               |
/// | ``TimeSeriesScope/sixMonths``      | 1 month   | 6                |
/// | ``TimeSeriesScope/year``                 | 1 month   | 12              |
public enum TimeSeriesScope: String, CaseIterable {
    /// Daily resolution with 24 steps of 1 hour.
    case day
    
    /// Weekly resolution with 7 steps of 1 day.
    case week
    
    /// Monthly resolution with 32 steps of 1 day.
    case month
    
    /// 3-month resolution with 3 steps of 1 month.
    case threeMonths
    
    /// 6-month resolution with 6 steps of 1 month.
    case sixMonths
    
    /// Yearly resolution with 12 steps of 1 month.
    case year
}

/// Describes options for formatting a ``TimeSeriesScope``.
public enum TimeSeriesScopeFormat {
    /// Single-letter short format.
    case short
    
    /// Spelled out long format.
    case long
    
    /// Custom format.
    case custom(_ formatter: (TimeSeriesScope) -> String)
}

// MARK: ChartTimeInterval extensions

extension TimeSeriesScope: Identifiable, Hashable {
    public var id: Self { self }
}

extension TimeSeriesScope {
    /// The interval to use as a base for all transformations.
    static let baseInterval: TimeSeriesScope = .day
    
    func dateComponents(times value: Int) -> DateComponents {
        var components = DateComponents()
        switch self {
        case .day:
            components.hour = value
        case .week:
            components.day = value
        case .month:
            components.day = value
        case .threeMonths:
            components.month = value
        case .sixMonths:
            components.month = value
        case .year:
            components.month = value
        }
        
        return components
    }
    
    var dateComponents: DateComponents {
        self.dateComponents(times: 1)
    }
}

// MARK: ChartScopeFormat extensions

public extension TimeSeriesScopeFormat {
    /// Format a time interval using this format.
    ///
    /// - Parameters:
    ///   - interval: The time interval to format.
    ///   - languageCode: The language to use. Currently, English (en) and German (de) are supported.
    /// - Returns: The formatted time interval.
    func callAsFunction(_ interval: TimeSeriesScope, languageCode: String? = nil) -> String {
        switch self {
        case .short:
            switch languageCode {
            case "de":
                switch interval {
                case .day:
                    return "T"
                case .week:
                    return "W"
                case .month:
                    return "M"
                case .threeMonths:
                    return "3M"
                case .sixMonths:
                    return "6M"
                case .year:
                    return "J"
                }
            default:
                switch interval {
                case .day:
                    return "D"
                case .week:
                    return "W"
                case .month:
                    return "M"
                case .threeMonths:
                    return "3M"
                case .sixMonths:
                    return "6M"
                case .year:
                    return "Y"
                }
            }
        case .long:
            switch languageCode {
            case "de":
                switch interval {
                case .day:
                    return "Tag"
                case .week:
                    return "Woche"
                case .month:
                    return "Monat"
                case .threeMonths:
                    return "3 Mon."
                case .sixMonths:
                    return "6 Mon."
                case .year:
                    return "Jahr"
                }
            default:
                switch interval {
                case .day:
                    return "Day"
                case .week:
                    return "Week"
                case .month:
                    return "Month"
                case .threeMonths:
                    return "3 Mon."
                case .sixMonths:
                    return "6 Mon."
                case .year:
                    return "Year"
                }
            }
        case .custom(let formatter):
            return formatter(interval)
        }
    }
}

internal func defaultWeekdayFormat(weekday: Int, languageCode: String? = nil) -> String {
    switch weekday {
    case 1:
        switch languageCode {
        case "de":
            return "So"
        default:
            return "Sun"
        }
    case 2:
        switch languageCode {
        case "de":
            return "Mo"
        default:
            return "Mon"
        }
    case 3:
        switch languageCode {
        case "de":
            return "Di"
        default:
            return "Tue"
        }
    case 4:
        switch languageCode {
        case "de":
            return "Mi"
        default:
            return "Wed"
        }
    case 5:
        switch languageCode {
        case "de":
            return "Do"
        default:
            return "Thu"
        }
    case 6:
        switch languageCode {
        case "de":
            return "Fr"
        default:
            return "Fri"
        }
    case 7:
        fallthrough
    default:
        switch languageCode {
        case "de":
            return "Sa"
        default:
            return "Sat"
        }
    }
}

internal func defaultMonthFormat(month: Int, languageCode: String? = nil) -> String {
    switch month {
    case 1:
        switch languageCode {
        case "de":
            return "Jan"
        default:
            return "Jan"
        }
    case 2:
        switch languageCode {
        case "de":
            return "Feb"
        default:
            return "Feb"
        }
    case 3:
        switch languageCode {
        case "de":
            return "Mär"
        default:
            return "Mar"
        }
    case 4:
        switch languageCode {
        case "de":
            return "Apr"
        default:
            return "Apr"
        }
    case 5:
        switch languageCode {
        case "de":
            return "Mai"
        default:
            return "May"
        }
    case 6:
        switch languageCode {
        case "de":
            return "Jun"
        default:
            return "Jun"
        }
    case 7:
        switch languageCode {
        case "de":
            return "Jul"
        default:
            return "Jul"
        }
    case 8:
        switch languageCode {
        case "de":
            return "Aug"
        default:
            return "Aug"
        }
    case 9:
        switch languageCode {
        case "de":
            return "Sep"
        default:
            return "Sep"
        }
    case 10:
        switch languageCode {
        case "de":
            return "Okt"
        default:
            return "Oct"
        }
    case 11:
        switch languageCode {
        case "de":
            return "Nov"
        default:
            return "Nov"
        }
    default:
        switch languageCode {
        case "de":
            return "Dez"
        default:
            return "Dec"
        }
    }
}

internal func longMonthFormat(month: Int, languageCode: String? = nil) -> String {
    switch month {
    case 1:
        switch languageCode {
        case "de":
            return "Januar"
        default:
            return "January"
        }
    case 2:
        switch languageCode {
        case "de":
            return "Februar"
        default:
            return "February"
        }
    case 3:
        switch languageCode {
        case "de":
            return "März"
        default:
            return "March"
        }
    case 4:
        switch languageCode {
        case "de":
            return "April"
        default:
            return "April"
        }
    case 5:
        switch languageCode {
        case "de":
            return "Mai"
        default:
            return "May"
        }
    case 6:
        switch languageCode {
        case "de":
            return "Juni"
        default:
            return "June"
        }
    case 7:
        switch languageCode {
        case "de":
            return "Juli"
        default:
            return "July"
        }
    case 8:
        switch languageCode {
        case "de":
            return "August"
        default:
            return "August"
        }
    case 9:
        switch languageCode {
        case "de":
            return "September"
        default:
            return "September"
        }
    case 10:
        switch languageCode {
        case "de":
            return "Oktober"
        default:
            return "October"
        }
    case 11:
        switch languageCode {
        case "de":
            return "November"
        default:
            return "November"
        }
    default:
        switch languageCode {
        case "de":
            return "Dezember"
        default:
            return "December"
        }
    }
}
