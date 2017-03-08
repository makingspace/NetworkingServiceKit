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
        
    /// default session manager to be use with Alamofire
    private let sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.httpAdditionalHeaders?["User-Agent"] = AlamoNetworkManager.agent
        configuration.httpShouldSetCookies = false
        return SessionManager(configuration: configuration)
    }()
    
    //MARK: - Request handling
    
    /// Creates and executes a request using Alamofire
    ///
    /// - Parameters:
    ///   - path: full path to the URL
    ///   - method: HTTP method, default is GET
    ///   - parameters: URL or body parameters depending on the HTTP method, default is empty
    ///   - paginated: if the request should follow pagination, success only if all pages are completed
    ///   - success: success block with a response
    ///   - failure: failure block with an error
    func request(path: String,
                 method: HTTPMethod = .get,
                 with parameters: [String: Any] = [String: Any](),
                 paginated:Bool = false,
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock){
        
        guard let httpMethod = Alamofire.HTTPMethod(rawValue: method.string) else { return }
        let currentToken = APITokenManager.currentToken
        var headers: HTTPHeaders = [:]
        
        //lets use URL encoding only for GETs / DELETEs
        let encoding: ParameterEncoding = method == .get || method == .delete ? URLEncoding.default : JSONEncoding.default
        
        //attach authentication if any
        if let token = currentToken {
            headers["Authorization"] = "Bearer \(token.accessToken)"
        }
        let fullPath = "\(configuration.baseURL)\(path)"
        sessionManager.request(fullPath,
                          method: httpMethod,
                          parameters: parameters,
                          encoding: encoding,
                          headers: headers).validate().responseJSON { rawResponse in
                            //print response in DEBUG mode
                            #if DEBUG
                                debugPrint(rawResponse)
                            #endif
                            
                            if let response = rawResponse.value as? [String:Any],
                                rawResponse.error == nil {
                                if let nextPage = response["next"] as? String,
                                    paginated
                                {
                                    //call a request with the next page
                                    self.getNextPage(forURL: nextPage,
                                                     method: httpMethod,
                                                     with: parameters,
                                                     onExistingResponse: response,
                                                     encoding: encoding,
                                                     headers: headers,
                                                     success: success,
                                                     failure: failure)
                                } else {
                                    //return inmediatly
                                    success(response)
                                }
                            } else if let error = rawResponse.error {
                                failure(error, self.errorResponse(fromData: rawResponse.data))
                            } else {
                                //if the request is succesful but has no response (validation for http code has passed also)
                                success([String:Any]())
                            }
        }
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
    
    //MARK: - Pagination
    
    /// Request the next page, indicated in the response from the first request
    ///
    /// - Parameters:
    ///   - urlString: full path to the url that has the next page
    ///   - method: HTTP method to follow
    ///   - parameters: URL or body parameters depending on the HTTP method
    ///   - aggregateResponse: existing response from first call
    ///   - encoding: encoding for the request
    ///   - headers:  headers for the request
    ///   - success: success block with a response
    ///   - failure: failure block with an error
    func getNextPage(forURL urlString:String,
                     method: Alamofire.HTTPMethod,
                     with parameters: [String: Any],
                     onExistingResponse aggregateResponse:[String: Any],
                     encoding: ParameterEncoding = URLEncoding.default,
                     headers: HTTPHeaders? = nil,
                     success: @escaping SuccessResponseBlock,
                     failure: @escaping ErrorResponseBlock)
    {
        sessionManager.request(urlString,
                               method: method,
                               parameters: parameters,
                               encoding: encoding,
                               headers: headers).validate().responseJSON { rawResponse in
                                
                                if let response = rawResponse.value as? [String:Any],
                                    rawResponse.error == nil {
                                    var currentResponse = aggregateResponse
                                    
                                    //attach new response into existing response
                                    if var currentResults = currentResponse["results"] as? [[String: Any]],
                                        let newResults = response["results"] as? [String : Any]{
                                        currentResults.append(newResults)
                                        currentResponse["results"] = currentResults
                                    }
                                    
                                    //iterate on the next page if any
                                    if let nextPage = response["next"] as? String,
                                        !nextPage.isEmpty
                                    {
                                        self.getNextPage(forURL: nextPage,
                                                         method: method,
                                                         with: parameters,
                                                         onExistingResponse: currentResponse,
                                                         success: success,
                                                         failure: failure)
                                    } else {
                                        success(currentResponse)
                                    }
                                } else if let error = rawResponse.error {
                                    failure(error, self.errorResponse(fromData: rawResponse.data))
                                }
        }
    }
    
    
    /// Returns an error response from a data stream
    ///
    /// - Parameter data: data stream
    /// - Returns: a response, empty dictionary if there were issues parsing the data
    private func errorResponse(fromData data:Data?) -> [String: Any]
    {
        var errorResponse = [String:Any]()
        if let responseData = data,
            let responseDataString = String(data: responseData, encoding:String.Encoding.utf8),
            let responseDictionary = self.convertToDictionary(text: responseDataString),
            let responseError = responseDictionary["error"] as? [String: Any]{
            errorResponse = responseError
        }
        return errorResponse
    }
    
    
    /// Serializes a String JSON Response into a dictionary
    ///
    /// - Parameter text: string response
    /// - Returns: dictionary response
    private func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
