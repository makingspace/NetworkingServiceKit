//
//  AlamoNetworkManagerTests.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot on 4/5/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
import Quick
import Nimble
import NetworkingServiceKit
import Mockingjay

class RandomService : AbstractBaseService {
    
}
class AlamoNetworkManagerTests: QuickSpec
{
    override func spec() {
        let arrayResponse = [["param" : "value"],["param" : "value"]] as [[String : Any]]
        let dictionaryResponse = ["param" : "value"] as [String : Any]
        
        beforeSuite {
            NetworkingServiceLocator.load(withServices: [RandomService.self])
        }
        describe("when executing a request") {
            context("that returns an array") {
                
                it("should have a response dictionary with an array of results inside") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/api/v3/array"), builder: json(arrayResponse))
                    
                    waitUntil { done in
                        let randomService = NetworkingServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "array", success: { response in
                            let results = response["results"] as! [[String : Any]]
                            expect(results).toNot(beNil())
                            done()
                        }, failure: { error, errorDetails in
                        })
                    }
                }
            }
            
            context("that returns a dictionary"){
                it("should have a response dictionary with a dictionary response") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/api/v3/dictionary"), builder: json(dictionaryResponse))
                    
                    waitUntil { done in
                        let randomService = NetworkingServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "dictionary", success: { response in
                            expect(response).toNot(beNil())
                            done()
                        }, failure: { error, errorDetails in
                        })
                    }
                }
            }
            
            context("that returns a paginated dictionary") {
                
            }
            
            context("that returns an empty response") {
                it("should have a empty dictionary") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/api/v3/empty_dictionary"), builder: json([String : Any]()))
                    
                    waitUntil { done in
                        let randomService = NetworkingServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "empty_dictionary", success: { response in
                            expect(response).toNot(beNil())
                            expect(response.count).to(equal(0))
                            done()
                        }, failure: { error, errorDetails in
                        })
                    }
                }
            }
            
            context("that returns a 500") {
                it("should return an error of type .internalServerError") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/api/v3/error500"), builder: http(500))
                    
                    waitUntil { done in
                        let randomService = NetworkingServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "error500", success: { response in
                        }, failure: { error, errorDetails in
                            expect(error.responseCode).to(equal(500))
                            switch error {
                            case .responseValidationFailed(let reason):
                                switch reason {
                                case .internalServerError: done()
                                default:break
                                }
                            default:break
                            }
                        })
                    }
                }
            }
            
            context("that returns a error on the response") {
                it("should return an error of type .badRequest") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/api/v3/error500"), builder: http(404))
                    
                    waitUntil { done in
                        let randomService = NetworkingServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "error500", success: { response in
                        }, failure: { error, errorDetails in
                            expect(error.responseCode).to(equal(404))
                            switch error {
                            case .responseValidationFailed(let reason):
                                switch reason {
                                case .badRequest(let code):
                                    expect(code).to(equal(404))
                                    done()
                                default:break
                                }
                            default:break
                            }
                        })
                    }
                }
            }
            
            context("that returns a 401") {
                it("should return an error of type .tokenExpired") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/api/v3/error500"), builder: http(401))
                    
                    waitUntil { done in
                        let randomService = NetworkingServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "error500", success: { response in
                        }, failure: { error, errorDetails in
                            expect(error.responseCode).to(equal(401))
                            switch error {
                            case .responseValidationFailed(let reason):
                                switch reason {
                                case .tokenExpired(let code):
                                    expect(code).to(equal(401))
                                    done()
                                default:break
                                }
                            default:break
                            }
                        })
                    }
                }
            }
        }
    }
}
