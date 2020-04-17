//
//  NotificationsController.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/18/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import UPCarouselFlowLayout

class NotificationsController: HomePostCellViewController, NotificationCellDelegate {
    private var notifications = [Notification]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        navigationItem.title = "Notifications"
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor : UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
//        self.navigationController?.navigationBar.shadowImage = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).as1ptImage()
        self.navigationController?.navigationBar.shadowImage = UIColor.white.as1ptImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(NotificationCell.self, forCellWithReuseIdentifier: NotificationCell.cellId)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
                
        fetchAllNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
//        self.navigationController?.navigationBar.shadowImage = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).as1ptImage()
        self.navigationController?.navigationBar.shadowImage = UIColor.white.as1ptImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.collectionView?.refreshControl?.endRefreshing()
    }

    private func fetchAllNotifications() {
        collectionView?.refreshControl?.beginRefreshing()

        Database.database().fetchAllNotifications(completion: { (notifications) in
            self.notifications = notifications
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }) { (_) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notifications.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NotificationCell.cellId, for: indexPath) as! NotificationCell
        cell.notification = notifications[indexPath.item]
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    @objc private func handleRefresh() {
            fetchAllNotifications()
    }
    
    func handleShowGroup(group: Group) {
        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        groupProfileController.group = group
        navigationController?.pushViewController(groupProfileController, animated: true)
    }
    
    func handleShowUser(user: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = user
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func handleShowGroupMemberRequest(group: Group) {
        Database.database().isInGroup(groupId: group.groupId, completion: { (inGroup) in
            let membersController = MembersController(collectionViewLayout: UICollectionViewFlowLayout())
            membersController.group = group
            membersController.isInGroup = inGroup
            membersController.isMembersView = false
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationItem.backBarButtonItem?.tintColor = .black
            self.navigationController?.pushViewController(membersController, animated: true)
        }) { (err) in
            return
        }
    }
    
    func handleShowGroupSubscriberRequest(group: Group) {
        // need to remember that maybe a group was private, made public and notification is still there
        // maybe make the actionbutton type just be the group if the group isn't private therefore skipping this function
        Database.database().isInGroup(groupId: group.groupId, completion: { (inGroup) in
            let groupFollowersController = GroupFollowersController(collectionViewLayout: UICollectionViewFlowLayout())
            groupFollowersController.group = group
            groupFollowersController.isInGroup = inGroup
            groupFollowersController.isPrivate = group.isPrivate
            if group.isPrivate ?? false {
                // if group is private enable go to the requestors page
                groupFollowersController.isFollowersView = false
            }
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            self.navigationItem.backBarButtonItem?.tintColor = .black
            self.navigationController?.pushViewController(groupFollowersController, animated: true)
        }) { (err) in
            return
        }
    }
    
    func didTapPost(group: Group, post: GroupPost) {
        let layout = UPCarouselFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.spacingMode = UPCarouselFlowLayoutSpacingMode.fixed(spacing: 8)
        layout.sideItemAlpha = 0.7
        layout.sideItemScale = 0.7

        let largeImageViewController = LargeImageViewController(collectionViewLayout: layout)
        largeImageViewController.group = group
        largeImageViewController.postToScrollToId = post.id
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem?.tintColor = .white
        navigationController?.pushViewController(largeImageViewController, animated: true)
    }
    
    func groupJoinAlert(group: Group) {
        var groupname = group.groupname
        if groupname == "" {
            groupname = "a group"
        }
        let alert = UIAlertController(title: "", message: "You are now a member of " + groupname, preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
          alert.dismiss(animated: true, completion: nil)
        }
    }
}

extension NotificationsController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
    }
}





