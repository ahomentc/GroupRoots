//
//  GroupProfileHeader.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.

import UIKit
import Firebase

//MARK: - GroupProfileHeaderDelegate

protocol GroupProfileHeaderDelegate {
    func didChangeToListView()
    func didChangeToGridView()
    func handleShowNewGroup()
    func handleShowUsersRequesting()
    func handleShowFollowers()
    func showInviteCopyAlert()
    func handleDidJoinGroupFromInvite()
    func handleShowEditGroup()
    func didTapUser(user: User)
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
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowRequests))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private lazy var totalFollowersLabel: GroupProfileStatsLabel = {
        let label = GroupProfileStatsLabel(value: 0, title: "subscribers")
        label.isUserInteractionEnabled = true
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
    
    private lazy var requestsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Members", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor(white: 0, alpha: 0.6).cgColor
        button.addTarget(self, action: #selector(handleShowRequests), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()
    
    private let editProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit Group", for: .normal)
        button.backgroundColor = UIColor.white
        button.isHidden = true
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        button.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        button.layer.borderWidth = 1
        button.addTarget(self, action: #selector(handleShowEditGroup), for: .touchUpInside)
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
    
    private var bioLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.isHidden = true
        return label
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
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 10, width: UIScreen.main.bounds.width, height: 100), collectionViewLayout: layout)
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
        if group?.groupProfileImageUrl != nil && group?.groupProfileImageUrl != ""{
            return 20
        }
        else {
            return 10
        }
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
        bioLabel.text = bio
        bioLabel.isHidden = false
        
        if bio != "" {
            addSubview(bioLabel)
            bioLabel.anchor(top: collectionView.bottomAnchor, left: leftAnchor, paddingTop: padding, paddingLeft: 15, height: 34)
            
            addSubview(joinButton)
            joinButton.anchor(top: bioLabel.bottomAnchor, left: leftAnchor, paddingTop: 15, paddingLeft: 15, height: 34)
            
            addSubview(subscribeButton)
            subscribeButton.anchor(top: bioLabel.bottomAnchor, left: joinButton.rightAnchor, paddingTop: 15, paddingLeft: 15, height: 34)

            addSubview(editProfileButton)
            editProfileButton.anchor(top: bioLabel.bottomAnchor, right: rightAnchor, paddingTop: 15, paddingRight: 15,  width: 100, height: 34)
            
            let stackView = UIStackView(arrangedSubviews: [membersLabel, totalFollowersLabel, inviteCodeButton])
            stackView.distribution = .fillEqually
            stackView.spacing = 15
            addSubview(stackView)
            stackView.anchor(top: joinButton.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 30, paddingRight: 30)
        }
        else {
            addSubview(joinButton)
            joinButton.anchor(top: collectionView.bottomAnchor, left: leftAnchor, paddingTop: 15, paddingLeft: 15, height: 34)
            
            addSubview(subscribeButton)
            subscribeButton.anchor(top: collectionView.bottomAnchor, left: joinButton.rightAnchor, paddingTop: 15, paddingLeft: 15, height: 34)

            addSubview(editProfileButton)
            editProfileButton.anchor(top: collectionView.bottomAnchor, right: rightAnchor, paddingTop: 15, paddingRight: 15,  width: 100, height: 34)
            
            let stackView = UIStackView(arrangedSubviews: [membersLabel, totalFollowersLabel, inviteCodeButton])
            stackView.distribution = .fillEqually
            stackView.spacing = 15
            addSubview(stackView)
            stackView.anchor(top: joinButton.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 30, paddingRight: 30)
        }
        
        
        Database.database().fetchGroupMembers(groupId: group.groupId, completion: { (users) in
            self.users = users
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }) { (_) in
            self.collectionView?.refreshControl?.endRefreshing()
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
            else{
                // check if the user is following the group or not
                Database.database().isFollowingGroup(groupId: groupId, completion: { (following) in
                    if following {
                        self.subscribeButton.type = .unsubscribe
                        return
                    }
                }) { (err) in
                    return
                }
                self.subscribeButton.type = .subscribe
            }
        }) { (err) in
            return
        }
        
        
    }

    private func reloadGroupStats() {
        guard let groupId = group?.groupId else { return }
    
        Database.database().numberOfPostsForGroup(groupId: groupId) { (count) in
            self.postsLabel.setValue(count)
        }
        
        Database.database().fetchGroupMembers(groupId: groupId, completion: { (members) in
            self.membersLabel.setValue(members.count)
        }) { (_) in}
        
        Database.database().fetchGroupFollowers(groupId: groupId, completion: { (followers) in
            self.totalFollowersLabel.setValue(followers.count)
        }) { (_) in}
    }
    
    private func reloadInviteCode() {
        // check to see if the user is in the group first, if so, then put the invite code in
        guard let groupId = group?.groupId else { return }
        Database.database().isInGroup(groupId: groupId, completion: { (inGroup) in
            if inGroup {
                self.inviteCodeButton.isHidden = false
                self.editProfileButton.isHidden = false // also just update the edit profile button here out of laziness
                
                let code = String(groupId.suffix(6))
//                self.inviteCodeButton.setTitle("Invite Code: " + code, for: .normal)
                let attributedText = NSMutableAttributedString(string: "\(code)\n", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)])
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
        
        NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
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
    
    @objc private func handleShowEditGroup(){
        delegate?.handleShowEditGroup()
    }
    
    @objc private func handleInviteTap(){
        guard let groupId = group?.groupId else { return }
        let code = String(groupId.suffix(6))
        let pasteboard = UIPasteboard.general
        pasteboard.string = code
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
        layer.borderWidth = 1.4
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
        layer.borderWidth = 1.4
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
        if group?.groupProfileImageUrl != nil && group?.groupProfileImageUrl != ""{
            if indexPath.item == 0 {
                return CGSize(width: 112, height: 100)
            }
            else {
                return CGSize(width: 80, height: 80)
            }
        }
        else {
            return CGSize(width: 90, height: 80)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

        let totalCellWidth = 80 * collectionView.numberOfItems(inSection: 0)
        let totalSpacingWidth = 10 * (collectionView.numberOfItems(inSection: 0) - 1)

        let leftInset = (collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset

        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)

    }
}
