# Overview

[![Build Status](https://travis-ci.org/linkedin/ConsistencyManager-iOS.svg?branch=master)](https://travis-ci.org/linkedin/ConsistencyManager-iOS)
[![codecov](https://codecov.io/gh/linkedin/ConsistencyManager-iOS/branch/master/graph/badge.svg)](https://codecov.io/gh/linkedin/ConsistencyManager-iOS)
[![GitHub release](https://img.shields.io/github/release/linkedin/ConsistencyManager-iOS.svg?maxAge=86400)](https://github.com/linkedin/ConsistencyManager-iOS/releases)

This library provides a way of keeping immutable models consistent. First, listeners listen to an immutable model. Whenever this model (or any child model) is updated, the Consistency Manager will generate a new model and notify its listeners.

## Rocket Data

If you are interested in this project, you may want to consider using Rocket Data which provides a higher level API for the Consistency Manager. It implements caching, collection support, and conflict resolution. It's the recommended way for consuming the Consistency Manager.

GitHub: https://github.com/linkedin/RocketData

Documentation: https://linkedin.github.io/RocketData

## Installation

```ruby
pod 'ConsistencyManager'
```

## Motivation

Immutable models have many advantages including thread-safety, performance, and more functional and understandable code. However, many applications need to be able to update their models, and these models are often shared across different screens. Since the models are immutable, you always need to create new models for changes. Then, you need to propagate these changes to all the screens rendering this model. The Consistency Manager provides a pub-sub API and automatically regenerates new models for listeners.

## How It Works

Immutable models can be visualized as trees. Each model has fields representing data (strings, ints, etc.) and pointers to other immutable models. Each model also may have an id to uniquely identify themselves. For instance, a messaging application could have these two models:

<div align="center"><img src="https://raw.githubusercontent.com/linkedin/ConsistencyManager-iOS/master/docs/images/treeOriginal.png" height="320px" /></div>

In the application, two view controllers would register with the Consistency Manager that they are listening on these models.

```swift
// In each UIViewController
ConsistencyManager.sharedInstance.listenForUpdates(self)
```

Later in the application, some source, like a network request, push notification, or user action, indicates that a person with id = 12 has come online. The application can then create a new person model which looks like this:

<div align="center"><img src="https://raw.githubusercontent.com/linkedin/ConsistencyManager-iOS/master/docs/images/nodeUpdate.png" height="150px" /></div>

Then, the application would update this model in the consistency manager.

```swift
ConsistencyManager.sharedInstance.updateWithNewModel(personModel)
```

The Consistency Manager finds that two models, Message and Contacts, need updating and creates new copies of these models with the updated Person model:

<div align="center"><img src="https://raw.githubusercontent.com/linkedin/ConsistencyManager-iOS/master/docs/images/treeUpdate.png" height="320px" /></div>

The Consistency Manager then delivers the updated models to the subscribed listeners (view controllers in this case) via delegate callbacks. The view controller simply needs to set the new data and refresh its view.

## Docs

To get started, you should take a look at the docs:

https://linkedin.github.io/ConsistencyManager-iOS

## Swift Version

We are currently not maintaining separate branches for different Swift versions. You can use an older and stable version of the Consistency Manager for older versions of Swift though. HEAD currently supports Swift 3.

| Swift Version | Consistency Manager Version  |
|---------------|------------------------------|
| 1             | Not supported                |
| 2.0 - 2.1     | 2.x.x (untested)             |
| 2.2 - 2.3     | 2.x.x                        |
| 3 (Easy migration API) | 3.x.x               |
| 3 (Better API) | 4.x.x                       |

NOTE: If you are migrating to Swift 3, consider using version 3.0.0 first, then migrating to 4.x.x. 3.0.0 migrates the code to the new syntax without making any API changes. 4.x.x introduces a better API which is more consistent with the new Swift 3 API guidelines.

