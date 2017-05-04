//
//  AuthenticationService.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation
import CryptoSwift

/// Response for de/authenticating users
@objc
open class AuthenticationService : AbstractBaseService
{
    
    /// Authenticates a user with an existing email and password, 
    /// if successful this service automatically persist all token information
    ///
    /// - Parameters:
    ///   - email: user's email
    ///   - password: user's password
    ///   - completion: a completion block indicating if the authentication was succesful
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
        }, failure: { error, errorResponse in
            completion(false)
        })
    }
    
    
    /// Logout the existing user, we will try to use any stored user tokens,
    /// if succesful all token data will get automatically clear, service locator will get reset also
    ///
    /// - Parameter completion: a completion block indicating if the logout was successful
    public func logoutExistingUser(completion:@escaping (_ completed:Bool)-> Void)
    {
        guard self.isAuthenticated else {
            completion(false)
            return
        }
        
        let parameters:[String: Any] = ["device_identifier" : UIDevice.current.identifierForVendor?.uuidString ?? ""]
        request(path: "logout",
                method: .post,
                with: parameters,
                success: { response in
                    APITokenManager.clearAuthentication()
                    ServiceLocator.reloadExistingServices()
                    completion(true)
        }, failure: { error, errorResponse in
            completion(false)
        })
    }
    
    
    /// Does a logout call with a custom access token(authentication) on the headers
    /// if succesful all token data will get automatically clear, service locator will get reset also
    /// - Parameters:
    ///   - token: authentication token
    ///   - completion: a completion block indicating if the logout was successful
    public func logoutUser(withAcessToken token:String, completion:@escaping (_ completed:Bool)-> Void)
    {
        guard self.isAuthenticated else {
            completion(false)
            return
        }
        
        let parameters:[String: Any] = ["device_identifier" : UIDevice.current.identifierForVendor?.uuidString ?? ""]
        request(path: "logout",
                method: .post,
                with: parameters,
                paginated: false,
                headers: ["Authorization" : "Bearer " + token],
                success: { response in
                    APITokenManager.clearAuthentication()
                    ServiceLocator.reloadExistingServices()
                    completion(true)
        }, failure: { error, errorResponse in
            completion(false)
        })
    }
    
    /// Does a logout call with a custom access token(authentication) on the headers for the given email
    /// if succesful all token data will get automatically clear, service locator will get reset also
    /// - Parameters:
    ///   - token: authentication token
    ///   - completion: a completion block indicating if the logout was successful
    public func logoutUser(withEmail email:String, completion:@escaping (_ completed:Bool)-> Void)
    {
        if let token = APITokenManager.accessToken(for: email) {
            self.logoutUser(withAcessToken: token, completion: completion)
        } else {
            completion(false)
        }
        
    }
}
