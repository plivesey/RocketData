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
 This class implements a data provider for a collection (array) of data. Each individual model will be kept consistent with other models in the system.
*/
open class CollectionDataProvider<T: SimpleModel>: ConsistencyManagerListener, BatchListenable {

    // MARK: - Public instance variables

    /// The data for this data provider
    open var data: [T] {
        get {
            return dataHolder.data
        }
    }

    /**
     Returns the number of elements in the collection.
     Convenience method: equivalent to collectionDataProvider.data.count
     */
    open var count: Int {
        return data.count
    }

    /// Delegate which is notified of changes to the data.
    open weak var delegate: CollectionDataProviderDelegate?

    /// The cache key which backs this collection. If nil, the collection will not be cached.
    open private(set) var cacheKey: String? {
        didSet {
            dataModelManager.sharedCollectionManager.updateProvider(self, cacheKey: cacheKey, previousCacheKey: oldValue)
        }
    }

    /// The DataModelManager which backs this data provider.
    open let dataModelManager: DataModelManager

    /// This saves the batchListener instance. It is public because it implements the BatchListenable protocol. You should never edit this directly.
    open weak var batchListener: BatchDataProviderListener?

    /**
     You can set this variable to pause and unpause listening for changes to data.
     After setting paused to true, the data in the data provider will not change unless you call setData explicitly.
     Any changes from the data model manager will be ignored until unpause.

     You should not call this if you are batch listening for changes.
     Instead, you should call pauseListeningForChanges() on the batch listener.

     When you resume listening to changes (setting paused to false), if there have been changes since the data provider was paused, the DataProviderDelegate will be called and the model will be updated.
     However, the changes object you get back for these changes is likely to just be a `CollectionChange.reset` object.
     Since changes can come from multiple places in different orders, it's very difficult to guarantee these will be in the correct order.
     So, for unpausing, if we do not know what to use, we will simply use `.reset`.
     */
    open var isPaused: Bool {
        get {
            if let batchListener = batchListener {
                return batchListener.isPaused
            } else {
                return dataModelManager.consistencyManager.isListenerPaused(self)
            }
        }
        set {
            Log.sharedInstance.assert(batchListener == nil, "You should not manually set paused on the collection data provider if you are using a batch listener. Instead, you should use the paused variable on batch listener.")
            if newValue {
                dataModelManager.consistencyManager.pauseListener(self)
            } else {
                dataModelManager.consistencyManager.resumeListener(self)
                syncWithSiblingDataProviders()
            }
        }
    }

    // MARK: - Private instance variables

    var dataHolder = DataHolder<[T]>(data: [])

    /// This is updated whenever we set data. In some circumstances, we want to check that our new update is newer than our current model.
    var lastUpdated: ChangeTime {
        return dataHolder.lastUpdated
    }

    /// When in a paused state, this keeps track of the last context for an update.
    /// When unpausing, this will be returned as the context for changes.
    var lastPausedContext: Any?

    // MARK: - Initializers

    /**
     Initializer.

     - parameter dataModelManager: The DataModelManager to use with this data provider.
     */
    public init(dataModelManager: DataModelManager) {
        self.dataModelManager = dataModelManager
    }

    // MARK: - Public methods

    /**
     Getter for models in the collection. If the index is out of bounds, it will return an error.
     Convenience method: equivalent to collectionDataProvider.data[index]
     */
    open subscript(index: Int) -> T {
        get {
            return data[index]
        }
    }

    /**
     Sets new data on the data provider.
     This will update the cache and start maintaining consistency on the model. It will also cause any other data providers which rely on this data to update.
     The entire collection is replaced.

     - parameter data: The new data to set on the provider.
     - parameter cacheKey: The key to cache this collection. If nil, this collection won't be cached. Often, you should just pass in `dataProvider.cacheKey` here if you don't want the cacheKey to change.
     - parameter shouldCache: If false, we will not persist this to the cache even if cacheKey is not nil.
     - parameter context: Default nil. The cache delegate has a context parameter. Whatever you pass to this function will be forwarded to that cache delegate.
     This is useful to pass on additional information you want to associate with this model such as alternate cache keys (e.g. URL), associated data, or
     anything else you want.
     */
    open func setData(_ data: [T], cacheKey: String?, shouldCache: Bool = true, context: Any? = nil) {
        self.dataHolder.setData(data, changeTime: ChangeTime())
        self.cacheKey = cacheKey
        if shouldCache, let cacheKey = cacheKey {
            dataModelManager.cacheCollection(data, forKey: cacheKey, context: context)
        }

        updateAndListenToNewModelsInConsistencyManager(context: context)
        // Update all shared collections
        if let cacheKey = cacheKey {
            dataModelManager.sharedCollectionManager.siblingProvidersForProvider(self, cacheKey: cacheKey).forEach { provider in
                provider.setAnyData(anyData, context: context)
            }
        }
    }

    /**
     Fetches the collection from the cache. This uses the cacheKey passed in when creating the data provider.
     It will only fetch from the cache and set the model once.
     This is because if we have data, it should be identical to the cached data so fetching from the cache is pointless.
     Either fetching data or manually setting data will cause this to be a no-op.

     - parameter cacheKey: The cache key to use to fetch the item. Can be nil (it will still attempt a cache lookup using the context).
     Setting this will reset the cache key of this data provider.
     - parameter context: Default nil. This context is passed to the cacheDelegate when making the query.
     - parameter completion: Called on the main thread. This is called with the result from the cache.
     At this point, the data provider will already have new data, so there's no need to call setData.
    */
    open func fetchDataFromCache(withCacheKey cacheKey: String?, context: Any? = nil, completion: @escaping ([T]?, NSError?)->()) {

        guard cacheKey != self.cacheKey else {
            // If the cacheKey is the same as what we currently have, there's no point in fetching again from the cache
            // Our 'cached' model is already in memory and is our current model, so let's return it
            completion(data, nil)
            return
        }

        // Let's try to retrieve the data from a sibling provider
        // This will be faster and help ensure consistency
        if let cacheKey = cacheKey,
            let data: DataHolder<[T]> = dataModelManager.sharedCollectionManager.dataFromProviders(cacheKey: cacheKey) {
                self.dataHolder = data
                self.listenForUpdates()
                self.cacheKey = cacheKey
                completion(data.data, nil)
        } else {
            let cacheFetchDate = ChangeTime()

            dataModelManager.collectionFromCache(cacheKey, context: context) { (collection: [T]?, error) in
                // While we were fetching from the cache, we may have gotten data in a sibling provider
                // Let's check again because otherwise, we may get out of sync
                if let cacheKey = cacheKey,
                    let data: DataHolder<[T]> = self.dataModelManager.sharedCollectionManager.dataFromProviders(cacheKey: cacheKey) {
                        self.dataHolder = data
                        self.listenForUpdates()
                        self.cacheKey = cacheKey
                        completion(data.data, nil)
                } else {
                    // If we've updated the data since we initialzed the cache fetch we want to discard this request
                    // In this case, the cached data is staler than our current data
                    // If we have no last updated variable, then it means the cached data isn't stale
                    let cacheDataFresh = cacheFetchDate.after(self.lastUpdated)

                    if cacheKey != self.cacheKey && cacheDataFresh {
                        if let collection = collection {
                            self.dataHolder.setData(collection, changeTime: ChangeTime())
                            self.listenForUpdates()
                            self.cacheKey = cacheKey
                        }
                        completion(collection, error)
                    } else {
                        // Our current data is the most up to date, so we should return that as the result of the cache lookup
                        completion(self.data, nil)
                    }
                }
            }
        }
    }

    /**
     Insert an array of data into the collection. This will trigger a cache update.

     - parameter data: The data to insert.
     - parameter index: The index to insert the data at. If you want to insert it at the end, pass in the count of the current collection. If this index is out
     of bounds an exception will be thrown and the code will crash.
     - parameter shouldCache: If false, we will not persist this to the cache.
     - parameter context: This context will be passed onto the cache delegate. Default nil.
    */
    open func insert(_ newData: [T], at index: Int, shouldCache: Bool = true, context: Any? = nil) {
        if newData.count > 0 {
            var updatedData = data
            updatedData.insert(contentsOf: newData, at: index)
            dataHolder.setData(updatedData, changeTime: ChangeTime())

            if shouldCache, let cacheKey = cacheKey {
                dataModelManager.cacheCollection(data, forKey: cacheKey, context: context)
            }

            // Update all shared collections
            if let cacheKey = cacheKey {
                let anyData = newData.map { $0 as Any }
                dataModelManager.sharedCollectionManager.siblingProvidersForProvider(self, cacheKey: cacheKey).forEach { provider in
                    provider.insertAny(anyData, at: index, context: context)
                }
            }

            // First, we want to make sure we update the consistency manager after we've updated all the other data providers so we're in sync.
            // Next, we actually need to do two things:
            // - Update the whole collection. This will actually only affect paused collections because all the other collections were updated above.
            // - Update all the new models. This will update all the models individually and possibly cause other rows in the current collection to update.
            updateAndListenToNewModelsInConsistencyManager(context: context)
            // NOTE: No cache key here, because this is just updating all the new models
            let newModelsBatchModel = batchModelFromModels(newData, cacheKey: nil)
            dataModelManager.consistencyManager.updateModel(newModelsBatchModel, context: ConsistencyContextWrapper(context: context))
        }
    }

    /**
     Append array of data into the collection. This will trigger a cache update.

     - parameter data: The data to insert.
     - parameter shouldCache: If false, we will not persist this to the cache.
     - parameter context: Default nil. This context will be passed onto the cache delegate.
     */
    open func append(_ newData: [T], shouldCache: Bool = true, context: Any? = nil) {
        insert(newData, at: data.count, shouldCache: shouldCache, context: context)
    }

    /**
     Update an element at a certain index. This will trigger a cache update.
     
     - parameter element: The updated element.
     - parameter index: The index to update the element. If this index is out of bounds an exception will be thrown and the code will crash.
     - parameter shouldCache: If false, we will not persist this to the cache.
     - parameter context: This context will be passed onto the cache delegate. Default nil.
     */
    open func update(_ element: T, at index: Int, shouldCache: Bool = true, context: Any? = nil) {
        var updatedData = data
        updatedData[index] = element
        dataHolder.setData(updatedData, changeTime: ChangeTime())

        if shouldCache, let cacheKey = cacheKey {
            self.dataModelManager.cacheCollection(data, forKey: cacheKey, context: context)
        }

        // Update all shared collections
        if let cacheKey = cacheKey {
            dataModelManager.sharedCollectionManager.siblingProvidersForProvider(self, cacheKey: cacheKey).forEach { provider in
                provider.updateAny(element, at: index, context: context)
            }
        }

        // First, we want to make sure we update the consistency manager after we've updated all the other data providers so we're in sync.
        // Next, we actually need to do two things:
        // - Update the whole collection. This will actually only affect paused collections because all the other collections were updated above.
        // - Update the new model. This will possibly cause other rows in the current collection to update.
        updateAndListenToNewModelsInConsistencyManager(context: context)
        dataModelManager.consistencyManager.updateModel(element, context: ConsistencyContextWrapper(context: context))
    }

    /**
     Remove an element at a certain index. This will trigger a cache update.

     - parameter index: The index to update the element. If this index is out of bounds an exception will be thrown and the code will crash.
     - parameter shouldCache: If false, we will not persist this to the cache.
     - parameter context: This context will be passed onto the cache delegate. Default nil.
     */
    open func remove(at index: Int, shouldCache: Bool = true, context: Any? = nil) {
        var updatedData = data
        updatedData.remove(at: index)
        dataHolder.setData(updatedData, changeTime: ChangeTime())

        if shouldCache, let cacheKey = cacheKey {
            dataModelManager.cacheCollection(data, forKey: cacheKey, context: context)
        }

        // No need to relisten because we know we don't have any new models
        // Any updates to the removed model will be ignored automatically
        updateAndListenToNewModelsInConsistencyManager(context: context, shouldListen: false)

        // Update all shared collections
        if let cacheKey = cacheKey {
            dataModelManager.sharedCollectionManager.siblingProvidersForProvider(self, cacheKey: cacheKey).forEach { provider in
                provider.removeAnyAtIndex(index, context: context)
            }
        }
    }

    // MARK: Class Methods

    /**
    This is similar to the setData instance method, but allows you to set data on a certain cacheKey without having an instance of a CollectionDataProvider.
    This method will update any data providers using the same cache key and propegates this change to the cache.

    - parameter data: The new data to set.
    - parameter cacheKey: The cache key for this data.
    - parameter dataModelManager: The data model manager to associate with this change.
    - parameter context: This context will be passed onto the cache delegate. Default nil.
    */
    open static func setData(_ data: [T], cacheKey: String, dataModelManager: DataModelManager, context: Any? = nil) {
        let collectionDataProvider = CollectionDataProvider<T>(dataModelManager: dataModelManager)
        collectionDataProvider.setData(data, cacheKey: cacheKey, context: context)
    }

    /**
     This is similar to the insert instance method, but allows you to insert data on a certain cacheKey without having an instance of a CollectionDataProvider.
     First, it loads data from the cache or another shared data provider (if one is in memory).
     Then, it calls the index closure with this data and requests the index to insert.
     This method will update any data providers using the same cache key and propegates this change to the cache.

     - parameter newData: The new data to set.
     - parameter index: A closure to specify the index given the current data in the collection.
     It does not do any bounds checking on this index, so if you need to, you should implement that here.
     - parameter cacheKey: The cache key for this data.
     - parameter dataModelManager: The data model manager to associate with this change.
     - parameter context: This context will be passed onto the cache delegate. Default nil.
     - parameter completion: This completion block is called when the insert has succeeded (but the data may not yet be propegated to the cache).
     If there is no data in the cache for this cacheKey, it will return an error as the insert has failed. Default nil.
     */
    open static func insert(_ newData: [T], at index: @escaping (([T])->Int), cacheKey: String, dataModelManager: DataModelManager, context: Any? = nil, completion: ((NSError?)->())? = nil) {
        let collectionDataProvider = CollectionDataProvider<T>(dataModelManager: dataModelManager)
        collectionDataProvider.fetchDataFromCache(withCacheKey: cacheKey) { cachedData, error in
            if let cachedData = cachedData {
                collectionDataProvider.insert(newData, at: index(cachedData), context: context)
            }
            completion?(error)
        }
    }

    /**
     This is similar to the append instance method, but allows you to append data on a certain cacheKey without having an instance of a CollectionDataProvider.
     First, it loads data from the cache or another shared data provider (if one is in memory).
     Then, it appends to this data.
     This method will update any data providers using the same cache key and propegates this change to the cache.

     - parameter newData: The new data to append.
     - parameter cacheKey: The cache key for this data.
     - parameter dataModelManager: The data model manager to associate with this change.
     - parameter context: This context will be passed onto the cache delegate. Default nil.
     - parameter completion: This completion block is called when the insert has succeeded (but the data may not yet be propegated to the cache).
     If there is no data in the cache for this cacheKey, it will return an error as the insert has failed. Default nil.
     */
    open static func append(_ newData: [T], cacheKey: String, dataModelManager: DataModelManager, context: Any? = nil, completion: ((NSError?)->())? = nil) {
        let collectionDataProvider = CollectionDataProvider<T>(dataModelManager: dataModelManager)
        collectionDataProvider.fetchDataFromCache(withCacheKey: cacheKey) { cachedData, error in
            collectionDataProvider.append(newData, context: context)
            completion?(error)
        }
    }

    /**
     This is similar to the update instance method, but allows you to update data on a certain cacheKey without having an instance of a CollectionDataProvider.
     First, it loads data from the cache or another shared data provider (if one is in memory).
     Then, it calls the index closure with this data and requests the index to update.
     This method will update any data providers using the same cache key and propegates this change to the cache.

     - parameter element: The model to update.
     - parameter index: A closure to specify the index given the current data in the collection.
     It does not do any bounds checking on this index, so if you need to, you should implement that here.
     - parameter cacheKey: The cache key for this data.
     - parameter dataModelManager: The data model manager to associate with this change.
     - parameter context: This context will be passed onto the cache delegate. Default nil.
     - parameter completion: This completion block is called when the insert has succeeded (but the data may not yet be propegated to the cache).
     If there is no data in the cache for this cacheKey, it will return an error as the insert has failed. Default nil.
     */
    open static func update(_ element: T, at index: @escaping (([T])->Int), cacheKey: String, dataModelManager: DataModelManager, context: Any? = nil, completion: ((NSError?)->())? = nil) {
        let collectionDataProvider = CollectionDataProvider<T>(dataModelManager: dataModelManager)
        collectionDataProvider.fetchDataFromCache(withCacheKey: cacheKey) { cachedData, error in
            if let cachedData = cachedData {
                collectionDataProvider.update(element, at: index(cachedData), context: context)
            }
            completion?(error)
        }
    }

    /**
     This is similar to the removeAtIndex instance method, but allows you to remove an element from data on a certain cacheKey without having an instance of a CollectionDataProvider.
     First, it loads data from the cache or another shared data provider (if one is in memory).
     Then, it calls the index closure with this data and requests the index to remove.
     This method will update any data providers using the same cache key and propegates this change to the cache.

     - parameter index: A closure to specify the index given the current data in the collection.
     It does not do any bounds checking on this index, so if you need to, you should implement that here.
     - parameter cacheKey: The cache key for this data.
     - parameter dataModelManager: The data model manager to associate with this change.
     - parameter context: This context will be passed onto the cache delegate. Default nil.
     - parameter completion: This completion block is called when the insert has succeeded (but the data may not yet be propegated to the cache).
     If there is no data in the cache for this cacheKey, it will return an error as the insert has failed. Default nil.
     */
    open static func removeAtIndex(_ index: @escaping (([T])->Int), cacheKey: String, dataModelManager: DataModelManager, context: Any? = nil, completion: ((NSError?)->())? = nil) {
        let collectionDataProvider = CollectionDataProvider<T>(dataModelManager: dataModelManager)
        collectionDataProvider.fetchDataFromCache(withCacheKey: cacheKey) { cachedData, error in
            if let cachedData = cachedData {
                collectionDataProvider.remove(at: index(cachedData), context: context)
            }
            completion?(error)
        }
    }

    // MARK: Batch Listenable

    open func batchDataProviderUnpausedDataProvider() {
        syncWithSiblingDataProviders()
    }

    open func syncedWithContext(_ context: Any?) -> Bool {
        if let context = context as? ConsistencyContextWrapper {
            return lastUpdated == context.creationDate
        }
        // Default to true so we're not ignored in the updates list
        return true
    }

    // MARK: Consistency Manager Listener

    open func currentModel() -> ConsistencyManagerModel? {
        // We will listen to a batch model with all of our submodels
        return BatchUpdateModel(models: data.map { model in model as ConsistencyManagerModel }, modelIdentifier: cacheKey)
    }

    open func modelUpdated(_ model: ConsistencyManagerModel?, updates: ModelUpdates, context: Any?) {
        guard let model = model as? BatchUpdateModel else {
            Log.sharedInstance.assert(false, "CollectionDataProvider got called with the wrong model type. This should never happen.")
            return
        }

        let actualContext: Any?
        var changeTime: ChangeTime?
        if let context = context as? ConsistencyContextWrapper {
            if !context.creationDate.after(lastUpdated) {
                // Our current data is newer than this change so let's discard this change.
                return
            }
            actualContext = context.context
            changeTime = context.creationDate
        } else {
            // The change came from a manual change to the consistency manager so we don't have time information
            // This isn't preferable, but let's assume that we actually want this change
            actualContext = context
        }

        // Sadly, optionally casting to [T] doesn't work due to a swift bug (at runtime, accessing the model crashes)
        // So, we're forced to use a map and cast each model individually
        let newData = model.models.flatMap { model -> T? in
            Log.sharedInstance.assert(model is T || model == nil, "CollectionDataProvider found a model which was of the wrong type. This should never happen and indicates a bug in the library.")
            return model as? T
        }

        // Here we are:
        // Enumerating the array so we get indexes
        // Then, reversing the array so that deletes can be applied in order (if you mutate the array while iterating over changes, you should do this in reverse order)
        let collectionChangesInformation = data.enumerated().reversed().flatMap { (index, element) in
            return element.modelIdentifier.flatMap { (identifier) -> CollectionChangeInformation? in
                if updates.deletedModelIds.contains(identifier) {
                    return .delete(index: index)
                } else if updates.changedModelIds.contains(identifier) {
                    return .update(index: index)
                } else {
                    // There was no change to this element, so let's return nil (which means it won't be in collectionChanges)
                    return nil
                }
            }
        }

        var collectionChanges = CollectionChange.changes(collectionChangesInformation)

        if data.count + collectionChangesInformation.deltaNumberOfElements() != newData.count {
            // This sometimes happens when collection methods (like insert/delete) are used while the data provider is paused
            // When coming back from a paused state, there is a different number of elements, but it's difficult to see which are updated/deleted/inserted
            // So, reset is returned
            collectionChanges = .reset
        }

        // If this update came from Rocket Data, change time will not be nil.
        // Otherwise, just use current time.
        dataHolder.setData(newData, changeTime: changeTime ?? ChangeTime())

        delegate?.collectionDataProviderHasUpdatedData(self, collectionChanges: collectionChanges, context: actualContext)
    }

    // MARK: Private Methods

    /**
     Updates an array of models in the consistency manager and relistens to these new models.
     */
    private func updateAndListenToNewModelsInConsistencyManager(context: Any?, shouldListen: Bool = true) {
        let batchModel = batchModelFromModels(data, cacheKey: cacheKey)
        dataModelManager.consistencyManager.updateModel(batchModel, context: ConsistencyContextWrapper(context: context))
        if shouldListen {
            listenForUpdates(model: batchModel)
        }
    }

    /**
     Returns a batch model from an array of models.
     */
    private func batchModelFromModels(_ models: [T], cacheKey: String?) -> BatchUpdateModel {
        // Need to map to do this cast sadly
        let consistencyManagerModels = models.map { model in model as ConsistencyManagerModel }
        return BatchUpdateModel(models: consistencyManagerModels, modelIdentifier: cacheKey)
    }

    /**
     This function takes data from sibling data providers and sets it the current provider. This updates our data to the latest if possible.
     Called whenever the listener is unpaused.
     */
    private func syncWithSiblingDataProviders() {
        var updatedData = false
        // We should immediately set our data to the data of shared collections if possible.
        // We need to do this before we resume listening with the consistency manager.
        if let sharedData: DataHolder<[T]> = cacheKey.flatMap({ self.dataModelManager.sharedCollectionManager.dataFromProviders(cacheKey: $0) }) {
            if !CollectionDataProvider<T>.dataEqual(data, rhs: sharedData.data) {
                updatedData = true
            }
            // Else, we don't need to update our data, but we also have the lastest data.
            // So let's update our data updated time.
            // This will cause us to ignore any consistency manager changes while we were paused.
            // Setting the current data with a change time accomplishes this, so we'll do this either way.
            dataHolder = sharedData
        }

        if updatedData {
            updateDelegatesWithChange(.reset, context: lastPausedContext)
            lastPausedContext = nil
        }
    }

    /**
     Relisten for updates in the consistency manager.
     This is marked as internal so SharedCollectionManager can access this.
     - parameter model: A specific model you want to listen to. If nil, it will listen to the entire model.
     */
    func listenForUpdates(model: ConsistencyManagerModel? = nil) {
        if let batchListener = batchListener {
            if let model = model {
                batchListener.listenerHasUpdatedModel(model)
            } else {
                batchListener.listenerHasUpdatedModel(self)
            }
        } else {
            if let model = model {
                dataModelManager.consistencyManager.addListener(self, to: model)
            } else {
                dataModelManager.consistencyManager.addListener(self)
            }
        }
    }
}

/**
 This protocol defines a delegate for the CollectionDataProvider.
 */
public protocol CollectionDataProviderDelegate: class {
    /**
     This delegate method is called whenever we get an update from the consistency manager that our model has changed and we need to refresh.
     For example, if someone else sets data with the same ID as this data, then this data will get updated if it has changed.
     It will only be called when the data has actually changed.

     - parameter dataProvider: The data provider which has changed. If you have multiple data providers, you can use === to determine which one has changed.
     - parameter collectionChanges: This object contains information about which indexes were inserted/deleted.
     If you access the array of changes, then an ordering of the changes is provided.
     If you iterate over these changes, and apply them in order, you will be deleting/inserting the correct indexes.
     For instance, if index 3 and 5 were deleted, they would be in decreasing order.
     In this way, deleting index 5 does not alter index 3.
     You can use this information to run animations on your data or only update certain rows of the view.
     - parameter context: Whenever you make a change to a model, you can pass in a context. This context will be passed back to you here.
     */
    func collectionDataProviderHasUpdatedData<T>(_ dataProvider: CollectionDataProvider<T>, collectionChanges: CollectionChange, context: Any?)
}
