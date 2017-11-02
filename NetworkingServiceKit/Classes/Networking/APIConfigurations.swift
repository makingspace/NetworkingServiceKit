//
//  APIConfiguration.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation

let APIConfigurationKey = "Server"

/// Protocol for describing the necessary authentication key/secret to use when authenticating a client
public protocol APIConfigurationAuth {
    var secret: String { get }
    var key: String { get }
    init(bundleId: String?)
}

/// Protocol for describing a server connection
public protocol APIConfigurationType {
    var URL: String { get }
    var webURL: String { get }
    static var defaultConfiguration: APIConfigurationType { get }
    init(stringKey: String)
}

/// Handles the current server connection and authentication for a valid APIConfigurationType and APIConfigurationAuth
@objc public class APIConfiguration: NSObject {
    public static var apiConfigurationType: APIConfigurationType.Type?
    public static var authConfigurationType: APIConfigurationAuth.Type?
    @objc public let baseURL: String
    @objc public let webURL: String
    @objc public let APIKey: String
    @objc public let APISecret: String
    
    internal init(type: APIConfigurationType, auth: APIConfigurationAuth) {
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
    
    /// Returns the current APIConfiguration, either staging or production
    @objc public static var current: APIConfiguration {
        guard let configurationType = APIConfiguration.apiConfigurationType,
            let authType = APIConfiguration.authConfigurationType else {
                print("Error: ServiceLocator couldn't find the current APIConfiguration, make sure to define your own types for APIConfiguration.apiConfigurationType and APIConfiguration.authConfigurationType")
                return APIConfiguration()
        }
        return APIConfiguration(type: self.currentConfigurationType(with: configurationType),
                                auth: authType.init(bundleId: Bundle.main.appBundleIdentifier))
    }
    public static func currentConfigurationType(with configuration: APIConfigurationType.Type) -> APIConfigurationType {
        let environmentDictionary = ProcessInfo.processInfo.environment
        if let environmentConfiguration = environmentDictionary[APIConfigurationKey] {
            return configuration.init(stringKey: environmentConfiguration)
        }
        
        return configuration.defaultConfiguration
    }
}
