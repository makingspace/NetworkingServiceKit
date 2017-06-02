//
//  Service.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation

/// Defines the Behavior of a stub response
///
/// - immediate: the sub returns inmediatly
/// - delayed: the stub returns after a defined number of seconds
public enum ServiceStubBehavior {
    /// Return a response immediately.
    case immediate
    
    /// Return a response after a delay.
    case delayed(seconds: TimeInterval)
}

/// Used for stubbing responses.
public enum ServiceStubType {
    
    /// The network returned a response, including status code and response.
    case success(code:Int, response:[String:Any]?)
    
    /// The network request failed with an error
    case failure(code:Int, response:[String:Any]?)
}

/// Defines the scenario case that this request expects
///
/// - authenticated: service is authenticated
/// - unauthenticated: service is unauthenticated
public enum ServiceStubCase {
    case authenticated(tokenInfo:[String:Any])
    case unauthenticated
}

/// Defines a stub request case
public struct ServiceStubRequest {
    public let path:String
    public let parameters:[String:Any]?
    
    public init(path:String, parameters:[String:Any]? = nil) {
        self.path = path
        self.parameters = parameters
    }
}

/// Defines stub response for a matching API path
public struct ServiceStub {
    public let request:ServiceStubRequest
    public let stubType:ServiceStubType
    public let stubBehavior:ServiceStubBehavior
    public let stubCase:ServiceStubCase
    
    public init(execute request:ServiceStubRequest,
                with type:ServiceStubType,
                when stubCase:ServiceStubCase = .unauthenticated,
                react behavior:ServiceStubBehavior = .immediate)
    {
        self.request = request
        self.stubType = type
        self.stubBehavior = behavior
        self.stubCase = stubCase
    }
}
