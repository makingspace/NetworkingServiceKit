//
//  HTTPURLResponseExtensions.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 7/12/17.
//
//

import Foundation

extension HTTPURLResponse {
    
    /// By default our URLSessionConfiguration uses NSURLRequest.CachePolicy.useProtocolCachePolicy
    /// this means our policy for caching requests is interpreted according to the "Cache-Control" header field in the response.
    /// This property indicates if the response has no cache policy
    internal var isResponseCachePolicyDisabled:Bool {
        let responseHeaders = self.allHeaderFields
        if let cacheControl = responseHeaders["Cache-Control"] as? String {
            return cacheControl.contains("no-cache") || cacheControl.contains("max-age=0")
        } else if responseHeaders["Cache-Control"] == nil {
            return true
        }
        return false
    }
}
