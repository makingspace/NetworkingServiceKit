//
//  AlamoNetworkManagerTests.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot on 4/5/17.
//  Copyright © 2017 Makespace Inc. All rights reserved.
//

import XCTest
import Quick
import Nimble
import NetworkingServiceKit
import Mockingjay

public enum RandomConfigurationType: String, APIConfigurationType {
    case basic = "BASIC"

    public init(stringKey: String) {
        self = .basic
    }
    
    /// URL for given server
    public var URL: String {
        return "https://random.com"
    }
    
    /// Web URL for given server
    public var webURL: String {
        return "https://random.com"
    }
    
    /// Display name for given server
    public var displayName: String {
        return self.rawValue.capitalized
    }
    
    /// Explicitly tells our protocol which is our default configuration
    public static var defaultConfiguration: APIConfigurationType {
        return RandomConfigurationType.basic
    }
}

class RandomService : AbstractBaseService {
    override var serviceVersion: String {
        return "v3"
    }
}
class AlamoNetworkManagerTests: QuickSpec
{
    override func spec() {
        let arrayResponse = [["param" : "value"],["param" : "value"]] as [[String : Any]]
        let dictionaryResponse = ["param" : "value"] as [String : Any]
        let dictionaryNextResponse2 = ["next" : "https://random.com/v3/dictionary_next2", "results" : [["obj1" : "value"]]] as [String : Any]
        let dictionaryNextResponse3 = ["next" : "https://random.com/v3/dictionary_next3", "results" : [["obj2" : "value"]]] as [String : Any]
        let dictionaryNextResponse4 = ["results" : [["obj3" : "value"]]] as [String : Any]
        
        beforeEach {
            MockingjayProtocol.removeAllStubs()
            ServiceLocator.defaultNetworkClientType = AlamoNetworkManager.self
            ServiceLocator.set(services: [RandomService.self],
                               api: RandomConfigurationType.self,
                               auth: TwitterApp.self,
                               token: TwitterAPIToken.self)
        }
        describe("when executing a request") {
            context("that returns an array") {
                
                it("should have a response dictionary with an array of results inside") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/array"), builder: json(arrayResponse))
                    
                    waitUntil { done in
                        let randomService = ServiceLocator.service(forType: RandomService.self)
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
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/dictionary"), builder: json(dictionaryResponse))
                    
                    waitUntil { done in
                        let randomService = ServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "dictionary", success: { response in
                            expect(response).toNot(beNil())
                            done()
                        }, failure: { error, errorDetails in
                        })
                    }
                }
            }
            
            context("that returns a paginated dictionary") {
                it("should have a merged dictionary from all the requests") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/dictionary_next1"), builder: json(dictionaryNextResponse2))
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/dictionary_next2"), builder: json(dictionaryNextResponse3))
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/dictionary_next3"), builder: json(dictionaryNextResponse4))
                    
                    waitUntil { done in
                        let randomService = ServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "dictionary_next1", paginated:true, success: { response in
                            expect(response["results"]).toNot(beNil())
                            let results = response["results"] as! [[String:Any]]
                            expect(results.count).to(equal(3))
                            done()
                        }, failure: { error, errorDetails in
                        })
                    }
                }
            }
            
            context("that returns an empty response") {
                it("should have a empty dictionary") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/empty_dictionary"), builder: json([String : Any]()))
                    
                    waitUntil { done in
                        let randomService = ServiceLocator.service(forType: RandomService.self)
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
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/error500"), builder: http(500))
                    
                    waitUntil { done in
                        let randomService = ServiceLocator.service(forType: RandomService.self)
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
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/error500"), builder: http(404))
                    
                    waitUntil { done in
                        let randomService = ServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "error500", success: { response in
                        }, failure: { error, errorDetails in
                            expect(error.responseCode).to(equal(404))
                            switch error {
                            case .responseValidationFailed(let reason):
                                switch reason {
                                case .badRequest(let error):
                                    expect((error as NSError).code).to(equal(404))
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
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/error500"), builder: http(401))
                    
                    waitUntil { done in
                        let randomService = ServiceLocator.service(forType: RandomService.self)
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
            
            context("that is force cached") {
                it("should correctly store and return the cached request if the cache is valid") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/dictionary"), builder: json(dictionaryResponse))
                    
                    waitUntil { done in
                        let randomService = ServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "dictionary", cachePolicy:CacheResponsePolicy(type: .forceCache, maxAge: 2),
                                               success: { response in
                            expect(response).toNot(beNil())
                            let originalRequest = URLRequest(url: URL(string: "https://random.com/v3/dictionary")!)
                            let cachedResponse = originalRequest.cachedJSONResponse()
                            expect(cachedResponse).toNot(beNil())
                                                
                            //Since we are cache now, the stubs should not be needed
                            MockingjayProtocol.removeAllStubs()
                            randomService?.request(path: "dictionary", cachePolicy:CacheResponsePolicy(type: .forceCache, maxAge: 2),
                                                   success: { response in
                                expect(response).toNot(beNil())
                                done()
                            }, failure: { error, errorDetails in
                            })
                        }, failure: { error, errorDetails in
                        })
                    }
                }
                
                it("should fail if the cache has been invalidated") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/dictionary"), builder: json(dictionaryResponse))
                    
                    waitUntil(timeout:6) { done in
                        let randomService = ServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "dictionary", cachePolicy:CacheResponsePolicy(type: .forceCache, maxAge: 2),
                                               success: { response in
                                                expect(response).toNot(beNil())
                                                let originalRequest = URLRequest(url: URL(string: "https://random.com/v3/dictionary")!)
                                                let cachedResponse = originalRequest.cachedJSONResponse()
                                                expect(cachedResponse).toNot(beNil())
                                                
                                                //Since we are cache now, the stubs should not be needed
                                                MockingjayProtocol.removeAllStubs()
                                                // Now let's wait for the cache to get invalidated
                                                sleep(3)
                                                randomService?.request(path: "dictionary", cachePolicy:CacheResponsePolicy(type: .forceCache, maxAge: 2),
                                                                       success: { response in
                                                }, failure: { error, errorDetails in
                                                    //the request to network fails since there is no stub and no cache
                                                    done()
                                                })
                        }, failure: { error, errorDetails in
                        })
                    }
                }
                
                it("should correctly return cached responses from paginated requests") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/dictionary_next1"), builder: json(dictionaryNextResponse2))
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/dictionary_next2"), builder: json(dictionaryNextResponse3))
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/v3/dictionary_next3"), builder: json(dictionaryNextResponse4))
                    
                    waitUntil { done in
                        let randomService = ServiceLocator.service(forType: RandomService.self)
                        randomService?.request(path: "dictionary_next1",
                                               paginated:true,
                                               cachePolicy:CacheResponsePolicy(type: .forceCache, maxAge: 2),
                                               success: { response in
                            expect(response["results"]).toNot(beNil())
                            let results = response["results"] as! [[String:Any]]
                            expect(results.count).to(equal(3))
                                                
                            let originalRequest1 = URLRequest(url: URL(string: "https://random.com/v3/dictionary_next1")!)
                            expect(originalRequest1.cachedJSONResponse()).toNot(beNil())
                            let originalRequest2 = URLRequest(url: URL(string: "https://random.com/v3/dictionary_next2")!)
                            expect(originalRequest2.cachedJSONResponse()).toNot(beNil())
                            let originalRequest3 = URLRequest(url: URL(string: "https://random.com/v3/dictionary_next3")!)
                            expect(originalRequest3.cachedJSONResponse()).toNot(beNil())
                                                
                            //Since we are cache now, the stubs should not be needed
                            MockingjayProtocol.removeAllStubs()
                                                
                            //paginated request should work through cache
                            randomService?.request(path: "dictionary_next1",
                                                   paginated:true,
                                                   cachePolicy:CacheResponsePolicy(type: .forceCache, maxAge: 2),
                                                   success: { response in
                                expect(response["results"]).toNot(beNil())
                                let results = response["results"] as! [[String:Any]]
                                expect(results.count).to(equal(3))
                                done()
                            }, failure: { error, errorDetails in
                            })
                        }, failure: { error, errorDetails in
                        })
                    }

                }
            }
        }
    }
}
