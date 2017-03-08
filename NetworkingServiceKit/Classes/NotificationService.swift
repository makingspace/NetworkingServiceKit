//
//  NotificationService.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 3/7/17.
//
//

import UIKit

@objc
open class NotificationService: AbstractBaseService {
    
    
    /// Save a device token with our APITokenManager
    ///
    /// - Parameter token: device token
    public func saveDeviceToken(token:String)
    {
        APITokenManager.set(object: token, for: .deviceTokenKey)
    }
    
    
    /// Registers a device token with the server for a specific phone number
    ///
    /// - Parameters:
    ///   - number: phone number been used
    ///   - completion: a completion block indicating if anything went good
    public func registerDeviceToken(forPhoneNumber number:String,
                             completion:@escaping (_ registered:Bool,_ error:Error?)-> Void) {
        if let existingToken = APITokenManager.set(object: token, for: .deviceTokenKey) as? String,
            let deviceID = UIDevice.current.identifierForVendor?.uuidString
        {
            
            let params = [
                "device_identifier" : deviceID,
                "token" : existingToken,
                "os_type" : "ios",
                "os_version" : UIDevice.current.systemVersion,
                "device_type" : UIDevice.current.model
            ]
            request(path: "devices", method: .post, with: params, paginated: false, success: { response in
                completion(true, nil)
            }, failure: { error, errorResponse in
                completion(false, error)
            })
        }
    
    }
}
