# Note: You must be using Cocoapods 1.0.0 or above

use_frameworks!

target :'RocketData' do
  pod 'ConsistencyManager', '~> 3.0.0'
end

target :'RocketDataTests' do
  pod 'ConsistencyManager', '~> 3.0.0'
end

# This is necessary to convert the target to swift 3.0
# This isn't detected automatically by cocoapods or supported in the podspec
# We can remove this once Cocoapods has a better solution
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end

# This is necessary to convert the target to swift 3
# This isn't detected automatically by cocoapods or supported in the podspec
# We can remove this once Cocoapods has a better solution
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '2.3'
        end
    end
end

