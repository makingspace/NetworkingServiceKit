//
//  StringExtensions.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/24/17.
//
//

import Foundation
import Alamofire

internal let stringParametersKey = "stringParametersKey"

/// Extenstion that allows a string to be sent as a request parameters
extension String {
    /// Convert the receiver string to a `Parameters` object.
    public func asParameters() -> Parameters {
        return [stringParametersKey: self]
    }
}

/// Convert the parameters into a string body, and it is added as the request body.
/// The string must be sent as parameters using its `asParameters` method.
public struct StringEncoding: ParameterEncoding {

    /// The options for writing the parameters as JSON data.
    public let options: JSONSerialization.WritingOptions

    /// Creates a new instance of the encoding using the given options
    ///
    /// - parameter options: The options used to encode the json. Default is `[]`
    ///
    /// - returns: The new instance
    public init(options: JSONSerialization.WritingOptions = []) {
        self.options = options
    }

    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()

        guard let parameters = parameters,
            let stringBody = parameters[stringParametersKey] as? String else {
                return urlRequest
        }

        urlRequest.httpBody = stringBody.data(using: .utf8)

        return urlRequest
    }
}
