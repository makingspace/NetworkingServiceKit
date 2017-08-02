//
//  TwitterSearchServiceTests.swift
//  MakespaceServiceKit
//
//  Created by Phillipe Casorla Sagot on 4/25/17.
//  Copyright © 2017 Makespace Inc. All rights reserved.
//

import Quick
import Nimble
import NetworkingServiceKit
import Mockingjay

class TwitterSearchServiceTestsStubbed: QuickSpec {
    
    var searchService:TwitterSearchService?
    override func spec() {
        
        let searchStub = ServiceStub(execute: ServiceStubRequest(path: "/1.1/search/tweets.json", parameters: ["q" : "#makespace"]),
                                     with: .success(code: 200, response: ["statuses" : [["text" : "tweet1" ,
                                                                                         "user" : ["screen_name" : "darkzlave",
                                                                                                   "profile_image_url_https" : "https://lol.png",
                                                                                                   "location" : "Stockholm, Sweden"]],
                                                                                        ["text" : "tweet2" ,
                                                                                         "user" : ["screen_name" : "makespace",
                                                                                                   "profile_image_url_https" : "https://lol2.png",
                                                                                                   "location" : "New York"]]],
                                                                          "search_metadata" : ["next_results" : "https://search.com/next?pageId=2"]
                                        ]), when: .unauthenticated,
                                            react:.delayed(seconds: 0.5))
        let searchStubFromJSON = ServiceStub(execute: ServiceStubRequest(path: "/1.1/search/tweets.json", parameters: ["q" : "#makespaceFromJSON"]),
                                             with: ServiceStubType(buildWith: "twitterSearch",http:200),
                                             when: .unauthenticated,
                                             react:.delayed(seconds: 0.5))
        let searchEmptyStub = ServiceStub(execute: ServiceStubRequest(path: "/1.1/search/tweets.json", parameters: ["q" : ""]),
                                          with: .success(code: 200, response: [:]),
                                          when: .unauthenticated,
                                          react:.immediate)
        let searchFail = ServiceStub(execute: ServiceStubRequest(path: "/1.1/search/tweets.json", parameters: ["q" : "#random"]),
                                                    with: .failure(code:500, response:[:]),
                                                    when: .unauthenticated,
                                                    react:.immediate)

        beforeEach {
            ServiceLocator.defaultNetworkClientType = StubNetworkManager.self
            ServiceLocator.reset()
            ServiceLocator.set(services: [TwitterSearchService.self],
                               api: TwitterAPIConfigurationType.self,
                               auth: TwitterApp.self,
                               token: TwitterAPIToken.self)
            self.searchService = ServiceLocator.service(forType: TwitterSearchService.self, stubs: [searchStub,searchEmptyStub,searchFail,searchStubFromJSON])
        }
        describe("when doing a search request") {
            context("with a proper query") {
                it("should correctly parse and return the search results as objects") {
                    waitUntil { done in
                        self.searchService?.searchRecents(by: "#makespace", completion: { results in
                            expect(results.count).to(equal(2))
                            let resultFirst = results.first
                            expect(resultFirst).toNot(beNil())
                            expect(resultFirst?.tweet).to(equal("tweet1"))
                            expect(resultFirst?.user.handle).to(equal("darkzlave"))
                            expect(resultFirst?.user.imagePath).to(equal("https://lol.png"))
                            done()
                        })
                    }
                }
            }
            
            
            context("with an empty query") {
                it("should return immediatly with no results") {
                    self.searchService?.searchRecents(by: "", completion: { results in
                        expect(results.count).to(equal(0))
                    })
                }
            }
        }
        
        describe("when doing a failed search request") {
            context("with a proper query") {
                it("should return no results") {
                    self.searchService?.searchRecents(by: "#random", completion: { results in
                        expect(results.count).to(equal(0))
                    })
                }
            }
        }
        
        describe("when doing a search request through a JSON response") {
            context("with a proper query") {
                it("should correctly parse and return the search results as objects") {
                    waitUntil { done in
                        self.searchService?.searchRecents(by: "#makespaceFromJSON", completion: { results in
                            expect(results.count).to(equal(3))
                            let resultFirst = results.first
                            expect(resultFirst).toNot(beNil())
                            expect(resultFirst?.tweet).to(equal("tweet1"))
                            expect(resultFirst?.user.handle).to(equal("darkzlave"))
                            expect(resultFirst?.user.imagePath).to(equal("https://lol.png"))
                            done()
                        })
                    }
                }
            }

        }
    }
}

class TwitterSearchServiceTestsAlamo: QuickSpec {
    override func spec() {
        
        beforeEach {
            ServiceLocator.defaultNetworkClientType = AlamoNetworkManager.self
            ServiceLocator.reset()
            ServiceLocator.set(services: [TwitterSearchService.self],
                               api: TwitterAPIConfigurationType.self,
                               auth: TwitterApp.self,
                               token: TwitterAPIToken.self)
        }
        
        describe("when doing a search request") {
            context("with a next page available") {
                it("should correctly parse and return the search results as objects") {
                    let searchResponse = ["statuses" : [["text" : "tweet1" ,
                                                         "user" : ["screen_name" : "darkzlave",
                                                                   "profile_image_url_https" : "https://lol.png",
                                                                   "location" : "Stockholm, Sweden"]],
                                                        ["text" : "tweet2" ,
                                                         "user" : ["screen_name" : "makespace",
                                                                   "profile_image_url_https" : "https://lol2.png",
                                                                   "location" : "New York"]]],
                                          "search_metadata" : ["next_results" : "?id=2"]
                        ] as [String : Any]
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/1.1/search/tweets.json"), builder: json(searchResponse))
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/1.1/search/tweets.json?id=2"), builder: json(searchResponse))

                    waitUntil { done in
                        let searchService = ServiceLocator.service(forType: TwitterSearchService.self)
                        searchService?.searchRecents(by: "#makespace", completion: { results in
                            searchService?.searchNextRecentsPageProducer().on(value: { results in
                                expect(results.count).to(equal(2))
                                let resultFirst = results.first
                                expect(resultFirst).toNot(beNil())
                                expect(resultFirst?.tweet).to(equal("tweet1"))
                                expect(resultFirst?.user.handle).to(equal("darkzlave"))
                                expect(resultFirst?.user.imagePath).to(equal("https://lol.png"))
                                done()
                            }).start()
                        })
                    }
                }
            }
            
            context("with a next page NON available") {
                it("return empty results") {
                    let searchService = ServiceLocator.service(forType: TwitterSearchService.self)
                    searchService?.searchNextRecentsPageProducer().on(value: { results in
                        expect(results.count).to(equal(0))
                    }).start()
                }
            }
        }
    }
}
