//
//  ServiceLocator+Stub.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 6/2/17.
//
//

import Foundation

extension ServiceLocator
{
    /// Returns a service for a specific type
    ///
    /// - Parameter type: type of service
    /// - Returns: service object
    open class func service<T: Service>(forType type: T.Type, stubs:[ServiceStub]) -> T? {
        if var service = ServiceLocator.shared.currentServices[String(describing: type.self)] as? T {
            service.stubs = stubs
            return service
        }
        return nil
    }
    
    /// Sets the current auth token into all currently loaded services
    internal class func reloadTokenForServices() {
        for (serviceClass, service) in ServiceLocator.shared.currentServices {
            var service = service
            service.token = APITokenManager.currentToken
            ServiceLocator.shared.currentServices[serviceClass] = service
        }
    }
}
