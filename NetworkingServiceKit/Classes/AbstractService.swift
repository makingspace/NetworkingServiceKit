//
//  AbstractService.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 2/27/17.
//
//

import Foundation

public protocol AbstractService
{
    init(token:APIToken?, networkManager:NetworkManager)
    var token:APIToken? { get set }
    var networkManager:NetworkManager { get set }
    var currentConfiguration:APIConfiguration { get }
    var serviceVersion: String { get }
    var servicePath: String { get }
    
    func servicePath(for query:String) -> String
    var isAuthenticated:Bool { get }
    func request(path: String,
                 method: HTTPMethod,
                 with parameters: [String: Any],
                 paginated:Bool,
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock)
}

open class AbstractBaseService: NSObject,AbstractService
{
    
    public var networkManager: NetworkManager
    
    public var token: APIToken?
    
    public var currentConfiguration: APIConfiguration {
        return self.networkManager.configuration
    }
    
    /// Init method for an AbstractService, each service must have the current token auth and access to the networkManager to execute requests
    ///
    /// - Parameters:
    ///   - token: an existing APIToken
    ///   - networkManager: an object that supports our NetworkManager protocol
    public required init(token: APIToken?, networkManager: NetworkManager) {
        self.token = token
        self.networkManager = networkManager
    }

    /// Currently supported version of the service
    public var serviceVersion: String {
        return "v3"
    }
    
    /// Name here your service path
    public var servicePath:String {
        return ""
    }
    
    /// Returns a local path for an API request, this includes the service version and name. i.e v4/accounts/user_profile
    ///
    /// - Parameter query: api local path
    /// - Returns: local path to the api for the given query
    public func servicePath(for query:String) -> String
    {
        var fullPath = ""
        if (!self.servicePath.isEmpty) {
            fullPath = (fullPath as NSString).appendingPathComponent(self.servicePath)
        }
        if (!self.serviceVersion.isEmpty) {
            fullPath = (fullPath as NSString).appendingPathComponent(self.serviceVersion)
        }
        fullPath = (fullPath as NSString).appendingPathComponent(query)
        return fullPath
    }
    
    public var isAuthenticated:Bool
    {
        return (self.token != nil)
    }
    
    /// Creates and executes a request using our current Network provider
    ///
    /// - Parameters:
    ///   - path: full path to the URL
    ///   - method: HTTP method, default is GET
    ///   - parameters: URL or body parameters depending on the HTTP method, default is empty
    ///   - paginated: if the request should follow pagination, success only if all pages are completed
    ///   - success: success block with a response
    ///   - failure: failure block with an error
    public func request(path: String,
                 method: HTTPMethod = .get,
                 with parameters: [String: Any] = [String: Any](),
                 paginated:Bool = false,
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock)
    {
        self.networkManager.request(path: servicePath(for: path),
                                    method: method,
                                    with: parameters,
                                    paginated: paginated,
                                    success: success,
                                    failure: failure)
    }
    
}
