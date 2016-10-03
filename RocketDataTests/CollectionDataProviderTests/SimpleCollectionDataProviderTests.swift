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

class SimpleCollectionDataProviderTests: RocketDataTestCase {

    // MARK: - Set Data

    func testSetData() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        XCTAssertEqual(dataProvider.data, [])
        let model = ParentModel(id: 1)
        dataProvider.setData([model], cacheKey: nil)
        XCTAssertEqual(dataProvider.data[0].id, 1)
        XCTAssertEqual(dataProvider[0].id, 1)
        XCTAssertEqual(dataProvider.count, 1)
        dataProvider.setData([], cacheKey: nil)
        XCTAssertEqual(dataProvider.count, 0)
    }

    func testSetDataCaching() {
        let cache = ExpectCacheDelegate()
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager(cacheDelegate: cache))

        let expectation = self.expectation(description: "Wait for delegate")
        cache.setCollectionCalled = { collection, cacheKey, context in
            XCTAssertTrue(collection[0] is ParentModel)
            XCTAssertEqual((collection[0] as? ParentModel)?.id, 1)
            XCTAssertEqual(cacheKey, "cacheKey")
            XCTAssertEqual(context as? String, "context")
            expectation.fulfill()
        }

        let model = ParentModel(id: 1)
        dataProvider.setData([model], cacheKey: "cacheKey", context: "context")

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testSetDataNoCaching() {
        let cache = ExpectCacheDelegate()
        let dataModelManager = ExpectCacheDataModelManager(cacheDelegate: cache)
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)

        let model = ParentModel(id: 1)
        dataProvider.setData([model], cacheKey: nil, context: nil)
        XCTAssertEqual(dataModelManager.cacheCollectionCalled, 0)
    }

    func testFetchDataSuccess() {
        let cache = ExpectCacheDelegate()
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager(cacheDelegate: cache))

        cache.collectionForKeyCalled = { key, context, completion in
            XCTAssertEqual(key, "cacheKey")
            XCTAssertEqual(context as? String, "context")
            let model = ParentModel(id: 1)
            completion([model], nil)
        }

        let expectation = self.expectation(description: "Wait for delegate")
        dataProvider.fetchDataFromCache(withCacheKey: "cacheKey", context: "context") { collection, error in
            XCTAssertEqual(collection?[0].id, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(dataProvider[0].id, 1)
    }

    func testFetchDataFail() {
        let cache = ExpectCacheDelegate()
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager(cacheDelegate: cache))

        let expectedError = NSError(domain: "", code: 0, userInfo: nil)

        cache.collectionForKeyCalled = { key, context, completion in
            XCTAssertEqual(key, "cacheKey")
            XCTAssertEqual(context as? String, "context")
            completion(nil, expectedError)
        }

        let expectation = self.expectation(description: "Wait for delegate")
        dataProvider.fetchDataFromCache(withCacheKey: "cacheKey", context: "context") { collection, error in
            XCTAssertNil(collection)
            XCTAssertTrue(error === expectedError)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(dataProvider.count, 0)
    }

    // MARK: - Mutating methods

    func testInsert() {
        let cacheDelegate = ExpectCacheDelegate()
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager(cacheDelegate: cacheDelegate))

        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherModel = ParentModel(id: 2)

        var expectation = self.expectation(description: "setCollection")
        cacheDelegate.setCollectionCalled = { collection, key, context in
            XCTAssertEqual(collection.count, 2)
            expectation.fulfill()
        }

        dataProvider.setData([otherModel, otherModel], cacheKey: "cacheKey", context: "wrong")

        // We need to wait for the initial setCollectionCalled to process before we test what we actually want to test
        waitForExpectations(timeout: 10, handler: nil)

        expectation = self.expectation(description: "insert")
        cacheDelegate.setCollectionCalled = { collection, key, context in
            XCTAssertEqual((collection[1] as? ParentModel)?.name, "new")
            XCTAssertEqual(collection.count, 3)
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(key, "cacheKey")
            expectation.fulfill()
        }

        dataProvider.insert([newModel], at: 1, context: "context")

        XCTAssertEqual(dataProvider.count, 3)
        XCTAssertEqual(dataProvider[1].name, "new")

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testAppend() {
        let cacheDelegate = ExpectCacheDelegate()
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager(cacheDelegate: cacheDelegate))

        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherModel = ParentModel(id: 2)

        var expectation = self.expectation(description: "setCollection")
        cacheDelegate.setCollectionCalled = { collection, key, context in
            XCTAssertEqual(collection.count, 2)
            expectation.fulfill()
        }

        dataProvider.setData([otherModel, otherModel], cacheKey: "cacheKey", context: "wrong")

        // We need to wait for the initial setCollectionCalled to process before we test what we actually want to test
        waitForExpectations(timeout: 10, handler: nil)

        expectation = self.expectation(description: "append")
        cacheDelegate.setCollectionCalled = { collection, key, context in
            XCTAssertEqual((collection[2] as? ParentModel)?.name, "new")
            XCTAssertEqual(collection.count, 3)
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(key, "cacheKey")
            expectation.fulfill()
        }

        dataProvider.append([newModel], context: "context")

        XCTAssertEqual(dataProvider.count, 3)
        XCTAssertEqual(dataProvider[2].name, "new")

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testUpdate() {
        let cacheDelegate = ExpectCacheDelegate()
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager(cacheDelegate: cacheDelegate))

        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherModel = ParentModel(id: 2)

        var expectation = self.expectation(description: "setCollection")
        cacheDelegate.setCollectionCalled = { collection, key, context in
            XCTAssertEqual(collection.count, 2)
            expectation.fulfill()
        }

        dataProvider.setData([otherModel, otherModel], cacheKey: "cacheKey", context: "wrong")

        // We need to wait for the initial setCollectionCalled to process before we test what we actually want to test
        waitForExpectations(timeout: 10, handler: nil)

        expectation = self.expectation(description: "update")
        cacheDelegate.setCollectionCalled = { collection, key, context in
            XCTAssertEqual((collection[1] as? ParentModel)?.name, "new")
            XCTAssertEqual(collection.count, 2)
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(key, "cacheKey")
            expectation.fulfill()
        }

        dataProvider.update(newModel, at: 1, context: "context")

        XCTAssertEqual(dataProvider.count, 2)
        XCTAssertEqual(dataProvider[1].name, "new")

        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testRemove() {
        let cacheDelegate = ExpectCacheDelegate()
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager(cacheDelegate: cacheDelegate))

        let firstModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let secondModel = ParentModel(id: 2)

        var expectation = self.expectation(description: "setCollection")
        cacheDelegate.setCollectionCalled = { collection, key, context in
            XCTAssertEqual(collection.count, 2)
            expectation.fulfill()
        }

        dataProvider.setData([firstModel, secondModel], cacheKey: "cacheKey", context: "wrong")

        // We need to wait for the initial setCollectionCalled to process before we test what we actually want to test
        waitForExpectations(timeout: 10, handler: nil)

        expectation = self.expectation(description: "update")
        cacheDelegate.setCollectionCalled = { collection, key, context in
            XCTAssertEqual((collection[0] as? ParentModel)?.name, "initial")
            XCTAssertEqual(collection.count, 1)
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(key, "cacheKey")
            expectation.fulfill()
        }

        dataProvider.remove(at: 1, context: "context")

        XCTAssertEqual(dataProvider.count, 1)
        XCTAssertEqual(dataProvider[0].name, "initial")

        waitForExpectations(timeout: 10, handler: nil)
    }

    // MARK: Fetch data no-ops

    func testFetchFromCacheTwice() {
        let cache = ExpectCacheDelegate()
        let dataModelManager = ExpectCacheDataModelManager(cacheDelegate: cache)
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)

        cache.collectionForKeyCalled = { key, context, completion in
            XCTAssertEqual(key, "cacheKey")
            XCTAssertEqual(context as? String, "context")
            let model = ParentModel(id: 1)
            completion([model], nil)
        }

        var expectation = self.expectation(description: "Wait for delegate")
        dataProvider.fetchDataFromCache(withCacheKey: "cacheKey", context: "context") { collection, error in
            XCTAssertEqual(collection?[0].id, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(dataProvider[0].id, 1)
        XCTAssertEqual(dataModelManager.collectionFromCacheCalled, 1)

        expectation = self.expectation(description: "Wait for delegate 2")
        dataProvider.fetchDataFromCache(withCacheKey: "cacheKey", context: "context") { collection, error in
            XCTAssertEqual(collection?[0].id, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(dataProvider[0].id, 1)
        // Even though we fetched again, we shouldn't have actually hit the cache
        XCTAssertEqual(dataModelManager.collectionFromCacheCalled, 1)
    }

    func testSetDataThenFetchFromCache() {
        let cache = ExpectCacheDelegate()
        let dataModelManager = ExpectCacheDataModelManager(cacheDelegate: cache)
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)

        cache.collectionForKeyCalled = { key, context, completion in
            XCTAssertEqual(key, "cacheKey")
            XCTAssertEqual(context as? String, "context")
            let model = ParentModel(id: 1)
            completion([model], nil)
        }

        dataProvider.setData([ParentModel(id: 1)], cacheKey: "cacheKey")

        XCTAssertEqual(dataProvider[0].id, 1)
        XCTAssertEqual(dataModelManager.collectionFromCacheCalled, 0)

        let expectation = self.expectation(description: "Wait for delegate")
        dataProvider.fetchDataFromCache(withCacheKey: "cacheKey", context: "context") { collection, error in
            XCTAssertEqual(collection?[0].id, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(dataProvider[0].id, 1)
        // Since we already setData, we shouldn't have hit the cache
        XCTAssertEqual(dataModelManager.collectionFromCacheCalled, 0)
    }

    func testFetchFailThenFetchSuccess() {
        let cache = ExpectCacheDelegate()
        let dataModelManager = ExpectCacheDataModelManager(cacheDelegate: cache)
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)

        cache.collectionForKeyCalled = { key, context, completion in
            completion(nil, NSError(domain: "", code: 0, userInfo: nil))
        }

        var expectation = self.expectation(description: "Wait for delegate")
        dataProvider.fetchDataFromCache(withCacheKey: "cacheKey", context: "context") { collection, error in
            XCTAssertNil(collection)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(dataProvider.count, 0)
        XCTAssertEqual(dataModelManager.collectionFromCacheCalled, 1)

        // Now, the cache will succeed
        cache.collectionForKeyCalled = { key, context, completion in
            XCTAssertEqual(key, "cacheKey")
            XCTAssertEqual(context as? String, "context")
            let model = ParentModel(id: 1)
            completion([model], nil)
        }

        expectation = self.expectation(description: "Wait for delegate 2")
        dataProvider.fetchDataFromCache(withCacheKey: "cacheKey", context: "context") { collection, error in
            XCTAssertEqual(collection?[0].id, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)

        XCTAssertEqual(dataProvider[0].id, 1)
        // Since we needed to fetch twice, this should be 2
        XCTAssertEqual(dataModelManager.collectionFromCacheCalled, 2)
    }

    class ExpectCacheDataModelManager: DataModelManager {

        var cacheCollectionCalled = 0
        var collectionFromCacheCalled = 0

        override func cacheCollection<T: SimpleModel>(_ collection: [T], forKey cacheKey: String, context: Any?) {
            cacheCollectionCalled += 1
            super.cacheCollection(collection, forKey: cacheKey, context: context)
        }

        override func collectionFromCache<T : SimpleModel>(_ cacheKey: String?, context: Any?, completion: @escaping ([T]?, NSError?) -> ()) {
            collectionFromCacheCalled += 1
            super.collectionFromCache(cacheKey, context: context, completion: completion)
        }
    }


}
