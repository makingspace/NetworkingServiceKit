//
//  AuthenticationServiceTests.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/5/17.
//  Copyright © 2017 Makespace Inc. All rights reserved.
//

import Quick
import Nimble
import MakespaceServiceKit
import Mockingjay

class AuthenticationServiceTests: QuickSpec, ServiceLocatorDelegate {
    
    var delegateGot401 = false
    override func spec() {
        
        let dataResponse = ["token_type" : "access",
                            "access_token" : "KWALI",] as [String : Any]
        
        beforeEach {
            self.delegateGot401 = false
            UserDefaults.clearServiceLocatorUserDefaults()
            APITokenManager.clearAuthentication()
            ServiceLocator.reset()
            ServiceLocator.loadDefaultServices()
        }
        
        describe("when a user is authenticating through our Authenticate service") {
            context("and the credentials are correct") {
                
                it("should be authenticated") {
                    MockingjayProtocol.addStub(matcher: http(.post, uri: "/oauth2/token"), builder: json(dataResponse))
                    
                    waitUntil { done in
                        let authenticationService = ServiceLocator.service(forType: AuthenticationService.self)
                        authenticationService?.authenticateTwitterClient(completion: { authenticated in
                            expect(authenticated).to(beTrue())
                            done()
                        })
                    }
                }
            }
        }
        
        describe("when the current user is already authenticated") {
            context("and is trying to logout") {
                it("should clear token data") {
                    let token = APITokenManager.store(tokenInfo: dataResponse)
                    expect(token).toNot(beNil())
                    //add token info to each service
                    ServiceLocator.reloadExistingServices()
                    
                    MockingjayProtocol.addStub(matcher: http(.post, uri: "/oauth2/invalidate_token"), builder: json([:]))
                    
                    waitUntil { done in
                        let authenticationService = ServiceLocator.service(forType: AuthenticationService.self)
                        authenticationService?.logoutTwitterClient(completion: { loggedOut in
                            expect(loggedOut).to(beTrue())
                            done()
                        })
                    }
                }
            }
        }
        
        describe("when the current user is NOT authenticated") {
            context("and is trying to logout") {
                it("should not return succesfully") {
                    APITokenManager.clearAuthentication()
                    let token = APITokenManager.currentToken
                    expect(token).to(beNil())
                    
                    waitUntil { done in
                        let authenticationService = ServiceLocator.service(forType: AuthenticationService.self)
                        authenticationService?.logoutTwitterClient(completion: { loggedOut in
                            expect(loggedOut).to(beFalse())
                            done()
                        })
                    }
                }
            }
        }
        
        describe("when we are authenticated but the token has expired") {
            context("and is trying to logout") {
                it("should report to the delegate there is a token expired") {
                    let token = APITokenManager.store(tokenInfo: dataResponse)
                    expect(token).toNot(beNil())
                    //add token info to each service
                    ServiceLocator.reloadExistingServices()
                    MockingjayProtocol.addStub(matcher: http(.post, uri: "/oauth2/invalidate_token"), builder: http(401))
                    
                    //set ourselves as delegate
                    ServiceLocator.setDelegate(delegate: self)
                    waitUntil { done in
                        let authenticationService = ServiceLocator.service(forType: AuthenticationService.self)
                        authenticationService?.logoutTwitterClient(completion: { loggedOut in
                            expect(loggedOut).to(beFalse())
                            expect(self.delegateGot401).to(beTrue())
                            done()
                        })
                    }
                }
            }
        }
    }
    
    func networkLocatorTokenDidExpired() {
        self.delegateGot401 = true
    }
}
