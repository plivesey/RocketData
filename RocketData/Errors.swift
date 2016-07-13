// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import Foundation

/// This is the domain used for all NSError objects created by Rocket Data
public let rocketDataErrorDomain = "com.rocketData"

/**
 This enum lists all the error codes which Rocket Data will produce.
 The class is not public because otherwise adding a new error would be a backwards incompatible change.
*/
enum Error: Int {
    /// This is called whenever you attempt to parse a model using DataModelManager.parse and the types don't match.
    /// Usually this means you are using a DataProvider of type T and expect in your cache a type U where T is not a subclass of U.
    case wrongModelClassParsed = 1

    /**
     Returns an NSError representation of the current error type.
    */
    func error() -> NSError {
        let developerMessage: String
        switch self {
        case .wrongModelClassParsed:
            developerMessage = "The model passed to parseModel was of the wrong type. This probably means you are using a DataProvider with a type T that you don't support."
        }
        return NSError(domain: rocketDataErrorDomain, code: rawValue, userInfo: ["developerMessage": developerMessage])
    }
}
