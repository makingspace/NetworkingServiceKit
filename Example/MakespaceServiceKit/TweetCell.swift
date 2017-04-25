//
//  TweetCell.swift
//  MakespaceServiceKit
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/25/17.
//  Copyright © 2017 Makespace Inc. All rights reserved.
//

import UIKit
import MakespaceServiceKit

class TweetCell: UITableViewCell {

    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var tweetLabel: UILabel!
    @IBOutlet weak var tweetImageView: UIImageView!
    
    func load(with result:TwitterSearchResult) {
        tweetLabel.text = result.tweet
        userLabel.text = result.user.handle
        tweetImageView.setImageWith(url: URL(string: result.user.imagePath)!, placeholderImage: nil)
    }
}
