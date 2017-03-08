//
//  APIToken.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 2/27/17.
//
//

import Foundation

public enum APITokenKey: String
{
    case refreshTokenKey = "MSCurrentRefreshTokenKey"
    case tokenTypeKey = "MSCurrentTokenTypeKey"
    case accessTokenKey = "MSCurrentAccessTokenKey"
    case expiresKey = "MSCurrentExpiresInKey"
    case scopeKey = "MSCurrentScopeKey"
    case emailKey = "MSCurrentEmailKey"
    case deviceTokenKey = "MSDeviceToken"
    
    var responseKey: String {
        switch self {
            case .refreshTokenKey: return "refresh_token"
            case .tokenTypeKey: return "token_type"
            case .accessTokenKey: return "access_token"
            case .expiresKey: return "expires_in"
            case .scopeKey: return "scope"
            case .emailKey: return "email"
            case .deviceTokenKey: return "device_identifier"
        }
    }
}

public struct APIToken
{
    var refreshToken:String
    var tokenType:String
    var accessToken:String
    var expiresIn:Int
    var scope:String
    var email:String
}

open class APITokenManager
{
    static var currentToken:APIToken? {
        if let email = self.object(for: .emailKey) as? String,
            let refreshToken = self.object(for: .refreshTokenKey) as? String,
            let tokenType = self.object(for: .tokenTypeKey) as? String,
            let accessToken = self.object(for: .accessTokenKey) as? String,
            let expiresIn = self.object(for: .expiresKey) as? Int,
            let scope = self.object(for: .scopeKey) as? String
            {
                let token = APIToken(refreshToken: refreshToken,
                                     tokenType: tokenType,
                                     accessToken: accessToken,
                                     expiresIn: expiresIn,
                                     scope: scope,
                                     email: email)
                return token
            }
        return nil
    }
    
    static func store(tokenInfo:[String:Any], for email:String) -> APIToken?
    {
        if let refreshToken = tokenInfo[APITokenKey.refreshTokenKey.responseKey] as? String,
            let tokenType = tokenInfo[APITokenKey.tokenTypeKey.responseKey] as? String,
            let accessToken = tokenInfo[APITokenKey.accessTokenKey.responseKey] as? String,
            let expiresIn = tokenInfo[APITokenKey.expiresKey.responseKey] as? Int,
            let scope = tokenInfo[APITokenKey.scopeKey.responseKey] as? String {
            
            self.set(object: email, for: .emailKey)
            self.set(object: refreshToken, for: .refreshTokenKey)
            self.set(object: tokenType, for: .tokenTypeKey)
            self.set(object: accessToken, for: .accessTokenKey)
            self.set(object: expiresIn, for: .expiresKey)
            self.set(object: scope, for: .scopeKey)
            return self.currentToken
        }
        return nil
    }
    
    static func object(for key:APITokenKey) -> Any?
    {
        return UserDefaults.standard.object(forKey: key.rawValue)
    }
    
    static func set(object obj:Any?, for key:APITokenKey)
    {
        UserDefaults.standard.set(obj, forKey: key.rawValue)
    }
    
    static func clearAuthentication()
    {
        self.set(object: nil, for: .emailKey)
        self.set(object: nil, for: .refreshTokenKey)
        self.set(object: nil, for: .tokenTypeKey)
        self.set(object: nil, for: .accessTokenKey)
        self.set(object: nil, for: .expiresKey)
        self.set(object: nil, for: .scopeKey)
    }
    
    private static func accessTokeKey(for email:String) -> String {
        if let bundleExecutable = Bundle.main.infoDictionary?["CFBundleExecutable"] as? NSString {
            return "\(email)@com.makespace.\(bundleExecutable).access"
        }
        return email
    }
    private static func refreshTokeKey(for email:String) -> String {
        if let bundleExecutable = Bundle.main.infoDictionary?["CFBundleExecutable"] as? NSString {
            return "\(email)@com.makespace.\(bundleExecutable).access"
        }
        return email
    }
}
