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
