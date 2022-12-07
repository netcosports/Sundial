
use_frameworks!
inhibit_all_warnings!
platform :ios, '11.0'

install! 'cocoapods', :disable_input_output_paths => true

target 'Demo' do
  pod 'Sundial', :path => '.', :inhibit_warnings => false
  pod 'SnapKit'

  pod 'Astrolabe', :git => 'git@github.com:netcosports/Astrolabe.git', :branch => 'kmm'
  
  pod 'PinLayout'
  pod 'Nocturnal', :git => 'git@github.com:netcosports/Nocturnal.git', :branch => 'kmm'
  pod 'Alidade', :git => 'git@github.com:netcosports/Alidade.git', :branch => 'kmm'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|

    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 11.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
      end
      if config.name == 'Debug'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
        else
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
      end
    end
  end
end

