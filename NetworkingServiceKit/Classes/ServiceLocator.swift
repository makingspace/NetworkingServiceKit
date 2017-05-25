//
//  APIServiceLocator.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/23/17.
//
//

import UIKit
public protocol ServiceLocatorDelegate {
    func authenticationTokenDidExpired()
}

open class ServiceLocator: NSObject {
    /// Our Default Networking Client
    public static var defaultNetworkClientType: NetworkManager.Type = AlamoNetworkManager.self

    /// Defines a private singleton, all interactions should be done through static methods
    internal static var shared: ServiceLocator = ServiceLocator()
    internal var delegate: ServiceLocatorDelegate?

    private var currentServices: [String:Service]
    private var loadedServiceTypes: [Service.Type]
    private var configuration: APIConfiguration!
    private var networkManager: NetworkManager!
    private var token: APIToken?

    /// Inits default configuration and network manager
    private override init() {
        self.currentServices = [String: Service]()
        self.loadedServiceTypes = [Service.Type]()
        self.token = APITokenManager.currentToken
    }

    /// Resets the ServiceLocator singleton instance
    open class func reset() {
        ServiceLocator.shared = ServiceLocator()
    }

    /// Reloads token, networkManager and configuration with existing hooked services
    open class func reloadExistingServices() {
        let serviceTypes = ServiceLocator.shared.loadedServiceTypes
        ServiceLocator.shared = ServiceLocator()
        if let configType = APIConfiguration.apiConfigurationType,
            let authType = APIConfiguration.authConfigurationType,
            let tokenType = APITokenManager.tokenType {
            ServiceLocator.set(services: serviceTypes,
                               api: configType,
                               auth: authType,
                               token: tokenType)
        }
    }

    /// Load a custom list of services
    ///
    /// - Parameter serviceTypes: list of services types that are going to get hooked

    /// Sets the current supported services
    ///
    /// - Parameters:
    ///   - serviceTypes: an array of servide types that will be supported when asking for a service
    ///   - apiConfigurationType: the type of APIConfigurationType this services will access
    ///   - authConfigurationType: the type of APIConfigurationAuth this services will include in their requests
    ///   - tokenType: the type of APIToken that will guarantee auth for our service requests
    open class func set(services serviceTypes: [Service.Type],
                         api apiConfigurationType: APIConfigurationType.Type,
                         auth authConfigurationType: APIConfigurationAuth.Type,
                         token tokenType: APIToken.Type) {
        //Set of services that we support
        ServiceLocator.shared.loadedServiceTypes = serviceTypes

        //Hold references to the defined API Configuration and Auth
        APIConfiguration.apiConfigurationType = apiConfigurationType
        APIConfiguration.authConfigurationType = authConfigurationType
        APITokenManager.tokenType = tokenType

        //Init our Default Network Client
        let configuration = APIConfiguration.current
        ServiceLocator.shared.configuration = configuration
        ServiceLocator.shared.networkManager = ServiceLocator.defaultNetworkClientType.init(with: configuration)

        //Allocate services
        ServiceLocator.shared.currentServices = ServiceLocator.shared.loadedServiceTypes.reduce(
        [String: Service]()) { (dict, entry) in
            var dict = dict
            dict[String(describing: entry.self)] = entry.init(token: ServiceLocator.shared.token,
                                                              networkManager: ServiceLocator.shared.networkManager)
            return dict
        }
    }

    /// Returns a service for a specific type
    ///
    /// - Parameter type: type of service
    /// - Returns: service object
    open class func service<T: Service>(forType type: T.Type) -> T? {
        if let service = ServiceLocator.shared.currentServices[String(describing: type.self)] as? T {
            return service
        }
        return nil
    }

    /// Returns a service given a string class name (Useful to be call from Obj-c)
    ///
    /// - Parameter className: string name for the class we are looking
    /// - Returns: a working service
    @objc
    open class func service(forClassName className: String) -> NSObject? {
        //check if className contains framework name
        let components = className.components(separatedBy: ".")
        var realClassName = className
        if components.count == 2 {
            realClassName = components[1]
        }
        if let service = ServiceLocator.shared.currentServices[realClassName] as? NSObject {
            return service
        }
        return nil
    }

    /// Sets a global delegate for the service locator
    open class func setDelegate(delegate: ServiceLocatorDelegate) {
        self.shared.delegate = delegate
    }

    // Returns current NetworkManager
    open class var currentNetworkManager: NetworkManager {
        return ServiceLocator.shared.networkManager
    }
}