//
//  TwitterSearchService.swift
//  Makespace Inc.
//
//  Created by Phillipe Casorla Sagot (@darkzlave) on 4/24/17.
//
//

import Foundation
import NetworkingServiceKit

public struct TwitterUser
{
    public let handle:String
    public let imagePath:String
    public let location: String
}
public struct TwitterSearchResult
{
    public let tweet: String
    public let user: TwitterUser
}
open class TwitterSearchService: AbstractBaseService
{
    private var nextResultsPage:String?
    open override var serviceVersion: String
    {
        return "1.1"
    }
    
    /// Search Recent Tweets by hashtag
    ///
    /// - Parameters:
    ///   - hashtag: the hashtag to use when searching
    ///   - completion: a list of TwitterSearchResult based on the term/hashtag sent
    public func searchRecents(by hashtag:String,
                              completion:@escaping (_ results:[TwitterSearchResult])-> Void) {
        guard !hashtag.isEmpty else {
            completion([TwitterSearchResult]())
            return
        }
        let parameters = ["q" : hashtag]
        request(path: "search/tweets.json",
                method: .get,
                with: parameters,
                success: { response in
                    var searchResults = [TwitterSearchResult]()
                    if let results = response["statuses"] as? [[String:Any]] {
                        for result in results {
                            if let tweet = result["text"] as? String,
                                let user = result["user"] as? [String:Any],
                                let userHandle = user["screen_name"] as? String,
                                let userImagePath = user["profile_image_url_https"] as? String,
                                let location = user["location"] as? String
                            {
                                searchResults.append(TwitterSearchResult(tweet: tweet,
                                                                         user: TwitterUser(handle: userHandle,
                                                                                           imagePath:userImagePath,
                                                                                           location: location)))
                            }
                        }
                    }
                    //save next page
                    if let metadata = response["search_metadata"] as? [String:Any],
                        let nextPage = metadata["next_results"] as? String{
                        self.nextResultsPage = nextPage
                    }
                    completion(searchResults)
        }, failure: { error, errorResponse in
            completion([TwitterSearchResult]())
        })
    }
    
    /// Continue the search for the last valid hashtag that was searched for
    ///
    /// - Parameter completion: a list of TwitterSearchResult based on the term/hashtag sent
    public func searchNextRecentsPage(completion:@escaping (_ results:[TwitterSearchResult])-> Void) {
        guard let nextPage = self.nextResultsPage else {
            completion([TwitterSearchResult]())
            return
        }
        request(path: "search/tweets.json\(nextPage)",
                method: .get,
                with: [:],
                success: { response in
                    var searchResults = [TwitterSearchResult]()
                    if let results = response["statuses"] as? [[String:Any]] {
                        for result in results {
                            if let tweet = result["text"] as? String,
                                let user = result["user"] as? [String:Any],
                                let userHandle = user["screen_name"] as? String,
                                let userImagePath = user["profile_image_url_https"] as? String,
                                let location = user["location"] as? String
                            {
                                searchResults.append(TwitterSearchResult(tweet: tweet,
                                                                         user: TwitterUser(handle: userHandle,
                                                                                           imagePath:userImagePath,
                                                                                           location: location)))
                            }
                        }
                    }
                    //save next page
                    if let metadata = response["search_metadata"] as? [String:Any],
                        let nextPage = metadata["next_results"] as? String{
                        self.nextResultsPage = nextPage
                    }
                    completion(searchResults)
        }, failure: { error, errorResponse in
            completion([TwitterSearchResult]())
        })
    }
}
