// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import XCTest
import RocketData

/**
 This class provides some useful helpers for writing SharedCollectionTests.

 It provides the ability to setup shared collections with the cacheKey "cacheKey".
 It also initializes there with data from the cache (one item with id: 0).
 */
class SharedCollectionTests: RocketDataTestCase {
    
    var cacheUpdates = 0
    var cacheRequests = 0
    let cacheDelegate = ExpectCacheDelegate()
    lazy var dataModelManager: DataModelManager = DataModelManager(cacheDelegate: self.cacheDelegate)

    var verifySetCollectionContext = true

    override func setUp() {
        super.setUp()

        cacheDelegate.collectionForKeyCalled = { cacheKey, context, completion in
            XCTAssertEqual(context as? String, "cacheContext")
            XCTAssertEqual(cacheKey, "cacheKey")
            self.cacheRequests += 1
            let initialModels: [Any] = [ParentModel(id: 0)]
            completion(initialModels, nil)
        }

        cacheDelegate.setCollectionCalled = { _, cacheKey, context in
            self.cacheUpdates += 1
            if self.verifySetCollectionContext {
                XCTAssertEqual(context as? String, "context")
            }
            XCTAssertEqual(cacheKey, "cacheKey")
        }
    }

    /**
     Helper function for creating shared collections.
     */
    func sharedCollectionDataProvider(delegate: ClosureCollectionDataProviderDelegate?) -> CollectionDataProvider<ParentModel> {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)
        dataProvider.delegate = delegate
        let expectation = expectationWithDescription("waitForCache")
        // Fetching from the cache will set the cacheKey
        dataProvider.fetchDataFromCache(cacheKey: "cacheKey", context: "cacheContext") { _, _ in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
        return dataProvider
    }
}
