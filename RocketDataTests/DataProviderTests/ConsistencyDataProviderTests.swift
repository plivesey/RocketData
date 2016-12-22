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

class ConsistencyDataProviderTests: RocketDataTestCase {

    func testSettingSameID() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])

        let expectation = self.expectation(description: "Wait for delegate")
        let delegate = ClosureDataProviderDelegate() { context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider.data?.name, "new")
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureDataProviderDelegate() { context in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData(initialModel, updateCache: false, context: "wrong")
        otherDataProvider.setData(newModel, updateCache: false, context: "context")

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSettingSameModel() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])

        let delegate = ClosureDataProviderDelegate() { context in
            XCTFail()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureDataProviderDelegate() { context in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData(initialModel, updateCache: false, context: "wrong")
        otherDataProvider.setData(initialModel, updateCache: false, context: "wrong")

        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)
    }

    func testSettingModelWithDifferentSubtree() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(id: 3, name: "childInitial"), otherChildren: [])
        let newModel = ParentModel(id: 4, name: "new", requiredChild: ChildModel(id: 3, name: "childNew"), otherChildren: [])

        let expectation = self.expectation(description: "Wait for delegate")
        let delegate = ClosureDataProviderDelegate() { context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider.data?.name, "initial")
            XCTAssertEqual(dataProvider.data?.requiredChild.name, "childNew")
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureDataProviderDelegate() { context in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData(initialModel, updateCache: false, context: "wrong")
        otherDataProvider.setData(newModel, updateCache: false, context: "context")

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDeletingModel() {
        let expectCacheDelegate = ExpectCacheDelegate()
        let dataModelManager = DataModelManager(cacheDelegate: expectCacheDelegate)
        let dataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])

        let expectation = self.expectation(description: "Wait for delegate")
        let delegate = ClosureDataProviderDelegate() { context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertNil(dataProvider.data)
            expectation.fulfill()
        }
        dataProvider.delegate = delegate

        var numberOfTimesCalled = 0
        expectCacheDelegate.deleteModelCalled = { model, cacheKey, context in
            XCTAssertEqual(model as? ParentModel, initialModel)
            XCTAssertEqual(cacheKey, initialModel.modelIdentifier)
            XCTAssertEqual(context as? String, "context")
            numberOfTimesCalled += 1
        }

        dataProvider.setData(initialModel, updateCache: false, context: "wrong")
        dataModelManager.deleteModel(initialModel, context: "context")

        waitForExpectations(timeout: 10, handler: nil)

        waitForCacheToFinish(dataModelManager)
        XCTAssertEqual(numberOfTimesCalled, 1)
    }

    func testDeletingOptionalModel() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [ChildModel(id: 2, name: "child")])

        let expectation = self.expectation(description: "Wait for delegate")
        let delegate = ClosureDataProviderDelegate() { context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider.data?.name, "initial")
            XCTAssertEqual(dataProvider.data?.otherChildren.count, 0)
            expectation.fulfill()
        }
        dataProvider.delegate = delegate

        dataProvider.setData(initialModel, updateCache: false, context: "wrong")
        DataModelManager.sharedDataManagerNoCache.deleteModel(ChildModel(id: 2, name: "child"), context: "context")

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testDeletingRequiredModel() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(id: 3, name: "childInitial"), otherChildren: [])

        let expectation = self.expectation(description: "Wait for delegate")
        let delegate = ClosureDataProviderDelegate() { context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertNil(dataProvider.data)
            expectation.fulfill()
        }
        dataProvider.delegate = delegate

        dataProvider.setData(initialModel, updateCache: false, context: "wrong")
        DataModelManager.sharedDataManagerNoCache.deleteModel(ChildModel(id: 3, name: "childInitial"), context: "context")

        waitForExpectations(timeout: 10, handler: nil)
    }

    /**
     Given two data providers:
     - Set model1 on the first data provider
     - Set model2 on the second data provider
     - Set model3 on the first data provider

     The first data provider shouldn't have it's delegate called because it got model3 before the consistency manager completed
     */
    func testSettingModelAfterUpdate() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let updateModel = ParentModel(id: 1, name: "update", requiredChild: ChildModel(), otherChildren: [])
        let finalModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])

        let expectation = self.expectation(description: "Wait for delegate")
        let delegate = ClosureDataProviderDelegate() { context in
            // This should never get called because
            XCTFail()
        }
        dataProvider.delegate = delegate

        let otherDelegate = ClosureDataProviderDelegate() { context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider.data, finalModel)
            XCTAssertEqual(otherDataProvider.data, finalModel)
            expectation.fulfill()
        }
        otherDataProvider.delegate = otherDelegate

        // First, let's set data on data provider 1
        dataProvider.setData(initialModel, updateCache: false, context: "wrong")
        // Now, let's set the new data on data provider 2
        otherDataProvider.setData(updateModel, updateCache: false, context: "wrong")
        // Data provider one will soon get a consistency manager update, but first...
        dataProvider.setData(finalModel, updateCache: false, context: "context")

        waitForExpectations(timeout: 10, handler: nil)
    }

    // MARK: Timing Tests

    func testConsistencyManagerUpdateAfterSetData() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        // Let's create this before we do the setData. This ensures that this change happened before the setData.
        let contextWrapper = ConsistencyContextWrapper(context: nil)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])

        let delegate = ClosureDataProviderDelegate() { context in
            XCTFail()
        }
        dataProvider.delegate = delegate

        dataProvider.setData(initialModel, updateCache: false, context: "wrong")
        // This uses a date before the setData, so should be a no-op
        DataModelManager.sharedDataManagerNoCache.consistencyManager.updateModel(newModel, context: contextWrapper)

        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)
    }

    // MARK: Projection Tests

    /**
     This test is a sanity check that different model projections work.
     Most of the tests for this feature are in the ConsistencyManager project.
     It takes two data providers with different versions of the same model.
     Then, it updates one data provider and expects the other to update as well.
     */
    func testDataProviderUpdatesWhenUsingDifferentModelProjection() {
        let dataProvider = DataProvider<FullChildModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = DataProvider<ChildModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = FullChildModel(id: 1, name: "initial", otherData: 42)
        let newModel = ChildModel(id: 1, name: "new")

        let expectation = self.expectation(description: "Wait for delegate")
        let delegate = ClosureDataProviderDelegate() { context in
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(dataProvider.data?.name, "new")
            XCTAssertEqual(dataProvider.data?.otherData, 42)
            expectation.fulfill()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureDataProviderDelegate() { context in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData(initialModel, updateCache: false, context: "wrong")
        otherDataProvider.setData(newModel, updateCache: false, context: "context")

        waitForExpectations(timeout: 10, handler: nil)
    }

    /**
     This test is a sanity check that different model projections work.
     Most of the tests for this feature are in the ConsistencyManager project.
     It takes two data providers with different versions of the same model.
     It updates one data provider with a new model which doesn't affect the original model in any way.
     Then does the same thing the other way.
     */
    func testDataProviderDoesntUpdateWhenNewModelHasNoChanges() {
        let dataProvider = DataProvider<ChildModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = DataProvider<FullChildModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let initialModel = ChildModel(id: 1, name: "initial")
        // No actual change here
        let newModel = FullChildModel(id: 1, name: "initial", otherData: 42)

        let delegate = ClosureDataProviderDelegate() { context in
            XCTFail()
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureDataProviderDelegate() { context in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate

        dataProvider.setData(initialModel, updateCache: false, context: "wrong")
        otherDataProvider.setData(newModel, updateCache: false, context: "context")

        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)

        XCTAssertEqual(dataProvider.data?.name, "initial")

        dataProvider.setData(initialModel, updateCache: false, context: "wrong")

        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)

        XCTAssertEqual(otherDataProvider.data?.name, "initial")
        XCTAssertEqual(otherDataProvider.data?.otherData, 42)
    }
    
    // MARK: Listen to ID
    
    func testBasicListeningToID() {
        let dataProvider = DataProvider<ChildModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        dataProvider.modelIdentifier = "ChildModel:1"
        
        let child = ChildModel(id: 1, name: "new")
        let model = ParentModel(id: 1, name: "new", requiredChild: child, otherChildren: [])
        
        var delegateCalled = 0
        let delegate = ClosureDataProviderDelegate() { context in
            XCTAssertEqual(context as? String, "context")
            delegateCalled += 1
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureDataProviderDelegate() { context in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate
        
        otherDataProvider.setData(model, context: "context")
        
        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)
        
        XCTAssertEqual(dataProvider.data, child)
        XCTAssertEqual(delegateCalled, 1)
    }
    
    func testBasicListeningToIDFromCache() {
        let dataProvider = DataProvider<ChildModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        
        let waitForCacheMiss = expectation(description: "waitForCacheMiss")
        dataProvider.fetchDataFromCache(withCacheKey: "ChildModel:1", listenToModelIdentifier: true) { _, _ in
            waitForCacheMiss.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        
        let child = ChildModel(id: 1, name: "new")
        let model = ParentModel(id: 1, name: "new", requiredChild: child, otherChildren: [])
        
        var delegateCalled = 0
        let delegate = ClosureDataProviderDelegate() { context in
            XCTAssertEqual(context as? String, "context")
            delegateCalled += 1
        }
        dataProvider.delegate = delegate
        let otherDelegate = ClosureDataProviderDelegate() { context in
            XCTFail()
        }
        otherDataProvider.delegate = otherDelegate
        
        otherDataProvider.setData(model, context: "context")
        
        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)
        
        XCTAssertEqual(dataProvider.data, child)
        XCTAssertEqual(delegateCalled, 1)
    }
}
