//
//  DateFormatterExtensions.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 3/7/17.
//
//

import Foundation

extension DateFormatter {
    
    class internal func makespace() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }
    
    class internal func makespaceDateFormatterWithMicroSeconds() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        return dateFormatter
    }
    
    class internal func makespaceHourMinute() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter
    }
    
    class internal func makespaceYearMonthDay() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }
    
    class internal func string(fromMSDate msDate: Date) -> String {
        return self.makespace().string(from: msDate)
    }
    
    class internal func date(fromMSString dateString: String) -> Date? {
        return self.makespace().date(from: dateString)
    }
}
