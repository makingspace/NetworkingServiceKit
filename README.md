[![CI Status](http://img.shields.io/travis/darkzlave/NetworkingServiceKit.svg?style=flat)](https://travis-ci.org/darkzlave/NetworkingServiceKit)
[![Version](https://img.shields.io/cocoapods/v/NetworkingServiceKit.svg?style=flat)](http://cocoapods.org/pods/NetworkingServiceKit)
[![License](https://img.shields.io/cocoapods/l/NetworkingServiceKit.svg?style=flat)](http://cocoapods.org/pods/NetworkingServiceKit)
[![Platform](https://img.shields.io/cocoapods/p/NetworkingServiceKit.svg?style=flat)](http://cocoapods.org/pods/NetworkingServiceKit)

<p align="center" >
  <img src="https://github.com/makingspace/NetworkingServiceKit/blob/master/NetworkingServiceKit/Assets/logo.png" alt="NetworkingServiceKit" title="NetworkingServiceKit" height ="100" width="525">
</p>


## Description

NetworkingServiceKit( originally [MSNetworking](https://github.com/makingspace/MSNetworking)). It's a networking library for our internal apps built 100% in swift and following a design pattern known as the [Service Locator](https://msdn.microsoft.com/en-us/library/ff648968.aspx).

NetworkingServiceKit is launched by either running the default services or specifying a specifc set of services, for example:

```swift
NetworkingServiceLocator.loadDefaultServices()
//or with custom services
NetworkingServiceLocator.load(withServices: [AuthenticationService.self])

```
For using one of loaded services you simply ask the service locator, for example:

```swift
let service = NetworkingServiceLocator.service(forType: OpsService.self)
service?.getBookingsWithUserXid("usr_La4Jb7zTbkFSgmBLeKuLbN", success: { response in
    print("Success")
}, error: { error, errorResponse in
    print("error")
})
```
## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

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
