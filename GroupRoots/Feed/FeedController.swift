import UIKit
import Firebase

class FeedController: UICollectionViewController, FeedPostCellDelegate, UICollectionViewDelegateFlowLayout {
    
//    override var prefersStatusBarHidden: Bool { return true }
      
    // 2d representation of the dict, same as dict but with no values
    // later, just use the dict but convert it to this after all data is loaded in
    var groupPosts2D = [[GroupPost]]()
    var groupPostsCount = [String: Int]()
    var groupPostsVisible = [String: Int]()
    var groupPostMembers = [String: [User]]()
    var groupsVisibleCount = 2
    var maxDistanceScrolledEach = [CGFloat]()
    var numPicsScrolledEach = [Int]()
    var isScrolling = false
        
    private let loadingScreenView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 10
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0, alpha: 1)
        return iv
    }()

    func showEmptyStateViewIfNeeded() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().numberOfFollowingForUser(withUID: currentLoggedInUserId) { (followingCount) in
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
//        handleRefresh()
        self.configureNavBar()
                
        // play the video for the visible cell
        collectionView.visibleCells.forEach { cell in
            (cell as! MyCell).playVisibleVideo()
        }
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
        
        loadingScreenView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        loadingScreenView.layer.cornerRadius = 0
        loadingScreenView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        loadingScreenView.image = #imageLiteral(resourceName: "Splash3.png")
        self.view.insertSubview(loadingScreenView, at: 0)

        collectionView?.register(MyCell.self, forCellWithReuseIdentifier: "cellId")
        collectionView?.allowsSelection = false
        collectionView?.showsVerticalScrollIndicator = false
        
        self.view.backgroundColor = UIColor.black
        fetchAllPosts()
        configureNavigationBar()
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: { timer in
            self.loadingScreenView.isHidden = true
        })
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl

        PushNotificationManager().updatePushTokenIfNeeded()
    }
    

    private func configureNavigationBar() {
        self.configureNavBar()
        let textAttributes = [NSAttributedString.Key.font: UIFont(name: "Avenir", size: 22)!, NSAttributedString.Key.foregroundColor : UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
    }

    private func fetchAllPosts() {
        showEmptyStateViewIfNeeded()
        fetchBaseGroupPosts()
    }
        
    // For now, only public groups
    // When have private groups, add a check to see if have access
    // For now, fetch all posts of all groups of all following
    // In the future, will only show some of the posts, the ones from groups that have
    //  the highest score. Score will be determined by how many of the people you're following
    //  are in the group, and how many people you're in a group with are in the group.

    private func fetchBaseGroupPosts() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        collectionView?.refreshControl?.beginRefreshing()
        
        var group_ids = Set<String>()
        self.groupPosts2D = [[GroupPost]]()
        
        // get all the userIds of the people user is following
        let sync = DispatchGroup()
        sync.enter()
        // fetch the group ids of the user
        Database.database().fetchAllGroupIds(withUID: currentLoggedInUserId, completion: { (groupIds) in
            groupIds.forEach({ (groupId) in
                if group_ids.contains(groupId) == false && groupId != "" {
                    group_ids.insert(groupId)
                }
            })
            sync.leave()
        }, withCancel: { (err) in
            print("Failed to fetch posts:", err)
            self.loadingScreenView.isHidden = true
            self.collectionView?.refreshControl?.endRefreshing()
        })
               
        sync.enter()
        Database.database().fetchGroupsFollowing(withUID: currentLoggedInUserId, completion: { (groups) in
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
                Database.database().fetchAllGroupPosts(groupId: groupId, completion: { (countAndPosts) in
                    if countAndPosts.count > 0 {
                        let posts = countAndPosts[1] as! [GroupPost]
                        let count = countAndPosts[0] as! Int
                        let sortedPosts = posts.sorted(by: { (p1, p2) -> Bool in
                            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                        })
                        if sortedPosts.count > 0 {
                            let groupId = sortedPosts[0].group.groupId
                            self.groupPosts2D.append(sortedPosts)
                            // dictionary with group and how many total posts are for that group
                            self.groupPostsCount[groupId] = count
                            self.groupPostsVisible[groupId] = 0
                            lower_sync.enter()
                            Database.database().fetchGroupMembers(groupId: groupId, completion: { (users) in
                                lower_sync.leave()
                                self.groupPostMembers[groupId] =  users
                            }) { (_) in }
                        }
                    }
                    lower_sync.leave()
                }, withCancel: { (err) in
                    self.loadingScreenView.isHidden = true
                    self.collectionView?.refreshControl?.endRefreshing()
                })
            })
            lower_sync.notify(queue: .main) {
                self.groupPosts2D.sort(by: { (p1, p2) -> Bool in
                    return p1[0].creationDate.compare(p2[0].creationDate) == .orderedDescending
                })
                self.loadingScreenView.isHidden = true
                self.fetchMoreGroups()
                self.collectionView?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }
    }

    private func fetchMoreGroupPosts(row: Int) {
        collectionView?.refreshControl?.beginRefreshing()
        if row >= self.groupPosts2D.count || self.groupPosts2D[row].count-1 >= self.groupPosts2D[row].count {
            print("groupId cannot be found")
            self.collectionView?.refreshControl?.endRefreshing()
            return
        }
        let groupId = self.groupPosts2D[row][self.groupPosts2D[row].count-1].group.groupId
        if self.groupPostsVisible[groupId]! == 0 {
            self.groupsVisibleCount += 1
        }
        self.groupPostsVisible[groupId]! += 3
        self.collectionView?.reloadData()
        self.collectionView?.refreshControl?.endRefreshing()
    }
    
    private func fetchMoreGroups() {
        if self.groupPosts2D.count > 0{
            for i in 0...self.groupPosts2D.count-1 {
                // find first entree with count 0, and load 3 from there
                let groupId = self.groupPosts2D[i][0].group.groupId
                var self_destruct = 2
                if self.groupPostsVisible[groupId] == 0 {
                    self.groupPostsVisible[groupId] = 3
                    self_destruct -= 1
                }
                if self_destruct < 1 {
                    return
                }
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if groupsVisibleCount > groupPosts2D.count{
            return groupPosts2D.count
        }
        return groupsVisibleCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! MyCell
        if indexPath.row < groupPosts2D.count{
            let groupId = groupPosts2D[indexPath.row][0].group.groupId
            var numPostsToShow = groupPostsVisible[groupId] ?? 0
            if numPostsToShow > 0 {
                if numPostsToShow > groupPosts2D[indexPath.row].count {
                    numPostsToShow = groupPosts2D[indexPath.row].count
                }
                myCell.groupPosts = Array(groupPosts2D[indexPath.row].prefix(numPostsToShow))
                myCell.groupPostMembers = groupPostMembers[groupId]
                if groupPosts2D[indexPath.row].count > 0 {
                    let groupId = groupPosts2D[indexPath.row][0].group.groupId
                    myCell.totalPostsNum = groupPostsCount[groupId]
                }
            }
        }
        myCell.feedController = self
        myCell.delegate = self
        myCell.tag = indexPath.row
        myCell.isScrollingVertically = isScrolling
        myCell.maxDistanceScrolled = CGFloat(0)
        myCell.numPicsScrolled = 1
        return myCell
    }
    
//    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, cellForItemAt indexPath: IndexPath) {
//        print("Hi")
//    }

    @objc private func handleRefresh() {
        // stop video of visible cell
        collectionView.visibleCells.forEach { cell in
            // TODO: write logic to stop the video before it begins scrolling
            (cell as! MyCell).pauseVisibleVideo()
            (cell as! MyCell).isScrollingVertically = isScrolling
        }
        
        showEmptyStateViewIfNeeded()
        fetchBaseGroupPosts()
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        collectionView.visibleCells.forEach { cell in
            // TODO: write logic to stop the video before it begins scrolling
            (cell as! MyCell).pauseVisibleVideo()
            (cell as! MyCell).isScrollingVertically = isScrolling
        }
        isScrolling = true
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
        
        if maxDistanceScrolled < endPos {
            maxDistanceScrolled = endPos
            numGroupsScrolled += 1
            
            // if viewed more than 2 groups, load 2 more
            if numGroupsScrolled % 2 == 0 {
                groupsVisibleCount += 2
                collectionView?.refreshControl?.beginRefreshing()
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
            }
        }
        isScrolling = false
        collectionView.visibleCells.forEach { cell in
            (cell as! MyCell).isScrollingVertically = isScrolling
        }
//        collectionView.visibleCells.forEach { cell in
//            (cell as! MyCell).playVisibleVideo()
//        }
    }

    //MARK: - FeedPostCellDelegate
    func didReachScrollEnd(for cell: MyCell) {
        fetchMoreGroupPosts(row: cell.tag)
    }

    func didTapComment(groupPost: GroupPost) {
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.groupPost = groupPost
        navigationController?.pushViewController(commentsController, animated: true)
        
//        let nacController = UINavigationController(rootViewController: commentsController)
//        present(nacController, animated: true, completion: nil)
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
        let viewersController = ViewersController()
        viewersController.viewers = viewers
        viewersController.viewsCount = viewsCount
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
        let action = UIAlertAction(title: "Unsubscribe", style: .destructive, handler: { (_) in
            
            let alert = UIAlertController(title: "Unsubscribe?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Unsubscribe", style: .default, handler: { (_) in
                
                Database.database().deleteGroupPost(groupId: groupPost.group.groupId, postId: groupPost.id) { (_) in
                }
                Database.database().removeGroupFromUserFollowing(withUID: uid, groupId: groupPost.group.groupId) { (err) in
                    
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }

    func updateMaxDistance(for cell: HomePostCell) {
        self.maxDistanceScrolledEach[cell.tag] = CGFloat(self.numPicsScrolledEach[cell.tag])
    }
    
    func updateNumPicsScrolled(for cell: HomePostCell) {
        self.numPicsScrolledEach[cell.tag] += 1
    }
    
    func didSelectUser(selectedUser: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = selectedUser
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func showMoreMembers(group: Group){
        let membersController = MembersController(collectionViewLayout: UICollectionViewFlowLayout())
        membersController.group = group
        membersController.isInGroup = false
        self.navigationController?.pushViewController(membersController, animated: true)
    }
    
    func requestPlay(for cell: FeedPostCell) {
        if !isScrolling {
            cell.player.playFromCurrentTime()
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
        messageLabel.textColor = UIColor.white
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.font = UIFont(name: "Avenir", size: 20)
        messageLabel.sizeToFit()

        viewController.collectionView.backgroundView = messageLabel;
    }
}
