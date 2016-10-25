//
//  RocketDataCacheDelegate.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import Foundation
import RocketData
import PINCache

class RocketDataCacheDelegate: CacheDelegate {

    /**
     This is the underlying cache implementation. We're going to use a PINCache because it's thread safe (so we can avoid using GCD here).
     You should feel free to use any cache you'd like.
     */
    fileprivate let cache = PINCache(name: "SampleAppCache")

    func modelForKey<T : SimpleModel>(_ cacheKey: String?, context: Any?, completion: @escaping (T?, NSError?) -> ()) {
        guard let cacheKey = cacheKey,
            let data = cache.object(forKey: cacheKey) as? [AnyHashable: Any],
            let modelType = T.self as? SampleAppModel.Type else {
                // NOTE: The last cast is to ensure that we only deal with SampleAppModels. This allows us to call init(data:)
                // We've decided not to return a real error here because we never use it in our data providers
                completion(nil, nil)
                return
        }

        // You can also use ParsingHelpers to do this conversion, but it doesn't work with protocols
        completion(modelType.init(data: data) as? T, nil)
    }

    func setModel(_ model: SimpleModel, forKey cacheKey: String, context: Any?) {
        if let model = model as? SampleAppModel {
            cache.setObject(model.data() as NSCoding, forKey: cacheKey, block: nil)
        } else {
            assertionFailure("In our app, we only want to use RocketData with SampleAppModels")
        }
    }

    func collectionForKey<T : SimpleModel>(_ cacheKey: String?, context: Any?, completion: @escaping ([T]?, NSError?) -> ()) {
        guard let cacheKey = cacheKey,
            let collectionCacheValue = cache.object(forKey: cacheKey) as? [String],
            let modelType = T.self as? SampleAppModel.Type else {
                // NOTE: The last cast is to ensure that we only deal with SampleAppModels. This allows us to call init(data:)
                // We've decided not to return a real error here because we never use it in our data providers
                completion(nil, nil)
                return
        }

        // For this app, we've decided to save the models from collections seperately
        // So, collectionCacheValue is an array of ids. We'll try to resolved each of these ids to a real object in the cache
        // If one fails, that's ok. We'll still return as much as we can
        let collection: [T] = collectionCacheValue.flatMap {
            guard let data = self.cache.object(forKey: $0) as? [AnyHashable: Any] else {
                return nil
            }
            return modelType.init(data: data) as? T
        }
        completion(collection, nil)
    }

    func setCollection(_ collection: [SimpleModel], forKey cacheKey: String, context: Any?) {
        // In this method, we're going to store an array of strings for the collection and cache all the models individually
        // This means updating one of the models will automatically update the collection

        collection.forEach { model in
            if let cacheKey = model.modelIdentifier {
                setModel(model, forKey: cacheKey, context: nil)
            } else {
                assertionFailure("This should never happen because all of our collection models have ids")
            }
        }

        let collectionCacheValue = collection.flatMap {
            return $0.modelIdentifier
        }

        cache.setObject(collectionCacheValue as NSCoding, forKey: cacheKey, block: nil)
    }

    func deleteModel(_ model: SimpleModel, forKey cacheKey: String?, context: Any?) {
        guard let cacheKey = cacheKey else {
            return
        }
        cache.removeObject(forKey: cacheKey)
    }
}
