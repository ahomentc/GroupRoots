//
//  GroupProfileController.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//


import UIKit
import Firebase
import UPCarouselFlowLayout

 // This will be the basis of group profile controller

class GroupProfileController: HomePostCellViewController {

    var group: Group? {
        didSet {
            configureGroup()
        }
    }
    
    var canView: Bool? = nil
    var isInFollowPending: Bool? = nil
    let padding: CGFloat = 12

    private var header: GroupProfileHeader?

    private var alertController: UIAlertController = {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        return ac
    }()

    private var isGridView: Bool = true
    
    private let upperCoverView: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 350))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 0)
        return backgroundView
    }()
    
    private lazy var acceptInviteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Accept Invitation", for: .normal)
        button.addTarget(self, action: #selector(handleInviteJoin), for: .touchUpInside)
        button.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1.2
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.isUserInteractionEnabled = true
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        
        let textAttributes = [NSAttributedString.Key.font: UIFont(name: "Avenir", size: 18)!, NSAttributedString.Key.foregroundColor : UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateGroupProfileFeed, object: nil)

        collectionView?.backgroundColor = .white
        collectionView?.register(GroupProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GroupProfileHeader.headerId)
        collectionView?.register(GroupProfilePhotoGridCell.self, forCellWithReuseIdentifier: GroupProfilePhotoGridCell.cellId)
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: HomePostCell.cellId)
        collectionView?.register(GroupProfileEmptyStateCell.self, forCellWithReuseIdentifier: GroupProfileEmptyStateCell.cellId)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name(rawValue: "updateMembers"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateGroup), name: NSNotification.Name(rawValue: "updatedGroup"), object: nil)
        
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
    
        configureAlertController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.collectionView?.refreshControl?.endRefreshing()
    }

    private func configureAlertController() {
        guard let group = group else { return }
        
        alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let edit_profile = UIAlertAction(title: "Edit Group", style: .default) { (_) in
            do {
                let editGroupController = EditGroupController()
                editGroupController.group = self.group
                let navController = UINavigationController(rootViewController: editGroupController)
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true, completion: nil)
            }
        }
        alertController.addAction(edit_profile)
        
        Database.database().isGroupHiddenOnProfile(groupId: group.groupId, completion: { (isHidden) in
            if isHidden {
                let show_group = UIAlertAction(title: "Show group in my profile", style: .default) { (_) in
                    do {
                        Database.database().setGroupVisibleOnProfile(groupId: group.groupId){ (err) in
                            if err != nil {
                                return
                            }
                            self.configureAlertController()
                        }
                    }
                }
                self.alertController.addAction(show_group)
            }
            else {
                let hide_group = UIAlertAction(title: "Hide group from my profile", style: .default) { (_) in
                    do {
                        Database.database().setGroupHiddenOnProfile(groupId: group.groupId){ (err) in
                            if err != nil {
                                return
                            }
                            self.configureAlertController()
                        }
                    }
                }
                self.alertController.addAction(hide_group)
            }
        }) { (err) in
            return
        }
    }
    
    @objc private func updateGroup(){
        guard let group = group else { return }
        Database.database().fetchGroup(groupId: group.groupId, completion: { (group) in
            self.group = group
            self.configureGroup()
        })
    }

    private func configureGroup() {
        guard let group = group else { return }
        Database.database().isInGroup(groupId: group.groupId, completion: { (inGroup) in
            if inGroup {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(self.handleSettings))
            }
        }) { (err) in
            return
        }
        if group.groupname == "" {
            navigationItem.title = "Group"
        }
        else {
            navigationItem.title = group.groupname
        }
        header?.group = group
        handleRefresh()
    }

    @objc private func handleSettings() {
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func handleInviteJoin() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let group = group else { return }
        // join the group action
        Database.database().acceptIntoGroup(withUID: currentLoggedInUserId, groupId: group.groupId){ (err) in
            if err != nil {
                return
            }
            // remove from group invited
            Database.database().removeFromGroupInvited(withUID: currentLoggedInUserId, groupId: group.groupId) { (err) in
                if err != nil {
                    return
                }
                self.handleDidJoinGroupFromInvite()
                self.view.layoutIfNeeded()
                
                // notification that member is now in group
                Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
                    Database.database().groupExists(groupId: group.groupId, completion: { (exists) in
                        if exists {
                            Database.database().fetchGroup(groupId: group.groupId, completion: { (group) in
                                Database.database().fetchGroupMembers(groupId: group.groupId, completion: { (members) in
                                    members.forEach({ (member) in
                                        if user.uid != member.uid {
                                            Database.database().createNotification(to: member, notificationType: NotificationType.newGroupJoin, subjectUser: user, group: group) { (err) in
                                                if err != nil {
                                                    return
                                                }
                                            }
                                        }
                                    })
                                }) { (_) in}
                            })
                        }
                        else {
                            return
                        }
                    })
                })
            }
        }
    }
    
    @objc private func handleRefresh() {
        guard let groupId = group?.groupId else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().isUserInvitedToGroup(withUID: currentLoggedInUserId, groupId: groupId, completion: { (isInvited) in
            if isInvited {
                self.view.addSubview(self.acceptInviteButton)
                self.acceptInviteButton.anchor(left: self.view.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.rightAnchor, paddingLeft: self.padding, paddingBottom: self.padding + 60, paddingRight: self.padding)
            }
        }) { (err) in
            return
        }
        collectionView?.refreshControl?.beginRefreshing()
        groupPosts.removeAll()
        Database.database().canViewGroupPosts(groupId: groupId, completion: { (canView) in
            if canView{
                self.canView = true
                self.isInFollowPending = false
                Database.database().fetchAllGroupPosts(groupId: groupId, completion: { (countAndPosts) in
                    if countAndPosts.count > 0 {
                        self.groupPosts = countAndPosts[1] as! [GroupPost]
                        self.groupPosts.sort(by: { (p1, p2) -> Bool in
                            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                        })
                    }
                    self.collectionView?.reloadData()
                    self.collectionView?.refreshControl?.endRefreshing()
                }) { (err) in
                    self.collectionView?.refreshControl?.endRefreshing()
                }
                self.header?.reloadGroupData()
            }
            else {
                self.canView = false
                Database.database().isInGroupFollowPending(groupId: groupId, withUID: currentLoggedInUserId, completion: { (followPending) in
                    self.isInFollowPending = true
                    self.collectionView?.reloadData()
                    self.collectionView?.refreshControl?.endRefreshing()
                }) { (err) in
                    return
                }
            }
        }) { (err) in
            return
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if groupPosts.count == 0 {
            return
        }
        
        let layout = UPCarouselFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.spacingMode = UPCarouselFlowLayoutSpacingMode.fixed(spacing: 8)
        layout.sideItemAlpha = 0.7
        layout.sideItemScale = 0.7

        let largeImageViewController = LargeImageViewController(collectionViewLayout: layout)
        largeImageViewController.group = group
        largeImageViewController.indexPath = indexPath
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem?.tintColor = .white
        navigationController?.pushViewController(largeImageViewController, animated: true)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if groupPosts.count == 0 {
            return 1
        }
        return groupPosts.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if groupPosts.count == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupProfileEmptyStateCell.cellId, for: indexPath)  as! GroupProfileEmptyStateCell
            cell.canView = self.canView
            cell.isInFollowPending = self.isInFollowPending
            return cell
        }

        if isGridView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupProfilePhotoGridCell.cellId, for: indexPath) as! GroupProfilePhotoGridCell
            cell.groupPost = groupPosts[indexPath.item]
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePostCell.cellId, for: indexPath) as! HomePostCell
        cell.groupPost = groupPosts[indexPath.item]
        cell.delegate = self
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if header == nil {
            header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: GroupProfileHeader.headerId, for: indexPath) as? GroupProfileHeader
            header?.delegate = self
            header?.group = group
            header?.numberOfPosts = self.groupPosts.count
        }
        return header!
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension GroupProfileController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if groupPosts.count == 0 {
            let emptyStateCellHeight = (view.safeAreaLayoutGuide.layoutFrame.height - 300)
            return CGSize(width: view.frame.width, height: emptyStateCellHeight)
        }

        if isGridView {
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        } else {
            let dummyCell = HomePostCell(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 1000))
            dummyCell.groupPost = groupPosts[indexPath.item]
            dummyCell.layoutIfNeeded()

            var height: CGFloat = dummyCell.header.bounds.height
            height += view.frame.width
            height += 24 + 2 * dummyCell.padding //bookmark button + padding
            height += dummyCell.captionLabel.intrinsicContentSize.height + 8

            //TODO: unsure why this is needed
            height += 8

            return CGSize(width: view.frame.width, height: height)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 300)
    }

}

//MARK: - GroupProfileHeaderDelegate

extension GroupProfileController: GroupProfileHeaderDelegate {

    func didChangeToGridView() {
        isGridView = true
        collectionView?.reloadData()
    }

    func didChangeToListView() {
        isGridView = false
        collectionView?.reloadData()
    }

    @objc internal func handleShowNewGroup() {
//        let createGroupController = CreateGroupController()
    }
    
    @objc internal func handleDidJoinGroupFromInvite() {
        guard let group = group else { return }
        self.acceptInviteButton.isHidden = true
        
        var groupname = group.groupname
        if group.groupname == "" {
            groupname = " a group"
        }
        let alert = UIAlertController(title: "", message: "You are now a member of " + groupname, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
          alert.dismiss(animated: true, completion: nil)
        }
        
        // notification to refresh
        NotificationCenter.default.post(name: NSNotification.Name("updateMembers"), object: nil)
        
        self.handleRefresh()
    }
    
    @objc internal func handleShowUsersRequesting() {
        Database.database().isInGroup(groupId: group!.groupId, completion: { (inGroup) in
            let membersController = MembersController(collectionViewLayout: UICollectionViewFlowLayout())
            membersController.group = self.group
            membersController.isInGroup = inGroup
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationItem.backBarButtonItem?.tintColor = .black
            self.navigationController?.pushViewController(membersController, animated: true)
        }) { (err) in
            return
        }
    }
    
    @objc internal func handleShowFollowers(){
        Database.database().isInGroup(groupId: group!.groupId, completion: { (inGroup) in
            let groupFollowersController = GroupFollowersController(collectionViewLayout: UICollectionViewFlowLayout())
            groupFollowersController.group = self.group
            groupFollowersController.isInGroup = inGroup
            groupFollowersController.isPrivate = self.group?.isPrivate
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationItem.backBarButtonItem?.tintColor = .black
            self.navigationController?.pushViewController(groupFollowersController, animated: true)
        }) { (err) in
            return
        }
    }
    
    @objc internal func handleShowEditGroup(){
        let editGroupController = EditGroupController()
        editGroupController.group = self.group
        let navController = UINavigationController(rootViewController: editGroupController)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc internal func showInviteCopyAlert() {
        let alert = UIAlertController(title: "", message: "Invite Code copied to clipboard", preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
          alert.dismiss(animated: true, completion: nil)
        }
    }
}


