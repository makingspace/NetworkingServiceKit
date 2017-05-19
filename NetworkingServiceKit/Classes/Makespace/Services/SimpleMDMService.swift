//
//  SimpleMDMService.swift
//  Makespace Inc.
//
//  Created by AL TYUS on 6/27/16.
//
//

import Foundation
import Alamofire
import SwiftyJSON

@objc
open class SimpleMDMService: AbstractBaseService {

    public enum RequestErrorType: Error {
        case serializationError
        case deviceNotRegistered
        case apiError(Error)
    }

    // Custom Failure block
    public typealias Failure = (RequestErrorType) -> Void

    /// Device identifier for current logged in device
    public var deviceId: Int?
    private let simpleMDMToken = "R6O2oVBl6z0mFFDN5c5IHbtp6kzKcRw3"

    open override var baseURL: String {
        return "https://a.simplemdm.com"
    }

    open override var serviceVersion: String {
        return "v1"
    }

    open override var servicePath: String {
        return "api"
    }

    //override request so we can attach out custom authentication header
    public override func request(path: String,
                                 method: HTTPMethod = .get,
                                 with parameters: RequestParameters = [:],
                                 paginated: Bool = false,
                                 headers: CustomHTTPHeaders = [:],
                                 success: @escaping SuccessResponseBlock,
                                 failure: @escaping ErrorResponseBlock) {
        var authHeaders = [String: String]()
        if let authorizationHeader = Request.authorizationHeader(user: simpleMDMToken, password: "") {
            authHeaders = [authorizationHeader.key: authorizationHeader.value]
        }
        super.request(path: path, method: method, with: parameters, paginated: paginated, headers: authHeaders, success: success, failure: failure)
    }

    // MARK: - APIs
    public func getApp(_ success:@escaping (SimpleMDMApp) -> Void, failure: @escaping Failure) {

        request(path: "apps",
                success: { response in

            let jsonData = JSON(response)["data"].arrayValue
            for appJSON in jsonData {
                let appObject = SimpleMDMApp(json: appJSON)
                if appObject.currentMDMApp {
                    success(appObject)
                    return
                }
            }
            failure(.serializationError)
        }) { (_, _) in
           failure(.serializationError)
        }
    }

    public func getDevice(_ success: @escaping SuccessResponseBlock, failure: @escaping Failure) {
        request(path: "devices", success: { response in

            guard let data = response["data"] as? [[String: AnyObject]] else {
                    failure(.serializationError)
                    return
            }

            let deviceName = UIDevice.current.deviceName

            let foundIndex = data.index { dataDict in
                guard let attributes = dataDict["attributes"] as? [String: AnyObject],
                    let name = attributes["name"] as? String else {
                        return false
                }

                return name == deviceName
            }

            guard let index = foundIndex else {
                failure(.deviceNotRegistered)
                return
            }

            let device = data[index]

            success(device)
        }, failure: { (error, _) in
            failure(RequestErrorType.apiError(error))
        })
    }

    public func getDevicePhoneNumber(_ success: @escaping (String) -> Void, failure: @escaping Failure) {
        request(path: "devices", success: { response in
            guard let data = response["data"] as? [[String: AnyObject]] else {
                    failure(.serializationError)
                    return
            }

            let deviceName = UIDevice.current.deviceName

            let foundIndex = data.index { dataDict in
                guard let attributes = dataDict["attributes"] as? [String: AnyObject],
                    let name = attributes["name"] as? String else {
                        return false
                }

                return name == deviceName
            }

            guard let index = foundIndex else {
                failure(.serializationError)
                return
            }

            let device = data[index]
            guard let attributes = device["attributes"] as? [String: AnyObject],
                let phoneNumber = attributes["phone_number"] as? String,
                let deviceId = device["id"] as? Int else {
                    failure(.serializationError)
                    return
            }
            self.deviceId = deviceId
            success(phoneNumber)
        }, failure: { (error, _) in
            failure(RequestErrorType.apiError(error))
        })
    }

    public func pushAppsForDevice(_ identifier: Int, completion:@escaping (_ completed: Bool) -> Void) {
        if let deviceId = self.deviceId {
            request(path: "devices/\(deviceId)/push_apps",
                method: .post,
                with: [String: Any](),
                paginated: false,
                success: { response in
                    let jsonObject = try! JSONSerialization.data(withJSONObject: response, options: JSONSerialization.WritingOptions.prettyPrinted)
                    let jsonString = NSString(data: jsonObject, encoding: String.Encoding.utf8.rawValue)! as String
                    print(jsonString)
                    completion(true)
            }) { (_, _) in
                completion(false)
            }
        }
    }
}
