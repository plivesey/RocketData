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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)

        let chatsViewController = ChatsViewController()
        let navigationController = UINavigationController(rootViewController: chatsViewController)
        window?.rootViewController = navigationController

        window?.makeKeyAndVisible()

        NetworkManager.startRandomPushNotifications()
        
        return true
    }

    func pushNotificationReceivedWithUpdatedUser(user: UserModel) {
        // This simulates what happens if we get a push notification which makes a user come online or goes offline
        // This probably isn't where this code should be, but it shows how you could handle this type of event

        DataModelManager.sharedInstance.updateModel(user)
    }
}
