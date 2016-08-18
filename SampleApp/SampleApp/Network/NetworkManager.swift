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

    static func loggedInUser() -> UserModel {
        return UserModel(id: 0, name: "Peter", online: true)
    }

    static func fetchChats(completion: ([UserModel], NSError?)->Void) {
        let delay = 1.5
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let chats = [
                UserModel(id: 1, name: "Nick", online: true),
                UserModel(id: 2, name: "Nitesh", online: false)
            ]
            completion(chats, nil)
        }
    }

    static func fetchMessage(user: UserModel, completion: ([MessageModel], NSError?)->Void) {
        let delay = 1.5
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            // To simulate the network, let's fetch from the cache and then add one additional message from the other user
            // This allows the data to grow as it would likely in real life
            // All this is just mocking though
            DataModelManager.sharedInstance.collectionFromCache(CollectionCacheKey.messages(user.id).cacheKey(), context: nil) { (messages: [MessageModel]?, nil) in
                dispatch_async(dispatch_get_main_queue()) {
                    var messages = messages ?? []
                    // Some of the messages may have the wrong online status. Since we're simulating a 'server response', let's reset all the users to the correct online status
                    messages = messages.map { message in
                        if message.sender.id == user.id {
                            return MessageModel(id: message.id, text: message.text, sender: user)
                        } else {
                            return message
                        }
                    }
                    let newMessage = MessageModel(id: nextMessageId(), text: "hey", sender: user)
                    messages.append(newMessage)
                    completion(messages, nil)
                }
            }
        }
    }

    static func startRandomPushNotifications() {
        startRandomUserOnlineNotifications()
        startRandomNewMessagesNotifications()
    }

    private static func startRandomUserOnlineNotifications() {
        let delay = Double(arc4random_uniform(4) + 2)
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let userId = Int(arc4random_uniform(2) + 1)
            let online = arc4random_uniform(2) == 0
            let username = userId == 1 ? "Nick" : "Nitesh"
            let newUserModel = UserModel(id: userId, name: username, online: online)
            (UIApplication.sharedApplication().delegate as? AppDelegate)?.pushNotificationReceivedWithUpdatedUser(newUserModel)

            print("Push notification: User \(online ? "came online": "went offline") (\(username)).")

            // Do it again!
            startRandomUserOnlineNotifications()
        }
    }

    private static func startRandomNewMessagesNotifications() {
        let delay = Double(arc4random_uniform(10) + 2)
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let userId = Int(arc4random_uniform(2) + 1)
            let username = userId == 1 ? "Nick" : "Nitesh"
            // Let's always say they are online because they just sent a message
            let newUserModel = UserModel(id: userId, name: username, online: true)
            let newMessageModel = MessageModel(id: nextMessageId(), text: "hey", sender: newUserModel)
            (UIApplication.sharedApplication().delegate as? AppDelegate)?.pushNotificationReceivedWithNewMessage(newMessageModel)

            print("Push notification: New message from (\(username)).")

            // Do it again!
            startRandomNewMessagesNotifications()
        }
    }

    /**
     A helper function which has a globally unique incrementing id.
     Normally, we'd get ids from the server, but since we don't have a server, we're going to use this to mock it out.
     */
    static func nextMessageId() -> Int {
        let key = "com.sampleapp.nextMessageId"
        let nextMessageId = NSUserDefaults.standardUserDefaults().integerForKey(key) + 1
        NSUserDefaults.standardUserDefaults().setInteger(nextMessageId, forKey: key)
        return nextMessageId
    }
}
