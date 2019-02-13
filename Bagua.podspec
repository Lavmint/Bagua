#
# Be sure to run `pod lib lint Bagua.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Bagua'
  s.version          = '0.2.7'
  s.summary          = 'Swift wrapper around CoreData stack inspired by Realm'

  s.homepage         = 'https://github.com/Lavmint/Bagua'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alexey Averkin' => 'lavmint@gmail.com' }
  s.source           = { :git => 'https://github.com/Lavmint/Bagua.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.swift_version = '4.2'
  
  s.source_files = 'Bagua/Classes/**/*'
  s.frameworks = 'CoreData'
end
