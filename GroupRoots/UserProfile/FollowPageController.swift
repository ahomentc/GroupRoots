//
//  GroupProfileController.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//


import UIKit
import Firebase


 // This will be the basis of group profile controller

class FollowPageController: UICollectionViewController {

    var user: User? {
        didSet {
            configureFollowing()
        }
    }
    
    var following = [User]()
    var followers = [User]()

    private var header: FollowPageHeader?

    private let alertController: UIAlertController = {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        return ac
    }()

    //    private var isFinishedPaging = false
    //    private var pagingCount: Int = 4

    var isFollowerView: Bool? {
        didSet {
            configureHeader()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        self.navigationController?.navigationBar.shadowImage = UIColor.white.as1ptImage()
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(FollowPageCell.self, forCellWithReuseIdentifier: FollowPageCell.cellId)
        collectionView?.register(FollowPageHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FollowPageHeader.headerId)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl

    }

    private func configureFollowing() {
        guard let user = user else { return }
        navigationItem.title = user.username
        handleRefresh()
    }

    private func configureHeader() {
        header?.isFollowerView = isFollowerView!
    }

    @objc private func handleRefresh() {
        guard let user_id = user?.uid else { return }

        followers.removeAll()
        following.removeAll()
        
        self.collectionView?.refreshControl?.beginRefreshing()
        Database.database().fetchUserFollowers(withUID: user_id, completion: { (follower_users) in
            self.followers = follower_users
            Database.database().fetchUserFollowing(withUID: user_id, completion: { (following_users) in
                self.following = following_users
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }) { (err) in
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        if isFollowerView! {
            userProfileController.user = followers[indexPath.item]
        }
        else{
            userProfileController.user = following[indexPath.item]
        }
        navigationController?.pushViewController(userProfileController, animated: true)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFollowerView! {
            return followers.count
        }
        return following.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowPageCell.cellId, for: indexPath) as! FollowPageCell
        if isFollowerView! {
            cell.user = followers[indexPath.item]
        }
        else {
            cell.user = following[indexPath.item]
        }
//        cell.delegate = self
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if header == nil {
            header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FollowPageHeader.headerId, for: indexPath) as? FollowPageHeader
            header?.delegate = self
            header?.isFollowerView = isFollowerView!
        }
        return header!
    }
   
}

extension FollowPageController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 66)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 44)
    }
}

//MARK: - FollowPageHeaderDelegate

extension FollowPageController: FollowPageHeaderDelegate {
    func didChangeToFollowersView() {
        isFollowerView = true
        collectionView?.reloadData()
    }

    func didChangeToFollowingView() {
        isFollowerView = false
        collectionView?.reloadData()
    }
}


