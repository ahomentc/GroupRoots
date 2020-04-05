//
//  LargeImageViewController.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/19/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import UPCarouselFlowLayout

class LargeImageViewController: UICollectionViewController, InnerPostCellDelegate, FeedMembersCellDelegate {
    
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
    
    // key is groupId
    // value is an array of GroupPosts of that group
    var groupPostsDict: [String:[GroupPost]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
        self.configureNavigationBar()
        
        // not actually scrolling but enables video play
        self.isScrolling = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isScrolling = true
    }
    
    private func configureNavigationBar() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem?.tintColor = .black
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = .clear
        let textAttributes = [NSAttributedString.Key.font: UIFont(name: "Avenir", size: 22)!, NSAttributedString.Key.foregroundColor : UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)]
        self.navigationController?.navigationBar.titleTextAttributes = textAttributes
    }
    
    private func configureGroup() {
        handleRefresh()
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
            self.scrollToSetPost()
            self.scrollToIndexPath()
                
            let sync = DispatchGroup()
            posts.forEach({ (groupPost) in
                sync.enter()
                Database.database().fetchFirstCommentForPost(withId: groupPost.id, completion: { (comments) in
                    self.numCommentsForPosts[groupPost.id] = comments.count
                    if comments.count > 0 {
                        self.firstCommentForPosts[groupPost.id] = comments[0]
                    }
                    Database.database().isInGroup(groupId: groupPost.group.groupId, completion: { (inGroup) in
                        sync.leave()
                        if inGroup {
                            sync.enter()
                            Database.database().fetchPostVisibleViewers(postId: groupPost.id, completion: { (viewer_ids) in
                                sync.leave()
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
                            }) { (err) in
                            }
                        }
                    }) { (err) in
                        return
                    }
                    
                }) { (err) in
                }
            })
            sync.notify(queue: .main) {
                Database.database().fetchGroupMembers(groupId: groupId, completion: { (users) in
                    self.groupPostMembers = users
                    DispatchQueue.main.async{
                        self.collectionView.reloadData()
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
        
        self.configureNavigationBar()
            
        self.view.backgroundColor = UIColor.black
        
        self.view.addSubview(header)
        header.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 25, paddingLeft: 5)
        header.delegate = self
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalPostsNum ?? groupPosts.count
        // !!!!!!!!!!!!! I don't think totalPostsNum is being used. Check this out!!!
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item < groupPosts.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedPostCell.cellId, for: indexPath) as! FeedPostCell
            cell.isScrolling = isScrolling
            cell.delegate = self
            cell.emptyComment = true
            cell.groupPost = groupPosts[indexPath.item]
            if firstCommentForPosts[groupPosts[indexPath.item].id] != nil {
                cell.firstComment = firstCommentForPosts[groupPosts[indexPath.item].id ]
            }
            if numCommentsForPosts[groupPosts[indexPath.item].id] != nil {
                cell.numComments = numCommentsForPosts[groupPosts[indexPath.item].id ]
            }
//            if viewersForPosts[groupPosts[indexPath.item].id] != nil {
//                cell.viewersForPost = viewersForPosts[groupPosts[indexPath.item].id ]
//            }
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyFeedPostCell.cellId, for: indexPath) as! EmptyFeedPostCell
            return cell
        }
    }
    
    func configureHeader() {
        guard let group = group else { return }
        if groupPostMembers.count == 0 { return }
        header.group = group
        header.groupPostMembers = groupPostMembers
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
    
    private func deleteAction(forPost groupPost: GroupPost) -> UIAlertAction? {
       let action = UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
           
           let alert = UIAlertController(title: "Delete Post?", message: nil, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
           alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (_) in
               
               Database.database().deleteGroupPost(groupId: groupPost.group.groupId, postId: groupPost.id) { (_) in
                   if let postIndex = self.groupPosts.index(where: {$0.id == groupPost.id}) {
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
    
    //MARK: - InnerPostCellDelegate
    
    func didTapComment(groupPost: GroupPost) {
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.groupPost = groupPost
        navigationController?.pushViewController(commentsController, animated: true)
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
        let viewersController = ViewersController()
        viewersController.viewers = viewers
        let navController = UINavigationController(rootViewController: viewersController)
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
//        if groupPosts.count == 0 { return }
//        let groupPost = groupPosts[0]
//        delegate?.didTapOptions(groupPost: groupPost)
    }
    
}
