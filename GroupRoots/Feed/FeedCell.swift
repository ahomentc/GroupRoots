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
    func didSelectUser(selectedUser: User)
    func showMoreMembers(group: Group)
    func didView(groupPost: GroupPost)
    func showViewers(viewers: [User], viewsCount: Int)
    func requestPlay(for_lower cell1: FeedPostCell, for_upper cell2: MyCell)
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
    var isScrolling = false
    var isScrollingVertically = false
    
    var groupPosts: [GroupPost]? {
        didSet {
            configureHeader()
            collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: false)
            self.reloadGroupData()
        }
    }
    
    var groupMembers: [User]? {
        didSet {
            configureHeader()
        }
    }
    
    // this might be bad but to clarify. FeedController sets groupPostsViewers for this cell. That in turn sets viewersForPosts
    var groupPostsViewers: [String: [User]]? { // key is the postId
        didSet{
            guard let groupPostsViewers = groupPostsViewers else { return }
            viewersForPosts = groupPostsViewers
        }
    }
    
    var groupPostsTotalViewers: [String: Int]? { // key is the postId
        didSet {
            guard let groupPostsTotalViewers = groupPostsTotalViewers else { return }
            numViewsForPost = groupPostsTotalViewers
            self.reloadGroupData()
        }
    }
    
    var checkedIfCommentExists = false
    var groupPostsFirstComment: [String: Comment]? { // key is the postId
        didSet {
            self.reloadGroupData()
        }
    }
    
    var groupPostsNumComments: [String: Int]? { // key is the postId
        didSet {
            self.reloadGroupData()
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
        guard let groupPosts = groupPosts else { return }
        guard groupPostsNumComments != nil else { return }
        if !checkedIfCommentExists { return } // this is needed because groupPostsFirstComment might be nil even if check
        
        
        // need to check if in group, else viewers will be nil and always return
        if groupPosts.count > 0 {
            Database.database().isInGroup(groupId: groupPosts[0].group.groupId, completion: { (inGroup) in
                if inGroup{
                    guard self.groupPostsTotalViewers != nil else { return }
                    guard self.groupPostsViewers != nil else { return }
                    DispatchQueue.main.async{ self.collectionView.reloadData() }
                }
                else {
                    DispatchQueue.main.async{ self.collectionView.reloadData()}
                }
            }) { (err) in return }
        }
        else {
            DispatchQueue.main.async{ self.collectionView.reloadData() }
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
        guard let groupMembers = groupMembers else { return }
        header.groupMembers = groupMembers
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groupPosts?.count ?? -1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MembersCell.cellId, for: indexPath) as! MembersCell
            cell.group = groupPosts?[0].group
            cell.delegate = self
            return cell
        }
        else {
            if indexPath.item-1 < groupPosts?.count ?? 0{                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedPostCell.cellId, for: indexPath) as! FeedPostCell
                cell.isScrollingVertically = isScrollingVertically
                cell.isScrolling = isScrolling
                cell.delegate = self
                cell.emptyComment = true

                guard let groupPosts = groupPosts else { return cell }
                cell.groupPost = groupPosts[indexPath.item-1]
                
                guard let groupPostsNumComments = groupPostsNumComments else { return cell }
                let postId = groupPosts[indexPath.item-1].id
                if groupPostsNumComments[postId] != nil {
                    cell.numComments = groupPostsNumComments[postId]
                    
                    self.checkedIfCommentExists = true
                    if groupPostsNumComments[postId] ?? 0 > 0 {
                        guard let groupPostsFirstComment = groupPostsFirstComment else { return cell }
    
                        if groupPostsFirstComment[postId] != nil {
                            cell.firstComment = groupPostsFirstComment[postId]
                        }
                    }
                }
                
                // this is actually fine even if it is nul because the cell is filled out anyways so ok to return it
                guard let groupPostsTotalViewers = self.groupPostsTotalViewers else { return cell }
                if groupPostsTotalViewers[postId] != nil {
                    cell.numViewsForPost = groupPostsTotalViewers[postId]
                }
                                
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
        isScrolling = false
    }
    
    //MARK: - InnerPostCellDelegate
    
    func requestPlay(for cell: FeedPostCell) {
        if !isScrolling {
            collectionView.visibleCells.forEach { cell2 in  // check if cell is still visible
                if cell2 == cell {
                    delegate?.requestPlay(for_lower: cell, for_upper: self)
                }
            }
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
