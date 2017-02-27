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
    func authenticate(email:String,
                      password:String,
                      completion:@escaping (_ authenticated:Bool)-> Void)
    {
        let timestamp = Date().timeIntervalSince1970
        let timestampString = String(timestamp)
        let combineString = "\(currentConfiguration.APISecret)%%\(timestampString)%%\(email.lowercased())"
        let signature = combineString.md5().lowercased()
        let parameters = ["password" : password,
                      "grant_type" : "password",
                      "oauth": [
                        "client_id" : currentConfiguration.APIKey,
                        "timestamp" : timestamp,
                        "signature" : signature]
        ] as [String : Any]
        networkManager.request(path: "authenticate",
                               method: .post,
                               with: parameters,
                               success: { response in
                                let token = APITokenManager.store(tokenInfo: parameters, for: email)
                                completion(token != nil)
        }, failure: { error in
            completion(false)
        })
    }
}
