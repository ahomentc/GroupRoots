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

class FollowPageController: UICollectionViewController, loadMoreFollowersCellDelegate, UserFollowCellDelegate {

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
    
    //MARK: First follow popup
    private let firstFollowLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Auto Group Follow", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
        attributedText.append(NSMutableAttributedString(string: "\n\nWhen you follow someone\nposts from their public groups\nwill appear in the following feed.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        label.attributedText = attributedText
        return label
    }()
    
    private lazy var firstFollowButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(closeFirstFollowPopup), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Got it", for: .normal)
        return button
    }()
    
    private let firstFollowBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 1)
//        view.layer.borderWidth = 1
//        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.zPosition = 3
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 10
        view.isHidden = true
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 150
        return view
    }()

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
        navigationItem.title = "Users"
        
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

        firstFollowLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height/3-80, width: UIScreen.main.bounds.width, height: 120)
        self.view.insertSubview(firstFollowLabel, at: 4)
        
        firstFollowBackground.frame = CGRect(x: UIScreen.main.bounds.width/2-140, y: UIScreen.main.bounds.height/3-120, width: 280, height: 270)
        self.view.insertSubview(firstFollowBackground, at: 3)
        
        firstFollowButton.frame = CGRect(x: UIScreen.main.bounds.width/2-50, y: UIScreen.main.bounds.height/3+60, width: 100, height: 50)
        firstFollowButton.layer.cornerRadius = 18
        self.view.insertSubview(firstFollowButton, at: 4)
    }

    private func configureFollowing() {
        guard let user = user else { return }
        self.navigationItem.title = user.username
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
                cell.delegate = self
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
            cell.delegate = self
            if indexPath.item < following.count {
                cell.user = following[indexPath.item]
            }
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
    
    func didFollowFirstUser() {
        self.showFirstFollowPopup()
    }
    
    @objc func showFirstFollowPopup() {
        self.firstFollowLabel.isHidden = false
        self.firstFollowBackground.isHidden = false
        self.firstFollowButton.isHidden = false
        
        self.firstFollowLabel.alpha = 0
        self.firstFollowBackground.alpha = 0
        self.firstFollowButton.alpha = 0
        
        UIView.animate(withDuration: 0.5) {
            self.collectionView.alpha = 0
            self.firstFollowLabel.alpha = 1
            self.firstFollowBackground.alpha = 1
            self.firstFollowButton.alpha = 1
        }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            self.collectionView.isHidden = true
        }
        
    }
    
    @objc func closeFirstFollowPopup() {
        self.firstFollowLabel.alpha = 1
        self.firstFollowBackground.alpha = 1
        self.firstFollowButton.alpha = 1
        
        self.collectionView.isHidden = false
        self.collectionView.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.collectionView.alpha = 1
            self.firstFollowLabel.alpha = 0
            self.firstFollowBackground.alpha = 0
            self.firstFollowButton.alpha = 0
        }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            self.firstFollowLabel.isHidden = true
            self.firstFollowBackground.isHidden = true
            self.firstFollowButton.isHidden = true
        }
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


