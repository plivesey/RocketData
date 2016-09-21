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
 This is the class used for logs in the library.
 All methods have some default implementations, but if you want, you can implement a delegate to implement your own logs.
*/
open class Log {

    /// Singleton accessor
    open static let sharedInstance = Log()

    /// Delegate for the class. If nil, then it will do default logging. Otherwise, it will leave it up to the delegate.
    open weak var delegate: LogDelegate?

    /**
     This is called whenever a critical error occurs in the library. 
     These critical errors can be recovered from, but will likely cause unexpected behavior in your app.
     The default behavior is to call assertionFailure which will crash the app in DEBUG and do nothing in RELEASE configurations.
    */
    open func assert(_ condition: @autoclosure () -> Bool, _ logText: @autoclosure () -> String, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        if !condition() {
            if let delegate = delegate {
                delegate.assertionFailure(logText(), file: file, function: function, line: line)
            } else {
                // Default behavior is to just call a regular assertionFailure
                assertionFailure(logText, file: file, line: line)
            }
        }
    }
}

/**
 The delegate for the Log class.
*/
public protocol LogDelegate: class {
    /// Called whenever assert is called in the library. See the docs for assert in Log.
    func assertionFailure(_ message: String, file: StaticString, function: StaticString, line: UInt)
}
