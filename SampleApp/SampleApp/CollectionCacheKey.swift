//
//  CollectionCacheKey.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import Foundation

enum CollectionCacheKey {
    case chat
    case messages(Int)

    func cacheKey() -> String {
        switch self {
        case .chat:
            return "chat"
        case .messages(let userId):
            return "messages:\(userId)"
        }
    }
}
