
import Foundation
import XCTest
@testable import Uncharted

final class UnchartedTests: XCTestCase {
    let dateFormatter: Foundation.DateFormatter = {
        let dateFormatter = Foundation.DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = .utc
        
        return dateFormatter
    }()
    
    func date(from string: String) -> Date {
        let date = dateFormatter.date(from: string)
        XCTAssertNotNil(date)
        
        return date!
    }
    
    // MARK: Data sources
    
    func testInterpolatingDataSource() {
        let fullData: [(Date, Double)] = [
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
        ]
        
        let dates = fullData.map { $0.0 }
        let valuesToRemove: [Int?] = [nil, 3, 7]
        for index in valuesToRemove {
            var data: [(Date, Double)] = fullData
            if let index {
                data.remove(at: index)
            }
            
            let source = AveragingTimeSeriesDataSource(data: data)
            
            // Whole interval range
            XCTAssertEqual(source.range(in: DateInterval(start: dates[0], end: dates[9])), 1...10)
            
            // First/last 5 days range
            XCTAssertEqual(source.range(in: DateInterval(start: dates[0], end: dates[4])), 1...5)
            XCTAssertEqual(source.range(in: DateInterval(start: dates[5], end: dates[9])), 6...10)
            
            // Whole interval average
            if index == nil {
                XCTAssertEqual(source.combinedValue(in: DateInterval(start: dates[0], end: dates[9])), 5.5)
            }
            
            // First/last 5 days average
            if index == nil {
                XCTAssertEqual(source.combinedValue(in: DateInterval(start: dates[0], end: dates[4])), 3)
            }
            XCTAssertEqual(source.combinedValue(in: DateInterval(start: dates[5], end: dates[9])), 8)
            
            // Existing values
            for i in 0..<10 {
                XCTAssertEqual(source.value(on: dates[i]), Double(i+1))
            }
            
            // Interpolated values
            XCTAssertEqual(3.5,  source.value(on: date(from: "2023-01-03T12:00:00+0000"))!, accuracy: 0.001)
            XCTAssertEqual(3.75, source.value(on: date(from: "2023-01-03T18:00:00+0000"))!, accuracy: 0.001)
            XCTAssertEqual(7.25, source.value(on: date(from: "2023-01-07T06:00:00+0000"))!, accuracy: 0.001)
            XCTAssertEqual(28/3, source.value(on: date(from: "2023-01-09T08:00:00+0000"))!, accuracy: 0.001)
        }
    }
}
