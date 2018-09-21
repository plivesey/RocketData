#!/bin/sh

set -o pipefail &&
time xcodebuild clean test \
    -workspace RocketData.xcworkspace \
    -scheme RocketData \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 6,OS=9.3' \
    -destination 'platform=iOS Simulator,name=iPhone 7,OS=10.1' \
    -destination 'platform=iOS Simulator,name=iPhone X,OS=11.3' \
    -destination 'platform=iOS Simulator,name=iPhone XS Max,OS=12.0' \
| xcpretty

# Disabling 8.4 because it's very flaky on travis
# We can look at reenabling when it gets more stable
#    -destination 'platform=iOS Simulator,name=iPhone 6,OS=8.4' \

