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
open class DataProvider<T: SimpleModel>: ConsistencyManagerListener, BatchListenable {

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
    open let dataModelManager: DataModelManager

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

    /// This saves the batchListener instance. It is public because it implements the BatchListenable protocol. You should never edit this directly.
    open weak var batchListener: BatchDataProviderListener?

    // MARK: - Private instance variables

    /// This wraps the data with a lastUpdated ChangeTime and makes sure the data is never changed without updating the ChangeTime
    var dataHolder = DataHolder<T?>(data: nil)

    /// This is updated whenever we set data. In some circumstances, we want to check that our new update is newer than our current model.
    var lastUpdated: ChangeTime {
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
        self.dataHolder.setData(data, changeTime: ChangeTime())
        if let data = data {
            if let cacheKey = data.modelIdentifier , updateCache {
                dataModelManager.cacheModel(data, forKey: cacheKey, context: context)
            }
            // These need to be called every time the model changes
            dataModelManager.consistencyManager.updateModel(data, context: ConsistencyContextWrapper(context: context))
            if let batchListener = batchListener {
                batchListener.listenerHasUpdatedModel(self)
            } else {
                dataModelManager.consistencyManager.addListener(self)
            }
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
                    self.dataHolder.setData(model, changeTime: ChangeTime())
                }
                completion(model, error)
            } else {
                // Our 'cached' model is already in memory and is our current model, so let's return it
                completion(self.data, nil)
            }
        }
    }

    // MARK: Consistency Manager Implementation

    open func currentModel() -> ConsistencyManagerModel? {
        return data
    }

    open func modelUpdated(_ model: ConsistencyManagerModel?, updates: ModelUpdates, context: Any?) {
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

        // Here, we are casting to T? so we catch nil. If the model is nil, it means it was deleted, so we should set data to nil
        if let model = model as? T? {
            // It will already have been updated in the cache so we don't need to recache it
            // We are also already listening to the new model so don't need to call listenForUpdates again
            // If we updated ourselves through Rocket Data, we'll always have a ChangeTime. Otherwise, let's use now.
            dataHolder.setData(model, changeTime: changeTime ?? ChangeTime())
            delegate?.dataProviderHasUpdatedData(self, context: actualContext)
        } else {
            Log.sharedInstance.assert(false, "Consistency manager returned an incorrect model type. It looks like we have duplicate ids for different classes. This is not allowed because models must have globally unique identifiers.")
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
