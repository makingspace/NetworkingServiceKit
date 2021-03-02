//
//  BundleExtensions.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/6/17.
//
//

import Foundation

extension Bundle {
    
    /// Returns a non optional bundle identifier, if bundle identifier is nil it will return `"com.app"`
    public var appBundleIdentifier: String {
        return self.bundleIdentifier ?? "com.app"
    }

    //Returns a non optional executable name of the target
    public var bundleExecutableName: String {
        return self.infoDictionary?["CFBundleExecutable"] as? String ?? "com.app"
    }

    //Returns a a non optional bundleVersion
    public var bundleVersion: String {
        let marketingVersion = infoDictionary?["CFBundleShortVersionString"] as? String //e.g. 1.2.0
        let buildNumber = self.infoDictionary?["CFBundleVersion"] as? String//e.g. 0
        
        return marketingVersion  ?? buildNumber ?? "1.0.0"
    }
}
