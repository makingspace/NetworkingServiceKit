//
//  AlamoNetworkRetrierAdapter.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 3/8/17.
//
//

import Foundation
import Alamofire

class AlamoAuthenticationAdapter: RequestAdapter {

    // Adapt requests with our authentication
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        //attach authentication if any token has been stored
        if let token = APITokenManager.currentToken, (urlRequest.value(forHTTPHeaderField: "Authorization") == nil){
            urlRequest.setValue("Bearer " + token.accessToken, forHTTPHeaderField: "Authorization")
        }
        //specify our custom user agent
        urlRequest.setValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        
        return urlRequest
    }
}
