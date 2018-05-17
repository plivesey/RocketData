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
*/
final class ParentModel: Model, Equatable {

    let id: Int
    let name: String
    let requiredChild: ChildModel
    let otherChildren: [ChildModel]

    init(id: Int, name: String, requiredChild: ChildModel, otherChildren: [ChildModel]) {
        self.id = id
        self.name = name
        self.requiredChild = requiredChild
        self.otherChildren = otherChildren
    }

    // MARK: Model

    var modelIdentifier: String? {
        return "ParentModel:\(id)"
    }

    func map(_ transform: (Model) -> Model?) -> ParentModel? {
        guard let requiredChild = transform(requiredChild) as? ChildModel else {
            // Cascade the delete
            return nil
        }

        let otherChildren = self.otherChildren.compactMap { child in
            return transform(child) as? ChildModel
        }
        return ParentModel(id: id, name: name, requiredChild: requiredChild, otherChildren: otherChildren)
    }

    func forEach(_ visit: (Model) -> Void) {
        visit(requiredChild)
        otherChildren.forEach { child in
            visit(child)
        }
    }
}

func ==(r: ParentModel, l: ParentModel) -> Bool {
    return r.id == l.id &&
        r.name == l.name &&
        r.requiredChild == l.requiredChild &&
        r.otherChildren == l.otherChildren
}

// This extension provides some convenience initializers
extension ParentModel {

    /**
     If you only care about the id of a model, this creates a parent model with 'default' fields.
    */
    convenience init(id: Int) {
        self.init(id: id, name: "", requiredChild: ChildModel(), otherChildren: [])
    }
}
