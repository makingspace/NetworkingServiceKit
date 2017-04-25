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
    
    /// Builds a NSError out of framework MSError struct - useful for ObjC bridges
    ///
    /// - Parameters:
    ///   - msError: the given msError from a failed API
    ///   - errorDetails: an error response from a failed API
    /// - Returns: an NSError with the data needed inside
    public static func make(from msError:MSError, errorDetails:MSErrorDetails?) -> NSError
    {
        let errorMessage = errorDetails?.message ?? ""
        return NSError(domain: Bundle.main.appBundleIdentifier,
                       code: msError.responseCode,
                       userInfo: ["errorType" : errorDetails?.errorType ?? "", "message" : errorMessage])
    }
}
