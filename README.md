# 🚀 Data

[![Build Status](https://travis-ci.org/linkedin/RocketData.svg?branch=master)](https://travis-ci.org/linkedin/RocketData)
[![codecov](https://codecov.io/gh/linkedin/RocketData/branch/master/graph/badge.svg)](https://codecov.io/gh/linkedin/RocketData)
[![GitHub release](https://img.shields.io/github/release/linkedin/RocketData.svg?maxAge=86400)](https://github.com/linkedin/RocketData/releases)
[![CocoaPods](https://img.shields.io/cocoapods/p/RocketData.svg?maxAge=86400)](#)

Rocket Data is a model management system with persistence for immutable models.

## Motivation

Immutability has [many benefits](see https://linkedin.github.io/RocketData/pages/130_immutability.html), but keeping models consistent and making changes is difficult. This library manages the consistency and caching of immutable models. It is intended to be an ideal replacement for Core Data. However, unlike Core Data, it does not block the main thread and does not crash whenever you do something slightly incorrect (see [Core Data Comparison](https://linkedin.github.io/RocketData/pages/100_coreData.html)). In most setups, the backing cache does not need a schema, and you never need to add migration logic.

## Scale

Rocket Data scales extremely well to large numbers of models and data providers. Since it does nearly all of its work on a background thread, you never need to worry about one change slowing down the whole application. You can also choose to stop listening to changes when a view controller is off screen to further increase performance.

The library is optimized for applications that fetch data from an external source, display it on the device, and allow the user to perform actions on this data. It implements an easy model for synchronizing this data in-memory between view controllers and with the cache.

## Bring Your Own Cache

With Rocket Data, you can choose your own caching solution. We recommend a fast key-value store, but you can use any store you can imagine. This also makes it easy to add LRU eviction.

## Installation

Installation via both [CocoaPods](https://cocoapods.org) and [Carthage](https://github.com/Carthage/Carthage) is supported.

### CocoaPods

Add this to your Podspec:
```ruby
pod 'RocketData'
```
Then run `pod install`.

### Carthage

Add this to your `Cartfile`:
```ogdl
github "linkedin/RocketData"
```
Then run `carthage update RocketData --platform ios`

NOTE: Currently, `--platform ios` is necessary for some reason. We are investigating the issue.

### Swift Version

We are currently not maintaining separate branches for different Swift versions. You can use an older version of Rocket Data for older versions of Swift though. HEAD currently supports Swift 3.

| Swift Version | Rocket Data Version          |
|---------------|------------------------------|
| 1             | Not supported                |
| 2.0 - 2.1     | 1.x.x (untested)             |
| 2.2           | 1.x.x                        |
| 2.3 (Cocoapods) | 1.x.x                      |
| 2.3 (Carthage) | 1.2.0                       |
| 3 (Easy migration API) | 2.0.0               |
| 3 (Better API) | 4.x.x                       |

NOTE: If you are migrating to Swift 3, consider using version 2.0.0 first, then migrating to 3.x.x. 3.0.0 migrates the code to the new syntax without making any API changes. 3.x.x introduces a better API which is more consistent with the new Swift 3 API guidelines.

## Documentation

To get started, you should take a look at the [docs](https://linkedin.github.io/RocketData).

### Consistency Manager

Rocket Data uses [ConsistencyManager-iOS](https://github.com/linkedin/ConsistencyManager-iOS/) to manage the in-memory consistency of models. While you never need to access the Consistency Manager directly, understanding how it works will help you understand Rocket Data.

## Security

If you believe you have discovered a security issue, please send an email to security@linkedin.com with information and detailed instructions on how to reproduce the issue.
