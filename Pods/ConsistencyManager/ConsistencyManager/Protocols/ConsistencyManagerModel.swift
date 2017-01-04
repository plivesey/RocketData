// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

/**
This protocol should be implemented by all the models you want to track using the consistency manager. Effectively, it asks you to treat a model as a tree, which enables the library to traverse the tree and map the tree.

IMPORTANT: These methods should be thread safe. Since they are all read operations, and do not mutate the model in any way, this shouldn't be a problem. We recommend using this library with completely immutable models for this reason. However, if there is a problem, you should place a lock on your model when running these methods.

Example Implementation:

```
class Person: ConsistencyManagerModel {
    let id: String
    let name: String
    let currentLocation: Location?
    let homeTown: Location

    var modelIdentifier: String? {
        return id
    }

    func map(transform: ConsistencyManagerModel -> ConsistencyManagerModel?) -> Person? {
        let newCurrentLocation: Location? = {
            if let currentLocation = self.currentLocation {
                return transform(currentLocation) as? Location
            } else {
                return nil
            }
        }()
        let newHomeTown = transform(homeTown) as? Location
            if newHomeTown == nil {
                return nil
            }

        return Person(id: id, name: name, currentLocation: newCurrentLocation, homeTown: newHomeTown!)
    }

    func forEach(function: ConsistencyManagerModel -> Void) {
        if let currentLocation = currentLocation {
            function(currentLocation)
        }
        function(homeTown)
    }

    func isEqualToModel(other: ConsistencyManagerModel) -> Bool {
        guard let other = other as? Person {
            return false
        }
        if id != other.id { return false }
        if name != other.name { return false }
        if !homeTown.isEqualToModel(other.homeTown) { return false }
        if let currentLocation = currentLocation, let otherLocation = other.currentLocation where !currentLocation.isEqualToModel(otherLocation) {
            return false
        } else if currentLocation != nil || other.currentLocation != nil {
            return false
        }
        return true
    }
}

class Location: ConsistencyManagerModel {
    let name: String

    var modelIdentifier: String? {
        // No id, so let's return nil
        return nil
    }

    func map(transform: ConsistencyManagerModel -> ConsistencyManagerModel?) -> Location? {
        // We have no submodels, so nothing to map here
        return self
    }

    func forEach(function: ConsistencyManagerModel -> Void) {
        // Do nothing. Nothing to iterate over.
    }

    func isEqualToModel(other: ConsistencyManagerModel) -> Bool {
        guard let other = other as? Person {
            return false
        }
        if name != other.name { return false }
        return true
    }
}
```

For other examples, see the documentation on Github.

*/
public protocol ConsistencyManagerModel {

    // MARK: Required Methods

    /**
     This method should return a globally unique identifier for the model.
     If it has no id, then you can return nil. If it has no id, it will be considered part of its parent model and you will not be able to update this model in isolation.
     Whenever you change a field on this model, you must post the parent model to the consistency manager for the updates to take place.

     If you're ids are not globally unique, then it's recommended to prefix this id with the class name.
     Ids must be globally unique or you will get unexpected behavior.
     */
    var modelIdentifier: String? { get }

    /**
     This method should run a map function on each child model and return a new version of self.
     It should iterate over all the model's children models and run a transform function on each model.
     Then, it should return a new version of self with the new child models.
     Note: child models are any model which conforms to the protocol. So you can ignore anything else (strings, ints, etc).

     If transform returns nil, it should remove this child model.
     If this child is in an array, it's recommended that you just remove this element from the array.
     If the model is a required model, it is up to you how you implement this.
     However, we recommend that you consider this a cascading delete and return nil from this function (signifying that we should delete the current model).

     It should NOT be recursive. As in, it should only map on the immediate children.
     It should not call map on its children's children.

     - NOTE: Ideally, we'd like this function to return `Self?`, not `ConsistencyManagerModel?`.
     However, Swift currently has a few bugs regarding returning Self in protocols which make this protocol hard to implement (e.g. returning self in protocol extensions doesn't work).
     When these bugs are fixed in Swift, we may consider moving back to using Self.
     You should always return the same type of model from this function even though the protocol doesn't specifically require it.

     - parameter transform: The mapping function
     - Returns: A new version of self with the map function applied
     */
    func map(_ transform: (ConsistencyManagerModel) -> ConsistencyManagerModel?) -> ConsistencyManagerModel?

    /**
     This function should simply iterate over all the child models and run the function passed in.
     Just like map, it only needs to run on anything which is a child and a ConsistencyManagerModel.

     This is very similar to map, and you can actually implement it using map (possibly in a protocol extension).
     For instance:

     extension ConsistencyManagerModel {
        func forEach(function: ConsistencyManagerModel -> Void) {
            _ = map() { model in
                function(model)
                return model
            }
        }
     }

     Here, we are just running map and discarding the result.
     This is correct and can save you some lines of code, but it's less performant since you are creating a new model and then discarding it.
     This performance difference is minor, so it's up to you which you prefer.

     It should NOT be recursive. It should only iterate over the immediate children. Not its children chilrden.

     - parameter visit: The iterating function to be called on each child element.
     */
    func forEach(_ visit: (ConsistencyManagerModel) -> Void)

    /**
     This function should compare one model to another model.
     If you are Equatable, you do NOT need to implement this, and it will automatically be implemented using ==.
     This is implemented in the protocol extension later in this file.

     Nearly always, you want this to act like == and return false if there are any differences.
     However, in some cases, there may be fields that you don't care about that change a lot.
     For instance, you may have some Globally Unique ID returned by the server which isn't used for rendering.
     If you want, you can choose to return true from this function even if these 'transient fields' are different.
     This means that if only this field changes, it will NOT cause a consistency manager update.
     Instead, the change will be dropped.
     However, if there are any other field changes, it will still cause an update and update the whole model.
     This is rare, but an open option if you need it.
     
     - parameter other: The other model to compare to.
     - Returns: True if the models are equal and we should not generate a consistency manager change.
     */
    func isEqualToModel(_ other: ConsistencyManagerModel) -> Bool

    // MARK: Projections

    /**
     Optional
     Most setups don't need to implement this method. You only need to implement this if you are using projections.
     For more information on projections, see https://linkedin.github.io/ConsistencyManager-iOS/pages/055_projections.html.

     This should take another model and merge it into the current model.
     If you have two models with the same id but different data, this should merge one model into the other.
     This should return the same type as Self. It should take all updates from the other model and merge it into the current model.
     For performance reasons, you could check if the other model is the same projection.
     If it is, you could avoid merging and just return the other model (since it's the correct class).
     
     - NOTE: Ideally, we'd like this function to return `Self?`, not `ConsistencyManagerModel?`.
     However, Swift currently has a few bugs regarding returning Self in protocols which make this protocol hard to implement (e.g. returning self in protocol extensions doesn't work).
     When these bugs are fixed in Swift, we may consider moving back to using Self.
     You should always return the same type of model from this function even though the protocol doesn't specifically require it.
     
     - parameter model: The other model to merge into the current model.
     - Returns: A new version of the current model with the changes from the other model.
     */
    func mergeModel(_ model: ConsistencyManagerModel) -> ConsistencyManagerModel

    /**
     You can override to distinguish different projections. Usually, you would have a different class for each projection.
     But you can use this to have one class represent multiple different projections (with optional fields for missing members).
     This is unusual and it's recommended instead to just use different classes for each projection.
     If you do this, you do not need to override this method and can use the default value.
     */
    var projectionIdentifier: String { get }
}

public extension ConsistencyManagerModel where Self: Equatable {

    /**
     This is a default implementation for isEqualToModel for models which are equatable.
     This can be overridden in subclasses if you don't want this default behavior.
     */
    public func isEqualToModel(_ other: ConsistencyManagerModel) -> Bool {
        if let other = other as? Self {
            return self == other
        } else {
            return false
        }
    }
}

/**
 This extension contains the default implementations which make `mergeModel(:)` and `projectionIdentifier` optional.
 */
public extension ConsistencyManagerModel {
    func mergeModel(_ model: ConsistencyManagerModel) -> ConsistencyManagerModel {
        // Usually, we don't need to merge and instead just return the other model.
        // This is because when we're not using projections, classes of the same id will always be of the same type.
        // So, we should just replace the current model with the updated model.
        assert(type(of: self) == type(of: model), "Two models of different classes have the same ID. This is not allowed without override mergeModel(:). See the documentation for more information on projections. Current Model: \(type(of: self)) - Update Model: \(type(of: model))")
        return model
    }

    var projectionIdentifier: String {
        // Returns the class name as a string
        // This means each class type identifies a different projection
        return String(describing: type(of: self))
    }
}
