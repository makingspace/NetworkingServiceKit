//
//  DateFormatterExtensions.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 3/7/17.
//
//

import Foundation

extension DateFormatter {
    
    class func makespace() -> DateFormatter {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }
    
    class func makespaceDateFormatterWithMicroSeconds() -> DateFormatter {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        return dateFormatter
    }
    
    class func makespaceHourMinute() -> DateFormatter {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter
    }
    
    class func makespaceYearMonthDay() -> DateFormatter {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }
    
    class func string(fromMSDate msDate: Date) -> String {
        return self.makespace().string(from: msDate)
    }
    
    class func date(fromMSString dateString: String) -> Date? {
        return self.makespace().date(from: dateString)
    }
}
