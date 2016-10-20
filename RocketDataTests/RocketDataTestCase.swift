// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import XCTest
@testable import RocketData
@testable import ConsistencyManager

/**
 This class contains helpers for RocketData tests. All tests should subclass this test.
 */
class RocketDataTestCase: XCTestCase {

    /**
     This function waits for a consistency manager to complete all current operations.
     */
    func waitForConsistencyManagerToFlush(_ consistencyManager: ConsistencyManager) {
        var expectation = self.expectation(description: "Wait for consistency manager to complete pending tasks")
        let operation = BlockOperation() {
            expectation.fulfill()
        }
        consistencyManager.queue.addOperation(operation)
        waitForExpectations(timeout: 10, handler: nil)

        expectation = self.expectation(description: "Wait for main thread to complete pending tasks")
        DispatchQueue.main.async(flags: .barrier, execute: {
            expectation.fulfill()
        }) 
        waitForExpectations(timeout: 10, handler: nil)
    }

    /**
     This function waits for the cache to complete all operations.
     */
    func waitForCacheToFinish(_ dataModelManager: DataModelManager) {
        var expectation = self.expectation(description: "Wait for consistency manager to complete pending tasks")
        (dataModelManager.externalDispatchQueue).async(flags: .barrier) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)

        expectation = self.expectation(description: "Wait for main thread to complete pending tasks")
        DispatchQueue.main.async(flags: .barrier) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
}
