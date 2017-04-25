//
//  APIConfiguration.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation

///Environment variable for harcoding the server mode
let APIConfigurationKey = "Server"

//Procotols for handling Auth and APIType
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
}

public enum TwitterApp: Int, APIConfigurationAuth {
    case twitterClient = 0
    
    public init(bundleId:String?)
    {
        guard let bundleId = bundleId else {
            self.init(rawValue: 0)!
            return
        }
        
        var n = 0
        while let app = TwitterApp(rawValue: n) {
            if app.bundleID.hasPrefix(bundleId) {
                self.init(rawValue: app.rawValue)!
                return
            }
            n += 1
        }
        //for this example lets default into our twitter client, otherwise here where you check your bundleID for your app
        self.init(rawValue: 0)!
    }
    
    public var bundleID: String {
        switch self {
        case .twitterClient:
            return "com.makespace.MakespaceServiceKit"
        }
    }
    
    //Twitter Developer Key and Secret, create your own here: https://apps.twitter.com
    public var key: String {
        switch self {
        case .twitterClient:
            return "QUk41VlXdW1fgvxPU2YP5wiGB"
        }
    }
    public var secret: String {
        switch self {
        case .twitterClient:
            return "RiikF9L25dMhSbFGFD1QRPk036IgQ3BUqpWkq7gN8fIfuYwpoI"
        }
    }
}

/// Server information for out twtter servers, in this case we dont have a staging URL for twitter API
public enum ServerConfigurationType: String, APIConfigurationType
{
    case staging = "STAGING"
    case production = "PRODUCTION"
    case custom = "CUSTOM"
    
    /// URL for given server
    public var URL: String {
        switch self {
        case .staging:
            return "https://api.twitter.com"
        case .production:
            return "https://api.twitter.com"
        case .custom:
            return "https://api.twitter.com"
        }
    }
    
    /// Web URL for given server
    public var webURL: String {
        switch self {
        case .staging:
            return "https://twitter.com"
        case .production:
            return "https://twitter.com"
        case .custom:
            return "https://twitter.com"
        }
    }
    
    /// Display name for given server
    public var displayName: String {
        return self.rawValue.capitalized
    }
}

/// An API configuration object describing the server we are connecting and the key/secret needed for authentication
@objc
public class APIConfiguration: NSObject
{
    public let baseURL:String
    public let webURL:String
    public let APIKey:String
    public let APISecret:String
    
    public init(type:APIConfigurationType, auth:APIConfigurationAuth){
        self.baseURL = type.URL
        self.webURL = type.webURL
        self.APIKey = auth.key
        self.APISecret = auth.secret
    }
    
    /// The current APIConfiguration based on our bundleID
    public static var current:APIConfiguration {
        return APIConfiguration(type: self.currentConfigurationType,
                                auth: TwitterApp(bundleId: Bundle.main.appBundleIdentifier))
    }
    
    /// The current configuration type that we are running, looks for an Environment variable "Server" for hardcoding the server type
    public static var currentConfigurationType:APIConfigurationType {
        let environmentDictionary = ProcessInfo.processInfo.environment;
        if let environmentConfiguration = environmentDictionary[APIConfigurationKey] {
            return ServerConfigurationType(rawValue: environmentConfiguration)!
        }
        
        #if DEBUG || STAGING
            return ServerConfigurationType.staging
        #else
            return ServerConfigurationType.production
        #endif
    }
}
