//
//  NSErrorExtensions
//  Pods
//
//  Created by Phillipe Casorla Sagot on 4/5/17.
//
//

import Foundation

extension NSError
{
    public static func make(from msError:MSError, errorDetails:MSErrorDetails?) -> NSError
    {
        var errorMessage = errorDetails?.message ?? ""
        errorMessage = errorMessage.replacingOccurrences(of: "[u\'", with: "")
        errorMessage = errorMessage.replacingOccurrences(of: "\']", with: "")
        return NSError(domain: Bundle.main.bundleIdentifier ?? "com.makespace",
                       code: msError.responseCode,
                       userInfo: ["errorType" : errorDetails?.errorType ?? "", "message" : errorMessage])
    }
}
