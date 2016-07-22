//
//  UserModel.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import Foundation
import RocketData

final class UserModel: SampleAppModel, Equatable {
    let id: Int
    let name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

    // MARK: - SampleAppModel

    required init?(data: [NSObject : AnyObject]) {
        guard let id = data["id"] as? Int,
            let name = data["name"] as? String else {
                return nil
        }
        self.id = id
        self.name = name
    }

    func data() -> [NSObject : AnyObject] {
        return [
            "id": id,
            "name": name
        ]
    }

    // MARK: - Rocket Data Model

    var modelIdentifier: String? {
        // We prepend UserModel to ensure this is globally unique
        return "UserModel:\(id)"
    }

    func map(transform: Model -> Model?) -> UserModel? {
        // No child objects, so we can just return self
        return self
    }

    func forEach(visit: Model -> Void) {
    }
}

func ==(lhs: UserModel, rhs: UserModel) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name
}
