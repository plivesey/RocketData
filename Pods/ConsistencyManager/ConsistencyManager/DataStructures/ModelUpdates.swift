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
 When you do an update through the consistency manager, it may cause multiple objects to be updated or deleted. 
 This struct informs you of the ids of objects which have changed.
*/
public struct ModelUpdates {
    /**
     The ids of all the models which have changed.
     
     This includes all non-deleted models which return false from isEqual(other).
     Therefore, if the root model is not deleted, it will always be included in this set.
     If a submodel is changed (or deleted), all parent models will be included in this set.
    */
    public var changedModelIds: Set<String>

    /**
     The ids of all models that have been deleted.
     
     If you return nil from map (indicating a cascading delete), multiple models may be deleted. All these ids will be included in this set.
    */
    public var deletedModelIds: Set<String>
}
