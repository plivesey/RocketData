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

class SimpleDataProviderTests: RocketDataTestCase {

    func testSetData() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        XCTAssertNil(dataProvider.data)
        let model = ParentModel(id: 1)
        dataProvider.setData(model)
        XCTAssertEqual(dataProvider.data?.id, 1)
        dataProvider.setData(nil)
        XCTAssertNil(dataProvider.data)
    }

    func testSetDataCaching() {
        let cache = ExpectCacheDelegate()
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager(cacheDelegate: cache))

        let expectation = expectationWithDescription("")
        cache.setModelCalled = { model, cacheKey, context in
            XCTAssertTrue(model is ParentModel)
            XCTAssertEqual((model as? ParentModel)?.id, 1)
            XCTAssertEqual(cacheKey, "ParentModel:1")
            XCTAssertEqual(context as? String, "context")
            expectation.fulfill()
        }

        let model = ParentModel(id: 1)
        dataProvider.setData(model, context: "context")

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testSetDataNoCaching() {
        let cache = ExpectCacheDelegate()
        let dataModelManager = ExpectCacheDataModelManager(cacheDelegate: cache)
        let dataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)

        let model = ParentModel(id: 1)
        dataProvider.setData(model, updateCache: false, context: nil)
        XCTAssertEqual(dataModelManager.cacheModelCalled, 0)
    }

    func testFetchDataSuccess() {
        let cache = ExpectCacheDelegate()
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager(cacheDelegate: cache))

        cache.modelForKeyCalled = { key, context, completion in
            XCTAssertEqual(key, "ParentModel:1")
            XCTAssertEqual(context as? String, "context")
            let model = ParentModel(id: 1)
            completion(model, nil)
        }

        let expectation = expectationWithDescription("")
        dataProvider.fetchDataFromCache(cacheKey: "ParentModel:1", context: "context") { (model, error) -> () in
            XCTAssertEqual(model?.id, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)

        XCTAssertEqual(dataProvider.data?.id, 1)
    }

    func testFetchDataFail() {
        let cache = ExpectCacheDelegate()
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager(cacheDelegate: cache))

        let expectedError = NSError(domain: "", code: 0, userInfo: nil)

        cache.modelForKeyCalled = { key, context, completion in
            XCTAssertEqual(key, "ParentModel:1")
            XCTAssertEqual(context as? String, "context")
            completion(nil, expectedError)
        }

        let expectation = expectationWithDescription("")
        dataProvider.fetchDataFromCache(cacheKey: "ParentModel:1", context: "context") { (model, error) -> () in
            XCTAssertNil(model)
            XCTAssertTrue(error === expectedError)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)

        XCTAssertNil(dataProvider.data)
    }

    // MARK: Cache no-ops

    func testFetchDataTwice() {
        let cache = ExpectCacheDelegate()
        let dataModelManager = ExpectCacheDataModelManager(cacheDelegate: cache)
        let dataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)

        cache.modelForKeyCalled = { key, context, completion in
            XCTAssertEqual(key, "ParentModel:1")
            XCTAssertEqual(context as? String, "context")
            let model = ParentModel(id: 1)
            completion(model, nil)
        }

        var expectation = expectationWithDescription("waitForCache1")
        dataProvider.fetchDataFromCache(cacheKey: "ParentModel:1", context: "context") { (model, error) -> () in
            XCTAssertEqual(model?.id, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)

        XCTAssertEqual(dataProvider.data?.id, 1)
        XCTAssertEqual(dataModelManager.modelFromCacheCalled, 1)

        // Now, let's load from the cache again. This should effectively be a no-op
        expectation = expectationWithDescription("waitForCache2")
        dataProvider.fetchDataFromCache(cacheKey: "ParentModel:1", context: "context") { (model, error) -> () in
            // We still expect to get success back
            XCTAssertEqual(model?.id, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)

        XCTAssertEqual(dataProvider.data?.id, 1)
        // Even though we called fetch again, it shouldn't have actually hit the cache
        XCTAssertEqual(dataModelManager.modelFromCacheCalled, 1)
    }

    func testFetchDataFailThenSucceed() {
        let cache = ExpectCacheDelegate()
        let dataModelManager = ExpectCacheDataModelManager(cacheDelegate: cache)
        let dataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)

        cache.modelForKeyCalled = { key, context, completion in
            // First time, we're going to fail
            completion(nil, NSError(domain: "", code: 0, userInfo: nil))
        }

        var expectation = expectationWithDescription("waitForCache1")
        dataProvider.fetchDataFromCache(cacheKey: "ParentModel:1", context: "context") { (model, error) -> () in
            XCTAssertNil(model)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)

        XCTAssertNil(dataProvider.data)
        XCTAssertEqual(dataModelManager.modelFromCacheCalled, 1)

        // This time, we're going to suceed
        cache.modelForKeyCalled = { key, context, completion in
            XCTAssertEqual(key, "ParentModel:1")
            XCTAssertEqual(context as? String, "context")
            let model = ParentModel(id: 1)
            completion(model, nil)
        }

        // Now, let's load from the cache again. This should actually hit the cache again since we failed first time.
        expectation = expectationWithDescription("waitForCache2")
        dataProvider.fetchDataFromCache(cacheKey: "ParentModel:1", context: "context") { (model, error) -> () in
            XCTAssertEqual(model?.id, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)

        XCTAssertEqual(dataProvider.data?.id, 1)
        XCTAssertEqual(dataModelManager.modelFromCacheCalled, 2)
    }

    func testSetDataThenFetch() {
        let cache = ExpectCacheDelegate()
        let dataModelManager = ExpectCacheDataModelManager(cacheDelegate: cache)
        let dataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)

        cache.modelForKeyCalled = { key, context, completion in
            XCTAssertEqual(key, "ParentModel:1")
            XCTAssertEqual(context as? String, "context")
            let model = ParentModel(id: 1)
            completion(model, nil)
        }

        dataProvider.setData(ParentModel(id: 1))

        XCTAssertEqual(dataProvider.data?.id, 1)
        XCTAssertEqual(dataModelManager.modelFromCacheCalled, 0)

        // Now, let's load from the cache again. This should effectively be a no-op
        let expectation = expectationWithDescription("waitForCache")
        dataProvider.fetchDataFromCache(cacheKey: "ParentModel:1", context: "context") { (model, error) -> () in
            // We still expect to get success back
            XCTAssertEqual(model?.id, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)

        XCTAssertEqual(dataProvider.data?.id, 1)
        // We should never have hit the cache
        XCTAssertEqual(dataModelManager.modelFromCacheCalled, 0)
    }

    func testFetchWithNilCacheKey() {
        let cache = ExpectCacheDelegate()
        let dataModelManager = ExpectCacheDataModelManager(cacheDelegate: cache)
        let dataProvider = DataProvider<ParentModel>(dataModelManager: dataModelManager)

        cache.modelForKeyCalled = { key, context, completion in
            XCTAssertNil(key)
            XCTAssertEqual(context as? String, "context")
            let model = ParentModel(id: 1)
            completion(model, nil)
        }

        // Let's load from the cache with a nil cacheKey
        // We should still fetch using the context
        let expectation = expectationWithDescription("waitForCache")
        dataProvider.fetchDataFromCache(cacheKey: nil, context: "context") { (model, error) -> () in
            // We still expect to get success back
            XCTAssertEqual(model?.id, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)

        XCTAssertEqual(dataProvider.data?.id, 1)
        XCTAssertEqual(dataModelManager.modelFromCacheCalled, 1)
    }

    class ExpectCacheDataModelManager: DataModelManager {

        var cacheModelCalled = 0
        var modelFromCacheCalled = 0

        override func cacheModel<T : SimpleModel>(model: T, forKey cacheKey: String, context: Any?) {
            cacheModelCalled += 1
            super.cacheModel(model, forKey: cacheKey, context: context)
        }

        override func modelFromCache<T : SimpleModel>(cacheKey: String?, context: Any?, completion: (T?, NSError?) -> ()) {
            modelFromCacheCalled += 1
            super.modelFromCache(cacheKey, context: context, completion: completion)
        }
    }
}
