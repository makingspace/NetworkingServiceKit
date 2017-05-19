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
