//
//  AlamoNetworkManager.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 2/27/17.
//
//

import Foundation
import Alamofire

class AlamoNetworkManager : NetworkManager
{
    var configuration: APIConfiguration
    
    required init(with configuration: APIConfiguration) {
        self.configuration = configuration
    }
    private let sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.httpAdditionalHeaders?["User-Agent"] = AlamoNetworkManager.agent
        configuration.httpShouldSetCookies = false
        return SessionManager(configuration: configuration)
    }()
    
    func request(path: String,
                 method: HTTPMethod,
                 with parameters: [String: Any],
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorBlock){
        
        guard let httpMethod = Alamofire.HTTPMethod(rawValue: method.rawValue) else { return }
        let currentToken = APITokenManager.currentToken
        var headers: HTTPHeaders = [:]
        if let token = currentToken {
            headers["Authorization"] = "Bearer \(token.accessToken)"
        }
        let fullPath = "\(configuration.baseURL)\(path)"
        sessionManager.request(fullPath,
                          method: httpMethod,
                          parameters: parameters,
                          encoding: JSONEncoding.default,
                          headers: headers).validate().responseJSON { response in
                            #if DEBUG
                                debugPrint(response)
                            #endif
                            if let result = response.result.value as? [String:Any],
                                response.error == nil {
                                success(result)
                            } else if let error = response.error {
                                let erroras = response.result.value
                                failure(error)
                            }
        }
    }
    
    private static var agent:String{
        let name = UIDevice.current.name
        let version = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        let bundleExecutableName = Bundle.main.infoDictionary?["CFBundleExecutable"] ?? ""
        let agent = "UserAgent:(AppName:\(bundleExecutableName), DeviceName:\(name), Version:\(version), Model:\(model))"
        return agent
    }
}
