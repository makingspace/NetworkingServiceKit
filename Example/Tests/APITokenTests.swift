//
//  APITokenTests.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot on 4/4/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import NetworkingServiceKit


class APITokenTests: QuickSpec {
        
    override func spec() {
        
        describe("when setting up access token information") {
            let userEmail = "email1@email.com"
            context("if we have an access token") {
                it("should return the appropiate information for the given email") {
                    let dataResponse = ["refresh_token" : "DWALI",
                               "token_type" : "access",
                               "access_token" : "KWALI",
                               "expires_in" : 100,
                               "scope" : "mobile"] as [String : Any]
                    let apiToken = APITokenManager.store(tokenInfo: dataResponse, for: userEmail)
                    expect(apiToken).toNot(beNil())
                    
                    let accessToken = APITokenManager.accessToken(for: userEmail)
                    expect(accessToken).to(equal("KWALI"))
                    
                    let refreshToken = APITokenManager.refreshToken(for: userEmail)
                    expect(refreshToken).to(equal("DWALI"))
                }
            }
            
            context("if we have clear the token info") {
                let dataResponse = ["refresh_token" : "DWALI",
                                    "token_type" : "access",
                                    "access_token" : "KWALI",
                                    "expires_in" : 100,
                                    "scope" : "mobile"] as [String : Any]
                let apiToken = APITokenManager.store(tokenInfo: dataResponse, for: userEmail)
                expect(apiToken).toNot(beNil())
                APITokenManager.clearAuthentication()
                
                let accessToken = APITokenManager.accessToken(for: userEmail)
                expect(accessToken).to(beNil())
                
                let refreshToken = APITokenManager.refreshToken(for: userEmail)
                expect(refreshToken).to(beNil())
            }
        }
    }
}
