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

/**
 These helpers make testing collection changes easier.
 We can more easily verify certain properties in XCTAssertEqual
 */
extension CollectionChange {

    subscript(index: Int) -> CollectionChangeInformation? {
        switch self {
        case .reset:
            return nil
        case .changes(let changes):
            return changes[index]
        }
    }

    var count: Int {
        switch self {
        case .reset:
            return 1
        case .changes(let changes):
            return changes.count
        }
    }
}
