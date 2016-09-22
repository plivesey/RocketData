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
 This object represents a single change to a collection.
 You can use these to animate changes in your view.
 */
public enum CollectionChange: Equatable {

    /// The whole collection was reset. In this case, you cannot animate changes.
    /// For instance, this is caused when someone calls setData.
    case reset

    /// This provides diff information for the collection change.
    /// These changes should be provided in the order given here.
    /// The indexes will be safe and correct in this order.
    /// See CollectionDataProviderDelegate for more info.
    case changes([CollectionChangeInformation])
}

public func ==(lhs: CollectionChange, rhs: CollectionChange) -> Bool {
    switch (lhs, rhs) {
    case (.reset, .reset):
        return true
    case (.changes(let l), .changes(let r)):
        return l == r
    default:
        return false
    }
}

/**
 This object gives specific change information about a collection.
 */
public enum CollectionChangeInformation: Equatable {

    /// This indicates that an element was updated at a specific index.
    case update(index: Int)

    /// This indicates that an element was deleted at a specific index.
    case delete(index: Int)

    /// This indicates that an element was inserted at a specific index.
    case insert(index: Int)
}

public func ==(lhs: CollectionChangeInformation, rhs: CollectionChangeInformation) -> Bool {
    switch (lhs, rhs) {
    case (.update(let l), .update(let r)):
        return l == r
    case (.delete(let l), .delete(let r)):
        return l == r
    case (.insert(let l), .insert(let r)):
        return l == r
    default:
        return false
    }
}

/**
 This extension provides some useful helpers on a collection of CollectionChanges.
 */
public extension Collection where Iterator.Element == CollectionChangeInformation {
    /**
     This returns the number of .delete items in the array.
     It does not dedupe for repeated elements.
     */
    public func numberOfDeletedElements() -> Int {
        return filter { element in
            switch element {
            case .delete:
                return true
            case .update, .insert:
                return false
            }
        }.count
    }

    /**
     This returns the number of .insert items in the array.
     It does not dedupe for repeated elements.
     */
    public func numberOfInsertedElements() -> Int {
        return filter { element in
            switch element {
            case .insert:
                return true
            case .update, .delete:
                return false
            }
        }.count
    }

    /**
     This returns how the count of the array has changed. So:

     ``oldArray.count + deltaNumberOfElements() == newArray.count``

     This is:

     ``numberOfInsertedItems - numberOfDeletedItems``.
     */
    public func deltaNumberOfElements() -> Int {
        return numberOfInsertedElements() - numberOfDeletedElements()
    }
}
