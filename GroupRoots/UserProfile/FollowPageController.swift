//
//  GroupProfileController.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//


import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

 // This will be the basis of group profile controller

class FollowPageController: UICollectionViewController, loadMoreFollowersCellDelegate {

    var user: User? {
        didSet {
            configureFollowing()
        }
    }
    
    var following = [User]()
    var followers = [User]()
    var oldestRetrievedDate = 10000000000000.0

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
        navigationItem.title = "Followers"
        
        self.navigationController?.navigationBar.shadowImage = UIColor.white.as1ptImage()
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(FollowPageCell.self, forCellWithReuseIdentifier: FollowPageCell.cellId)
        collectionView?.register(LoadMoreFollowersCell.self, forCellWithReuseIdentifier: LoadMoreFollowersCell.cellId)
        collectionView?.register(FollowPageHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FollowPageHeader.headerId)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl

    }

    private func configureFollowing() {
        guard user != nil else { return }
//        navigationItem.title = user.username
        handleRefresh()
    }

    private func configureHeader() {
        header?.isFollowerView = isFollowerView!
    }

    @objc private func handleRefresh() {
        guard let user_id = user?.uid else { return }

        followers.removeAll()
        following.removeAll()
        oldestRetrievedDate = 10000000000000.0
        
        self.collectionView?.refreshControl?.beginRefreshing()
        
        Database.database().fetchUserFollowing(withUID: user_id, completion: { (following_users) in
            self.following = following_users
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
        
        fetchMoreFollowers()
    }
    
    func handleLoadMoreFollowers() {
        fetchMoreFollowers()
    }
    
    private func fetchMoreFollowers() {
        guard let user_id = user?.uid else { return }
        
        collectionView?.refreshControl?.beginRefreshing()
        Database.database().fetchMoreFollowers(withUID: user_id, endAt: oldestRetrievedDate, completion: { (follower_users, lastFollow) in
            self.followers += follower_users
            if follower_users.last == nil {
                self.collectionView?.refreshControl?.endRefreshing()
                return
            }
            self.oldestRetrievedDate = lastFollow
            print("setting oldest date as: ", self.oldestRetrievedDate)
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }) { (_) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        if isFollowerView! {
            if indexPath.item < followers.count {
                userProfileController.user = followers[indexPath.item]
                navigationController?.pushViewController(userProfileController, animated: true)
            }
        }
        else{
            userProfileController.user = following[indexPath.item]
            navigationController?.pushViewController(userProfileController, animated: true)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFollowerView! {
            if followers.count > 0 {
                return followers.count + 1
            }
            return 0
        }
        return following.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isFollowerView! {
            if indexPath.row < followers.count {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowPageCell.cellId, for: indexPath) as! FollowPageCell
                cell.user = followers[indexPath.item]
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoadMoreFollowersCell.cellId, for: indexPath) as! LoadMoreFollowersCell
                cell.delegate = self
                cell.index = indexPath.row // set tag as the row to decide whether or not the load more label is visible
                cell.user = user
                return cell
            }
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowPageCell.cellId, for: indexPath) as! FollowPageCell
            cell.user = following[indexPath.item]
            return cell
        }
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


