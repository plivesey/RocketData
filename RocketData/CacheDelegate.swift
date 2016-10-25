// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import Foundation

/**
 This is the implementation of the cache for the data manager.
 You can use any cache solution you want, but it's recommended to use a key-value store like cache since the API is geared towards that.
 
 All these delegate methods may be called on any thread. You may call the completion blocks on any thread.
 The threads that call these methods are from a shared pool, so you can do synchronous gets and sets if you want.
 Because of these requirements, the cache delegate must effectively be thread safe for these methods. 
 If it is not thread safe, you should dispatch to your own thread to ensure thread safety.
*/
public protocol CacheDelegate {
    /**
     Given a cache key, you should retrieve a model of type T. 
     You should fetch it from the cache and call the completion block with the model and an error (if there is one).
     Likely, you probably have some superclass or protocol which all your models adhere to, and you can't handle it for any T.
     If this is the case, the parseModel function in DataModelManager should help parse your model assuming it's a certain superclass or protocol.
     For information on threading, see the CacheDelegate docs.
     
     Errors
     
     Errors in the completion block are completely optional here. The error object is not used by Rocket Data in any way. It is just passed back to the data providers. So, if you ignore the errors in data providers, you can just return (nil, nil) here on cache misses.
     
     - parameter cacheKey: The cache key for this model. This is always equal to the modelIdentifier.
     - parameter context: A context you can pass in when fetching from the cache.
     - parameter completion: A completion block to call when you have fetched a model. You may call this on any thread and should only call it once.
    */
    func modelForKey<T: SimpleModel>(_ cacheKey: String?, context: Any?, completion: @escaping (T?, NSError?)->())

    /**
     In this method, you should save a model in the cache.
     For information on threading, see the CacheDelegate docs.
     
     - parameter model: The model to save in the cache.
     - parameter cacheKey: The cache key for this model. This is always equal to the modelIdentifier.
     - parameter context: A context you can pass in when saving to the cache.
     */
    func setModel(_ model: SimpleModel, forKey cacheKey: String, context: Any?)

    /**
     Given a cache key, you should retrieve a collection of type [T].
     You should fetch it from the cache and call the completion block with the model and an error (if there is one).
     Likely, you probably have some superclass or protocol which all your models adhere to, and you can't handle it for any T.
     If this is the case, the parseModel function in DataModelManager should help parse your model assuming it's a certain superclass or protocol.
     For information on threading, see the CacheDelegate docs.
     
     Errors

     Errors in the completion block are completely optional here. The error object is not used by Rocket Data in any way. It is just passed back to the data providers. So, if you ignore the errors in data providers, you can just return (nil, nil) here on cache misses.

     - parameter cacheKey: The cache key for this model. This is defined by the CollectionDataProvider.
     - parameter context: A context you can pass in when fetching from the cache.
     - parameter completion: A completion block to call when you have fetched the models. You may call this on any thread and should only call it once.
     */
    func collectionForKey<T: SimpleModel>(_ cacheKey: String?, context: Any?, completion: @escaping ([T]?, NSError?)->())

    /**
     In this method, you should save a collection of models in the cache.
     For information on threading, see the CacheDelegate docs.

     - parameter collection: The models to save in the cache. This is defined by the CollectionDataProvider.
     - parameter cacheKey: The cache key for this model.
     - parameter context: A context you can pass in when saving to the cache.
     */
    func setCollection(_ collection: [SimpleModel], forKey cacheKey: String, context: Any?)

    /**
     Called when delete is called from the DataModelManager.
     The cacheKey is always the modelIdentifier of the model deleted.
     
     - parameter model: The model to delete.
     - parameter cacheKey: The modelIdentifier of the model.
     - parameter context: A context you can pass in when deleting.
     */
    func deleteModel(_ model: SimpleModel, forKey cacheKey: String?, context: Any?)
}
