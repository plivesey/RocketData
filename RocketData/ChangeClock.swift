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
 This class keeps a global clock which is used to record when changes happen.
 Whenever you create a new ChangeTime, it will be after any previous times and before any future times.
 It is not thread-safe. You must call it on the main thread.
 */
struct ChangeTime: Equatable {
    /// Keeps track of the last time we updated
    private static var lastTime = 1

    fileprivate let time: Int

    /**
     Creates a new ChangeTime instance. This is guarenteed to be after any previous times created.
     */
    init() {
        Log.sharedInstance.assert(Thread.isMainThread, "The ChangeClock was accessed on a different thread than the main thread. This probably means you are accessing something in the library that is not thread-safe on a different thread. This can cause race conditions.")
        self.time = ChangeTime.lastTime
        ChangeTime.lastTime += 1
    }

    /**
     Private initializer for creating a time with zero.
     */
    private init(time: Int) {
        self.time = time
    }

    /**
     Returns a time which all other times will be after.
     */
    static func timeZero() -> ChangeTime {
        return ChangeTime(time: 0)
    }

    /**
     Returns true if this time was created after another time.
     */
    func after(_ other: ChangeTime) -> Bool {
        return time > other.time
    }
}

func ==(lhs: ChangeTime, rhs: ChangeTime) -> Bool {
    return lhs.time == rhs.time
}
