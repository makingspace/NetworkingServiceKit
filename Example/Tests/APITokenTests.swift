//
//  APITokenTests.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot on 4/4/17.
//  Copyright © 2017 Makespace Inc. All rights reserved.
//

import Quick
import Nimble
import NetworkingServiceKit

class APITokenTests: QuickSpec {
    
    
    override func spec() {
        beforeEach {
            ServiceLocator.defaultNetworkClientType = StubNetworkManager.self
            UserDefaults.clearServiceLocatorUserDefaults()
            ServiceLocator.reset()
        }
        
        describe("when setting up access token information") {
            let userEmail = "email1@email.com"
            context("if we have an access token") {
                
                it("should return the appropiate information for the given email") {
                    let dataResponse = ["refresh_token" : "DWALI",
                                        "token_type" : "access",
                                        "access_token" : "KWALI",
                                        "expires_in" : 100,
                                        "scope" : "mobile"] as [String : Any]
                    APITokenManager.tokenType = TwitterAPIToken.self
                    let apiToken = APITokenManager.store(tokenInfo: dataResponse, for: userEmail)
                    expect(apiToken).toNot(beNil())
                    
                    let accessToken = TwitterAPIToken.object(for: TwitterAPITokenKey.accessTokenKey) as! String
                    expect(accessToken).to(equal("KWALI"))
                    
                    let tokenType = TwitterAPIToken.object(for: TwitterAPITokenKey.tokenTypeKey) as! String
                    expect(tokenType).to(equal("access"))
                }
                it("should be valid token on a loaded service") {
                    
                    let dataResponse = ["refresh_token" : "DWALI",
                                        "token_type" : "access",
                                        "access_token" : "KWALI",
                                        "expires_in" : 100,
                                        "scope" : "mobile"] as [String : Any]
                    APITokenManager.tokenType = TwitterAPIToken.self
                    let apiToken = APITokenManager.store(tokenInfo: dataResponse, for: userEmail)
                    expect(apiToken).toNot(beNil())
                    
                    ServiceLocator.set(services: [TwitterSearchService.self],
                                       api: TwitterAPIConfigurationType.self,
                                       auth: TwitterApp.self,
                                       token: TwitterAPIToken.self)
                    let searchService = ServiceLocator.service(forType: TwitterSearchService.self)
                    expect(searchService).toNot(beNil())
                    expect(searchService!.isAuthenticated).to(beTrue())
                }
            }
            
            context("if we have clear the token info") {
                it("should not be authenticated") {
                    let dataResponse = ["refresh_token" : "DWALI",
                                        "token_type" : "access",
                                        "access_token" : "KWALI",
                                        "expires_in" : 100,
                                        "scope" : "mobile"] as [String : Any]
                    APITokenManager.tokenType = TwitterAPIToken.self
                    let apiToken = APITokenManager.store(tokenInfo: dataResponse, for: userEmail)
                    expect(apiToken).toNot(beNil())
                    APITokenManager.clearAuthentication()
                    
                    let accessToken = TwitterAPIToken.object(for: TwitterAPITokenKey.accessTokenKey)
                    expect(accessToken).to(beNil())
                    
                    let tokenType = TwitterAPIToken.object(for: TwitterAPITokenKey.tokenTypeKey)
                    expect(tokenType).to(beNil())
                }
            }
        }
    }
}
