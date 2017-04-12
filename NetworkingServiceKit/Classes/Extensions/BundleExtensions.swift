//
//  BundleExtensions.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 4/6/17.
//
//

import Foundation

extension Bundle
{
    //Returns a bundle identifier that is not optional
    internal var appBundleIdentifier: String {
        return self.bundleIdentifier ?? "com.makespace.app"
    }
    
    //Returns the executable name of the target
    internal var bundleExecutableName: String {
        return self.infoDictionary?["CFBundleExecutable"] as? String ?? "com.makespace.app"
    }
    
    internal var bundleVersion: String {
        return self.infoDictionary?["CFBundleVersion"] as? String ?? "1.0.0"
    }
}
