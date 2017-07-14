//
//  URLRequestExtensions.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 7/12/17.
//
//

import Foundation

extension URLRequest {
    
    /// Returns a cached JSON response for the the current request if we have stored it before and it hasn't expired
    ///
    /// - Returns: the cached JSON response
    internal func cachedJSONResponse() -> Any? {
        if let cachedResponse = URLCache.shared.cachedResponse(for: self),
            let userInfo = cachedResponse.userInfo,
            let startTime = userInfo[CachedURLResponse.CacheURLResponseTime] as? Double,
            let maxAge = userInfo[CachedURLResponse.CacheURLResponseMaxAge] as? Double {
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            guard elapsed <= maxAge else { return nil }
            
            let data = cachedResponse.data
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            return json
        }
        return nil
    }
}

extension CachedURLResponse {
    
    internal static let CacheURLResponseMaxAge = "maxAge"
    internal static let CacheURLResponseTime = "time"
    
    
    /// Creates a CachedURLResponse with attached information for maxAge and current time the response got saved
    ///
    /// - Parameters:
    ///   - response: a network responwe
    ///   - data: response's data
    ///   - maxAge: max age the response will be valid before expiring
    internal convenience init(response: URLResponse, data: Data, maxAge:Double) {
        self.init(response: response,
                  data: data,
                  userInfo: [
                    CachedURLResponse.CacheURLResponseTime : CFAbsoluteTimeGetCurrent(),
                    CachedURLResponse.CacheURLResponseMaxAge : maxAge],
                  storagePolicy: .allowed)
    }
}
