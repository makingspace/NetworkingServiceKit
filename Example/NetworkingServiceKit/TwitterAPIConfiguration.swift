//
//  TwitterAPIConfiguration.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot on 5/4/17.
//  Copyright © 2017 Makespace Inc. All rights reserved.
//

import Foundation
import NetworkingServiceKit

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
public enum TwitterAPIConfigurationType: String, APIConfigurationType
{
    case staging = "STAGING"
    case production = "PRODUCTION"
    case custom = "CUSTOM"
    
    //Custom init for a key (makes it non failable as oppose to (rawValue:)
    public init(stringKey: String) {
        switch stringKey {
        case "STAGING":
            self = .staging
        case "PRODUCTION":
            self = .production
        case "CUSTOM":
            self = .custom
        default:
            self = .staging
        }
    }
    
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
    
    //Explicitly tells our protocol which is our staging configuration
    public static var stagingConfiguration: APIConfigurationType
    {
        return TwitterAPIConfigurationType.staging
    }
    
    //Explicitly tells our protocol which is our production configuration
    public static var productionConfiguration: APIConfigurationType
    {
        return TwitterAPIConfigurationType.production
    }
}
