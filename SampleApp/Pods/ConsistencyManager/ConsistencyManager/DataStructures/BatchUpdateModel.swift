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
 This model is useful if you want to batch updates to the consistency manager or listen to multiple models.
 It has 3 main use cases:

 1. Update multiple models in the consistency model at the same time.
 This will also cause listeners to only get notified once of this change which can cause better performance.
 In general, this is better than a for loop of updates.
 2. Listen to multiple models at once without an modelIdentifier.
 If you want to listen to mutliple models, you can use this API. The model will be set to nil if it is deleted.
 The batch listener uses this class, so you can look there for a sample implementation.
 3. Listen to multiple models with an modelIdentifier.
 If you use a modelIdentifier, you can have two seperate BatchUpdateModels which are kept in sync.
 This can be useful if you want to keep two different collections in sync.
 */
public final class BatchUpdateModel: ConsistencyManagerModel {

    /// The updated models
    public let models: [ConsistencyManagerModel?]

    /// The modelIdentifier for this BatchUpdateModel. This can be used to keep two BatchUpdateModels consistent.
    public let modelIdentifier: String?

    /**
     - parameter models: The models you want to listen to or update.
     - parameter modelIdentifier: An identifier for the batch model.
     This modelIdentifier must be globally unique (and different from all modelIdentifiers).
     If two BatchUpdateModels have the same identifier, they will be treated as the same model and should have the same data.
     */
    public init(models: [ConsistencyManagerModel], modelIdentifier: String? = nil) {
        self.models = models.map { model in model as ConsistencyManagerModel? }
        self.modelIdentifier = modelIdentifier
    }

    /**
     An initializer that allows you to pass in an array of optional models.
     This can be useful if you want to continuously listen to multiple models which may be deleted.

     - parameter models: The models you want to listen to or update.
     - parameter modelIdentifier: An identifier for the batch model.
     This modelIdentifier must be globally unique (and different from all modelIdentifiers).
     If two BatchUpdateModels have the same identifier, they will be treated as the same model and should have the same data.
     */
    public init(models: [ConsistencyManagerModel?], modelIdentifier: String? = nil) {
        self.models = models
        self.modelIdentifier = modelIdentifier
    }

    public func map(_ transform: (ConsistencyManagerModel) -> ConsistencyManagerModel?) -> ConsistencyManagerModel? {
        let newModels = models.map { model in
            return model.flatMap(transform)
        }
        return BatchUpdateModel(models: newModels)
    }

    public func forEach(_ visit: (ConsistencyManagerModel) -> Void) {
        models.flatMap { $0 }.forEach(visit)
    }

    public func isEqualToModel(_ other: ConsistencyManagerModel) -> Bool {
        guard let other = other as? BatchUpdateModel else {
            return false
        }

        if other.models.count != models.count {
            return false
        }

        for (index, model) in models.enumerated() {
            if let model = model, let otherModel = other.models[index] {
                if !model.isEqualToModel(otherModel) {
                    return false
                }
            } else if !(model == nil && other.models[index] == nil) {
                return false
            }
        }

        return true
    }
}
