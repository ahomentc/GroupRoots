//
//  FeedGroupCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 5/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import Zoomy

protocol FeedGroupCellDelegate {
    func didTapComment(groupPost: GroupPost)
    func didTapGroup(group: Group)
    func didTapUser(user: User)
    func didTapOptions(groupPost: GroupPost)
    func didSelectUser(selectedUser: User)
    func showMoreMembers(group: Group)
    func didView(groupPost: GroupPost)
    func showViewers(viewers: [User], viewsCount: Int)
    func requestPlay(for_lower cell1: FeedPostCell, for_upper cell2: MyCell)
    func didChangeViewType(isFullscreen: Bool)
    func requestZoomCapability(for cell: FeedPostCell)
    func viewFullScreen(group: Group, indexPath: IndexPath)
}

class FeedGroupCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, FeedGroupPageCellDelegate, InnerPostCellDelegate {
    
    var firstCommentForPosts = [String: Comment]()
    var viewersForPosts = [String: [User]]()
    var numViewsForPost = [String: Int]()
    var numCommentsForPosts = [String: Int]()
    var viewedPosts = [String: Bool]()
    
    
    // extremely ugly and bad bandaid solution so will explain in detail
    // PLEASE FIX. running out of time and just want to release already
    // have a variable called "safeToScroll" that is set true after 2 seconds
    // when clicking an image to go to fullscreen view
    // if scroll while "safeToScroll" is false, it will do a collectionview reload
    // "safeToScroll" is reset when exit fullScreen or on reuse
    var safeToScroll = false
    
    var groupPosts: [GroupPost]? {
        didSet {
            self.reloadGroupData()
        }
    }
    
    var groupMembers: [User]? {
        didSet {
            self.reloadGroupData()
        }
    }
    
    var usingCachedData: Bool?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        groupMembers = nil
        groupPosts = nil
        groupPostsTotalViewers = nil
        checkedIfCommentExists = false
        groupPostsFirstComment = nil
        groupPostsNumComments = nil
        hasViewedPosts = nil
        headerCollectionView.reloadData()
        isFullScreen = false
        closeButton.isHidden = true
        pageControlSwipe.isHidden = false
        headerCollectionView.isHidden = false
        groupnameButton.setTitleColor(.black, for: .normal)
        
        self.groupnameButton.isHidden = false
        self.closeButton.isHidden = false
        
        // scroll to first page
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
        
        safeToScroll = false
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
            guard let groupPostsFirstComment = groupPostsFirstComment else { return }
            firstCommentForPosts = groupPostsFirstComment
            self.reloadGroupData()
        }
    }
    
    var groupPostsNumComments: [String: Int]? { // key is the postId
        didSet {
            guard let groupPostsNumComments = groupPostsNumComments else { return }
            numCommentsForPosts = groupPostsNumComments
            self.reloadGroupData()
        }
    }
    
    var hasViewedPosts: [String: Bool]? {
        didSet {
            guard let hasViewedPosts = hasViewedPosts else { return }
            viewedPosts = hasViewedPosts
            self.reloadGroupData()
        }
    }
        
    var maxDistanceScrolled = CGFloat(0)
    var numPicsScrolled = 1

    var headerCollectionView: UICollectionView!
    var collectionView: UICollectionView!
    var pageControlSwipe: UIPageControl!
    var currentPage = 0
    
    var isFullScreen = false
    
    var delegate: FeedGroupCellDelegate?
    
    private lazy var groupnameButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(.black, for: .normal)
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
        button.isHidden = true
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(handleCloseFullscreen), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }()

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
        guard let groupMembers = groupMembers else { return }
        guard hasViewedPosts != nil else { return }
        
        self.collectionView.reloadData() // this is causing or uncovering some problems where video is playing over itself
        self.collectionView.layoutIfNeeded()
        self.headerCollectionView.reloadData()
        
        
        // set the layout according to isFullScreen
//        if isFullScreen {
//            self.delegate?.didChangeViewType(isFullscreen: true)
//            self.collectionView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
//        }
//        else {
//            self.delegate?.didChangeViewType(isFullscreen: false)
//            self.collectionView.frame = CGRect(x: 0, y: 220, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 220)
//        }
        
        if groupPosts.count > 0 {
            let group = groupPosts[0].group
            if group.groupname == "" {
                var usernames = ""
                if groupMembers.count == 1 {
                    usernames = groupMembers[0].username
                }
                else if groupMembers.count == 2 {
                    usernames = groupMembers[0].username + " & " + groupMembers[1].username
                }
                else {
                    usernames = groupMembers[0].username + " & " + groupMembers[1].username + " & " + groupMembers[2].username
                }
                if usernames.count > 16 {
                    usernames = String(usernames.prefix(16)) // keep only the first 16 characters
                    usernames = usernames + "..."
                }
//                groupnameButton.setTitle(usernames, for: .normal)
                let lockImage = #imageLiteral(resourceName: "lock")
                let lockIcon = NSTextAttachment()
                lockIcon.image = lockImage
                let lockIconString = NSAttributedString(attachment: lockIcon)

                let balanceFontSize: CGFloat = 20
                let balanceFont = UIFont.boldSystemFont(ofSize: balanceFontSize)

                //Setting up font and the baseline offset of the string, so that it will be centered
                let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, .foregroundColor: UIColor.black, .baselineOffset: (lockImage.size.height - balanceFontSize) / 2 - balanceFont.descender / 2]
                let balanceString = NSMutableAttributedString(string: usernames + " ", attributes: balanceAttr)

                if group.isPrivate ?? false {
                    balanceString.append(lockIconString)
                }
                self.groupnameButton.setAttributedTitle(balanceString, for: .normal)
            }
            else {
                
                let lockImage = #imageLiteral(resourceName: "lock")
                let lockIcon = NSTextAttachment()
                lockIcon.image = lockImage
                let lockIconString = NSAttributedString(attachment: lockIcon)

                let balanceFontSize: CGFloat = 20
                let balanceFont = UIFont.boldSystemFont(ofSize: balanceFontSize)

                //Setting up font and the baseline offset of the string, so that it will be centered
                let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, .foregroundColor: UIColor.black, .baselineOffset: (lockImage.size.height - balanceFontSize) / 2 - balanceFont.descender / 2]
                let balanceString = NSMutableAttributedString(string: group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") + " ", attributes: balanceAttr)

                if group.isPrivate ?? false {
                    balanceString.append(lockIconString)
                }
                self.groupnameButton.setAttributedTitle(balanceString, for: .normal)
            }
        }
        groupnameButton.setTitleColor(.black, for: .normal)
    }
    
    func setupViews() {
        let header_layout = UICollectionViewFlowLayout()
        header_layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        header_layout.itemSize = CGSize(width: 60, height: 60)
        header_layout.minimumLineSpacing = CGFloat(20)
        
        headerCollectionView = UICollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height/10, width: UIScreen.main.bounds.width, height: 120), collectionViewLayout: header_layout)
        headerCollectionView.delegate = self
        headerCollectionView.dataSource = self
        headerCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        headerCollectionView.register(GroupProfileHeaderCell.self, forCellWithReuseIdentifier: GroupProfileHeaderCell.cellId)
        headerCollectionView.register(MemberHeaderCell.self, forCellWithReuseIdentifier: MemberHeaderCell.cellId)
        headerCollectionView.showsHorizontalScrollIndicator = false
        headerCollectionView.isUserInteractionEnabled = true
        headerCollectionView.allowsSelection = true
        headerCollectionView.backgroundColor = UIColor.clear
        headerCollectionView.showsHorizontalScrollIndicator = false
        insertSubview(headerCollectionView, at: 10)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.minimumLineSpacing = CGFloat(0)
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 220, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 220), collectionViewLayout: layout)
//        CGRect(x: 0, y: 220, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 220)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(FeedPostCell.self, forCellWithReuseIdentifier: FeedPostCell.cellId)
        collectionView?.register(FeedGroupPageCell.self, forCellWithReuseIdentifier: FeedGroupPageCell.cellId)
        collectionView?.register(EmptyFeedPostCell.self, forCellWithReuseIdentifier: EmptyFeedPostCell.cellId)
        collectionView?.register(MembersCell.self, forCellWithReuseIdentifier: MembersCell.cellId)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        insertSubview(collectionView, at: 5)
        
        insertSubview(groupnameButton, at: 6)
        groupnameButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: UIScreen.main.bounds.height/3.5, paddingLeft: 20)
        groupnameButton.backgroundColor = .clear
        groupnameButton.isUserInteractionEnabled = true
        
        insertSubview(closeButton, at: 7)
        closeButton.anchor(top: topAnchor, right: rightAnchor, paddingTop: UIScreen.main.bounds.height/16, paddingRight: 20)
        
//        pageControlSwipe = UIPageControl()
        pageControlSwipe = UIPageControl(frame: CGRect(x: 0, y: UIScreen.main.bounds.height - UIScreen.main.bounds.height/10, width: UIScreen.main.bounds.width, height: 10))
        pageControlSwipe.pageIndicatorTintColor = UIColor.lightGray
        pageControlSwipe.currentPageIndicatorTintColor = UIColor.darkGray
        self.addSubview(pageControlSwipe)
//        pageControlSwipe.anchor(top: collectionView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 20, height: 10)
        
        self.groupnameButton.isHidden = false
        self.closeButton.isHidden = false
        
        self.backgroundColor = .white
          
//        Last resort
//        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
//            self.reloadGroupData()
//        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCloseFullscreen), name: NSNotification.Name(rawValue: "closeFullScreen"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.closeFullScreenWithRow(_:)), name: NSNotification.Name(rawValue: "closeFullScreenWithRow"), object: nil)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView { // collectionview for pictures with page cell
            if groupPosts?.count ?? 0 > 0 {
                if isFullScreen {
                    return groupPosts?.count ?? 0
                }
                else {
                    let count = Int(ceil(Double(groupPosts?.count ?? 0)/4))
                    if count < 5 {
                        self.pageControlSwipe.numberOfPages = count
                    } else {
                        self.pageControlSwipe.numberOfPages = 5
                    }
                    if count == 1 {
                        self.pageControlSwipe.isHidden = true
                    }
                    else {
                        self.pageControlSwipe.isHidden = false
                    }
                    return count
                }
            }
            else {
                return 0
            }
        }
        else {
            return (groupMembers?.count ?? -1) + 1
        }
    }
    
    // when click on a picture box, take to LargeImageViewController?
    // Thing is that it'd be nice to just scroll down to get to next post instead of clicking back and then scrolling down
    // so maybe just have an X instead to exit full screen view and don't use LargeImageViewController
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView { // collectionview for pictures with page cell
            if isFullScreen {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedPostCell.cellId, for: indexPath) as! FeedPostCell
//                cell.isScrolling = isScrolling
                cell.delegate = self
                cell.emptyComment = true
                cell.groupPost = groupPosts?[indexPath.item]
                let post_id = groupPosts?[indexPath.item].id ?? ""
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
                // only show 4 pictures in page
                let startPos = indexPath.row * 4
                var endPos = indexPath.row * 4 + 4
                
                let groupPostsCount = (groupPosts ?? []).count
                if endPos > groupPostsCount {
                    endPos = groupPostsCount
                }
                
                if endPos == 0 {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedGroupPageCell.cellId, for: indexPath) as! FeedGroupPageCell
                    cell.delegate = self
                    cell.tag = indexPath.row
                    return cell
                }
                
                let slicedArr = (groupPosts ?? [])[startPos..<endPos]
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedGroupPageCell.cellId, for: indexPath) as! FeedGroupPageCell
                cell.groupPosts = Array(slicedArr)
                cell.viewedPosts = viewedPosts
                cell.delegate = self
                cell.tag = indexPath.row
                return cell
            }
        }
        else { // collectionview with group members
            let group = groupPosts?[0].group
            if group?.groupProfileImageUrl != nil && group?.groupProfileImageUrl != "" {
                if indexPath.item == 0 {
                    let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: GroupProfileHeaderCell.cellId, for: indexPath) as! GroupProfileHeaderCell
                    cell.profileImageUrl = group?.groupProfileImageUrl
                    cell.groupname = group?.groupname
                    if groupMembers?.count ?? 0 > 0 {
                        if groupMembers?[0].profileImageUrl != nil {
                            cell.userOneImageUrl = groupMembers?[0].profileImageUrl
                        }
                        else {
                            cell.userOneImageUrl = ""
                        }
                    }
                    else {
                        cell.userOneImageUrl = ""
                    }
                    
                    cell.layer.backgroundColor = UIColor.clear.cgColor
                    cell.layer.shadowColor = UIColor.black.cgColor
                    cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                    cell.layer.shadowOpacity = 0.2
                    cell.layer.shadowRadius = 4.0
                    return cell
                }
                else {
                    let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: MemberHeaderCell.cellId, for: indexPath) as! MemberHeaderCell
                    cell.user = groupMembers?[indexPath.item-1]
                    cell.group_has_profile_image = true
                    cell.layer.backgroundColor = UIColor.clear.cgColor
                    cell.layer.shadowColor = UIColor.black.cgColor
                    cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                    cell.layer.shadowOpacity = 0.2
                    cell.layer.shadowRadius = 2.0
                    return cell
                }
            }
            else {
                if indexPath.item == 0 {
                    // modify this to be two small user cells
                    let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: GroupProfileHeaderCell.cellId, for: indexPath) as! GroupProfileHeaderCell
                    cell.groupname = group?.groupname
//                    cell.group = group
                    if groupMembers?.count ?? 0 > 0 {
                        if groupMembers?[0].profileImageUrl != nil {
                            cell.userOneImageUrl = groupMembers?[0].profileImageUrl
                        }
                        else {
                            cell.userOneImageUrl = ""
                        }
                    }
                    else {
                        cell.userOneImageUrl = ""
                    }
                    if groupMembers?.count ?? 0 > 1 {
                        if groupMembers?[1].profileImageUrl != nil {
                            cell.userTwoImageUrl = groupMembers?[1].profileImageUrl
                        }
                        else {
                            cell.userTwoImageUrl = ""
                        }
                    }
                    else {
                        cell.userTwoImageUrl = ""
                    }
                    cell.layer.backgroundColor = UIColor.clear.cgColor
                    cell.layer.shadowColor = UIColor.black.cgColor
                    cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                    cell.layer.shadowOpacity = 0.2
                    cell.layer.shadowRadius = 4.0
                    return cell
                }
                else {
                    let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: MemberHeaderCell.cellId, for: indexPath) as! MemberHeaderCell
                    cell.user = groupMembers?[indexPath.item-1]
                    cell.group_has_profile_image = false
                    cell.layer.backgroundColor = UIColor.clear.cgColor
                    cell.layer.shadowColor = UIColor.black.cgColor
                    cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                    cell.layer.shadowOpacity = 0.2
                    cell.layer.shadowRadius = 2.0
                    return cell
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == headerCollectionView {
            if indexPath.item == 0 {
                let group = groupPosts?[0].group
                if group != nil {
                    delegate?.didTapGroup(group: group!)
                }
            }
            else {
                let user = groupMembers?[indexPath.item-1]
                if user != nil {
                    delegate?.didTapUser(user: user!)
                }
            }
        }
    }
    
    func requestZoomCapability(for cell: FeedPostCell) {
        self.delegate?.requestZoomCapability(for: cell)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let pageWidth = scrollView.frame.width
        self.currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        self.pageControlSwipe.currentPage = self.currentPage % 5
    }

    @objc func handleGroupTap(){
        guard let groupPosts = groupPosts else { return }
        didTapGroup(group: groupPosts[0].group)
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
    
    //MARK: - FeedMembersCellDelegate
    func selectedMember(selectedUser: User) {
        delegate?.didSelectUser(selectedUser: selectedUser)
    }
    
    func showMoreMembers() {
        guard let group = groupPosts?[0].group else { return }
        delegate?.showMoreMembers(group: group)
    }
    
    func didTapPostCell(for_cell cell: FeedGroupPageCell, cell_number: Int) {
        guard let group = groupPosts?[0].group else { return }
        let cell_tapped_index = (4 * cell.tag) + cell_number
        delegate?.viewFullScreen(group: group, indexPath: IndexPath(item: cell_tapped_index, section: 0))
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
        isFullScreen = true
        
        //---
        
//        let cell_tapped_index = (4 * cell.tag) + cell_number
//        if isFullScreen == false {
//            // still doesn't work... but if this isn't here then for fullscreen it would just be at the index of the page.
//            // so rn it just loads full screen of index 0 first, which is a video which breaks it.
//            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
//            isFullScreen = true
//            self.delegate?.didChangeViewType(isFullscreen: true)
//            reloadGroupData()
//            NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
//            self.collectionView.scrollToItem(at: IndexPath(item: cell_tapped_index, section: 0), at: .centeredHorizontally, animated: false)
//
//            // band aid solution to videourl still being there problem which causes picture to disappear
//            // only do this if not a video
//
//            Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { timer in
//                self.safeToScroll = true
//            })
//
//            closeButton.isHidden = false
//            pageControlSwipe.isHidden = true
//            headerCollectionView.isHidden = true
//            let lockImage = #imageLiteral(resourceName: "lock")
//            let balanceFontSize: CGFloat = 20
//            let balanceFont = UIFont.boldSystemFont(ofSize: balanceFontSize)
//            let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, .foregroundColor: UIColor.white, .baselineOffset: (lockImage.size.height - balanceFontSize) / 2 - balanceFont.descender / 2]
//            let balanceString = NSMutableAttributedString(string: self.groupnameButton.titleLabel?.attributedText?.string ?? "", attributes: balanceAttr)
//            self.groupnameButton.setAttributedTitle(balanceString, for: .normal)
//        }
    }
    
    func goToImage(for cell: FeedPostCell, isRight: Bool) {
        
    }
    
    func requestPlay(for cell: FeedPostCell) {
//        guard let usingCachedData = usingCachedData else { return }
//        if !isScrolling && !usingCachedData  {
//            collectionView.visibleCells.forEach { cell2 in  // check if cell is still visible
//                if cell2 == cell {
//                    delegate?.requestPlay(for_lower: cell, for_upper: self)
//                }
//            }
//        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            self.stoppedScrolling()
        }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.stoppedScrolling()
        }
    }

    func stoppedScrolling() {
        // set current post as viewed
        if isFullScreen {
            if !safeToScroll {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { timer in
                    self.collectionView.reloadData()
//                    self.groupnameButton.setTitleColor(.white, for: .normal)

                    let lockImage = #imageLiteral(resourceName: "lock")
                    let balanceFontSize: CGFloat = 20
                    let balanceFont = UIFont.boldSystemFont(ofSize: balanceFontSize)
                    let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, .foregroundColor: UIColor.white, .baselineOffset: (lockImage.size.height - balanceFontSize) / 2 - balanceFont.descender / 2]
                    let balanceString = NSMutableAttributedString(string: self.groupnameButton.titleLabel?.attributedText?.string ?? "", attributes: balanceAttr)
                    self.groupnameButton.setAttributedTitle(balanceString, for: .normal)
                })
            }
            
            collectionView.visibleCells.forEach { cell in
                if cell is FeedPostCell {
                    let groupPost = (cell as! FeedPostCell).groupPost
                    if groupPost != nil {
                        delegate?.didView(groupPost: groupPost!)
                    }
                }
            }
        }
    }
    
    @objc private func closeFullScreenWithRow(_ notification: NSNotification){
        guard let groupPosts = groupPosts else { return }
        if groupPosts.count == 0 { return }
        let group = groupPosts[0].group
        
        if collectionView.visibleCells.count == 0 { return }
        
        collectionView.visibleCells.forEach { cell in // pause video
            if cell is FeedPostCell {
                (cell as! FeedPostCell).player.pause()
            }
        }
        
        isFullScreen = false
        self.delegate?.didChangeViewType(isFullscreen: false)
        closeButton.isHidden = true
        pageControlSwipe.isHidden = false
        headerCollectionView.isHidden = false
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
        safeToScroll = false
        
        if let dict = notification.userInfo as NSDictionary? {
            if let indexPathRow = dict["indexPathRow"] as? Int, let animatedScroll = dict["animatedScroll"] as? Bool, let groupId = dict["groupId"] as? String{
                let page = Int(floor(Double(indexPathRow) / 4))
                if groupId == group.groupId {
                    collectionView.scrollToItem(at: IndexPath(item: page, section: 0), at: .centeredHorizontally, animated: animatedScroll)
                }
            }
        }
    }
    
    @objc func handleCloseFullscreen(){
        if isFullScreen {
            if collectionView.visibleCells.count == 0 { return }
            
            // pause video
            collectionView.visibleCells.forEach { cell in
                if cell is FeedPostCell {
                    (cell as! FeedPostCell).player.pause()
                }
            }
            
            isFullScreen = false
            self.delegate?.didChangeViewType(isFullscreen: false)
//            reloadGroupData()
            closeButton.isHidden = true
            pageControlSwipe.isHidden = false
            headerCollectionView.isHidden = false
            NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
            safeToScroll = false
        }
    }
    
    func pauseVisibleVideo() {
        collectionView.visibleCells.forEach { cell in
            if cell.isKind(of: FeedPostCell.self){
                (cell as! FeedPostCell).player.pause()
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.pauseVisibleVideo()
    }
}

extension FeedGroupCell: UICollectionViewDelegateFlowLayout {
    
    private func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlowLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.collectionView {
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 175)
        }
        else {
            return CGSize(width: 60, height: 60)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == self.collectionView {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        else {
            return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
//            if groupMembers?.count == 1 {
//                let totalCellWidth = 60 * collectionView.numberOfItems(inSection: 0)
//                let totalSpacingWidth = 10 * (collectionView.numberOfItems(inSection: 0) - 1)
//
//                let leftInset = (collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
//                let rightInset = leftInset
//
//                return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
//            }
//            else if groupMembers?.count == 2 {
//                let totalCellWidth = 60 * collectionView.numberOfItems(inSection: 0)
//                let totalSpacingWidth = 20 * (collectionView.numberOfItems(inSection: 0) - 1)
//
//                let leftInset = (collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
//                let rightInset = leftInset
//
//                return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
//            }
//            else {
//                return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
//            }
        }
    }
}
