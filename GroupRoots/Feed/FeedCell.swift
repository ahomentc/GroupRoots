//
//  FeedCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/23/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import UPCarouselFlowLayout
import Firebase

protocol FeedPostCellDelegate {
    func didTapComment(groupPost: GroupPost)
    func didTapGroup(group: Group)
    func didTapUser(user: User)
    func didTapOptions(groupPost: GroupPost)
    func didReachScrollEnd(for cell: MyCell)
    func didSelectUser(selectedUser: User)
    func showMoreMembers(group: Group)
    func updateMaxDistance(for cell: HomePostCell)
    func updateNumPicsScrolled(for cell: HomePostCell)
    func didView(groupPost: GroupPost)
    func showViewers(viewers: [User], viewsCount: Int)
    func requestPlay(for cell: FeedPostCell)
}

class MyCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, InnerPostCellDelegate, FeedMembersCellDelegate {
    
    // the group posts loaded so far
    // When calling to fetch posts, we pass the last post in this set
    // we compare the date of the last post will all posts and retreive the n posts
    // after that.
    
    var firstCommentForPosts = [String: Comment]()
    var viewersForPosts = [String: [User]]()
    var numViewsForPost = [String: Int]()
    var numCommentsForPosts = [String: Int]()
    var syncDone = false
    var isScrolling = false
    var isScrollingVertically = false
    
    var groupPosts: [GroupPost]? {
        didSet {
            // maybe move the configure header part to FeedController
            configureHeader()
            if numPicsScrolled == 1 {
                collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: false)
            }
            
            let sync = DispatchGroup()
            groupPosts!.forEach({ (groupPost) in
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
                            // fetchPostViewers only gets non-anonymous views so need to use fetchNumPostViewers to get full number
                            Database.database().fetchPostViewers(postId: groupPost.id, completion: { (viewer_ids) in
                                Database.database().fetchNumPostViewers(postId: groupPost.id, completion: {(views_count) in
                                    sync.leave()
                                    self.numViewsForPost[groupPost.id] = views_count
                                    self.reloadGroupData()
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
//                        else{
//                            sync.leave()
//                        }
                    }) { (err) in
                        return
                    }
                    
                }) { (err) in
                }
            })
            sync.notify(queue: .main) {
                self.syncDone = true
                self.reloadGroupData()
            }
        }
    }
    
    var groupPostMembers: [User]? {
        didSet {
            configureHeader()
        }
    }
    
    var totalPostsNum: Int? {
        didSet {
            reloadGroupData()
        }
    }
    
    var maxDistanceScrolled = CGFloat(0)
    var numPicsScrolled = 1

    var collectionView: UICollectionView!
    
    let header = FeedPostCellHeader()
    var delegate: FeedPostCellDelegate?
    
    var feedController: FeedController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    func reloadGroupData(){
        guard totalPostsNum != nil else { return }
        guard numViewsForPost.count != 0 else { return }
        if !syncDone { return }
        
        DispatchQueue.main.async{
            self.collectionView.reloadData()
        }
    }
    
    func setupViews() {
        let layout = UPCarouselFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.spacingMode = UPCarouselFlowLayoutSpacingMode.fixed(spacing: 8)
        layout.sideItemAlpha = 0.7
        layout.sideItemScale = 0.7
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(FeedPostCell.self, forCellWithReuseIdentifier: FeedPostCell.cellId)
        collectionView?.register(EmptyFeedPostCell.self, forCellWithReuseIdentifier: EmptyFeedPostCell.cellId)
        collectionView?.register(MembersCell.self, forCellWithReuseIdentifier: MembersCell.cellId)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        self.addSubview(collectionView)
        
        addSubview(header)
        header.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 5)
        header.delegate = self        
    }
    
    func configureHeader() {
        if groupPosts?.count == 0 { return }
        guard let groupPost = groupPosts?[0] else { return }
        header.group = groupPost.group
        guard let groupPostMembers = groupPostMembers else { return }
        header.groupPostMembers = groupPostMembers
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (totalPostsNum ?? groupPosts?.count ?? -1) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print(indexPath.row)
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MembersCell.cellId, for: indexPath) as! MembersCell
            cell.group = groupPosts?[0].group
            cell.delegate = self
            return cell
        }
        else {
            if indexPath.item-1 < groupPosts?.count ?? 0{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedPostCell.cellId, for: indexPath) as! FeedPostCell
                cell.groupPost = groupPosts?[indexPath.item-1]

                if firstCommentForPosts[groupPosts?[indexPath.item-1].id ?? ""] != nil {
                    cell.firstComment = firstCommentForPosts[groupPosts?[indexPath.item-1].id ?? ""]
                }
                if numCommentsForPosts[groupPosts?[indexPath.item-1].id ?? ""] != nil {
                    cell.numComments = numCommentsForPosts[groupPosts?[indexPath.item-1].id ?? ""]
                }
                if numViewsForPost[groupPosts?[indexPath.item-1].id ?? ""] != nil {
                    cell.numViewsForPost = numViewsForPost[groupPosts?[indexPath.item-1].id ?? ""]
                }
                cell.isScrollingVertically = isScrollingVertically
                cell.isScrolling = isScrolling
                cell.delegate = self
                
                // when load the cell start playing if not scrolling
//                if !isScrolling && !isScrollingVertically{
//                    print("2")
//                    cell.player.playFromBeginning()
//                }
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyFeedPostCell.cellId, for: indexPath) as! EmptyFeedPostCell
                return cell
            }
        }
    }
    
    func pauseVisibleVideo() {
        collectionView.visibleCells.forEach { cell in
            if cell.isKind(of: FeedPostCell.self){
                (cell as! FeedPostCell).player.muted = true
                (cell as! FeedPostCell).player.pause()
            }
        }
    }
    
    func playVisibleVideo() {
        collectionView.visibleCells.forEach { cell in
            if cell.isKind(of: FeedPostCell.self){
                if (cell as! FeedPostCell).player.url?.absoluteString ?? "" != "" {
                    (cell as! FeedPostCell).player.muted = false
                    (cell as! FeedPostCell).player.playFromCurrentTime()
                }
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.pauseVisibleVideo()
        isScrolling = true
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let endPos = scrollView.contentOffset.x
        self.stoppedScrolling(endPos: endPos)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let endPos = scrollView.contentOffset.x
        if !decelerate {
            self.stoppedScrolling(endPos: endPos)
        }
    }

    func stoppedScrolling(endPos: CGFloat) {
        if maxDistanceScrolled < endPos {
            maxDistanceScrolled = endPos
            numPicsScrolled += 1
            
            // if viewed more than two pictures, load 3 more
            if numPicsScrolled % 2 == 0 {
                didReachScrollEnd()
            }
        }
        isScrolling = false
//        self.playVisibleVideo()
    }
    
    //MARK: - InnerPostCellDelegate
    
    func requestPlay(for cell: FeedPostCell) {
        if !isScrolling {
            delegate?.requestPlay(for: cell)
        }
    }
    
    func didTapComment(groupPost: GroupPost) {
        delegate?.didTapComment(groupPost: groupPost)
    }
    
    func didTapUser(user: User) {
        delegate?.didTapUser(user: user)
    }
    
    func didTapGroup(group: Group) {
        delegate?.didTapGroup(group: group)
    }
    
    func didTapOptions(groupPost: GroupPost) {
        delegate?.didTapOptions(groupPost: groupPost)
    }
    
    func didView(groupPost: GroupPost) {
        delegate?.didView(groupPost: groupPost)
    }
    
    func didTapViewers(groupPost: GroupPost){
        guard let viewers = viewersForPosts[groupPost.id] else { return }
        guard let numViews = numViewsForPost[groupPost.id] else { return }
        delegate?.showViewers(viewers: viewers, viewsCount: numViews)
    }
    
    @objc private func didReachScrollEnd() {
        delegate?.didReachScrollEnd(for: self)
    }
    
    func goToImage(for cell: FeedPostCell, isRight: Bool) {
        let old_indexPath_row = collectionView.indexPath(for: cell)?.row
        if old_indexPath_row == nil { return }
        if isRight {
            if old_indexPath_row! + 1 == self.collectionView.numberOfItems(inSection: 0) {
                return
            }
            collectionView.scrollToItem(at: IndexPath(item: old_indexPath_row! + 1, section: 0), at: .centeredHorizontally, animated: true)
            
            // THIS KEEPS ADDING IMAGES, EVEN IF GOING BACKWARDS THEN FORWARDS. NEEDS TO BE CHANGED BUT WORKS FOR NOW.
            numPicsScrolled += 1
            if numPicsScrolled % 2 == 0 {
                didReachScrollEnd()
            }
        }
        else {
            if old_indexPath_row! - 1 == -1 {
                return
            }
            collectionView.scrollToItem(at: IndexPath(item: old_indexPath_row! - 1, section: 0), at: .centeredHorizontally, animated: true)
        }
    }

    
    //MARK: - FeedMembersCellDelegate
    func selectedMember(selectedUser: User) {
        delegate?.didSelectUser(selectedUser: selectedUser)
    }
    
    func showMoreMembers() {
        guard let group = groupPosts?[0].group else { return }
        delegate?.showMoreMembers(group: group)
    }
}

extension MyCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}


//MARK: - HomePostCellHeaderDelegate

extension MyCell: FeedPostCellHeaderDelegate {
    
    func didTapGroup() {
        guard let group = groupPosts?[0].group else { return }
        delegate?.didTapGroup(group: group)
    }
    
    func didTapOptions() {
        guard let groupPost = groupPosts?[0] else { return }
        delegate?.didTapOptions(groupPost: groupPost)
    }
    
    func goToFirstImage() {
        collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: true)
    }
}
