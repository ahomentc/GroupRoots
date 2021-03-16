import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class FeedController: UICollectionViewController, FeedPostCellDelegate, UICollectionViewDelegateFlowLayout, ViewersControllerDelegate {
    func requestZoomCapability(for cell: FeedPostCell) {
//        addZoombehavior(for: cell.photoImageView, settings: .instaZoomSettings)
    }
    
    
    override var prefersStatusBarHidden: Bool { return true }
//    override var prefersStatusBarHidden: Bool { return false }
    
    // 2d representation of the dict, same as dict but with no values
    // later, just use the dict but convert it to this after all data is loaded in
    var groupPosts2D = [[GroupPost]]()
    var groupMembers = [String: [User]]()
    var groupPostsTotalViewersDict = [String: [String: Int]]()          // Dict inside dict. First key is the groupId. Within the value is another key with postId
    var groupPostsVisibleViewersDict = [String: [String: [User]]]()     //    same   ^
    var groupPostsFirstCommentDict = [String: [String: Comment]]()      //    same   |
    var groupPostsNumCommentsDict = [String: [String: Int]]()           // -- same --|
    var isScrolling = false
    var numGroupsInFeed = 3
    var disableVideo = false
    var usingCachedData = true
    
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
        let attributedText = NSMutableAttributedString(string: "No Internet Connection", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)])
        label.attributedText = attributedText
        return label
    }()
    
    private let noInternetBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.layer.zPosition = 3
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 10
        view.isHidden = true
        return view
    }()
    
    private lazy var reloadButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(loadFromNoInternet), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitle("Retry", for: .normal)
        return button
    }()

    func showEmptyStateViewIfNeeded() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().numberOfSubscriptionsForUser(withUID: currentLoggedInUserId) { (followingCount) in
            Database.database().numberOfGroupsForUser(withUID: currentLoggedInUserId, completion: { (groupsCount) in
                if followingCount == 0 && groupsCount == 0 {
                    TableViewHelper.EmptyMessage(message: "Welcome to GroupRoots!\nFollow friends to view group posts", viewController: self)
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
        self.disableVideo = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
        self.configureNavBar()
        self.disableVideo = false
        
        collectionView.visibleCells.forEach { cell in
            if cell is MyCell {
                (cell as! MyCell).pauseVisibleVideo()
            }
        }
        
        self.collectionView.scrollToNearestVisibleCollectionViewCell()
    }
    
    func configureNavBar(){
        self.navigationController?.navigationBar.height(CGFloat(0))
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = .clear
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor : UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        loadingScreenView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        loadingScreenView.layer.cornerRadius = 0
        loadingScreenView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        loadingScreenView.image =  #imageLiteral(resourceName: "Splash3")
        self.view.insertSubview(loadingScreenView, at: 5)
        
        reloadButton.frame = CGRect(x: UIScreen.main.bounds.width/2-50, y: UIScreen.main.bounds.height/2, width: 100, height: 50)
        reloadButton.layer.cornerRadius = 18
        self.view.insertSubview(reloadButton, at: 4)
        
        noInternetLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height/2-50, width: UIScreen.main.bounds.width, height: 20)
        self.view.insertSubview(noInternetLabel, at: 4)
        
        noInternetBackground.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-100, width: 300, height: 200)
        self.view.insertSubview(noInternetBackground, at: 3)
        
        collectionView?.register(MyCell.self, forCellWithReuseIdentifier: "cellId")
        collectionView?.register(EmptyFeedPostCell.self, forCellWithReuseIdentifier: EmptyFeedPostCell.cellId)
        collectionView?.allowsSelection = false
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.isPagingEnabled = true
        collectionView?.delegate = self;
        collectionView?.dataSource = self;
        
        
        // what happens here if there's been paging... more specifically, what happens when refresh and had paging occur?
        NotificationCenter.default.addObserver(self, selector: #selector(delayedRefresh), name: NSNotification.Name.updateHomeFeed, object: nil)
        
        self.view.backgroundColor = UIColor.black
        
        // get data from cache if there
        if let groupPosts2DRetrieved = UserDefaults.standard.object(forKey: "groupPosts2D") as? Data {
            guard let groupPosts2D = try? JSONDecoder().decode([[GroupPost]].self, from: groupPosts2DRetrieved) else {
                print("Error: Couldn't decode data into Blog")
                return
            }
            self.groupPosts2D = groupPosts2D
        }
        
        if let groupMembersRetrieved = UserDefaults.standard.object(forKey: "groupMembers") as? Data {
            guard let groupMembers = try? JSONDecoder().decode([String: [User]].self, from: groupMembersRetrieved) else {
                print("Error: Couldn't decode data into Blog")
                return
            }
            self.groupMembers = groupMembers
        }
        
        if let groupPostsTotalViewersDictRetrieved = UserDefaults.standard.object(forKey: "groupPostsTotalViewersDict") as? Data {
            guard let groupPostsTotalViewersDict = try? JSONDecoder().decode([String: [String: Int]].self, from: groupPostsTotalViewersDictRetrieved) else {
                print("Error: Couldn't decode data into Blog")
                return
            }
            self.groupPostsTotalViewersDict = groupPostsTotalViewersDict
        }
        
        if let groupPostsVisibleViewersDictRetrieved = UserDefaults.standard.object(forKey: "groupPostsVisibleViewersDict") as? Data {
            guard let groupPostsVisibleViewersDict = try? JSONDecoder().decode([String: [String: [User]]].self, from: groupPostsVisibleViewersDictRetrieved) else {
                print("Error: Couldn't decode data into Blog")
                return
            }
            self.groupPostsVisibleViewersDict = groupPostsVisibleViewersDict
        }
        
        if let groupPostsFirstCommentDictRetrieved = UserDefaults.standard.object(forKey: "groupPostsFirstCommentDict") as? Data {
            guard let groupPostsFirstCommentDict = try? JSONDecoder().decode([String: [String: Comment]].self, from: groupPostsFirstCommentDictRetrieved) else {
                print("Error: Couldn't decode data into Blog")
                return
            }
            self.groupPostsFirstCommentDict = groupPostsFirstCommentDict
        }
        
        if let groupPostsNumCommentsDictRetrieved = UserDefaults.standard.object(forKey: "groupPostsNumCommentsDict") as? Data {
            guard let groupPostsNumCommentsDict = try? JSONDecoder().decode([String: [String: Int]].self, from: groupPostsNumCommentsDictRetrieved) else {
                print("Error: Couldn't decode data into Blog")
                return
            }
            self.groupPostsNumCommentsDict = groupPostsNumCommentsDict
        }
        
        //        fetchAllPosts()
        fetchAllFreshGroupPosts()
        configureNavigationBar()
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: { timer in
            self.loadingScreenView.isHidden = true
        })
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        PushNotificationManager().updatePushTokenIfNeeded()
        
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
            self.reloadButton.isHidden = true
            self.noInternetLabel.isHidden = true
            self.noInternetBackground.isHidden = true
        }else{
            print("Internet Connection not Available!")
            self.reloadButton.isHidden = false
            self.noInternetLabel.isHidden = false
            self.noInternetBackground.isHidden = false
        }
    }
    
    @objc private func delayedRefresh() {
        // call refresh after 2 seconds
        let seconds = 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.handleRefresh()
        }
    }
    
    @objc private func handleRefresh() {
        // stop video of visible cell
        collectionView.visibleCells.forEach { cell in
            if cell is MyCell {
                // TODO: write logic to stop the video before it begins scrolling
                (cell as! MyCell).pauseVisibleVideo()
                (cell as! MyCell).isScrollingVertically = isScrolling
            }
        }
        fetchAllFreshGroupPosts()
    }

    private func configureNavigationBar() {
        self.configureNavBar()
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor : UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
    }

    // adds to groupPosts with the fetched
    private func fetchAllPosts() {
        showEmptyStateViewIfNeeded()
        fetchGroupPosts()
    }
    
    // replaces groupPosts with the fetched
    private func fetchAllFreshGroupPosts(){
        showEmptyStateViewIfNeeded()
        fetchFreshGroupPosts()
    }
    
    private func fetchFreshGroupPosts() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        collectionView?.refreshControl?.beginRefreshing()
        var group_ids = Set<String>()
        var tempGroupPosts2D = [[GroupPost]]()
        // get all the userIds of the people user is following
        let sync = DispatchGroup()
        
        // we don't need to show posts of groups that are member of but not following.
        // They auto follow it so they'd have to unfollow to not be in following, which means they
        // don't want to see the posts
        sync.enter()
        Database.database().fetchGroupsFollowingDynamic(withUID: currentLoggedInUserId, toLast: numGroupsInFeed, completion: { (groups) in
            self.reloadButton.isHidden = true
            self.noInternetLabel.isHidden = true
            self.noInternetBackground.isHidden = true
            
            groups.forEach({ (group) in
                if group_ids.contains(group.groupId) == false && group.groupId != "" {
                    group_ids.insert(group.groupId)
                }
            })
            sync.leave()
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
                                    let existingPostsForNumCommentInGroup = self.groupPostsNumCommentsDict[groupId]
                                    if existingPostsForNumCommentInGroup == nil {
                                        self.groupPostsNumCommentsDict[groupId] = [groupPost.id: comments.count]
                                    }
                                    else {
                                        self.groupPostsNumCommentsDict[groupId]![groupPost.id] = comments.count // it is def not nil so safe to unwrap
                                    }
                                    lower_sync.leave()
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
                
                if tempGroupPosts2D.count == 0 {
                    TableViewHelper.EmptyMessage(message: "No posts to show\nClick the plus to post to a group", viewController: self)
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                        self.collectionView?.backgroundView?.alpha = 1
                    }, completion: nil)
                }
                
                self.groupPosts2D = tempGroupPosts2D
//                    self.groupPosts2D += Array(tempGroupPosts2D.suffix(5))
                self.usingCachedData = false
                
                // save all in storage
                if let groupPosts2DEncodedData = try? JSONEncoder().encode(self.groupPosts2D) {
                    UserDefaults.standard.set(groupPosts2DEncodedData, forKey: "groupPosts2D")
                }
                
                if let groupMembersEncodedData = try? JSONEncoder().encode(self.groupMembers) {
                    UserDefaults.standard.set(groupMembersEncodedData, forKey: "groupMembers")
                }
                
                if let groupPostsTotalViewersDictEncodedData = try? JSONEncoder().encode(self.groupPostsTotalViewersDict) {
                    UserDefaults.standard.set(groupPostsTotalViewersDictEncodedData, forKey: "groupPostsTotalViewersDict")
                }
                
                if let groupPostsVisibleViewersDictEncodedData = try? JSONEncoder().encode(self.groupPostsVisibleViewersDict) {
                    UserDefaults.standard.set(groupPostsVisibleViewersDictEncodedData, forKey: "groupPostsVisibleViewersDict")
                }
                
                if let groupPostsFirstCommentDictEncodedData = try? JSONEncoder().encode(self.groupPostsFirstCommentDict) {
                    UserDefaults.standard.set(groupPostsFirstCommentDictEncodedData, forKey: "groupPostsFirstCommentDict")
                }
                
                if let groupPostsNumCommentsDictEncodedData = try? JSONEncoder().encode(self.groupPostsNumCommentsDict) {
                    UserDefaults.standard.set(groupPostsNumCommentsDictEncodedData, forKey: "groupPostsNumCommentsDict")
                }
                                
                self.loadingScreenView.isHidden = true
            
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }
    }
        
    // For now, only public groups
    // When have private groups, add a check to see if have access
    // For now, fetch all posts of all groups of all following
    // In the future, will only show some of the posts, the ones from groups that have
    //  the highest score. Score will be determined by how many of the people you're following
    //  are in the group, and how many people you're in a group with are in the group.

    private func fetchGroupPosts() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        collectionView?.refreshControl?.beginRefreshing()
        var group_ids = Set<String>()
//        self.groupPosts2D = [[GroupPost]]()
        var tempGroupPosts2D = [[GroupPost]]()
        // get all the userIds of the people user is following
        let sync = DispatchGroup()
        
        // we don't need to show posts of groups that are member of but not following.
        // They auto follow it so they'd have to unfollow to not be in following, which means they
        // don't want to see the posts
        sync.enter()
        Database.database().fetchGroupsFollowingDynamic(withUID: currentLoggedInUserId, toLast: numGroupsInFeed, completion: { (groups) in
//        Database.database().fetchGroupsFollowingDyanmicLast(withUID: currentLoggedInUserId, toLast: numGroupsInFeed, groupSize: 5, completion: { (groups) in
            self.reloadButton.isHidden = true
            self.noInternetLabel.isHidden = true
            self.noInternetBackground.isHidden = true
            
            groups.forEach({ (group) in
                if group_ids.contains(group.groupId) == false && group.groupId != "" {
                    group_ids.insert(group.groupId)
                }
            })
            sync.leave()
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
                                    let existingPostsForNumCommentInGroup = self.groupPostsNumCommentsDict[groupId]
                                    if existingPostsForNumCommentInGroup == nil {
                                        self.groupPostsNumCommentsDict[groupId] = [groupPost.id: comments.count]
                                    }
                                    else {
                                        self.groupPostsNumCommentsDict[groupId]![groupPost.id] = comments.count // it is def not nil so safe to unwrap
                                    }
                                    lower_sync.leave()
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
                                TableViewHelper.EmptyMessage(message: "No posts to show\nClick the plus to post to a group", viewController: self)
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
//                self.groupPosts2D = tempGroupPosts2D
                self.groupPosts2D += Array(tempGroupPosts2D.suffix(3))
                self.usingCachedData = false
                
                // save all in storage
                if let groupPosts2DEncodedData = try? JSONEncoder().encode(self.groupPosts2D) {
                    UserDefaults.standard.set(groupPosts2DEncodedData, forKey: "groupPosts2D")
                }
                
                if let groupMembersEncodedData = try? JSONEncoder().encode(self.groupMembers) {
                    UserDefaults.standard.set(groupMembersEncodedData, forKey: "groupMembers")
                }
                
                if let groupPostsTotalViewersDictEncodedData = try? JSONEncoder().encode(self.groupPostsTotalViewersDict) {
                    UserDefaults.standard.set(groupPostsTotalViewersDictEncodedData, forKey: "groupPostsTotalViewersDict")
                }
                
                if let groupPostsVisibleViewersDictEncodedData = try? JSONEncoder().encode(self.groupPostsVisibleViewersDict) {
                    UserDefaults.standard.set(groupPostsVisibleViewersDictEncodedData, forKey: "groupPostsVisibleViewersDict")
                }
                
                if let groupPostsFirstCommentDictEncodedData = try? JSONEncoder().encode(self.groupPostsFirstCommentDict) {
                    UserDefaults.standard.set(groupPostsFirstCommentDictEncodedData, forKey: "groupPostsFirstCommentDict")
                }
                
                if let groupPostsNumCommentsDictEncodedData = try? JSONEncoder().encode(self.groupPostsNumCommentsDict) {
                    UserDefaults.standard.set(groupPostsNumCommentsDictEncodedData, forKey: "groupPostsNumCommentsDict")
                }
                                
                self.loadingScreenView.isHidden = true
            
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
                
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if groupPosts2D.count == 0 {
            return 0
        }
        return groupPosts2D.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! MyCell
        if indexPath.row == groupPosts2D.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyFeedPostCell.cellId, for: indexPath) as! EmptyFeedPostCell
            return cell
        }
        else if indexPath.row < groupPosts2D.count {
            let posts = groupPosts2D[indexPath.row]
            let groupId = posts[0].group.groupId
            myCell.groupMembers = []
            myCell.header.groupMembers = []
            myCell.groupPosts = posts
            myCell.usingCachedData = self.usingCachedData
            myCell.groupMembers = groupMembers[groupId]
            myCell.groupPostsTotalViewers = groupPostsTotalViewersDict[groupId]
            myCell.groupPostsViewers = groupPostsVisibleViewersDict[groupId]
            myCell.groupPostsFirstComment = groupPostsFirstCommentDict[groupId]
            myCell.groupPostsNumComments = groupPostsNumCommentsDict[groupId]
            myCell.feedController = self
            myCell.delegate = self
            myCell.tag = indexPath.row
            myCell.isScrollingVertically = isScrolling
            myCell.maxDistanceScrolled = CGFloat(0)
            myCell.numPicsScrolled = 1
        }
        return myCell
    }
    
    @objc private func loadFromNoInternet() {
        self.loadingScreenView.isHidden = false
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { timer in
            self.loadingScreenView.isHidden = true
            if Reachability.isConnectedToNetwork(){
                self.reloadButton.isHidden = true
                self.noInternetLabel.isHidden = true
                self.noInternetBackground.isHidden = true
                self.fetchAllFreshGroupPosts()
            }else{
                self.reloadButton.isHidden = false
                self.noInternetLabel.isHidden = false
                self.noInternetBackground.isHidden = false
            }
        })
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        collectionView.visibleCells.forEach { cell in
            if cell is MyCell {
                // TODO: write logic to stop the video before it begins scrolling
                (cell as! MyCell).pauseVisibleVideo()
                (cell as! MyCell).isScrollingVertically = isScrolling
            }
        }
        isScrolling = true
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let endPos = scrollView.contentOffset.y
        self.stoppedScrolling(endPos: endPos)
        
//        if let indexPath = self.collectionView.indexPathsForVisibleItems.first {
//            print("is visible: ", indexPath.row)
//            if (indexPath.row + 1) % 10 == 0 {
//                numGroupsInFeed += 10
//                fetchGroupPosts()
//            }
//            if (indexPath.row + 1) ==  numGroupsInFeed {
//                print("adding 5")
//                numGroupsInFeed += 5
//                fetchGroupPosts()
//            }
//        }
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
        isScrolling = false
        collectionView.visibleCells.forEach { cell in
            if cell is MyCell {
                (cell as! MyCell).isScrollingVertically = isScrolling
            }
        }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
            if let indexPath = self.collectionView.indexPathsForVisibleItems.last {
                if indexPath.row ==  self.numGroupsInFeed {
                    self.numGroupsInFeed += 3
                    self.fetchAllFreshGroupPosts()
                }
            }
        })
    }
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        collectionView.visibleCells.forEach { cell in
            // TODO: write logic to stop the video before it begins scrolling
            if cell is MyCell {
                (cell as! MyCell).pauseVisibleVideo()
                (cell as! MyCell).isScrollingVertically = isScrolling
            }
        }
        return true
    }

    //MARK: - FeedPostCellDelegate

    func didTapComment(groupPost: GroupPost) {
        let commentsController = CommentsController()
        commentsController.groupPost = groupPost
        navigationController?.pushViewController(commentsController, animated: true)
        
//        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
//        commentsController.groupPost = groupPost
//        let navController = UINavigationController(rootViewController: commentsController)
//        self.present(navController, animated: true, completion: nil)
    }

    func didTapGroup(group: Group) {
        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        groupProfileController.group = group
        groupProfileController.modalPresentationCapturesStatusBarAppearance = true
        navigationController?.pushViewController(groupProfileController, animated: true)
    }
    
    func didTapUser(user: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = user
        userProfileController.modalPresentationCapturesStatusBarAppearance = true
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didView(groupPost: GroupPost) {
        Database.database().addToViewedPosts(postId: groupPost.id, completion: { _ in
        })
    }
    
    func showViewers(viewers: [User], viewsCount: Int) {
        collectionView.visibleCells.forEach { cell in
            if cell is MyCell {
                (cell as! MyCell).pauseVisibleVideo()
            }
        }
        
        let viewersController = ViewersController()
        viewersController.viewers = viewers
        viewersController.viewsCount = viewsCount
        viewersController.delegate = self
        let navController = UINavigationController(rootViewController: viewersController)
        self.present(navController, animated: true, completion: nil)
        
    }

    func didTapOptions(groupPost: GroupPost) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
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
//                    if let postIndex = self.groupPosts.index(where: {$0.id == groupPost.id}) {
//                        self.groupPosts.remove(at: postIndex)
//                        self.collectionView?.reloadData()
//                        self.showEmptyStateViewIfNeeded()
//                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }
    
    private func unsubscribeAction(forPost groupPost: GroupPost, uid: String) -> UIAlertAction? {
        let action = UIAlertAction(title: "Unfollow", style: .destructive, handler: { (_) in
            
            let alert = UIAlertController(title: "Unfollow?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Unfollow", style: .default, handler: { (_) in
                Database.database().removeGroupFromUserFollowing(withUID: uid, groupId: groupPost.group.groupId) { (err) in
                    NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
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
    
    func showMoreMembers(group: Group){
        let membersController = MembersController(collectionViewLayout: UICollectionViewFlowLayout())
        membersController.group = group
        membersController.isMembersView = true
        membersController.isInGroup = false
        self.navigationController?.pushViewController(membersController, animated: true)
    }
    
    func requestPlay(for_lower cell1: FeedPostCell, for_upper cell2: MyCell) {
        if !isScrolling && !disableVideo && !usingCachedData {
            // check to see if visible too
            collectionView.visibleCells.forEach { cell_visible in  // check if cell is still visible
                if cell_visible == cell2 {
                    cell1.player.playFromCurrentTime()
                }
            }
        }
    }
}

extension UIColor {

    /// Converts this `UIColor` instance to a 1x1 `UIImage` instance and returns it.
    ///
    /// - Returns: `self` as a 1x1 `UIImage`.
    func as1ptImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 2))
        setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 2))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}


class TableViewHelper {

    class func EmptyMessage(message:String, viewController:UICollectionViewController) {
        let rect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        let messageLabel = UILabel(frame: rect)
        messageLabel.text = message
        messageLabel.textColor = UIColor.init(white: 0.3, alpha: 1)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 18.0)
        messageLabel.sizeToFit()

        viewController.collectionView.backgroundView = messageLabel;
    }
}

extension UICollectionView {
    func scrollToNearestVisibleCollectionViewCell() {
        self.decelerationRate = UIScrollView.DecelerationRate.fast
        let visibleCenterPositionOfScrollView = Float(self.contentOffset.x + (self.bounds.size.width / 2))
        var closestCellIndex = -1
        var closestDistance: Float = .greatestFiniteMagnitude
        for i in 0..<self.visibleCells.count {
            let cell = self.visibleCells[i]
            let cellWidth = cell.bounds.size.width
            let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)

            // Now calculate closest cell
            let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
            if distance < closestDistance {
                closestDistance = distance
                closestCellIndex = self.indexPath(for: cell)!.row
            }
        }
        if closestCellIndex != -1 {
            self.scrollToItem(at: IndexPath(row: closestCellIndex, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    func getNearestVisibleCollectionViewCell() -> Int {
        let visibleCenterPositionOfScrollView = Float(self.contentOffset.x + (self.bounds.size.width / 2))
        var closestCellIndex = -1
        var closestDistance: Float = .greatestFiniteMagnitude
        for i in 0..<self.visibleCells.count {
            let cell = self.visibleCells[i]
            let cellWidth = cell.bounds.size.width
            let cellCenter = Float(cell.frame.origin.x + cellWidth / 2)

            // Now calculate closest cell
            let distance: Float = fabsf(visibleCenterPositionOfScrollView - cellCenter)
            if distance < closestDistance {
                closestDistance = distance
                closestCellIndex = self.indexPath(for: cell)!.row
            }
        }
        return closestCellIndex
    }
}
