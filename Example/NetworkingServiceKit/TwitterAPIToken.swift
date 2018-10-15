//
//  TwitterAPIToken.swift
//  NetworkingServiceKit
//
//  Created by Phillipe Casorla Sagot on 5/5/17.
//  Copyright © 2017 Makespace Inc. All rights reserved.
//

import Foundation
import NetworkingServiceKit

//Custom Keys for Twitter Auth Response
public enum TwitterAPITokenKey: String {
    case tokenTypeKey = "Token_CurrentTokenTypeKey"
    case accessTokenKey = "Token_CurrentAccessTokenKey"
    var responseKey: String {
        switch self {
        case .tokenTypeKey: return "token_type"
        case .accessTokenKey: return "access_token"
        }
    }
}

/// Twitter API Token Object used for authenticating requests
public class TwitterAPIToken: NSObject, APIToken {
    var tokenType: String
    var accessToken: String

    public init(tokenType: String,
                accessToken: String) {

        self.tokenType = tokenType
        self.accessToken = accessToken
    }

    public var authorization: String {
        return self.accessToken
    }
    
    public static func make(from tokenResponse: Any) -> APIToken? {
        if let tokenResponse = tokenResponse as? [String: Any],
            let tokenType = tokenResponse[TwitterAPITokenKey.tokenTypeKey.responseKey] as? String,
            let accessToken = tokenResponse[TwitterAPITokenKey.accessTokenKey.responseKey] as? String {
            let token = TwitterAPIToken(tokenType: tokenType, accessToken: accessToken)
            self.set(object: tokenType, for: .tokenTypeKey)
            self.set(object: accessToken, for: .accessTokenKey)
            return token
        }
        return nil
    }

    public static func makePersistedToken() -> APIToken? {
        if let tokenType = self.object(for: .tokenTypeKey) as? String,
            let accessToken = self.object(for: .accessTokenKey) as? String {
            let token = TwitterAPIToken(tokenType: tokenType, accessToken: accessToken)
            return token
        }
        return nil
    }

    public static func clearToken() {
        self.set(object: nil, for: .tokenTypeKey)
        self.set(object: nil, for: .accessTokenKey)
    }

    public static func object(for key: TwitterAPITokenKey) -> Any? {
        return UserDefaults.serviceLocator?.object(forKey: key.rawValue)
    }

    public static func set(object obj:Any?, for key: TwitterAPITokenKey) {
        UserDefaults.serviceLocator?.set(obj, forKey: key.rawValue)
    }
}
