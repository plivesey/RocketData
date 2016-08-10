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

/**
 This class is only used to test projections and most tests don't use this class.
 It's a projection which can be converted to ChildModel. It has the same fields, but also an additional field - `additionalData`.
 The modelIdentifier will be the same as ChildModels.
 The `mergeModel` method of this class implements this behavior.
 */
final class FullChildModel: Model, Equatable {

    let id: Int?
    let name: String?
    let otherData: Int?

    init(id: Int? = nil, name: String? = nil, otherData: Int? = nil) {
        self.id = id
        self.name = name
        self.otherData = otherData
    }

    // MARK: Model

    var modelIdentifier: String? {
        if let id = id {
            // We are going to have the same ID as ChildModel does
            return "ChildModel:\(id)"
        } else {
            return nil
        }
    }

    func map(transform: Model -> Model?) -> FullChildModel? {
        return self
    }

    func forEach(visit: Model -> Void) {
    }

    func mergeModel(model: Model) -> FullChildModel {
        if let model = model as? FullChildModel {
            // If the other model is the same class, we can just do a replacement
            return model
        } else if let model = model as? ChildModel {
            // If the other model is a child model, let's merge those fields into a new instance of FullChildModel
            return FullChildModel(id: model.id, name: model.name, otherData: otherData)
        } else {
            assertionFailure("Unable to merge model with this class.")
            return self
        }
    }
}

func ==(r: FullChildModel, l: FullChildModel) -> Bool {
    return r.id == l.id &&
        r.name == l.name &&
        r.otherData == l.otherData
}
