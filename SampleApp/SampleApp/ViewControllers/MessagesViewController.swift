//
//  MessagesViewController.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import UIKit
import RocketData

/**
 This view controller displays a list of messages between the current user and another user.
 It has a button to say "hey" to the other user. The only thing you can do in chats is say "hey".
 */
class MessagesViewController: UIViewController, CollectionDataProviderDelegate, DataProviderDelegate, UITableViewDataSource, UITableViewDelegate {

    /// This data provider is for the other user. We only use this to display the title of the view controller.
    private let userDataProvider = DataProvider<UserModel>()
    /// This data provider is for all the messages in our table view.
    private let dataProvider = CollectionDataProvider<MessageModel>()

    /// This is the cache key we use for the CollectionDataProvider. It's generated based on the other user's id.
    private let cacheKey: String

    // MARK: - IBOutlets

    @IBOutlet weak var tableView: UITableView!

    // MARK: - View Lifecycle

    init(otherUser: UserModel) {
        cacheKey = CollectionCacheKey.messages(otherUser.id).cacheKey()

        super.init(nibName: "MessagesViewController", bundle: nil)

        userDataProvider.delegate = self
        dataProvider.delegate = self

        userDataProvider.setData(otherUser)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let user = userDataProvider.data {
            title = "Chat with \(user.name)"
        }

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // We're going to do two things in parallel - access the cache and the network.
        // RocketData ensures there is no race condition here. If the cache returns after the network, the cache result is automatically discarded.
        dataProvider.fetchDataFromCache(cacheKey: cacheKey) { (_, _) in
            self.tableView.reloadData()
        }

        if let user = userDataProvider.data {
            NetworkManager.fetchMessage(user) { (models, error) in
                if error == nil {
                    self.dataProvider.setData(models, cacheKey: self.cacheKey)
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Actions

    @IBAction func heyButtonPressed() {
        // Here is where you'd send an actualy network request. But we're just going to create a message model locally.
        let loggedInUser = NetworkManager.loggedInUser()
        let newMessageId = NetworkManager.nextMessageId()
        let message = MessageModel(id: newMessageId, text: "hey", sender: loggedInUser)
        dataProvider.append([message])

        tableView.reloadData()
    }

    // MARK: - TableView

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider.count
    }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

        let message = dataProvider[indexPath.row]
        var text = message.sender.name
        if !message.sender.online {
            text += " (Offline)"
        }
        text += ": \(dataProvider[indexPath.row].text)"
        cell.textLabel?.text = text
        return cell
    }

    // MARK: - DataProviderDelegates

    func dataProviderHasUpdatedData<T>(dataProvider: DataProvider<T>, context: Any?) {
        // Since we only use this model to set the title, it's the only UI we need to update.
        if let user = userDataProvider.data {
            title = "Chat with \(user.name)"
        }
    }

    func collectionDataProviderHasUpdatedData<T>(dataProvider: CollectionDataProvider<T>, collectionChanges: CollectionChange, context: Any?) {
        // This will be called whenever one of the models changes. In our case, this happens whenever someone comes online/offline.
        // Optional: Use collectionChanges to do tableview animations
        self.tableView.reloadData()
    }
}
