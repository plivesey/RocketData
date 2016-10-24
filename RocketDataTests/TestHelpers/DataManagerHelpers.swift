// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import Foundation
import RocketData

extension DataModelManager {
    static let sharedDataManagerNoCache = DataModelManager(cacheDelegate: NoOpCacheDelegate())
}

class NoOpCacheDelegate: CacheDelegate {

    func modelForKey<T: SimpleModel>(_ cacheKey: String?, context: Any?, completion: @escaping (T?, NSError?)->()) {
        completion(nil, NSError(domain: "com.rocketData.unitTests", code: 0, userInfo: nil))
    }

    func setModel(_ model: SimpleModel, forKey cacheKey: String, context: Any?) {
    }

    func collectionForKey<T: SimpleModel>(_ cacheKey: String?, context: Any?, completion: @escaping ([T]?, NSError?)->()) {
        completion(nil, NSError(domain: "com.rocketData.unitTests", code: 0, userInfo: nil))
    }

    func setCollection(_ collection: [SimpleModel], forKey cacheKey: String, context: Any?) {
    }

    func deleteModel(_ model: SimpleModel, forKey cacheKey: String?, context: Any?) {
    }
}

class ExpectCacheDelegate: CacheDelegate {

    var modelForKeyCalled: ((String?, Any?, @escaping (Any?, NSError?)->Void)->Void)?
    var setModelCalled: ((SimpleModel, String, Any?)->Void)?
    var collectionForKeyCalled: ((String?, Any?, @escaping ([Any]?, NSError?)->Void)->Void)?
    var setCollectionCalled: (([SimpleModel], String, Any?)->Void)?
    var deleteModelCalled: ((SimpleModel, String?, Any?)->Void)?

    func modelForKey<T: SimpleModel>(_ cacheKey: String?, context: Any?, completion: @escaping (T?, NSError?)->()) {
        modelForKeyCalled?(cacheKey, context) { model, error in
            completion(model as? T, error)
        }
    }

    func setModel(_ model: SimpleModel, forKey cacheKey: String, context: Any?) {
        setModelCalled?(model, cacheKey, context)
    }

    func collectionForKey<T: SimpleModel>(_ cacheKey: String?, context: Any?, completion: @escaping ([T]?, NSError?)->()) {
        collectionForKeyCalled?(cacheKey, context) { models, error in
            completion(models as? [T], error)
        }
    }

    func setCollection(_ collection: [SimpleModel], forKey cacheKey: String, context: Any?) {
        // Annoying workaround for a compiler bug
        let simpleModels = collection.map { model in
            model as SimpleModel
        }
        setCollectionCalled?(simpleModels, cacheKey, context)
    }

    func deleteModel(_ model: SimpleModel, forKey cacheKey: String?, context: Any?) {
        deleteModelCalled?(model, cacheKey, context)
    }
}
