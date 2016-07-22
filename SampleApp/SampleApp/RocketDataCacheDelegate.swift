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
    let cache = PINCache()

    func modelForKey<T : SimpleModel>(cacheKey: String?, context: Any?, completion: (T?, NSError?) -> ()) {
        guard let cacheKey = cacheKey,
            let data = cache.objectForKey(cacheKey) as? [NSObject: AnyObject],
            let modelType = T.self as? SampleAppModel.Type else {
                completion(nil, nil)
                return
        }

        // You can also use ParsingHelpers to do this conversion, but it doesn't work with protocols
        completion(modelType.init(data: data) as? T, nil)
    }

    func setModel<T : SimpleModel>(model: T, forKey cacheKey: String, context: Any?) {
        if let model = model as? SampleAppModel {
            cache.setObject(model.data(), forKey: cacheKey, block: nil)
        }
    }

    func parseModel<T>(parseBlock: SampleAppModel.Type -> SampleAppModel?) -> (T?, NSError?) {
        if let Model = T.self as? SampleAppModel.Type {
            let model = parseBlock(Model) as? T
            return (model, nil)
        } else {
            return (nil, nil)
        }
    }

    func collectionForKey<T : SimpleModel>(cacheKey: String?, context: Any?, completion: ([T]?, NSError?) -> ()) {
        guard let cacheKey = cacheKey,
            let collectionCacheValue = cache.objectForKey(cacheKey) as? [String],
            let modelType = T.self as? SampleAppModel.Type else {
                completion(nil, nil)
                return
        }

        let collection: [T] = collectionCacheValue.flatMap {
            guard let data = self.cache.objectForKey($0) as? [NSObject: AnyObject] else {
                return nil
            }
            return modelType.init(data: data) as? T
        }
        completion(collection, nil)
    }

    func setCollection<T : SimpleModel>(collection: [T], forKey cacheKey: String, context: Any?) {
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

        cache.setObject(collectionCacheValue, forKey: cacheKey, block: nil)
    }

    func deleteModel(model: SimpleModel, forKey cacheKey: String?, context: Any?) {
        guard let cacheKey = cacheKey else {
            return
        }
        cache.removeObjectForKey(cacheKey)
    }
}
