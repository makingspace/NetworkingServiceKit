//
//  APIServiceLocator.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 2/23/17.
//
//

import UIKit

open class NetworkingServiceLocator: NSObject {
    
    private static let shared:NetworkingServiceLocator = NetworkingServiceLocator()
    
    private var currentServices:[String:AbstractService]
    private var loadedServiceTypes:[AbstractService.Type]
    private var configuration:APIConfiguration
    private var token:APIToken?
    private var networkManager:NetworkManager
    
    private override init() {
        self.currentServices = [String:AbstractService]()
        self.loadedServiceTypes = [AbstractService.Type]()
        self.configuration = APIConfiguration.current!
        self.networkManager = AlamoNetworkManager(with: self.configuration)
    }
    
    open class func loadDefaultServices()
    {
        let defaultServices = [AuthenticationService.self]
        NetworkingServiceLocator.load(withServices: defaultServices)
    }
    
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
    
    open class func service<T : AbstractService>(forType type: T.Type) -> T?
    {
        if let service = NetworkingServiceLocator.shared.currentServices[String(describing: type.self)] as? T {
            return service
        }
        return nil
    }
}
