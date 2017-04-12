//
//  APIConfiguration.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 2/27/17.
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
}

public enum MakeSpaceApp: Int, APIConfigurationAuth {
    case clouder = 0
    case rocket = 1
    case photoSpace = 2
    case photoKit = 3
    
    public init(bundleId:String?)
    {
        guard let bundleId = bundleId else {
            self.init(rawValue: 0)!
            return
        }
        
        var n = 0
        while let app = MakeSpaceApp(rawValue: n) {
            if app.bundleID.hasPrefix(bundleId) {
                self.init(rawValue: app.rawValue)!
                return
            }
            n += 1
        }
        
        //if we dont find a proper APP, we are defaulting into clouder key/secret
        self.init(rawValue: 0)!
    }
    
    public var bundleID: String {
        switch self {
        case .clouder:
            return "com.makespace.clouder"
        case .rocket:
            return "com.makespace.Rocket"
        case .photoSpace:
            return "com.makespace.PhotoSpace"
        case .photoKit:
            return "com.makespace.PhotoKit"
        }
    }
    
    public var key: String {
        switch self {
        case .clouder:
            return "heJVRD823lmpbBimLRe2hnR7R73E3N5o"
        case .rocket:
            return "vIBIr!64yr.-3lgOfGuDykUj=l?n@g_zCTFw.lBL"
        case .photoSpace:
            return "AY6Q3N4VKfgUad0VN89m3fN3aI8VQa!2wstI?AzT"
        case .photoKit:
            return "I474O=y!U9WOgtIXZGvdr_!RaJ-WTD1ZC1gGjiL5"
        }
    }
    public var secret: String {
        switch self {
        case .clouder:
            return "cc2ycni1958tOEvW5uRNgbcIAhRUGO86wUMqQIIp5rO9PPRc7xiwfdrMjAVWdB8V"
        case .rocket:
            return "f;.TEcgoK.y?_bDEusiLlERh;NKWaaX_rqN5FDtKu6ZqDOrMN-K5;UaWCD5xVu;==c@K9shLW;6O2f.rW?ZZzll3v43fHRvkAnU1AAou;8MCxN0mMY@0FPpR8cn::XUO"
        case .photoSpace:
            return "OzSjxM=xw5hVoFZpXIdtz76gqu.CLnqy;Km3gPgwOO2D8ckdqm.zCTRmQa5NhaUFau0M@RwOuQon26Dh@n4t=9WlX?!!Z.d=xvifS!@@wapz-Jl6!B:QjzxxrtMAqTU4"
        case .photoKit:
            return "gGh5bQ0uprA39i_8T4y9HXJaRcsxE8j!oc=ecTrVHSMPyee9FwD?QYi0ldlRhBlYl:EF6Q.L@GY-E38tdmsN00x45@Vs3;BPtINe.?hOLf_KBEb9PEFKaRzdY!9VVR31"
        }
    }
}

public enum MakespaceConfigurationType: String, APIConfigurationType
{
    case staging = "STAGING"
    case production = "PRODUCTION"
    case custom = "CUSTOM"
    
    /// URL for given server
    public var URL: String {
        //return a custom URL if anything has been set
        if let customURL = APITokenManager.object(for: .customURLKey) as? String{
            return customURL
        }
        switch self {
        case .staging:
            return "https://staging.mksp.co/api"
        case .production:
            return "https://api.makespace.com"
        case .custom:
            return "https://api.makespace.com"
        }
    }
    
    /// Web URL for given server
    public var webURL: String {
        switch self {
        case .staging:
            return "https://staging.mksp.co"
        case .production:
            return "https://makespace.com"
        case .custom:
            return "https://makespace.com"
        }
    }
    
    /// Display name for given server
    public var displayName: String {
        return self.rawValue.capitalized
    }
}

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
    
    public static var current:APIConfiguration {
        return APIConfiguration(type: self.currentConfigurationType,
                                auth: MakeSpaceApp(bundleId: Bundle.main.appBundleIdentifier))
    }
    
    public static var currentConfigurationType:APIConfigurationType {
        let environmentDictionary = ProcessInfo.processInfo.environment;
        if let environmentConfiguration = environmentDictionary[APIConfigurationKey] {
            return MakespaceConfigurationType(rawValue: environmentConfiguration)!
        }
        
        #if DEBUG || STAGING
            return MakespaceConfigurationType.staging
        #else
            return MakespaceConfigurationType.production
        #endif
    }
}
