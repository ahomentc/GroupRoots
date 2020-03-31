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
}

//MARK: - GroupProfileHeader

class GroupProfileHeader: UICollectionViewCell {

    var delegate: GroupProfileHeaderDelegate?

    var group: Group? {
        didSet {
            reloadGroupData()
        }
    }
    
    var numberOfPosts: Int? {
        didSet {
//            reloadData()
        }
    }
    
    var members: Int? {
        didSet {
//            reloadData()
        }
    }
    
    var memberRequestors: Int? {
        didSet {
//            reloadData()
        }
    }
    
    var followers: Int? {
        didSet {
//            reloadData()
        }
    }
    
    var pendingFollowers: Int? {
        didSet {
//            reloadData()
        }
    }

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
    
    private lazy var inviteCodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitle("", for: .normal)
        button.isHidden = true
        button.setTitleColor(.black, for: .normal)
        button.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 5
        button.backgroundColor = .white
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.isUserInteractionEnabled = true
        button.addTarget(self, action: #selector(handleInviteTap), for: .touchUpInside)
        return button
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
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: padding, paddingLeft: padding, width: 80, height: 80)
        profileImageView.layer.cornerRadius = 32
        
        let stackView = UIStackView(arrangedSubviews: [postsLabel, totalFollowersLabel, membersLabel])
        stackView.distribution = .fillEqually
        addSubview(stackView)
        stackView.anchor(top: topAnchor, left: profileImageView.rightAnchor, right: rightAnchor, paddingTop: padding, paddingLeft: padding, paddingRight: padding, height: 50)
        
        addSubview(joinButton)
        joinButton.anchor(top: stackView.bottomAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: padding, paddingRight: padding + 10, height: 34)
        
        addSubview(subscribeButton)
        subscribeButton.anchor(top: stackView.bottomAnchor, right: joinButton.leftAnchor, paddingTop: 5, paddingLeft: padding, paddingRight: padding, height: 34)
        
        addSubview(inviteCodeButton)
        inviteCodeButton.anchor(top: subscribeButton.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: CGFloat(2), paddingRight: CGFloat(2), height: 34)
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
                let code = String(groupId.suffix(6))
                self.inviteCodeButton.setTitle("Invite Code: " + code, for: .normal)
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
                print("hi")
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
        let attributedText = NSMutableAttributedString(string: "\(value)\n", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]))
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



