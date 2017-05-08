//
//  UserDefaultsExtensions.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/25/17.
//
//

import Foundation

extension UserDefaults {
    
    open class var serviceLocator: UserDefaults {
        return UserDefaults(suiteName: "\(Bundle.main.appBundleIdentifier).serviceLocator)")!
    }
    
    open class func clearServiceLocatorUserDefaults()
    {
        UserDefaults().removePersistentDomain(forName: "\(Bundle.main.appBundleIdentifier).serviceLocator)")
    }
}
