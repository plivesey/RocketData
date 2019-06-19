Pod::Spec.new do |spec|
  spec.name             = 'RocketData'
  spec.version          = '8.0.0'
  spec.license          = { :type => 'Apache License, Version 2.0' }
  spec.homepage         = 'https://plivesey.github.io/RocketData'
  spec.authors          = 'plivesey'
  spec.summary          = 'A non-blocking CoreData replacement which uses immutable models.'
  spec.source           = { :git => 'https://github.com/plivesey/RocketData.git', :tag => spec.version }
  spec.source_files     = 'RocketData/**/*.swift'
  spec.ios.deployment_target  = '8.0'
  spec.ios.frameworks         = 'Foundation'
  spec.tvos.deployment_target = '9.0'
  spec.tvos.frameworks        = 'Foundation'

  spec.dependency 'ConsistencyManager', '~> 8.0.0'
end

