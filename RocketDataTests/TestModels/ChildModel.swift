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
 This class defines a model to use in unit tests. It's simple but sufficiently complex to write effective unit tests.
 Usually, this is only used as a part of ParentModel.
 */
final class ChildModel: Model, Equatable {

    let id: Int?
    let name: String?

    init(id: Int? = nil, name: String? = nil) {
        self.id = id
        self.name = name
    }

    // MARK: Model

    var modelIdentifier: String? {
        if let id = id {
            return "ChildModel:\(id)"
        } else {
            return nil
        }
    }

    func map(_ transform: (Model) -> Model?) -> ChildModel? {
        return self
    }

    func forEach(_ visit: (Model) -> Void) {
    }

    /**
     This method allows this model to be merged with FullChildModel.
     */
    func mergeModel(_ model: Model) -> Model {
        if let model = model as? ChildModel {
            return model
        } else if let model = model as? FullChildModel {
            return ChildModel(id: model.id, name: model.name)
        } else {
            assertionFailure("Unable to merge model with this class.")
            return self
        }
    }
}

func ==(r: ChildModel, l: ChildModel) -> Bool {
    return r.id == l.id &&
        r.name == l.name
}
