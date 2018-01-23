#!/bin/sh

set -o pipefail &&
time xcodebuild clean test \
    -workspace RocketData.xcworkspace \
    -scheme RocketData \
    -sdk iphonesimulator11.0 \
    -destination 'platform=iOS Simulator,name=iPhone 6,OS=9.3' \
    -destination 'platform=iOS Simulator,name=iPhone 7,OS=11.0' \
| xcpretty

# Disabling 8.4 because it's very flaky on travis
# We can look at reenabling when it gets more stable
#    -destination 'platform=iOS Simulator,name=iPhone 6,OS=8.4' \

