[![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=58e4111d378b330001f0228e&branch=master&build=latest)](https://dashboard.buddybuild.com/apps/58e4111d378b330001f0228e/build/latest?branch=master)

<p align="center" >
  <img src="https://github.com/makingspace/NetworkingServiceKit/blob/master/NetworkingServiceKit/Assets/logo.png" alt="NetworkingServiceKit" title="NetworkingServiceKit" height ="100" width="525">
</p>


## Description

NetworkingServiceKit is a library for building modular microservices. It is built 100% in swift and follows a design pattern known as the [Service Locator](https://msdn.microsoft.com/en-us/library/ff648968.aspx).

NetworkingServiceKit works as a full fledge replacement for the standard iOS monolith API client. Using a modular approach to services, the framework enables the app to select which services it requires to run so that networking can happen seamlessly.

Networking is usually one of the biggest responsibilities a service layer requires and is a standard requirement in most apps. NetworkingServiceKit includes out-of-the-box authentication for requests. It uses a decoupled AlamoFire client along with a set of protocols that define your authentication needs to seamlessly execute requests while encapsulating token authentication. This makes changes to your network architecture a breeze - updating your Alamofire version, or using a stub networking library, becomes a painless task instead of a complete rewrite.

To launch our **ServiceLocator** class you will need to define your list of services plus implementations of your authentication, your token and server details. For example:

```swift
ServiceLocator.set(services: [TwitterAuthenticationService.self,LocationService.self,TwitterSearchService.self],
                           api: TwitterAPIConfigurationType.self,
                           auth: TwitterApp.self,
                           token: TwitterAPIToken.self)

```
For this example we have created a simple Twitter client and implemented Twitter token handling, authentication and defined their server details. Our [TwitterAPIConfigurationType](https://github.com/makingspace/NetworkingServiceKit/blob/feature/OpenSourceExample2/Example/NetworkingServiceKit/TwitterAPIConfiguration.swift#L57) tells the service layer information about our server base URL. [TwitterApp](https://github.com/makingspace/NetworkingServiceKit/blob/feature/OpenSourceExample2/Example/NetworkingServiceKit/TwitterAPIConfiguration.swift#L12) gives the details needed for signing a request with a key and a secret. [TwitterAPIToken](https://github.com/makingspace/NetworkingServiceKit/blob/feature/OpenSourceExample2/Example/NetworkingServiceKit/TwitterAPIToken.swift#L13) implements how we are going to parse and store token information once we have been authenticated.

Once our client has been authenticated, all requests going through one of our implemented Service will get automatically signed by our implementation of an APIToken.

For requesting one of the loaded services you simply ask the service locator, for example:

```swift
let twitterSearchService = ServiceLocator.service(forType: TwitterSearchService.self)
twitterSearchService?.searchRecents(by: searchText, completion: { [weak self] results in

            if let annotations = self?.mapView.annotations {
                self?.mapView.removeAnnotations(annotations)
            }
            self?.currentResults = results
            self?.tweetsTableView.reloadData()
            self?.showTweetsLocationsOnMap()
        })
```
Each defined service can be linked to a specific microservice path and version by overriding the servicePath and serviceVersion properties, for example:

```swift
open class TwitterSearchService: AbstractBaseService {

    public override var serviceVersion: String {
        return "1.1"
    }

    public override var servicePath:String {
        return "search"
    }

    public func searchRecents(by hashtag:String,
                              completion:@escaping (_ results:[TwitterSearchResult])-> Void) {
    }
}
```
This will automatically prefix all request URLs in **TwitterSearchService** start with **search/1.1/**, so for the example func above, the full URL for the executed request will be something like https://api.twitter.com/search/v4/tweets.json.

## Stubbing

NetworkingServiceKit supports out of the box stubbing request through a custom API Client: **StubNetworkManager**. 

```swift
ServiceLocator.defaultNetworkClientType = StubNetworkManager.self
```
Once you have set up our Stub client, all you need is to request a service with a set of stubs, this stubs will get automatically link to a request if they matches the same criteria the stub it's defining. For Example:

```swift
let searchStub = ServiceStub(execute:
            ServiceStubRequest(path: "/1.1/search/tweets.json",
                               parameters: ["q" : "#makespace"]),
                                     with: .success(code: 200,
                                                    response: ["statuses" : [["text" : "tweet1" ,
                                                                              "user" : ["screen_name" : "darkzlave",
                                                                                        "profile_image_url_https" : "https://lol.png",
                                                                                        "location" : "Stockholm, Sweden"]],
                                                                             ["text" : "tweet2" ,
                                                                              "user" : ["screen_name" : "makespace",
                                                                                        "profile_image_url_https" : "https://lol2.png",
                                                                                        "location" : "New York"]]],
                                                               "search_metadata" : ["next_results" : "https://search.com/next?pageId=2"]
                                        ]), when: .authenticated(tokenInfo: ["token_type" : "access",
                                                                             "access_token" : "KWALI"]),
                                            react:.delayed(seconds: 0.5))
let searchService = ServiceLocator.service(forType: TwitterSearchService.self, stubs: [searchStub])                         
```

Our example searchStub will get returned for all .get authenticated requests that are under the path **/1.1/search/tweets.json?q=#makespace** and the request will return after 0.5sec. For our TwitterSearchService this occurs all seemlessly without having to do any changes on the code for it to be tested.

## ReactiveSwift
NSK includes supports for [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) through `ReactiveSwiftNetworkManager`. This enable services to return `SignalProducer` instead of relying on completion blocks. This can easily enable chaining and mapping of network responses, for example:

```swift

func searchNextRecentsPageProducer() -> SignalProducer<[TwitterSearchResult],MSError> {
    guard let nextPage = self.nextResultsPage else {
        return SignalProducer.empty
    }
    let request = request(path: "search/tweets.json\(nextPage)")
    return request.map { response -> [TwitterSearchResult] in
        var searchResults = [TwitterSearchResult]()
        
        guard let response = response else { return searchResults }
        
        if let results = response["statuses"] as? [[String:Any]] {
            for result in results {
                if let twitterResult = TwitterSearchResult(dictionary: result) {
                    searchResults.append(twitterResult)
                }
            }
        }

        return searchResults
    }
}

```


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
