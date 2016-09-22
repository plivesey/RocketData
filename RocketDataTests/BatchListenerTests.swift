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
import ConsistencyManager

class BatchListenerTests: RocketDataTestCase {

    /**
     Given a batch listener with two listeners:
     - setData on both listeners
     - cause an update which only affects one listener
     - verify that the listener and batch listener get notified
     */
    func testTwoListenersOneUpdate() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let collectionDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let batchDataProviderListener = BatchDataProviderListener(dataProviders: [dataProvider, collectionDataProvider], dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let model = ParentModel(id: 0)
        let models = [model, ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])]
        let updatedModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])

        dataProvider.setData(model)
        collectionDataProvider.setData(models, cacheKey: nil)

        let expectation = self.expectation(description: "waitForBatchUpdate")
        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === collectionDataProvider)
            XCTAssertEqual(context as? String, "context")

            XCTAssertEqual(dataProvider.data, model)
            XCTAssertEqual(collectionDataProvider[0], model)
            XCTAssertEqual(collectionDataProvider[1], updatedModel)

            expectation.fulfill()
        }
        batchDataProviderListener.delegate = batchDelegate

        let dataProviderDelegate = ClosureDataProviderDelegate() { _ in
            XCTFail()
        }
        dataProvider.delegate = dataProviderDelegate

        var calledCollectionDelegate = 0
        let collectionProviderDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            calledCollectionDelegate += 1

            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(collectionDataProvider[0], model)
            XCTAssertEqual(collectionDataProvider[1], updatedModel)

            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 1))
        }
        collectionDataProvider.delegate = collectionProviderDelegate

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        otherDataProvider.setData(updatedModel, updateCache: false, context: "context")

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(calledCollectionDelegate, 1)
    }

    /**
     Given a batch listener with two listeners:
     - setData on both listeners
     - cause an update which only affects both listeners
     - verify that both listeners and batch listener get notified
     */
    func testTwoListenersSharedUpdate() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let collectionDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let batchDataProviderListener = BatchDataProviderListener(dataProviders: [dataProvider, collectionDataProvider], dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let model = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let models = [model, ParentModel(id: 0)]
        let updatedModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])

        dataProvider.setData(model)
        collectionDataProvider.setData(models, cacheKey: nil)

        let expectation = self.expectation(description: "waitForBatchUpdate")
        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(listeners.count, 2)
            XCTAssertTrue(listeners.contains { $0 === collectionDataProvider })
            XCTAssertTrue(listeners.contains { $0 === dataProvider })
            XCTAssertEqual(context as? String, "context")

            XCTAssertEqual(dataProvider.data, updatedModel)
            XCTAssertEqual(collectionDataProvider[0], updatedModel)
            XCTAssertEqual(collectionDataProvider[1].id, 0)

            expectation.fulfill()
        }
        batchDataProviderListener.delegate = batchDelegate

        var calledDelegate = 0
        let dataProviderDelegate = ClosureDataProviderDelegate() { context in
            calledDelegate += 1
            XCTAssertEqual(dataProvider.data, updatedModel)
        }
        dataProvider.delegate = dataProviderDelegate

        var calledCollectionDelegate = 0
        let collectionProviderDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            calledCollectionDelegate += 1

            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(collectionDataProvider[0], updatedModel)
            XCTAssertEqual(collectionDataProvider[1].id, 0)

            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 0))
        }
        collectionDataProvider.delegate = collectionProviderDelegate

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        otherDataProvider.setData(updatedModel, updateCache: false, context: "context")

        waitForExpectations(timeout: 10, handler: nil)
        
        XCTAssertEqual(calledCollectionDelegate, 1)
        XCTAssertEqual(calledDelegate, 1)

        // Since both data providers got updated with the same data, they should have the same lastUpdated
        XCTAssertEqual(dataProvider.lastUpdated, collectionDataProvider.lastUpdated)
    }

    /**
     Given a batch listener with two listeners:
     - setData on both listeners
     - cause an batch update which only affects both listeners
     - verify that both listeners and batch listener get notified, but only once each
     */
    func testTwoListenersBatchUpdate() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let collectionDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let batchDataProviderListener = BatchDataProviderListener(dataProviders: [dataProvider, collectionDataProvider], dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let model = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let models = [model, ParentModel(id: 0)]

        let firstUpdatedModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let secondUpdatedModel = ParentModel(id: 0, name: "secondNew", requiredChild: ChildModel(), otherChildren: [])

        dataProvider.setData(model)
        collectionDataProvider.setData(models, cacheKey: nil)

        let expectation = self.expectation(description: "waitForBatchUpdate")
        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(listeners.count, 2)
            XCTAssertTrue(listeners.contains { $0 === collectionDataProvider })
            XCTAssertTrue(listeners.contains { $0 === dataProvider })
            XCTAssertEqual(context as? String, "context")

            XCTAssertEqual(dataProvider.data, firstUpdatedModel)
            XCTAssertEqual(collectionDataProvider[0], firstUpdatedModel)
            XCTAssertEqual(collectionDataProvider[1], secondUpdatedModel)

            expectation.fulfill()
        }
        batchDataProviderListener.delegate = batchDelegate

        var calledDelegate = 0
        let dataProviderDelegate = ClosureDataProviderDelegate() { context in
            calledDelegate += 1

            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider.data, firstUpdatedModel)
        }
        dataProvider.delegate = dataProviderDelegate

        var calledCollectionDelegate = 0
        let collectionProviderDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            calledCollectionDelegate += 1

            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(collectionDataProvider[0], firstUpdatedModel)
            XCTAssertEqual(collectionDataProvider[1], secondUpdatedModel)

            XCTAssertEqual(collectionChanges.count, 2)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 1))
            XCTAssertEqual(collectionChanges[1], CollectionChangeInformation.update(index: 0))
        }
        collectionDataProvider.delegate = collectionProviderDelegate

        DataModelManager.sharedDataManagerNoCache.updateModels([firstUpdatedModel, secondUpdatedModel], updateCache: false, context: "context")

        waitForExpectations(timeout: 10, handler: nil)
        
        XCTAssertEqual(calledCollectionDelegate, 1)
        XCTAssertEqual(calledDelegate, 1)

        // Since both data providers got updated with the same data, they should have the same lastUpdated
        XCTAssertEqual(dataProvider.lastUpdated, collectionDataProvider.lastUpdated)
    }

    /**
     Given a batch listener with two listeners:
     - setData on both listeners
     - update an element on one so it's shared with the other
     - cause an update to this new element, so both listeners should get notified
     - verify that both listeners and batch listener get notified
     */
    func testTwoListenersCollectionUpdate() {
        let collectionDataProvider1 = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let collectionDataProvider2 = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let batchDataProviderListener = BatchDataProviderListener(dataProviders: [collectionDataProvider1, collectionDataProvider2], dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let setIndexModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let updatedModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let initialModels1 = [ParentModel(id: 0)]
        let initialModels2 = [ParentModel(id: 2)]

        collectionDataProvider1.setData(initialModels1, cacheKey: nil)
        collectionDataProvider2.setData(initialModels2, cacheKey: nil)

        let expectation = self.expectation(description: "waitForBatchUpdate")
        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === collectionDataProvider1)
            XCTAssertEqual(context as? String, "context")

            XCTAssertEqual(collectionDataProvider1[0], updatedModel)
            XCTAssertEqual(collectionDataProvider2.data, initialModels2)

            expectation.fulfill()
        }
        batchDataProviderListener.delegate = batchDelegate

        var calledCollectionDelegate = 0
        let collectionProvider1Delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            calledCollectionDelegate += 1

            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(collectionDataProvider1[0], updatedModel)
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 0))
        }
        collectionDataProvider1.delegate = collectionProvider1Delegate

        let collectionProvider2Delegate = ClosureCollectionDataProviderDelegate() { _ in
            XCTFail()
        }
        collectionDataProvider2.delegate = collectionProvider2Delegate

        collectionDataProvider1.update(setIndexModel, at: 0, context: "wrong")

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        otherDataProvider.setData(updatedModel, updateCache: false, context: "context")

        waitForExpectations(timeout: 10, handler: nil)
        
        XCTAssertEqual(calledCollectionDelegate, 1)
    }

    /**
     Given a batch listener with two listeners:
     - setData on both listeners
     - insert an element on one so it's shared with the other
     - cause an update to this new element, so both listeners should get notified
     - verify that both listeners and batch listener get notified
     */
    func testTwoListenersCollectionInsert() {
        let collectionDataProvider1 = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let collectionDataProvider2 = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        
        let batchDataProviderListener = BatchDataProviderListener(dataProviders: [collectionDataProvider1, collectionDataProvider2], dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let setIndexModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let updatedModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let initialModels1 = [ParentModel(id: 0)]
        let initialModels2 = [ParentModel(id: 2)]

        collectionDataProvider1.setData(initialModels1, cacheKey: nil)
        collectionDataProvider2.setData(initialModels2, cacheKey: nil)

        let expectation = self.expectation(description: "waitForBatchUpdate")
        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === collectionDataProvider1)
            XCTAssertEqual(context as? String, "context")

            XCTAssertEqual(collectionDataProvider1[0], updatedModel)
            XCTAssertEqual(collectionDataProvider2.data, initialModels2)

            expectation.fulfill()
        }
        batchDataProviderListener.delegate = batchDelegate

        var calledCollectionDelegate = 0
        let collectionProvider1Delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            calledCollectionDelegate += 1

            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(collectionDataProvider1[0], updatedModel)
            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 0))
        }
        collectionDataProvider1.delegate = collectionProvider1Delegate

        let collectionProvider2Delegate = ClosureCollectionDataProviderDelegate() { _ in
            XCTFail()
        }
        collectionDataProvider2.delegate = collectionProvider2Delegate

        collectionDataProvider1.insert([setIndexModel], at: 0, context: "wrong")

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        otherDataProvider.setData(updatedModel, updateCache: false, context: "context")

        waitForExpectations(timeout: 10, handler: nil)
        
        XCTAssertEqual(calledCollectionDelegate, 1)
    }

    /**
     The consistency manager has extensive pause tests. This just does a basic sanity check.
     For more complex scenarios, we depend on the consistency manager tests.
     For more complex CollectionDataProvider tests, see PauseCollectionDataProviderTests.
     */
    func testBasicPausing() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let collectionDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let batchDataProviderListener = BatchDataProviderListener(dataProviders: [dataProvider, collectionDataProvider], dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 0, name: "initial", requiredChild: ChildModel(id: 1, name: "child"), otherChildren: [])
        let models = [initialModel, ParentModel(id: 1, name: "other", requiredChild: ChildModel(), otherChildren: [])]
        let updatedModel = ParentModel(id: 0, name: "new", requiredChild: ChildModel(id: 1, name: "new"), otherChildren: [])

        dataProvider.setData(initialModel)
        collectionDataProvider.setData(models, cacheKey: nil)

        var numberOfTimesCalled = 0
        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            numberOfTimesCalled += 1

            XCTAssertEqual(listeners.count, 2)
            XCTAssertTrue(listeners.contains { $0 === collectionDataProvider })
            XCTAssertTrue(listeners.contains { $0 === dataProvider })
            XCTAssertEqual(context as? String, "context")

            XCTAssertEqual(dataProvider.data, updatedModel)
            XCTAssertEqual(collectionDataProvider[0], updatedModel)
        }
        batchDataProviderListener.delegate = batchDelegate

        var calledDataProviderDelegate = 0
        let dataProviderDelegate = ClosureDataProviderDelegate() { context in
            calledDataProviderDelegate += 1

            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider.data, updatedModel)
        }
        dataProvider.delegate = dataProviderDelegate

        var calledCollectionDelegate = 0
        let collectionProviderDelegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            calledCollectionDelegate += 1

            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(collectionDataProvider[0], updatedModel)

            XCTAssertEqual(collectionChanges.count, 1)
            XCTAssertEqual(collectionChanges[0], CollectionChangeInformation.update(index: 0))
        }
        collectionDataProvider.delegate = collectionProviderDelegate

        XCTAssertFalse(batchDataProviderListener.isPaused)
        batchDataProviderListener.isPaused = true
        XCTAssertTrue(batchDataProviderListener.isPaused)

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        otherDataProvider.setData(ParentModel(id: 0, name: "new", requiredChild: ChildModel(id: 1, name: "child"), otherChildren: []), context: "first")

        XCTAssertEqual(dataProvider.data, initialModel)
        XCTAssertEqual(collectionDataProvider.data, models)
        XCTAssertEqual(numberOfTimesCalled, 0)
        XCTAssertEqual(calledDataProviderDelegate, 0)
        XCTAssertEqual(calledCollectionDelegate, 0)

        DataModelManager.sharedDataManagerNoCache.updateModel(ChildModel(id: 1, name: "new"), context: "context")

        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)

        XCTAssertEqual(dataProvider.data, initialModel)
        XCTAssertEqual(collectionDataProvider.data, models)
        XCTAssertEqual(numberOfTimesCalled, 0)
        XCTAssertEqual(calledDataProviderDelegate, 0)
        XCTAssertEqual(calledCollectionDelegate, 0)

        batchDataProviderListener.isPaused = false
        XCTAssertFalse(batchDataProviderListener.isPaused)

        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)

        XCTAssertEqual(dataProvider.data, updatedModel)
        XCTAssertEqual(collectionDataProvider[0], updatedModel)
        XCTAssertEqual(numberOfTimesCalled, 1)
        XCTAssertEqual(calledDataProviderDelegate, 1)
        XCTAssertEqual(calledCollectionDelegate, 1)
    }
}
