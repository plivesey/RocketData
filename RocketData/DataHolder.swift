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
 This class encapsulates some data of a generic type and the time it was last updated.
 This helps ensure that whenever the data is updated, the time is also updated.

 For a CollectionDataProvider, T would be [T]. For a DataProvider, T would be T?.
 */
struct DataHolder<T> {
    /// The data backed by this data holder
    private(set) var data: T
    /// The time the data was updated
    private(set) var lastUpdated: ChangeTime

    /**
     Initialize with initial data as well as a specific change time.
     The default ChangeTime is time zero since most of the time, you are initializing an 'empty' DataHolder and want all updates.
     */
    init(data: T, changeTime: ChangeTime = ChangeTime.timeZero()) {
        self.data = data
        lastUpdated = changeTime
    }

    /**
     This modifies the data in the data holder.
     - parameter data: The new data.
     - parameter changeTime: The new change time to set on lastUpdated.
     */
    mutating func setData(_ data: T, changeTime: ChangeTime) {
        if lastUpdated.after(changeTime) {
            return
        }
        self.data = data
        lastUpdated = changeTime
    }
}
