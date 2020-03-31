//
//  GroupFollowersController.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 2/28/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

class GroupFollowersController: UICollectionViewController {
    
    private var users = [User]()
    var group: Group? {
        didSet {
            configureGroup()
        }
    }
    private var header: GroupFollowersHeader?
    private var isFollowersView: Bool = true
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        view.backgroundColor = .white

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(GroupFollowerCell.self, forCellWithReuseIdentifier: GroupFollowerCell.cellId)
        collectionView?.register(GroupFollowersHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GroupFollowersHeader.headerId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        // This might be redundant since the delegate is already being called
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name(rawValue: "updateMembers"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name(rawValue: "updateFollowers"), object: nil)
        
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)

    }
    
    // only load the 
    private func fetchAllFollowers() {
        collectionView?.refreshControl?.beginRefreshing()
        
        guard let group = group else { return }
        
        if isFollowersView {
            // get all followers
            Database.database().fetchGroupFollowers(groupId: group.groupId, completion: { (users) in
                self.users = users
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }) { (_) in
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }
        else{
            // get all pending followers
            Database.database().fetchGroupFollowersPending(groupId: group.groupId, completion: { (users) in
                print("fetching requesting followers")
                self.users = users
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }) { (_) in
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }
    }

    private func configureGroup() {
        guard let group = group else { return }
        navigationItem.title = group.groupname
        handleRefresh()
    }
    
    @objc private func handleRefresh() {
        fetchAllFollowers()
    }
    
    // when an item is selected, go to that view controller
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = users[indexPath.item]
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupFollowerCell.cellId, for: indexPath) as! GroupFollowerCell
        cell.user = users[indexPath.item]
        cell.group = group
        cell.showRemoveButton = isInGroup ?? false
        cell.isFollowersView = isFollowersView
        cell.delegate = self
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if header == nil {
            header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GroupFollowersHeader.headerId, for: indexPath) as? GroupFollowersHeader
            header?.delegate = self
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
        fetchAllFollowers()
        self.collectionView.reloadData()
    }
}


//MARK: - MembersHeaderDelegate

extension GroupFollowersController: GroupFollowersHeaderDelegate {
    func didChangeToFollowersView() {
        isFollowersView = true
        users = []
        collectionView?.reloadData()
        fetchAllFollowers()
    }
    
    func didChangeToPendingFollowersView() {
        isFollowersView = false
        users = []
        collectionView?.reloadData()
        fetchAllFollowers()
    }
}



