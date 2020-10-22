//
//  LargeImageViewController.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/19/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import UPCarouselFlowLayout
import Zoomy
import NVActivityIndicatorView

class LargeImageViewController: UICollectionViewController, InnerPostCellDelegate, FeedMembersCellDelegate, ViewersControllerDelegate {
    
    override var prefersStatusBarHidden: Bool { return true }
    // the group posts loaded so far
    // When calling to fetch posts, we pass the last post in this set
    // we compare the date of the last post will all posts and retreive the n posts
    // after that.
    
    var group: Group? {
        didSet {
            configureGroup()
        }
    }

    var indexPath: IndexPath!
    
    var postToScrollToId: String!
                    
    var groupPosts = [GroupPost]()
    var groupPostMembers = [User]()
    var firstCommentForPosts = [String: Comment]()
    var viewersForPosts = [String: [User]]()
    var numViewsForPost = [String: Int]()
    var numCommentsForPosts = [String: Int]()
    var isScrolling = false
    
    let header = LargeImageViewHeader()
    
    var totalPostsNum: Int? {
        didSet {
            DispatchQueue.main.async{
                self.collectionView.reloadData()
            }
        }
    }
    
    var isZooming = false
    
    // key is groupId
    // value is an array of GroupPosts of that group
    var groupPostsDict: [String:[GroupPost]] = [:]
    
    let activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width/2 - 35, y: UIScreen.main.bounds.height/2 - 50, width: 70, height: 70), type: NVActivityIndicatorType.circleStrokeSpin)
    
    private lazy var groupnameButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(.white, for: .normal)
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        label.contentHorizontalAlignment = .center
        label.isUserInteractionEnabled = true
        label.addTarget(self, action: #selector(handleGroupTap), for: .touchUpInside)
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "compress"), for: .normal)
        button.isUserInteractionEnabled = true
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(handleCloseFullscreen), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        setupViews()
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDismiss)))
    }
    
    var viewTranslation = CGPoint(x: 0, y: 0)
    @objc func handleDismiss(sender: UIPanGestureRecognizer) {
        if !isZooming{
            switch sender.state {
                case .changed:
                    viewTranslation = sender.translation(in: view)
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                        self.view.transform = CGAffineTransform(translationX: 0, y: self.viewTranslation.y)
                    })
                case .ended:
                    if viewTranslation.y < 50 && viewTranslation.y > -50 {
                        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                            self.view.transform = .identity
                        })
                    } else {
                        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                            if self.viewTranslation.y > 50 {
                                self.view.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
                            }
                            else {
                                self.view.transform = CGAffineTransform(translationX: 0, y: -1 * UIScreen.main.bounds.height)
                            }
                        })
                        self.sendCloseNotifications(animatedScroll: false)
                        NotificationCenter.default.post(name: NSNotification.Name("reloadViewedPosts"), object: nil)
                        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { timer in
                            self.collectionView.isHidden = true
                            self.view.backgroundColor = .clear
//                            self.sendCloseNotifications(animatedScroll: true)
                            self.dismiss(animated: false, completion: nil)
                        }
                    }
                default:
                    break
                }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationBar()
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
        
        // not actually scrolling but enables video play
        self.isScrolling = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isScrolling = true
        self.navigationController?.isNavigationBarHidden = false
//        handleCloseFullscreen()
    }
    
    private func configureNavigationBar() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem?.tintColor = .black
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = .clear
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor : UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        self.navigationController?.isNavigationBarHidden = true
    }
    
    private func configureGroup() {
        handleRefresh()
        configureGroupNameButton()
    }
    
    @objc private func configureGroupNameButton() {
        guard let group = group else { return }
        if group.groupname != "" {
            let lockImage = #imageLiteral(resourceName: "lock_white")
            let lockIcon = NSTextAttachment()
            lockIcon.image = lockImage
            let lockIconString = NSAttributedString(attachment: lockIcon)

            let balanceFontSize: CGFloat = 20
            let balanceFont = UIFont.boldSystemFont(ofSize: balanceFontSize)

            //Setting up font and the baseline offset of the string, so that it will be centered
            let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, .foregroundColor: UIColor.white, .baselineOffset: (lockImage.size.height - balanceFontSize) / 2 - balanceFont.descender / 2]
            let balanceString = NSMutableAttributedString(string: group.groupname.replacingOccurrences(of: "_-a-_", with: " ") + " ", attributes: balanceAttr)

            if group.isPrivate ?? false {
                balanceString.append(lockIconString)
            }
            self.groupnameButton.setAttributedTitle(balanceString, for: .normal)
        }
    }
    
    @objc private func handleRefresh() {
        guard let groupId = group?.groupId else { return }
        groupPosts.removeAll()
        
        Database.database().fetchAllGroupPosts(groupId: groupId, completion: { (countAndPosts) in
            let posts = countAndPosts[1] as! [GroupPost]
            self.groupPosts = posts
            self.groupPosts.sort(by: { (p1, p2) -> Bool in
                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
            })
            
            self.configureHeader()
            self.collectionView?.reloadData()
            self.scrollToIndexPath()
            self.scrollToSetPost()
                
            let sync = DispatchGroup()
            posts.forEach({ (groupPost) in
                sync.enter()
                Database.database().numberOfCommentsForPost(postId: groupPost.id) { (commentsCount) in
                    self.numCommentsForPosts[groupPost.id] = commentsCount
                    Database.database().isInGroup(groupId: groupPost.group.groupId, completion: { (inGroup) in
                        sync.leave()
                        if inGroup {
                            sync.enter()
                            Database.database().fetchPostVisibleViewers(postId: groupPost.id, completion: { (viewer_ids) in
                                Database.database().fetchNumPostViewers(postId: groupPost.id, completion: {(views_count) in
                                    sync.leave()
                                    self.numViewsForPost[groupPost.id] = views_count
//                                    self.reloadGroupData()
                                    if viewer_ids.count > 0 {
                                        var viewers = [User]()
                                        let viewersSync = DispatchGroup()
                                        sync.enter()
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
                                            self.viewersForPosts[groupPost.id] = viewers
                                            sync.leave()
                                        }
                                    }
                                }) { (err) in }
                            }) { (err) in
                            }
                        }
                    }) { (err) in
                        return
                    }
                }
            })
            sync.notify(queue: .main) {
                Database.database().fetchGroupMembers(groupId: groupId, completion: { (users) in
                    self.groupPostMembers = users
                    DispatchQueue.main.async{
                        self.activityIndicatorView.isHidden = true
                        self.collectionView.reloadData()
                        self.scrollToIndexPath()
                        self.configureHeader()
                    }
                }) { (_) in }
            }
            self.collectionView?.refreshControl?.endRefreshing()

        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }
    
    func scrollToSetPost(){
        if postToScrollToId != nil {
            var index = 0
            for post in self.groupPosts {
                if post.id == postToScrollToId {
                    self.collectionView?.scrollToItem(at: IndexPath(item: index, section: 0), at: [.centeredVertically, .centeredHorizontally], animated: false)
                    self.postToScrollToId = nil
                    break
                }
                index += 1
            }
        }
    }
    
    func scrollToIndexPath() {
        if self.indexPath != nil{
            self.collectionView?.scrollToItem(at: self.indexPath, at: [.centeredVertically, .centeredHorizontally], animated: false)
            self.indexPath = nil
        }
    }
    
    func setupViews() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(FeedPostCell.self, forCellWithReuseIdentifier: FeedPostCell.cellId)
        collectionView?.register(EmptyFeedPostCell.self, forCellWithReuseIdentifier: EmptyFeedPostCell.cellId)
        collectionView?.register(MembersCell.self, forCellWithReuseIdentifier: MembersCell.cellId)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        
        self.configureNavigationBar()
        
        self.view.insertSubview(groupnameButton, at: 6)
        groupnameButton.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: UIScreen.main.bounds.height/16, paddingLeft: 50, paddingRight: 50)
        groupnameButton.backgroundColor = .clear
        groupnameButton.isUserInteractionEnabled = true
        
        self.view.addSubview(closeButton)
        closeButton.anchor(top: self.view.topAnchor, right: self.view.rightAnchor, paddingTop: 40, paddingRight: 20)
        
        activityIndicatorView.isHidden = false
        self.view.insertSubview(activityIndicatorView, at: 20)
        activityIndicatorView.startAnimating()
        
        self.view.backgroundColor = UIColor.black
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCloseFullscreen), name: NSNotification.Name(rawValue: "closeFullScreenViewController"), object: nil)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if groupPosts.count == 0 {
            return 0
        }
        return groupPosts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item < groupPosts.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedPostCell.cellId, for: indexPath) as! FeedPostCell
            cell.isScrolling = isScrolling
            cell.delegate = self
            cell.emptyComment = true
            cell.groupPost = groupPosts[indexPath.item]
            let post_id = groupPosts[indexPath.item].id
            if firstCommentForPosts[post_id] != nil {
                cell.firstComment = firstCommentForPosts[post_id]
            }
            if numCommentsForPosts[post_id] != nil {
                cell.numComments = numCommentsForPosts[post_id]
            }
            if numViewsForPost[post_id] != nil {
                cell.numViewsForPost = numViewsForPost[post_id]
            }
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyFeedPostCell.cellId, for: indexPath) as! EmptyFeedPostCell
            return cell
        }
    }
    
    func sendCloseNotifications(animatedScroll: Bool){
        guard let group = group else { return }
        var row = -1
        collectionView.visibleCells.forEach { cell in
            if collectionView.indexPath(for: cell) != nil {
                row = collectionView.indexPath(for: cell)!.row
            }
        }
        if row == -1 { // error occured when trying to find row
            NotificationCenter.default.post(name: NSNotification.Name("closeFullScreen"), object: nil)
        }
        else {
            let userDataDict:[String: Any] = ["indexPathRow": row, "animatedScroll": animatedScroll, "groupId": group.groupId]
            NotificationCenter.default.post(name: NSNotification.Name("closeFullScreenWithRow"), object: nil, userInfo: userDataDict)
        }
    }
    
    @objc func handleCloseFullscreen(){
        // this is called when the button to close is pressed, no need to animate in that case
        // if animate it will look weird
        sendCloseNotifications(animatedScroll: false)
        NotificationCenter.default.post(name: NSNotification.Name("reloadViewedPosts"), object: nil)
        self.dismiss(animated: true, completion: {})
    }
    
    func configureHeader() {        
        if groupPosts.count == 0 { return }
        let groupPost = groupPosts[0]
        header.group = groupPost.group
        header.groupMembers = groupPostMembers
    }
    
    func pauseVisibleVideo() {
        collectionView.visibleCells.forEach { cell in
            if cell.isKind(of: FeedPostCell.self){
                (cell as! FeedPostCell).player.pause()
            }
        }
    }
    
    func playVisibleVideo() {
        collectionView.visibleCells.forEach { cell in
            if cell.isKind(of: FeedPostCell.self){
                if (cell as! FeedPostCell).player.url?.absoluteString ?? "" != "" {
                    (cell as! FeedPostCell).player.playFromCurrentTime()
                }
            }
        }
    }
    
    func requestZoomCapability(for cell: FeedPostCell) {
        addZoombehavior(for: cell.photoImageView, settings: .instaZoomSettings)
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.pauseVisibleVideo()
        isScrolling = true
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let endPos = scrollView.contentOffset.x
        self.stoppedScrolling(endPos: endPos)
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let endPos = scrollView.contentOffset.x
        if !decelerate {
            self.stoppedScrolling(endPos: endPos)
        }
    }

    func stoppedScrolling(endPos: CGFloat) {
        isScrolling = false
        
        // set didView for cell
        collectionView.visibleCells.forEach { cell in
            if cell is FeedPostCell {
                let groupPost = (cell as! FeedPostCell).groupPost
                if groupPost != nil {
                    handleDidView(groupPost: groupPost!)
                }
            }
        }
    }
    
    func requestPlay(for cell: FeedPostCell) {
        if !isScrolling {
            // check to see if visible too
            collectionView.visibleCells.forEach { cell_visible in  // check if cell is still visible
                if cell_visible == cell {
                    cell.player.playFromCurrentTime()
                }
            }
        }
    }
    
    func handleDidView(groupPost: GroupPost) {
        Database.database().addToViewedPosts(postId: groupPost.id, completion: { _ in })
    }
    
    private func deleteAction(forPost groupPost: GroupPost) -> UIAlertAction? {
       let action = UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
           
           let alert = UIAlertController(title: "Delete Post?", message: nil, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
           alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (_) in
               
               Database.database().deleteGroupPost(groupId: groupPost.group.groupId, postId: groupPost.id) { (_) in
                   if let postIndex = self.groupPosts.index(where: {$0.id == groupPost.id}) {
                        NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                        NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                        self.groupPosts.remove(at: postIndex)
                        self.collectionView?.reloadData()
//                           self.showEmptyStateViewIfNeeded()
                    
                   }
               }
           }))
           self.present(alert, animated: true, completion: nil)
       })
       return action
   }
    
    func goToFirstImage() {
        collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    func goToImage(for cell: FeedPostCell, isRight: Bool) {
        let old_indexPath_row = collectionView.indexPath(for: cell)?.row
        if old_indexPath_row == nil { return }
        if isRight {
            if old_indexPath_row! + 1 == self.collectionView.numberOfItems(inSection: 0) {
                return
            }
            collectionView.scrollToItem(at: IndexPath(item: old_indexPath_row! + 1, section: 0), at: .centeredHorizontally, animated: true)
            
        }
        else {
            if old_indexPath_row! - 1 == -1 {
                return
            }
            collectionView.scrollToItem(at: IndexPath(item: old_indexPath_row! - 1, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    @objc func handleGroupTap(){
        guard let group = group else { return }
        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        groupProfileController.group = group
        groupProfileController.modalPresentationCapturesStatusBarAppearance = true
        navigationController?.pushViewController(groupProfileController, animated: true)
    }
    
    //MARK: - InnerPostCellDelegate
    
    func didTapComment(groupPost: GroupPost) {
        let commentsController = CommentsController()
        commentsController.groupPost = groupPost
        navigationController?.pushViewController(commentsController, animated: true)
        
//        let navController = UINavigationController(rootViewController: commentsController)
//        navController.modalPresentationStyle = .popover
//        self.present(navController, animated: true, completion: nil)
    }
    
    func didTapUser(user: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = user
        userProfileController.modalPresentationCapturesStatusBarAppearance = true
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapGroup(group: Group) {
        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        groupProfileController.group = group
        groupProfileController.modalPresentationCapturesStatusBarAppearance = true
        navigationController?.pushViewController(groupProfileController, animated: true)
    }
    
    func didTapViewers(groupPost: GroupPost) {
        guard let viewers = viewersForPosts[groupPost.id] else { return }
        guard let numViews = numViewsForPost[groupPost.id] else { return }
        let viewersController = ViewersController()
        viewersController.viewers = viewers
        viewersController.viewsCount = numViews
        viewersController.delegate = self
        let navController = UINavigationController(rootViewController: viewersController)
        navController.modalPresentationStyle = .popover
        self.present(navController, animated: true, completion: nil)
    }
    
    func didView(groupPost: GroupPost) {
        Database.database().addToViewedPosts(postId: groupPost.id, completion: { _ in
        })
    }
    
    func didTapOptions(groupPost: GroupPost) {                
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        Database.database().isInGroup(groupId: groupPost.group.groupId, completion: { (inGroup) in
            if inGroup {
                if let deleteAction = self.deleteAction(forPost: groupPost) {
                    alertController.addAction(deleteAction)
                }
            }
            else{
//                if let muteAction = muteAction(forPost: groupPost) {
//                    alertController.addAction(muteAction)
//                }
            }
        }) { (err) in
            return
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func didReachScrollEnd() {
    }
    
    func selectedMember(selectedUser: User) {
//        delegate?.didSelectUser(selectedUser: selectedUser)
    }
    
    func showMoreMembers() {
//        guard let group = group else { return }
//        delegate?.showMoreMembers(group: group)
    }
}

extension LargeImageViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}

//MARK: - LargeImageViewHeaderDelegate
extension LargeImageViewController: LargeImageViewHeaderDelegate {
    
    func didTapGroup() {
        guard let group = group else { return }
        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        groupProfileController.group = group
        groupProfileController.modalPresentationCapturesStatusBarAppearance = true
        navigationController?.pushViewController(groupProfileController, animated: true)
    }
    
    func didTapOptions() {
    }
    
}

extension LargeImageViewController: Zoomy.Delegate {
    
    func didBeginPresentingOverlay(for imageView: Zoomable) {
        NotificationCenter.default.post(name: NSNotification.Name("tabBarDisappear"), object: nil)
        collectionView.isScrollEnabled = false
        isZooming = true
    }
    
    func didEndPresentingOverlay(for imageView: Zoomable) {
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
        collectionView.isScrollEnabled = true
        isZooming = false
    }
}
