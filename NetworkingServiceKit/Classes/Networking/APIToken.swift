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
    case customURLKey = "MSCustomURLKey"
    var responseKey: String {
        switch self {
            case .refreshTokenKey: return "refresh_token"
            case .tokenTypeKey: return "token_type"
            case .accessTokenKey: return "access_token"
            case .expiresKey: return "expires_in"
            case .scopeKey: return "scope"
            case .emailKey: return "email"
            case .deviceTokenKey: return "device_identifier"
            case .customURLKey: return "custom_url"
        }
    }
}

@objc
public class APIToken : NSObject
{
    var refreshToken:String
    var tokenType:String
    var accessToken:String
    var expiresIn:Int
    var scope:String
    var email:String
    
    public init(refreshToken: String,
                tokenType: String,
                accessToken: String,
                expiresIn: Int,
                scope: String,
                email: String) {
        
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.scope = scope
        self.email = email
    }
}

@objc
open class APITokenManager : NSObject
{
    public static var currentToken:APIToken? {
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
    
    public static func store(tokenInfo:[String:Any], for email:String) -> APIToken?
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
            
            //save tokens for specific email key (helps differntiate between multiple signed accounts)
            UserDefaults.standard.set(accessToken, forKey: APITokenManager.accessTokenKey(for: email))
            UserDefaults.standard.set(refreshToken, forKey: APITokenManager.refreshTokenKey(for: email))
            return self.currentToken
        }
        return nil
    }
    
    public static func object(for key:APITokenKey) -> Any?
    {
        return UserDefaults.standard.object(forKey: key.rawValue)
    }
    
    public static func set(object obj:Any?, for key:APITokenKey)
    {
        UserDefaults.standard.set(obj, forKey: key.rawValue)
    }
    
    public static func clearAuthentication()
    {
        if let email = self.object(for: .emailKey) as? String {
            //clear specific tokens for current email
            UserDefaults.standard.set(nil, forKey: APITokenManager.accessTokenKey(for: email))
            UserDefaults.standard.set(nil, forKey: APITokenManager.refreshTokenKey(for: email))
        }
        
        self.set(object: nil, for: .emailKey)
        self.set(object: nil, for: .refreshTokenKey)
        self.set(object: nil, for: .tokenTypeKey)
        self.set(object: nil, for: .accessTokenKey)
        self.set(object: nil, for: .expiresKey)
        self.set(object: nil, for: .scopeKey)
        self.set(object: nil, for: .scopeKey)
    }
    
    public static func setCurrentToken(for email:String) {
        UserDefaults.standard.set(accessToken, forKey: APITokenManager.accessTokenKey(for: email))
    }
    
    public static func accessToken(for email:String) -> String? {
        return UserDefaults.standard.object(forKey: self.accessTokenKey(for: email)) as? String
    }
    
    public static func refreshToken(for email:String) -> String? {
        return UserDefaults.standard.object(forKey: self.refreshTokenKey(for: email)) as? String
    }
    
    private static func accessTokenKey(for email:String) -> String {
        let bundleExecutable = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String ?? "com.makespace"
        return "\(email)@com.makespace.\(bundleExecutable).access"
    }
    private static func refreshTokenKey(for email:String) -> String {
        let bundleExecutable = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String ?? "com.makespace"
        return "\(email)@com.makespace.\(bundleExecutable).refresh"
    }
}
