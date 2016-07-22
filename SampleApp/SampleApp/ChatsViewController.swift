//
//  ChatsViewController.swift
//  SampleApp
//
//  Created by Peter Livesey on 7/22/16.
//  Copyright © 2016 LinkedIn. All rights reserved.
//

import UIKit
import RocketData

class ChatsViewController: UIViewController, CollectionDataProviderDelegate, UITableViewDataSource, UITableViewDelegate {

    let dataProvider = CollectionDataProvider<UserModel>()
    let cacheKey = CollectionCacheKey.chat.cacheKey()

    // IBOutlets

    @IBOutlet weak var tableView: UITableView!

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
        cell.textLabel?.text = dataProvider[indexPath.row].name
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let user = dataProvider[indexPath.row]
        let messagesViewController = MessagesViewController(otherUser: user)
        navigationController?.pushViewController(messagesViewController, animated: true)
    }

    // MARK: - DataProvider

    func collectionDataProviderHasUpdatedData<T>(dataProvider: CollectionDataProvider<T>, collectionChanges: CollectionChange, context: Any?) {
        // Optional: Use collectionChanges to do tableview animations
        self.tableView.reloadData()
    }
}
