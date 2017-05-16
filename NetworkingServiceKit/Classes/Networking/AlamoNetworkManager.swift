//
//  AlamoNetworkManager.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation
import Alamofire

class AlamoNetworkManager : NetworkManager
{
    private static let validStatusCodes = (200...299)
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
        encoding = parameters.validStringRequest() ? StringEncoding() : encoding        

        sessionManager.request(path,
                          method: httpMethod,
                          parameters: parameters,
                          encoding: encoding,
                          headers: headers).validate(statusCode: AlamoNetworkManager.validStatusCodes).responseJSON { rawResponse in
                            //print response in DEBUG mode
                            #if DEBUG
                                debugPrint(rawResponse)
                            #endif
                            
                            if let response = rawResponse.value as? [Any] {
                                let responseDic = ["results" : response]
                                success(responseDic)
                            } else if let response = rawResponse.value as? [String:Any],
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
                            } else if let (reason, errorDetails) = self.buildError(fromResponse: rawResponse) {
                                //Figure out if we have an error and an error response
                                failure(MSError.responseValidationFailed(reason: reason), errorDetails)
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
                               headers: headers).validate(statusCode: AlamoNetworkManager.validStatusCodes).responseJSON { rawResponse in
                                
                                if let response = rawResponse.value as? [String:Any],
                                    rawResponse.error == nil {
                                    var currentResponse = aggregateResponse
                                    
                                    //attach new response into existing response
                                    if var currentResults = currentResponse["results"] as? [[String: Any]],
                                        let newResults = response["results"] as? [[String : Any]] {
                                        currentResults.append(contentsOf: newResults)
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
                                } else if let (reason, errorDetails) = self.buildError(fromResponse: rawResponse) {
                                    //Figure out if we have an error and an error response
                                    failure(MSError.responseValidationFailed(reason: reason), errorDetails)
                                } else {
                                    //if the request is succesful but has no response (validation for http code has passed also)
                                    success([String:Any]())
                                }
        }
    }
    
    /// Returns an ResponseFailureReason and MSErrorDetails if the rawResponse is a valid error and has an error response
    ///
    /// - Parameter rawResponse: response from the request
    /// - Returns: a valid error reason and details if they were returned in the correct format
    func buildError(fromResponse rawResponse:DataResponse<Any>) -> (MSError.ResponseFailureReason,MSErrorDetails?)?
    {
        if rawResponse.error != nil,
            let statusCode = rawResponse.response?.statusCode,
            !AlamoNetworkManager.validStatusCodes.contains(statusCode) {
            
            let errorDetails = self.errorResponse(fromData: rawResponse.data, request: rawResponse.request)
            //If we have a status code and a server error let,s build the reason with that instead
            let reason = MSError.ResponseFailureReason(code: statusCode,
                                                       error: NSError.make(from: statusCode, errorDetails: errorDetails))

            return (reason, errorDetails)
        }
        return nil
    }
    
    /// Returns an error response from a data stream
    ///
    /// - Parameter data: data stream
    /// - Returns: a response, empty dictionary if there were issues parsing the data
    private func errorResponse(fromData data:Data?, request:URLRequest?) -> MSErrorDetails?
    {
        var errorResponse:MSErrorDetails? = nil
        var body:String? = nil
        var path:String? = nil
        //parse body out of the response
        if let request = request,
            let url = request.url?.absoluteString,
            let httpBody = request.httpBody,
            let stringBody = String(data: httpBody, encoding: String.Encoding.utf8) {
            body = stringBody
            path = url
        }
        if let responseData = data,
            let responseDataString = String(data: responseData, encoding:String.Encoding.utf8),
            let responseDictionary = self.convertToDictionary(text: responseDataString) {
            
            if let responseError = responseDictionary["error"] as? [String: Any],
                let errorType = responseError["type"] as? String,
                let message = responseError["message"] as? String
            {
                errorResponse = MSErrorDetails(errorType: errorType, message: message, body: body, path: path)
            } else if let responseError = responseDictionary["errors"] as? [[String: Any]],
                let responseFirstError = responseError.first,
                let errorType = responseFirstError["label"] as? String,
                let message = responseFirstError["message"] as? String
            {
                //multiple error
                errorResponse = MSErrorDetails(errorType: errorType, message: message, body: body, path: path)
            }
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
