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
 This defines a WeakHolder which specifically holds a ConsistencyManagerListener.
 This is useful because WeakBox<ConsistencyManagerListener> is illegal in Swift. You need a concrete type like this one.
 */
public struct WeakListenerBox: WeakHolder {

    // Sadly, we need to declare this because by default, it's internal
    public init(element: ConsistencyManagerListener?) {
        self.element = element
    }

    public weak var element: ConsistencyManagerListener?
}

/**
 This defines a WeakHolder which specifically holds a ConsistencyManagerUpdatesListener.
 This is useful because WeakBox<ConsistencyManagerUpdatesListener> is illegal in Swift. You need a concrete type like this one.
 */
public struct WeakUpdatesListenerBox: WeakHolder {

    // Sadly, we need to declare this because by default, it's internal
    public init(element: ConsistencyManagerUpdatesListener?) {
        self.element = element
    }

    public weak var element: ConsistencyManagerUpdatesListener?
}
