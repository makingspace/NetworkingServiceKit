//
//  Service.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 2/27/17.
//
//

import Foundation

/// Defines the Behavior of a stub response
///
/// - immediate: the sub returns inmediatly
/// - delayed: the stub returns after a defined number of seconds
public enum ServiceStubBehavior {
    /// Return a response immediately.
    case immediate
    
    /// Return a response after a delay.
    case delayed(seconds: TimeInterval)
}

private let validStatusCodes = (200...299)
/// Used for stubbing responses.
public enum ServiceStubType {
    
    /// Builds a ServiceStubType from a HTTP Code and a local JSON file
    ///
    /// - Parameters:
    ///   - jsonFile: the name of the bundled json file
    ///   - code: the http code. Success codes are (200..299)
    public init(buildWith jsonFile:String, http code:Int) {
        let response = JSONSerialization.JSONObjectWithFileName(fileName: jsonFile)
        if validStatusCodes.contains(code) {
            self = .success(code: code, response: response)
        } else {
            self = .failure(code: code, response: response)
        }
    }
    
    /// The network returned a response, including status code and response.
    case success(code:Int, response:[String:Any]?)
    
    /// The network request failed with an error
    case failure(code:Int, response:[String:Any]?)
}

/// Defines the scenario case that this request expects
///
/// - authenticated: service is authenticated
/// - unauthenticated: service is unauthenticated
public enum ServiceStubCase {
    case authenticated(tokenInfo:[String:Any])
    case unauthenticated
}

/// Defines a stub request case
public struct ServiceStubRequest {
    
    /// URL Path to regex against upcoming requests
    public let path:String
    
    /// Optional parameters that will get compare as well against requests with the same kinda of parameters
    public let parameters:[String:Any]?
    
    public init(path:String, parameters:[String:Any]? = nil) {
        self.path = path
        self.parameters = parameters
    }
}

/// Defines stub response for a matching API path
public struct ServiceStub {
    /// A stubbed request
    public let request:ServiceStubRequest
    
    /// The type of stubbing we want to do, either a success or a failure
    public let stubType:ServiceStubType
    
    /// The behavior for this stub, if we want the request to come back sync or async
    public let stubBehavior:ServiceStubBehavior
    
    /// The type of case we want when the request gets executed, either authenticated with a token or unauthenticated
    public let stubCase:ServiceStubCase
    
    public init(execute request:ServiceStubRequest,
                with type:ServiceStubType,
                when stubCase:ServiceStubCase,
                react behavior:ServiceStubBehavior)
    {
        self.request = request
        self.stubType = type
        self.stubBehavior = behavior
        self.stubCase = stubCase
    }
}

extension JSONSerialization
{
    
    /// Builds a JSON Dictionary from a bundled json file
    ///
    /// - Parameter fileName: the name of the json file
    /// - Returns: returns a JSON dictionary
    public class func JSONObjectWithFileName(fileName:String) -> [String:Any]?
    {
        if let path = Bundle.currentTestBundle?.path(forResource: fileName, ofType: "json"),
            let jsonData = NSData(contentsOfFile: path),
            let jsonResult = try! JSONSerialization.jsonObject(with: jsonData as Data, options: ReadingOptions.mutableContainers) as? [String:Any]
        {
            return jsonResult
        }
        return nil
    }
}

extension Bundle {
    
    /// Locates the first bundle with a '.xctest' file extension.
    internal static var currentTestBundle: Bundle? {
        return allBundles.first { $0.bundlePath.hasSuffix(".xctest") }
    }
    
}
