//
//  NetworkManagerProtocol.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation

//Custom Makespace Error Response Object
public struct MSErrorDetails {
    public let message: String
    public let body: String?
    public let path: String?
    public let code: Int
    public let underlyingError: Error?

    public init(message: String, body: String?, path: String?, code: Int, underlyingError: Error?) {
        self.message = message
        self.body = body
        self.path = path
        self.code = code
        self.underlyingError = underlyingError
    }
    
    public init(error: NSError) {
        self.init(message: error.localizedDescription, body: nil, path: nil, code: error.code, underlyingError: error)
    }
}

public enum MSErrorType {
    /// The underlying reason the request failed
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
    
    public enum PersistenceFailureReason {
        case invalidData
        case persistenceFailure
        
        public var description: String {
            switch self {
            case .invalidData:
                return "Invalid Data"
            case .persistenceFailure:
                return "Core Data Failure"
            }
        }
    }
    
    case responseValidation(reason: ResponseFailureReason)
    case persistenceValidation(reason: PersistenceFailureReason)
}

//Custom Makespace Error
public struct MSError: Error {
    public let type: MSErrorType
    public let details: MSErrorDetails
    
    public init(type: MSErrorType, details: MSErrorDetails) {
        self.type = type
        self.details = details
    }
    
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

// Mapped Error response failures
public extension MSErrorType.ResponseFailureReason {

    var hasTokenExpired: Bool {
        switch self {
        case .tokenExpired:
            return true
        default:
            return false
        }
        
    }
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
    /// Returns whether the MSError is because our token expired
    public var hasTokenExpired: Bool {
        switch type {
        case .responseValidation(let reason):
            return reason.hasTokenExpired
        default:
            return false
        }
    }
    
    public var isNetworkError: Bool {
        switch type {
        case .responseValidation(let reason):
            return reason == .connectivity
        default:
            return false
        }
    }
    
    static var genericLocalDataError: MSError {
        return MSError(type: .persistenceValidation(reason: .invalidData), error: nil)
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
                 headers: CustomHTTPHeaders,
                 stubs: [ServiceStub],
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock)

    init(with configuration: APIConfiguration)
}
