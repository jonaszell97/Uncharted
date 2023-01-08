
import SwiftUI
import Toolbox

public enum TimeBasedChartScope: String, CaseIterable {
    /// Daily resolution.
    case day
    
    /// Weekly resolution.
    case week
    
    /// Monthly resolution.
    case month
    
    /// 3-month resolution.
    case threeMonths
    
    /// 6-month resolution.
    case sixMonths
    
    /// Yearly resolution.
    case year
}

public enum ChartTimeIntervalFormat {
    /// Single-letter short format.
    case short
    
    /// Spelled out long format.
    case long
    
    /// Custom format.
    case custom(_ formatter: (TimeBasedChartScope) -> String)
}

// MARK: ChartTimeInterval extensions

extension TimeBasedChartScope: Identifiable, Hashable {
    public var id: Self { self }
}

extension TimeBasedChartScope {
    /// The interval to use as a base for all transformations.
    public static let baseInterval: TimeBasedChartScope = .day
    
    public func dateComponents(times value: Int) -> DateComponents {
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
    
    public var dateComponents: DateComponents {
        self.dateComponents(times: 1)
    }
}

// MARK: ChartTimeIntervalFormat extensions

public extension ChartTimeIntervalFormat {
    /// Format a time interval.
    func callAsFunction(_ interval: TimeBasedChartScope, languageCode: String? = nil) -> String {
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
