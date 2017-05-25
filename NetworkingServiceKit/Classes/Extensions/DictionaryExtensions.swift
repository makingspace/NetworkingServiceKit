//
//  DictionaryExtensions.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/24/17.
//
//

import Foundation

extension Dictionary where Key: ExpressibleByStringLiteral, Key.StringLiteralType == String, Value: Any {

    /// Validates if this dictionary is a masked array with key arrayParametersKey
    ///
    /// - Returns: true if the dictionary includes an array for the expected key
    func validArrayRequest() -> Bool {
        let key = Key(stringLiteral: arrayParametersKey)
        if self[key] != nil {
            return true
        }
        return false
    }

    /// Validates if this dictionary is a masked string with key stringParametersKey
    ///
    /// - Returns: true if the dictionary includes a string with the expected key
    func validStringRequest() -> Bool {
        let key = Key(stringLiteral: stringParametersKey)
        if self[key] != nil {
            return true
        }
        return false
    }
}
