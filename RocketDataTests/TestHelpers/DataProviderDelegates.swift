// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import Foundation
import RocketData
import ConsistencyManager

class ClosureDataProviderDelegate: DataProviderDelegate {

    let modelUpdated: (Any?)->()

    init(modelUpdated: (Any?)->()) {
        self.modelUpdated = modelUpdated
    }

    func dataProviderHasUpdatedData<T>(dataProvider: DataProvider<T>, context: Any?) {
        modelUpdated(context)
    }
}

class ClosureCollectionDataProviderDelegate: CollectionDataProviderDelegate {

    let collectionUpdated: (CollectionChange, Any?)->()

    init(collectionUpdated: (CollectionChange, Any?)->()) {
        self.collectionUpdated = collectionUpdated
    }

    func collectionDataProviderHasUpdatedData<T>(dataProvider: CollectionDataProvider<T>, collectionChanges: CollectionChange, context: Any?) {
        collectionUpdated(collectionChanges, context)
    }
}

class ClosureBatchListenerDelegate: BatchDataProviderListenerDelegate {

    let listenersUpdated: ([ConsistencyManagerListener], Any?)->()

    init(listenersUpdated: ([ConsistencyManagerListener], Any?)->()) {
        self.listenersUpdated = listenersUpdated
    }

    func batchDataProviderListener(batchListener: BatchDataProviderListener, hasUpdatedDataProviders dataProviders: [ConsistencyManagerListener], context: Any?) {
        listenersUpdated(dataProviders, context)
    }
}
