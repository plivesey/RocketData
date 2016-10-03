// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import Foundation

/**
 This class allows you to combine multiple different listeners into one listener.

 If you have multiple consistency manager listeners that share common child models then an update to one of these child models will cause all of the
 listeners to fire. You may want to be notified only once when all of these listeners fire instead of multiple times. This class allows you to do this.
 You initialize an instance of this class with an array of listeners.
 If one or more of these listeners are updated due to a consistency manager change, then first modelUpdated will be called on all of the listeners; then,
 this class will call modelUpdated once on its delegate with a batch model representing all the models.
 This will notify you once that a change has occured.

 ### SETUP

 You should NOT call addListener on any of the listeners that you pass into this class. Instead, you should call it directly on the instance of this class.
 This causes the instance of this class to listen to each of the models of the listeners.
 Any time you manually change a model on one of the listeners, you need to call listenerHasUpdatedModel.
 */
open class BatchListener: ConsistencyManagerListener {

    open let listeners: [ConsistencyManagerListener]

    /// The delegate that is called after one or more listeners in the `listeners` array are updated
    open weak var delegate: BatchListenerDelegate?

    /// Listening to all models occurs immediately upon initialization of the BatchListener object
    public init(listeners: [ConsistencyManagerListener], consistencyManager: ConsistencyManager) {
        self.listeners = listeners
        addListener(consistencyManager)
    }

    /**
     Instead of calling addListener on each of the child listeners, you should call this method.
     You should also call it whenever you manually change any of the sublisteners.
     */
    open func addListener(_ consistencyManager: ConsistencyManager) {
        consistencyManager.addListener(self)
    }

    /**
     Whenever you manually change a model on a listener, you must call this method to let the batch listener know.
     */
    open func listenerHasUpdatedModel(_ listener: ConsistencyManagerListener, consistencyManager: ConsistencyManager) {
        if let model = listener.currentModel() {
            consistencyManager.addListener(self, to: model)
        }
        // else the model nil, so we don't have to listen to anything new.
    }

    /**
     If you manually change a model on a listener and you do not want to relisten on the whole model (because only part of the model has changed), you can call this method to relisten on only part of a model.
     
     - parameter model: The model which has changed.
     - parameter consistencyManager: The consistency manager you are using to listen to these changes.
     */
    open func listenerHasUpdatedModel(_ model: ConsistencyManagerModel, consistencyManager: ConsistencyManager) {
        consistencyManager.addListener(self, to: model)
    }

    // MARK: Consistency Manager Implementation

    open func currentModel() -> ConsistencyManagerModel? {
        let models = listeners.map { listener in
            return listener.currentModel()
        }
        return BatchUpdateModel(models: models)
    }

    open func modelUpdated(_ model: ConsistencyManagerModel?, updates: ModelUpdates, context: Any?) {
        if let model = model as? BatchUpdateModel, model.models.count == listeners.count {

            var updatedListeners = [ConsistencyManagerListener]()

            for (index, listener) in listeners.enumerated() {
                if let currentModel = listener.currentModel() {
                    let currentModelIds = BatchListener.allIds(currentModel)
                    let currentModelUpdates = ModelUpdates(
                        changedModelIds: updates.changedModelIds.intersection(currentModelIds),
                        deletedModelIds: updates.deletedModelIds.intersection(currentModelIds)
                    )
                    if currentModelUpdates.changedModelIds.count > 0 || currentModelUpdates.deletedModelIds.count > 0 {
                        listener.modelUpdated(model.models[index], updates: currentModelUpdates, context: context)
                        updatedListeners.append(listener)
                    }
                }
                // else they have no model, so nothing can have changed
            }
            // Now that we've updated all of our listeners, let's update our delegate
            delegate?.batchListener(self, hasUpdatedListeners: updatedListeners, updates: updates, context: context)
        } else {
            assertionFailure("modelUpdated called with a model that isn't a BatchUpdateModel, or the array was the wrong size. This should never happen and indicates a bug in the library.")
        }
    }

    // MARK: Private Helpers

    fileprivate static func allIds(_ model: ConsistencyManagerModel) -> Set<String> {
        var ids = Set<String>()
        if let id = model.modelIdentifier {
            ids.insert(id)
        }
        model.forEach { child in
            ids.formUnion(allIds(child))
        }
        return ids
    }
}

public protocol BatchListenerDelegate: class {
    /**
     This method is called whenever one of the listeners has an updated model.
     First, it will call the delegate method of each listener which is affected, then it will call this method.
     When you resume listening on a BatchListener, this method will be called if there were updates that were missed.
     This method is called on the main thread.

     - parameter batchListener: The batch listener which received this update.
     - parameter listeners: The listeners whicih have been updated.
     - parameter updates: The combined ModelUpdates from all the listeners affected.
     - parameter context: The context which caused this change.
     */
    func batchListener(_ batchListener: BatchListener, hasUpdatedListeners listeners: [ConsistencyManagerListener], updates: ModelUpdates, context: Any?)
}
