//
//  NetworkManagerProtocol.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation

//Custom Makespace Error Response Object
@objc
public class MSErrorDetails: NSObject {
    public let errorType: String
    public let message: String
    public let body: String?
    public let path: String?

    public init(errorType: String, message: String, body: String?, path: String?) {
        self.errorType = errorType
        self.message = message
        self.body = body
        self.path = path
    }
}
//Custom Makespace Error
public enum MSError: Error {
    /// The underlying reason the request failed
    ///
    /// - tokenExpired: request received a 401 from a backend
    /// - badRequest: generic error for responses
    /// - internalServerError: a 500 request
    /// - badStatusCode: a request that could not validate a status code
    /// - persistanceFailure: any issues related to our data layer
    public enum ResponseFailureReason {

        case tokenExpired(code: Int)
        case badRequest(error: Error)
        case internalServerError
        case badStatusCode
        case persistanceFailure(code: Int)
    }

    public enum PersistanceFailureReason {

        case invalidData
        case persistanceFailure(code: Int)
    }

    case responseValidationFailed(reason: ResponseFailureReason)
    case persistanceValidationFailed(reason: PersistanceFailureReason)

}

// Mapped Error response failures
extension MSError.ResponseFailureReason {
    var responseCode: Int {
        switch self {
        case .tokenExpired(let code):
            return code
        case .badRequest(let error):
            return (error as NSError).code
        case .internalServerError:
            return 500
        default:
            return 0
        }
    }

    var underlyingError: Error? {
        switch self {
        case .badRequest(let error):
            return error
        default:
            return nil
        }
    }

    var hasTokenExpired: Bool {
        switch self {
        case .tokenExpired( _):
            return true
        default:
            return false
        }
    }
    init(code: Int, error: Error) {
        switch code {
        case 401:
            self = .tokenExpired(code: code)
        case 500:
            self = .internalServerError

        default:
            self = .badRequest(error: error)
        }
    }
}

extension MSError {
    /// Returns whether the MSError is because our token expired
    public var hasTokenExpired: Bool {
        switch self {
        case .responseValidationFailed(let reason):
            return reason.hasTokenExpired
        default: return false
        }
    }

    //Returns the response code for an error
    public var responseCode: Int {
        switch self {
        case .responseValidationFailed(let reason):
            return reason.responseCode
        default:
            return 0
        }
    }

    /// The `Error` returned by a system framework associated with a `.responseValidationFailed`
    public var underlyingError: Error? {
        switch self {
        case .responseValidationFailed(let reason):
            return reason.underlyingError
        default:
            return nil
        }
    }

    /// Helper method for determining whether an error is a connectivity issue
    ///
    /// - returns: returns true if the error is a connectivity issue and false if not
    public var isNetworkError: Bool {
        switch self.responseCode {
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
public typealias ErrorResponseBlock = (MSError, MSErrorDetails?) -> Void
//Custom parameter typealias
public typealias CustomHTTPHeaders = [String: String]
public typealias RequestParameters = [String: Any]

/// Protocol for defining a Network Manager
public protocol NetworkManager {
    var configuration: APIConfiguration {get set}
    func request(path: String,
                 method: HTTPMethod,
                 with parameters: RequestParameters,
                 paginated: Bool,
                 headers: CustomHTTPHeaders,
                 success: @escaping SuccessResponseBlock,
                 failure: @escaping ErrorResponseBlock)

    init(with configuration: APIConfiguration)
}
