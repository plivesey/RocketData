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
    let online: Bool

    init(id: Int, name: String, online: Bool) {
        self.id = id
        self.name = name
        self.online = online
    }

    // MARK: - SampleAppModel

    required init?(data: [AnyHashable: Any]) {
        guard let id = data["id"] as? Int,
            let name = data["name"] as? String,
            let online = data["online"] as? Bool else {
                return nil
        }
        self.id = id
        self.name = name
        self.online = online
    }

    func data() -> [AnyHashable: Any] {
        return [
            "id": id,
            "name": name,
            "online": online
        ]
    }

    // MARK: - Rocket Data Model

    var modelIdentifier: String? {
        // We prepend UserModel to ensure this is globally unique
        return "UserModel:\(id)"
    }

    func map(_ transform: (Model) -> Model?) -> UserModel? {
        // No child objects, so we can just return self
        return self
    }

    func forEach(_ visit: (Model) -> Void) {
    }
}

func ==(lhs: UserModel, rhs: UserModel) -> Bool {
    return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.online == rhs.online
}
