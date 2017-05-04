//
//  NotificationService.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 3/7/17.
//
//

import UIKit

extension Data {
    var hexString: String {
        return map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
    }
}

@objc
open class NotificationService: AbstractBaseService {
    
    
    /// Save a device token with our APITokenManager
    ///
    /// - Parameter token: device token
    public func saveDeviceToken(token:Data)
    {
        APITokenManager.set(object: token.hexString, for: .deviceTokenKey)
    }
    
    
    /// Registers a device token with the server for a specific phone number
    ///
    /// - Parameters:
    ///   - number: phone number been used
    ///   - completion: a completion block indicating if anything went good
    public func registerDeviceToken(forPhoneNumber number:String,
                             completion:@escaping (_ registered:Bool,_ error:MSError?)-> Void) {
        if let existingToken = APITokenManager.object(for: .deviceTokenKey) as? String,
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
        } else {
            completion(false, nil)
        }
    
    }
}
