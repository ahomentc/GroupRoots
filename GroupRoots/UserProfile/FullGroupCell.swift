//
//  FullGroupCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 9/29/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol FullGroupCellDelegate {
    func didTapGroup(group: Group)
    func didTapUser(user: User)
    func didTapGroupPost(groupPost: GroupPost, index: Int)
    func postToGroup(group: Group)
}

class FullGroupCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var group: Group? {
        didSet {
//            configureGroupCell()
            configureGroupHeader()
        }
    }
    
    var user: User? {
        didSet {
            configureGroupCell()
        }
    }
    
    var isInGroup: Bool? {
        didSet {
            configureGroupCell()
        }
    }
    
    var groupPosts: [GroupPost]? {
        didSet {
            configureGroupCell()
        }
    }
    
    var groupMembers: [User]? {
        didSet {
            configureGroupHeader()
//            configureGroupCell()
        }
    }
    
    var canView: Bool? {
        didSet {
            configureGroupCell()
        }
    }
    
    var isInFollowPending: Bool? {
        didSet {
            configureGroupCell()
        }
    }
    
    var isGroupHidden: Bool? {
        didSet {
            configureGroupCell()
        }
    }
    
    var delegate: FullGroupCellDelegate?
    
    
    private let hiddenIcon: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "hide_eye").withRenderingMode(.alwaysOriginal), for: .normal)
        button.isHidden = true
        return button
    }()
    
    private lazy var groupnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .left
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleGroupTap))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
//        label.isUserInteractionEnabled = false
        // ^^^ is false because the background to it (the whole cell) takes you to group
        return label
    }()
    
    private let noPostsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        label.text = "No posts yet."
        label.numberOfLines = 2
        label.isHidden = true
        label.textColor = .lightGray
        return label
    }()

    private let privateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.isHidden = true
        label.textColor = .lightGray
        return label
    }()
    
    private lazy var subscribeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleSubscribeTap), for: .touchUpInside)
        button.setTitle("Follow", for: .normal)
        button.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        button.backgroundColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.isUserInteractionEnabled = true
        button.isHidden = true
        return button
    }()
    
    private lazy var emptyPostButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(postToGroup), for: .touchUpInside)
        button.setTitle("Post", for: .normal)
        button.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        button.backgroundColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.isUserInteractionEnabled = true
        button.isHidden = true
        return button
    }()
    
    var headerCollectionView: UICollectionView!
    var collectionView: UICollectionView!
    
    static var cellId = "fullGroupCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.backgroundColor = UIColor(white: 0, alpha: 0)
        self.group = nil
        
        self.groupnameLabel.text = ""
        let emptyString = NSMutableAttributedString(string:"")
        self.groupnameLabel.attributedText = emptyString
        
        self.groupPosts = nil
        self.groupMembers = nil
        self.isGroupHidden = nil
        self.isInFollowPending = nil
        self.canView = nil
        self.isInGroup = nil
        
        collectionView.isHidden = false
        noPostsLabel.isHidden = true
        privateLabel.isHidden = true
        subscribeButton.isHidden = true
        emptyPostButton.isHidden = true
        hiddenIcon.isHidden = true
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: false)
    }
    
    private func sharedInit() {
        self.backgroundColor = UIColor(white: 0, alpha: 0)
                        
        contentView.addSubview(hiddenIcon)
        hiddenIcon.anchor(top: topAnchor, right: rightAnchor, paddingTop: 6, paddingRight: 12)
        
        contentView.addSubview(groupnameLabel)
        groupnameLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 125, paddingLeft: 22)
        
        contentView.addSubview(noPostsLabel)
        noPostsLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 170)
        
        contentView.addSubview(privateLabel)
        privateLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 170)
        
        contentView.addSubview(subscribeButton)
        subscribeButton.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 220, paddingLeft: UIScreen.main.bounds.width/3, paddingRight: UIScreen.main.bounds.width/3, height: 40)
        
        contentView.addSubview(emptyPostButton)
        emptyPostButton.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 220, paddingLeft: UIScreen.main.bounds.width/3, paddingRight: UIScreen.main.bounds.width/3, height: 40)
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.25)
        contentView.addSubview(separatorView)
        separatorView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 50, paddingRight: 50, height: 0.5)
        
        // need this because group will already be loaded but order might change so need to reload cell
//        configureCell()
        
        let header_layout = UICollectionViewFlowLayout()
        header_layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
//        header_layout.itemSize = CGSize(width: 60, height: 60)
//        header_layout.minimumLineSpacing = CGFloat(20)
        
        headerCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 105), collectionViewLayout: header_layout)
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
        contentView.insertSubview(headerCollectionView, at: 5)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.minimumLineSpacing = CGFloat(0)
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 155, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width/3), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(FeedPostCell.self, forCellWithReuseIdentifier: FeedPostCell.cellId)
        collectionView?.register(FeedGroupPageCell.self, forCellWithReuseIdentifier: FeedGroupPageCell.cellId)
        collectionView?.register(EmptyFeedPostCell.self, forCellWithReuseIdentifier: EmptyFeedPostCell.cellId)
        collectionView?.register(MembersCell.self, forCellWithReuseIdentifier: MembersCell.cellId)
        collectionView?.register(GroupProfilePhotoGridCell.self, forCellWithReuseIdentifier: GroupProfilePhotoGridCell.cellId)
        collectionView?.register(PlusCell.self, forCellWithReuseIdentifier: PlusCell.cellId)
        collectionView.isUserInteractionEnabled = true
        
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        contentView.insertSubview(collectionView, at: 5)
    }
    
    // doing this here to load faster
    private func configureGroupHeader(){
        guard let groupMembers = groupMembers else { return }
        guard let group = group else { return }
        
        let lockImage = #imageLiteral(resourceName: "lock")
        let lockIcon = NSTextAttachment()
        lockIcon.image = lockImage
        let lockIconString = NSAttributedString(attachment: lockIcon)

        let balanceFontSize: CGFloat = 16
        let balanceFont = UIFont.boldSystemFont(ofSize: balanceFontSize)
        //Setting up font and the baseline offset of the string, so that it will be centered
        let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, .foregroundColor: UIColor.black, .baselineOffset: (lockImage.size.height - balanceFontSize) / 2 - balanceFont.descender / 2]
        
        if group.groupname != "" {
            let balanceString = NSMutableAttributedString(string: group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") + " ", attributes: balanceAttr)
            if group.isPrivate ?? false {
                balanceString.append(lockIconString)
            }
            self.groupnameLabel.attributedText = balanceString
        }
        else {
            if groupMembers.count > 2 {
                var usernames = groupMembers[0].username + " & " + groupMembers[1].username + " & " + groupMembers[2].username
                if usernames.count > 21 {
                    usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                    usernames = usernames + "..."
                }
                let balanceString = NSMutableAttributedString(string: usernames.replacingOccurrences(of: "_-a-_", with: " ") + " ", attributes: balanceAttr)
                if group.isPrivate ?? false {
                    balanceString.append(lockIconString)
                }
                self.groupnameLabel.attributedText = balanceString
            }
            else if groupMembers.count == 2 {
                var usernames = groupMembers[0].username + " & " + groupMembers[1].username
                if usernames.count > 21 {
                    usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                    usernames = usernames + "..."
                }
                let balanceString = NSMutableAttributedString(string: usernames.replacingOccurrences(of: "_-a-_", with: " ") + " ", attributes: balanceAttr)
                if group.isPrivate ?? false {
                    balanceString.append(lockIconString)
                }
                self.groupnameLabel.attributedText = balanceString
            }
            else if groupMembers.count == 1 {
                var usernames = groupMembers[0].username
                if usernames.count > 21 {
                    usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                    usernames = usernames + "..."
                }
                let balanceString = NSMutableAttributedString(string: usernames.replacingOccurrences(of: "_-a-_", with: " ") + " ", attributes: balanceAttr)
                if group.isPrivate ?? false {
                    balanceString.append(lockIconString)
                }
                self.groupnameLabel.attributedText = balanceString
            }
        }
        self.headerCollectionView.reloadData()
    }
    
    private func configureGroupCell(){
        guard isGroupHidden != nil else { return }
        guard isInFollowPending != nil else { return }
        guard canView != nil else { return }
        guard isInGroup != nil else { return }
        guard let groupPosts = groupPosts else { return }
        guard let isGroupHidden = isGroupHidden else { return }
        guard let user = user else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        if isGroupHidden && currentLoggedInUserId == user.uid {
            self.hiddenIcon.isHidden = false
        }
        else {
           self.hiddenIcon.isHidden = true
        }
        
        if groupPosts.count == 0 {
            self.setupEmpty()
        }
        
        self.collectionView?.reloadData()
        self.collectionView?.refreshControl?.endRefreshing()
    }
    
    func setupEmpty(){
        collectionView.isHidden = true
        noPostsLabel.isHidden = false
        if canView ?? true { // no posts
//            noPostsLabel.isHidden = false
            noPostsLabel.text = "No posts yet"
            if isInGroup ?? false {
                emptyPostButton.isHidden = false
            }
        }
        else { // private so need to set the follow label thing
            if isInFollowPending ?? false {
                noPostsLabel.isHidden = false
                privateLabel.isHidden = true
                noPostsLabel.text = "This group is private.\n Your follow is pending."
                subscribeButton.isHidden = true
            }
            else {
                noPostsLabel.isHidden = true
                privateLabel.isHidden = false
                privateLabel.text = "This group is private.\n Follow to see their posts."
                subscribeButton.isHidden = false
            }
        }
    }
    
    @objc func postToGroup(){
        guard let group = group else { return }
        self.delegate?.postToGroup(group: group)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView {
            if self.isInGroup != nil && self.isInGroup! {
                return (groupPosts?.count ?? 0) + 1
            }
            else {
                return groupPosts?.count ?? 0
            }
        }
        else {
            return (groupMembers?.count ?? 0) + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.collectionView { // collectionview for posts
            if indexPath.item == 0 {
                if self.isInGroup != nil && self.isInGroup! {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlusCell.cellId, for: indexPath) as! PlusCell
                    cell.parentCollectionViewSize = collectionView.numberOfItems(inSection: 0)
                    return cell
                }
                else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupProfilePhotoGridCell.cellId, for: indexPath) as! GroupProfilePhotoGridCell
                    cell.groupPost = groupPosts?[0]
                    cell.photoImageView.layer.cornerRadius = 12
                    return cell
                }
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupProfilePhotoGridCell.cellId, for: indexPath) as! GroupProfilePhotoGridCell
                if self.isInGroup != nil && self.isInGroup! {
                    if indexPath.item - 1 < groupPosts?.count ?? 0 {
                        cell.groupPost = groupPosts?[indexPath.item - 1]
                    }
                }
                else {
                    if indexPath.item < groupPosts?.count ?? 0 {
                        cell.groupPost = groupPosts?[indexPath.item]
                    }
                }
                cell.photoImageView.layer.cornerRadius = 12
                return cell
            }
        }
        else { // collectionview with group members
            guard let group = group else {
                // if group not set yet just set an empty cell
                let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: MemberHeaderCell.cellId, for: indexPath) as! MemberHeaderCell
                cell.layer.backgroundColor = UIColor.clear.cgColor
                cell.layer.shadowColor = UIColor.black.cgColor
                cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                cell.layer.shadowOpacity = 0.2
                cell.layer.shadowRadius = 2.0
                return cell
            }
            
            if group.groupProfileImageUrl != nil && group.groupProfileImageUrl != "" {
                if indexPath.item == 0 {
                    let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: GroupProfileHeaderCell.cellId, for: indexPath) as! GroupProfileHeaderCell
                    cell.profileImageUrl = group.groupProfileImageUrl
                    cell.groupname = group.groupname
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
                    if groupMembers?.count == 0 {
                        // do soemting
                    }
                    if indexPath.item-1 < groupMembers?.count ?? 0 {
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
                if indexPath.item == 0 {
                    // modify this to be two small user cells
                    let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: GroupProfileHeaderCell.cellId, for: indexPath) as! GroupProfileHeaderCell
                    cell.groupname = group.groupname
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
                    if groupMembers?.count == 0 {
                        // do something
                        
                        
                        
                        
                    }
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
        if collectionView == self.collectionView { // collectionview for posts
            guard let groupPosts = self.groupPosts else { return }
            guard let isInGroup = self.isInGroup else { return }
            if indexPath.row == 0 {
                if self.isInGroup != nil && self.isInGroup! {
                    guard let group = group else { return }
                    self.delegate?.postToGroup(group: group)
                }
                else {
                    if indexPath.row < groupPosts.count {
                        delegate?.didTapGroupPost(groupPost: groupPosts[indexPath.row], index: indexPath.row)
                    }
                }
            }
            else if self.groupPosts?.count != 0 {
                if isInGroup {
                    if indexPath.row - 1 < groupPosts.count {
                        delegate?.didTapGroupPost(groupPost: groupPosts[indexPath.row - 1], index: indexPath.row-1)
                    }
                }
                else {
                    if indexPath.row < self.groupPosts?.count ?? 0 {
                        delegate?.didTapGroupPost(groupPost: groupPosts[indexPath.row], index: indexPath.row)
                    }
                }
            }
        }
        else { // collectionview with group members
            if indexPath.row == 0 {
                guard let group = group else { return }
                delegate?.didTapGroup(group: group)
            }
            else {
                guard let groupMembers = self.groupMembers else { return }
                delegate?.didTapUser(user: groupMembers[indexPath.row - 1])
            }
        }
    }

    @objc private func handleGroupTap(){
        guard let group = group else { return }
        delegate?.didTapGroup(group: group)
    }
    
    @objc private func handleSubscribeTap() {
        guard let groupId = group?.groupId else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        noPostsLabel.isHidden = false
        privateLabel.isHidden = true
        noPostsLabel.text = "This group is private.\n Your subscription is pending."
        subscribeButton.isHidden = true
        
        Database.database().subscribeToGroup(groupId: groupId) { (err) in
            
            NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
            NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
            
            // sending notification
            Database.database().groupExists(groupId: groupId, completion: { (exists) in
                if exists {
                    Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                        Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
                            Database.database().fetchGroupMembers(groupId: groupId, completion: { (members) in
                                guard let isPrivate = group.isPrivate else { return }
                                members.forEach({ (member) in
                                    if user.uid != member.uid {
                                        if isPrivate {
                                            // send notification for subscription request to all members of group
                                            Database.database().createNotification(to: member, notificationType: NotificationType.groupSubscribeRequest, subjectUser: user, group: group) { (err) in
                                                if err != nil {
                                                    return
                                                }
                                            }
                                        }
                                        else {
                                            // send notification for did subscribe to all members of group
                                            Database.database().createNotification(to: member, notificationType: NotificationType.newGroupSubscribe, subjectUser: user, group: group) { (err) in
                                                if err != nil {
                                                    return
                                                }
                                            }
                                        }
                                    }
                                })
                            }) { (_) in}
                        })
                    })
                }
            })
        }
    }
}

extension FullGroupCell: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == self.collectionView {
            return 3
        }
        else {
            return 5
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.collectionView { // for posts
            let width = (UIScreen.main.bounds.width - 16) / 3
            if groupPosts?.count ?? 0 == 0 {
                return CGSize(width: UIScreen.main.bounds.width, height: width)
            }
            if indexPath.item == 0 && self.isInGroup != nil && self.isInGroup! {
                return CGSize(width: width/3*2, height: width)
            }
            return CGSize(width: width, height: width)
        }
        else {
            return CGSize(width: 70, height: 60)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == self.collectionView {
            return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        }
        else {
            return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
//            if groupMembers?.count ?? 0 == 1 {
//                let totalCellWidth = 60 * collectionView.numberOfItems(inSection: 0)
//                let totalSpacingWidth = 10 * (collectionView.numberOfItems(inSection: 0) - 1)
//
//                let leftInset = (collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
//                let rightInset = leftInset
//
//                return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
//            }
//            else if groupMembers?.count ?? 0 == 2 {
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
