
import Foundation
import Toolbox

public protocol TimeSeriesDataSource {
    /// - returns: The value for a given date.
    func value(on date: Date) -> Double?
    
    /// - returns: The average value within a given date interval.
    func averageValue(in interval: DateInterval) -> Double?
    
    /// - returns: The maximum and minimum value within a given date interval.
    func range(in interval: DateInterval) -> ClosedRange<Double>?
    
    /// - returns: The date interval within which this source can provide data.
    var interval: DateInterval { get }
}

public struct InterpolatingTimeSeriesDataSource {
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
    
    /// Initialize from a dataset.
    public init(data: [(Date, Double)]) {
        self.data = data.sorted { $0.0 < $1.0 }
    }
    
    /// Initialize from a dataset.
    public init(data: [Date: Double]) {
        self.init(data: data.map { ($0.key, $0.value) })
    }
}

extension InterpolatingTimeSeriesDataSource: TimeSeriesDataSource {
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
    public func averageValue(in interval: DateInterval) -> Double? {
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
