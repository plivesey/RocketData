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
 This class creates a reference counted dictionary instead of doing structs.
 It's used for a specific part of the consistency manager for performance reasons.
 Using this over regular structs caused a ~50x performance improvement.
 */
class DictionaryHolder<T: Hashable, U> {
    var dictionary = Dictionary<T, U>()
}

/**
 This class creates a reference counted array instead of doing structs.
 It's used for a specific part of the consistency manager for performance reasons.
 Using this over regular structs caused a ~50x performance improvement.
 */
class ArrayHolder<T> {
    var array = Array<T>()
}
