// © 2016 LinkedIn Corp. All rights reserved.
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import XCTest
import RocketData
import ConsistencyManager

class ParsingHelpersTests: RocketDataTestCase {

    class Parent {
        required init() {
        }
    }

    class Child: Parent, SimpleModel {
        required init() {
        }

        var modelIdentifier: String? {
            return nil
        }

        func isEqualToModel(model: SimpleModel) -> Bool {
            return false
        }
    }

    class NonSimpleModel {
        required init() {
        }
    }

    // MARK: parseModel with no custom errors

    func testSimpleModelSuccess() {
        let (model, error): (Child?, NSError?) = ParsingHelpers.parseModel { (aClass: Parent.Type) in
            return aClass.init()
        }
        XCTAssertNotNil(model)
        XCTAssertNil(error)
    }

    func testSimpleModelFailure() {
        let (model, error): (Child?, NSError?) = ParsingHelpers.parseModel { (aClass: NonSimpleModel.Type) in
            return aClass.init()
        }
        XCTAssertNil(model)
        XCTAssertNotNil(error)
    }

    // MARK: parseModel with custom errors

    func testErrorModelSuccess() {
        let (model, error): (Child?, NSError?) = ParsingHelpers.parseModel { (aClass: Parent.Type) in
            return (aClass.init(), nil)
        }
        XCTAssertNotNil(model)
        XCTAssertNil(error)
    }

    func testErrorModelFailure() {
        let (model, error): (Child?, NSError?) = ParsingHelpers.parseModel { (aClass: NonSimpleModel.Type) in
            return (aClass.init(), nil)
        }
        XCTAssertNil(model)
        XCTAssertNotNil(error)
    }

    func testErrorModelCustomErrorFailure() {
        let expectedError = NSError(domain: "", code: 0, userInfo: nil)
        let (model, error): (Child?, NSError?) = ParsingHelpers.parseModel { (aClass: Parent.Type) in
            return (nil, expectedError)
        }
        XCTAssertNil(model)
        XCTAssertNotNil(error)
        XCTAssertTrue(error === expectedError)
    }

    // MARK: parseCollectionModel with no custom errors

    func testSimpleCollectionModelSuccess() {
        let (model, error): ([Child]?, NSError?) = ParsingHelpers.parseCollection { (aClass: Parent.Type) in
            return [aClass.init()]
        }
        XCTAssertNotNil(model)
        XCTAssertNil(error)
        XCTAssertEqual(model?.count, 1)
    }

    func testSimpleCollectionFailure() {
        let (model, error): ([Child]?, NSError?) = ParsingHelpers.parseCollection { (aClass: NonSimpleModel.Type) in
            return [aClass.init()]
        }
        XCTAssertNil(model)
        XCTAssertNotNil(error)
    }

    // MARK: parseModel with custom errors

    func testErrorCollectionSuccess() {
        let (model, error): ([Child]?, NSError?) = ParsingHelpers.parseCollection { (aClass: Parent.Type) in
            return ([aClass.init()], nil)
        }
        XCTAssertNotNil(model)
        XCTAssertNil(error)
        XCTAssertEqual(model?.count, 1)
    }

    func testErrorCollectionFailure() {
        let (model, error): ([Child]?, NSError?) = ParsingHelpers.parseCollection { (aClass: NonSimpleModel.Type) in
            return ([aClass.init()], nil)
        }
        XCTAssertNil(model)
        XCTAssertNotNil(error)
    }

    func testErrorCollectionCustomErrorFailure() {
        let expectedError = NSError(domain: "", code: 0, userInfo: nil)
        let (model, error): ([Child]?, NSError?) = ParsingHelpers.parseCollection { (aClass: Parent.Type) in
            return (nil, expectedError)
        }
        XCTAssertNil(model)
        XCTAssertNotNil(error)
        XCTAssertTrue(error === expectedError)
    }
}
