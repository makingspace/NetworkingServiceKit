//
//  TweetCell.swift
//  MakespaceServiceKit
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/25/17.
//  Copyright © 2017 Makespace Inc. All rights reserved.
//

import UIKit
import NetworkingServiceKit

class TweetCell: UITableViewCell {

    @IBOutlet private weak var userLabel: UILabel!
    @IBOutlet private weak var tweetLabel: UILabel!
    @IBOutlet private weak var tweetImageView: UIImageView!

    func load(with result: TwitterSearchResult) {
        tweetLabel.text = result.tweet
        userLabel.text = result.user.handle
        tweetImageView.setImageWith(url: URL(string: result.user.imagePath)!, placeholderImage: nil)
    }
}

extension UIImageView {
    
    /// Loads an image URL into this ImageView
    ///
    /// - Parameters:
    ///   - url: the image url to set into this ImageView
    ///   - placeholder: a placeholder image, if the request fails or the image is invalid
    public func setImageWith(url: URL, placeholderImage placeholder: UIImage?) {
        //Let's make it all manual for the sake of not adding another dependency
        
        let session = URLSession(configuration: .default)

        let downloadPicTask = session.dataTask(with: url) { (data, response, error) in
            if error == nil, let imageData = data  {
                 DispatchQueue.main.sync {
                    self.image = UIImage(data: imageData)
                }
            }
            
            DispatchQueue.main.sync {
                if self.image == nil {
                    self.image = placeholder
                }
            }
        }
        
        downloadPicTask.resume()
    }
}
