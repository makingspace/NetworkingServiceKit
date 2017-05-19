//
//  UIDeviceExtensions.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/6/17.
//
//

import Foundation

extension UIDevice {
    /// Returns the current device name, if we are running tests it returns a default name
    internal var deviceName: String {
        let runningStackDuringUnitTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        return runningStackDuringUnitTest ? "Default iPhone" : UIDevice.current.name
    }
}
