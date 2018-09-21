//
//  AppDelegate.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import UIKit
import RocketData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        let chatsViewController = ChatsViewController()
        let navigationController = UINavigationController(rootViewController: chatsViewController)
        window?.rootViewController = navigationController

        window?.makeKeyAndVisible()

        // We're going to send random push notifications to the app to show how we can use Rocket Data to handle data changes
        // The push notifications are going to be users coming online/offline and new messages
        NetworkManager.startRandomPushNotifications()
        
        return true
    }

    func pushNotificationReceivedWithUpdatedUser(_ user: UserModel) {
        // This simulates what happens if we get a push notification which makes a user come online or goes offline
        // This probably isn't where this code should be, but it shows how you could handle this type of event

        DataModelManager.sharedInstance.updateModel(user)
    }

    func pushNotificationReceivedWithNewMessage(_ message: MessageModel) {
        // We use the sender id as the collection id
        let collectionCacheKey = CollectionCacheKey.messages(message.sender.id)
        // We can use this class method to update all collection data providers with this cache key
        CollectionDataProvider<MessageModel>.append([message], cacheKey: collectionCacheKey.cacheKey(), dataModelManager: DataModelManager.sharedInstance)
    }
}
