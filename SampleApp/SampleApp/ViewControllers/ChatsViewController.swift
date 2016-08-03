//
//  ChatsViewController.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import UIKit
import RocketData

/**
 This is the home screen of the application.
 It represents a list of users who we are currently chatting with.
 Tapping on a row in this view controller will bring up a `MessagesViewController` which will show the current chat.
 */
class ChatsViewController: UIViewController, CollectionDataProviderDelegate, UITableViewDataSource, UITableViewDelegate {

    /// The data provider which backs this view controller
    private let dataProvider = CollectionDataProvider<UserModel>()
    /// The cache key for our data provider
    private let cacheKey = CollectionCacheKey.chat.cacheKey()

    // MARK: - IBOutlets

    @IBOutlet weak var tableView: UITableView!

    // MARK: - View Lifecycle

    init() {
        super.init(nibName: "ChatsViewController", bundle: nil)
        dataProvider.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Hey Chat App"

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // In parallel, we're going to fetch from the cache and fetch from the network
        // There's no chance of a race condition here, because it's handled by RocketData
        dataProvider.fetchDataFromCache(cacheKey: cacheKey) { (_, _) in
            self.tableView.reloadData()
        }

        NetworkManager.fetchChats { (models, error) in
            if error == nil {
                self.dataProvider.setData(models, cacheKey: self.cacheKey)
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - TableView

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        // You can use subscript notation to access models from the CollectionDataProvider
        let user = dataProvider[indexPath.row]
        var text = user.name
        if !user.online {
            text += " (Offline)"
        }
        cell.textLabel?.text = text
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let user = dataProvider[indexPath.row]
        let messagesViewController = MessagesViewController(otherUser: user)
        navigationController?.pushViewController(messagesViewController, animated: true)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: - CollectionDataProviderDelegate

    func collectionDataProviderHasUpdatedData<T>(dataProvider: CollectionDataProvider<T>, collectionChanges: CollectionChange, context: Any?) {
        // This will be called whenever one of the models changes. In our case, this happens whenever someone comes online/offline.
        // Optional: Use collectionChanges to do tableview animations
        self.tableView.reloadData()
    }
}
