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

class PauseDataProviderTests: RocketDataTestCase {

    /// The consistency manager implements several complex test cases for pause
    /// We're just going to include a sanity check here
    func testPause() {
        let dataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)

        var numberOfTimesCalled = 0
        let delegate = ClosureDataProviderDelegate() { context in
            XCTAssertEqual(context as? String, "context")
            numberOfTimesCalled += 1
        }
        dataProvider.delegate = delegate

        let initialModel = ParentModel(id: 0, name: "initial", requiredChild: ChildModel(id: 1, name: "child"), otherChildren: [])
        dataProvider.setData(initialModel)

        XCTAssertFalse(dataProvider.paused)
        dataProvider.paused = true
        XCTAssertTrue(dataProvider.paused)

        let otherDataProvider = DataProvider<ParentModel>(dataModelManager: DataModelManager.sharedDataManagerNoCache)
        otherDataProvider.setData(ParentModel(id: 0, name: "new", requiredChild: ChildModel(id: 1, name: "child"), otherChildren: []), context: "first")

        XCTAssertEqual(dataProvider.data, initialModel)
        XCTAssertEqual(numberOfTimesCalled, 0)

        DataModelManager.sharedDataManagerNoCache.updateModel(ChildModel(id: 1, name: "new"), context: "context")

        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)

        XCTAssertEqual(dataProvider.data, initialModel)
        XCTAssertEqual(numberOfTimesCalled, 0)

        dataProvider.paused = false
        XCTAssertFalse(dataProvider.paused)

        waitForConsistencyManagerToFlush(DataModelManager.sharedDataManagerNoCache.consistencyManager)

        XCTAssertEqual(numberOfTimesCalled, 1)
    }
    
}
