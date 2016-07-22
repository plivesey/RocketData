//
//  AppDelegate.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)

        let chatsViewController = ChatsViewController()
        let navigationController = UINavigationController(rootViewController: chatsViewController)
        window?.rootViewController = navigationController

        window?.makeKeyAndVisible()
        
        return true
    }
}
