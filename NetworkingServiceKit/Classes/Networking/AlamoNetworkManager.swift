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
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        sessionConfiguration.httpShouldSetCookies = false
        let session = SessionManager(configuration: sessionConfiguration)
        //custom adapter for inserting our authentication
        session.adapter = AlamoAuthenticationAdapter()
        return session
    }()
    
    //MARK: - Request handling
    
    /// Creates and executes a request using Alamofire
    ///
    /// - Parameters:
    ///   - path: full path to the URL
    ///   - method: HTTP method, default is GET
    ///   - parameters: URL or body parameters depending on the HTTP method, default is empty
    ///   - paginated: if the request should follow pagination, success only if all pages are completed
    ///   - headers: custom headers that should be attached with this request
    ///   - success: success block with a response
    ///   - failure: failure block with an error
    func request(path: String,
                 method: HTTPMethod = .get,
                 with parameters: RequestParameters = RequestParameters(),
                 paginated:Bool = false,
                 headers:CustomHTTPHeaders = CustomHTTPHeaders(),
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock)
    {
        
        guard let httpMethod = Alamofire.HTTPMethod(rawValue: method.string) else { return }
        
        //lets use URL encoding only for GETs / DELETEs OR use a specific encoding for arrays
        var encoding: ParameterEncoding = method == .get || method == .delete ? URLEncoding.default : JSONEncoding.default
        encoding = parameters.validArrayRequest() ? ArrayEncoding() : encoding

        sessionManager.request(path,
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
                            } else if let error = rawResponse.error as? NSError {
                                var reason = MSError.ResponseFailureReason.badRequest(code: error.code)
                                
                                if let statusCode = rawResponse.response?.statusCode
                                {
                                    //if the response has a 401 that means we have an authentication issue
                                    reason = statusCode == 401 ? MSError.ResponseFailureReason.tokenExpired(code: statusCode) :
                                        MSError.ResponseFailureReason.badRequest(code: statusCode)
                                }
                                failure(MSError.responseValidationFailed(reason: reason),
                                        self.errorResponse(fromData: rawResponse.data))
                            } else {
                                //if the request is succesful but has no response (validation for http code has passed also)
                                success([String:Any]())
                            }
        }
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
                     with parameters: RequestParameters,
                     onExistingResponse aggregateResponse:[String: Any],
                     encoding: ParameterEncoding = URLEncoding.default,
                     headers: CustomHTTPHeaders? = nil,
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
                                } else if let error = rawResponse.error as? NSError {
                                    var reason = MSError.ResponseFailureReason.badRequest(code: error.code)
                                    
                                    if let statusCode = rawResponse.response?.statusCode
                                    {
                                        //if the response has a 401 that means we have an authentication issue
                                        reason = statusCode == 401 ? MSError.ResponseFailureReason.tokenExpired(code: statusCode) :
                                            MSError.ResponseFailureReason.badRequest(code: statusCode)
                                    }
                                    failure(MSError.responseValidationFailed(reason: reason), self.errorResponse(fromData: rawResponse.data))
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
