//
//  DateFormatterExtensions.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 3/7/17.
//
//

import Foundation

extension DateFormatter {
    
    class public func makespace() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }
    
    class public func makespaceDateFormatterWithMicroSeconds() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        return dateFormatter
    }
    
    class public func makespaceHourMinute() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter
    }
    
    class public func makespaceYearMonthDay() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }
    
    class public func string(fromMSDate msDate: Date) -> String {
        return self.makespace().string(from: msDate)
    }
    
    class public func date(fromMSString dateString: String) -> Date? {
        return self.makespace().date(from: dateString)
    }
}
