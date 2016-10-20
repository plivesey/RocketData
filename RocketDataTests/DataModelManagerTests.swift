//
//  DataModelManagerTests.swift
//  RocketData
//
//  Created by Peter Livesey on 10/20/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import XCTest
import RocketData

class DataModelManagerTests: RocketDataTestCase {
    
    func testUpdateModelWithCache() {
        let cacheExpectation = expectation(description: "Wait for cache")
        let cache = ExpectCacheDelegate()
        let dataModelManager = DataModelManager(cacheDelegate: cache)
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])

        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
        }
        dataProvider.delegate = delegate

        cache.setModelCalled = { model, key, context in
            XCTAssertEqual(model as? ParentModel, newModel)
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(key, "ParentModel:1")
            cacheExpectation.fulfill()
        }

        dataProvider.setData([initialModel], cacheKey: nil, context: "wrong")
        dataModelManager.updateModel(newModel, context: "context")

        waitForExpectations(timeout: 10, handler: nil)
        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        XCTAssertEqual(dataProvider[0], newModel)
    }

    func testUpdateModelWithoutCache() {
        let cache = ExpectCacheDelegate()
        let dataModelManager = DataModelManager(cacheDelegate: cache)
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])

        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
        }
        dataProvider.delegate = delegate

        cache.setModelCalled = { model, key, context in
            XCTFail()
        }

        dataProvider.setData([initialModel], cacheKey: nil, context: "wrong")
        dataModelManager.updateModel(newModel, updateCache: false, context: "context")

        waitForCacheToFinish(dataModelManager)
        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        XCTAssertEqual(dataProvider[0], newModel)
    }

    func testUpdateModelsWithCache() {
        let cacheExpectation = expectation(description: "Wait for cache")
        let cache = ExpectCacheDelegate()
        let dataModelManager = DataModelManager(cacheDelegate: cache)
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let otherInitialModel = ParentModel(id: 2, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherNewModel = ParentModel(id: 2, name: "new", requiredChild: ChildModel(), otherChildren: [])

        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
        }
        dataProvider.delegate = delegate

        var setModelCalled = 0
        cache.setModelCalled = { model, key, context in
            setModelCalled += 1
            XCTAssertEqual(model as? ParentModel, setModelCalled == 1 ? newModel : otherNewModel)
            XCTAssertEqual(context as? String, "context")
            XCTAssertEqual(key, "ParentModel:\(setModelCalled)")
            if setModelCalled == 2 {
                cacheExpectation.fulfill()
            }
        }

        dataProvider.setData([initialModel, otherInitialModel], cacheKey: nil, context: "wrong")
        dataModelManager.updateModels([newModel, otherNewModel], context: "context")

        waitForExpectations(timeout: 10, handler: nil)
        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        XCTAssertEqual(dataProvider[0], newModel)
        XCTAssertEqual(dataProvider[1], otherNewModel)
    }

    func testUpdateModelsWithoutCache() {
        let cache = ExpectCacheDelegate()
        let dataModelManager = DataModelManager(cacheDelegate: cache)
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: dataModelManager)

        let initialModel = ParentModel(id: 1, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let otherInitialModel = ParentModel(id: 2, name: "initial", requiredChild: ChildModel(), otherChildren: [])
        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let otherNewModel = ParentModel(id: 2, name: "new", requiredChild: ChildModel(), otherChildren: [])

        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            XCTAssertEqual(context as? String, "context")
        }
        dataProvider.delegate = delegate

        cache.setModelCalled = { model, key, context in
            XCTFail()
        }

        dataProvider.setData([initialModel, otherInitialModel], cacheKey: nil, context: "wrong")
        dataModelManager.updateModels([newModel, otherNewModel], updateCache: false, context: "context")

        waitForCacheToFinish(dataModelManager)
        waitForConsistencyManagerToFlush(dataModelManager.consistencyManager)

        XCTAssertEqual(dataProvider[0], newModel)
        XCTAssertEqual(dataProvider[1], otherNewModel)
    }
}
