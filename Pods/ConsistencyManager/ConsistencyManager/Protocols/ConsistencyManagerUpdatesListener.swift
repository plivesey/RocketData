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
 This protocol allows a class to listen to ALL changes to the consistency manager.
 */
public protocol ConsistencyManagerUpdatesListener: class {
    /**
     Called whenever there is any change to the consistency manager.
     This method is run on the main thread. If you have any extensive processing, it's highly recommended to do this on a background thread
     since this will be called for every single consistency update.

     This method passes back a list of all the updates made as a result of this change.
     It is a dictionary of `[modelIdentifier: change]`. All of the model's children will be in this dictionary if it was an update.

     - parameter consistencyManager: The consistency manager which has received the change.
     - parameter model: The model which has been updated (NOTE: This model may have been deleted).
     To check if it has been deleted, check `changes[model.modelIdentifier] == .deleted`.
     - parameter changes: This is a flattened representation of all the children of the model that was updated.
     It is a dictionary from ID to model. If it is nil, it has been deleted.
     The value is an array because multiple models with the same ID may have been updated. This only applies if you're using projections.
     - parameter context: The context passed in with this update
     */
    func consistencyManager(_ consistencyManager: ConsistencyManager,
                            updatedModel model: ConsistencyManagerModel,
                            changes: [String: ModelChange],
                            context: Any?)
}
