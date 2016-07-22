// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import XCTest
@testable import RocketData

class ConsistencyCollectionDataProviderTests: RocketDataTestCase {

    // MARK: Set data

    func testSettingSameID() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider[0].name, "new")
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 0))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData([initialModel], cacheKey: nil, context: "wrong")
        otherDataProvider.setData([newModel], cacheKey: nil, context: "context")

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testSettingSameModel() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])

        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTFail()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData([initialModel], cacheKey: nil, context: "wrong")
        otherDataProvider.setData([initialModel], cacheKey: nil, context: "wrong")

        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)
    }

    func testSettingModelWithDifferentSubtree() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(id: 3, name: "childInitial"), otherChildren: [])
        let newModel = ParentModel(id: 4, name: "new", requiredChild: ChildModel(id: 3, name: "childNew"), otherChildren: [])

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider[0].name, "initial")
            XCTAssertEqual(dataProvider[0].requiredChild.name, "childNew")
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 0))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData([initialModel], cacheKey: nil, context: "wrong")
        otherDataProvider.setData([newModel], cacheKey: nil, context: "context")

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    // MARK: Deleting

    func testDeletingModel() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider.count, 0)
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.delete(index: 0))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate

        dataProvider.setData([initialModel], cacheKey: nil, context: "wrong")
        DataModelManager.sharedDataManagerNoCache.deleteModel(initialModel, context: "context")

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testDeletingOptionalModel() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [ChildModel(id: 2, name: nil)])

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider[0].name, "initial")
            XCTAssertEqual(dataProvider[0].otherChildren.count, 0)
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 0))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate

        dataProvider.setData([initialModel], cacheKey: nil, context: "wrong")
        DataModelManager.sharedDataManagerNoCache.deleteModel(ChildModel(id: 2, name: nil), context: "context")

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testDeletingRequiredModel() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(id: 3, name: "childInitial"), otherChildren: [])

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider.data.count, 0)
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.delete(index: 0))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate

        dataProvider.setData([initialModel], cacheKey: nil, context: "wrong")
        DataModelManager.sharedDataManagerNoCache.deleteModel(ChildModel(id: 3, name: "childInitial"), context: "context")

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    // MARK: - Other collection methods

    // MARK: Insert

    func testInsertItems() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherModel = ParentModel(id: 2)

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider[0].name, "new")
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 0))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData([initialModel], cacheKey: nil, context: "wrong")
        otherDataProvider.setData([otherModel, otherModel], cacheKey: nil, context: "wrong")

        otherDataProvider.insert([newModel], at: 1, context: "context")

        XCTAssertEqual(otherDataProvider.count, 3)
        XCTAssertEqual(otherDataProvider[1].name, "new")

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testInsertListenOnNewItems() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherModel = ParentModel(id: 2)

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider[0].name, "new")
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 0))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData([otherModel], cacheKey: nil, context: "wrong")
        otherDataProvider.setData([otherModel, otherModel], cacheKey: nil, context: "wrong")

        // First, insert the initial model
        dataProvider.insert([initialModel], at: 0, context: "wrong")
        // Now, update it to a new model
        otherDataProvider.insert([newModel], at: 1, context: "context")

        XCTAssertEqual(otherDataProvider.count, 3)
        XCTAssertEqual(otherDataProvider[1].name, "new")

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAppendItems() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherModel = ParentModel(id: 2)

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider[0].name, "new")
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 0))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData([initialModel], cacheKey: nil, context: "wrong")
        otherDataProvider.setData([otherModel, otherModel], cacheKey: nil, context: "wrong")

        otherDataProvider.append([newModel], context: "context")
        
        XCTAssertEqual(otherDataProvider.count, 3)
        XCTAssertEqual(otherDataProvider[2].name, "new")
        
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAppendListenOnNewItems() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherModel = ParentModel(id: 2)

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider[1].name, "new")
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 1))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData([otherModel], cacheKey: nil, context: "wrong")
        otherDataProvider.setData([otherModel, otherModel], cacheKey: nil, context: "wrong")

        // First, append the initial model
        dataProvider.append([initialModel], context: "wrong")
        // Now, update the to a new model
        otherDataProvider.append([newModel], context: "context")

        XCTAssertEqual(otherDataProvider.count, 3)
        XCTAssertEqual(otherDataProvider[2].name, "new")

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    // MARK: Update

    func testUpdateItemSameId() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherModel = ParentModel(id: 2)

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider[1].name, "new")
            XCTAssertEqual(dataProvider.count, 3)
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 1))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData([otherModel, initialModel, otherModel], cacheKey: nil, context: "wrong")
        otherDataProvider.setData([otherModel, otherModel, initialModel], cacheKey: nil, context: "wrong")

        otherDataProvider.update(newModel, at: 2, context: "context")

        XCTAssertEqual(otherDataProvider.count, 3)
        XCTAssertEqual(otherDataProvider[2].name, "new")

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testUpdateItemDifferentId() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherModel = ParentModel(id: 2)

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider[1].name, "new")
            XCTAssertEqual(dataProvider.count, 3)
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 1))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData([otherModel, initialModel, otherModel], cacheKey: nil, context: "wrong")
        otherDataProvider.setData([otherModel, otherModel, otherModel], cacheKey: nil, context: "wrong")

        otherDataProvider.update(newModel, at: 1, context: "context")

        XCTAssertEqual(otherDataProvider.count, 3)
        XCTAssertEqual(otherDataProvider[1].name, "new")

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testUpdateListenOnNewModel() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherModel = ParentModel(id: 2)

        let expectation = expectationWithDescription("Wait for delegate")
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider[1].name, "new")
            XCTAssertEqual(dataProvider.count, 3)
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 1))
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData([otherModel, otherModel, otherModel], cacheKey: nil, context: "wrong")
        otherDataProvider.setData([otherModel, otherModel, otherModel], cacheKey: nil, context: "wrong")

        // First, update to the initial model
        dataProvider.update(initialModel, at: 1, context: "wrong")
        // Now, let's update this model to a new model
        otherDataProvider.update(newModel, at: 2, context: "context")

        XCTAssertEqual(otherDataProvider.count, 3)
        XCTAssertEqual(otherDataProvider[2].name, "new")

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    // MARK: - Delegate tests

    func testSingleDelegateCallbackForTwoUpdates() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let firstModel = ParentModel(id: 1, name: "", requiredChild: ChildModel(id: 3, name: "initial"), otherChildren: [])
        let secondModel = ParentModel(id: 2, name: "", requiredChild: ChildModel(id: 3, name: "initial"), otherChildren: [])
        let thirdModel = ParentModel(id: 4)

        // Note: We've updated child with id = 3
        let otherModel = ParentModel(id: 5, name: "", requiredChild: ChildModel(id: 3, name: "new"), otherChildren: [])

        var numberOfDelegateCalls = 0
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider[0].requiredChild.name, "new")
            XCTAssertEqual(dataProvider[1].requiredChild.name, "new")
            XCTAssertEqual(collectionChanges.count, 2)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 1))
            XCTAssertEqual(collectionChanges[1], CollectionChangeInformation.update(index: 0))
            numberOfDelegateCalls += 1
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureDataProviderDelegate() { context in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData([firstModel, secondModel, thirdModel], cacheKey: nil, context: "wrong")
        otherDataProvider.setData(otherModel, context: "context")

        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)

        // Even though we updated two rows in the data provider, we should just get one callback
        XCTAssertEqual(numberOfDelegateCalls, 1)
    }

    func testSingleDelegateCallbackForTwoDeletes() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let firstModel = ParentModel(id: 1, name: "", requiredChild: ChildModel(id: 3, name: "initial"), otherChildren: [])
        let secondModel = ParentModel(id: 2, name: "", requiredChild: ChildModel(id: 3, name: "initial"), otherChildren: [])
        let thirdModel = ParentModel(id: 4)

        // Note: We're going to delete this model which will cause two cascading deletes
        let otherModel = ChildModel(id: 3, name: "new")

        var numberOfDelegateCalls = 0
        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider.count, 1)
            XCTAssertEqual(collectionChanges.count, 2)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.delete(index: 1))
            XCTAssertEqual(collectionChanges[1], CollectionChangeInformation.delete(index: 0))
            numberOfDelegateCalls += 1
        }
        dataProvider.delegate = delegate

        dataProvider.setData([firstModel, secondModel, thirdModel], cacheKey: nil, context: "wrong")
        DataModelManager.sharedDataManagerNoCache.deleteModel(otherModel, context: "context")

        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)

        // Even though we updated two rows in the data provider, we should just get one callback
        XCTAssertEqual(numberOfDelegateCalls, 1)
    }

    // MARK: Timing Tests

    func testConsistencyManagerUpdateAfterSetData() {
        func testDeletingModel() {
            let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

            // Let's create this before we do the setData. This ensures that this change happened before the setData.
            let contextWrapper = ConsistencyContextWrapper(context: nil)

            let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
            let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])

            let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
                XCTFail()
            }
            dataProvider.delegate = delegate

            dataProvider.setData([initialModel], cacheKey: nil, context: "wrong")
            // This uses a date before the setData, so should be a no-op
            DataModelManager.sharedDataManagerNoCache.consistencyManager.updateWithNewModel(newModel, context: contextWrapper)

            waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)
        }
    }
}
