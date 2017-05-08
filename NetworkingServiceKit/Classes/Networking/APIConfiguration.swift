//
//  APIConfiguration.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation

let APIConfigurationKey = "Server"
public protocol APIConfigurationAuth
{
    var secret:String { get }
    var key:String { get }
    init(bundleId:String?)
}
public protocol APIConfigurationType
{
    var URL:String { get }
    var webURL:String { get }
    static var stagingConfiguration:APIConfigurationType { get }
    static var productionConfiguration:APIConfigurationType { get }
    init(stringKey:String)
}

public class APIConfiguration: NSObject
{
    public static var apiConfigurationType:APIConfigurationType.Type?
    public static var authConfigurationType:APIConfigurationAuth.Type?
    public let baseURL:String
    public let webURL:String
    public let APIKey:String
    public let APISecret:String
    
    internal init(type:APIConfigurationType, auth:APIConfigurationAuth){
        self.baseURL = type.URL
        self.webURL = type.webURL
        self.APIKey = auth.key
        self.APISecret = auth.secret
    }
    private override init() {
        self.baseURL = ""
        self.webURL = ""
        self.APIKey = ""
        self.APISecret = ""
    }
    
    public static var current:APIConfiguration {
        guard let configurationType = APIConfiguration.apiConfigurationType,
            let authType = APIConfiguration.authConfigurationType else {
                print("Error: ServiceLocator couldn't find the current APIConfiguration, make sure to define your own types for APIConfiguration.apiConfigurationType and APIConfiguration.authConfigurationType")
            return APIConfiguration()
        }
        return APIConfiguration(type: self.currentConfigurationType(with: configurationType),
                                auth: authType.init(bundleId: Bundle.main.appBundleIdentifier))
    }
    public static func currentConfigurationType(with configuration: APIConfigurationType.Type) -> APIConfigurationType {
        let environmentDictionary = ProcessInfo.processInfo.environment;
        if let environmentConfiguration = environmentDictionary[APIConfigurationKey] {
            return configuration.init(stringKey: environmentConfiguration)
        }
        
        #if DEBUG || STAGING
            return configuration.stagingConfiguration
        #else
            return configuration.productionConfiguration
        #endif
    }
}
