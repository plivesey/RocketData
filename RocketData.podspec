Pod::Spec.new do |spec|
  spec.name             = 'RocketData'
  spec.version          = '1.0.1'
  spec.license          = { :type => 'Apache License, Version 2.0' }
  spec.homepage         = 'https://linkedin.github.io/RocketData'
  spec.authors          = 'LinkedIn'
  spec.summary          = 'A non-blocking CoreData replacement which uses immutable models.'
  spec.source           = { :git => 'https://github.com/linkedin/RocketData.git', :tag => spec.version }
  spec.source_files     = 'RocketData/**/*.swift'
  spec.platform         = :ios, '8.0'
  spec.frameworks       = 'Foundation'
  spec.dependency 'ConsistencyManager', '~> 1.0.0'
end

