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
 This class defines an array which doesn't hold strong references to its elements. If an element in the array gets dealloced at some point, accessing that element will just return nil.

 You cannot put structs into the WeakArray because structs cannot be declared with weak. You can only put classes into the array.

 KNOWN BUGS

 You can't create a WeakArray<SomeProtocol>. This is because of an Apple bug: https://bugs.swift.org/browse/SR-1176.
*/

// Here I want to do this: WeakArray<T: class>, but that doesn't work. So this is a decent work around.
public struct WeakArray<T: AnyObject>: ExpressibleByArrayLiteral {

    // MARK: Internal

    /// The internal data is an array of closures which return weak T's
    fileprivate var data: [() -> T?]

    // MARK: Initializers

    /**
     Creates an empty array
    */
    public init() {
        data = []
    }

    /**
     Creates an array with a certain capacity. All elements in the array will be nil.
    */
    public init(count: Int) {
        data = Array<() -> T?>(repeating: {
            return nil
        }, count: count)
    }

    /**
     Array literal initializer. Allows you to initialize a WeakArray with array notation.
    */
    public init(arrayLiteral elements: T?...) {
        data = []
        for element in elements {
            data.append(weakClosureWithValue(element))
        }
    }

    // MARK: Public Properties

    /// How many elements the array stores
    public var count: Int {
        return data.count
    }

    // MARK: Public Methods

    /**
     Append an element to the array.
    */
    public mutating func append(_ element: T?) {
        data.append(weakClosureWithValue(element))
    }

    /**
     This method iterates through the array and removes any element which is nil.
     It also returns an array of nonoptional values for convenience.

     This method runs in O(n), so you should only call this method every time you need it. You should only call it once.
     i.e. Don't do this:
     for _ in array.prune()
    */
    public mutating func prune() -> [T] {
        var nonOptionalElements = [T]()
        data = data.filter { closure in
            let value = closure()
            if let value = value {
                nonOptionalElements.append(value)
                return true
            } else {
                return false
            }
        }
        return nonOptionalElements
    }

    /**
     This function is similar to the map function on Array. It takes a function that maps T to U and returns a WeakArray of the same length with this function applied to each element.
    */
    public func map<U>(_ function: (T?) -> U?) -> WeakArray<U> {
        var newArray = WeakArray<U>()
        for value in self {
            let newValue = function(value)
            newArray.append(newValue)
        }
        return newArray
    }

    // MARK: Private Methods

    fileprivate func weakClosureWithValue(_ object: T?) -> () -> T? {
        return { [weak object] in
            return object
        }
    }
}

// MARK: MutableCollectionType Implementation

extension WeakArray: MutableCollection {

    // Required by SequenceType
    public func makeIterator() -> IndexingIterator<WeakArray<T>> {
        // Rather than implement our own generator, let's take advantage of the generator provided by IndexingGenerator
        return IndexingIterator<WeakArray<T>>(_elements: self)
    }

    // Required by _CollectionType
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    // Required by _CollectionType
    public var endIndex: Int {
        return self.count
    }

    // Required by _CollectionType
    public var startIndex: Int {
        return 0
    }

    /**
     Getter and setter array
    */
    public subscript(index: Int) -> T? {
        get {
            let closure = data[index]
            return closure()
        }
        set {
            data[index] = weakClosureWithValue(newValue)
        }
    }
}
