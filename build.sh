#!/bin/sh

set -o pipefail &&
time xcodebuild clean test \
    -workspace RocketData.xcworkspace \
    -scheme RocketData \
    -sdk iphonesimulator10.0 \
    -destination 'platform=iOS Simulator,name=iPhone 6,OS=9.3' \
    -destination 'platform=iOS Simulator,name=iPhone 6,OS=8.4' \
    -destination 'platform=iOS Simulator,name=iPhone 7,OS=10.0' \ 
| xcpretty

