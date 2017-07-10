//
//  Service.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation

/// Defines the necessary methods that a service should implement
public protocol Service {
    
    /// Builds a service with an auth token and a networkManager implementation
    ///
    /// - Parameters:
    ///   - token: an auth token (if we are authenticated)
    ///   - networkManager: the networkManager we are currently using
    init(token: APIToken?, networkManager: NetworkManager)
    
    /// Current auth token this service has
    var token: APIToken? { get set }
    
    /// Current network manger this service is using
    var networkManager: NetworkManager { get set }
    
    /// Current API configuration
    var currentConfiguration: APIConfiguration { get }
    
    /// Default service version
    var serviceVersion: String { get }
    
    /// Default service path
    var servicePath: String { get }

    /// Builds a service query path with our version and default root path
    ///
    /// - Parameter query: the query to build
    /// - Returns: a compose query with the baseURL, service version and service path included
    func servicePath(for query: String) -> String
    
    /// True if our auth token is valid
    var isAuthenticated: Bool { get }
    
    /// Executes a request with out current network Manager
    ///
    /// - Parameters:
    ///   - path: a full URL
    ///   - method: HTTP method
    ///   - parameters: parameters for the request
    ///   - paginated: if we have to merge this request pagination
    ///   - headers: optional headers to include in the request
    ///   - success: success block
    ///   - failure: failure block
    func request(path: String,
                 method: NetworkingServiceKit.HTTPMethod,
                 with parameters: RequestParameters,
                 paginated: Bool,
                 headers: CustomHTTPHeaders,
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock)
    
    
    /// Returns a list of Service Stubs (api paths with a stub type)
    var stubs:[ServiceStub] { get set }
}

/// Abstract Base Service, sets up a default implementations of the Service protocol. Defaults the service path and version into empty strings.
open class AbstractBaseService: NSObject, Service {

    open var networkManager: NetworkManager

    open var token: APIToken?
    
    open var stubs:[ServiceStub] = [ServiceStub]()

    open var currentConfiguration: APIConfiguration {
        return self.networkManager.configuration
    }

    /// Init method for an Service, each service must have the current token auth and access to the networkManager to execute requests
    ///
    /// - Parameters:
    ///   - token: an existing APIToken
    ///   - networkManager: an object that supports our NetworkManager protocol
    public required init(token: APIToken?, networkManager: NetworkManager) {
        self.token = token
        self.networkManager = networkManager
    }

    /// Currently supported version of the service
    open var serviceVersion: String {
        return ""
    }

    /// Name here your service path
    open var servicePath: String {
        return ""
    }

    /// Returns the baseURL for this service, default is the current configuration URL
    open var baseURL: String {
        return currentConfiguration.baseURL
    }

    /// Returns a local path for an API request, this includes the service version and name. i.e v4/accounts/user_profile
    ///
    /// - Parameter query: api local path
    /// - Returns: local path to the api for the given query
    open func servicePath(for query: String) -> String {
        var fullPath = self.baseURL
        if (!self.servicePath.isEmpty) {
            fullPath += "/" + self.servicePath
        }
        if (!self.serviceVersion.isEmpty) {
            fullPath += "/" + self.serviceVersion
        }
        fullPath += "/" + query
        return fullPath
    }

    /// Returns if this service has a valid token for authentication with our systems
    open var isAuthenticated: Bool {
        return (self.token != nil)
    }

    /// Creates and executes a request using our default Network Manager
    ///
    /// - Parameters:
    ///   - path: full path to the URL
    ///   - method: HTTP method, default is GET
    ///   - parameters: URL or body parameters depending on the HTTP method, default is empty
    ///   - paginated: if the request should follow pagination, success only if all pages are completed
    ///   - headers: custom headers that should be attached with this request
    ///   - success: success block with a response
    ///   - failure: failure block with an error
    open func request(path: String,
                 method: NetworkingServiceKit.HTTPMethod = .get,
                 with parameters: RequestParameters = RequestParameters(),
                 paginated: Bool = false,
                 headers: CustomHTTPHeaders = CustomHTTPHeaders(),
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock) {
        self.networkManager.request(path: servicePath(for: path),
                                    method: method,
                                    with: parameters,
                                    paginated: paginated,
                                    headers: headers,
                                    stubs: self.stubs,
                                    success: success,
                                    failure: { error in
                                        if error.hasTokenExpired && self.isAuthenticated {
                                            //If our error response was because our token expired, then lets tell the delegate
                                            ServiceLocator.shared.delegate?.authenticationTokenDidExpired()
                                        }
                                        failure(error)
        })
    }

}
