//
//  ServiceLocatorTests.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot on 4/4/17.
//  Copyright © 2017 Makespace Inc. All rights reserved.
//

import Quick
import Nimble
import NetworkingServiceKit

class ServiceLocatorSpec: QuickSpec {
    
    override func spec() {
        
        beforeEach {
            ServiceLocator.reset()
        }
        describe("Requesting for a service should be not nil if the service has been loaded") {
            context("when service has been loaded") {
                
                it("should return a properly setup service") {
                    ServiceLocator.set(services: [TwitterAuthenticationService.self],
                                       api: TwitterAPIConfigurationType.self,
                                       auth: TwitterApp.self,
                                       token: TwitterAPIToken.self)
                    let authService = ServiceLocator.service(forType: TwitterAuthenticationService.self)
                    expect(authService).toNot(beNil())
                }
                
                it("should return a properly setup service from a given class name as well") {
                    ServiceLocator.set(services: [TwitterAuthenticationService.self],
                                       api: TwitterAPIConfigurationType.self,
                                       auth: TwitterApp.self,
                                       token: TwitterAPIToken.self)
                    let authService = ServiceLocator.service(forClassName: "TwitterAuthenticationService")
                    expect(authService).toNot(beNil())
                }
                
                it("should return a properly setup service from a given class name as well even when including the module name") {
                    ServiceLocator.set(services: [TwitterAuthenticationService.self],
                                       api: TwitterAPIConfigurationType.self,
                                       auth: TwitterApp.self,
                                       token: TwitterAPIToken.self)
                    let authService = ServiceLocator.service(forClassName: "NetworkingServiceKit.TwitterAuthenticationService")
                    expect(authService).toNot(beNil())
                }
            }
            
            context("when service has not been loaded") {
                it("should NOT return a service for a service that has not been loaded") {
                    ServiceLocator.set(services: [TwitterSearchService.self],
                                       api: TwitterAPIConfigurationType.self,
                                       auth: TwitterApp.self,
                                       token: TwitterAPIToken.self)
                    let authService = ServiceLocator.service(forType: TwitterSearchService.self)
                    expect(authService).toNot(beNil())
                }
                
                it("should NOT return a service for a wrong service name") {
                    ServiceLocator.set(services: [TwitterSearchService.self],
                                       api: TwitterAPIConfigurationType.self,
                                       auth: TwitterApp.self,
                                       token: TwitterAPIToken.self)
                    let authService = ServiceLocator.service(forClassName: "TwitterSearchService")
                    expect(authService).toNot(beNil())
                }
            }
        }
        
        describe("Services should get clear after resetting") {
            context("when loading a service after resetting") {
                ServiceLocator.set(services: [TwitterAuthenticationService.self],
                                   api: TwitterAPIConfigurationType.self,
                                   auth: TwitterApp.self,
                                   token: TwitterAPIToken.self)
                ServiceLocator.reset()
                let authService = ServiceLocator.service(forType: TwitterAuthenticationService.self)
                expect(authService).to(beNil())
            }
        }
    }
    
}
