#!/bin/sh

set -o pipefail &&
time xcodebuild clean test \
    -scheme RocketData \
    -sdk macosx \
    -enableCodeCoverage YES \
    | tee build.log \
    | xcpretty &&
time xcodebuild clean test \
    -scheme RocketData \
    -sdk iphonesimulator \
    -disable-concurrent-destination-testing \
    -enableCodeCoverage YES \
    -destination 'platform=iOS Simulator,name=iPhone 6,OS=10.3.1' \
    -destination 'platform=iOS Simulator,name=iPhone 7,OS=11.4' \
    -destination 'platform=iOS Simulator,name=iPhone X,OS=12.4' \
    -destination 'platform=iOS Simulator,name=iPhone 11 Pro,OS=13.3' \
    | tee build.log \
    | xcpretty &&
time xcodebuild clean test \
    -scheme RocketData \
    -sdk appletvsimulator \
    -enableCodeCoverage YES \
    -destination 'platform=tvOS Simulator,name=Apple TV,OS=13.3' \
    | tee build.log \
    | xcpretty &&
cat build.log
