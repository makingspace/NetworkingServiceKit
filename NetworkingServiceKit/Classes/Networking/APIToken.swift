//
//  APIToken.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation

public protocol APIToken {
    var authorization:String { get }
    static func makePersistedToken()  -> APIToken?
    static func make(from tokenResponse:[String:Any], email:String?) -> APIToken?
    static func clearToken()
}

@objc
open class APITokenManager : NSObject
{
    public static var tokenType:APIToken.Type?
    public static var currentToken:APIToken? {
        if let tokenType = APITokenManager.tokenType {
            return tokenType.makePersistedToken()
        }
        return nil
    }
    
    public static func store(tokenInfo:[String:Any], for email:String? = nil) -> APIToken?
    {
        if let type = APITokenManager.tokenType {
            return type.make(from: tokenInfo, email: email)
        }
        return nil
    }
    
    public static func clearAuthentication()
    {
        if let tokenType = APITokenManager.tokenType {
            tokenType.clearToken()
        }
    }
}
