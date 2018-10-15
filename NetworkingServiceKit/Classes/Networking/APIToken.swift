//
//  APIToken.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation

/// Protocol for describing token handling for our service locator
@objc
public protocol APIToken {
    var authorization: String { get }
    static func makePersistedToken() -> APIToken?
    static func make(from tokenResponse: Any) -> APIToken?
    static func clearToken()
}

/// Handles storing and clearing an existing APIToken implementation
@objc
open class APITokenManager: NSObject {
    @objc public static var tokenType: APIToken.Type?
    
    @objc public static var currentToken: APIToken? {
        if let tokenType = APITokenManager.tokenType {
            return tokenType.makePersistedToken()
        }
        return nil
    }
    
    public static var isAuthenticated:Bool {
        return APITokenManager.currentToken != nil
    }

    @discardableResult
    public static func store(tokenInfo: Any) -> APIToken? {
        if let type = APITokenManager.tokenType {
            return type.make(from: tokenInfo)
        }
        return nil
    }

    public static func clearAuthentication() {
        if let tokenType = APITokenManager.tokenType {
            tokenType.clearToken()
        }
    }
}
