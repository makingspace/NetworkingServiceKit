//
//  NSErrorExtensions
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/5/17.
//
//

import Foundation

extension NSError {

    /// A key for userInfo to save our error message from the server
    static var messageKey: String {
        return "message"
    }

    /// Returns a user friendly error message from the error response
    public var errorMessage: String {
        return self.userInfo[NSError.messageKey] as? String ?? ""
    }

    /// Builds an NSError object from our MSError
    ///
    /// - Parameters:
    ///   - msError: an error type
    /// - Returns: A valid NSError with attached extra information on the userInfo
    public static func make(from msError: MSError) -> NSError {
        var errorMessage = msError.details.message
        errorMessage = errorMessage.replacingOccurrences(of: "[u\'", with: "")
        errorMessage = errorMessage.replacingOccurrences(of: "\']", with: "")
        return NSError(domain: Bundle.main.appBundleIdentifier,
                       code: msError.details.code,
                       userInfo: [NSError.messageKey: errorMessage])
    }
}
