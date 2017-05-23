//
//  ImageExtensions.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 3/13/17.
//
//

import Foundation
import UIKit
import AlamofireImage

extension UIImage {
    
    /// Indicates if an image has transparency
    ///
    /// - Returns: true if the image has transparency
    func hasAlpha() -> Bool {
        if let alphaInfo = self.cgImage?.alphaInfo {
            return (alphaInfo == .first ||
                alphaInfo == .last ||
                alphaInfo == .premultipliedFirst ||
                alphaInfo == .premultipliedLast)
        }
        return false
    }

    /// Returns a HTTP Post Body with the image binary attached as a base64 string
    ///
    /// - Returns: the http body with the image attached as data
    func base64DataUri() -> String {
        var imageData: Data = Data()
        var mimeType: String = "image/png"
        if self.hasAlpha(), let dataPNG = UIImagePNGRepresentation(self) {
            imageData = dataPNG
        } else if let dataJPEG = UIImageJPEGRepresentation(self, 1.0) {
            imageData = dataJPEG
            mimeType = "image/jpeg"
        }
        return String(format: "data:%@;base64,%@", mimeType, imageData.base64EncodedString())
    }
}

extension UIImageView {

    /// Loads an image URL into this ImageView
    ///
    /// - Parameters:
    ///   - url: the image url to set into this ImageView
    ///   - placeholder: a placeholder image, if the request fails or the image is invalid
    public func setImageWith(url: URL, placeholderImage placeholder: UIImage?) {
        self.af_setImage(withURL: url, placeholderImage: placeholder)
    }
}
