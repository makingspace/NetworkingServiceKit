//
//  NetworkManagerProtocol.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 2/27/17.
//
//

import Foundation

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
public typealias ErrorResponseBlock = (Error,[String:Any]?) -> Void


/// Protocol for defining a Network Manager
@objc
public protocol NetworkManager
{
    var configuration:APIConfiguration {get set}
    func request(path: String,
                 method: HTTPMethod,
                 with parameters: [String: Any],
                 paginated:Bool,
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock)
    
    init(with configuration:APIConfiguration)
}
