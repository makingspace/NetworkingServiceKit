//
//  APIServiceLocator.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 2/23/17.
//
//

import UIKit
import NetworkingServiceKit
public protocol NetworkingServiceLocatorDelegate
{
    func networkLocatorTokenDidExpired()
}

open class NetworkingServiceLocator: NSObject {
    
    /// Defines a private singleton, all interactions should be done through static methods
    internal static var shared:NetworkingServiceLocator = NetworkingServiceLocator()
    internal var delegate:NetworkingServiceLocatorDelegate?
    
    private var currentServices:[String:AbstractService]
    private var loadedServiceTypes:[AbstractService.Type]
    private var configuration:APIConfiguration
    private var token:APIToken?
    private var networkManager:NetworkManager
    
    /// Inits default configuration and network manager
    private override init() {
        self.currentServices = [String:AbstractService]()
        self.loadedServiceTypes = [AbstractService.Type]()
        self.configuration = APIConfiguration.current!
        self.networkManager = AlamoNetworkManager(with: self.configuration)
        self.token = APITokenManager.currentToken
    }
    
    /// Reloads token, networkManager and configuration with existing hooked services
    open class func reloadServiceLocator()
    {
        let serviceTypes = NetworkingServiceLocator.shared.loadedServiceTypes
        NetworkingServiceLocator.shared = NetworkingServiceLocator()
        NetworkingServiceLocator.load(withServices: serviceTypes)
    }
    
    /// Load Default services that all app need
    open class func loadDefaultServices()
    {
        //Define here default services
        if let defaultServices = [AuthenticationService.self,
                                  AccountService.self,
                                  NotificationService.self,
                                  OpsService.self,
                                  SimpleMDMService.self] as? [AbstractService.Type] {
            NetworkingServiceLocator.load(withServices: defaultServices)
        }
    }
    
    
    /// Load a custom list of services
    ///
    /// - Parameter serviceTypes: list of services types that are going to get hooked
    open class func load(withServices serviceTypes:[AbstractService.Type])
    {
        NetworkingServiceLocator.shared.loadedServiceTypes = serviceTypes
        
        NetworkingServiceLocator.shared.currentServices = NetworkingServiceLocator.shared.loadedServiceTypes.reduce(
        [String:AbstractService]()) { (dict, entry) in
            var dict = dict
            dict[String(describing: entry.self)] = entry.init(token: NetworkingServiceLocator.shared.token,
                                                              networkManager: NetworkingServiceLocator.shared.networkManager)
            return dict
        }
    }
    
    
    /// Returns a service for a specific type
    ///
    /// - Parameter type: type of service
    /// - Returns: service object
    open class func service<T : AbstractService>(forType type: T.Type) -> T?
    {
        if let service = NetworkingServiceLocator.shared.currentServices[String(describing: type.self)] as? T {
            return service
        }
        return nil
    }
    
    /// Sets a global delegate for the service locator
    open class func setDelegate(delegate: NetworkingServiceLocatorDelegate)
    {
        self.shared.delegate = delegate
    }
}
