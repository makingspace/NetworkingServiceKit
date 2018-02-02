//
//  NetworkManagerProtocol.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation
import Alamofire

//Custom Makespace Error Response Object
@objc public class MSErrorDetails: NSObject {
    /// Message describing the error
    public let message: String
    /// Body of network request
    public let body: String?
    /// Path of network request
    public let path: String?
    /// Error code
    public let code: Int
    /// Original error object
    public let underlyingError: Error?

    public init(message: String, body: String?, path: String?, code: Int, underlyingError: Error?) {
        self.message = message
        self.body = body
        self.path = path
        self.code = code
        self.underlyingError = underlyingError
    }
    
    public convenience init(error: NSError) {
        self.init(message: error.localizedDescription, body: nil, path: nil, code: error.code, underlyingError: error)
    }
    
    public convenience init(data: Data?, request: URLRequest?, code: Int, error: Error?) {
        let components = request?.components
        let body = components?.body
        let path = components?.path
        
        var errorMessage: String?
        
        if let responseData = data,
            let responseDataString = String(data: responseData, encoding:String.Encoding.utf8),
            let responseDictionary = responseDataString.jsonDictionary {
            
            if let responseError = responseDictionary["error"] as? [String: Any],
                let message = responseError[NSError.messageKey] as? String {
                errorMessage = message
            } else if let responseError = responseDictionary["errors"] as? [[String: Any]],
                let responseFirstError = responseError.first,
                let message = responseFirstError[NSError.messageKey] as? String {
                //multiple error
                errorMessage = message
            }
        }
        
        self.init(message: errorMessage ?? (error?.localizedDescription ?? ""), body: body, path: path, code: code, underlyingError: error)
    }
}

public enum MSErrorType {
    /// Enum describing the network failure
    ///
    /// - tokenExpired: request received a 401 from a backend
    /// - badRequest: generic error for responses
    /// - internalServerError: a 500 request
    /// - badStatusCode: a request that could not validate a status code
    /// - notConnected: user not connected to the internet
    /// - forbidden: received a 403
    /// - notFound: 404, path not found
    /// - invalidResponse: server returns a response, but not in the expected format
    public enum ResponseFailureReason {
        case tokenExpired
        case badRequest
        case internalServerError
        case badStatusCode
        case connectivity
        case forbidden
        case notFound
        case invalidResponse
        
        public var description: String {
            switch self {
            case .tokenExpired:
                return "Expired Auth Token"
            case .badRequest:
                return "Invalid Network Request"
            case .forbidden:
                return "Invalid Credentials"
            case .notFound:
                return "Invalid Request Path"
            case .internalServerError:
                return "Internal Server Error"
            case .badStatusCode:
                return "Invalid Status Code"
            case .connectivity:
                return "Network Connectivity Issues"
            case .invalidResponse:
                return "Unable to Parse Server Response"
            }
        }
    }
    
    /// Enum used for errors associated with local failures
    ///
    /// - invalidData: Catchall for expected data being missing
    /// - persistenceFailure: Core Data failure
    public enum PersistenceFailureReason {
        case invalidData(description: String?)
        case persistenceFailure
        
        public var description: String {
            switch self {
            case .invalidData(let description):
                return description ?? "Invalid Data"
            case .persistenceFailure:
                return "Core Data Failure"
            }
        }
    }
    
    case responseValidation(reason: ResponseFailureReason)
    case persistenceValidation(reason: PersistenceFailureReason)
}

//Custom Makespace Error
@objc public class MSError: NSObject, Error {
    /// Enum value describing the failure
    public let type: MSErrorType
    /// Details of the error
    public let details: MSErrorDetails
    
    /// Designated initializer
    ///
    /// - Parameters:
    ///   - type: type of failure
    ///   - details: error details
    public init(type: MSErrorType, details: MSErrorDetails) {
        self.type = type
        self.details = details
    }
    
    /// Convenience initializer
    ///
    /// - Parameters:
    ///   - type: type of failure
    ///   - error: NSError object associated with failure
    public init(type: MSErrorType, error: NSError?) {
        self.type = type
        
        if let error = error {
            self.details = MSErrorDetails(error: error)
        }
        else {
            let description: String
            switch type {
            case .persistenceValidation(let reason):
                description = reason.description
            case .responseValidation(let reason):
                description = reason.description
            }
            self.details = MSErrorDetails(message: description, body: nil, path: nil, code: 0, underlyingError: nil)
        }
    }
}

extension MSError: CustomNSError {
    public var errorCode: Int {
        return details.code
    }
    
    public var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: details.message]
    }
}

// Mapped Error response failures
public extension MSErrorType.ResponseFailureReason {

    /// Conveience initializer
    ///
    /// - Parameter code: response code of the error
    public init(code: Int) {
        switch code {
        case 401:
            self = .tokenExpired
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        case 500:
            self = .internalServerError

        default:
            self = code.isNetworkErrorCode ? .connectivity : .badRequest
        }
    }
}

public extension MSError {
    /// Shortcut for identifying token expiration errors
    @objc public var hasTokenExpired: Bool {
        switch type {
        case .responseValidation(let reason):
            return reason == .tokenExpired
        default:
            return false
        }
    }
    
    /// Shortcut for identifying connectivity errors
    @objc public var isNetworkError: Bool {
        switch type {
        case .responseValidation(let reason):
            return reason == .connectivity
        default:
            return false
        }
    }
    
    /// Returns a generic error to describe Core Data problems
    @objc static var genericPersistenceError: MSError {
        return MSError(type: .persistenceValidation(reason: .invalidData(description: nil)), error: nil)
    }
    
    static func dataError(description: String) -> MSError {
        return MSError(type: .persistenceValidation(reason: .invalidData(description: description)), error: nil)
    }
}

internal extension Int {
    var isNetworkErrorCode: Bool {
        switch self {
        case NSURLErrorTimedOut, NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return true
        default:
            return false
        }
    }
}

/// Custom HTTP enum types for our network protocol
@objc
public enum HTTPMethod: Int32 {
    case options
    case get
    case head
    case post
    case put
    case patch
    case delete
    case trace
    case connect

    var string: String {
        switch self {
        case .options: return "OPTIONS"
        case .get: return "GET"
        case .head: return "HEAD"
        case .post: return "POST"
        case .put: return "PUT"
        case .patch: return "PATCH"
        case .delete: return "DELETE"
        case .trace: return "TRACE"
        case .connect: return "CONNECT"
        }
    }
}

/// Custom type of cache policy
@objc
public enum CacheResponsePolicyType : UInt {
    
    /// Cache based on HTTP-Header: Cache-Control
    case cacheControlBased
    
    /// Force Cache this response, return from the cache immediatly otherwise load network
    case forceCacheDataElseLoad
    
    /// Revalidates the cache, returns from network
    case reloadRevalidatingForceCacheData
    
    /// If the cache policy supports force caching
    var supportsForceCache:Bool {
        switch self {
        case .forceCacheDataElseLoad, .reloadRevalidatingForceCacheData: return true
        default: return false
        }
    }
}

/// Describe how the cache should behave when receiving a network response
@objc
open class CacheResponsePolicy: NSObject {
    // Cache policy type
    let type:CacheResponsePolicyType
    // Max age we would hold a cache, only used for forceCache, otherwise this is specified in the server response
    let maxAge:Double
    
    public init(type:CacheResponsePolicyType, maxAge:Double) {
        self.type = type
        self.maxAge = maxAge
    }
    
    /// Returns the default cache policy
    open static var `default`:CacheResponsePolicy {
        return CacheResponsePolicy(type:.cacheControlBased, maxAge:0)
    }
}

/// Success/Error blocks for a NetworkManager response
public typealias SuccessResponseBlock = ([String:Any]) -> Void
public typealias ErrorResponseBlock = (MSError) -> Void
//Custom parameter typealias
public typealias CustomHTTPHeaders = [String: String]
public typealias RequestParameters = [String: Any]

/// Protocol for defining a Network Manager
public protocol NetworkManager {
    var configuration: APIConfiguration {get set}
    func request(path: String,
                 method: NetworkingServiceKit.HTTPMethod,
                 with parameters: RequestParameters,
                 paginated: Bool,
                 cachePolicy:CacheResponsePolicy,
                 headers: CustomHTTPHeaders,
                 stubs: [ServiceStub],
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock)
    
    func upload(path: String,
                withConstructingBlock constructingBlock: @escaping (MultipartFormData) -> Void,
                progressBlock: @escaping (Progress) -> Void,
                headers: CustomHTTPHeaders,
                stubs: [ServiceStub],
                success: @escaping SuccessResponseBlock,
                failure: @escaping ErrorResponseBlock)
    
    init(with configuration: APIConfiguration)
}
