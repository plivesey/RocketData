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
 This protocol should be defined on any class you want to add as a listener to the conistency manager.
 All methods are called on the main thread, and you should ensure that these methods run fast.

 You SHOULD NOT call ANY conistency manager methods from either of these functions. This could cause an infinite loop.
 */

public protocol ConsistencyManagerListener: class {

    /**
     This should return the current model which this class cares about.
     The consistency manager is a decentralized model manager.
     It doesn't actually contain references to the model and will call this method whenever it needs one.
     
     It is run synchronously on the main thread, so it should be a fast call.
     */
    func currentModel() -> ConsistencyManagerModel?

    /**
     This function is called whenever the model has been updated by the conistency manager.

     There are a few important points:

     * This model will always be the same class as returned by current model. Sadly, the swift typing system isn't strong enough to make this a generic protocol.
     * Do NOT call any consistency manager methods from this method. You do NOT need to call listen on the new model as this is handled automatically.
     * The model will be nil if it has been deleted from the consistency manager.

     - parameter model: The new model which has been updated. If nil, it indicates the model has been deleted.
     - parameter updates: An update model which contains all the changes beteween the current model and the new model.
     - parameter context: This passes back the context which was passed to the consistency manager when the update occurred.
     */
    func modelUpdated(_ model: ConsistencyManagerModel?, updates: ModelUpdates, context: Any?)
}
