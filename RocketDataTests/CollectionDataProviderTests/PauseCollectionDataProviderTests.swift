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

class PauseCollectionDataProviderTests: SharedCollectionTests {

    /**
     With some shared collections:
     1) Pause two of them
     2) Edit the other in many different ways
     3) Verify the others don't change
     4) Unpause the paused collections
     5) Verify they get the changes
     */
    func testBasicPause() {
        // We update with "wrong" context in this test, so let's ignore this check.
        verifySetCollectionContext = false

        for initialCollectionPaused in [false, true] {
            cacheRequests = 0
            cacheUpdates = 0

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

            if initialCollectionPaused {
                // This should have no effect on the test either way, so let's test both ways
                XCTAssertFalse(dataProvider1.isPaused)
                dataProvider1.isPaused = true
                XCTAssertTrue(dataProvider1.isPaused)
            }

            let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
                XCTAssertEqual(context as? String, "context")
                XCTAssertEqual(listeners.count, 1)
                XCTAssertTrue(listeners[0] === dataProvider3)
                delegatesCalled += 1
            }

            let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
            batchListener.delegate = batchDelegate

            XCTAssertFalse(dataProvider2.isPaused)
            dataProvider2.isPaused = true
            XCTAssertTrue(dataProvider2.isPaused)
            XCTAssertFalse(batchListener.isPaused)
            batchListener.isPaused = true
            XCTAssertTrue(batchListener.isPaused)

            let newModel = ParentModel(id: 1)

            dataProvider1.setData([newModel], cacheKey: "cacheKey", context: "wrong")
            XCTAssertEqual(delegatesCalled, 0)
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.insert([ParentModel(id: 2)], at: 0, context: "wrong")
            XCTAssertEqual(delegatesCalled, 0)
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.append([ParentModel(id: 3)], context: "wrong")
            XCTAssertEqual(delegatesCalled, 0)
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.update(ParentModel(id: 4), at: 2, context: "wrong")
            XCTAssertEqual(delegatesCalled, 0)
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.remove(at: 1, context: "context")
            XCTAssertEqual(delegatesCalled, 0)
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider2.isPaused = false
            XCTAssertFalse(dataProvider2.isPaused)
            batchListener.isPaused = false
            XCTAssertFalse(batchListener.isPaused)

            // Now we should have correct data
            dataProviders.forEach { dataProvider in
                XCTAssertEqual(dataProvider.count, 2)
                XCTAssertEqual(dataProvider.data, dataProvider1.data)
            }
            XCTAssertEqual(delegatesCalled, 3)

            waitForCacheToFinish(dataModelManager)
            XCTAssertEqual(cacheUpdates, 5)
            // Should only have requested from the cache once
            XCTAssertEqual(cacheRequests, 1)

            // Finally, we should ensure that everyone's still listening to the new model
            // Let's nil out all the delegates since they are checking for the update
            dataProviders.forEach { dataProvider in
                dataProvider.delegate = nil
            }
            batchListener.delegate = nil

            dataProvider1.isPaused = false

            let otherDataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)
            otherDataProvider.setData(ParentModel(id: 4, name: "new", requiredChild: ChildModel(), otherChildren: []))

            waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

            dataProviders.forEach { dataProvider in
                XCTAssertEqual(dataProvider.count, 2)
                XCTAssertEqual(dataProvider[1].id, 4)
                XCTAssertEqual(dataProvider[1].name, "new")
            }

            waitForCacheToFinish(dataModelManager)
        }
    }

    /**
     With some shared collections:
     1) Pause two of them
     2) Edit the other in many different ways
     3) Verify the others don't change
     4) Edit the first data provider back to the original data
     4) Unpause the paused collections
     5) Verify no-one gets updated
     */
    func testMakeChangesThenChangeBack() {
        for initialCollectionPaused in [false, true] {
            cacheRequests = 0
            cacheUpdates = 0

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

            if initialCollectionPaused {
                // This should have no effect on the test either way, so let's test both ways
                XCTAssertFalse(dataProvider1.isPaused)
                dataProvider1.isPaused = true
                XCTAssertTrue(dataProvider1.isPaused)
            }

            let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
                XCTFail()
            }

            let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
            batchListener.delegate = batchDelegate

            XCTAssertFalse(dataProvider2.isPaused)
            dataProvider2.isPaused = true
            XCTAssertTrue(dataProvider2.isPaused)
            XCTAssertFalse(batchListener.isPaused)
            batchListener.isPaused = true
            XCTAssertTrue(batchListener.isPaused)

            let newModel = ParentModel(id: 1)

            dataProvider1.setData([newModel], cacheKey: "cacheKey", context: "context")
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.insert([ParentModel(id: 2)], at: 0, context: "context")
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.append([ParentModel(id: 3)], context: "context")
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.update(ParentModel(id: 4), at: 2, context: "context")
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.remove(at: 1, context: "context")
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.remove(at: 1, context: "context")
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.update(ParentModel(id: 0), at: 0, context: "context")
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            // We should now be back at the start with just one thing in the array - ParentModel(id: 0)

            dataProvider2.isPaused = false
            XCTAssertFalse(dataProvider2.isPaused)
            batchListener.isPaused = false
            XCTAssertFalse(batchListener.isPaused)

            // Now we should have correct data
            dataProviders.forEach { dataProvider in
                XCTAssertEqual(dataProvider.count, 1)
                XCTAssertEqual(dataProvider.data, dataProvider1.data)
            }

            waitForCacheToFinish(dataModelManager)
            XCTAssertEqual(cacheUpdates, 7)
            // Should only have requested from the cache once
            XCTAssertEqual(cacheRequests, 1)

            waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)
        }
    }

    /**
     With some shared collections:
     1) Pause two of them
     2) Edit the other in many different ways
     3) Verify the others don't change
     4) Dealloc the original collection
     5) Unpause the paused collections
     6) Verify they get the changes
     */
    func testSetDataDeallocUnpause() {
        // We update with "wrong" context in this test, so let's ignore this check.
        verifySetCollectionContext = false

        cacheRequests = 0
        cacheUpdates = 0

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

        let dataProvider2 = sharedCollectionDataProvider(delegate2)
        let dataProvider3 = sharedCollectionDataProvider(delegate3)

        let batchDelegate = ClosureBatchListenerDelegate() { listeners, context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(listeners.count, 1)
            XCTAssertTrue(listeners[0] === dataProvider3)
            delegatesCalled += 1
        }

        let batchListener = BatchDataProviderListener(dataProviders: [dataProvider3], dataModelManager: dataModelManager)
        batchListener.delegate = batchDelegate

        let dataProviders = [dataProvider2, dataProvider3]

        var expectedData = [ParentModel]()

        // This ensures that dataProvider1 is released before we unpause the others
        weak var weakDataProvider1: CollectionDataProvider<ParentModel>?
        autoreleasepool {
            let dataProvider1 = sharedCollectionDataProvider(delegate1)
            weakDataProvider1 = dataProvider1

            XCTAssertFalse(dataProvider2.isPaused)
            dataProvider2.isPaused = true
            XCTAssertTrue(dataProvider2.isPaused)
            XCTAssertFalse(batchListener.isPaused)
            batchListener.isPaused = true
            XCTAssertTrue(batchListener.isPaused)

            let newModel = ParentModel(id: 1)

            dataProvider1.setData([newModel], cacheKey: "cacheKey", context: "wrong")
            XCTAssertEqual(delegatesCalled, 0)
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.insert([ParentModel(id: 2)], at: 0, context: "wrong")
            XCTAssertEqual(delegatesCalled, 0)
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.append([ParentModel(id: 3)], context: "wrong")
            XCTAssertEqual(delegatesCalled, 0)
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.update(ParentModel(id: 4), at: 2, context: "wrong")
            XCTAssertEqual(delegatesCalled, 0)
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            dataProvider1.remove(at: 1, context: "context")
            XCTAssertEqual(delegatesCalled, 0)
            XCTAssertEqual(dataProvider2.data, [ParentModel(id: 0)])
            XCTAssertEqual(dataProvider3.data, [ParentModel(id: 0)])

            expectedData = dataProvider1.data

            // We need to flush here otherwise the consistency manager will hold onto the listener for a little while
            self.waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)
        }

        XCTAssertNil(weakDataProvider1)

        dataProvider2.isPaused = false
        XCTAssertFalse(dataProvider2.isPaused)
        batchListener.isPaused = false
        XCTAssertFalse(batchListener.isPaused)

        // Since in this case, our update is coming from the consistency manager, we need to wait here
        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 2)
            XCTAssertEqual(dataProvider.data, expectedData)
        }
        XCTAssertEqual(delegatesCalled, 3)

        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(cacheUpdates, 5)
        // Should only have requested from the cache once
        XCTAssertEqual(cacheRequests, 1)

        // Finally, we should ensure that everyone's still listening to the new model
        // Let's nil out all the delegates since they are checking for the update
        dataProviders.forEach { dataProvider in
            dataProvider.delegate = nil
        }
        batchListener.delegate = nil

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)
        otherDataProvider.setData(ParentModel(id: 4, name: "new", requiredChild: ChildModel(), otherChildren: []))

        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        dataProviders.forEach { dataProvider in
            XCTAssertEqual(dataProvider.count, 2)
            XCTAssertEqual(dataProvider[1].id, 4)
            XCTAssertEqual(dataProvider[1].name, "new")
        }

        waitForCacheToFinish(dataModelManager)
    }

    /**
    Verify that data from providers returns the most recent change.
    */
    func testDataFromProviders() {
        let dataProvider1 = sharedCollectionDataProvider(nil)
        let dataProvider2 = sharedCollectionDataProvider(nil)
        let dataProvider3 = sharedCollectionDataProvider(nil)

        dataProvider1.isPaused = true
        dataProvider2.isPaused = true
        dataProvider3.isPaused = true

        var data: DataHolder<[ParentModel]>? = dataModelManager.sharedCollectionManager.dataFromProviders(cacheKey: "cacheKey")
        // Before we do anything, data should return 0 since all data providers have this value
        XCTAssertEqual(data?.data[0].id, 0)

        dataProvider2.setData([ParentModel(id: 1)], cacheKey: "cacheKey", context: "context")

        data = dataModelManager.sharedCollectionManager.dataFromProviders(cacheKey: "cacheKey")
        XCTAssertEqual(data?.data[0].id, 1)

        dataProvider1.setData([ParentModel(id: 2)], cacheKey: "cacheKey", context: "context")

        data = dataModelManager.sharedCollectionManager.dataFromProviders(cacheKey: "cacheKey")
        XCTAssertEqual(data?.data[0].id, 2)

        dataProvider3.setData([ParentModel(id: 3)], cacheKey: "cacheKey", context: "context")

        data = dataModelManager.sharedCollectionManager.dataFromProviders(cacheKey: "cacheKey")
        XCTAssertEqual(data?.data[0].id, 3)
    }
}
