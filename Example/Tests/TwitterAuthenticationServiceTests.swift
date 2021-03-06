//
//  TwitterAuthenticationServiceTests.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/5/17.
//  Copyright © 2017 Makespace Inc. All rights reserved.
//

import Quick
import Nimble
import NetworkingServiceKit

class TwitterAuthenticationServiceTests: QuickSpec, ServiceLocatorDelegate {
    
    var delegateGot401 = false
    
    override func spec() {
        
        let authStub = ServiceStub(execute: ServiceStubRequest(path: "/oauth2/token"),
                                   with: .success(code: 200, response: ["token_type" : "access", "access_token" : "KWALI"]),
                                   when: .unauthenticated,
                                   react:.immediate)
        let logoutStub = ServiceStub(execute: ServiceStubRequest(path: "/oauth2/invalidate_token"),
                                     with: .success(code: 200, response: [:]),
                                     when: .unauthenticated,
                                     react:.immediate)
        let logoutStubUnauthenticated = ServiceStub(execute: ServiceStubRequest(path: "/oauth2/invalidate_token"),
                                                    with: .failure(code:401, response:[:]),
                                                    when: .unauthenticated,
                                                    react:.immediate)
        let logoutStubAuthenticated = ServiceStub(execute: ServiceStubRequest(path: "/oauth2/invalidate_token"),
                                                  with: .failure(code:401, response:[:]),
                                                  when: .authenticated(tokenInfo: ["token_type" : "access", "access_token" : "KWALI"]),
                                                  react:.immediate)
        
        beforeEach {
            ServiceLocator.defaultNetworkClientType = StubNetworkManager.self            
            self.delegateGot401 = false
            UserDefaults.clearServiceLocatorUserDefaults()
            APITokenManager.clearAuthentication()
            ServiceLocator.reset()
            ServiceLocator.set(services: [TwitterAuthenticationService.self],
                               api: TwitterAPIConfigurationType.self,
                               auth: TwitterApp.self,
                               token: TwitterAPIToken.self)
        }
        
        describe("when a user is authenticating through our Authenticate service") {
            context("and the credentials are correct") {
                
                it("should be authenticated") {
                    
                    let authenticationService = ServiceLocator.service(forType: TwitterAuthenticationService.self, stubs: [authStub])
                    authenticationService?.authenticateTwitterClient(completion: { authenticated in
                        expect(authenticated).to(beTrue())
                    })
                }
            }
        }
        
        describe("when the current user is already authenticated") {
            context("and is trying to logout") {
                it("should clear token data") {
                    let authenticationService = ServiceLocator.service(forType: TwitterAuthenticationService.self, stubs: [logoutStub])
                    authenticationService?.logoutTwitterClient(completion: { loggedOut in
                        expect(loggedOut).to(beTrue())
                    })
                }
            }
        }
        
        describe("when the current user is NOT authenticated") {
            context("and is trying to logout") {
                it("should not return succesfully") {
                    let authenticationService = ServiceLocator.service(forType: TwitterAuthenticationService.self, stubs: [logoutStubUnauthenticated])
                    authenticationService?.logoutTwitterClient(completion: { loggedOut in
                        expect(loggedOut).to(beFalse())
                    })
                }
            }
        }
        
        describe("when we are authenticated but the token has expired") {
            context("and is trying to logout") {
                it("should report to the delegate there is a token expired") {
                    
                    //set ourselves as delegate
                    ServiceLocator.setDelegate(delegate: self)
                    let authenticationService = ServiceLocator.service(forType: TwitterAuthenticationService.self, stubs: [logoutStubAuthenticated])
                    authenticationService?.logoutTwitterClient(completion: { loggedOut in
                        expect(loggedOut).to(beFalse())
                        expect(self.delegateGot401).to(beTrue())
                    })
                }
            }
        }
    }
    
    // MARK: ServiceLocatorDelegate
    func authenticationTokenDidExpire(forService service: Service) {
        self.delegateGot401 = true
    }
    
    func shouldInterceptRequest(with request: URLRequest) -> Bool {
        return false
    }
    
    func processIntercept(for request: NSMutableURLRequest) -> URLRequest? {
        return nil
    }
}
