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
 This class is used for all consistency manager updates.
 This wraps the passed in context inside another context which keeps track of the creation date.
 With this, we can track when consistency manager changes began and throw out any changes which are out-dated.
 */
class ConsistencyContextWrapper {

    let context: Any?
    let creationDate: ChangeTime = ChangeTime()

    init(context: Any?) {
        self.context = context
    }

    /**
     This function converts from the context given by the consistency manager to the context the user of this library expects to be returned.
     */
    class func actualContextFromConsistencyManagerContext(_ context: Any?) -> Any? {
        if let context = context as? ConsistencyContextWrapper {
            return context.context
        } else {
            return context
        }
    }
}
