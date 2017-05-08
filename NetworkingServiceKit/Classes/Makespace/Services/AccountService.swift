//
//  AccountService.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 3/7/17.
//
//

import UIKit

@objc
open class AccountService: AbstractBaseService {
    
    open override var serviceVersion: String {
        return "v3"
    }
    
    /// Check if a user's email exist
    ///
    /// - Parameters:
    ///   - email: email to checkup
    ///   - completion: true if the email was found
    public func lookupUser(with email:String,
                    completion:@escaping (_ emailFound:Bool)-> Void) {
        let params = [
            "email" : email
        ]
        request(path: "account", method: .get, with: params, success: { response in
            completion(response.count > 0 ? true : false)
        }, failure: { error, errorResponse in
            completion(false)
        })
        
    }
}
