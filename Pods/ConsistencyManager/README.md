# Overview

This library provides a way of keeping immutable models consistent. First, listeners listen to an immutable model. Whenever this model (or any child model) is updated, the Consistency Manager will generate a new model and notify its listeners.

## Installation

```ruby
pod 'ConsistencyManager'
```

## Motivation

Immutable models have many advantages including thread-safety, performance, and more functional and understandable code. However, many applications need to be able to update their models, and these models are often shared across different screens. The models are also often shared across different screens. Since the models are immutable, you always need to create new models for changes. Then, you need to propagate these changes to all the screens rendering this model. The Consistency Manager provides a pub-sub API and automatically regenerates new models for listeners.

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

