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
    
    required public init(with configuration: APIConfiguration,
                        interceptor: RequestInterceptor?) {
        self.configuration = configuration
         
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.headers = HTTPHeaders.default
        sessionConfiguration.httpShouldSetCookies = false
        let protocolClasses = sessionConfiguration.protocolClasses ?? [AnyClass]()
        sessionConfiguration.protocolClasses = [NetworkURLProtocol.self] as [AnyClass] + protocolClasses
        //Setup our cache
        let capacity = 100 * 1024 * 1024 // 100 MBs
        let urlCache = URLCache(memoryCapacity: capacity, diskCapacity: capacity, diskPath: nil)
        sessionConfiguration.urlCache = urlCache
        //This is the default value but let's make it clear caching by default depends on the response Cache-Control header
        sessionConfiguration.requestCachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
        
        self.session = Session(configuration: sessionConfiguration,
                              startRequestsImmediately: false,
                              interceptor: interceptor ?? AlamoAuthenticationAdapter())
            
    }
    
    /// default session manager to be use with Alamofire
    private let session: Session!
    
    public func cancelAllRequests() {
        session.cancelAllRequests()
    }
    
    public func upload(path: String,
                       withConstructingBlock constructingBlock: @escaping (MultipartFormData) -> Void,
                       progressBlock: @escaping (Progress) -> Void,
                       headers: CustomHTTPHeaders,
                       stubs: [ServiceStub],
                       success: @escaping SuccessResponseBlock,
                       failure: @escaping ErrorResponseBlock) {
        session.upload(multipartFormData: constructingBlock, to: path).uploadProgress { progress in
            progressBlock(progress)
        }.responseJSON { response in
            if let json = response.value as? [String: Any] {
                success(json)
            }
            else {
                failure(MSError.dataError(description: (response.error?.localizedDescription ?? "Upload Failed")))
            }
        }.resume()
    }
    
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
                        stubs: [ServiceStub] = [],
                        success: @escaping SuccessResponseBlock,
                        failure: @escaping ErrorResponseBlock) {
        
        let httpMethod = Alamofire.HTTPMethod(rawValue: method.string)
        
        //lets use URL encoding only for GETs / DELETEs OR use a specific encoding for arrays
        var encoding: ParameterEncoding = method == .get || method == .delete ? URLEncoding.default : JSONEncoding.default
        encoding = parameters.validArrayRequest() ? ArrayEncoding() : encoding
        encoding = parameters.validStringRequest() ? StringEncoding() : encoding
        
        let request = session.request(path,
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
                                        } else if let error = self.buildError(fromResponse: rawResponse) {
                                            //Figure out if we have an error and an error response
                                            failure(error)
                                        } else {
                                            //if the request is succesful but has no response (validation for http code has passed also)
                                            success([String: Any]())
                                        }
        }
        
        if cachePolicy.type == .forceCacheDataElseLoad,
            let urlRequest = try? request.convertible.asURLRequest(),
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
            AlamoNetworkManager.log("CACHED \(urlRequest.description)")
        } else {
            request.resume()
            if let desc = try? request.convertible.asURLRequest().description {
                AlamoNetworkManager.log(desc)
            }
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
        
        let request = session.request(urlString,
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
                                        } else if let error = self.buildError(fromResponse: rawResponse) {
                                            //Figure out if we have an error and an error response
                                            failure(error)
                                        } else {
                                            //if the request is succesful but has no response (validation for http code has passed also)
                                            success([String: Any]())
                                        }
        }
        
        if cachePolicy.type == .forceCacheDataElseLoad,
            let urlRequest = try? request.convertible.asURLRequest(),
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
            AlamoNetworkManager.log("CACHED \(urlRequest.description)")
        } else {
            request.resume()
            if let desc = try? request.convertible.asURLRequest().description {
                AlamoNetworkManager.log(desc)
            }
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
        }
        else {
            let response = rawResponse as? [String:Any] ?? [:]
            
            if let nextPage = response["next"] as? String,
                paginated {
                //call a request with the next page
                self.getNextPage(forURL: nextPage,
                                 method: method,
                                 with: [:],
                                 onExistingResponse: response,
                                 encoding: encoding,
                                 headers: headers,
                                 cachePolicy: cachePolicy,
                                 success: success,
                                 failure: failure)
            }
            else {
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
    
    /// Returns an MSError if the rawResponse is a valid error and has an error response
    ///
    /// - Parameter rawResponse: response from the request
    /// - Returns: a valid error reason and details if they were returned in the correct format
    func buildError(fromResponse rawResponse: DataResponse<Any, AFError>) -> MSError?
    {
        if let afError = rawResponse.error {
            if let statusCode = rawResponse.response?.statusCode,
                !AlamoNetworkManager.validStatusCodes.contains(statusCode) {
                
                let details = MSErrorDetails(data: rawResponse.data, request: rawResponse.request, code: statusCode, error: afError)
                let reason = MSErrorType.ResponseFailureReason(code: statusCode)
                
                return MSError(type: .responseValidation(reason: reason), details: details)
            }
            else {
                let error = (afError.underlyingError ?? afError) as NSError
                if error.code.isNetworkErrorCode {
                    
                    let components = rawResponse.request?.components
                    let details = MSErrorDetails(message: error.localizedDescription, body: components?.body, path: components?.path, code: error.code, underlyingError: error)
                    return MSError(type: .responseValidation(reason: .connectivity), details: details)
                }
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
