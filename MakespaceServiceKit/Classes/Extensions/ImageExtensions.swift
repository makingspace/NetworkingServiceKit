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

extension UIImageView
{
    public func setImageWith(url:URL, placeholderImage placeholder:UIImage?)
    {
        self.af_setImage(withURL: url, placeholderImage: placeholder)
    }
}
