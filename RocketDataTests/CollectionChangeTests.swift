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
import ConsistencyManager

class CollectionChangeTests: RocketDataTestCase {

    func testEquality() {
        XCTAssertEqual(CollectionChange.reset, CollectionChange.reset)
        XCTAssertEqual(CollectionChangeInformation.update(index: 3), CollectionChangeInformation.update(index: 3))
        XCTAssertEqual(CollectionChangeInformation.delete(index: 3), CollectionChangeInformation.delete(index: 3))
        XCTAssertNotEqual(CollectionChangeInformation.update(index: 3), CollectionChangeInformation.delete(index: 3))
        XCTAssertNotEqual(CollectionChangeInformation.update(index: 3), CollectionChangeInformation.update(index: 4))
        XCTAssertNotEqual(CollectionChangeInformation.delete(index: 3), CollectionChangeInformation.delete(index: 4))
    }

    /**
     This test verifies what happens if we get some bad data from the consistency manager.
     This should never happen, but if it does happen we shouldn't crash.
     
     This provides an update where the number of elements - number deleted doesn't match up.
     In this case, we can't work out which rows were added/deleted so just say the whole collection was reset.
     */
    func testCollectionDataProviderIncorrectData() {
        let dataProvider = CollectionDataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        let newModel = ParentModel(id: 1, name: "new", requiredChild: ChildModel(), otherChildren: [])
        let model = ParentModel(id: 1)

        dataProvider.setData([model], cacheKey: nil)

        let delegate = ClosureCollectionDataProviderDelegate() { (collectionChanges, context) in
            // Because we gave it a bad updates object, we should default to reset
            // This is better than possibly crashing
            XCTAssertEqual(collectionChanges, CollectionChange.reset)
        }
        dataProvider.delegate = delegate

        let badModelUpdates = ModelUpdates(changedModelIds: [], deletedModelIds: [model.modelIdentifier!])
        dataProvider.modelUpdated(BatchUpdateModel(models: [newModel]), updates: badModelUpdates, context: nil)
    }

    func testCollectionChangeArrayNoDeletes() {
        let changes = [CollectionChangeInformation.update(index: 2), CollectionChangeInformation.update(index: 5)]
        XCTAssertEqual(changes.numberOfDeletedElements(), 0)
        XCTAssertEqual(changes.deltaNumberOfElements(), 0)
    }

    func testCollectionChangeArrayWithDeletes() {
        let changes = [CollectionChangeInformation.delete(index: 0), CollectionChangeInformation.update(index: 2), CollectionChangeInformation.delete(index: 5)]
        XCTAssertEqual(changes.numberOfDeletedElements(), 2)
        XCTAssertEqual(changes.deltaNumberOfElements(), -2)
    }
}
