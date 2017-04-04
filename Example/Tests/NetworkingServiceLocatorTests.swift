//
//  NetworkingServiceLocatorTests.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot on 4/4/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import NetworkingServiceKit

class fdwfsdfSpec: QuickSpec {

}

class NetworkingServiceLocatorSpec: QuickSpec {
    
    override func spec() {
        
        beforeEach {
            NetworkingServiceLocator.reset()
        }
        describe("Requesting for a service should be not nil if the service has been loaded") {
            context("when service has been loaded") {
                
                it("should return a properly setup service") {
                    NetworkingServiceLocator.load(withServices: [AuthenticationService.self])
                    let authService = NetworkingServiceLocator.service(forType: AuthenticationService.self)
                    expect(authService).toNot(beNil())
                }
                
                it("should return a properly setup service from a given class name as well") {
                    NetworkingServiceLocator.load(withServices: [AuthenticationService.self])
                    let authService = NetworkingServiceLocator.service(forClassName: "AuthenticationService")
                    expect(authService).toNot(beNil())
                }
                
                it("should return a properly setup service from a given class name as well even when including the module name") {
                    NetworkingServiceLocator.load(withServices: [AuthenticationService.self])
                    let authService = NetworkingServiceLocator.service(forClassName: "NetworkingServiceKit.AuthenticationService")
                    expect(authService).toNot(beNil())
                }
            }
            
            context("when service has not been loaded") {
                it("should NOT return a service for a service that has not been loaded") {
                    NetworkingServiceLocator.load(withServices: [AccountService.self])
                    let authService = NetworkingServiceLocator.service(forType: AccountService.self)
                    expect(authService).toNot(beNil())
                }
                
                it("should NOT return a service for a wrong service name") {
                    NetworkingServiceLocator.load(withServices: [AccountService.self])
                    let authService = NetworkingServiceLocator.service(forClassName: "AccountService")
                    expect(authService).toNot(beNil())
                }
            }
            
            context("when loading all default services") {
                it("should include the following services") {
                    NetworkingServiceLocator.loadDefaultServices()
                    let defaultServices = ["AuthenticationService",
                                           "AccountService",
                                           "NotificationService",
                                           "OpsService",
                                           "SimpleMDMService"]
                    for serviceType in defaultServices {
                        let service = NetworkingServiceLocator.service(forClassName: serviceType)
                        expect(service).toNot(beNil())
                    }
                }
            }
        }
    }
    
}
