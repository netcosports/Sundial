Pod::Spec.new do |s|

  s.name = 'Sundial'
  s.version = '6.0.1'
  s.summary = 'Collection view layout for pager header'

  s.homepage = 'https://github.com/netcosports/Sundial'
  s.license = { :type => "MIT" }
  s.author = {
    'Sergei Mikhan' => 'sergei@netcosports.com'
  }
  s.source = { :git => 'https://github.com/netcosports/Sundial.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.dependency 'Astrolabe', '~> 6'
  s.swift_versions = ['5.0', '5.1', '5.2', '5.3']
  s.source_files = ['Sources/**/*.swift']

end
