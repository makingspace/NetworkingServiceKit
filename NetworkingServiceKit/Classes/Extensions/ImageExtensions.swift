//
//  ImageExtensions.swift
//  Pods
//
//  Created by Phillipe Casorla Sagot on 3/13/17.
//
//

import Foundation

extension UIImage
{
    func hasAlpha() -> Bool {
        if let alphaInfo = self.cgImage?.alphaInfo {
            return (alphaInfo == .first ||
                alphaInfo == .last ||
                alphaInfo == .premultipliedFirst ||
                alphaInfo == .premultipliedLast);
        }
        return false
    }
    
    func base64DataUri() -> String{
        var imageData:Data = Data()
        var mimeType:String = "image/png"
        if self.hasAlpha(), let dataPNG = UIImagePNGRepresentation(self) {
            imageData = dataPNG
        } else if let dataJPEG = UIImageJPEGRepresentation(self, 1.0)
        {
            imageData = dataJPEG
        }
        return String(format: "data:%@;base64,%@", mimeType, imageData.base64EncodedString())
    }
}