//
//  AuthenticationService.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 2/27/17.
//
//

import Foundation
import CryptoSwift

open class AuthenticationService : AstractBaseService
{
    public func authenticate(email:String,
                      password:String,
                      completion:@escaping (_ authenticated:Bool)-> Void)
    {
        let timestampString = String(Int(Date().timeIntervalSince1970))
        let combineString = "\(currentConfiguration.APISecret)%\(timestampString)%\(email.lowercased())"
        let signature = combineString.md5().lowercased()
        let parameters = ["username": email,
                          "password" : password,
                          "grant_type" : "password",
                          "oauth": [
                            "client_id" : currentConfiguration.APIKey,
                            "timestamp" : timestampString,
                            "signature" : signature]
            ] as [String : Any]
        
        request(path: "authenticate",
                method: .post,
                with: parameters,
                success: { response in
                    let token = APITokenManager.store(tokenInfo: response, for: email)
                    completion(token != nil)
        }, failure: { error in
            completion(false)
        })
    }
}
