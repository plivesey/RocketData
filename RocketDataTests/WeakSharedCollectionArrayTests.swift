// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import Foundation
import XCTest
@testable import RocketData

/**
 This tests our weak shared collection array.
 Once we are able to move to the ConsistencyManager's WeakArray<T>, we can get rid of this class and these tests.
 https://bugs.swift.org/browse/SR-1176
 */
class WeakSharedCollectionArrayTests: RocketDataTestCase {

    // MARK: Basic Functionality

    func testWeakArrayBasic() {
        var array: WeakSharedCollectionArray = {
            var array = WeakSharedCollectionArray()
            let test = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
            array.append(test)
            XCTAssertNotNil(array[0])
            return array
        }()
        XCTAssertNil(array[0])
    }

    func testRepeatedValues() {
        let weakArray: WeakSharedCollectionArray = {
            let testClass = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
            let weakArray: WeakSharedCollectionArray = [testClass, testClass]
            XCTAssertNotNil(weakArray[0])
            XCTAssertNotNil(weakArray[1])
            XCTAssertTrue(weakArray[1] === weakArray[0])

            return weakArray
        }()

        // Now we're out of scope, both values should be nil
        XCTAssertNil(weakArray[0])
        XCTAssertNil(weakArray[1])
    }

    // MARK: Initializers

    func testCapacityCount() {
        for count in 0..<100 {
            let test = WeakSharedCollectionArray(count: count)
            XCTAssertEqual(count, test.count)
        }
    }

    func testArrayLiteralEmpty() {
        let array: WeakSharedCollectionArray = []
        XCTAssertEqual(array.count, 0)
    }

    func testArrayLiteralFull() {
        let array: WeakSharedCollectionArray = {
            var strongArray = [CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache), CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache), CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)]
            let array: WeakSharedCollectionArray = [strongArray[0], strongArray[1], strongArray[2]]
            for i in 0..<3 {
                XCTAssertTrue(array[i] === strongArray[i])
            }
            return array
        }()

        // Everythings out of scope now, so let's check that its nil
        for element in array {
            XCTAssertNil(element)
        }
    }

    func testArrayLiteralNil() {
        let array: WeakSharedCollectionArray = [nil, nil, nil]
        for element in array {
            XCTAssertNil(element)
        }
    }

    func testArrayLiteralPartial() {
        let array: WeakSharedCollectionArray = {
            var strongArray = [CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache), CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache), CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)]
            let array: WeakSharedCollectionArray = [strongArray[0], nil, strongArray[1], nil, strongArray[2], nil]
            for i in 0..<6 {
                if i % 2 == 0 {
                    XCTAssertTrue(array[i] === strongArray[i / 2])
                } else {
                    XCTAssertNil(array[i])
                }
            }
            return array
        }()

        // Everythings out of scope now, so let's check that its nil
        for element in array {
            XCTAssertNil(element)
        }
    }

    // MARK: Properties

    func testCount() {
        for count in 0..<100 {
            var array = WeakSharedCollectionArray()
            for _ in 0..<count {
                array.append(CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache))
            }
            XCTAssertEqual(count, array.count)
        }
    }

    // MARK: Public Methods

    func testPruneAllNil() {
        for count in 0..<100 {
            var weakArray: WeakSharedCollectionArray = {
                var strongArray = [CollectionDataProvider<ParentModel>]()
                var weakArray = WeakSharedCollectionArray()

                for _ in 0..<count {
                    let testObject = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
                    strongArray.append(testObject)
                    weakArray.append(testObject)
                }

                // Nothing should be pruned because everything is still here
                XCTAssertEqual(weakArray.prune().count, count)
                XCTAssertEqual(weakArray.count, count)

                return weakArray
            }()

            // We haven't pruned yet, so count won't have changed
            XCTAssertEqual(weakArray.count, count)
            // Now prune should take everything out of the array
            XCTAssertEqual(weakArray.prune().count, 0)
            XCTAssertEqual(weakArray.count, 0)
        }
    }

    func testPruneSomeNil() {
        for count in 0..<100 {
            var outerStrongArray = [CollectionDataProvider<ParentModel>]()
            var weakArray: WeakSharedCollectionArray = {
                var strongArray = [CollectionDataProvider<ParentModel>]()
                var weakArray = WeakSharedCollectionArray()

                for i in 0..<count {
                    let testObject = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
                    strongArray.append(testObject)
                    weakArray.append(testObject)
                    if i % 2 == 1 {
                        // Let's keep this around until the end
                        // So here, we're keeping all the odd values
                        outerStrongArray.append(testObject)
                    }
                }

                // Nothing should be pruned because everything is still here
                XCTAssertEqual(weakArray.prune().count, count)
                XCTAssertEqual(weakArray.count, count)

                return weakArray
            }()

            // Now prune should take everything out of the array
            XCTAssertEqual(weakArray.prune().count, count / 2)
            XCTAssertEqual(weakArray.count, count / 2)

            for i in 0..<count / 2 {
                XCTAssertTrue(outerStrongArray[i] === weakArray[i])
            }
        }
    }

    func testMap() {
        for count in 0..<100 {
            var strongArray = [CollectionDataProvider<ParentModel>]()
            var weakArray = WeakSharedCollectionArray()

            for _ in 0..<count {
                let testObject = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
                strongArray.append(testObject)
                weakArray.append(testObject)
            }

            let mappedWeakArray: WeakSharedCollectionArray = weakArray.map { element in
                let newElement = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
                newElement.setData([ParentModel(id: 0)], cacheKey: nil)
                strongArray.append(newElement)
                return newElement
            }

            for element in mappedWeakArray {
                if let element = element {
                    XCTAssertEqual(element.anyData.count, 1)
                } else {
                    XCTFail()
                }
            }
        }
    }

    func testFilter() {
        for count in 0..<100 {
            var strongArray = [CollectionDataProvider<ParentModel>]()
            var weakArray = WeakSharedCollectionArray()

            for i in 0..<count {
                let testObject = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
                if i % 2 == 0 {
                    testObject.setData([ParentModel(id: 0)], cacheKey: nil)
                }
                strongArray.append(testObject)
                weakArray.append(testObject)
            }

            let filteredWeakArray = weakArray.filter { element in
                return element?.anyData.count == 1
            }

            for element in filteredWeakArray {
                if let element = element {
                    XCTAssertEqual(element.anyData.count, 1)
                } else {
                    XCTFail()
                }
            }
        }
    }

    // MARK: MutableCollectionType Tests

    func testGetterSetter() {
        for count in 0..<100 {
            var weakArray = WeakSharedCollectionArray(count: count)
            for i in 0..<count {
                // Assert everything is nil after initializing
                XCTAssertNil(weakArray[i])
                let test = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
                weakArray[i] = test
                XCTAssertTrue(weakArray[i] === test)
            }
            // Now everything is out of scope, so everything should be nil again
            for i in 0..<count {
                XCTAssertNil(weakArray[i])
            }
        }
    }

    /**
     This test ensures that the sequence methods work correctly.
     It verifies that when you create an array with X items, that you can iterate over these values.
     */
    func testSequenceType() {
        for count in 0..<100 {
            let weakArray: WeakSharedCollectionArray = {
                var strongArray = [CollectionDataProvider<ParentModel>]()
                var weakArray = WeakSharedCollectionArray()
                for _ in 0..<count {
                    let testObject = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
                    strongArray.append(testObject)
                    weakArray.append(testObject)
                }
                var seenArray = Array<Bool>(count: count, repeatedValue: false)

                // Now let's test the iterator phase 1
                for (index, element) in weakArray.enumerate() {
                    if element != nil {
                        seenArray[index] = true
                    } else {
                        XCTFail("It shouldn't ever be nil")
                    }
                }

                for seen in seenArray {
                    XCTAssertTrue(seen)
                }

                return weakArray
            }()

            // Now let's test the weak array iterating over nil values
            var iterations = 0
            for element in weakArray {
                XCTAssertNil(element)
                iterations += 1
            }
            // Should have iterated over every value
            XCTAssertEqual(iterations, count)
        }
    }
}
