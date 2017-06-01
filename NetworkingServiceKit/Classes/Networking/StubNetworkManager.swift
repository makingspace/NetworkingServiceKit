//
//  StubNetworkManager.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot on 6/1/17.
//
//

import Foundation

open class StubNetworkManager: NetworkManager {
    
    open var configuration: APIConfiguration
    
    required public init(with configuration: APIConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Request handling
    
    /// Creates and executes a stubbed request through the stubbed cases
    ///
    /// - Parameters:
    ///   - path: full path to the URL
    ///   - method: HTTP method, default is GET
    ///   - parameters: URL or body parameters depending on the HTTP method, default is empty
    ///   - paginated: if the request should follow pagination, success only if all pages are completed
    ///   - headers: custom headers that should be attached with this request
    ///   - stubbed: a list of stubbed cases for this request to get compare against
    ///   - success: success block with a response
    ///   - failure: failure block with an error
    open func request(path: String,
                 method: NetworkingServiceKit.HTTPMethod = .get,
                 with parameters: RequestParameters = RequestParameters(),
                 paginated: Bool = false,
                 headers: CustomHTTPHeaders = CustomHTTPHeaders(),
                 stubbed: [ServiceStub],
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock) {
        let matchingRequests = stubbed.filter { path.contains($0.request.path) && ($0.request.parameters == nil ||
            NSDictionary(dictionary: parameters).isEqual(to: NSDictionary(dictionary: $0.request.parameters ?? [:]) as! [AnyHashable : Any])) }
        
        let isAuthenticated = APITokenManager.currentToken != nil
        let matchingRequestByCase = matchingRequests.filter { stub -> Bool in
            switch(stub.stubCase) {
            case .authenticated:
                return isAuthenticated == true
            case .unauthenticated:
                return isAuthenticated == false
            }
        }
        
        if let matchingRequest = matchingRequests.first {
            //lets take the first stubbed that works with this request
            switch (matchingRequest.stubCase,matchingRequest.stubType) {
            case (.authenticated,.success(_, let response)):
                executeBlock(with: matchingRequest.stubBehavior) {
                    success(response ?? [:])
                }
                
            case (.unauthenticated,.success(_, _)):
                executeBlock(with: matchingRequest.stubBehavior) {
                    failure(MSError.responseValidationFailed(reason: MSError.ResponseFailureReason.tokenExpired(code: 401)), nil)
                }
                
            case (.authenticated,.failure(let code, let response)):
                executeBlock(with: matchingRequest.stubBehavior) {
                    failure(MSError.responseValidationFailed(reason: MSError.ResponseFailureReason(code: code, error: NSError(domain: Bundle.main.appBundleIdentifier, code: code, userInfo: response))), self.buildErrorDetails(from: response, path: path))
                }
                
            case (.unauthenticated,.failure(let code, let response)):
                executeBlock(with: matchingRequest.stubBehavior) {
                    failure(MSError.responseValidationFailed(reason: MSError.ResponseFailureReason.tokenExpired(code: code)),
                            self.buildErrorDetails(from: response, path: path))
                }
            }
        } else {
            //there doesn't seem to be any stubbed cases matching this request
            success([String: Any]())
        }
    }
    
    
    /// Builds a MSErrorDetails from the given stubbed error response
    ///
    /// - Parameters:
    ///   - response: an error response
    ///   - path: current api path
    /// - Returns: a MSErrorDetails if the response had valid data
    private func buildErrorDetails(from response:[String:Any]?, path:String) -> MSErrorDetails? {
        if let response = response,
            let responseError = response["error"] as? [String: Any],
            let errorType = responseError["type"] as? String,
            let message = responseError["message"] as? String {
            let jsonData = try! JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
            
            return MSErrorDetails(errorType: errorType, message: message, body: String(data: jsonData, encoding: String.Encoding.utf8), path: path)
        }
        return nil
    }
    
    /// Executes a block based on a stubbed behavior
    ///
    /// - Parameters:
    ///   - behavior: a behavior
    ///   - closure: the block to execute
    private func executeBlock(with behavior:ServiceStubBehavior, closure:@escaping ()->()) {
        switch behavior {
        case .immediate:
            closure()
        case .delayed(let delay):
            let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: closure)
        }
        
    }
}
