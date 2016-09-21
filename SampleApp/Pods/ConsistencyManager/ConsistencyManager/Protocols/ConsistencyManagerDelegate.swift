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
 The delegate protocol for the conistency manager.

 It provides error handling and debugging helpers.
 */
public protocol ConsistencyManagerDelegate: class {
    /**
     Sometimes, the consistency manager may encounter a critical error.
     This is usually because a method implemented by your models or listeners is not implemented correctly.
     If you encounter one of these errors, the conistency manager will gracefully degrade by ignoring the change or request,
     and there is likely nothing you can do about it in your code (catching the error on a case by case basis won't help because you won't know how to handle the error).
     This method is provided as a convenience so you can log these errors and fix them.
     If you have set up the library correctly, you should never have this method called.

     This method is optional. If you don't implement it, it will do nothing.

     - parameter consistencyManager: The consistency manager with the error.
     - parameter error: An english string describing the error.
     This is useful for logging, but should NOT be shown to the user as it will not be very useful.
     */
    func consistencyManager(_ consistencyManager: ConsistencyManager, failedWithCriticalError error: String)

    /**
     This is called whenever the consistency manager finds a model which has changed and will replace it.
     These models could be child models so it's actually where the diff is taking place.
     This is mostly just useful for debugging. It will be called whenever something changes in the consistency manager.

     This method is optional. If you don't implement it, it will do nothing.

     - parameter consistency Manager: The consistency manager with the error.
     - parameter oldModel: The previous model which was found.
     - parameter newModel: The new model which will replace the old model.
     - parameter context: The context passed in to the consistency manager which caused this change.
     */
    func consistencyManager(_ consistencyManager: ConsistencyManager, willReplaceModel oldModel: ConsistencyManagerModel, withModel newModel: ConsistencyManagerModel, context: Any?)
}

// MARK: Optional Methods Extension

public extension ConsistencyManagerDelegate {
    func consistencyManager(_ consistencyManager: ConsistencyManager, failedWithCriticalError error: String) {
        // No implementation. This makes this method optional.
    }

    func consistencyManager(_ consistencyManager: ConsistencyManager, willReplaceModel oldModel: ConsistencyManagerModel, withModel newModel: ConsistencyManagerModel, context: Any?) {
        // No implementation. This makes this method optional.
    }
}
