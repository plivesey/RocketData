Pod::Spec.new do |spec|
  spec.name             = 'RocketData'
  spec.version          = '5.0.0'
  spec.license          = { :type => 'Apache License, Version 2.0' }
  spec.homepage         = 'https://plivesey.github.io/RocketData'
  spec.authors          = 'plivesey'
  spec.summary          = 'A non-blocking CoreData replacement which uses immutable models.'
  spec.source           = { :git => 'https://github.com/plivesey/RocketData.git', :tag => spec.version }
  spec.source_files     = 'RocketData/**/*.swift'
  spec.platform         = :ios, '8.0'
  spec.frameworks       = 'Foundation'
  spec.dependency 'ConsistencyManager', '~> 5.2.0'
end

