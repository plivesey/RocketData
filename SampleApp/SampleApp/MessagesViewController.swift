//
//  MessagesViewController.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import UIKit
import RocketData

class MessagesViewController: UIViewController, CollectionDataProviderDelegate, DataProviderDelegate, UITableViewDataSource, UITableViewDelegate {

    let userDataProvider = DataProvider<UserModel>()
    let dataProvider = CollectionDataProvider<MessageModel>()

    let cacheKey: String

    // IBOutlets

    @IBOutlet weak var tableView: UITableView!

    init(otherUser: UserModel) {
        userDataProvider.setData(otherUser)
        cacheKey = CollectionCacheKey.messages(otherUser.id).cacheKey()

        super.init(nibName: "MessagesViewController", bundle: nil)

        userDataProvider.delegate = self
        dataProvider.delegate = self
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

    // MARK: - DataProvider

    func dataProviderHasUpdatedData<T>(dataProvider: DataProvider<T>, context: Any?) {
        if let user = userDataProvider.data {
            title = "Chat with \(user.name)"
        }
    }

    func collectionDataProviderHasUpdatedData<T>(dataProvider: CollectionDataProvider<T>, collectionChanges: CollectionChange, context: Any?) {
        // Optional: Use collectionChanges to do tableview animations
        self.tableView.reloadData()
    }
}
