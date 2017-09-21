//
//  NetworkURLProtocol.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot on 9/20/17.
//

import UIKit

/// Custom URLProtocol for intercepting requests
class NetworkURLProtocol: URLProtocol {
    
    private var session: URLSession?
    private var sessionTask: URLSessionDataTask?
    
    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        
        if session == nil {
            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        }
    }
    
    /// Check if we should intercept a request
    ///
    /// - Parameter request: request to be intercepted based on our delegate and baseURL
    /// - Returns: if we should intercept
    override class func canInit(with request: URLRequest) -> Bool {
        let baseURL = APIConfiguration.current.baseURL
        if let delegate = ServiceLocator.shared.delegate,
            let urlString = request.url?.absoluteString,
            urlString.contains(baseURL) {
            return delegate.shouldInterceptRequest(with: request)
        }
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override var cachedResponse: CachedURLResponse? {
        return nil
    }
    
    /// Load the request, if we find this request is an intercepted one, execute the new request
    override func startLoading() {
        if let delegate = ServiceLocator.shared.delegate,
            let newRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest,
            let modifiedRequest = delegate.processIntercept(for: newRequest) {
            sessionTask = session?.dataTask(with: modifiedRequest as URLRequest)
            sessionTask?.resume()
            
            if ServiceLocator.logLevel != .none {
                print("☢️ ServiceLocator: Intercepted request, NEW: \(modifiedRequest.url?.absoluteString ?? "")")
            }
        }
    }
    
    override func stopLoading() {
        sessionTask?.cancel()
    }
}

// MARK: - URLSessionDataDelegate
extension NetworkURLProtocol: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        completionHandler(request)
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error = error else { return }
        client?.urlProtocol(self, didFailWithError: error)
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace = challenge.protectionSpace
        let sender = challenge.sender
        
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                sender?.use(credential, for: challenge)
                completionHandler(.useCredential, credential)
                return
            }
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        client?.urlProtocolDidFinishLoading(self)
    }
}
