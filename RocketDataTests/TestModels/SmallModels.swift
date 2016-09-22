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

/*
 These classes aren't actually used in tests.
 They are here to test that they compile. They are the smallest versions of Model and SimpleModel and neither are final.
 If they compile, the test passes.
 */

class SmallSimpleModel: SimpleModel {
    var modelIdentifier: String? {
        return nil
    }

    func isEqual(to model: SimpleModel) -> Bool {
        return true
    }
}

class SmallModel: Model {
    var modelIdentifier: String? {
        return nil
    }

    func isEqual(to model: Model) -> Bool {
        return true
    }

    func map(_ transform: (Model) -> Model?) -> Self? {
        return self
    }

    func forEach(_ visit: (Model) -> Void) {
    }
}

