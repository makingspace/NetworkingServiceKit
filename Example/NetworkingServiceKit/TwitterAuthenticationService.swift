//
//  TwitterAuthenticationService.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation
import NetworkingServiceKit

/// Response for de/authenticating users
@objc
open class TwitterAuthenticationService: AbstractBaseService {

    /// Authenticates a user with an existing email and password, 
    /// if successful this service automatically persist all token information
    ///
    /// - Parameters:
    ///   - email: user's email
    ///   - password: user's password
    ///   - completion: a completion block indicating if the authentication was succesful
    public func authenticateTwitterClient(completion:@escaping (_ authenticated: Bool) -> Void) {
        if let encodedKey = currentConfiguration.APIKey.addingPercentEncoding(withAllowedCharacters:.urlHostAllowed),
            let encodedSecret = currentConfiguration.APISecret.addingPercentEncoding(withAllowedCharacters:.urlHostAllowed) {
            let combinedAuth = "\(encodedKey):\(encodedSecret)"
            let base64Auth = Data(combinedAuth.utf8).base64EncodedString()
            let body = "grant_type=client_credentials"
            request(path: "oauth2/token",
                    method: .post,
                    with: body.asParameters(),
                    headers: ["Authorization": "Basic " + base64Auth],
                    success: { response in
                        let token = APITokenManager.store(tokenInfo: response)
                        completion(token != nil)
            }, failure: { _ in
                completion(false)
            })
        } else {
            completion(false)
        }
    }

    /// Logout the existing token
    /// if succesful all token data will get automatically clear, service locator will get reset also
    ///
    /// - Parameter completion: a completion block indicating if the logout was successful
    public func logoutTwitterClient(completion:@escaping (_ authenticated: Bool) -> Void) {

        request(path: "oauth2/invalidate_token",
                method: .post,
                with: [:],
                success: { _ in
                    APITokenManager.clearAuthentication()
                    ServiceLocator.reloadExistingServices()
                    completion(true)
        }, failure: { _ in
            completion(false)
        })
    }
}
