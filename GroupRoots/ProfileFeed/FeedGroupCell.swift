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
    func viewFullScreen(group: Group, groupPostId: String)
    func postToGroup(group: Group)
}

class FeedGroupCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, FeedGroupPageCellDelegate, InnerPostCellDelegate {
    
    var firstCommentForPosts = [String: Comment]()
    var viewersForPosts = [String: [User]]()
    var numViewsForPost = [String: Int]()
    var numCommentsForPosts = [String: Int]()
    var viewedPosts = [String: Bool]()
    var isInGroup: Bool = false
    var group: Group?
    
    static var cellId = "feedGroupCellId"
    
    
    // extremely ugly and bad bandaid solution so will explain in detail
    // PLEASE FIX. running out of time and just want to release already
    // have a variable called "safeToScroll" that is set true after 2 seconds
    // when clicking an image to go to fullscreen view
    // if scroll while "safeToScroll" is false, it will do a collectionview reload
    // "safeToScroll" is reset when exit fullScreen or on reuse
    var safeToScroll = false
    
    var groupPosts: [GroupPost]? {
        didSet {
            guard groupPosts != nil else { return }
            // add empty to grouposts to the first posts
            let remainder = self.groupPosts!.count % 4
            let toAdd = 4 - remainder
            if toAdd > 0 && toAdd < 4 {
                for _ in 1...toAdd {
                    let emptyGroupPost = GroupPost(group: Group(groupId: "", dictionary: Dictionary()), user: nil, dictionary: Dictionary())
                    self.groupPosts!.insert(emptyGroupPost, at: 0)
                }
            }
            self.reloadGroupData()
        }
    }
    
    var groupMembers: [User]? {
        didSet {
            self.reloadGroupData()
        }
    }
    
    var usingCachedData: Bool?
    
    var collectionViewOffset = CGPoint(x: 0, y: 0)
    var hasDisappeared = false
    
    var hasShownCollectionView = false
    
    override func prepareForReuse() {
        print("reusing")
        super.prepareForReuse()
        groupMembers = nil
        groupPosts = nil
        groupPostsTotalViewers = nil
        checkedIfCommentExists = false
        groupPostsFirstComment = nil
        groupPostsNumComments = nil
        hasViewedPosts = nil
        headerCollectionView.reloadData()
        pageCollectionView.reloadData()
        isFullScreen = false
        closeButton.isHidden = true
        headerCollectionView.isHidden = false
        groupnameButton.setTitleColor(.black, for: .normal)
        collectionViewOffset = CGPoint(x: 0, y: 0)
        
        self.groupnameButton.isHidden = false
        self.closeButton.isHidden = false
        
        self.hasShownCollectionView = false
        
//        collectionView.alpha = 0 // added for pre-scroll
        
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
    
    var lastCommentSet = false
    var groupPostsLastComment: [String: Comment]? { // key is the postId
        didSet {
            self.lastCommentSet = true
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
    
    let pageSelectorImage: UIImageView = {
        let img = UIImageView()
        img.image = #imageLiteral(resourceName: "pageSelector")
        return img
    }()
        
    var maxDistanceScrolled = CGFloat(0)
    var numPicsScrolled = 1

    var headerCollectionView: UICollectionView!
    var collectionView: UICollectionView!
    var pageCollectionView: UICollectionView!
    
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
    
    let lastPostedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .lightGray
        label.textAlignment = .right
        label.text = ""
        return label
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
        guard let group = group else { return }
        guard let groupPosts = groupPosts else { return }
        guard groupPostsNumComments != nil else { return }
        guard let groupMembers = groupMembers else { return }
        guard hasViewedPosts != nil else { return }
        if !lastCommentSet { return }
//        guard groupPostsLastComment != nil else { return }
        
        self.collectionView.reloadData() // this is causing or uncovering some problems where video is playing over itself
        self.collectionView.layoutIfNeeded()
        self.headerCollectionView.reloadData()
        self.pageCollectionView.reloadData()
        
        self.pageCollectionView.performBatchUpdates(nil, completion: {
            (result) in
            let groupPostsCount = groupPosts.count
            let count = Int(ceil(Double(groupPostsCount)/4))
            self.pageCollectionView.scrollToItem(at: IndexPath(item: count + 2, section: 0), at: .centeredHorizontally, animated: false)
        })
        
        if groupPosts.count > 0 {
            
            // this doesn't work because groupPosts[0] is an empty post as padding
            let timeAgoDisplay = groupPosts[0].creationDate.timeAgoDisplay()
            lastPostedLabel.text = "Updated " + timeAgoDisplay
            
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
        else {
            lastPostedLabel.text = ""
        }
        groupnameButton.setTitleColor(.black, for: .normal)
    }
    
    func setupViews() {
        let header_layout = UICollectionViewFlowLayout()
        header_layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        header_layout.itemSize = CGSize(width: 60, height: 60)
        header_layout.minimumLineSpacing = CGFloat(20)
        
        headerCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 120), collectionViewLayout: header_layout)
        headerCollectionView.delegate = self
        headerCollectionView.dataSource = self
        headerCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        headerCollectionView.register(GroupProfileHeaderCell.self, forCellWithReuseIdentifier: GroupProfileHeaderCell.cellId)
        headerCollectionView.register(MemberHeaderCell.self, forCellWithReuseIdentifier: MemberHeaderCell.cellId)
        headerCollectionView.register(CreatePostHeaderCell.self, forCellWithReuseIdentifier: CreatePostHeaderCell.cellId)
        headerCollectionView.showsHorizontalScrollIndicator = false
        headerCollectionView.isUserInteractionEnabled = true
        headerCollectionView.allowsSelection = true
        headerCollectionView.backgroundColor = UIColor.clear
        headerCollectionView.showsHorizontalScrollIndicator = false
        contentView.insertSubview(headerCollectionView, at: 10)
        
        let pageHeight = self.frame.width - 32
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: pageHeight )
        layout.minimumLineSpacing = CGFloat(0)

        
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 160, width: UIScreen.main.bounds.width, height: pageHeight), collectionViewLayout: layout)
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
        collectionView?.semanticContentAttribute = .forceRightToLeft
//        collectionView.alpha = 0 // added for pre-scroll
        contentView.insertSubview(collectionView, at: 5)
                
        let page_layout = UICollectionViewFlowLayout()
        page_layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        page_layout.itemSize = CGSize(width: 50, height: 50)
        page_layout.minimumLineSpacing = CGFloat(20)
        
        pageCollectionView = UICollectionView(frame: CGRect(x: 0, y: 90 + UIScreen.main.bounds.width - 30 + UIScreen.main.bounds.height/8, width: UIScreen.main.bounds.width, height: 50), collectionViewLayout: page_layout)
        pageCollectionView.delegate = self
        pageCollectionView.dataSource = self
        pageCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        pageCollectionView?.register(PageNumberCell.self, forCellWithReuseIdentifier: PageNumberCell.cellId)
        pageCollectionView.showsHorizontalScrollIndicator = false
        pageCollectionView.isUserInteractionEnabled = true
        pageCollectionView.allowsSelection = true
        pageCollectionView.backgroundColor = UIColor.clear
        pageCollectionView.showsHorizontalScrollIndicator = false
        contentView.insertSubview(pageCollectionView, at: 10)
        
        let lineSeparatorView = UIView()
        lineSeparatorView.backgroundColor = UIColor.init(white: 0.6, alpha: 1)
        addSubview(lineSeparatorView)
        lineSeparatorView.anchor(top: pageCollectionView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: -5, paddingLeft: (UIScreen.main.bounds.width-50)/2, paddingRight: (UIScreen.main.bounds.width-50)/2, height: 1.5)
        
//        contentView.addSubview(lastPostedLabel)
//        lastPostedLabel.anchor(top: topAnchor, right: rightAnchor, paddingTop: 65 + UIScreen.main.bounds.height/8, paddingRight: 20)

        contentView.insertSubview(groupnameButton, at: 6)
        groupnameButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: 85 + UIScreen.main.bounds.height / 14 , paddingLeft: 20, height: 10)
        groupnameButton.backgroundColor = .clear
        groupnameButton.isUserInteractionEnabled = true
        
        self.groupnameButton.isHidden = false
        self.closeButton.isHidden = false
        
        self.backgroundColor = UIColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCloseFullscreen), name: NSNotification.Name(rawValue: "closeFullScreen"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.closeFullScreenWithRow(_:)), name: NSNotification.Name(rawValue: "closeFullScreenWithRow"), object: nil)
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView { // collectionview for pictures with page cell
            if groupPosts?.count ?? 0 > 0 {
//                let remainder = groupPosts!.count % 4
                let groupPostsCount = groupPosts!.count
                let count = Int(ceil(Double(groupPostsCount)/4))
                return count
            }
            else {
                return 0
            }
        }
        else if collectionView == self.headerCollectionView {
            if self.isInGroup {
                return (groupMembers?.count ?? -1) + 2 // extra space for share button
            }
            return (groupMembers?.count ?? -1) + 1
        }
        else {
            if groupPosts?.count ?? 0 > 0 {
                let groupPostsCount = groupPosts!.count
                let count = Int(ceil(Double(groupPostsCount)/4))
                return count + 4 // have the 4 for padding on the left and right
            }
            else {
                return 0
            }
        }
    }
    
    // when click on a picture box, take to LargeImageViewController?
    // Thing is that it'd be nice to just scroll down to get to next post instead of clicking back and then scrolling down
    // so maybe just have an X instead to exit full screen view and don't use LargeImageViewController
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView { // collectionview for pictures with page cell
            
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
            
            // get the groupPosts in slicedArr
            var lastCommentForPosts = [String: Comment]()
            if groupPostsLastComment != nil {
                for groupPost in slicedArr {
                    lastCommentForPosts[groupPost.id] = groupPostsLastComment![groupPost.id]
                }
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedGroupPageCell.cellId, for: indexPath) as! FeedGroupPageCell
            cell.groupPosts = Array(slicedArr).reversed()
            cell.viewedPosts = viewedPosts
            cell.lastCommentForPosts = lastCommentForPosts
            cell.delegate = self
            cell.tag = indexPath.row
            return cell
        }
        else if collectionView == self.headerCollectionView { // collectionview with group members
            let group = groupPosts?[3].group
            if group?.groupProfileImageUrl != nil && group?.groupProfileImageUrl != "" {
                if indexPath.item == 0 && self.isInGroup {
                    let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: CreatePostHeaderCell.cellId, for: indexPath) as! CreatePostHeaderCell
                    cell.layer.backgroundColor = UIColor.clear.cgColor
                    cell.layer.shadowColor = UIColor.black.cgColor
                    cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                    cell.layer.shadowOpacity = 0.2
                    cell.layer.shadowRadius = 2.0
                    return cell
                }
                else if  indexPath.item == 0 || (indexPath.item == 1 && self.isInGroup) {
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
                    if self.isInGroup {
                        cell.user = groupMembers?[indexPath.item-2]
                    }
                    else {
                        cell.user = groupMembers?[indexPath.item-1]
                    }
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
                if indexPath.item == 0 && self.isInGroup {
                    let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: CreatePostHeaderCell.cellId, for: indexPath) as! CreatePostHeaderCell
                    cell.layer.backgroundColor = UIColor.clear.cgColor
                    cell.layer.shadowColor = UIColor.black.cgColor
                    cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                    cell.layer.shadowOpacity = 0.2
                    cell.layer.shadowRadius = 2.0
                    return cell
                }
                else if  indexPath.item == 0 || (indexPath.item == 1 && self.isInGroup) {
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
                    if self.isInGroup {
                        cell.user = groupMembers?[indexPath.item-2]
                    }
                    else {
                        cell.user = groupMembers?[indexPath.item-1]
                    }
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
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageNumberCell.cellId, for: indexPath) as! PageNumberCell
            if self.groupPosts != nil {
                
                let groupPostsCount = groupPosts!.count
                let count = Int(ceil(Double(groupPostsCount)/4))
                
                if indexPath.item < 2 {
                    cell.backgroundColor = .clear
                }
                else if indexPath.item > count + 1 {
                    cell.backgroundColor = .clear
                }
                else {
                    cell.backgroundColor = .clear
                    cell.number = (indexPath.item - 2) + 1
                }
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == headerCollectionView {
            if indexPath.item == 0 && self.isInGroup {
                let group = groupPosts?[3].group
                if group != nil {
                    self.delegate?.postToGroup(group: group!)
                }
            }
            else if  indexPath.item == 0 || (indexPath.item == 1 && self.isInGroup) {
                let group = groupPosts?[3].group
                if group != nil {
                    delegate?.didTapGroup(group: group!)
                }
            }
            else {
                if self.isInGroup {
                    let user = groupMembers?[indexPath.item-2]
                    if user != nil {
                        delegate?.didTapUser(user: user!)
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
        else if collectionView == pageCollectionView && groupPosts != nil {
            let groupPostsCount = groupPosts!.count
            let count = Int(ceil(Double(groupPostsCount)/4))
            
            if !(indexPath.item < 2 || indexPath.item > count + 1) {
                let page_index = indexPath.item - 2
                let index = count - page_index - 1
                let rect = self.collectionView.layoutAttributesForItem(at: IndexPath(item: index, section: 0))?.frame
                self.collectionView.scrollRectToVisible(rect!, animated: true)
                self.pageCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
    
    func showCollectionView() {
        if !hasShownCollectionView{
            self.collectionView.alpha = 0
            Timer.scheduledTimer(withTimeInterval: 0.005, repeats: false) { timer in
//                self.collectionView.alpha = 1
                self.collectionView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                UIView.animate(withDuration: 0.05, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                    self.collectionView.alpha = 1
                }, completion: nil)
                UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                    self.collectionView.transform = CGAffineTransform.identity
                }, completion: nil)
            }
        }
        else {
            self.collectionView.alpha = 1
            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                self.collectionView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }, completion: nil)
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                    self.collectionView.transform = CGAffineTransform.identity
                }, completion: nil)
            }
        }
//        hasShownCollectionView = true
        
        
    }
    
    func requestZoomCapability(for cell: FeedPostCell) {
        self.delegate?.requestZoomCapability(for: cell)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
    }

    @objc func handleGroupTap(){
        guard let group = group else { return }
        guard let groupPosts = groupPosts else { return }
        didTapGroup(group: group)
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
        guard let group = group else { return }
        delegate?.showMoreMembers(group: group)
    }
    
//    func didTapPostCell(for_cell cell: FeedGroupPageCell, cell_number: Int) {
//        guard let group = groupPosts?[0].group else { return }
//        let cell_tapped_index = (4 * cell.tag) + cell_number
//
//        self.collectionViewOffset = self.collectionView.contentOffset;
//        self.hasDisappeared = true
//
//        delegate?.viewFullScreen(group: group, indexPath: IndexPath(item: cell_tapped_index, section: 0))
//        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
//    }
    
    func didTapPostCell(groupPostId: String) {
        guard let group = group else { return }
        self.hasDisappeared = true
        self.collectionViewOffset = self.collectionView.contentOffset;
        delegate?.viewFullScreen(group: group, groupPostId: groupPostId)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
    }
    
    func goToImage(for cell: FeedPostCell, isRight: Bool) {
    }
    
    func requestPlay(for cell: FeedPostCell) {
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            self.stoppedScrolling(scrollView)
        }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.stoppedScrolling(scrollView)
        }
    }

    func stoppedScrolling(_ scrollView: UIScrollView) {
        guard let groupPosts = groupPosts else { return }
        let groupPostsCount = groupPosts.count
        let count = Int(ceil(Double(groupPostsCount)/4))
        
        if scrollView == self.pageCollectionView {
            self.pageCollectionView.scrollToNearestVisibleCollectionViewCell()
            let page_index = self.pageCollectionView.getNearestVisibleCollectionViewCell() - 2
            let index = count - page_index - 1
            let rect = self.collectionView.layoutAttributesForItem(at: IndexPath(item: index, section: 0))?.frame
            self.collectionView.scrollRectToVisible(rect!, animated: true)
        }
        else if scrollView == self.collectionView {
            let index = count - self.collectionView.getNearestVisibleCollectionViewCell() - 1
            self.pageCollectionView.scrollToItem(at: IndexPath(item: index + 2, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    @objc private func closeFullScreenWithRow(_ notification: NSNotification){
        
        guard let groupPosts = groupPosts else { return }
        if groupPosts.count == 0 { return }
        
        if collectionView.visibleCells.count == 0 { return }
        
        collectionView.visibleCells.forEach { cell in // pause video
            if cell is FeedPostCell {
                (cell as! FeedPostCell).player.pause()
            }
        }
        
        closeButton.isHidden = true
        headerCollectionView.isHidden = false
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
        safeToScroll = false
        
        if self.hasDisappeared {
            self.collectionView.contentOffset = self.collectionViewOffset
            self.hasDisappeared = false
        }
    }
    
    @objc func handleCloseFullscreen(){
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
            let pageHeight = self.frame.width - 32
            return CGSize(width: UIScreen.main.bounds.width, height: pageHeight)
        }
        else if collectionView == self.headerCollectionView {
            return CGSize(width: 60, height: 60)
        }
        else {
            return CGSize(width: 50, height: 50)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == self.collectionView {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        else if collectionView == self.headerCollectionView {
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
        else {
            return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        }
    }
}
