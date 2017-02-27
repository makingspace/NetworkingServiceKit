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
}

open class AstractBaseService: AbstractService
{
    
    public var networkManager: NetworkManager
    
    public var token: APIToken?
    
    public var currentConfiguration: APIConfiguration {
        return self.networkManager.configuration
    }
    
    public required init(token: APIToken?, networkManager: NetworkManager) {
        self.token = token
        self.networkManager = networkManager
    }

    public var serviceVersion: String {
        return "v3"
    }
    
    public var servicePath:String {
        return ""
    }
    
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
    
}
