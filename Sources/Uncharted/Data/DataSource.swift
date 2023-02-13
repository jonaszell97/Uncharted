
import Foundation
import Toolbox

/// Protocol for types that can act as the data source for a ``TimeSeriesView``.
public protocol TimeSeriesDataSource {
    /// The date interval within which this source can provide data.
    var interval: DateInterval { get }
    
    /// Get the value for a single date.
    ///
    /// - Parameter date: The date for which the value should be returned.
    /// - Returns: The value for a given date.
    func value(on date: Date) -> Double?
    
    /// Get the combined value for a range of dates.
    ///
    /// - Parameter interval: The date interval whose contained values should be combined.
    /// - Returns: The combined value within a given date interval. It is up to the data source to decide how values are combined.
    func combinedValue(in interval: DateInterval) -> Double?
    
    /// Get the range of values in an interval.
    ///
    /// - Parameter interval: The date interval whose value range should be determined.
    /// - Returns: The maximum and minimum value within a given date interval.
    func range(in interval: DateInterval) -> ClosedRange<Double>?
}

/// A time-series data source that combines values in an interval by summing them.
public struct SummingTimeSeriesDataSource {
    /// The available data points.
    var data: [(Date, Double)]
    
    /// The start of the data range.
    var startDate: Date { data.first?.0 ?? .distantFuture }
    
    /// The end of the data range.
    var endDate: Date { data.last?.0 ?? .distantPast }
    
    /// The interval of values.
    public var interval: DateInterval {
        guard !data.isEmpty else { return .init(start: .distantFuture, duration: 0) }
        return .init(start: data.first!.0, end: data.last!.0)
    }
    
    /// Create a summing data source from a dataset.
    public init(data: [(Date, Double)]) {
        self.data = data.sorted { $0.0 < $1.0 }
    }
    
    /// Create a summing data source from a dictionary of dates mapped to values.
    public init(data: [Date: Double]) {
        self.init(data: data.map { ($0.key, $0.value) })
    }
}

extension SummingTimeSeriesDataSource: TimeSeriesDataSource {
    /// Return the value for a given date.
    public func value(on date: Date) -> Double? {
        data.first { $0.0 == date }?.1
    }
    
    /// - returns: The sum of the values within a given date interval.
    public func combinedValue(in interval: DateInterval) -> Double? {
        let dataInterval = self.interval
        guard dataInterval.overlaps(interval) else {
            return nil
        }
        
        var valuesInRange: [Double] = []
        for (date, value) in data {
            guard date < interval.end else {
                break
            }
            guard date >= interval.start else {
                continue
            }
            
            valuesInRange.append(value)
        }
        
        return valuesInRange.reduce(0) { $0 + $1 }
    }
    
    /// - returns: The maximum and minimum value within a given date interval.
    public func range(in interval: DateInterval) -> ClosedRange<Double>? {
        let dataInterval = self.interval
        guard dataInterval.overlaps(interval) else {
            return nil
        }
        
        var valuesInRange: [Double] = []
        for (date, value) in data {
            guard date <= interval.end else {
                break
            }
            guard date >= interval.start else {
                continue
            }
            
            valuesInRange.append(value)
        }
        
        return (valuesInRange.min() ?? 0)...(valuesInRange.max() ?? 0)
    }
}

/// A time-series data source that combines values in an interval by averaging them.
public struct AveragingTimeSeriesDataSource {
    /// The available data points.
    var data: [(Date, Double)]
    
    /// The start of the data range.
    var startDate: Date { data.first?.0 ?? .distantFuture }
    
    /// The end of the data range.
    var endDate: Date { data.last?.0 ?? .distantPast }
    
    /// The interval of values.
    public var interval: DateInterval {
        guard !data.isEmpty else { return .init(start: .distantFuture, duration: 0) }
        return .init(start: data.first!.0, end: data.last!.0)
    }
    
    /// Create a summing data source from a dataset.
    public init(data: [(Date, Double)]) {
        self.data = data.sorted { $0.0 < $1.0 }
    }
    
    /// Create a summing data source from a dictionary of dates mapped to values.
    public init(data: [Date: Double]) {
        self.init(data: data.map { ($0.key, $0.value) })
    }
}

extension AveragingTimeSeriesDataSource: TimeSeriesDataSource {
    /// Return the value for a given date.
    public func value(on date: Date) -> Double? {
        guard date >= startDate, date <= endDate else {
            return nil
        }
        
        guard let nextHighestIndex = (data.firstIndex { $0.0 >= date }) else {
            return self.data.last!.1
        }
        
        let (nextHighestDate, nextHighestValue) = data[nextHighestIndex]
        guard nextHighestDate != date, nextHighestIndex > 0 else {
            return nextHighestValue
        }
        
        let (previousDate, previousValue) = data[nextHighestIndex - 1]
        
        let dateDifference = nextHighestDate.timeIntervalSinceReferenceDate - previousDate.timeIntervalSinceReferenceDate
        assert(dateDifference > 0)
        
        let dateOffset = date.timeIntervalSinceReferenceDate - previousDate.timeIntervalSinceReferenceDate
        assert(dateOffset > 0)
        
        let valueDifference = nextHighestValue - previousValue
        return previousValue + ((dateOffset / dateDifference) * valueDifference)
    }
    
    /// - returns: The average value within a given date interval.
    public func combinedValue(in interval: DateInterval) -> Double? {
        let dataInterval = self.interval
        guard dataInterval.overlaps(interval) else {
            return nil
        }
        
        var valuesInRange: [Double] = []
        for (date, value) in data {
            guard date <= interval.end else {
                break
            }
            guard date >= interval.start else {
                continue
            }
            
            valuesInRange.append(value)
        }
        
        if !valuesInRange.isEmpty {
            return valuesInRange.mean
        }
        
        guard
            let interpolatedStart = self.value(on: interval.start),
            let interpolatedEnd = self.value(on: interval.end)
        else {
            return nil
        }
        
        return (interpolatedStart + interpolatedEnd) * 0.5
    }
    
    /// - returns: The maximum and minimum value within a given date interval.
    public func range(in interval: DateInterval) -> ClosedRange<Double>? {
        guard
            let interpolatedStart = self.value(on: interval.start),
            let interpolatedEnd = self.value(on: interval.end)
        else {
            return nil
        }
        
        return interpolatedStart...interpolatedEnd
    }
}
