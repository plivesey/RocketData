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
 This is an enum for all the errors we have in the app.
 We do not want to make it public because that means adding an error is a backwards incompatible change.
 We'll just use this to keep track of all errors.
 */
enum CriticalError: String {
    case DeleteIDFailure = "Attemped to delete an object which does not have an id. This is a no-op so is probably not behaving like you expect."
    case WrongMapClass = "You must return a class of the same type from map. You should not attempt to change classes. In the future, we will probably make this protocol return Self so this is enforced. See the docs for map(...) in ConsistencyManagerModel for more info."
}
