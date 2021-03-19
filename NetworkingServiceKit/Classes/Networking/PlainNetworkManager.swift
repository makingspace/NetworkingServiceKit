//
//  PlainNetworkManager.swift
//  NetworkingServiceKit
//
//  Created by Leandro Perez on 09/03/2021.
//

import Foundation
import Alamofire

/// WIP: A networking manager that uses `URLSession` and `URLSessionTask` directly.
/// This would allow for background url sessions
open class PlainNetworkManager : NSObject, NetworkManager {
    public var configuration: APIConfiguration
    private var progressHandlersByTaskID = [Int : (success: SuccessResponseBlock,
                                                   failure: ErrorResponseBlock)]()
    
    private lazy var backgroundSession: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.backgroundWithPrefixIdentifier()
        sessionConfiguration.headers = .default
        sessionConfiguration.httpShouldSetCookies = false
        var protocolClasses = sessionConfiguration.protocolClasses ?? [AnyClass]()
        sessionConfiguration.protocolClasses = [NetworkURLProtocol.self] as [AnyClass] + protocolClasses
        //Setup our cache
        let capacity = 100 * 1024 * 1024 // 100 MBs
        let urlCache = URLCache(memoryCapacity: capacity, diskCapacity: capacity, diskPath: nil)
        sessionConfiguration.urlCache = urlCache
        //This is the default value but let's make it clear caching by default depends on the response Cache-Control header
        sessionConfiguration.requestCachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
        let session = URLSession(configuration: sessionConfiguration,
                                 delegate: self,
                                 delegateQueue: .main)
        return session
    }()
    
    public required init(with configuration: APIConfiguration) {
        self.configuration = configuration
    }
    
    public func request(path: String,
                        method: HTTPMethod,
                        with parameters: RequestParameters,
                        paginated: Bool,
                        cachePolicy: CacheResponsePolicy,
                        headers: CustomHTTPHeaders,
                        stubs: [ServiceStub],
                        success: @escaping SuccessResponseBlock,
                        failure: @escaping ErrorResponseBlock) {
        
        guard let url = URL(string: path) else {fatalError("malformed url \(path)")}
        guard let body = try? JSONSerialization.data(withJSONObject: parameters) else { fatalError("malformed parameters \(parameters)")}
        
        let request = URLRequest.from(method,
                                      url: url,
                                      accept: .json,
                                      contentType: .json,
                                      body: body,
                                      headers: headers.dictionary,
                                      expectedStatusCode: expected200to300,
                                      timeOutInterval: 10)
        let task = backgroundSession.dataTask(with: request)
        progressHandlersByTaskID[task.taskIdentifier] = (success, failure)
        task.resume()
    }
    
    public func upload(path: String,
                       withConstructingBlock constructingBlock: @escaping (MultipartFormData) -> Void,
                       progressBlock: @escaping (Progress) -> Void,
                       headers: CustomHTTPHeaders,
                       stubs: [ServiceStub],
                       success: @escaping SuccessResponseBlock,
                       failure: @escaping ErrorResponseBlock) {
     //TODO: complete this
    }
}

public extension URLSessionConfiguration {
    static func backgroundWithPrefixIdentifier(_ prefix: String = "com.makespace.networking.",
                                               sharedContainerIdentifier : String = "group.makespace.apps",
                                               bundle: Bundle = .main) -> URLSessionConfiguration {
        let appBundleName = bundle.bundleURL.lastPathComponent
            .lowercased()
            .replacingOccurrences(of: " ", with: ".")
        return URLSessionConfiguration.background(withIdentifier: prefix + appBundleName)
    }
}



/// Built-in Content Types
public enum ContentType: String {
    case json = "application/json"
    case xml = "application/xml"
}

/// Returns `true` if `code` is in the 200..<300 range.
public func expected200to300(_ code: Int) -> Bool {
    return code >= 200 && code < 300
}

extension URLRequest {
    static func from(_ method: HTTPMethod,
                     url: URL,
                     accept: ContentType? = nil,
                     contentType: ContentType? = nil,
                     body: Data? = nil,
                     headers: [String:String] = [:],
                     expectedStatusCode: @escaping (Int) -> Bool = expected200to300,
                     timeOutInterval: TimeInterval = 10)  -> URLRequest {
        var request = URLRequest(url: url)
        if let a = accept {
            request.setValue(a.rawValue, forHTTPHeaderField: "Accept")
        }
        if let ct = contentType {
            request.setValue(ct.rawValue, forHTTPHeaderField: "Content-Type")
        }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.timeoutInterval = timeOutInterval
        request.httpMethod = method.string
        
        // body *needs* to be the last property that we set, because of this bug: https://bugs.swift.org/browse/SR-6687
        request.httpBody = body
        return request
    }
}

public typealias Handler<T> = (T) -> Void

/// Signals that a response's data was unexpectedly nil.
public struct NoDataError: Error {
    public init() { }
}

/// An unknown error
public struct UnknownError: Error {
    public init() { }
}

/// Signals that a response's status code was wrong.
public struct WrongStatusCodeError: Error {
    public let statusCode: Int
    public let response: HTTPURLResponse?
    public let responseBody: Data?
    public init(statusCode: Int, response: HTTPURLResponse?, responseBody: Data?) {
        self.statusCode = statusCode
        self.response = response
        self.responseBody = responseBody
    }
}

extension URLSession {
    
    @discardableResult
    public func request(_ request: URLRequest,
                        dispatchQueue : DispatchQueue = .main,
                        dataWrapper: Handler<Data?>? = nil,
                        success: @escaping SuccessResponseBlock,
                        failure: @escaping ErrorResponseBlock) -> URLSessionDataTask {
        let task = dataTask(with: request, completionHandler: { data, resp, err in
            if let err = err {
                dispatchQueue.async {
                    failure(MSError(type: .responseValidation(reason: .invalidResponse), details: .init(error: err as NSError)))
                }
                
                return
            }
            
            guard let h = resp as? HTTPURLResponse else {
                dispatchQueue.async {
                    failure(MSError(type: .responseValidation(reason: .invalidResponse), details: MSErrorDetails(error: NSError())))
                }
                return
            }
            
            guard expected200to300(h.statusCode) else {
                dispatchQueue.async {
                    let reason = MSErrorType.ResponseFailureReason(code: h.statusCode)
                    failure(MSError(type: .responseValidation(reason: reason), details:  MSErrorDetails(error: NSError(domain: "makespace", code: h.statusCode, userInfo: nil))))
                }
                return
            }
        })
        task.resume()
        return task
    }
    
    @discardableResult
    public func request<A>(_ request: URLRequest,
                           dispatchQueue : DispatchQueue = .main,
                           dataWrapper: Handler<Data?>? = nil,
                           parse: @escaping (Data?, URLResponse?) -> Result<A, Error>,
                           onComplete: @escaping (Result<A, Error>) -> ()) -> URLSessionDataTask {
        let task = dataTask(with: request, completionHandler: { data, resp, err in
            if let err = err {
                dispatchQueue.async {
                    onComplete(.failure(err))
                }
                
                return
            }
            
            guard let h = resp as? HTTPURLResponse else {
                dispatchQueue.async {
                    onComplete(.failure(UnknownError()))
                }
                return
            }
            
            guard expected200to300(h.statusCode) else {
                dispatchQueue.async {
                    onComplete(.failure(WrongStatusCodeError(statusCode: h.statusCode, response: h, responseBody: data)))
                }
                return
            }
            
            dispatchQueue.async {
                dataWrapper?(data)
                onComplete(parse(data,resp))
            }
        })
        task.resume()
        return task
    }
}


extension PlainNetworkManager:  URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let handler = progressHandlersByTaskID[task.taskIdentifier] else {return}
        
        if let error = error {
            handler.failure(MSError.from(error: error))
        }
        
        guard let h = task.response as? HTTPURLResponse else {
            
            handler.failure(MSError(type: .responseValidation(reason: .invalidResponse), details: MSErrorDetails(error: NSError())))
            return
        }
        
        guard expected200to300(h.statusCode) else {
            
            let reason = MSErrorType.ResponseFailureReason(code: h.statusCode)
            handler.failure(MSError(type: .responseValidation(reason: reason), details:  MSErrorDetails(error: NSError(domain: "makespace", code: h.statusCode, userInfo: nil))))
            return
        }
    }
}

extension PlainNetworkManager:  URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let handler = progressHandlersByTaskID[dataTask.taskIdentifier] else {return}
        
        //TODO: Parse the data using the same alamofire parser and send it.
//        handler.success(data)
    }
}

extension MSError {
    static func from(error: Error) -> MSError {
        let nsError = error as NSError
        return MSError(type: .responseValidation(reason: MSErrorType.ResponseFailureReason(code: nsError.code)), error: nsError)
    }
}
