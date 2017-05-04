//
//  AccountServiceTests.swift
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

class AccountServiceTests: QuickSpec
{
    override func spec() {
        
        beforeEach {
            ServiceLocator.load(withServices: [AccountService.self])
        }
        
        describe("when looking up for a user given an email") {
            context("and the user exists"){
                it("should return it found a user") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/api/v3/account"), builder: json(["email" : "email@email.com"]))
                    
                    waitUntil { done in
                        let accountService = ServiceLocator.service(forType: AccountService.self)
                        accountService?.lookupUser(with: "email@email.com", completion: { foundUser in
                            expect(foundUser).to(beTrue())
                            done()
                        })
                    }
                }
            }
            context("and the user does not exists"){
                it("should return it didnt found a user") {
                    MockingjayProtocol.addStub(matcher: http(.get, uri: "/api/v3/account"), builder: http(200))
                    
                    waitUntil { done in
                        let accountService = ServiceLocator.service(forType: AccountService.self)
                        accountService?.lookupUser(with: "email@email.com", completion: { foundUser in
                            expect(foundUser).to(beFalse())
                            done()
                        })
                    }
                }
            }
        }
    }
}
