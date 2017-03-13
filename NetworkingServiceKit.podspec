#
# Be sure to run `pod lib lint NetworkingServiceKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NetworkingServiceKit'
  s.version          = '0.3.4'
  s.summary          = 'A service layer of networking microservices for iOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
NetworkingServiceKit is the rencarnation of MSNetworking, using a modular approach to services, the framework enables the user to select which services will need to have running, also NetworkingServiceKit takes a different approach when it comes to using Network Clients like AFNetworking, instead all requests are routed through a protocol, this makes the library loosely couple from the networking implementation.
                       DESC

  s.homepage         = 'https://github.com/makingspace/NetworkingServiceKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'darkzlave' => 'phillipe@makespace.com' }
  s.source           = { :git => 'https://github.com/makingspace/NetworkingServiceKit.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/darkzlave'
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS[config=Debug]' => '-D DEBUG',
    'OTHER_SWIFT_FLAGS[config=Staging]' => '-D STAGING'
  }
  s.ios.deployment_target = '9.0'

  s.source_files = 'NetworkingServiceKit/Classes/**/*'

  # s.resource_bundles = {
  #   'NetworkingServiceKit' => ['NetworkingServiceKit/Assets/*.png']
  # }

#    s.public_header_files = 'Pod/Classes/**/*.h'
    s.dependency 'Alamofire'
    s.dependency 'CryptoSwift'
    s.dependency 'SwiftyJSON'
end
