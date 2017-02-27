//
//  APIAbstractService.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 2/23/17.
//
//

import UIKit
@objc
public enum NetworkingServiceType : Int32 {
    case accounts = 1
    
    func classForSubtype() -> AbstractService.Type? {
        switch self {
            case .accounts: return AuthenticationService.self
        }
    }
}
