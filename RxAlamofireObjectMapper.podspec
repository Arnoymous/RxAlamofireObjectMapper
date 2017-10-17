#
# Be sure to run `pod lib lint RxAlamofireObjectMapper.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RxAlamofireObjectMapper'
  s.version          = '0.1.9'
  s.summary          = 'Rx DataRequest helpers for ObjectMapper'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Arnoymous/RxAlamofireObjectMapper'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Arnoymous' => 'arnaud.dorgans@gmail.com' }
  s.source           = { :git => 'https://github.com/Arnoymous/RxAlamofireObjectMapper.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/arnauddorgans'

  s.ios.deployment_target = '8.0'
  #s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'RxAlamofireObjectMapper/Classes/**/*'
  
  # s.resource_bundles = {
  #   'RxAlamofireObjectMapper' => ['RxAlamofireObjectMapper/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'RxSwift', '~> 3.6.1'
s.dependency 'Alamofire', '~> 4.5.1'
s.dependency 'ObjectMapper', '~> 3.0.0'
end
