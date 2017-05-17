//
//  AppDelegate.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 02/23/2017.
//  Copyright (c) 2017 Makespace Inc. All rights reserved.
//

import UIKit
import NetworkingServiceKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Attach our services
        ServiceLocator.set(services: [TwitterAuthenticationService.self,LocationService.self,TwitterSearchService.self],
                           api: TwitterAPIConfigurationType.self,
                           auth: TwitterApp.self,
                           token: TwitterAPIToken.self)
        //if we are not authenticated, launch out auth service
        if APITokenManager.currentToken ==  nil {
            let authService = ServiceLocator.service(forType: TwitterAuthenticationService.self)
            authService?.authenticateTwitterClient(completion: { authenticated in
                print("Authenticated with Twitter")
            })
        }
        return true
    }
}

