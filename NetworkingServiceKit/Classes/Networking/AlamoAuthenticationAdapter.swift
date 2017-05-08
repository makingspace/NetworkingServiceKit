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

    // MARK: - RequestAdapter
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        //attach authentication if any token has been stored
        if let token = APITokenManager.currentToken, (urlRequest.value(forHTTPHeaderField: "Authorization") == nil){
            urlRequest.setValue("Bearer " + token.authorization, forHTTPHeaderField: "Authorization")
        }
        //specify our custom user agent
        urlRequest.setValue(AlamoAuthenticationAdapter.agent, forHTTPHeaderField: "User-Agent")
        urlRequest.setValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        
        return urlRequest
    }
    
    /// Custom makespace agent header
    private static var agent:String{
        let name = UIDevice.current.name
        let version = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        let bundleExecutableName = Bundle.main.bundleExecutableName
        let agent = "UserAgent:(AppName:\(bundleExecutableName), DeviceName:\(name), Version:\(version), Model:\(model))"
        return agent
    }
}
