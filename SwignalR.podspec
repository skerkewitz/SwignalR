#
# Be sure to run `pod lib lint SwignalR.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwignalR'
  s.version          = '0.8.0'
  s.summary          = 'A SignalR implementation in Swift 3.1'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/skerkewitz/SwignalR'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Stefan Kerkewitz' => 'stefan.kerkewitz@gmail.com' }
  s.source           = { :git => 'https://github.com/skerkewitz/SwignalR.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/SirGodOfCoding'

  s.ios.deployment_target = '9.0'

  s.source_files = 'SwignalR/Classes/**/*'

  s.dependency 'Alamofire', '~> 4.3'
  s.dependency 'Starscream', '~> 2.0'
  s.dependency 'CocoaLumberjack/Swift', '~> 3.0'
end
