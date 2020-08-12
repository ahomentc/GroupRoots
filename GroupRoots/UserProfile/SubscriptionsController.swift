//
//  SubscriptionsController.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 3/7/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

 // This will be the basis of group profile controller

class SubscriptionsController: UICollectionViewController {

    var user: User? {
        didSet {
            self.handleRefresh()
        }
    }
    
    var subscriptions = [Group]()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        navigationItem.title = "Subscriptions"
        self.navigationController?.navigationBar.shadowImage = UIColor.white.as1ptImage()
//        navigationItem.title = "Subscriptions"
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(SubscriptionCell.self, forCellWithReuseIdentifier: SubscriptionCell.cellId)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl

    }

    @objc private func handleRefresh() {
        guard let user_id = user?.uid else { return }

//        self.navigationItem.title = username
        self.subscriptions.removeAll()

        collectionView?.refreshControl?.beginRefreshing()
        Database.database().fetchUserSubscriptions(withUID: user_id, completion: { (subscription_groups) in
            self.subscriptions = subscription_groups
            self.collectionView.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        groupProfileController.group = subscriptions[indexPath.item]
        navigationController?.pushViewController(groupProfileController, animated: true)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subscriptions.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SubscriptionCell.cellId, for: indexPath) as! SubscriptionCell
        if subscriptions.count != 0 && indexPath.item < subscriptions.count {
            cell.group = subscriptions[indexPath.item]
        }
//        cell.delegate = self
        return cell
    }
   
}

extension SubscriptionsController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 66)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 10)
    }
}
