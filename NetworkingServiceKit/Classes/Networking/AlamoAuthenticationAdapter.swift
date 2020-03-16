//
//  AlamoNetworkRetrierAdapter.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 3/8/17.
//
//

import Foundation
import Alamofire

class AlamoAuthenticationAdapter: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        //attach authentication if any token has been stored
        if let token = APITokenManager.currentToken, (urlRequest.value(forHTTPHeaderField: "Authorization") == nil) {
            urlRequest.setValue("Bearer " + token.authorization, forHTTPHeaderField: "Authorization")
        }
        //specify our custom user agent
        urlRequest.setValue(AlamoAuthenticationAdapter.agent, forHTTPHeaderField: "User-Agent")

        completion(Result.success(urlRequest))
    }
    
    /// Custom makespace agent header
    private static var agent: String {
        let name = UIDevice.current.name
        let version = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        let bundleExecutableName = Bundle.main.bundleExecutableName
        let agent = "UserAgent:(AppName:\(bundleExecutableName), DeviceName:\(name), Version:\(version), Model:\(model))"
        return agent
    }
}
