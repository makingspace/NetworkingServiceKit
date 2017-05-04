//
//  SimpleMDMServiceTests.swift
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

class SimpleMDMServiceTests: QuickSpec {
    override func spec() {
        beforeEach {
            ServiceLocator.load(withServices: [SimpleMDMService.self])
        }
        
        describe("when loading a simpleMDM app for the current build"){
            context("if we know our app should be found"){
                it("should find the apropiate simpleMDM object") {
                    let path = Bundle(for: type(of: self)).path(forResource: "simplemdm_apps", ofType: "json")!
                    let data = NSData(contentsOfFile: path)!
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/api/v1/apps"), builder: jsonData(data as Data))
                    waitUntil { done in
                        let simpleMDMService = ServiceLocator.service(forType: SimpleMDMService.self)
                        simpleMDMService?.getApp({ app in
                            done()
                        }, failure: { error in
                        })
                    }
                }
            }
        }

        describe("when requesting our device details from simpleMDM") {
            context("and our device has been registered before"){
                it("it should fine the appropiate device"){
                    let path = Bundle(for: type(of: self)).path(forResource: "simplemdm_device", ofType: "json")!
                    let data = NSData(contentsOfFile: path)!
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/api/v1/devices"), builder: jsonData(data as Data))
                    waitUntil { done in
                        let simpleMDMService = ServiceLocator.service(forType: SimpleMDMService.self)
                        simpleMDMService?.getDevice({ response in
                            done()
                        }, failure: { error in
                        })
                    }
                }
            }
        }

        describe("when requesting our device phone number from simpleMDM") {
            context("and our device has been registered before"){
                it("it should fine the appropiate device phone number"){
                    let path = Bundle(for: type(of: self)).path(forResource: "simplemdm_device", ofType: "json")!
                    let data = NSData(contentsOfFile: path)!
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/api/v1/devices"), builder: jsonData(data as Data))
                    waitUntil { done in
                        let simpleMDMService = ServiceLocator.service(forType: SimpleMDMService.self)
                        simpleMDMService?.getDevicePhoneNumber({ phone in
                            expect(phone).to(equal("+13479715605"))
                            done()
                        }, failure: { error in
                        })
                    }
                }
            }
        }
    }
}
