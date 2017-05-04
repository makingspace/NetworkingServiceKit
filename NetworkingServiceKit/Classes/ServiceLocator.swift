//
//  APIServiceLocator.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/23/17.
//
//

import UIKit
public protocol ServiceLocatorDelegate
{
    func networkLocatorTokenDidExpired()
}

open class ServiceLocator: NSObject {
    
    /// Defines a private singleton, all interactions should be done through static methods
    internal static var shared:ServiceLocator = ServiceLocator()
    internal var delegate:ServiceLocatorDelegate?
    
    private var currentServices:[String:AbstractService]
    private var loadedServiceTypes:[AbstractService.Type]
    private var configuration:APIConfiguration
    private var token:APIToken?
    private var networkManager:NetworkManager
    
    /// Inits default configuration and network manager
    private override init() {
        self.currentServices = [String:AbstractService]()
        self.loadedServiceTypes = [AbstractService.Type]()
        self.configuration = APIConfiguration.current
        self.networkManager = AlamoNetworkManager(with: self.configuration)
        self.token = APITokenManager.currentToken
    }
    
    /// Resets the ServiceLocator singleton instance
    open class func reset()
    {
        ServiceLocator.shared = ServiceLocator()
    }
    
    /// Reloads token, networkManager and configuration with existing hooked services
    open class func reloadExistingServices()
    {
        let serviceTypes = ServiceLocator.shared.loadedServiceTypes
        ServiceLocator.shared = ServiceLocator()
        ServiceLocator.load(withServices: serviceTypes)
    }
    
    /// Load Default services that all app need
    open class func loadDefaultServices()
    {
        //Define here default services
        let defaultServices:[AbstractService.Type] = [AuthenticationService.self,
                                                      AccountService.self,
                                                      NotificationService.self,
                                                      OpsService.self,
                                                      SimpleMDMService.self]
        ServiceLocator.load(withServices: defaultServices)
    }
    
    
    /// Load a custom list of services
    ///
    /// - Parameter serviceTypes: list of services types that are going to get hooked
    open class func load(withServices serviceTypes:[AbstractService.Type])
    {
        ServiceLocator.shared.loadedServiceTypes = serviceTypes
        
        ServiceLocator.shared.currentServices = ServiceLocator.shared.loadedServiceTypes.reduce(
        [String:AbstractService]()) { (dict, entry) in
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
    open class func service<T : AbstractService>(forType type: T.Type) -> T?
    {
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
    open class func service(forClassName className:String) -> NSObject? {
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
    open class func setDelegate(delegate: ServiceLocatorDelegate)
    {
        self.shared.delegate = delegate
    }
    
    // Returns current NetworkManager
    open class var currentNetworkManager:NetworkManager {
        return ServiceLocator.shared.networkManager
    }
}
