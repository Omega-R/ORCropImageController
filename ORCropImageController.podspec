#
# Be sure to run `pod lib lint ORCropImageController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ORCropImageController'
  s.version          = '1.0.0'
  s.summary          = 'ORCropImageController - crop of the image.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
'ORCropImageController allows user to perform crop of the image.'
                       DESC

  s.homepage         = 'https://github.com/Omega-R/ORCropImageController'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Nikita Egoshin" => "nikita.egoshin@omega-r.com", 'Egor Lindberg' => 'egor.lindberg@omega-r.com' }
  s.source           = { :git => 'https://github.com/Omega-R/ORCropImageController.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'Sources/ORCropImageController/Classes/**/*'
  s.swift_version = '5.0'
  
  # s.resource_bundles = {
  #   'ORCropImageController' => ['ORCropImageController/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'QuartzCore'
  # s.dependency 'AFNetworking', '~> 2.3'
end
