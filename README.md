[![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=58e4111d378b330001f0228e&branch=master&build=latest)](https://dashboard.buddybuild.com/apps/58e4111d378b330001f0228e/build/latest?branch=master)

<p align="center" >
  <img src="https://github.com/makingspace/NetworkingServiceKit/blob/master/NetworkingServiceKit/Assets/logo.png" alt="NetworkingServiceKit" title="NetworkingServiceKit" height ="100" width="525">
</p>


## Description

NetworkingServiceKit (originally [MSNetworking](https://github.com/makingspace/MSNetworking)). It's a library for building modular microservices, 100% in swift and following a design pattern known as the [Service Locator](https://msdn.microsoft.com/en-us/library/ff648968.aspx).

NetworkingServiceKit works as a solution for the standard iOS monolith API client and for the non-existent middleware layer that most iOS Apps lack, using a modular approach to services, the framework enables the app to select which services it will require to have running for it to work.

Since networking is one of the biggest responsabilities a service layer usually requires, NetworkingServiceKit includes auto-of-the-box authenticating requests, persisting auth and seemlessly executing request through a decoupled AlamoFire client. This makes a breeze replacing the networking client implementation for different version of Alamofire, or just another library.

To launch NetworkingServiceKit either run the default services or specify a set of services, for example:

```swift
NetworkingServiceLocator.loadDefaultServices()
//or with custom services
NetworkingServiceLocator.load(withServices: [AuthenticationService.self])

```
For requesting one of the loaded services you simply ask the service locator, for example:

```swift
let service = NetworkingServiceLocator.service(forType: OpsService.self)
service?.getBookingsWithUserXid("usr_La4Jb7zTbkFSgmBLeKuLbN", success: { response in
    print("Success")
}, error: { error, errorResponse in
    print("error")
})
```
Each defined service can be linked to a specific microservice path and version by overriding the servicePath and serviceVersion properties, for example:

```swift
open class TwitterSearchService: AbstractBaseService {
    
    public override var serviceVersion: String {
        return "v4"
    }
    
    public override var servicePath:String {
        return "search"
    }
    
    public func searchRecents(by hashtag:String,
                              completion:@escaping (_ results:[TwitterSearchResult])-> Void) {
        guard !hashtag.isEmpty else {
            completion([TwitterSearchResult]())
            return
        }
        let parameters = ["q" : hashtag]
        request(path: "tweets.json",
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
}
```
This will automatically prefix all request URLs in **TwitterSearchService** start with **search/v4/** for the example func above the full URL for the executed request will be something like https://api.twitter.com/search/v4/tweets.json.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first. 

The example project consists of a very simple Twitter client that authenticates automatically using Twitter's Application-only authentication (https://dev.twitter.com/oauth/application-only). The client supports searching for tweets, pagination of results and showing the location of the listed tweets in a map.

## Requirements

## Installation

NetworkingServiceKit is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "NetworkingServiceKit"
```

## Author

darkzlave, phillipe@makespace.com

## License

NetworkingServiceKit is available under the MIT license. See the LICENSE file for more info.
