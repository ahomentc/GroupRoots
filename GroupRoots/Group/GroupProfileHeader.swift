//
//  GroupProfileHeader.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

//MARK: - GroupProfileHeaderDelegate

protocol GroupProfileHeaderDelegate {
    func didChangeToListView()
    func didChangeToGridView()
    func handleShowNewGroup()
    func handleShowUsersRequesting()
    func handleShowFollowers()
    func showInviteCopyAlert()
    func handleDidJoinGroupFromInvite()
    func handleShowAddMember()
    func didTapUser(user: User)
    func setNavigationTitle(title: String)
}

//MARK: - GroupProfileHeader

class GroupProfileHeader: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {

    var delegate: GroupProfileHeaderDelegate?

    private var users = [User]()
    var group: Group? {
        didSet {
            reloadGroupData()
        }
    }
    
    var numberOfPosts: Int? {
        didSet {
        }
    }
    
    var members: Int? {
        didSet {
        }
    }
    
    var memberRequestors: Int? {
        didSet {
        }
    }
    
    var followers: Int? {
        didSet {
        }
    }
    
    var pendingFollowers: Int? {
        didSet {
        }
    }

    // this collection view holds the members
    var collectionView: UICollectionView!
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        return iv
    }()

    private let postsLabel = GroupProfileStatsLabel(value: 0, title: "posts")
    
    private lazy var membersLabel: GroupProfileStatsLabel = {
        let label = GroupProfileStatsLabel(value: 0, title: "members")
        label.isUserInteractionEnabled = false
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowRequests))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private lazy var totalFollowersLabel: GroupProfileStatsLabel = {
        let label = GroupProfileStatsLabel(value: 0, title: "subscribers")
        label.isUserInteractionEnabled = false
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowFollowers))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private lazy var joinButton: GroupJoinButton = {
        let button = GroupJoinButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleJoinTap), for: .touchUpInside)
        return button
    }()
    
    private lazy var subscribeButton: GroupJoinButton = {
        let button = GroupJoinButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleSubscribeTap), for: .touchUpInside)
        return button
    }()
    
    private let addMemberButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Member", for: .normal)
        button.backgroundColor = UIColor.white
        button.isHidden = true
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        button.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        button.layer.borderWidth = 1
        button.addTarget(self, action: #selector(handleShowAddMember), for: .touchUpInside)
        return button
    }()
    
    private lazy var inviteCodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitle("", for: .normal)
        button.isHidden = true
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.textColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 5
        button.backgroundColor = .white
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.isUserInteractionEnabled = true
        button.addTarget(self, action: #selector(handleInviteTap), for: .touchUpInside)
        return button
    }()
    
//    private var bioLabel: UILabel = {
//        let label = UILabel()
//        label.text = ""
//        label.isHidden = true
//        label.lineBreakMode = .byWordWrapping
//        label.numberOfLines = 2
//        return label
//    }()
    
    private let bioLabel: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.isHidden = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        return textView
    }()

    private let padding: CGFloat = 12

    static var headerId = "groupProfileHeaderId"

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    private func sharedInit() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 5, width: UIScreen.main.bounds.width, height: 110), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .black
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(MemberHeaderCell.self, forCellWithReuseIdentifier: MemberHeaderCell.cellId)
        collectionView?.register(GroupProfileHeaderCell.self, forCellWithReuseIdentifier: GroupProfileHeaderCell.cellId)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        self.addSubview(collectionView)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if group?.groupProfileImageUrl != nil && group?.groupProfileImageUrl != ""{
            return users.count + 1
        }
        else{
            return users.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // if there is a group profile image
        if group?.groupProfileImageUrl != nil && group?.groupProfileImageUrl != ""{
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupProfileHeaderCell.cellId, for: indexPath) as! GroupProfileHeaderCell
                cell.profileImageUrl = group?.groupProfileImageUrl
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemberHeaderCell.cellId, for: indexPath) as! MemberHeaderCell
                cell.user = users[indexPath.item-1]
                cell.group_has_profile_image = true
                return cell
            }
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemberHeaderCell.cellId, for: indexPath) as! MemberHeaderCell
            cell.user = users[indexPath.item]
            cell.group_has_profile_image = false
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if group?.groupProfileImageUrl != nil && group?.groupProfileImageUrl != ""{
            if indexPath.item > 0 {
                let user = users[indexPath.item-1]
                delegate?.didTapUser(user: user)
            }
        }
        else {
            let user = users[indexPath.item]
            delegate?.didTapUser(user: user)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
//        if group?.groupProfileImageUrl != nil && group?.groupProfileImageUrl != ""{
//            return 20
//        }
//        else {
//            return 10
//        }
    }

    func reloadGroupData() {
        guard let group = group else { return }
        reloadJoinButton()
        reloadGroupStats()
        reloadSubscribeButton()
        reloadInviteCode()
        
        if let profileImageUrl = group.groupProfileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        }
        
        let bio = group.bio
//        let bio = "this is the bio. this is the second sentence. this is the second sentence. this is the second sentence"
//        let bio = "this is the bio. this is the second sentence."
        bioLabel.isHidden = false
        let attributedText = NSMutableAttributedString(string: bio, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.black])
        bioLabel.attributedText = attributedText
        
        if bio != "" {
            addSubview(bioLabel)
            bioLabel.anchor(top: collectionView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: padding, paddingLeft: 30, paddingRight: 30)
            
            let buttonStackView = UIStackView(arrangedSubviews: [joinButton, subscribeButton, addMemberButton])
            buttonStackView.distribution = .fillProportionally
            buttonStackView.spacing = 15
            addSubview(buttonStackView)
            buttonStackView.anchor(top: bioLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 20, paddingLeft: 30, paddingRight: 30, height: 34)
            
            let stackView = UIStackView(arrangedSubviews: [membersLabel, totalFollowersLabel, inviteCodeButton])
            stackView.distribution = .fillEqually
            stackView.spacing = 15
            addSubview(stackView)
            stackView.anchor(top: buttonStackView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 30, paddingRight: 30)
        }
        else {
            let buttonStackView = UIStackView(arrangedSubviews: [joinButton, subscribeButton, addMemberButton])
            buttonStackView.distribution = .fillProportionally
            buttonStackView.spacing = 15
            addSubview(buttonStackView)
            buttonStackView.anchor(top: collectionView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 30, paddingRight: 30, height: 34)
            
            let stackView = UIStackView(arrangedSubviews: [membersLabel, totalFollowersLabel, inviteCodeButton])
            stackView.distribution = .fillEqually
            stackView.spacing = 15
            addSubview(stackView)
            stackView.anchor(top: buttonStackView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 30, paddingRight: 30)
        }
        
        
        Database.database().fetchGroupMembers(groupId: group.groupId, completion: { (users) in
            self.users = users
            
            // set the navigation title
            if group.groupname == "" {
                var usernames = ""
                if users.count == 1 {
                    usernames = users[0].username
                }
                else if users.count == 2 {
                    usernames = users[0].username + " & " + users[1].username
                }
                else {
                    usernames = users[0].username + " & " + users[1].username + " & " + users[2].username
                }
                if usernames.count > 20 {
                    usernames = String(usernames.prefix(20)) // keep only the first 16 characters
                    usernames = usernames + "..."
                }
                self.delegate?.setNavigationTitle(title: usernames)
            }
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }) { (_) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
        
        Database.database().isInGroup(groupId: group.groupId, completion: { (inGroup) in
            if inGroup {
                Database.database().hasGroupRequestUsers(groupId: group.groupId, completion: { (has_member_requestors) in
                    Database.database().hasGroupSubscriptionRequestUsers(groupId: group.groupId, completion: { (has_subscription_requestors) in
                        self.membersLabel.setAttributedTextWithDot(has_requestors: has_member_requestors)
                        self.totalFollowersLabel.setAttributedTextWithDot(has_requestors: has_subscription_requestors)
                    })
                })
            }
        }) { (err) in
            return
        }
    }
    
    private func reloadJoinButton() {
        guard let groupId = group?.groupId else { return }
        
        // check if user is in the group
        Database.database().isInGroup(groupId: groupId, completion: { (inGroup) in
            if inGroup {
                self.joinButton.type = .leave
                return
            }
        }) { (err) in
            return
        }
        
        // check if user has requested to join
        Database.database().hasRequestedGroup(groupId: groupId, completion: { (requested) in
            if requested {
                self.joinButton.type = .requested
                return
            }
        }) { (err) in
            return
        }
        
        self.joinButton.type = .join
    }
    
    private func reloadSubscribeButton() {
        guard let groupId = group?.groupId else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        // check if user in in pending follow
        Database.database().isInGroupFollowPending(groupId: groupId, withUID: currentLoggedInUserId, completion: { (followingPending) in
            if followingPending {
                self.subscribeButton.type = .requested
            }
            else {
                // check if the user is following the group or not
                Database.database().isFollowingGroup(groupId: groupId, completion: { (following) in
                    if following {
                        self.subscribeButton.type = .unsubscribe
                        return
                    }
                    else {
                        self.subscribeButton.type = .subscribe
                    }
                }) { (err) in
                    return
                }
            }
        }) { (err) in
            return
        }
        
        
    }

    private func reloadGroupStats() {
        guard let group = group else { return }
    
        Database.database().numberOfPostsForGroup(groupId: group.groupId) { (count) in
            self.postsLabel.setValue(count)
        }
        
        Database.database().numberOfMembersForGroup(groupId: group.groupId) { (membersCount) in
            self.membersLabel.setValue(membersCount)
            // check if user is in group or subscribed first
            Database.database().isInGroup(groupId: group.groupId, completion: { (inGroup) in
                Database.database().isFollowingGroup(groupId: group.groupId, completion: { (following) in
                    if inGroup || following {
                        self.membersLabel.isUserInteractionEnabled = true
                    }
                    else {
                        self.membersLabel.isUserInteractionEnabled = !(group.isPrivate ?? true)
                    }
                }) { (err) in
                    return
                }
            }) { (_) in}
        }
        
        Database.database().numberOfSubscribersForGroup(groupId: group.groupId) { (membersCount) in
            self.totalFollowersLabel.setValue(membersCount)
            // check if user is in group or subscribed first
            Database.database().isInGroup(groupId: group.groupId, completion: { (inGroup) in
                Database.database().isFollowingGroup(groupId: group.groupId, completion: { (following) in
                    if inGroup || following {
                        self.totalFollowersLabel.isUserInteractionEnabled = true
                    }
                    else {
                        self.totalFollowersLabel.isUserInteractionEnabled = !(group.isPrivate ?? true)
                    }
                }) { (err) in
                    return
                }
            }) { (_) in}
        }
    }
    
    private func reloadInviteCode() {
        // check to see if the user is in the group first, if so, then put the invite code in
        guard let groupId = group?.groupId else { return }
        Database.database().isInGroup(groupId: groupId, completion: { (inGroup) in
            if inGroup {
                self.inviteCodeButton.isHidden = false
                self.addMemberButton.isHidden = false // also just update the edit profile button here out of laziness
                
                let code = String(groupId.suffix(6))
                let stripped_code = code.replacingOccurrences(of: "_", with: "a", options: .literal, range: nil)
                let stripped_code2 = stripped_code.replacingOccurrences(of: "-", with: "b", options: .literal, range: nil)
//                self.inviteCodeButton.setTitle("Invite Code: " + code, for: .normal)
                let attributedText = NSMutableAttributedString(string: "\(stripped_code2)\n", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)])
                attributedText.append(NSAttributedString(string: "Invite", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]))
                self.inviteCodeButton.setAttributedTitle(attributedText, for: .normal)
                return
            }
            else {
                self.inviteCodeButton.isHidden = true
            }
        }) { (err) in
            return
        }
    }
    
    @objc private func handleJoinTap() {
        guard let groupId = group?.groupId else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let previousButtonType = joinButton.type
        joinButton.type = .loading
        
        if previousButtonType == .join {
            Database.database().isUserInvitedToGroup(withUID: currentLoggedInUserId, groupId: groupId, completion: { (isInvited) in
                if isInvited {
                    // if is invited auto add to group
                    // join the group action
                    Database.database().acceptIntoGroup(withUID: currentLoggedInUserId, groupId: groupId){ (err) in
                        if err != nil {
                            return
                        }
                        // remove from group invited
                        Database.database().removeFromGroupInvited(withUID: currentLoggedInUserId, groupId: groupId) { (err) in
                            if err != nil {
                                return
                            }
                            self.delegate?.handleDidJoinGroupFromInvite()
                            self.reloadJoinButton()
                            self.reloadGroupStats()
                            self.reloadSubscribeButton()
                            self.reloadInviteCode()
                            
                            // notification that member is now in group
                            Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
                                Database.database().groupExists(groupId: groupId, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                                            Database.database().fetchGroupMembers(groupId: groupId, completion: { (members) in
                                                members.forEach({ (member) in
                                                    if user.uid != member.uid {
                                                        Database.database().createNotification(to: member, notificationType: NotificationType.newGroupJoin, subjectUser: user, group: group) { (err) in
                                                            if err != nil {
                                                                return
                                                            }
                                                        }
                                                    }
                                                })
                                            }) { (_) in}
                                        })
                                    }
                                    else {
                                        return
                                    }
                                })
                            })
                        }
                    }
                }
                else{
                    Database.database().joinGroup(groupId: groupId) { (err) in // adds user to requested members of group... should change name
                        if err != nil {
                            self.joinButton.type = previousButtonType
                            return
                        }
                        self.reloadJoinButton()
                        self.reloadGroupStats()
                        self.reloadSubscribeButton()
                        self.reloadInviteCode()
                        
                        // send the notification each each user in the group
                        Database.database().fetchGroupMembers(groupId: groupId, completion: { (users) in
                            users.forEach({ (user) in
                                if user.uid != currentLoggedInUserId {
                                    Database.database().createNotification(to: user, notificationType: NotificationType.groupJoinRequest, group: self.group!) { (err) in
                                        if err != nil {
                                            return
                                        }
                                    }
                                }
                            })
                        }) { (_) in}
                    }
                }
            }) { (err) in
                return
            }
        } else if previousButtonType == .requested {
            Database.database().cancelJoinRequest(groupId: groupId) { (err) in
                if err != nil {
                    self.joinButton.type = previousButtonType
                    return
                }
                self.reloadJoinButton()
                self.reloadGroupStats()
                self.reloadSubscribeButton()
                self.reloadInviteCode()
            }
        } else if previousButtonType == .leave {
            Database.database().leaveGroup(groupId: groupId) { (err) in
                if err != nil {
                    self.joinButton.type = previousButtonType
                    return
                }
                self.reloadJoinButton()
                self.reloadGroupStats()
                self.reloadSubscribeButton()
                self.reloadInviteCode()
            }
        } else if previousButtonType == .subscribe {
            
        } else if previousButtonType == .unsubscribe {
            
        }
        
        NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
        NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
    }
    
    @objc private func handleSubscribeTap() {
        guard let groupId = group?.groupId else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let previousButtonType = subscribeButton.type
        subscribeButton.type = .loading
                
        if previousButtonType == .subscribe {
            // when you subscribe to group and group is in removedGroups, bypass that and remove the group from that list
            
            // check if a private group or not
            // remove from groupsBlocked if its there
            
            Database.database().subscribeToGroup(groupId: groupId) { (err) in
                if err != nil {
                    self.subscribeButton.type = previousButtonType
                    return
                }
                self.reloadSubscribeButton() // put this in callback
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
            
            
        } else if previousButtonType == .unsubscribe {
            Database.database().removeGroupFromUserFollowing(withUID: currentLoggedInUserId, groupId: groupId) { (err) in
                if err != nil {
                    self.subscribeButton.type = previousButtonType
                    return
                }
                self.reloadSubscribeButton() // put this in callback
                NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
            }
        } else if previousButtonType == .requested {
            Database.database().removeUserFromGroupPending(withUID: currentLoggedInUserId, groupId: groupId) { (err) in
                if err != nil {
                    self.subscribeButton.type = previousButtonType
                    return
                }
                self.reloadSubscribeButton() // put this in callback
                NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
            }
        }
    }

    @objc private func handleCreateNewGroup(){
        delegate?.handleShowNewGroup()
    }
    
    @objc private func handleShowRequests(){
        delegate?.handleShowUsersRequesting()
    }
    
    @objc private func handleShowFollowers(){
        delegate?.handleShowFollowers()
    }
    
    @objc private func handleShowAddMember(){
        delegate?.handleShowAddMember()
    }
    
    @objc private func handleInviteTap(){
        guard let groupId = group?.groupId else { return }
        let code = String(groupId.suffix(6))
        let stripped_code = code.replacingOccurrences(of: "_", with: "a", options: .literal, range: nil)
        let stripped_code2 = stripped_code.replacingOccurrences(of: "-", with: "b", options: .literal, range: nil)
        let pasteboard = UIPasteboard.general
        pasteboard.string = stripped_code2
        delegate?.showInviteCopyAlert()
    }
}

//MARK: - GroupProfileStatsLabel

private class GroupProfileStatsLabel: UILabel {

    private var value: Int = 0
    private var title: String = ""

    init(value: Int, title: String) {
        super.init(frame: .zero)
        self.value = value
        self.title = title
        sharedInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    private func sharedInit() {
        numberOfLines = 0
        textAlignment = .center
        setAttributedText()
    }

    func setValue(_ value: Int) {
        self.value = value
        setAttributedText()
    }
    
    public func setAttributedTextWithDot(has_requestors: Bool) {
        if !has_requestors {
            return
        }
        
        let dotImage = #imageLiteral(resourceName: "dot")
        let dotIcon = NSTextAttachment()
        dotIcon.image = dotImage
        let dotIconString = NSAttributedString(attachment: dotIcon)

        let balanceFontSize: CGFloat = 16
        let balanceFont = UIFont.boldSystemFont(ofSize: balanceFontSize)

        //Setting up font and the baseline offset of the string, so that it will be centered
        let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, .baselineOffset: (dotImage.size.height - balanceFontSize + 2) / 2 - balanceFont.descender / 2]
        let bottom = value == 1 ? String(self.title.dropLast()) : self.title
        let attributedText = NSMutableAttributedString(string: "\(value)\n", attributes: balanceAttr)
        
        attributedText.insert(NSAttributedString(string: "  ", attributes: [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]), at: 0)
        attributedText.insert(dotIconString, at: 0)
        
        attributedText.append(NSAttributedString(string: bottom, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]))
        self.attributedText = attributedText
    }

    private func setAttributedText() {
        let attributedText = NSMutableAttributedString(string: "\(value)\n", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)])
        var labelTitle = self.title
        if value == 1 {
            labelTitle = String(self.title.dropLast())
        }
        attributedText.append(NSAttributedString(string: labelTitle, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]))
        self.attributedText = attributedText
    }
}

//MARK: - JoinButtonType

private enum JoinButtonType {
    case loading, join, requested, leave, subscribe, unsubscribe
}

//MARK: - GroupJoinButton

private class GroupJoinButton: UIButton {
    
    var type: JoinButtonType = .loading {
        didSet {
            configureButton()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    private func sharedInit() {
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 3
        configureButton()
    }

    private func configureButton() {
        switch type {
        case .loading:
            setupLoadingStyle()
        case .join:
            setupJoinStyle()
        case .requested:
            setupRequestedStyle()
        case .leave:
            setupLeaveStyle()
        case .subscribe:
            setupSubscribeStyle()
        case .unsubscribe:
            setupUnsubscribeStyle()
        }
        
    }
    
    private func setupLoadingStyle() {
        setTitle("Loading", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        isUserInteractionEnabled = false
    }

    private func setupRequestedStyle() {
        setTitle("Requested", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        isUserInteractionEnabled = true
        layer.cornerRadius = 5
        layer.borderWidth = 1
    }

    private func setupLeaveStyle() {
        setTitle("Leave", for: .normal)
        setTitleColor(.black, for: .normal)
        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 5
        backgroundColor = .white
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        isUserInteractionEnabled = true
    }

    private func setupJoinStyle() {
        setTitle("Join", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = UIColor.white
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        isUserInteractionEnabled = true
    }
    
    private func setupSubscribeStyle() {
        setTitle("Subscribe", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = UIColor.white
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        isUserInteractionEnabled = true
    }
    
    private func setupUnsubscribeStyle() {
        setTitle("Unsubscribe", for: .normal)
        setTitleColor(.black, for: .normal)
        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 5
        backgroundColor = .white
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        isUserInteractionEnabled = true
    }
}

extension GroupProfileHeader: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 75, height: 75)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if users.count == 1 {
            let totalCellWidth = 80 * collectionView.numberOfItems(inSection: 0)
            let totalSpacingWidth = 10 * (collectionView.numberOfItems(inSection: 0) - 1)

            let leftInset = (collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
            let rightInset = leftInset

            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        }
        else {
            return UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 0)
        }
    }
}
