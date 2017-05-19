//
//  MakespaceAPIToken.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 5/5/17.
//
//

import Foundation

//Custom Keys for Makespace Auth Response
public enum MakespaceAPITokenKey: String {
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

/// Implements Makespace token handling
@objc
public class MakespaceAPIToken: NSObject, APIToken {
    var refreshToken: String
    var tokenType: String
    var accessToken: String
    var expiresIn: Int
    var scope: String
    var email: String

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

    public var authorization: String {
        return self.accessToken
    }

    public static func make(from tokenResponse: [String:Any], email: String?) -> APIToken? {
        if let refreshToken = tokenResponse[MakespaceAPITokenKey.refreshTokenKey.responseKey] as? String,
            let tokenType = tokenResponse[MakespaceAPITokenKey.tokenTypeKey.responseKey] as? String,
            let accessToken = tokenResponse[MakespaceAPITokenKey.accessTokenKey.responseKey] as? String,
            let expiresIn = tokenResponse[MakespaceAPITokenKey.expiresKey.responseKey] as? Int,
            let scope = tokenResponse[MakespaceAPITokenKey.scopeKey.responseKey] as? String,
            let email = email {
            let token = MakespaceAPIToken(refreshToken: refreshToken,
                                          tokenType: tokenType,
                                          accessToken: accessToken,
                                          expiresIn: expiresIn,
                                          scope: scope,
                                          email: email)

            self.set(object: email, for: .emailKey)
            self.set(object: refreshToken, for: .refreshTokenKey)
            self.set(object: tokenType, for: .tokenTypeKey)
            self.set(object: accessToken, for: .accessTokenKey)
            self.set(object: expiresIn, for: .expiresKey)
            self.set(object: scope, for: .scopeKey)

            //save tokens for specific email key (helps differntiate between multiple signed accounts)
            UserDefaults.standard.set(accessToken, forKey: MakespaceAPIToken.accessTokenKey(for: email))
            UserDefaults.standard.set(refreshToken, forKey: MakespaceAPIToken.refreshTokenKey(for: email))

            return token
        }
        return nil
    }

    public static func makePersistedToken() -> APIToken? {
        if let email = self.object(for: .emailKey) as? String,
            let refreshToken = self.object(for: .refreshTokenKey) as? String,
            let tokenType = self.object(for: .tokenTypeKey) as? String,
            let accessToken = self.object(for: .accessTokenKey) as? String,
            let expiresIn = self.object(for: .expiresKey) as? Int,
            let scope = self.object(for: .scopeKey) as? String {
            let token = MakespaceAPIToken(refreshToken: refreshToken,
                                          tokenType: tokenType,
                                          accessToken: accessToken,
                                          expiresIn: expiresIn,
                                          scope: scope,
                                          email: email)
            return token
        }
        return nil
    }

    public static func clearToken() {
        if let email = self.object(for: .emailKey) as? String {
            //clear specific tokens for current email
            UserDefaults.standard.set(nil, forKey: MakespaceAPIToken.accessTokenKey(for: email))
            UserDefaults.standard.set(nil, forKey: MakespaceAPIToken.refreshTokenKey(for: email))
        }

        self.set(object: nil, for: .emailKey)
        self.set(object: nil, for: .refreshTokenKey)
        self.set(object: nil, for: .tokenTypeKey)
        self.set(object: nil, for: .accessTokenKey)
        self.set(object: nil, for: .expiresKey)
        self.set(object: nil, for: .scopeKey)
        self.set(object: nil, for: .scopeKey)
    }

    public static func object(for key: MakespaceAPITokenKey) -> Any? {
        return UserDefaults.standard.object(forKey: key.rawValue)
    }

    public static func set(object obj:Any?, for key: MakespaceAPITokenKey) {
        UserDefaults.standard.set(obj, forKey: key.rawValue)
    }

    public static func setCurrentToken(for email: String) {
        if let currentToken = self.object(for: .accessTokenKey) as? String {
            UserDefaults.standard.set(currentToken, forKey: MakespaceAPIToken.accessTokenKey(for: email))
        }
    }

    public static func accessToken(for email: String) -> String? {
        return UserDefaults.standard.object(forKey: self.accessTokenKey(for: email)) as? String
    }

    public static func refreshToken(for email: String) -> String? {
        return UserDefaults.standard.object(forKey: self.refreshTokenKey(for: email)) as? String
    }

    private static func accessTokenKey(for email: String) -> String {
        let bundleExecutable = Bundle.main.bundleExecutableName
        return "\(email)@com.makespace.\(bundleExecutable).access"
    }
    private static func refreshTokenKey(for email: String) -> String {
        let bundleExecutable = Bundle.main.bundleExecutableName
        return "\(email)@com.makespace.\(bundleExecutable).refresh"
    }
}
