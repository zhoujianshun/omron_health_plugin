#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint omron_health_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'omron_health_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # 添加 OMRONLib.framework (Objective-C)
  s.vendored_frameworks = 'Frameworks/OMRONLib.framework'
  
  # 保留 bitcode 设置为 NO (OMRON SDK 可能不支持 bitcode)
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'ENABLE_BITCODE' => 'NO',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  
  # 确保 Swift 可以找到 OC framework
  s.user_target_xcconfig = { 
    'OTHER_LDFLAGS' => '-framework OMRONLib'
  }
  
  # Flutter.framework does not contain a i386 slice.
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'omron_health_plugin_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
