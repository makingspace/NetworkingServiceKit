//
//  UIDeviceExtensions.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 4/6/17.
//
//

import Foundation

extension UIDevice
{
    internal var deviceName: String {
        let runningStackDuringUnitTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        return runningStackDuringUnitTest ? "Default iPhone" : UIDevice.current.name
    }
}
