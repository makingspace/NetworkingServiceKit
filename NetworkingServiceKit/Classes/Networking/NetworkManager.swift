//
//  NetworkManagerProtocol.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 2/27/17.
//
//

import Foundation
//Custom Makespace Error
public enum MSError : Error {
    
    /// The underlying reason the request failed
    ///
    /// - tokenExpired: request received a 401 from a backend
    /// - badRequest: generic error for responses
    public enum ResponseFailureReason {
        
        case tokenExpired
        case badRequest
    }
    
    case responseValidationFailed(reason: ResponseFailureReason)
}

extension MSError {
    /// Returns whether the MSError is because our token expired
    public var hasTokenExpired: Bool {
        switch self {
        case .responseValidationFailed(let reason):
            return reason == .tokenExpired
        }
    }
}


/// Custom HTTP enum types for Makespace
@objc
public enum HTTPMethod: Int32 {
    case options
    case get
    case head
    case post
    case put
    case patch
    case delete
    case trace
    case connect
    
    var string:String {
        switch self {
        case .options: return "OPTIONS"
        case .get: return "GET"
        case .head: return "HEAD"
        case .post: return "POST"
        case .put: return "PUT"
        case .patch: return "PATCH"
        case .delete: return "DELETE"
        case .trace: return "TRACE"
        case .connect: return "CONNECT"
        }
        return ""
    }
}

/// Success/Error blocks for a NetworkManager response
public typealias SuccessResponseBlock = ([String:Any]) -> Void
public typealias ErrorResponseBlock = (MSError,[String:Any]?) -> Void
//Custom parameter typealias
public typealias CustomHTTPHeaders = [String: String]
public typealias RequestParameters = [String: Any]

/// Protocol for defining a Network Manager
public protocol NetworkManager
{
    var configuration:APIConfiguration {get set}
    func request(path: String,
                 method: HTTPMethod,
                 with parameters: RequestParameters,
                 paginated:Bool,
                 headers:CustomHTTPHeaders,
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock)
    
    init(with configuration:APIConfiguration)
}
