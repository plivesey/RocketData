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
 This class implements a data provider for a single model.
 */
open class DataProvider<T: SimpleModel>: ConsistencyManagerListener, BatchListenable, ConsistencyManagerUpdatesListener {

    // MARK: - Public instance variables

    /// The data that's backed by this data provider
    open var data: T? {
        get {
            return dataHolder.data
        }
    }

    /// Delegate which is notified of changes to the data.
    open weak var delegate: DataProviderDelegate?

    /// The data model manager which is backing this DataProvider
    public let dataModelManager: DataModelManager

    /**
     You can set this variable to pause and unpause listening for changes to data.
     After setting paused to true, the data in the data provider will not change unless you call setData explicitly.
     Any changes from the data model manager will be ignored until unpause.

     You should not call this if you are batch listening for changes.
     Instead, you should call pauseListeningForChanges() on the batch listener.

     When you resume listening to changes (setting paused to false), if there have been changes since the data provider was paused, the DataProviderDelegate will be called and the model will be updated.
     */
    open var isPaused: Bool {
        get {
            return dataModelManager.consistencyManager.isListenerPaused(self)
        }
        set {
            Log.sharedInstance.assert(batchListener == nil, "You should not manually set paused if you are using a batch listener. Instead, you should use the paused variable on batch listener.")
            if newValue {
                dataModelManager.consistencyManager.pauseListener(self)
            } else {
                dataModelManager.consistencyManager.resumeListener(self)
            }
        }
    }

    /**
     This property returns the model identifier which is associated with this `DataProvider`.
     It either returns the id of the data currently set, or an id that it's listening to (if the model doesn't exist yet).
     If you don't have a model yet, but want to listen to a model which may exist in the future, you can set
     this property to an ID.
     You should NOT do this if you have already set data (this will throw an assertion).
     After setting this property, if the model is updated elsewhere, the delegate will be called and the new model will be set.
     */
    open var modelIdentifier: String? {
        get {
            if let data = data {
                return data.modelIdentifier
            } else {
                return listeningToModelIdentifier
            }
        }
        set {
            guard data == nil else {
                Log.sharedInstance.assert(false, "You should not manually set the model identifier when you already have a model.")
                return
            }
            listeningToModelIdentifier = newValue
            if newValue != nil {
                // If we start listening to a new ID, we need to add ourselves as a global listener
                dataModelManager.consistencyManager.addModelUpdatesListener(self)
            }
        }
    }

    /// This saves the batchListener instance. It is public because it implements the BatchListenable protocol. You should never edit this directly.
    open weak var batchListener: BatchDataProviderListener?

    // MARK: - Private instance variables

    /// This wraps the data with a lastUpdated ChangeTime and makes sure the data is never changed without updating the ChangeTime
    var dataHolder = DataHolder<T?>(data: nil) {
        didSet {
            if dataHolder.data != nil && listeningToModelIdentifier != nil {
                // If we set new data, let's erase the ID we're listening to and stop listening to updates
                listeningToModelIdentifier = nil
                dataModelManager.consistencyManager.removeModelUpdatesListener(self)
            }
        }
    }

    /**
     This is the internal storage for the ID we are listening to.
     If `data` is not nil, this should be nil.
     */
    private var listeningToModelIdentifier: String?

    /// This is updated whenever we set data. In some circumstances, we want to check that our new update is newer than our current model.
    open var lastUpdated: ChangeTime {
        return dataHolder.lastUpdated
    }

    // MARK: - Initializers

    public init(dataModelManager: DataModelManager) {
        self.dataModelManager = dataModelManager
    }

    // MARK: - Public methods

    /**
     Use this method to set new data on the data provider. This will update the cache and start maintaining consistency on this model.
     
     - parameter data: The new data to set on the provider.
     If you pass in nil, it will set nil on the data provider, but won't delete the model from the system.
     - parameter updateCache: Default true. If true, this change will be forwarded to the cache.
     - parameter context: Default nil. The cache delegate has a context parameter. Whatever you pass to this function will be forwarded to that cache delegate.
     This is useful to pass on additional information you want to associate with this model such as alternate cache keys (e.g. URL), associated data,
     or anything else you want.
    */
    open func setData(_ data: T?, updateCache: Bool = true, context: Any? = nil) {
        let isSuccess = self.dataHolder.setData(data, changeTime: ChangeTime())
        if !isSuccess {
            return
        }
        
        if let data = data {
            if let cacheKey = data.modelIdentifier , updateCache {
                dataModelManager.cacheModel(data, forKey: cacheKey, context: context)
            }
            // These need to be called every time the model changes
            dataModelManager.consistencyManager.updateModel(data, context: ConsistencyContextWrapper(context: context))
            listenForUpdates()
        }
    }

    /**
     Fetches a model from the cache.
     It will only fetch from the cache and set the model if data is nil.
     This is because if we have data, it should be identical to the cached data so fetching from the cache is pointless.

     - parameter cacheKey: The cache key for this model.
     - parameter context: This context is passed to the cacheDelegate when making the query. Default nil.
     - parameter completion: Called on the main thread. This is called with the result from the cache.
     At this point, the data provider will already have new data, so there's no need to call setData.
     This completion block will always be called exactly once, even if no data was updated.

     TODO: Once we do a major version bump, remove this method and use the other method with an optional parameter.
     */
    open func fetchDataFromCache(withCacheKey cacheKey: String?, context: Any? = nil, completion: @escaping (T?, NSError?)->()) {

        if cacheKey != nil && cacheKey == data?.modelIdentifier {
            // If the cacheKey is the same as what we currently have, there's no point in fetching again from the cache
            // Our 'cached' model is already in memory and is our current model, so let's return it
            completion(data, nil)
            return
        }

        let cacheFetchDate = ChangeTime()
        
        dataModelManager.modelFromCache(cacheKey, context: context) { (model: T?, error) in

            // If our fetch occurred before we set new data on the data provider we want to discard this cached data because we assume the new data is fresher
            let cacheDataFresh = cacheFetchDate.after(self.lastUpdated)

            if cacheDataFresh {
                if let model = model {
                    let isSuccess = self.dataHolder.setData(model, changeTime: ChangeTime())
                    if !isSuccess {
                        return
                    }
                    
                    self.listenForUpdates()
                }
                completion(model, error)
            } else {
                // Our 'cached' model is already in memory and is our current model, so let's return it
                completion(self.data, nil)
            }
        }
    }
    
    /**
     Fetches a model from the cache.
     It will only fetch from the cache and set the model if data is nil.
     This is because if we have data, it should be identical to the cached data so fetching from the cache is pointless.
     
     - parameter cacheKey: The cache key for this model.
     - parameter listenToModelIdentifier: If true, then the data provider will start listening to this cache key
     even if the cache misses. This means if the cache misses, but then the model is added to the cache later,
     the data provider will get that new data.
     - parameter context: This context is passed to the cacheDelegate when making the query. Default nil.
     - parameter completion: Called on the main thread. This is called with the result from the cache.
     At this point, the data provider will already have new data, so there's no need to call setData.
     This completion block will always be called exactly once, even if no data was updated.
     */
    open func fetchDataFromCache(withCacheKey cacheKey: String?, listenToModelIdentifier: Bool, context: Any? = nil, completion: @escaping (T?, NSError?)->()) {
        fetchDataFromCache(withCacheKey: cacheKey, context: context) { model, error in
            if self.data == nil && model == nil && listenToModelIdentifier {
                // Only if our current data is nil and the cache missed should we start listening to this ID
                self.modelIdentifier = cacheKey
            }
            completion(model, error)
        }
    }
    
    // MARK: Helpers
    
    /**
     Call this whenever a new model is changed internally. This is done on setting data and fetching data.
     */
    func listenForUpdates() {
        if let batchListener = batchListener {
            batchListener.listenerHasUpdatedModel(self)
        } else {
            dataModelManager.consistencyManager.addListener(self)
        }
    }

    /**
     Given a context, it assumes it is a ConsistencyContextWrapper.
     It then unwraps a change time and actual context form this object with defaults.
     It uses nil as a sentinal value to signify that this operation should be discarded (the change time is out of date).
     */
    func changeTimeAndContext(fromContext context: Any?) -> (changeTime: ChangeTime, actualContext: Any?)? {
        let actualContext: Any?
        let changeTime: ChangeTime
        if let context = context as? ConsistencyContextWrapper {
            if !context.creationDate.after(lastUpdated) {
                // Our current data is newer than this change so let's discard this change.
                return nil
            }
            actualContext = context.context
            changeTime = context.creationDate
        } else {
            // The change came from a manual change to the consistency manager so we don't have time information
            // This isn't preferable, but let's assume that we actually want this change
            actualContext = context
            changeTime = ChangeTime()
        }

        return (changeTime, actualContext)
    }

    // MARK: Consistency Manager Implementation

    open func currentModel() -> ConsistencyManagerModel? {
        return data
    }

    open func modelUpdated(_ model: ConsistencyManagerModel?, updates: ModelUpdates, context: Any?) {
        guard let (changeTime, actualContext) = changeTimeAndContext(fromContext: context) else {
            // This signifies that this change should be discarded because it's out of date
            return
        }

        // Here, we are casting to T? so we catch nil. If the model is nil, it means it was deleted, so we should set data to nil
        if let model = model as? T? {
            // It will already have been updated in the cache so we don't need to recache it
            // We are also already listening to the new model so don't need to call listenForUpdates again
            // If we updated ourselves through Rocket Data, we'll always have a ChangeTime. Otherwise, let's use now.
            dataHolder.setData(model, changeTime: changeTime)
            delegate?.dataProviderHasUpdatedData(self, context: actualContext)
        } else {
            Log.sharedInstance.assert(false, "Consistency manager returned an incorrect model type. It looks like we have duplicate ids for different classes. This is not allowed because models must have globally unique identifiers.")
        }
    }
    
    open func consistencyManager(_ consistencyManager: ConsistencyManager,
                            updatedModel model: ConsistencyManagerModel,
                            changes: [String: ModelChange],
                            context: Any?) {
        // We only care about changes if we have a modelId and data is nil
        if let modelId = listeningToModelIdentifier, data == nil {
            // Let's see if we care about any of these changes
            if let modelChange = changes[modelId] {
                // We only care if the model is updated. If it's deleted, we ignore it and still keep listening
                if case ModelChange.updated(let models) = modelChange {
                    models.forEach { newModel in
                        // There may be multiple projections here. Let's search for one of the right class.
                        if let newModel = newModel as? T {
                            guard let (changeTime, actualContext) = changeTimeAndContext(fromContext: context) else {
                                // This signifies that this change should be discarded because it's out of date
                                return
                            }
                            dataHolder.setData(newModel, changeTime: changeTime)
                            delegate?.dataProviderHasUpdatedData(self, context: actualContext)
                        }
                    }
                }
                
            }
        } else {
            // Otherwise, let's stop listening because we don't care anymore
            dataModelManager.consistencyManager.removeModelUpdatesListener(self)
        }
    }

    // MARK: BatchListener Implementation

    open func batchDataProviderUnpausedDataProvider() {
        // We don't need to do anything special here
        // We'll just wait for the consistency manager to update us
    }

    open func syncedWithContext(_ context: Any?) -> Bool {
        if let context = context as? ConsistencyContextWrapper {
            return lastUpdated == context.creationDate
        }
        // Default to true so we're not ignored in the updates list
        return true
    }
}

/**
 This protocol defines a delegate for the DataProvider.
*/
public protocol DataProviderDelegate: class {
    /**
     This delegate method is called whenever we get an update from the consistency manager that our model has changed and we need to refresh.
     For example, if someone else sets data with the same ID as this data, then this data will get updated if it has changed.
     It will only be called when the method has actually changed.
     
     - paramter dataProvider: The data provider which has changed. If you have multiple data providers, you can use === to determine which one has changed.
     - paramter context: Whenever you make a change to a model, you can pass in a context. This context will be passed back to you here.
    */
    func dataProviderHasUpdatedData<T>(_ dataProvider: DataProvider<T>, context: Any?)
}
