//
//  GroupFollowersController.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 2/28/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class GroupFollowersController: UICollectionViewController, loadMoreSubscribersCellDelegate {
    
    private var users = [User]()
    var oldestRetrievedDate = 10000000000000.0
    
    var group: Group? {
        didSet {
            configureGroup()
        }
    }
    private var header: GroupFollowersHeader?
    
    var isInGroup: Bool? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var isPrivate: Bool? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var isFollowersView: Bool? {
        didSet {
            configureGroup()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        view.backgroundColor = .white

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        navigationItem.title = "Subscribers"
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(GroupFollowerCell.self, forCellWithReuseIdentifier: GroupFollowerCell.cellId)
        collectionView?.register(LoadMoreSubscribersCell.self, forCellWithReuseIdentifier: LoadMoreSubscribersCell.cellId)
        collectionView?.register(GroupFollowersHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GroupFollowersHeader.headerId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        // This might be redundant since the delegate is already being called
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name(rawValue: "updateMembers"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name(rawValue: "updateFollowers"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.removeASubscribeRequestor(_:)), name: NSNotification.Name(rawValue: "removeASubscribeRequestor"), object: nil)
        
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)

    }

    // make this be limited and expand when reach bottom
    private func fetchSubscribers() {
        collectionView?.refreshControl?.beginRefreshing()
        
        guard let group = group else { return }
        guard let isFollowersView = isFollowersView else { return }
        
        if isFollowersView {
            Database.database().fetchMoreGroupFollowers(groupId: group.groupId, endAt: oldestRetrievedDate, completion: { (followers, lastFollow) in
                self.users += followers
                if followers.last == nil {
                    self.collectionView?.refreshControl?.endRefreshing()
                    return
                }
                self.oldestRetrievedDate = lastFollow
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }) { (_) in
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }
        else{
            // get all pending followers
            Database.database().fetchGroupFollowersPending(groupId: group.groupId, completion: { (users) in
                self.users = users
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }) { (_) in
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }
    }
    
    func handleLoadMoreSubscribers() {
        fetchSubscribers()
    }

    private func configureGroup() {
        guard group != nil else { return }
        guard isFollowersView != nil else { return }
//        navigationItem.title = group.groupname
        handleRefresh()
    }
    
    @objc private func handleRefresh() {
        users.removeAll()
        oldestRetrievedDate = 10000000000000.0
        fetchSubscribers()
    }
    
    @objc private func removeASubscribeRequestor(_ notification: NSNotification){
        if let dict = notification.userInfo as NSDictionary? {
            if let user_id = dict["id"] as? String{
                // remove user_id from self.users
                users.removeAll { $0.uid == user_id }
                self.collectionView?.refreshControl?.beginRefreshing()
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }
    }
    
    // when an item is selected, go to that view controller
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        
        if isFollowersView! {
            if indexPath.item < users.count {
                userProfileController.user = users[indexPath.item]
                navigationController?.pushViewController(userProfileController, animated: true)
            }
        }
        else{
            userProfileController.user = users[indexPath.item]
            navigationController?.pushViewController(userProfileController, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !isFollowersView! {
            return users.count
        }
        
        if users.count > 0 {
            return users.count + 1
        }
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if !isFollowersView! {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupFollowerCell.cellId, for: indexPath) as! GroupFollowerCell
            if indexPath.row < users.count {
                cell.user = users[indexPath.item]
            }
            cell.group = group
            cell.showRemoveButton = isInGroup ?? false
            cell.isFollowersView = isFollowersView
            cell.delegate = self
            return cell
        }
        
        if indexPath.row < users.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupFollowerCell.cellId, for: indexPath) as! GroupFollowerCell
            cell.user = users[indexPath.item]
            cell.group = group
            cell.showRemoveButton = isInGroup ?? false
            cell.isFollowersView = isFollowersView
            cell.delegate = self
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoadMoreSubscribersCell.cellId, for: indexPath) as! LoadMoreSubscribersCell
            cell.delegate = self
            cell.index = indexPath.row // set tag as the row to decide whether or not the load more label is visible
            cell.group = group
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if header == nil {
            header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GroupFollowersHeader.headerId, for: indexPath) as? GroupFollowersHeader
            header?.delegate = self
            header?.isFollowersView = isFollowersView ?? true
            header?.showPendingButton = (isInGroup ?? false) && (isPrivate ?? false)
        }
        return header!
    }
}

extension GroupFollowersController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 66)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if (isInGroup ?? false) && (isPrivate ?? false) {
            return CGSize(width: view.frame.width, height: 44)
        }
        return CGSize(width: view.frame.width, height: 5)
    }
}


//MARK: - UserDecisionCellDelegate

extension GroupFollowersController: GroupFollowersCellDelegate {
    func acceptUserRequest() {
        // for some reason never gets here
        // notification instead of this
        
        // just refereshes the page
        users = []                                  // just added
        oldestRetrievedDate = 10000000000000.0      // just added
        fetchSubscribers()
        self.collectionView.reloadData()
    }
}


//MARK: - MembersHeaderDelegate

extension GroupFollowersController: GroupFollowersHeaderDelegate {
    func didChangeToFollowersView() {
        isFollowersView = true
        users = []
        oldestRetrievedDate = 10000000000000.0
        collectionView?.reloadData()
//        fetchSubscribers()
    }
    
    func didChangeToPendingFollowersView() {
        isFollowersView = false
        users = []
        oldestRetrievedDate = 10000000000000.0
        collectionView?.reloadData()
        fetchSubscribers()
    }
}



