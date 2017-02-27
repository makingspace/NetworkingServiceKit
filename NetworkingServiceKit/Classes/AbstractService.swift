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
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorBlock)
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
    
    public func request(path: String,
                 method: HTTPMethod,
                 with parameters: [String: Any],
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorBlock)
    {
        networkManager.request(path: servicePath(for: path), method: method, with: parameters, success: success, failure: failure)
    }
    
}
