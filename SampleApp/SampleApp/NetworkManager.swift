//
//  NetworkManager.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import Foundation
import RocketData

/**
 This is just a mock network manager. It has some delays in it to make it semi realistic.
 */
class NetworkManager {

    static func fetchChats(completion: ([UserModel], NSError?)->Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { 
            sleep(2)
            dispatch_async(dispatch_get_main_queue()) {
                let chats = [
                    UserModel(id: 1, name: "Nick"),
                    UserModel(id: 2, name: "Nitesh")
                ]
                completion(chats, nil)
            }
        }
    }
}
