//
//  NSErrorExtensions
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/5/17.
//
//

import Foundation

extension NSError
{
    
    /// A key for userInfo to save our error type from the server
    private static var errorTypeKey = "errorType"
    
    /// A key for userInfo to save our error message from the server
    private static var errorMessageKey = "message"
    
    /// Returns an error type from the error response
    public var errorType:String {
        return self.userInfo[NSError.errorTypeKey] as? String ?? ""
    }
    
    /// Returns a user friendly error message from the error response
    public var errorMessage:String {
        return self.userInfo[NSError.errorMessageKey] as? String ?? ""
    }
    
    /// Builds an NSError object from our MSError type and MSErrorDetails
    ///
    /// - Parameters:
    ///   - msError: an error type
    ///   - errorDetails: an error details
    /// - Returns: A valid NSError with attached extra information on the userInfo
    public static func make(from msError:MSError, errorDetails:MSErrorDetails?) -> NSError
    {
        var errorMessage = errorDetails?.message ?? ""
        errorMessage = errorMessage.replacingOccurrences(of: "[u\'", with: "")
        errorMessage = errorMessage.replacingOccurrences(of: "\']", with: "")
        return NSError(domain: Bundle.main.appBundleIdentifier,
                       code: msError.responseCode,
                       userInfo: [NSError.errorTypeKey : errorDetails?.errorType ?? "", NSError.errorMessageKey : errorMessage])
    }
    
    /// Builds an NSError object from a HTTP Code and MSErrorDetails
    ///
    /// - Parameters:
    ///   - code: a HTTP Code
    ///   - errorDetails: an error details
    /// - Returns: A valid NSError with attached extra information on the userInfo
    public static func make(from code:Int, errorDetails:MSErrorDetails?) -> NSError
    {
        var errorMessage = errorDetails?.message ?? ""
        errorMessage = errorMessage.replacingOccurrences(of: "[u\'", with: "")
        errorMessage = errorMessage.replacingOccurrences(of: "\']", with: "")
        return NSError(domain: Bundle.main.appBundleIdentifier,
                       code: code,
                       userInfo: [NSError.errorTypeKey : errorDetails?.errorType ?? "", NSError.errorMessageKey : errorMessage])
    }
}
