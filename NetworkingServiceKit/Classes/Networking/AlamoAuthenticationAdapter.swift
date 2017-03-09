//
//  AlamoNetworkRetrierAdapter.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 3/8/17.
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
            urlRequest.setValue("Bearer " + token.accessToken, forHTTPHeaderField: "Authorization")
        }
        //specify our custom user agent
        urlRequest.setValue(AlamoAuthenticationAdapter.agent, forHTTPHeaderField: "User-Agent")
        
        return urlRequest
    }
    
    /// Custom makespace agent header
    private static var agent:String{
        let name = UIDevice.current.name
        let version = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        let bundleExecutableName = Bundle.main.infoDictionary?["CFBundleExecutable"] ?? ""
        let agent = "UserAgent:(AppName:\(bundleExecutableName), DeviceName:\(name), Version:\(version), Model:\(model))"
        return agent
    }
}
