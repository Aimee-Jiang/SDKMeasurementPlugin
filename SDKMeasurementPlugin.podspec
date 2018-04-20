#
# Be sure to run `pod lib lint SDKMeasurementPlugin.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SDKMeasurementPlugin'
  s.version          = '0.0.1'
  s.summary          = 'The plugin serves the publishers for measurement of continuous view-time and viewability.'
  
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  
  s.description      = 'It\'s a light-weight SDK to provide measurement of continuous view-time and viewabilty independent from AN SDK without conflicts with Freewheel and DFP'
  
  s.libraries = 'c++'
  s.homepage         = 'https://github.com/Aimee-Jiang/SDKMeasurementPlugin.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Weiwei Jiang' => 'weiweij@fb.com' }
  s.source           = { :git => 'https://github.com/Aimee-Jiang/SDKMeasurementPlugin.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '8.0'
  
  s.source_files = 'SDKMeasurementPlugin/Classes/*.{h,m,mm}'
  
  s.public_header_files = 'SDKMeasurementPlugin/Classes/*.h'
  s.frameworks = 'UIKit', 'MapKit', 'AVFoundation', 'AVKit'
  
end

