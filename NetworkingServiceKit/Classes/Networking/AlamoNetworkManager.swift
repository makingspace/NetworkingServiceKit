//
//  AlamoNetworkManager.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation
import Alamofire

open class AlamoNetworkManager: NetworkManager {
    private static let validStatusCodes = (200...299)
    public var configuration: APIConfiguration
    
    required public init(with configuration: APIConfiguration) {
        self.configuration = configuration
    }
    
    /// default session manager to be use with Alamofire
    private let sessionManager: SessionManager = {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        sessionConfiguration.httpShouldSetCookies = false
        //Setup our cache
        let capacity = 100 * 1024 * 1024 // 100 MBs
        let urlCache = URLCache(memoryCapacity: capacity, diskCapacity: capacity, diskPath: nil)
        sessionConfiguration.urlCache = urlCache
        //This is the default value but let's make it clear caching by default depends on the response Cache-Control header
        sessionConfiguration.requestCachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
        let session = SessionManager(configuration: sessionConfiguration)
        session.startRequestsImmediately = false
        //custom adapter for inserting our authentication
        session.adapter = AlamoAuthenticationAdapter()
        return session
    }()
    
    // MARK: - Request handling
    
    /// Creates and executes a request using Alamofire
    ///
    /// - Parameters:
    ///   - path: full path to the URL
    ///   - method: HTTP method, default is GET
    ///   - parameters: URL or body parameters depending on the HTTP method, default is empty
    ///   - paginated: if the request should follow pagination, success only if all pages are completed
    ///   - cachePolicy: specifices the policy to follow for caching responses
    ///   - headers: custom headers that should be attached with this request
    ///   - success: success block with a response
    ///   - failure: failure block with an error
    public func request(path: String,
                        method: NetworkingServiceKit.HTTPMethod = .get,
                        with parameters: RequestParameters = RequestParameters(),
                        paginated: Bool = false,
                        cachePolicy:CacheResponsePolicy,
                        headers: CustomHTTPHeaders = CustomHTTPHeaders(),
                        stubs: [ServiceStub],
                        success: @escaping SuccessResponseBlock,
                        failure: @escaping ErrorResponseBlock) {
        
        guard let httpMethod = Alamofire.HTTPMethod(rawValue: method.string) else { return }
        
        //lets use URL encoding only for GETs / DELETEs OR use a specific encoding for arrays
        var encoding: ParameterEncoding = method == .get || method == .delete ? URLEncoding.default : JSONEncoding.default
        encoding = parameters.validArrayRequest() ? ArrayEncoding() : encoding
        encoding = parameters.validStringRequest() ? StringEncoding() : encoding
        
        let request = sessionManager.request(path,
                                             method: httpMethod,
                                             parameters: parameters,
                                             encoding: encoding,
                                             headers: headers).validate(statusCode: AlamoNetworkManager.validStatusCodes).responseJSON { rawResponse in
                                                
                                                //Print response if we have a verbose log mode
                                                AlamoNetworkManager.logNetwork(rawResponse: rawResponse)
                                                
                                                //Return valid response
                                                if rawResponse.error == nil {
                                                    // Cached our response through URLCache
                                                    AlamoNetworkManager.cache(response: rawResponse.response,
                                                                              with: rawResponse.data,
                                                                              for: rawResponse.request,
                                                                              using: cachePolicy)
                                                    // Process valid response
                                                    self.process(rawResponse: rawResponse.value,
                                                                 method: httpMethod,
                                                                 parameters: parameters,
                                                                 encoding: encoding,
                                                                 paginated: paginated,
                                                                 cachePolicy: cachePolicy,
                                                                 headers: headers,
                                                                 success: success,
                                                                 failure: failure)
                                                } else if let (reason, errorDetails) = self.buildError(fromResponse: rawResponse) {
                                                    //Figure out if we have an error and an error response
                                                    failure(MSError.responseValidationFailed(reason: reason), errorDetails)
                                                } else {
                                                    //if the request is succesful but has no response (validation for http code has passed also)
                                                    success([String: Any]())
                                                }
        }

        if cachePolicy.type == .forceCacheDataElseLoad,
            let urlRequest = request.request,
            let cachedResponse = urlRequest.cachedJSONResponse() {
            //Process valid response
            self.process(rawResponse: cachedResponse,
                         method: httpMethod,
                         parameters: parameters,
                         encoding: encoding,
                         paginated: paginated,
                         cachePolicy: cachePolicy,
                         headers: headers,
                         success: success,
                         failure: failure)
            AlamoNetworkManager.log("CACHED \(request.description)")
        } else {
            request.resume()
            AlamoNetworkManager.log(request.description)
        }
    }
    
    
    // MARK: - Pagination
    
    /// Request the next page, indicated in the response from the first request
    ///
    /// - Parameters:
    ///   - urlString: full path to the url that has the next page
    ///   - method: HTTP method to follow
    ///   - parameters: URL or body parameters depending on the HTTP method
    ///   - aggregateResponse: existing response from first call
    ///   - encoding: encoding for the request
    ///   - headers:  headers for the request
    ///   - cachePolicy: specifices the policy to follow for caching responses
    ///   - success: success block with a response
    ///   - failure: failure block with an error
    func getNextPage(forURL urlString: String,
                     method: Alamofire.HTTPMethod,
                     with parameters: RequestParameters,
                     onExistingResponse aggregateResponse: [String: Any],
                     encoding: ParameterEncoding = URLEncoding.default,
                     headers: CustomHTTPHeaders? = nil,
                     cachePolicy:CacheResponsePolicy,
                     success: @escaping SuccessResponseBlock,
                     failure: @escaping ErrorResponseBlock) {
        
        let request = sessionManager.request(urlString,
                                             method: method,
                                             parameters: parameters,
                                             encoding: encoding,
                                             headers: headers).validate(statusCode: AlamoNetworkManager.validStatusCodes).responseJSON { rawResponse in
                                                
                                                //Print response if we have a verbose log mode
                                                AlamoNetworkManager.logNetwork(rawResponse: rawResponse)
                                                
                                                //Return valid response
                                                if let response = rawResponse.value as? [String:Any],
                                                    rawResponse.error == nil {
                                                    // Cached our response through URLCache
                                                    AlamoNetworkManager.cache(response: rawResponse.response,
                                                                              with: rawResponse.data,
                                                                              for: rawResponse.request,
                                                                              using: cachePolicy)
                                                    
                                                    //Process valid response
                                                    self.processNextPage(response: response,
                                                                         forURL: urlString,
                                                                         method: method,
                                                                         parameters: parameters,
                                                                         onExistingResponse: aggregateResponse,
                                                                         encoding: encoding,
                                                                         headers: headers,
                                                                         cachePolicy: cachePolicy,
                                                                         success: success,
                                                                         failure: failure)
                                                } else if let (reason, errorDetails) = self.buildError(fromResponse: rawResponse) {
                                                    //Figure out if we have an error and an error response
                                                    failure(MSError.responseValidationFailed(reason: reason), errorDetails)
                                                } else {
                                                    //if the request is succesful but has no response (validation for http code has passed also)
                                                    success([String: Any]())
                                                }
        }
        
        if cachePolicy.type == .forceCacheDataElseLoad,
            let urlRequest = request.request,
            let cachedResponse = urlRequest.cachedJSONResponse() as? [String:Any] {
            
            //Process valid response
            self.processNextPage(response: cachedResponse,
                                 forURL: urlString,
                                 method: method,
                                 parameters: parameters,
                                 onExistingResponse: aggregateResponse,
                                 encoding: encoding,
                                 headers: headers,
                                 cachePolicy: cachePolicy,
                                 success: success,
                                 failure: failure)
            AlamoNetworkManager.log("CACHED \(request.description)")
        } else {
            request.resume()
            AlamoNetworkManager.log(request.description)
        }
    }
    
    // MARK: - Response Processing
    
    
    /// Process a network response
    ///
    /// - Parameters:
    ///   - rawResponse: parsed response
    ///   - method: HTTP method, default is GET
    ///   - parameters: URL or body parameters depending on the HTTP method, default is empty
    ///   - encoding: the defined encoding for the request
    ///   - paginated: if the request should follow pagination, success only if all pages are completed
    ///   - cachePolicy: specifices the policy to follow for caching responses
    ///   - headers: custom headers that should be attached with this request
    ///   - success: success block with a response
    ///   - failure: failure block with an error
    private func process(rawResponse:Any?,
                         method: Alamofire.HTTPMethod,
                         parameters: RequestParameters,
                         encoding: ParameterEncoding,
                         paginated: Bool,
                         cachePolicy:CacheResponsePolicy,
                         headers: CustomHTTPHeaders,
                         success: @escaping SuccessResponseBlock,
                         failure: @escaping ErrorResponseBlock) {
        
        if let response = rawResponse as? [Any] {
            let responseDic = ["results": response]
            success(responseDic)
        } else if let response = rawResponse as? [String:Any] {
            if let nextPage = response["next"] as? String,
                paginated {
                //call a request with the next page
                self.getNextPage(forURL: nextPage,
                                 method: method,
                                 with: parameters,
                                 onExistingResponse: response,
                                 encoding: encoding,
                                 headers: headers,
                                 cachePolicy: cachePolicy,
                                 success: success,
                                 failure: failure)
            } else {
                //return inmediatly
                success(response)
            }
        }
    }
    
    /// Process a paginated network response
    ///
    /// - Parameters:
    ///   - response: parsed response list of objects
    ///   - urlString: next page URL
    ///   - method: HTTP method, default is GET
    ///   - parameters: URL or body parameters depending on the HTTP method, default is empty
    ///   - aggregateResponse: our agregated response from previous responses
    ///   - encoding: the defined encoding for the request
    ///   - paginated: if the request should follow pagination, success only if all pages are completed
    ///   - cachePolicy: specifices the policy to follow for caching responses
    ///   - headers: custom headers that should be attached with this request
    ///   - success: success block with a response
    ///   - failure: failure block with an error
    private func processNextPage(response:[String:Any],
                                 forURL urlString: String,
                                 method: Alamofire.HTTPMethod,
                                 parameters: RequestParameters,
                                 onExistingResponse aggregateResponse: [String: Any],
                                 encoding: ParameterEncoding,
                                 headers: CustomHTTPHeaders?,
                                 cachePolicy:CacheResponsePolicy,
                                 success: @escaping SuccessResponseBlock,
                                 failure: @escaping ErrorResponseBlock) {
        var currentResponse = aggregateResponse
        
        //attach new response into existing response
        if var currentResults = currentResponse["results"] as? [[String: Any]],
            let newResults = response["results"] as? [[String : Any]] {
            currentResults.append(contentsOf: newResults)
            currentResponse["results"] = currentResults
        }
        
        //iterate on the next page if any
        if let nextPage = response["next"] as? String,
            !nextPage.isEmpty {
            self.getNextPage(forURL: nextPage,
                             method: method,
                             with: parameters,
                             onExistingResponse: currentResponse,
                             encoding: encoding,
                             headers: headers,
                             cachePolicy: cachePolicy,
                             success: success,
                             failure: failure)
        } else {
            success(currentResponse)
        }
        
    }
    
    // MARK: - Error Handling
    
    /// Returns an ResponseFailureReason and MSErrorDetails if the rawResponse is a valid error and has an error response
    ///
    /// - Parameter rawResponse: response from the request
    /// - Returns: a valid error reason and details if they were returned in the correct format
    func buildError(fromResponse rawResponse: DataResponse<Any>) -> (MSError.ResponseFailureReason, MSErrorDetails?)?
    {
        if rawResponse.error != nil,
            let statusCode = rawResponse.response?.statusCode,
            !AlamoNetworkManager.validStatusCodes.contains(statusCode) {
            
            let errorDetails = errorResponse(fromData: rawResponse.data, request: rawResponse.request)
            //If we have a status code and a server error let,s build the reason with that instead
            let reason = MSError.ResponseFailureReason(code: statusCode,
                                                       error: NSError.make(from: statusCode, errorDetails: errorDetails))
            
            return (reason, errorDetails)
        }
        else if let error = rawResponse.error as NSError?, error.code.isNetworkErrorCode {
            
            let components = AlamoNetworkManager.requestComponents(rawResponse.request)
            let details = MSErrorDetails(errorType: "offline", message: error.localizedDescription, body: components?.body, path: components?.path)
            return (MSError.ResponseFailureReason.connectivity(code: error.code), details)
        }
        
        return nil
    }
    
    /// Returns an error response from a data stream
    ///
    /// - Parameter data: data stream
    /// - Returns: a response, empty dictionary if there were issues parsing the data
    private func errorResponse(fromData data: Data?, request: URLRequest?) -> MSErrorDetails? {
        var errorResponse: MSErrorDetails? = nil
        let components = AlamoNetworkManager.requestComponents(request)
        let body = components?.body
        let path = components?.path
        
        if let responseData = data,
            let responseDataString = String(data: responseData, encoding:String.Encoding.utf8),
            let responseDictionary = AlamoNetworkManager.convertToDictionary(text: responseDataString) {
            
            if let responseError = responseDictionary["error"] as? [String: Any],
                let errorType = responseError["type"] as? String,
                let message = responseError["message"] as? String {
                errorResponse = MSErrorDetails(errorType: errorType, message: message, body: body, path: path)
            } else if let responseError = responseDictionary["errors"] as? [[String: Any]],
                let responseFirstError = responseError.first,
                let errorType = responseFirstError["label"] as? String,
                let message = responseFirstError["message"] as? String {
                //multiple error
                errorResponse = MSErrorDetails(errorType: errorType, message: message, body: body, path: path)
            }
        }
        return errorResponse
    }
    
    /// Extracts a path and a body from a URLRequest
    ///
    /// - Parameter request: original request
    /// - Returns: tuple of path and body
    private static func requestComponents(_ request: URLRequest?) -> (path: String?, body: String?)? {
        guard let request = request else { return nil }
        let path = request.url?.absoluteString
        var body:String? = nil
        
        if let httpBody = request.httpBody {
            body = String(data: httpBody, encoding: String.Encoding.utf8)
        }
        
        return (path: path, body: body)
    }
    
    /// Serializes a String JSON Response into a dictionary
    ///
    /// - Parameter text: string response
    /// - Returns: dictionary response
    private static func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    // MARK: - Debugging
    
    /// Prints a debug of a network response
    ///
    /// - Parameter rawResponse: response to get printed
    private static func logNetwork(rawResponse:Any) {
        if ServiceLocator.logLevel == .verbose {
            print("🔵 ServiceLocator: ")
            debugPrint(rawResponse)
        }
    }
    
    /// Print a service locator log if we have logging enabled
    ///
    /// - Parameter text: log to print
    private static func log(_ text:String) {
        //Print request if we have log mode enabled
        if ServiceLocator.logLevel != .none {
            print("🔵 ServiceLocator: " + text)
        }
    }
    
    // MARK: - Caching
    
    /// Handles caching a response based on a cache policy
    ///
    /// - Parameters:
    ///   - response: the network response
    ///   - data: response's data
    ///   - request: original request
    ///   - cachePolicy: cache policy
    private static func cache(response:HTTPURLResponse?, with data:Data?, for request:URLRequest?, using cachePolicy: CacheResponsePolicy) {
        // Cached our response through URLCache if we are force caching and the response doesn't specify a Cache-Control
        if cachePolicy.type.supportsForceCache,
            let response = response,
            response.isResponseCachePolicyDisabled,
            let request = request,
            let data = data,
            cachePolicy.maxAge > 0 {
            let cachedURLResponse = CachedURLResponse(response: response,
                                                      data: data,
                                                      maxAge: cachePolicy.maxAge)
            URLCache.shared.storeCachedResponse(cachedURLResponse, for: request)
        }
    }
}
