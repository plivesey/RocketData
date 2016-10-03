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


// MARK: - Protocols

/**
 This is the minimum requirement for models to implement. When using this protocol, you will get consistency for top level models only.
 So, if a submodel or subtree of your model changes, you will not be notified of this change.
 If you want to be notified of submodel changes, you should use the Model protocol.
 This protocol is useful if you don't get these types of changes or you don't care about these changes.
*/
public protocol SimpleModel: ConsistencyManagerModel {

    /**
     Should return true if this model is equal to another model. 
     The library uses this method to determine if a change has occured and if a replacement is necessary.
     
     If your model is Equatable, you do not need to implement this method (it will be implemented automatically using ==).
     */
    func isEqual(to model: SimpleModel) -> Bool
}

/**
 This is a more powerful protocol for models to implement than SimpleModel. This is the recommended protocol to implement.
 When using this protocol, you will get consistency for both the top level model and all submodels.
 So, if a submodel changes, a new top level model will be generated and will be updated.
 */
public protocol Model: SimpleModel {

    /**
     Should return true if this model is equal to another model.
     The library uses this method to determine if a change has occured and if a replacement is necessary.
     
     If your model is Equatable, you do not need to implement this method (it will be implemented automatically using ==).
     */
    func isEqual(to model: Model) -> Bool

    /**
     This method should run a map function on each child model and return a new version of self.

     If the transform function returns nil, then it should treat this like a filter and remove this model. 
     For instance, if you have an array of models, and you return nil for one of them, it should remove this model from the array.
     If setting one of these models to nil will invalidate the current model (as in, the model is required), then you should return nil.
     This will cascade the delete and remove the current model.

     It SHOULD NOT be recursive. As in, it should only map on the immediate children. It should not call map on its children's children.

     - parameter transform: The mapping function
     - Returns: A new version of self with the map function applied
     */
    func map(_ transform: (Model) -> Model?) -> Self?

    /**
     This method should iterate over all the child models in self.

     It SHOULD NOT be recursive. It should only iterate over the immediate children. Not its children's children.

     - parameter function: The iterating function to be called on each child element.
     */
    func forEach(_ visit: (Model) -> Void)

    /**
     Optional method. Do not implement this method unless you want to support projections (not common).
     
     See the docs for `func mergeModel(model: ConsistencyManagerModel) -> ConsistencyManagerModel` in `ConsistencyManagerModel.swift` for more information on projections and this method.
     
     This method should always return Self.
     However, Swift currently has a bug which doesn't allow this to return Self without needing it to be overridden in every class.
     See https://bugs.swift.org/browse/SR-2357
     
     - parameter model: The model which should be merged into the current model.
     - Returns: A model of type Self which contains the merged field from model.
     */
    func merge(_ model: Model) -> Model
}

// MARK: - Extensions

/*
This extension automatically implements isEqualToModel whenever the SimpleModel is equatable.
*/
extension SimpleModel where Self: Equatable {
    public func isEqual(to model: SimpleModel) -> Bool {
        if let model = model as? Self {
            return model == self
        } else {
            return false
        }
    }
}

/*
 This extension automatically implements isEqualToModel whenever the Model is equatable.
*/
extension Model where Self: Equatable {
    public func isEqual(to model: Model) -> Bool {
        if let model = model as? Self {
            return model == self
        } else {
            return false
        }
    }
}

/*
This extension allows SimpleModel to easily inherit ConsistencyManagerModel. It does this with default implementations that make consistency only work
with top level models. With this extension, you only need to implement two methods: modelIdentifier and isEqualToModel.
*/
extension SimpleModel {
    public func isEqualToModel(_ model: ConsistencyManagerModel) -> Bool {
        if let model = model as? Model {
            return isEqual(to: model)
        } else {
            return false
        }
    }

    // This method is implemented with a default implementation. This causes it to be a top level model only.
    public func map(_ transform: (ConsistencyManagerModel) -> ConsistencyManagerModel?) -> ConsistencyManagerModel? {
        return self
    }

    // This method is implemented with a default implementation. This causes it to be a top level model only.
    public func forEach(_ visit: (ConsistencyManagerModel) -> Void) {
        // Do nothing
    }
}

/*
This extension implements the consistency manager model protocol and the simple model protocol
The methods are the same, but the type signatures are slightly different. This runs all the appropriate casts.
*/
extension Model {
    public func isEqual(to model: SimpleModel) -> Bool {
        if let model = model as? Model {
            return isEqualToModel(model)
        } else {
            return false
        }
    }

    public func isEqualToModel(_ model: ConsistencyManagerModel) -> Bool {
        if let model = model as? Model {
            return isEqual(to: model)
        } else {
            return false
        }
    }

    // Implement the consistency manager protocol to return our version of map
    public func map(_ transform: (ConsistencyManagerModel) -> ConsistencyManagerModel?) -> ConsistencyManagerModel? {
        return map { model -> Model? in
            return transform(model) as? Model
        }
    }

    // Implement the consistency manager protocol to return our version of forEach
    public func forEach(_ visit: (ConsistencyManagerModel) -> Void) {
        forEach { (model: Model) in
            visit(model)
        }
    }
}

/**
 This extension replaces the ConsistencyManager version of `mergeModel` with the RocketData version (which uses `Model`).
 It also implements the default version of `mergeModel` which should just return the other model (since it will be the same class).
 */
extension Model {
    public func merge(_ model: Model) -> Model {
        // This cast should always succeed.
        if let model = model as? Self {
            return model
        } else {
            Log.sharedInstance.assert(false, "Two objects with the same ID have difference classes. In most setups, this is not allowed. You should override mergeModel(:) if you want to support projections. See the docs for more information.")
            return self
        }
    }

    public func mergeModel(_ model: ConsistencyManagerModel) -> ConsistencyManagerModel {
        if let model = model as? Model {
            return merge(model)
        } else {
            Log.sharedInstance.assert(false, "Model detected that doesn't implement Model. If you want to use projections, all models should implement the Model protocol.")
            return model
        }
    }
}
