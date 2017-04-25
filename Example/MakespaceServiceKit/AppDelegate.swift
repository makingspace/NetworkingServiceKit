//
//  AppDelegate.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 02/23/2017.
//  Copyright (c) 2017 Makespace Inc. All rights reserved.
//

import UIKit
import MakespaceServiceKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        ServiceLocator.loadDefaultServices()
        //if we are not authenticated
        if APITokenManager.currentToken ==  nil {
            let authService = ServiceLocator.service(forType: AuthenticationService.self)
            authService?.authenticateTwitterClient(completion: { authenticated in
                print("Authenticated with Twitter")
            })
        }
        return true
    }
}

