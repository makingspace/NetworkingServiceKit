//
//  NetworkManager+Reactive.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 7/31/17.
//
//

import Foundation
import ReactiveSwift

public protocol ReactiveNetworkManager : NetworkManager {
    func request(path: String,
                 method: NetworkingServiceKit.HTTPMethod,
                 with parameters: RequestParameters,
                 paginated: Bool,
                 cachePolicy:CacheResponsePolicy,
                 headers: CustomHTTPHeaders,
                 stubs: [ServiceStub]) -> SignalProducer<[String:Any]?, MSError>
}

extension AlamoNetworkManager: ReactiveNetworkManager {
    
    /// Creates and executes a request using Alamofire in a Reactive form
    ///
    /// - Parameters:
    ///   - path: full path to the URL
    ///   - method: HTTP method, default is GET
    ///   - parameters: URL or body parameters depending on the HTTP method, default is empty
    ///   - paginated: if the request should follow pagination, success only if all pages are completed
    ///   - cachePolicy: specifices the policy to follow for caching responses
    ///   - headers: custom headers that should be attached with this request
    public func request(path: String,
                        method: NetworkingServiceKit.HTTPMethod = .get,
                        with parameters: RequestParameters = RequestParameters(),
                        paginated: Bool = false,
                        cachePolicy:CacheResponsePolicy = CacheResponsePolicy.default,
                        headers: CustomHTTPHeaders = CustomHTTPHeaders(),
                        stubs: [ServiceStub] = [ServiceStub]()) ->  SignalProducer<[String:Any]?, MSError> {
        return SignalProducer { [weak self] observer, lifetime in
            self?.request(path: path,
                          method: method,
                          with: parameters,
                          paginated: paginated,
                          cachePolicy: cachePolicy,
                          headers: headers,
                          stubs: stubs, success: { response in
                            observer.send(value: response)
                            observer.sendCompleted()
            }, failure: { error in
                observer.send(error: error)
            })
        }
    }
}

public extension Service {
    
    /// Lets a service execute a request using the default networking client in a Reactive form
    ///
    /// - Parameters:
    ///   - path: full path to the URL
    ///   - method: HTTP method, default is GET
    ///   - parameters: URL or body parameters depending on the HTTP method, default is empty
    ///   - paginated: if the request should follow pagination, success only if all pages are completed
    ///   - cachePolicy: specifices the policy to follow for caching responses
    ///   - headers: custom headers that should be attached with this request
    public func request(path: String,
                        method: NetworkingServiceKit.HTTPMethod = .get,
                        with parameters: RequestParameters = RequestParameters(),
                        paginated: Bool = false,
                        cachePolicy:CacheResponsePolicy = CacheResponsePolicy.default,
                        headers: CustomHTTPHeaders = CustomHTTPHeaders(),
                        stubs: [ServiceStub] = [ServiceStub]()) ->  SignalProducer<[String:Any]?, MSError> {
        
        if let reactiveNetworkManager = self.networkManager as? ReactiveNetworkManager {
            return reactiveNetworkManager.request(path: servicePath(for: path),
                                                  method: method,
                                                  with: parameters,
                                                  paginated: paginated,
                                                  cachePolicy: cachePolicy,
                                                  headers: headers,
                                                  stubs: stubs).on(failed: { error in
                                                    if error.hasTokenExpired && self.isAuthenticated {
                                                        //If our error response was because our token expired, then lets tell the delegate
                                                        ServiceLocator.shared.delegate?.authenticationTokenDidExpired()
                                                    }
                                                  })
        }
        
        return SignalProducer.empty
    }
}
