# 🚀 Data

Rocket Data is a model management system with persistence for immutable models. Immutability has many benefits (see INSERT_LINK_CASEFORIMMUTABILITY), but keeping models consistent and making changes is difficult. This library manages the consistency and caching of immutable models. It is intended to be an ideal replacement for Core Data. However, unlike Core Data, it does not block the main thread and does not crash whenever you do something slightly incorrect (see Core Data Comparison). In most setups, the backing cache does not need a schema, and you never need to add migration logic.

## Scale

Rocket Data scales extremely well to large numbers of models and data providers. Since it does nearly all of its work on a background thread, you never need to worry about one change slowing down the whole application. You can also choose to stop listening to changes when a view controller is off screen to further increase performance.

The library is optimized for applications that fetch data from an external source, display it on the device, and allow the user to perform actions on this data. It implements an easy model for synchronizing this data in-memory between view controllers and with the cache.

## Custom Caching

With Rocket Data, you can choose your own caching solution. We recommend a fast key-value store, but you can use any solution that you can imagine. This also makes it easy to add LRU eviction.

# Consistency Manager

Rocket Data uses ConsistencyManager-iOS to manage the in-memory consistency of models. While you never need to access the Consistency Manager directly, understanding how it works will help you understand Rocket Data.

Consistency Manager Docs: https://linkedin.github.io/ConsistencyManager-iOS/

Consistency Manager Code: https://github.com/linkedin/ConsistencyManager-iOS/

# Installation

```
pod 'RocketData'
```

# Docs

To get started, you should take a look at the docs:

https://linkedin.github.io/RocketData
