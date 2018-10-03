Pod::Spec.new do |s|

  s.name = 'Sundial'
  s.version = '4.2'
  s.summary = 'Collection view layout for pager header'

  s.homepage = 'https://github.com/netcosports/Sundial'
  s.license = { :type => "MIT" }
  s.author = {
    'Sergei Mikhan' => 'sergei@netcosports.com'
  }
  s.source = { :git => 'https://github.com/netcosports/Sundial.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.dependency 'Astrolabe/Core'
  s.source_files = ['Sources/*.swift', 'Sources/UIScrollView+ScrollingToTop.{h,m}']

end
