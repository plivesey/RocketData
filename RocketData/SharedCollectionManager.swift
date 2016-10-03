// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import Foundation
import ConsistencyManager

/**
 This class manages shared collections. It keeps track of all collections with the same cache key.
 Most of the operations run synchronously to ensure that all collections with the same cache key are always the same.
 */
class SharedCollectionManager {

    /**
     This keeps track of all the providers with the same cacheKey.
     Whenever we do a change, we search this array for other collections with the same cacheKey and run the same operations on those collections.
     */
    private var providers = [String: WeakSharedCollectionArray]()

    /**
     This should be called whenever a collection data provider's cacheKey has changed.
     It will update the providers dictionary accordingly.
     */
    func updateProvider(_ provider: SharedCollection, cacheKey: String?, previousCacheKey: String?) {
        if cacheKey == previousCacheKey {
            return
        }
        // Remove the previous value
        if let previousCacheKey = previousCacheKey,
            let previousProviders = providers[previousCacheKey] {
                // Remove it from the previous cacheKey array
                providers[previousCacheKey] = previousProviders.filter { element in
                    return element !== provider
                }
        }
        // Add the new value
        if let cacheKey = cacheKey {
            var collections: WeakSharedCollectionArray
            if var weakArray = providers[cacheKey] {
                if !weakArray.contains(where: { element in element === provider }) {
                    weakArray.append(provider)
                }
                collections = weakArray
            } else {
                collections = [provider]
            }
            providers[cacheKey] = collections
        }
    }

    /**
     Returns all providers with the same cache key as the current provider.
     It does not return the current provider in the returned array.
     */
    func siblingProvidersForProvider(_ provider: SharedCollection, cacheKey: String) -> [SharedCollection] {
        if var weakArray = providers[cacheKey] {
            // We'll use this opportunity to prune the weak array and clean up some memory
            let siblingProviders = weakArray.prune().filter { $0 !== provider }
            providers[cacheKey] = weakArray
            return siblingProviders
        } else {
            return []
        }
    }

    /**
     Searches for any providers with the same cacheKey and returns the most up to date data.
     This is effectively a cache lookup, but runs synchronously.
     It is also guaranteed to give the most recent change, which the cache lookup may not (because its asyncronous).
     */
    func dataFromProviders<T>(cacheKey: String) -> DataHolder<[T]>? {
        if var dataProviders = providers[cacheKey] {
            let dataProvidersArray = dataProviders.prune()
            providers[cacheKey] = dataProviders
            let data = dataFromProviders(dataProvidersArray)
            if let data = data, let genericArray: [T] = SharedCollectionManager.genericArrayFromArray(data.data) {
                return DataHolder<[T]>(data: genericArray, changeTime: data.lastUpdated)
            }
        }
        return nil
    }

    /**
     Helper which searches for the most recent data from an array of SharedCollection.
     */
    func dataFromProviders(_ providers: [SharedCollection]) -> DataHolder<[Any]>? {
        let maxElement = providers.max { first, second in
            return second.lastUpdated.after(first.lastUpdated)
        }
        if let maxElement = maxElement {
            return DataHolder<[Any]>(data: maxElement.anyData, changeTime: maxElement.lastUpdated)
        } else {
            return nil
        }
    }

    /**
     Private function which converts a generic array of [Any] to [T].
     It checks for errors while doing this.
     This will only fail if the user of the library is trying to share two collections with different types.
     If it fails, we will return nil and no change will be made.
     */
    fileprivate static func genericArrayFromArray<T>(_ array: [Any]) -> [T]? {
        let actualData = array.flatMap { $0 as? T }
        if array.count == actualData.count {
            return actualData
        } else {
            Log.sharedInstance.assert(false, "Unable to cast collection array to [T]. This means you are trying to share two collections which have different models. You can only share collections of the same type.")
            return nil
        }
    }
}

/**
 In the SharedCollectionManager, we actually want to store CollectionDataProvider<?>.
 However, that's not currently supported in Swift, so we have to create this protocol.
 This protocol matches the methods we need from CollectionDataProvider, but uses Any instead of T.
 This allows us to store them in a dictionary.
 These methods implement the necessary updates when a shared collection makes changes.
 */
protocol SharedCollection: class {
    /**
     This should return the data of the array cast to Any.
     */
    var anyData: [Any] { get }
    /**
     This returns the last time the collection was updated.
     */
    var lastUpdated: ChangeTime { get }
    /**
     This sets new data.
     It should also check for equality since we will call this even though we're not sure anything has actually changed.
     */
    func setAnyData(_ data: [Any], context: Any?)
    /**
     This should insert an array into the collection.
     It should NOT call update on the consistency manager or try to save to the cache.
     The original collection will already do this and we don't want to make multiple calls.
     It should however listen on any new elements.
     */
    func insertAny(_ data: [Any], at index: Int, context: Any?)
    /**
     This should update an element in the collection.
     It should NOT call update on the consistency manager or try to save to the cache.
     The original collection will already do this and we don't want to make multiple calls.
     It should however listen on any new elements.
     */
    func updateAny(_ element: Any, at index: Int, context: Any?)
    /**
     This should remove an element from the collection.
     It should NOT call update on the consistency manager or try to save to the cache.
     The original collection will already do this and we don't want to make multiple calls.
     */
    func removeAnyAtIndex(_ index: Int, context: Any?)
}

extension CollectionDataProvider: SharedCollection {

    var anyData: [Any] {
        get {
            // This is necessary because of a Swift bug.
            return data.map { $0 as Any }
        }
    }

    func setAnyData(_ newData: [Any], context: Any?) {
        guard let newData: [T] = SharedCollectionManager.genericArrayFromArray(newData) else {
            return
        }
        if !CollectionDataProvider.dataEqual(newData, rhs: data) {
            let consistencyManagerModels = newData.map { model in model as ConsistencyManagerModel }
            let batchModel = BatchUpdateModel(models: consistencyManagerModels)
            listenForUpdates(model: batchModel)

            if !isPaused {
                dataHolder.setData(newData, changeTime: ChangeTime())
                updateDelegatesWithChange(.reset, context: context)
            } else {
                lastPausedContext = context
            }
        }
    }

    func insertAny(_ newData: [Any], at index: Int, context: Any?) {
        guard let newData: [T] = SharedCollectionManager.genericArrayFromArray(newData) else {
            return
        }

        if newData.count > 0 {
            let consistencyManagerModels = newData.map { model in model as ConsistencyManagerModel }
            let batchModel = BatchUpdateModel(models: consistencyManagerModels)
            listenForUpdates(model: batchModel)

            if !isPaused {
                // Index must be within range
                // data.count is ok because it will insert at the end
                if index > data.count || index < 0 {
                    Log.sharedInstance.assert(false, "Index out of bounds on shared collection. This means something has gotten out of sync and something has gone wrong. Make sure you are only accessing CollectionDataProviders on the main thread. If you cannot find the problem, please file a bug.")
                    return
                }

                var updatedData = data
                updatedData.insert(contentsOf: newData, at: index)
                dataHolder.setData(updatedData, changeTime: ChangeTime())

                // This should create an array of indexes starting at the insert point
                // e.g. start with [x,y] insert two elements at index 1
                // Should return [1, 2]
                let changes = newData.enumerated().map { (elementIndex, _) in
                    return CollectionChangeInformation.insert(index: elementIndex + index)
                }
                updateDelegatesWithChange(.changes(changes), context: context)
            } else {
                lastPausedContext = context
            }
        }
    }

    func updateAny(_ element: Any, at index: Int, context: Any?) {
        guard let element = element as? T else {
            Log.sharedInstance.assert(false, "Unable to cast update element to T. This means you are trying to share two collections which have different models. You can only share collections of the same type.")
            return
        }

        listenForUpdates(model: element)

        if !isPaused {
            if index >= data.count || index < 0 {
                Log.sharedInstance.assert(false, "Index out of bounds on shared collection. This means something has gotten out of sync and something has gone wrong. Make sure you are only accessing CollectionDataProviders on the main thread. If you cannot find the problem, please file a bug.")
                return
            }

            var updatedData = data
            updatedData[index] = element
            dataHolder.setData(updatedData, changeTime: ChangeTime())

            updateDelegatesWithChange(.changes([.update(index: index)]), context: context)
        } else {
            lastPausedContext = context
        }
    }

    func removeAnyAtIndex(_ index: Int, context: Any?) {
        if !isPaused {
            if index >= data.count || index < 0 {
                Log.sharedInstance.assert(false, "Index out of bounds on shared collection. This means something has gotten out of sync and something has gone wrong. Make sure you are only accessing CollectionDataProviders on the main thread. If you cannot find the problem, please file a bug.")
                return
            }

            var updatedData = data
            updatedData.remove(at: index)
            dataHolder.setData(updatedData, changeTime: ChangeTime())

            updateDelegatesWithChange(.changes([.delete(index: index)]), context: context)
        } else {
            lastPausedContext = context
        }
    }

    func updateDelegatesWithChange(_ change: CollectionChange, context: Any?) {
        delegate?.collectionDataProviderHasUpdatedData(self, collectionChanges: change, context: context)
        // Since the change doesn't go through the consistency manager, we need to manually notify our batch listener
        if let batchListener = batchListener {
            batchListener.delegate?.batchDataProviderListener(batchListener, hasUpdatedDataProviders: [self], context: context)
        }
    }

    /**
     This is a helper method which checks two arrays of T for equality.
     It simply iterates over the array and checks that the elements return true for isEqualToModel.
     */
    static func dataEqual(_ lhs: [T], rhs: [T]) -> Bool {
        if lhs.count != rhs.count {
            return false
        }
        for index in 0..<lhs.count {
            if !lhs[index].isEqualToModel(rhs[index]) {
                return false
            }
        }
        return true
    }
}
