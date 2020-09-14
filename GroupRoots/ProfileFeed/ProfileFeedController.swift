//
//  ProfileFeedController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 5/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import NVActivityIndicatorView
import Zoomy
import SwiftGifOrigin

class ProfileFeedController: UICollectionViewController, UICollectionViewDelegateFlowLayout, ViewersControllerDelegate, FeedGroupCellDelegate, CreateGroupControllerDelegate, InviteToGroupWhenCreateControllerDelegate {
        
    override var prefersStatusBarHidden: Bool {
      return statusBarHidden
    }
    
    var statusBarHidden = false {
      didSet(newValue) {
        setNeedsStatusBarAppearanceUpdate()
      }
    }
    
    // 2d representation of the dict, same as dict but with no values
    // later, just use the dict but convert it to this after all data is loaded in
    var groupPosts2D = [[GroupPost]]()
    var groupMembers = [String: [User]]()
    var groupPostsTotalViewersDict = [String: [String: Int]]()          // Dict inside dict. First key is the groupId. Within the value is another key with postId
    var groupPostsVisibleViewersDict = [String: [String: [User]]]()     //    same   ^
    var groupPostsFirstCommentDict = [String: [String: Comment]]()      //    same   |
    var groupPostsNumCommentsDict = [String: [String: Int]]()           // -- same --|
    var numGroupsInFeed = 5
    var usingCachedData = true
    var fetchedAllGroups = false
    var oldestRetrievedDate = 10000000000000.0
    
    var isFirstView = true
    
    private let loadingScreenView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 10
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0, alpha: 1)
        return iv
    }()
    
    private let noInternetLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "No Internet Connection", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
        label.attributedText = attributedText
        return label
    }()
    
    private let noInternetBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        view.layer.zPosition = 3
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 10
        view.isHidden = true
        return view
    }()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.4, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Welcome to GroupRoots!\n\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        attributedText.append(NSMutableAttributedString(string: "When you subscribe to groups, you'll\nsee photos and videos they post here\n\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        attributedText.append(NSMutableAttributedString(string: "When you join a group, you’ll\nbe able to post to it.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
//        attributedText.append(NSMutableAttributedString(string: "Following friends automatically\n subscribes you to their public groups", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        label.attributedText = attributedText
        return label
    }()
    
    private let noSubscriptionsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.4, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "No group posts yet\n\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        attributedText.append(NSMutableAttributedString(string: "When you subscribe to groups, you'll\nsee photos and videos they post here\n\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        attributedText.append(NSMutableAttributedString(string: "When you join a group, you’ll\nbe able to post to it.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        label.attributedText = attributedText
        return label
    }()

    private lazy var reloadButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(loadFromNoInternet), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Retry", for: .normal)
        return button
    }()
    
    private lazy var newGroupButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleShowNewGroup), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Create a Group", for: .normal)
        return button
    }()
    
    private lazy var goButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleFirstGo), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Next", for: .normal)
        return button
    }()
    
    private lazy var inviteButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleShowInviteCode), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Enter a Group Invite Code", for: .normal)
        return button
    }()
    
    private lazy var createGroupIconButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleShowNewGroup), for: .touchUpInside)
        button.layer.zPosition = 10;
        button.setImage(#imageLiteral(resourceName: "group_plus"), for: .normal)
        return button
    }()
    
    let logoImageView: UIImageView = {
        let img = UIImageView()
        img.image = #imageLiteral(resourceName: "icon_login_4")
        img.isHidden = true
        return img
    }()
    
    let horizontalGifView: UIImageView = {
        let img = UIImageView()
        img.isHidden = true
        return img
    }()
    
    let verticalGifView: UIImageView = {
        let img = UIImageView()
        img.isHidden = true
        return img
    }()
    
    private lazy var animationsButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(showSecondAnim), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Next", for: .normal)
        return button
    }()
    
    private lazy var animationsButton2: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(endIntro), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Got it", for: .normal)
        return button
    }()
    
    private let animationsTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.4, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Group Profile Feed", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        label.attributedText = attributedText
        return label
    }()
    
    private let animationsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.4, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Swipe up to cycle through groups.\nGroups appear by the last time they posted.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)])
        label.attributedText = attributedText
        return label
    }()
    
    let activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width/2 - 35, y: UIScreen.main.bounds.height/2 - 35, width: 70, height: 70), type: NVActivityIndicatorType.circleStrokeSpin)
    
    func showEmptyStateViewIfNeeded() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().numberOfSubscriptionsForUser(withUID: currentLoggedInUserId) { (followingCount) in
            Database.database().numberOfGroupsForUser(withUID: currentLoggedInUserId, completion: { (groupsCount) in
                if followingCount == 0 && groupsCount == 0 {
                    self.newGroupButton.isHidden = false
                    self.goButton.isHidden = true
                    self.inviteButton.isHidden = false
//                    self.welcomeLabel.isHidden = false
                    self.noSubscriptionsLabel.isHidden = false
                    self.logoImageView.isHidden = false
                    
//                    TableViewHelper.EmptyMessage(message: "Welcome to GroupRoots!\n\nFollow friends to see their\ngroups in your feed", viewController: self)
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                        self.collectionView?.backgroundView?.alpha = 1
                    }, completion: nil)
                    
                } else {
                    self.collectionView?.backgroundView?.alpha = 0
                }
            })
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
        // Show the navigation bar on other view controllers
        self.collectionView?.refreshControl?.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                (cell as! FeedGroupCell).pauseVisibleVideo()
            }
        }
        
        self.collectionView.scrollToNearestVisibleCollectionViewCell()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.configureNavBar()
        
        // check if fullscreen and set tabBar color accordingly
        for cell in collectionView.visibleCells {
            if cell is FeedGroupCell {
                let visible_cell = cell as! FeedGroupCell
                if visible_cell.isFullScreen {
                    self.createGroupIconButton.isHidden = true
                    NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
//                    self.statusBarHidden = true
                }
                else {
                    self.createGroupIconButton.isHidden = false
                    NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
//                    self.statusBarHidden = false
                }
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        if let hasOpenedAppRetrieved = UserDefaults.standard.object(forKey: "hasOpenedApp") as? Data {
            guard let hasOpenedApp = try? JSONDecoder().decode(Bool.self, from: hasOpenedAppRetrieved) else {
                print("Error: Couldn't decode data into Blog")
                return
            }
            self.isFirstView = !hasOpenedApp
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
        
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor : UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        loadingScreenView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        loadingScreenView.layer.cornerRadius = 0
        loadingScreenView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        loadingScreenView.image =  #imageLiteral(resourceName: "Splash4")
        self.view.insertSubview(loadingScreenView, at: 10)
        
        reloadButton.frame = CGRect(x: UIScreen.main.bounds.width/2-50, y: UIScreen.main.bounds.height/2, width: 100, height: 50)
        reloadButton.layer.cornerRadius = 18
        self.view.insertSubview(reloadButton, at: 4)
        
        noInternetLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height/2-50, width: UIScreen.main.bounds.width, height: 20)
        self.view.insertSubview(noInternetLabel, at: 4)
        
        noInternetBackground.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-100, width: 300, height: 200)
        self.view.insertSubview(noInternetBackground, at: 3)
        
        welcomeLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-150, width: 300, height: 300)
        self.view.insertSubview(welcomeLabel, at: 4)
        
        noSubscriptionsLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-150, width: 300, height: 300)
        self.view.insertSubview(noSubscriptionsLabel, at: 4)
        
        inviteButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 - 30, width: 300, height: 50)
        inviteButton.layer.cornerRadius = 14
        self.view.insertSubview(inviteButton, at: 4)
        
        newGroupButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 + 30, width: 300, height: 50)
        newGroupButton.layer.cornerRadius = 14
        self.view.insertSubview(newGroupButton, at: 4)
        
        goButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 + 30, width: 300, height: 50)
        goButton.layer.cornerRadius = 14
        self.view.insertSubview(goButton, at: 4)
        
        logoImageView.frame = CGRect(x: view.frame.width/2 - 100, y: 80, width: 200, height: 200)
        self.view.addSubview(logoImageView)
        
        horizontalGifView.frame = CGRect(x: view.frame.width/2 - 101.25, y: UIScreen.main.bounds.height/3 - 70, width: 202.5, height: 360)
        horizontalGifView.loadGif(name: "horiz")
        self.view.addSubview(horizontalGifView)
        
        verticalGifView.frame = CGRect(x: view.frame.width/2 - 101.25, y: UIScreen.main.bounds.height/3 - 50, width: 202.5, height: 300.15)
        verticalGifView.loadGif(name: "vert")
        self.view.addSubview(verticalGifView)
        
        animationsTitleLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/3-300, width: 300, height: 300)
        self.view.addSubview(animationsTitleLabel)
        
        animationsLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-200, y: UIScreen.main.bounds.height/3-250, width: 400, height: 300)
        self.view.addSubview(animationsLabel)
        
        animationsButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 + 30, width: 300, height: 50)
        animationsButton.layer.cornerRadius = 14
        self.view.insertSubview(animationsButton, at: 4)
        
        animationsButton2.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 + 30, width: 300, height: 50)
        animationsButton2.layer.cornerRadius = 14
        self.view.insertSubview(animationsButton2, at: 4)
        
        createGroupIconButton.frame = CGRect(x: UIScreen.main.bounds.width-50, y: 30, width: 40, height: 40)
        createGroupIconButton.layer.cornerRadius = 14
        self.view.insertSubview(createGroupIconButton, at: 10)
        
        collectionView?.register(FeedGroupCell.self, forCellWithReuseIdentifier: "cellId")
        collectionView?.register(EmptyFeedPostCell.self, forCellWithReuseIdentifier: EmptyFeedPostCell.cellId)
        collectionView?.allowsSelection = false
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.isPagingEnabled = true
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = .clear
        
        self.view.backgroundColor = .white
        
        // what happens here if there's been paging... more specifically, what happens when refresh and had paging occur?
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateUserProfileFeed, object: nil)
        configureNavigationBar()
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { timer in
            self.loadingScreenView.isHidden = true
        })
        
        PushNotificationManager().updatePushTokenIfNeeded()
        
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
            self.reloadButton.isHidden = true
            self.noInternetLabel.isHidden = true
            self.noInternetBackground.isHidden = true
            
            activityIndicatorView.isHidden = false
            activityIndicatorView.color = .black
            self.view.insertSubview(activityIndicatorView, at: 20)
            activityIndicatorView.startAnimating()
            
            self.loadGroupPosts()
        } else {
            print("Internet Connection not Available!")
            self.reloadButton.isHidden = false
            self.noInternetLabel.isHidden = false
            self.noInternetBackground.isHidden = false
        }
    }
    
    @objc func handleRefresh() {
        // stop video of visible cell
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                // TODO: write logic to stop the video before it begins scrolling
                (cell as! FeedGroupCell).pauseVisibleVideo()
            }
        }
        groupPosts2D = [[GroupPost]]()
        groupMembers = [String: [User]]()
        groupPostsTotalViewersDict = [String: [String: Int]]()
        groupPostsVisibleViewersDict = [String: [String: [User]]]()
        groupPostsFirstCommentDict = [String: [String: Comment]]()
        groupPostsNumCommentsDict = [String: [String: Int]]()
        oldestRetrievedDate = 10000000000000.0
        self.numGroupsInFeed = 5
        self.fetchedAllGroups = false
        
        loadGroupPosts()
    }
    
    private func configureNavigationBar() {
        self.configureNavBar()
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor : UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
    }
    
    func requestZoomCapability(for cell: FeedPostCell) {
        addZoombehavior(for: cell.photoImageView, settings: .instaZoomSettings)
    }
    
    private func loadGroupPosts(){
        addGroupPosts()
        showEmptyStateViewIfNeeded()
    }
    
    private func addGroupPosts() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        collectionView?.refreshControl?.beginRefreshing()
        var group_ids = Set<String>()
        var tempGroupPosts2D = [[GroupPost]]()
        // get all the userIds of the people user is following
        let sync = DispatchGroup()
        var batch_size = 6
        batch_size = batch_size - 1

        // we don't need to show posts of groups that are member of but not following.
        // They auto follow it so they'd have to unfollow to not be in following, which means they
        // don't want to see the posts
        sync.enter()
        Database.database().fetchNextGroupsFollowing(withUID: currentLoggedInUserId, endAt: oldestRetrievedDate, completion: { (groups) in
            self.reloadButton.isHidden = true
            self.newGroupButton.isHidden = true
            self.goButton.isHidden = true
            self.inviteButton.isHidden = true
            self.welcomeLabel.isHidden = true
            self.noSubscriptionsLabel.isHidden = true
            self.logoImageView.isHidden = true
            self.noInternetLabel.isHidden = true
            self.noInternetBackground.isHidden = true
            if groups.last == nil {
                self.collectionView?.refreshControl?.endRefreshing()
                sync.leave()
                return
            }
//            self.oldestRetrievedDate = groups.first!.lastPostedDate
            Database.database().fetchGroupsFollowingGroupLastPostedDate(withUID: currentLoggedInUserId, groupId: groups.first!.groupId) { (date) in
                self.oldestRetrievedDate = date
                groups.forEach({ (group) in
                    if group_ids.contains(group.groupId) == false && group.groupId != "" {
                        group_ids.insert(group.groupId)
                    }
                })
                sync.leave()
            }
        }, withCancel: { (err) in
            print("Failed to fetch posts:", err)
            self.loadingScreenView.isHidden = true
            self.collectionView?.refreshControl?.endRefreshing()
        })
        // run below when all the group ids have been collected
        sync.notify(queue: .main) {
            let lower_sync = DispatchGroup()
            group_ids.forEach({ (groupId) in
                lower_sync.enter()
                // could change this function to have only posts but maybe this could be useful in the future
                Database.database().fetchAllGroupPosts(groupId: groupId, completion: { (countAndPosts) in
                    // this section has gotten all the groupPosts within each group
                    if countAndPosts.count > 0 {
                        TableViewHelper.EmptyMessage(message: "", viewController: self)
                        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                            self.collectionView?.backgroundView?.alpha = 1
                        }, completion: nil)


                        let posts = countAndPosts[1] as! [GroupPost]
                        let sortedPosts = posts.sorted(by: { (p1, p2) -> Bool in
                            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                        })
                        if sortedPosts.count > 0 {      // don't complete if no posts (don't add it to feed)
                            let groupId = sortedPosts[0].group.groupId
                            tempGroupPosts2D.append(sortedPosts)

                            // set the members of the group
                            lower_sync.enter()
                            Database.database().fetchGroupMembers(groupId: groupId, completion: { (users) in
                                lower_sync.leave()
                                self.groupMembers[groupId] =  users
                            }) { (_) in }

                            // go through each post
                            posts.forEach({ (groupPost) in
                                // note that all these fetches are async of each other and are concurent so any of them could occur first

                                // get the first comment of the post and set the number of comments
                                lower_sync.enter()
                                Database.database().fetchFirstCommentForPost(withId: groupPost.id, completion: { (comments) in
                                    if comments.count > 0 {
                                        let existingPostsForFirstCommentInGroup = self.groupPostsFirstCommentDict[groupId]
                                        if existingPostsForFirstCommentInGroup == nil {
                                            self.groupPostsFirstCommentDict[groupId] = [groupPost.id: comments[0]]
                                        }
                                        else {
                                            self.groupPostsFirstCommentDict[groupId]![groupPost.id] = comments[0] // it is def not nil so safe to unwrap
                                        }
                                    }
                                    
                                    Database.database().numberOfCommentsForPost(postId: groupPost.id) { (commentsCount) in
                                        let existingPostsForNumCommentInGroup = self.groupPostsNumCommentsDict[groupId]
                                        if existingPostsForNumCommentInGroup == nil {
                                            self.groupPostsNumCommentsDict[groupId] = [groupPost.id: commentsCount]
                                        }
                                        else {
                                            self.groupPostsNumCommentsDict[groupId]![groupPost.id] = commentsCount // it is def not nil so safe to unwrap
                                        }
                                        lower_sync.leave()
                                    }
                                }) { (err) in }

                                // the following is only if the user is in a gorup
                                lower_sync.enter()
                                Database.database().isInGroup(groupId: groupPost.group.groupId, completion: { (inGroup) in
                                    lower_sync.leave()
                                    if inGroup {
                                        // get the viewers
                                        lower_sync.enter()
                                        Database.database().fetchPostVisibleViewers(postId: groupPost.id, completion: { (viewer_ids) in
                                            if viewer_ids.count > 0 {
                                                var viewers = [User]()
                                                let viewersSync = DispatchGroup()
                                                viewer_ids.forEach({ (viewer_id) in
                                                    viewersSync.enter()
                                                    Database.database().userExists(withUID: viewer_id, completion: { (exists) in
                                                        if exists{
                                                            Database.database().fetchUser(withUID: viewer_id, completion: { (user) in
                                                                viewers.append(user)
                                                                viewersSync.leave()
                                                            })
                                                        }
                                                        else {
                                                            viewersSync.leave()
                                                        }
                                                    })
                                                })
                                                viewersSync.notify(queue: .main) {
                                                    let existingPostsForVisibleViewersInGroup = self.groupPostsVisibleViewersDict[groupId]
                                                    if existingPostsForVisibleViewersInGroup == nil {
                                                        self.groupPostsVisibleViewersDict[groupId] = [groupPost.id: viewers]
                                                    }
                                                    else {
                                                        self.groupPostsVisibleViewersDict[groupId]![groupPost.id] = viewers
                                                    }
                                                    lower_sync.leave()
                                                }
                                            }
                                            else {
                                                lower_sync.leave()
                                            }
                                        }) { (err) in return}

                                        // get the post total viewers
                                        lower_sync.enter()
                                        Database.database().fetchNumPostViewers(postId: groupPost.id, completion: {(views_count) in
                                            let existingPostsForTotalViewersInGroup = self.groupPostsTotalViewersDict[groupId]
                                            if existingPostsForTotalViewersInGroup == nil {
                                                self.groupPostsTotalViewersDict[groupId] = [groupPost.id: views_count]
                                            }
                                            else {
                                                self.groupPostsTotalViewersDict[groupId]![groupPost.id] = views_count
                                            }
                                            lower_sync.leave()

                                        }) { (err) in return }
                                    }
                                }) { (err) in return }
                            })
                        }
                    }
                    else {
                        let seconds = 1.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                            if self.groupPosts2D.count == 0 {
//                                TableViewHelper.EmptyMessage(message: "No posts to show\nClick the plus to post to a group", viewController: self)
//                                self.newGroupButton.isHidden = false
//                                self.goButton.isHidden = true
//                                self.inviteButton.isHidden = false
//                                self.welcomeLabel.isHidden = false
//                                self.logoImageView.isHidden = false
                                UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                                    self.collectionView?.backgroundView?.alpha = 1
                                }, completion: nil)
                            }
                        }
                    }
                    lower_sync.leave()
                }, withCancel: { (err) in
                    self.loadingScreenView.isHidden = true
                    self.collectionView?.refreshControl?.endRefreshing()
                })
            })
            lower_sync.notify(queue: .main) {
                tempGroupPosts2D.sort(by: { (p1, p2) -> Bool in
                    return p1[0].creationDate.compare(p2[0].creationDate) == .orderedDescending
                })

                if tempGroupPosts2D.count < batch_size {
                    self.fetchedAllGroups = true
                }
                
                self.loadingScreenView.isHidden = true
                self.activityIndicatorView.isHidden = true
                
                self.groupPosts2D += Array(tempGroupPosts2D.suffix(batch_size))
                self.usingCachedData = false

                // add refresh capability only after posts have been loaded
                let refreshControl = UIRefreshControl()
                refreshControl.addTarget(self, action: #selector(self.handleRefresh), for: .valueChanged)
                self.collectionView?.refreshControl = refreshControl
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    self.collectionView?.refreshControl?.endRefreshing()
                    self.collectionView.scrollToNearestVisibleCollectionViewCell()
                }

//                if self.isFirstView && tempGroupPosts2D.count > 0 {
                if self.isFirstView {
                    self.newGroupButton.isHidden = true
                    self.inviteButton.isHidden = true
                    self.goButton.isHidden = false
                    self.welcomeLabel.isHidden = false
                    self.logoImageView.isHidden = false
                    self.collectionView.isHidden = true
                    self.createGroupIconButton.isHidden = true
                }
                else if tempGroupPosts2D.count > 0 {
                    self.activityIndicatorView.isHidden = true
                    self.newGroupButton.isHidden = true
                    self.goButton.isHidden = true
                    self.inviteButton.isHidden = true
                    self.welcomeLabel.isHidden = true
                    self.noSubscriptionsLabel.isHidden = true
                    self.logoImageView.isHidden = true
                    self.collectionView.isHidden = false
                    self.createGroupIconButton.isHidden = false
                }
                else if self.groupPosts2D.count == 0 {
                    self.newGroupButton.isHidden = false
                    self.goButton.isHidden = true
                    self.inviteButton.isHidden = false
                    self.noSubscriptionsLabel.isHidden = false
                    self.welcomeLabel.isHidden = true
                    self.logoImageView.isHidden = false
                    self.collectionView.isHidden = true
                    self.createGroupIconButton.isHidden = true
                }
            }
        }
    }

    func configureNavBar() {
        self.navigationController?.navigationBar.height(CGFloat(0))
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = .clear
    }
    
    // to be used when transitioning back to ProfileFeedController
    func configureNavBarForTransition(){
        self.navigationController?.navigationBar.height(CGFloat(0))
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if groupPosts2D.count == 0 {
            return 0
        }
        return groupPosts2D.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let feedCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! FeedGroupCell
        if indexPath.row == groupPosts2D.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyFeedPostCell.cellId, for: indexPath) as! EmptyFeedPostCell
            cell.fetchedAllGroups = fetchedAllGroups
            return cell
        }
        else if indexPath.row < groupPosts2D.count {
            let posts = groupPosts2D[indexPath.row]
            let groupId = posts[0].group.groupId
            feedCell.groupPosts = posts
            feedCell.usingCachedData = self.usingCachedData
            feedCell.groupMembers = groupMembers[groupId]
            feedCell.groupPostsTotalViewers = groupPostsTotalViewersDict[groupId]
            feedCell.groupPostsViewers = groupPostsVisibleViewersDict[groupId]
            feedCell.groupPostsFirstComment = groupPostsFirstCommentDict[groupId]
            feedCell.groupPostsNumComments = groupPostsNumCommentsDict[groupId]
            feedCell.delegate = self
            feedCell.tag = indexPath.row
//            feedCell.isScrollingVertically = isScrolling
            feedCell.maxDistanceScrolled = CGFloat(0)
            feedCell.numPicsScrolled = 1
        }
        return feedCell
    }

    @objc private func loadFromNoInternet() {
        self.loadingScreenView.isHidden = false
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { timer in
            self.loadingScreenView.isHidden = true
            if Reachability.isConnectedToNetwork(){
                self.reloadButton.isHidden = true
                self.noInternetLabel.isHidden = true
                self.noInternetBackground.isHidden = true
                self.loadGroupPosts()
            } else{
                self.reloadButton.isHidden = false
                self.noInternetLabel.isHidden = false
                self.noInternetBackground.isHidden = false
            }
        })
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                let visible_cell = cell as! FeedGroupCell
                visible_cell.pauseVisibleVideo()
                
                let original_pos = scrollView.contentOffset.y
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { timer in
                    let new_pos = scrollView.contentOffset.y
                    if abs(new_pos - original_pos) > 100 {
                        visible_cell.handleCloseFullscreen()
                        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
                    }
                })
            }
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let endPos = scrollView.contentOffset.y
        self.stoppedScrolling(endPos: endPos)
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let endPos = scrollView.contentOffset.y
        if !decelerate {
            self.stoppedScrolling(endPos: endPos)
        }
    }

    private var maxDistanceScrolled = CGFloat(0)
    private var numGroupsScrolled = 1
    func stoppedScrolling(endPos: CGFloat) {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
            if let indexPath = self.collectionView.indexPathsForVisibleItems.last {
                if indexPath.row == self.numGroupsInFeed {
                    self.numGroupsInFeed += 5
                    self.loadGroupPosts()
                }
            }
            
            // check if fullscreen and set tabBar color accordingly
            self.collectionView.visibleCells.forEach { cell in
                if cell is FeedGroupCell {
                    let visible_cell = cell as! FeedGroupCell
                    
                    if visible_cell.isFullScreen {
                        self.createGroupIconButton.isHidden = true
                        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
//                        self.statusBarHidden = true
                    }
                    else {
                        self.createGroupIconButton.isHidden = false
                        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
//                        self.statusBarHidden = false
                    }
                }
                else {
                    self.createGroupIconButton.isHidden = false
                    NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
//                    self.statusBarHidden = false
                }
            }
        })
    }
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                (cell as! FeedGroupCell).pauseVisibleVideo()
            }
        }
        return true
    }
    
    func didTapComment(groupPost: GroupPost) {
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.groupPost = groupPost
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func didTapGroup(group: Group) {
        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        groupProfileController.group = group
        groupProfileController.modalPresentationCapturesStatusBarAppearance = true
        navigationController?.pushViewController(groupProfileController, animated: true)
    }
    
    func didTapOptions(groupPost: GroupPost) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if let reportAction = self.reportAction(forPost: groupPost) {
            alertController.addAction(reportAction)
        }
        
        Database.database().isInGroup(groupId: groupPost.group.groupId, completion: { (inGroup) in
            if inGroup {
                if let deleteAction = self.deleteAction(forPost: groupPost) {
                    alertController.addAction(deleteAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            else{
                if let unsubscribeAction = self.unsubscribeAction(forPost: groupPost, uid: currentLoggedInUserId) {
                    alertController.addAction(unsubscribeAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }) { (err) in
            return
        }
    }
    
    private func deleteAction(forPost groupPost: GroupPost) -> UIAlertAction? {
        let action = UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
            
            let alert = UIAlertController(title: "Delete Post?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (_) in
                
                Database.database().deleteGroupPost(groupId: groupPost.group.groupId, postId: groupPost.id) { (_) in
                    NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }
    
    private func unsubscribeAction(forPost groupPost: GroupPost, uid: String) -> UIAlertAction? {
        let action = UIAlertAction(title: "Unsubscribe", style: .destructive, handler: { (_) in
            let alert = UIAlertController(title: "Unsubscribe?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Unsubscribe", style: .default, handler: { (_) in
                Database.database().removeGroupFromUserFollowing(withUID: uid, groupId: groupPost.group.groupId) { (err) in
                    NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }
    
    private func reportAction(forPost groupPost: GroupPost) -> UIAlertAction? {
        let action = UIAlertAction(title: "Report", style: .destructive, handler: { (_) in
            
            let alert = UIAlertController(title: "Report Post?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Report", style: .default, handler: { (_) in
                Database.database().reportPost(withId: groupPost.id, groupId: groupPost.group.groupId) { (err) in
                    if err != nil {
                        return
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }
    
    func didSelectUser(selectedUser: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = selectedUser
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func showMoreMembers(group: Group) {
        
    }
    
    func didChangeViewType(isFullscreen: Bool) {
        if isFullscreen {
            print("---------")
            print("create group icon is: ", createGroupIconButton.isHidden)
            self.createGroupIconButton.isHidden = true
            print("create group icon is: ", createGroupIconButton.isHidden)
//            self.statusBarHidden = true
        }
        else {
            self.createGroupIconButton.isHidden = false
//            self.statusBarHidden = false
        }
    }
    
    func didView(groupPost: GroupPost) {
        Database.database().addToViewedPosts(postId: groupPost.id, completion: { _ in })
    }
    
    func showViewers(viewers: [User], viewsCount: Int) {
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                (cell as! FeedGroupCell).pauseVisibleVideo()
            }
        }
        
        let viewersController = ViewersController()
        viewersController.viewers = viewers
        viewersController.viewsCount = viewsCount
        viewersController.delegate = self
        let navController = UINavigationController(rootViewController: viewersController)
        navController.modalPresentationStyle = .popover
        self.present(navController, animated: true, completion: nil)
    }
    
    func requestPlay(for_lower cell1: FeedPostCell, for_upper cell2: MyCell) {
        
    }

    func didTapUser(user: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = user
        userProfileController.modalPresentationCapturesStatusBarAppearance = true
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    @objc internal func handleShowNewGroup() {
        let createGroupController = CreateGroupController()
        createGroupController.delegate = self
        createGroupController.delegateForInvite = self
        let navController = UINavigationController(rootViewController: createGroupController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true, completion: nil)
    }
    
    @objc internal func handleShowInviteCode() {
        let introCodeController = IntroCodeController()
        let nacController = UINavigationController(rootViewController: introCodeController)
        present(nacController, animated: true, completion: nil)
    }
    
    @objc internal func handleFirstGo() {
        // uncomment when done laying out
        self.isFirstView = false
        if let hasOpenedApp = try? JSONEncoder().encode(true) {
            UserDefaults.standard.set(hasOpenedApp, forKey: "hasOpenedApp")
        }

        self.newGroupButton.isHidden = true
        self.goButton.isHidden = true
        self.inviteButton.isHidden = true
        self.welcomeLabel.isHidden = true
        self.logoImageView.isHidden = true
        
        self.verticalGifView.isHidden = false
        self.animationsTitleLabel.isHidden = false
        self.animationsButton.isHidden = false
        self.animationsLabel.isHidden = false
        
//        self.activityIndicatorView.isHidden = false
//        self.handleRefresh()
    }
    
    @objc internal func showSecondAnim() {
        self.animationsButton.isHidden = true
        self.animationsButton2.isHidden = false
        self.horizontalGifView.isHidden = false
        self.verticalGifView.isHidden = true
        
        self.animationsLabel.attributedText = NSMutableAttributedString(string: "Swipe left to see all of a group’s posts.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)])
    }
    
    @objc internal func endIntro() {
        self.animationsButton2.isHidden = true
        self.horizontalGifView.isHidden = true
        self.animationsTitleLabel.isHidden = true
        self.animationsButton.isHidden = true
        self.animationsLabel.isHidden = true
        
        self.activityIndicatorView.isHidden = false
        self.handleRefresh()
    }
    
    func shouldOpenGroup(groupId: String) {
        Database.database().groupExists(groupId: groupId, completion: { (exists) in
            if exists {
                Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                    self.handleRefresh()
                    
                    let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
                    groupProfileController.group = group
                    groupProfileController.modalPresentationCapturesStatusBarAppearance = true
                    self.navigationController?.pushViewController(groupProfileController, animated: true)
                })
            }
            else {
                return
            }
        })
    }
}

extension ProfileFeedController: Zoomy.Delegate {
    
    func didBeginPresentingOverlay(for imageView: Zoomable) {
        NotificationCenter.default.post(name: NSNotification.Name("tabBarDisappear"), object: nil)
        collectionView.isScrollEnabled = false
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                (cell as! FeedGroupCell).collectionView.isScrollEnabled = false
            }
        }
    }
    
    func didEndPresentingOverlay(for imageView: Zoomable) {
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
        collectionView.isScrollEnabled = true
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                (cell as! FeedGroupCell).collectionView.isScrollEnabled = true
            }
        }
    }
}
