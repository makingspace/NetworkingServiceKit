//
//  NetworkManagerProtocol.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 2/27/17.
//
//

import Foundation

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}
public typealias SuccessResponseBlock = (AnyObject) -> Void
public typealias ErrorBlock = (Error) -> Void

public protocol NetworkManager
{
    var configuration:APIConfiguration {get set}
    func request(path: String,
                 method: HTTPMethod,
                 with parameters: [String: Any],
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorBlock)
    
    init(with configuration:APIConfiguration)
}
