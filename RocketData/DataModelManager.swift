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
 Class which holds onto the cache delegate and consistency manager. You should only have one of these per application.
 Ideally, you should add an extension which adds a singleton accessor like:

 let sharedInstance = DataModelManager(cacheDelegate: MyCacheDelegate())

 Whenever you initialize a data provider, you need to pass in this shared data model manager. You can add an extension to make this easy. For example:

 extension DataProvider<T> {
    convenience init() {
        self.init(dataModelManager: DataModelManager.sharedInstance)
    }
 }

 All the methods in this class are thread safe.
 */
open class DataModelManager {

    /// Cache Delegate. This is strongly retained since it is required by the library.
    open let cacheDelegate: CacheDelegate

    /// Consistency Manager.
    open let consistencyManager = ConsistencyManager()

    let sharedCollectionManager = SharedCollectionManager()

    /// A queue for doing external requests. This means that if the app blocks on a delegate method for too long, the library and app won't be slowed down.
    let externalDispatchQueue = DispatchQueue(label: "com.rocketData.externalDispatchQueue", attributes: .concurrent)

    public init(cacheDelegate: CacheDelegate) {
        self.cacheDelegate = cacheDelegate
    }

    /**
     This function updates an individual model in the consistency manager and cache.
     This will cause any data providers listening to this model change to update.

     - parameter model: The model you want to update.
     - parameter updateCache: You can pass in false here if you only want to update the models in memory.
     - parameter context: This context will be passed back to data provider delegates if this causes an update.
     */
    open func updateModel(_ model: SimpleModel, updateCache: Bool = true, context: Any? = nil) {
        consistencyManager.updateModel(model, context: ConsistencyContextWrapper(context: context))
        if updateCache, let cacheKey = model.modelIdentifier {
            cacheModel(model, forKey: cacheKey, context: context)
        }
    }

    /**
     This function updates an array of models in the consistency manager and cache.
     This will cause any data providers listening to this model change to update.
     Even if each model causes a different change in the data provider, it will still only receive one delegate callback with all the changes here.
     
     - parameter models: The models you want to update.
     - parameter updateCache: You can pass in false here if you only want to update the models in memory.
     - parameter context: This context will be passed back to data provider delegates if this causes an update.
     */
    open func updateModels(_ models: [SimpleModel], updateCache: Bool = true, context: Any? = nil) {
        let batchModel = BatchUpdateModel(models: models.map { $0 as ConsistencyManagerModel })
        consistencyManager.updateModel(batchModel, context: ConsistencyContextWrapper(context: context))
        if updateCache {
            externalDispatchQueue.async {
                models.forEach { model in
                    if let cacheKey = model.modelIdentifier {
                        self.cacheDelegate.setModel(model, forKey: cacheKey, context: context)
                    }
                }
            }
        }
    }

    /**
     Deletes a model from the system and the cache.
     This will remove the model from all collections and subtrees. The delete may cascade to delete parent models if it's a required field.
     If you want to remove a model from an array or just a single tree, you should call removeAtIndex on the collection or updateModel on the parent.
     
     - parameter model: The model to delete.
     - parameter updateCache: If false, the cache will not be updated.
     - parameter context: The context to pass to the updated data providers and the cache delegate.
     */
    open func deleteModel(_ model: SimpleModel, updateCache: Bool = true, context: Any? = nil) {
        let modelIdentifier = model.modelIdentifier
        if modelIdentifier != nil {
            // This will be a no-op if you try to delete something without an id
            consistencyManager.deleteModel(model, context: ConsistencyContextWrapper(context: context))
        }
        if updateCache {
            (externalDispatchQueue).async {
                self.cacheDelegate.deleteModel(model, forKey: modelIdentifier, context: context)
            }
        }
    }

    /**
     Save a model in the cache. This simply forwards the method to the cache delegate.
     The cache key you pass in here should be equal to the modelIdentifier of the model.
     */
    open func cacheModel(_ model: SimpleModel, forKey cacheKey: String, context: Any?) {
        externalDispatchQueue.async {
            self.cacheDelegate.setModel(model, forKey: cacheKey, context: context)
        }
    }

    /**
     Get a model from the cache. This simply forwards the method to the cache delegate.
     */
    open func modelFromCache<T: SimpleModel>(_ cacheKey: String?, context: Any?, completion: @escaping (T?, NSError?)->()) {
        externalDispatchQueue.async {
            self.cacheDelegate.modelForKey(cacheKey, context: context) { (model: T?, error) in
                DispatchQueue.main.async {
                    completion(model, error)
                }
            }
        }
    }

    /**
     Save a collection model in the cache. This simply forwards the method to the cache delegate.
     */
    open func cacheCollection<T: SimpleModel>(_ collection: [T], forKey cacheKey: String, context: Any?) {
        externalDispatchQueue.async {
            self.cacheDelegate.setCollection(collection, forKey: cacheKey, context: context)
        }
    }

    /**
     Get a collection model from the cache. This simply forwards the method to the cache delegate.
     */
    open func collectionFromCache<T: SimpleModel>(_ cacheKey: String?, context: Any?, completion: @escaping ([T]?, NSError?)->()) {
        externalDispatchQueue.async {
            self.cacheDelegate.collectionForKey(cacheKey, context: context) { (models: [T]?, error) in
                DispatchQueue.main.async {
                    completion(models, error)
                }
            }
        }
    }
}
