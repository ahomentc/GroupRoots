//
//  GroupRequestsController.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/18/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class MembersController: UICollectionViewController {
    
    private var users = [User]()
    var group: Group? {
        didSet {
            configureGroup()
        }
    }
    private var header: MembersHeader?

    var isMembersView: Bool? {
        didSet {
            configureGroup()
        }
    }
    
    var isInGroup: Bool? {
        didSet {
            collectionView.reloadData()
            
            if isInGroup! {
                // add plus button to add more members
                let plus = UIBarButtonItem(image: UIImage(named: "plus"), style: .plain, target: self, action: #selector(handleInviteMember)) // action:#selector(Class.MethodName) for swift 3
                self.navigationItem.rightBarButtonItem = plus
                self.navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
            }
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
        navigationItem.title = "Members"
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.cellId)
        collectionView?.register(MembersHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MembersHeader.headerId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
                
        // This might be redundant since the delegate is already being called
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name(rawValue: "updateMembers"), object: nil)
        
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)

    }
    
    private func fetchAllMembers() {
        guard let group = group else { return }
        guard let isMembersView = isMembersView else { return }
        
        collectionView?.refreshControl?.beginRefreshing()
        if isMembersView {
            // get all members
            Database.database().fetchGroupMembers(groupId: group.groupId, completion: { (users) in
                self.users = users
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }) { (_) in
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }
        else{
            // get all requesting members
            Database.database().fetchGroupRequestUsers(groupId: group.groupId, completion: { (users) in
                self.users = users
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }) { (_) in
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }
    }

    private func configureGroup() {
        guard group != nil else { return }
        guard isMembersView != nil else { return }
//        navigationItem.title = group.groupname
        handleRefresh()
    }
    
    @objc private func handleInviteMember() {
        guard let group = group else { return }
        let layout = UICollectionViewFlowLayout()
        let inviteToGroupController = InviteToGroupController(collectionViewLayout: layout)
        inviteToGroupController.group = group
        let navController = UINavigationController(rootViewController: inviteToGroupController)
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc private func handleRefresh() {
        fetchAllMembers()
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCell.cellId, for: indexPath) as! UserCell
        cell.user = users[indexPath.item]
        cell.group = group
        cell.isMembersView = isMembersView
        cell.delegate = self
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if header == nil {
            header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MembersHeader.headerId, for: indexPath) as? MembersHeader
            header?.delegate = self
            header?.isInGroup = isInGroup ?? false
            header?.isMembersView = isMembersView ?? true
        }
        return header!
    }
}

extension MembersController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 66)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if isInGroup ?? false {
            return CGSize(width: view.frame.width, height: 44)
        }
        return CGSize(width: view.frame.width, height: 5)
    }
}


//MARK: - UserDecisionCellDelegate

extension MembersController: UserDecisionCellDelegate {
    func acceptUserRequest() {
        // for some reason never gets here
        // notification instead of this
        
        // just refereshes the page
        fetchAllMembers()
        self.collectionView.reloadData()
    }
}


//MARK: - MembersHeaderDelegate

extension MembersController: MembersHeaderDelegate {

    func didChangeToMembersView() {
        isMembersView = true
        users = []
        collectionView?.reloadData()
        fetchAllMembers()
    }

    func didChangeToRequestsView() {
        isMembersView = false
        users = []
        collectionView?.reloadData()
        fetchAllMembers()
    }
}


