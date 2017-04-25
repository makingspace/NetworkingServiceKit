//
//  APITokenTests.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/4/17.
//  Copyright © 2017 Makespace Inc. All rights reserved.
//

import Quick
import Nimble
import MakespaceServiceKit

class APITokenTests: QuickSpec {
        
    override func spec() {
        beforeEach {
            UserDefaults.clearServiceLocatorUserDefaults()
        }
        
        describe("when setting up access token information") {
            context("if we have an access token") {
                it("should return the appropiate information for the given email") {
                    let dataResponse = ["refresh_token" : "DWALI",
                               "token_type" : "access",
                               "access_token" : "KWALI",
                               "expires_in" : 100,
                               "scope" : "mobile"] as [String : Any]
                    let apiToken = APITokenManager.store(tokenInfo: dataResponse)
                    expect(apiToken).toNot(beNil())
                    
                    let tokenType = APITokenManager.object(for: .tokenTypeKey) as! String
                    expect(tokenType).to(equal("access"))
                    
                    let accessToken = APITokenManager.object(for: .accessTokenKey) as! String
                    expect(accessToken).to(equal("KWALI"))
                }
            }
            
            context("if we have clear the token info") {
                it("should find nil values for all keys") {
                    let dataResponse = ["refresh_token" : "DWALI",
                                        "token_type" : "access",
                                        "access_token" : "KWALI",
                                        "expires_in" : 100,
                                        "scope" : "mobile"] as [String : Any]
                    let apiToken = APITokenManager.store(tokenInfo: dataResponse)
                    expect(apiToken).toNot(beNil())
                    APITokenManager.clearAuthentication()
                    
                    let accessToken = APITokenManager.object(for: .accessTokenKey)
                    expect(accessToken).to(beNil())
                    
                    let tokenType = APITokenManager.object(for: .tokenTypeKey)
                    expect(tokenType).to(beNil())
                }
            }
        }
    }
}
