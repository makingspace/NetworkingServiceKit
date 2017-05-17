//
//  UserDefaultsExtensions.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/25/17.
//
//

import Foundation

extension UserDefaults {
    
    
    /// Defines a custom UserDefaults to be used by the serviceLocator
    open class var serviceLocator: UserDefaults {
        return UserDefaults(suiteName: "\(Bundle.main.appBundleIdentifier).serviceLocator)")!
    }
    
    /// Clears our service locator's user defaults
    open class func clearServiceLocatorUserDefaults()
    {
        UserDefaults().removePersistentDomain(forName: "\(Bundle.main.appBundleIdentifier).serviceLocator)")
    }
}
