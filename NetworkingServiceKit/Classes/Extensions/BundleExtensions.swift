//
//  BundleExtensions.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/6/17.
//
//

import Foundation

extension Bundle {
    //Returns a non optional bundle identifier
    internal var appBundleIdentifier: String {
        return self.bundleIdentifier ?? "com.makespace.app"
    }

    //Returns a non optional executable name of the target
    internal var bundleExecutableName: String {
        return self.infoDictionary?["CFBundleExecutable"] as? String ?? "com.makespace.app"
    }

    //Returns a a non optional bundleVersion
    internal var bundleVersion: String {
        return self.infoDictionary?["CFBundleVersion"] as? String ?? "1.0.0"
    }
}
