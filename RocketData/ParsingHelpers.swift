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
 This class defines a bunch of helpers for parsing models. They are paticularly useful when implementing the CacheDelegate.
 */
open class ParsingHelpers {
    /**
     This function is useful when trying to parse a generic type T into a specific class.
     For instance, let's say you have to return a type T, but you know that it must be a subtype of MyModelClass.
     MyModelClass has an initializer, but T doesn't. You can use this function to parse it assuming its a MyModelClass.
     
     let result: (T?, NSError?) = parseModel { (modelClass: MyModelClass.Type) in
         return modelClass.init(customParameters: params)
     }
     
     This will return a model of specific type T assuming it is a MyModelClass.
     
     This is paticularly useful when implementing the CacheDelegate. 
     The CacheDelegate requests a model of type T, but you actually want to provide a model of type T: MyModelClass.
     You can use this function to make that assumption (U is a specific supertype such as MyModelClass).
     
     Sadly, this does not work if U is a protocol due to a Swift bug. In this case, you'll need to optionally cast manually.
     */
    open static func parseModel<T, U>(_ parseBlock: (U.Type) -> U?) -> (T?, NSError?) {
        if let Model = T.self as? U.Type {
            let model = parseBlock(Model) as? T
            return (model, nil)
        } else {
            return (nil, Error.wrongModelClassParsed.error())
        }
    }

    /**
     This function is useful when trying to parse a generic type T into a specific class.
     For instance, let's say you have to return a type T, but you know that it must be a subtype of MyModelClass.
     MyModelClass has an initializer, but T doesn't. You can use this function to parse it assuming its a MyModelClass.
     
     It also allows you to return a parsing error if you have one.

     let result: (T?, NSError?) = parseModel { (modelClass: MyModelClass.Type) in
         let errorPointer = NSErrorPointer()
         let model = modelClass.init(customParameters: params, error: errorPointer)
         return (model, errorPointer.memory)
     }

     This will return a model of specific type T assuming it is a MyModelClass.
     
     This is paticularly useful when implementing the CacheDelegate.
     The CacheDelegate requests a model of type T, but you actually want to provide a model of type T: MyModelClass.
     You can use this function to make that assumption (U is a specific supertype such as MyModelClass).

     Sadly, this does not work if U is a protocol due to a Swift bug. In this case, you'll need to optionally cast manually.
     */
    open static func parseModel<T, U>(_ parseBlock: (U.Type) -> (U?, NSError?)) -> (T?, NSError?) {
        if let Model = T.self as? U.Type {
            let model = parseBlock(Model)
            return (model.0 as? T, model.1)
        } else {
            return (nil, Error.wrongModelClassParsed.error())
        }
    }

    /**
     This function is useful when trying to parse a generic type T into a specific class.
     For instance, let's say you have to return a type T, but you know that it must be a subtype of MyModelClass.
     MyModelClass has an initializer, but T doesn't. You can use this function to parse it assuming its a MyModelClass.

     let result: ([T]?, NSError?) = parseModel { (modelClass: MyModelClass.Type) in
         var error: NSError?
         let model = retrievedData.flatMap { modelClass.init(data: $0) }
         return (model, error)
     }

     This will return a model of specific type T assuming it is a MyModelClass.
     
     This is paticularly useful when implementing the CacheDelegate.
     The CacheDelegate requests a model of type T, but you actually want to provide a model of type T: MyModelClass.
     You can use this function to make that assumption (U is a specific supertype such as MyModelClass).

     Sadly, this does not work if U is a protocol due to a Swift bug. In this case, you'll need to optionally cast manually.
     */
    open static func parseCollection<T, U>(_ parseBlock: (U.Type) -> [U]?) -> ([T]?, NSError?) {
        if let Model = T.self as? U.Type {
            let model = parseBlock(Model)
            // Though this is a flat map, this should never fail since T is a subtype of U
            let elements = model?.flatMap { $0 as? T }
            return (elements, nil)
        } else {
            return (nil, Error.wrongModelClassParsed.error())
        }
    }

    /**
     This function is useful when trying to parse a generic type T into a specific class.
     For instance, let's say you have to return a type T, but you know that it must be a subtype of MyModelClass.
     MyModelClass has an initializer, but T doesn't. You can use this function to parse it assuming its a MyModelClass.

     It also allows you to return a parsing error if you have one.

     let result: ([T]?, NSError?) = parseModel { (modelClass: MyModelClass.Type) in
         var error: NSError?
         let model = retrievedData.flatMap { modelClass.init(data: $0) }
         return (model, error)
     }

     This will return a model of specific type T assuming it is a MyModelClass.
     
     This is paticularly useful when implementing the CacheDelegate.
     The CacheDelegate requests a model of type T, but you actually want to provide a model of type T: MyModelClass.
     You can use this function to make that assumption (U is a specific supertype such as MyModelClass).

     Sadly, this does not work if U is a protocol due to a Swift bug. In this case, you'll need to optionally cast manually.
     */
    open static func parseCollection<T, U>(_ parseBlock: (U.Type) -> ([U]?, NSError?)) -> ([T]?, NSError?) {
        if let Model = T.self as? U.Type {
            let model = parseBlock(Model)
            // Though this is a flat map, this should never fail since T is a subtype of U
            let elements = model.0?.flatMap { $0 as? T }
            return (elements, model.1)
        } else {
            return (nil, Error.wrongModelClassParsed.error())
        }
    }
}
