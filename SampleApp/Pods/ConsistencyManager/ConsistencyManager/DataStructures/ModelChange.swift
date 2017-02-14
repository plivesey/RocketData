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
 This class is used to show which child models have changed. This object is usually in a dictionary: `[String: ModelChange]`.
 The strings represent IDs and it shows what's changed in this ID. Either the ID has been deleted or updated.
 If it's been updated, there are potentially several models that have updated if you are using projections.
 */
public enum ModelChange: Equatable {
    /**
     This indicates a model has been updated and lists the new models.
     If you are using projections, there may be multiple models that represent this change.
     Otherwise, there will just be one model here.
     */
    case updated([ConsistencyManagerModel])
    /**
     This indicates a model has been deleted.
     */
    case deleted

    public static func ==(lhs: ModelChange, rhs: ModelChange) -> Bool {
        switch (lhs, rhs) {
        case (.updated(let l), .updated(let r)):
            guard l.count == r.count else {
                return false
            }
            return zip(l, r).reduce(true) { isEqual, tuple in
                return isEqual && tuple.0.isEqualToModel(tuple.1)
            }
        case (.deleted, .deleted):
            return true
        default:
            return false
        }
    }
}
