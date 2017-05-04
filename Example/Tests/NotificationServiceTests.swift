//
//  NotificationServiceTests.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot on 4/6/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import Quick
import Nimble
import NetworkingServiceKit
import Mockingjay

class NotificationServiceTests: QuickSpec {
    override func spec() {
        
        beforeEach {
            ServiceLocator.load(withServices: [NotificationService.self])
        }
        
        describe("when storing a device token") {
            context("and we havent save a device token"){
                it("should return we couldnt register this token") {
                    MockingjayProtocol.addStub(matcher: http(.post, uri: "/api/v3/devices"), builder: json([String : Any]()))
                    
                    waitUntil { done in
                        APITokenManager.set(object: nil, for: .deviceTokenKey)
                        let notificationService = ServiceLocator.service(forType: NotificationService.self)
                        notificationService?.registerDeviceToken(forPhoneNumber: "305464646", completion: { registered, error in
                            expect(registered).to(beFalse())
                            done()
                        })
                    }
                }
            }
            
            context("and we have save a device token"){
                it("should return we succesfully registered this token") {
                    MockingjayProtocol.addStub(matcher: http(.post, uri: "/api/v3/devices"), builder: json([String : Any]()))

                    waitUntil { done in
                        let notificationService = ServiceLocator.service(forType: NotificationService.self)
                        notificationService?.saveDeviceToken(token: Data(count: 100))
                        notificationService?.registerDeviceToken(forPhoneNumber: "305464646", completion: { registered, error in
                            expect(registered).to(beTrue())
                            done()
                        })
                    }
                }
            }
        }
    }
}
