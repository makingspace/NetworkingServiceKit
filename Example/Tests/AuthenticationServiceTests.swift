//
//  AuthenticationServiceTests.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot on 4/5/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import NetworkingServiceKit
import Mockingjay

class AuthenticationServiceTests: QuickSpec, ServiceLocatorDelegate {
    
    var delegateGot401 = false
    override func spec() {
        
        let dataResponse = ["refresh_token" : "DWALI",
                            "token_type" : "access",
                            "access_token" : "KWALI",
                            "expires_in" : 100,
                            "scope" : "mobile"] as [String : Any]
        
        beforeEach {
            self.delegateGot401 = false
            APITokenManager.clearAuthentication()
            ServiceLocator.reset()
            ServiceLocator.loadDefaultServices()
        }
        
        describe("when a user is authenticating through our Authenticate service") {
            context("and the credentials are correct") {
                
                it("should be authenticated") {
                    MockingjayProtocol.addStub(matcher: http(.post, uri: "/api/v3/authenticate"), builder: json(dataResponse))
                    
                    waitUntil { done in
                        let authenticationService = ServiceLocator.service(forType: AuthenticationService.self)
                        authenticationService?.authenticate(email: "email@email.com", password: "password", completion: { authenticated in
                            expect(authenticated).to(beTrue())
                            done()
                        })
                    }
                }
            }
        }
        
        describe("when a user is authenticating through our Authenticate service") {
            context("and the credentials are incorrect") {
                
                it("should NOT be authenticated") {
                    MockingjayProtocol.addStub(matcher: http(.post, uri: "/api/v3/authenticate"), builder: http(404))
                    
                    waitUntil { done in
                        let authenticationService = ServiceLocator.service(forType: AuthenticationService.self)
                        authenticationService?.authenticate(email: "email@email.com", password: "password", completion: { authenticated in
                            expect(authenticated).to(beFalse())
                            done()
                        })
                    }
                }
            }
        }
        
        describe("when a user with an email is already authenticated") {
            context("and is trying to logout") {
                it("should clear token data") {
                    let token = APITokenManager.store(tokenInfo: dataResponse, for: "email@email.com")
                    expect(token).toNot(beNil())
                    //add token info to each service
                    ServiceLocator.reloadExistingServices()
                    
                    MockingjayProtocol.addStub(matcher: http(.post, uri: "/api/v3/logout"), builder: json([:]))
                    
                    waitUntil { done in
                        let authenticationService = ServiceLocator.service(forType: AuthenticationService.self)
                        authenticationService?.logoutUser(withEmail: "email@email.com", completion: { loggedOut in
                            expect(loggedOut).to(beTrue())
                            done()
                        })
                    }
                }
            }
        }
        
        describe("when the current user is already authenticated") {
            context("and is trying to logout") {
                it("should clear token data") {
                    let token = APITokenManager.store(tokenInfo: dataResponse, for: "email@email.com")
                    expect(token).toNot(beNil())
                    //add token info to each service
                    ServiceLocator.reloadExistingServices()
                    
                    MockingjayProtocol.addStub(matcher: http(.post, uri: "/api/v3/logout"), builder: json([:]))
                    
                    waitUntil { done in
                        let authenticationService = ServiceLocator.service(forType: AuthenticationService.self)
                        authenticationService?.logoutExistingUser(completion: { loggedOut in
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
                        authenticationService?.logoutExistingUser(completion: { loggedOut in
                            expect(loggedOut).to(beFalse())
                            done()
                        })
                    }
                }
            }
        }
        
        describe("when a user with an email is already authenticated but the token has expired") {
            context("and is trying to logout") {
                it("should report to the delegate there is a token expired") {
                    let token = APITokenManager.store(tokenInfo: dataResponse, for: "email@email.com")
                    expect(token).toNot(beNil())
                    //add token info to each service
                    ServiceLocator.reloadExistingServices()
                    MockingjayProtocol.addStub(matcher: http(.post, uri: "/api/v3/logout"), builder: http(401))
                    
                    //set ourselves as delegate
                    ServiceLocator.setDelegate(delegate: self)
                    waitUntil { done in
                        let authenticationService = ServiceLocator.service(forType: AuthenticationService.self)
                        authenticationService?.logoutUser(withEmail: "email@email.com", completion: { loggedOut in
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
