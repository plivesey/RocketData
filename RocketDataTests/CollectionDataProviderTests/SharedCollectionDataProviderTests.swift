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
import RocketData

class SharedCollectionDataProviderTests: SharedCollectionTests {

    /**
     Given three shared data providers (one with a batch listener):
     setData on one and verify that the change propegates to the others.
     Verify that each data provider is listening to the new models.
     */
    func testSetData() {
        var delegatesCalled = 0
        let delegate1 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }
        let delegate2 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes, CollectionChange.reset)
            delegatesCalled += 1
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes, CollectionChange.reset)
            delegatesCalled += 1
        }

        let dataProvider1 = sharedCollectionDataProvider(delegate1)
        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider1, dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === dataProvider3)
            delegatesCalled += 1
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        let newModel = ParentModel(id: 1)
        dataProvider1.setData([newModel, newModel], cacheKey: "cacheKey", context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 2)
            XCTAssertEqual(dataProvider[0].id, 1)
            XCTAssertEqual(dataProvider[1].id, 1)
        }
        XCTAssertEqual(delegatesCalled, 3)

        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 1)
        // Should only have requested from the cache once
        XCTAssertEqual(cacheRequests, 1)

        // Finally, we should ensure that everyones still listening to the new model
        // Let's nil out all the delegates since they are checking for the update
        dataProviders.forEach { dataProvider in
            dataProvider.delegate = nil
        }
        batchListener.delegate = nil

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)
        otherDataProvider.setData(ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: []))

        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 2)
            XCTAssertEqual(dataProvider[0].id, 1)
            XCTAssertEqual(dataProvider[0].name, "new")
            XCTAssertEqual(dataProvider[1].id, 1)
            XCTAssertEqual(dataProvider[1].name, "new")
        }
    }

    /**
     Given two shared data providers (one with a batch listener):
     setData with the class method and verify that the change propegates to the others.
     Verify that each data provider is listening to the new models.
     */
    func testSetDataClassMethod() {
        var delegatesCalled = 0
        let delegate2 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes, CollectionChange.reset)
            delegatesCalled += 1
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes, CollectionChange.reset)
            delegatesCalled += 1
        }

        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === dataProvider3)
            delegatesCalled += 1
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        let newModel = ParentModel(id: 1)
        CollectionDataProvider<ParentModel>.setData([newModel, newModel], cacheKey: "cacheKey", dataModelManager: dataModelManager, context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 2)
            XCTAssertEqual(dataProvider[0].id, 1)
            XCTAssertEqual(dataProvider[1].id, 1)
        }
        XCTAssertEqual(delegatesCalled, 3)

        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 1)
        // Should only have requested from the cache once
        XCTAssertEqual(cacheRequests, 1)

        // Finally, we should ensure that everyones still listening to the new model
        // Let's nil out all the delegates since they are checking for the update
        dataProviders.forEach { dataProvider in
            dataProvider.delegate = nil
        }
        batchListener.delegate = nil

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)
        otherDataProvider.setData(ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: []))

        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 2)
            XCTAssertEqual(dataProvider[0].id, 1)
            XCTAssertEqual(dataProvider[0].name, "new")
            XCTAssertEqual(dataProvider[1].id, 1)
            XCTAssertEqual(dataProvider[1].name, "new")
        }
    }

    /**
     Given three shared data providers (one with a batch listener):
     setData on one but set data that doesn't make a change.
     No-one should update.
     */
    func testSetDataNoChange() {
        // Since we're setting the same data, we shouldn't get any delegate callbacks
        let delegate1 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }
        let delegate2 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }

        let dataProvider1 = sharedCollectionDataProvider(delegate1)
        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider1, dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTFail()
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        dataProvider1.setData(dataProvider1.data, cacheKey: "cacheKey", context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 1)
            XCTAssertEqual(dataProvider[0].id, 0)
        }

        XCTAssertEqual(cacheRequests, 1)
    }

    /**
     Given two shared data providers (one with a batch listener):
     setData with the class method but set data that doesn't make a change.
     No-one should update.
     */
    func testSetDataNoChangeClassMethod() {
        // Since we're setting the same data, we shouldn't get any delegate callbacks
        let delegate2 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }

        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTFail()
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        CollectionDataProvider<ParentModel>.setData(dataProvider2.data, cacheKey: "cacheKey", dataModelManager: dataModelManager, context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 1)
            XCTAssertEqual(dataProvider[0].id, 0)
        }

        XCTAssertEqual(cacheRequests, 1)
    }

    /**
     Given three shared data providers (one with a batch listener):
     update on one and verify that the change propegates to the others.
     Verify that each data provider is listening to the new models.
     */
    func testUpdate() {
        var delegatesCalled = 0
        let delegate1 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }
        let delegate2 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .update(index: 0))
            delegatesCalled += 1
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .update(index: 0))
            delegatesCalled += 1
        }

        let dataProvider1 = sharedCollectionDataProvider(delegate1)
        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider1, dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === dataProvider3)
            delegatesCalled += 1
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        let newModel = ParentModel(id: 1)
        dataProvider1.update(newModel, at: 0, context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 1)
            XCTAssertEqual(dataProvider[0].id, 1)
        }
        XCTAssertEqual(delegatesCalled, 3)
        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 1)
        // Should only have requested from the cache once
        XCTAssertEqual(cacheRequests, 1)

        // Finally, we should ensure that everyones still listening to the new model
        // Let's nil out all the delegates since they are checking for the update
        dataProviders.forEach { dataProvider in
            dataProvider.delegate = nil
        }
        batchListener.delegate = nil

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)
        otherDataProvider.setData(ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: []))

        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 1)
            XCTAssertEqual(dataProvider[0].id, 1)
            XCTAssertEqual(dataProvider[0].name, "new")
        }
    }

    /**
     Given two shared data providers (one with a batch listener):
     update with the class method and verify that the change propegates to the data providers.
     Verify that each data provider is listening to the new models.
     */
    func testUpdateClassMethod() {
        var delegatesCalled = 0
        let delegate2 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .update(index: 0))
            delegatesCalled += 1
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .update(index: 0))
            delegatesCalled += 1
        }

        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === dataProvider3)
            delegatesCalled += 1
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        let newModel = ParentModel(id: 1)
        CollectionDataProvider<ParentModel>.update(newModel, at: { _ in return 0 }, cacheKey: "cacheKey", dataModelManager: dataModelManager, context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 1)
            XCTAssertEqual(dataProvider[0].id, 1)
        }
        XCTAssertEqual(delegatesCalled, 3)
        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 1)
        // Should only have requested from the cache once
        XCTAssertEqual(cacheRequests, 1)

        // Finally, we should ensure that everyones still listening to the new model
        // Let's nil out all the delegates since they are checking for the update
        dataProviders.forEach { dataProvider in
            dataProvider.delegate = nil
        }
        batchListener.delegate = nil

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)
        otherDataProvider.setData(ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: []))

        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 1)
            XCTAssertEqual(dataProvider[0].id, 1)
            XCTAssertEqual(dataProvider[0].name, "new")
        }
    }

    /**
     Given three shared data providers (one with a batch listener):
     insert on one and verify that the change propegates to the others.
     Verify that each data provider is listening to the new models.
     */
    func testInsert() {
        var delegatesCalled = 0
        let delegate1 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }
        let delegate2 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .insert(index: 0))
            delegatesCalled += 1
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .insert(index: 0))
            delegatesCalled += 1
        }

        let dataProvider1 = sharedCollectionDataProvider(delegate1)
        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider1, dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === dataProvider3)
            delegatesCalled += 1
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        let newModel = ParentModel(id: 1)
        dataProvider1.insert([newModel], at: 0, context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 2)
            XCTAssertEqual(dataProvider[0].id, 1)
        }
        XCTAssertEqual(delegatesCalled, 3)
        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 1)
        // Should only have requested from the cache once
        XCTAssertEqual(cacheRequests, 1)

        // Finally, we should ensure that everyones still listening to the new model
        // Let's nil out all the delegates since they are checking for the update
        dataProviders.forEach { dataProvider in
            dataProvider.delegate = nil
        }
        batchListener.delegate = nil

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)
        otherDataProvider.setData(ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: []))

        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 2)
            XCTAssertEqual(dataProvider[0].id, 1)
            XCTAssertEqual(dataProvider[0].name, "new")
        }
    }

    /**
     Given two shared data providers (one with a batch listener):
     insert with the class method and verify that the change propegates to the data providers.
     Verify that each data provider is listening to the new models.
     */
    func testInsertClassMethod() {
        var delegatesCalled = 0
        let delegate2 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .insert(index: 0))
            delegatesCalled += 1
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .insert(index: 0))
            delegatesCalled += 1
        }

        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === dataProvider3)
            delegatesCalled += 1
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        let newModel = ParentModel(id: 1)
        CollectionDataProvider<ParentModel>.insert([newModel], at: { _ in return 0 }, cacheKey: "cacheKey", dataModelManager: dataModelManager, context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 2)
            XCTAssertEqual(dataProvider[0].id, 1)
        }
        XCTAssertEqual(delegatesCalled, 3)
        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 1)
        // Should only have requested from the cache once
        XCTAssertEqual(cacheRequests, 1)

        // Finally, we should ensure that everyones still listening to the new model
        // Let's nil out all the delegates since they are checking for the update
        dataProviders.forEach { dataProvider in
            dataProvider.delegate = nil
        }
        batchListener.delegate = nil

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)
        otherDataProvider.setData(ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: []))

        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 2)
            XCTAssertEqual(dataProvider[0].id, 1)
            XCTAssertEqual(dataProvider[0].name, "new")
        }
    }

    /**
     Given three shared data providers (one with a batch listener):
     Append multiple items on one and verify that the change propegates to the others.
     Verify that each data provider is listening to the new models.
     */
    func testAppendMultipleItems() {
        var delegatesCalled = 0
        let delegate1 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }
        let delegate2 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 2)
            XCTAssertEqual(changes[0], .insert(index: 1))
            XCTAssertEqual(changes[1], .insert(index: 2))
            delegatesCalled += 1
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 2)
            XCTAssertEqual(changes[0], .insert(index: 1))
            XCTAssertEqual(changes[1], .insert(index: 2))
            delegatesCalled += 1
        }

        let dataProvider1 = sharedCollectionDataProvider(delegate1)
        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider1, dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === dataProvider3)
            delegatesCalled += 1
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        let newModel = ParentModel(id: 1)
        dataProvider1.append([newModel, newModel], context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 3)
            XCTAssertEqual(dataProvider[1].id, 1)
            XCTAssertEqual(dataProvider[2].id, 1)
        }
        XCTAssertEqual(delegatesCalled, 3)
        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 1)
        // Should only have requested from the cache once
        XCTAssertEqual(cacheRequests, 1)

        // Finally, we should ensure that everyones still listening to the new model
        // Let's nil out all the delegates since they are checking for the update
        dataProviders.forEach { dataProvider in
            dataProvider.delegate = nil
        }
        batchListener.delegate = nil

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)
        otherDataProvider.setData(ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: []))

        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 3)
            XCTAssertEqual(dataProvider[1].id, 1)
            XCTAssertEqual(dataProvider[1].name, "new")
            XCTAssertEqual(dataProvider[2].id, 1)
            XCTAssertEqual(dataProvider[2].name, "new")
        }
    }

    /**
     Given two shared data providers (one with a batch listener):
     Append multiple items with the class method and verify that the change propegates to the data providers.
     Verify that each data provider is listening to the new models.
     */
    func testAppendMultipleItemsClassMethod() {
        var delegatesCalled = 0
        let delegate2 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 2)
            XCTAssertEqual(changes[0], .insert(index: 1))
            XCTAssertEqual(changes[1], .insert(index: 2))
            delegatesCalled += 1
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 2)
            XCTAssertEqual(changes[0], .insert(index: 1))
            XCTAssertEqual(changes[1], .insert(index: 2))
            delegatesCalled += 1
        }

        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === dataProvider3)
            delegatesCalled += 1
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        let newModel = ParentModel(id: 1)
        CollectionDataProvider<ParentModel>.append([newModel, newModel], cacheKey: "cacheKey", dataModelManager: dataModelManager, context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 3)
            XCTAssertEqual(dataProvider[1].id, 1)
            XCTAssertEqual(dataProvider[2].id, 1)
        }
        XCTAssertEqual(delegatesCalled, 3)
        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 1)
        // Should only have requested from the cache once
        XCTAssertEqual(cacheRequests, 1)

        // Finally, we should ensure that everyones still listening to the new model
        // Let's nil out all the delegates since they are checking for the update
        dataProviders.forEach { dataProvider in
            dataProvider.delegate = nil
        }
        batchListener.delegate = nil

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)
        otherDataProvider.setData(ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: []))

        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 3)
            XCTAssertEqual(dataProvider[1].id, 1)
            XCTAssertEqual(dataProvider[1].name, "new")
            XCTAssertEqual(dataProvider[2].id, 1)
            XCTAssertEqual(dataProvider[2].name, "new")
        }
    }

    /**
     Given three shared data providers (one with a batch listener):
     remove on one and verify that the change propegates to the others.
     No need to test for listening to new models because there are no new models.
     */
    func testRemove() {
        var delegatesCalled = 0
        let delegate1 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }
        let delegate2 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .delete(index: 0))
            delegatesCalled += 1
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .delete(index: 0))
            delegatesCalled += 1
        }

        let dataProvider1 = sharedCollectionDataProvider(delegate1)
        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider1, dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === dataProvider3)
            delegatesCalled += 1
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        dataProvider1.removeAtIndex(0, context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 0)
        }
        XCTAssertEqual(delegatesCalled, 3)
        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 1)
        // Should only have requested from the cache once
        XCTAssertEqual(cacheRequests, 1)
    }

    /**
     Given two shared data providers (one with a batch listener):
     remove with the class method and verify that the change propegates to the data providers.
     No need to test for listening to new models because there are no new models.
     */
    func testRemoveWithClassMethod() {
        var delegatesCalled = 0
        let delegate2 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .delete(index: 0))
            delegatesCalled += 1
        }
        let delegate3 = ClosureCollectionDataProviderDelegate() { changes, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(changes.count, 1)
            XCTAssertEqual(changes[0], .delete(index: 0))
            delegatesCalled += 1
        }

        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)
        let dataProviders = [dataProvider2, dataProvider3]

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === dataProvider3)
            delegatesCalled += 1
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        CollectionDataProvider<ParentModel>.removeAtIndex({ _ in return 0 }, cacheKey: "cacheKey", dataModelManager: dataModelManager, context: "context")
        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 0)
        }
        XCTAssertEqual(delegatesCalled, 3)
        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 1)
        // Should only have requested from the cache once
        XCTAssertEqual(cacheRequests, 1)
    }

    /**
     When we use different cacheKeys nothing should be shared.
     Sanity check.
     */
    func testDifferentCacheKeys() {
        let delegate = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }
        let sharedDataProvider = sharedCollectionDataProvider(delegate)

        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)
        otherDataProvider.delegate = delegate

        cacheDelegate.collectionForKeyCalled = { cacheKey, context, completion in
            XCTAssertEqual(context as? String, "cacheContext")
            XCTAssertEqual(cacheKey, "otherCacheKey")
            self.cacheRequests += 1
            let initialModels: [Any] = [ParentModel(id: 0)]
            completion(initialModels, nil)
        }

        let expectation = expectationWithDescription("waitForCache")
        // Fetching from the cache will set the cacheKey
        otherDataProvider.fetchDataFromCache(cacheKey: "otherCacheKey", context: "cacheContext") { (_, _) in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)

        // Let's run a bunch of changes
        let model = ParentModel(id: 1)
        sharedDataProvider.update(model, at: 0, context: "context")
        sharedDataProvider.setData([model, model], cacheKey: "cacheKey", context: "context")
        sharedDataProvider.removeAtIndex(1, context: "context")
        sharedDataProvider.insert([model], at: 1, context: "context")

        // Shouldn't have changed the other data provider
        XCTAssertEqual(otherDataProvider.count, 1)
        XCTAssertEqual(otherDataProvider[0].id, 0)

        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 4)
    }

    /**
     This is a more complex test.
     First, we start a collection loading from the cache.
     Then, we add another collection with the same cacheKey and call setData with different data to the cache.
     Then, the cache returns.
     At this point, we expect the first collection should have the data from setData (not the cache)
     This ensures that data providers are always in sync across cache loading boundries.
     */
    func testAddCollectionWhileCacheLoads() {
        var collectionForKeyCalledExpectation: (()->Void)?
        let finishCacheLoadExpectation = expectationWithDescription("Wait for collectionForKeyCalledExpectation to be set")
        cacheDelegate.collectionForKeyCalled = { cacheKey, context, completion in
            XCTAssertEqual(context as? String, "cacheContext")
            XCTAssertEqual(cacheKey, "cacheKey")
            self.cacheRequests += 1
            let initialModels: [Any] = [ParentModel(id: 0)]
            collectionForKeyCalledExpectation = {
                completion(initialModels, nil)
            }
            finishCacheLoadExpectation.fulfill()
        }

        let delegate = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }

        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)
        dataProvider.delegate = delegate

        // This is a little tricky. We want to add another expectation here, but we can't because we already have one waiting for finishCacheLoad to be set
        // So, we'll create a closure which we can set later in the test
        var dataProviderLoadFinished = {}

        // Start loading from the cache
        dataProvider.fetchDataFromCache(cacheKey: "cacheKey", context: "cacheContext") { _, _ in
            dataProviderLoadFinished()
        }

        // Wait for it to hit the cache
        // This ensures that the finishCacheLoad block will be called
        waitForExpectationsWithTimeout(10, handler: nil)

        // Create another data provider, and call setData before the cache finishes
        let otherDataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)
        otherDataProvider.delegate = delegate
        otherDataProvider.setData([ParentModel(id: 1)], cacheKey: "cacheKey", context: "context")

        // At this point, we are still waiting for cached data, so data provider cacheKey should still be nil
        // This is only set once we're synced with the cacheKey
        XCTAssertNil(dataProvider.cacheKey)

        if let collectionForKeyCalledExpectation = collectionForKeyCalledExpectation {
            collectionForKeyCalledExpectation()
        } else {
            XCTFail("collectionForKeyCalledExpectation closure wasn't set. This means we probably have a race condition in this test. The 'Wait for collectionForKeyCalledExpectation to be set' expectation should wait for this to happen.")
        }

        let expectation = expectationWithDescription("Wait for data provider to call completion")
        dataProviderLoadFinished = {
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertEqual(dataProvider.cacheKey, "cacheKey")
        XCTAssertEqual(dataProvider.data, otherDataProvider.data)
    }

    /**
     Verify that listeners are released when they go out of scope (basically testing the weak array).
     */
    func testDeallocation() {
        let delegate1 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }
        let delegate2 = ClosureCollectionDataProviderDelegate() { _, _ in
            XCTFail()
        }

        let dataProvider1 = sharedCollectionDataProvider(delegate1)
        weak var weakDataProvider2: CollectionDataProvider<ParentModel>?
        autoreleasepool {
            let dataProvider2 = sharedCollectionDataProvider(delegate2)
            weakDataProvider2 = dataProvider2
            // The consistency manager temporarily holds onto the data provider when you add a listener
            // Let's wait for it to release us
            waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)
        }
        XCTAssertNil(weakDataProvider2)

        dataProvider1.removeAtIndex(0, context: "context")

        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 1)
        XCTAssertEqual(cacheRequests, 1)
        XCTAssertNil(weakDataProvider2)
    }
}
