//
//  SimpleMDMApp.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 1/17/17.
//
//

import Foundation
import SwiftyJSON

public enum SimpleMDMAppType: String
{
    case appStore = "app_store"
    case enterprise = "enterprise"
}

public struct SimpleMDMApp {
    public let appId:Int
    public let name:String
    public let appType:SimpleMDMAppType
    public let version:String
    public let localVersion:String
    public let bundleId:String
    public let currentMDMApp:Bool
    public let versionIsUpdated:Bool
    
    public init(json:JSON) {
        let attributes = json["attributes"]
        
        self.appId = json["id"].intValue
        self.name = attributes["name"].stringValue
        self.appType = SimpleMDMAppType(rawValue: attributes["app_type"].stringValue) ?? .enterprise
        self.version = attributes["version"].stringValue
        self.bundleId = attributes["bundle_identifier"].stringValue
        
        self.currentMDMApp = Bundle.main.appBundleIdentifier == self.bundleId
        
        let localVersion = Bundle.main.bundleVersion
        self.versionIsUpdated = SimpleMDMApp.isVersionNewer(localVersion: localVersion, serverVersion: self.version)
        self.localVersion = localVersion
    }
    
    public static func isVersionNewer(localVersion:String, serverVersion:String) -> Bool
    {
        let result = localVersion.compare(serverVersion, options: NSString.CompareOptions.numeric)
        if result == ComparisonResult.orderedDescending || result == ComparisonResult.orderedSame{
            return true
        }
        return false
    }
}
