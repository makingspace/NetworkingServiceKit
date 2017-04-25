//
//  APIToken.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation

//Custom Keys for Twitter Auth Response
public enum APITokenKey: String
{
    case tokenTypeKey = "Token_CurrentTokenTypeKey"
    case accessTokenKey = "Token_CurrentAccessTokenKey"
    var responseKey: String {
        switch self {
            case .tokenTypeKey: return "token_type"
            case .accessTokenKey: return "access_token"
        }
    }
}

/// API Token Object used for authenticating requests
@objc
public class APIToken : NSObject
{
    //define here more token info, for example refreshTokens or token permissions
    var tokenType:String
    var accessToken:String
    
    public init(tokenType: String,
                accessToken: String) {
        
        self.tokenType = tokenType
        self.accessToken = accessToken
    }
}

/// Handles the current APIToken and store upcoming tokens for new authentications
@objc
open class APITokenManager : NSObject
{
    
    /// Returns an existing auth token, nil if se havent authenticated yet
    public static var currentToken:APIToken? {
        if let tokenType = self.object(for: .tokenTypeKey) as? String,
            let accessToken = self.object(for: .accessTokenKey) as? String
            {
                let token = APIToken(tokenType: tokenType,
                                     accessToken: accessToken)
                return token
            }
        return nil
    }
    
    /// Stores auth information from a authentication request
    ///
    /// - Parameter tokenInfo: the authentication response
    /// - Returns: a new auth api token
    public static func store(tokenInfo:[String:Any]) -> APIToken?
    {
        if let tokenType = tokenInfo[APITokenKey.tokenTypeKey.responseKey] as? String,
            let accessToken = tokenInfo[APITokenKey.accessTokenKey.responseKey] as? String
        {
            
            self.set(object: tokenType, for: .tokenTypeKey)
            self.set(object: accessToken, for: .accessTokenKey)
            
            return self.currentToken
        }
        return nil
    }
    
    /// Retrieves token information for a specific token key
    ///
    /// - Parameter key: a specific token key
    /// - Returns: a value for the given token key
    public static func object(for key:APITokenKey) -> Any?
    {
        return UserDefaults.serviceLocator.object(forKey: key.rawValue)
    }
    
    /// Saves data for a specific token key
    ///
    /// - Parameters:
    ///   - obj: object to be saved
    ///   - key: a specific token key
    public static func set(object obj:Any?, for key:APITokenKey)
    {
        UserDefaults.serviceLocator.set(obj, forKey: key.rawValue)
    }
    
    /// Clears authentication - deletes data for all the token keys
    public static func clearAuthentication()
    {
        self.set(object: nil, for: .tokenTypeKey)
        self.set(object: nil, for: .accessTokenKey)
    }
}
