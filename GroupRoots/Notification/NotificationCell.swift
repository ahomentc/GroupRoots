import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

//MARK: - NotificationCellDelegate

protocol NotificationCellDelegate {
    func handleShowGroup(group: Group)
    func handleShowUser(user: User)
    func didTapPost(group: Group, post: GroupPost)
    func groupJoinAlert(group: Group)
    func handleShowGroupMemberRequest(group: Group)
    func handleShowGroupSubscriberRequest(group: Group)
    func handleShowComment(groupPost: GroupPost)
}

class NotificationCell: UICollectionViewCell {
    
    // For now, just do newFollow notification
    
    var delegate: NotificationCellDelegate?
    
    var notification: Notification? {
        didSet {
            configureCell()
            reloadActionButton()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        groupImageView.isHidden = true
        userOneImageView.isHidden = true
        userTwoImageView.isHidden = true
    }

    private lazy var profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        
        iv.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDidTapFromUser))
        iv.addGestureRecognizer(gestureRecognizer)
        return iv
    }()
    
    private let groupImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        return iv
    }()
    
    private let userOneImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 2
        return iv
    }()
    
    private let userTwoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 2
        return iv
    }()
    
    private lazy var postImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderWidth = 0
        iv.isUserInteractionEnabled = false
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDidTapPost))
        iv.addGestureRecognizer(gestureRecognizer)
        return iv
    }()
    
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDidTapFromUser))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private lazy var notificationsLabel: UILabel = {
        let label = UILabel()
        label.font = label.font.withSize(14)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = UIScreen.main.bounds.width * 0.6
        
//        label.isUserInteractionEnabled = true
//        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDidTapFromUser))
//        label.addGestureRecognizer(gestureRecognizer)
        
        return label
    }()
    
    private lazy var actionButton: ActionButton = {
        let button = ActionButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return button
    }()
    
    // Need to add a follow button
    
    static var cellId = "notificationCellId"
    
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
        profileImageView.anchor(left: leftAnchor, paddingLeft: 8, width: 45, height: 45)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 45/2
        
        addSubview(postImageView)
        postImageView.anchor(right: rightAnchor, paddingRight: 8, width: 50, height: 50)
        postImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        postImageView.layer.cornerRadius = 5
        postImageView.image = UIImage()
        postImageView.layer.borderWidth = 0
        
        addSubview(groupImageView)
        groupImageView.anchor(right: rightAnchor, paddingRight: 8, width: 50, height: 50)
        groupImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        groupImageView.layer.cornerRadius = 50 / 2
        groupImageView.isHidden = true
        
        addSubview(userOneImageView)
        userOneImageView.anchor(right: rightAnchor, paddingTop: 10, paddingRight: 8, width: 44, height: 44)
        userOneImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userOneImageView.layer.cornerRadius = 44/2
        userOneImageView.isHidden = true
        userOneImageView.image = UIImage()
        
        addSubview(userTwoImageView)
        userTwoImageView.anchor(right: rightAnchor, paddingTop: 0, paddingRight: 28, width: 44, height: 44)
        userTwoImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userTwoImageView.layer.cornerRadius = 44/2
        userTwoImageView.isHidden = true
        userOneImageView.image = UIImage()
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, paddingTop: 16, paddingLeft: 12)
        
        addSubview(notificationsLabel)
        notificationsLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, paddingTop: 24, paddingLeft: 12)
        
        addSubview(actionButton)
        actionButton.anchor(top: topAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 15, paddingBottom: 15, paddingRight: 8)
        
    }
    
    private func configureCell() {
        guard let notification = notification else { return }
        
        Database.database().viewNotification(notificationId: notification.id) { (err) in
            if err != nil {
                return
            }
        }
        
        usernameLabel.text = notification.from.username
        if notification.type == NotificationType.newFollow {
            notificationsLabel.text = "followed you"
        }
        else if notification.type == NotificationType.groupJoinInvitation {
            var groupname = "a group"
            if notification.group?.groupname ?? "" != "" {
                groupname = notification.group?.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") ?? ""
            }
            notificationsLabel.text = "invited you to join " + groupname
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.newGroupJoin {
            var groupname = "your group"
            if notification.group?.groupname ?? "" != "" {
                groupname = notification.group?.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") ?? ""
            }
            notificationsLabel.text = "joined " + groupname
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.groupJoinRequest {
            var groupname = "your group"
            if notification.group?.groupname ?? "" != "" {
                groupname = notification.group?.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") ?? ""
            }
            notificationsLabel.text = "requested to join " + groupname
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.newGroupSubscribe {
            var groupname = "your group"
            if notification.group?.groupname ?? "" != "" {
                groupname = notification.group?.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") ?? ""
            }
            notificationsLabel.text = "followed " + groupname
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.groupSubscribeRequest {
            var groupname = "your group"
            if notification.group?.groupname ?? "" != "" {
                groupname = notification.group?.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") ?? ""
            }
            notificationsLabel.text = "requested to follow " + groupname
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.groupProfileNameEdit {
            notificationsLabel.text = "removed your group's name"
            if notification.group?.groupname ?? "" != "" {
                let groupname = notification.group?.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") ?? ""
                notificationsLabel.text = "changed group name to " + groupname
            }
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.groupProfilePicEdit {
            var groupname = "your group"
            if notification.group?.groupname ?? "" != "" {
                groupname = notification.group?.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") ?? ""
            }
            notificationsLabel.text = "edited " + groupname + "'s profile picture"
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.groupPrivacyChange {
            guard let group = notification.group else { return }
            guard let isPrivate = group.isPrivate else { return }
            var groupname = "your group"
            if group.groupname != "" {
                groupname = notification.group?.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") ?? ""
            }
            if isPrivate {
                notificationsLabel.text = "made " + groupname + " private"
            }
            else {
                notificationsLabel.text = "made " + groupname + " public"
            }
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.groupPostComment {
            var groupname = "your group"
            if notification.group?.groupname ?? "" != "" {
                groupname = notification.group?.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") ?? ""
            }
            notificationsLabel.text = "commented on " + groupname + "'s post "
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowComments))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.mentionedInComment {
            notificationsLabel.text = "mentioned you in a comment"
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowComments))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.newGroupPost {
            var groupname = "your group"
            if notification.group?.groupname ?? "" != "" {
                groupname = notification.group?.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") ?? ""
            }
            notificationsLabel.text = "posted in " + groupname
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.unsubscribeRequest {
            guard let group = notification.group else { return }
            var groupname = "your group"
            if group.groupname != "" {
                groupname = notification.group?.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") ?? ""
            }
            notificationsLabel.text = "left " + groupname + ". Unfollow?"
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        if let profileImageUrl = notification.from.profileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        } else {
            profileImageView.image = #imageLiteral(resourceName: "user")
        }
        postImageView.image = UIImage()
        postImageView.layer.borderWidth = 0
        actionButton.setTitle("", for: .normal)
            
        Database.database().hasNotificationBeenInteractedWith(notificationId: notification.id, completion: { (seen) in
            if seen {
                self.backgroundColor = .white
            } else {
                self.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            }
        })
    }
    
    private func loadGroupMembersIcon(group: Group?){
        guard let group = group else { return }
        Database.database().fetchFirstNGroupMembers(groupId: group.groupId, n: 3, completion: { (first_n_users) in
            if let groupProfileImageUrl = group.groupProfileImageUrl {
                self.groupImageView.loadImage(urlString: groupProfileImageUrl)
                self.groupImageView.isHidden = false
                self.userOneImageView.isHidden = true
                self.userTwoImageView.isHidden = true
            } else {
                self.groupImageView.isHidden = true
                self.userOneImageView.isHidden = false
                self.userTwoImageView.isHidden = true
                
                if first_n_users.count > 0 {
                    if let userOneImageUrl = first_n_users[0].profileImageUrl {
                        self.userOneImageView.loadImage(urlString: userOneImageUrl)
                    } else {
                        self.userOneImageView.image = #imageLiteral(resourceName: "user")
                        self.userOneImageView.backgroundColor = .white
                    }
                }
                
                // set the second user (only if it exists)
                if first_n_users.count > 1 {
                    self.userTwoImageView.isHidden = false
                    if let userTwoImageUrl = first_n_users[1].profileImageUrl {
                        self.userTwoImageView.loadImage(urlString: userTwoImageUrl)
                        self.userTwoImageView.layer.borderWidth = 2
                    } else {
                        self.userTwoImageView.image = #imageLiteral(resourceName: "user")
                        self.userTwoImageView.backgroundColor = .white
                        self.userTwoImageView.layer.borderWidth = 2
                    }
                }
            }
        }) { (_) in }
    }
    
    private func reloadActionButton() {
        guard let userId = self.notification?.from.uid else { return }
        
        actionButton.type = .hidden
        
        if notification!.type == NotificationType.newFollow {
            actionButton.type = .loading
            self.groupImageView.isHidden = true
            self.userOneImageView.isHidden = true
            self.userTwoImageView.isHidden = true
            Database.database().isFollowingUser(withUID: userId, completion: { (following) in
                if following {
                    self.actionButton.type = .unfollow
                } else {
                    self.actionButton.type = .follow
                }
            }) { (err) in
                self.actionButton.type = .hidden
            }
        }
        // decision icon
        else if notification?.type == NotificationType.groupSubscribeRequest || notification?.type == NotificationType.groupJoinRequest {
            self.groupImageView.isHidden = true
            self.userOneImageView.isHidden = true
            self.userTwoImageView.isHidden = true
            Database.database().isInGroup(groupId: (self.notification?.group!.groupId)!, completion: { (inGroup) in
                if inGroup{
                    self.actionButton.group = self.notification?.group
                    self.actionButton.type = .decision
                }
                else {
                    self.actionButton.type = .hidden
                }
            }) { (err) in
                return
            }
        }
        // unsubscribe button
        else if notification?.type == NotificationType.unsubscribeRequest {
            self.groupImageView.isHidden = true
            self.userOneImageView.isHidden = true
            self.userTwoImageView.isHidden = true
            actionButton.type = .loading
            Database.database().isFollowingGroup(groupId: (self.notification?.group!.groupId)!, completion: { (following) in
                if following {
                    self.actionButton.type = .unsubscribe
                }
                else {
                    self.actionButton.type = .hidden
                }
            }) { (err) in
                return
            }
        }
        // normal group button
        else if notification!.type == NotificationType.newGroupJoin || notification?.type == NotificationType.newGroupSubscribe || notification?.type == NotificationType.groupProfileNameEdit || notification?.type == NotificationType.groupPrivacyChange || notification?.type == NotificationType.groupProfilePicEdit {
            Database.database().isInGroup(groupId: (self.notification?.group!.groupId)!, completion: { (inGroup) in
                if inGroup{
                    self.actionButton.group = self.notification?.group
                    self.loadGroupMembersIcon(group: self.notification?.group)
                }
            }) { (err) in
                return
            }
        }
        else if notification?.type == NotificationType.groupPostComment || notification!.type == NotificationType.newGroupPost || notification?.type == NotificationType.mentionedInComment {
            postImageView.loadImage(urlString: self.notification?.groupPost?.imageUrl ?? "")
            postImageView.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
            postImageView.layer.borderWidth = 0.5
            postImageView.layer.zPosition = 4;
            postImageView.isUserInteractionEnabled = true
        }
        else if notification?.type == NotificationType.groupJoinInvitation {
            self.groupImageView.isHidden = true
            self.userOneImageView.isHidden = true
            self.userTwoImageView.isHidden = true
            actionButton.type = .loading
            Database.database().isInGroup(groupId: (self.notification?.group!.groupId)!, completion: { (inGroup) in
                if inGroup{
                    self.actionButton.type = .hidden
                }
                else {
                    guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
                    Database.database().isUserInvitedToGroup(withUID: currentLoggedInUserId, groupId: (self.notification?.group!.groupId)!, completion: { (isInvited) in
                        if isInvited {
                            self.actionButton.group = self.notification?.group
                            self.actionButton.type = .join
                        }
                        else {
                            self.actionButton.type = .hidden
                        }
                    }) { (err) in
                        return
                    }
                }
            }) { (err) in
                return
            }
        }
    }
    
    @objc private func handleTap() {
        guard let notification = notification else { return }
        Database.database().interactWithNotification(notificationId: notification.id) { (err) in
            if err != nil {
                return
            }
            self.backgroundColor = .white
            guard let currentLoggedInUser = Auth.auth().currentUser?.uid else { return }
            if notification.type == NotificationType.newFollow {
                let previousButtonType = self.actionButton.type
                self.actionButton.type = .loading
                if previousButtonType == .follow {
                    Database.database().followUser(withUID: (notification.from.uid)) { (err) in
                        if err != nil {
                            self.actionButton.type = .hidden
                            return
                        }
                        self.reloadActionButton()
                        Database.database().createNotification(to: (self.notification?.from)!, notificationType: NotificationType.newFollow) { (err) in
                            if err != nil {
                                return
                            }
                        }
                    }
                } else if previousButtonType == .unfollow {
                    Database.database().unfollowUser(withUID: (notification.from.uid)) { (err) in
                        if err != nil {
                            self.actionButton.type = .hidden
                            return
                        }
                        self.reloadActionButton()
                    }
                }
            }
            else if notification.type == NotificationType.unsubscribeRequest {
                self.actionButton.type = .loading
                Database.database().removeGroupFromUserFollowing(withUID: currentLoggedInUser, groupId: (self.notification?.group!.groupId)!) { (err) in
                    if err != nil {
                        self.actionButton.type = .hidden
                        return
                    }
                    self.reloadActionButton()
                }
            }
            else if notification.type == NotificationType.groupJoinInvitation {
                self.actionButton.type = .loading
                guard let group = self.notification?.group else { return }
                Database.database().isInGroup(groupId: group.groupId, completion: { (inGroup) in
                    if inGroup{
                        // leave the group action here
                    }
                    else {
                        // join the group action
                        Database.database().acceptIntoGroup(withUID: currentLoggedInUser, groupId: group.groupId){ (err) in
                            if err != nil {
                                return
                            }
                            Database.database().removeFromGroupInvited(withUID: currentLoggedInUser, groupId: group.groupId) { (err) in
                                if err != nil {
                                    return
                                }
                                // notification that member is now in group
                                Database.database().fetchUser(withUID: currentLoggedInUser, completion: { (user) in
                                    Database.database().fetchGroupMembers(groupId: group.groupId, completion: { (members) in
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
                                
                                self.reloadActionButton()
                                self.delegate?.groupJoinAlert(group: group)
                                self.delegate?.handleShowGroup(group: group)

                                // notification to refresh
                                NotificationCenter.default.post(name: NSNotification.Name("updateMembers"), object: nil)
                                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                            }
                        }
                    }
                }) { (err) in
                    return
                }
            }
            else if notification.type == NotificationType.groupJoinRequest {
                self.handleShowGroupMemberRequest()
            }
            else if notification.type == NotificationType.groupSubscribeRequest {
                self.handleShowGroupSubscriberRequest()
            }
            else if notification.type == NotificationType.newGroupJoin || notification.type == NotificationType.newGroupPost || notification.type == NotificationType.groupPrivacyChange || notification.type == NotificationType.groupProfileNameEdit || notification.type == NotificationType.groupProfilePicEdit || notification.type == NotificationType.newGroupSubscribe {
                self.handleShowGroup()
            }
            NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
            NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
            NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
        }
    }
    
    @objc private func handleShowGroup() {
        guard let notification = notification else { return }
        guard let group = notification.group else { return }
        Database.database().interactWithNotification(notificationId: notification.id) { (err) in
            if err != nil {
                return
            }
            self.backgroundColor = .white
        }
        delegate?.handleShowGroup(group: group)
    }
    
    @objc private func handleShowComments() {
        guard let notification = notification else { return }
        guard let groupPost = notification.groupPost else { return }
        Database.database().interactWithNotification(notificationId: notification.id) { (err) in
            if err != nil {
                return
            }
            self.backgroundColor = .white
        }
        delegate?.handleShowComment(groupPost: groupPost)
    }
    
    @objc private func handleShowGroupMemberRequest() {
        guard let notification = notification else { return }
        guard let group = notification.group else { return }
        Database.database().interactWithNotification(notificationId: notification.id) { (err) in
            if err != nil {
                return
            }
            self.backgroundColor = .white
        }
        delegate?.handleShowGroupMemberRequest(group: group)
    }
    
    @objc private func handleShowGroupSubscriberRequest() {
        guard let notification = notification else { return }
        guard let group = notification.group else { return }
        Database.database().interactWithNotification(notificationId: notification.id) { (err) in
            if err != nil {
                return
            }
            self.backgroundColor = .white
        }
        delegate?.handleShowGroupSubscriberRequest(group: group)
    }
    
    @objc private func handleDidTapFromUser() {
        guard let notification = notification else { return }
        Database.database().interactWithNotification(notificationId: notification.id) { (err) in
            if err != nil {
                return
            }
            self.backgroundColor = .white
        }
        
        delegate?.handleShowUser(user: notification.from)
    }
    
    @objc private func handleDidTapPost() {
        guard let notification = notification else { return }
        guard let group = notification.group else { return }
        guard let post = notification.groupPost else { return }
        Database.database().interactWithNotification(notificationId: notification.id) { (err) in
            if err != nil {
                return
            }
            self.backgroundColor = .white
        }
        delegate?.didTapPost(group: group, post: post)
    }
    
    
}

//MARK: - ActionButtonType

private enum ActionButtonType {
    case loading, follow, unfollow, join, hidden, decision, unsubscribe
}

//MARK: - ActionButton

private class ActionButton: UIButton {
    
    var type: ActionButtonType = .hidden {
        didSet {
            configureButton()
        }
    }
    
    var group: Group? {
        didSet {
            configureGroupButton()
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
        case .follow:
            setupFollowStyle()
        case .unfollow:
            setupUnfollowStyle()
        case .hidden:
            setupHiddenStyle()
        case .decision:
            setupDecisionStyle()
        case .unsubscribe:
            setupUnsubscribeStyle()
        }
    }
    
    private func configureGroupButton(){
        setupGroupStyle()
    }
    
    private func setupLoadingStyle() {
        setTitle("Loading", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .clear
        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        layer.cornerRadius = 5
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        isUserInteractionEnabled = false
        setImage(UIImage(), for: .normal)
    }
    
    private func setupJoinStyle() {
        setTitle("Join", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = .clear
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1.4
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        isUserInteractionEnabled = true
        setImage(UIImage(), for: .normal)
    }
    
    private func setupFollowStyle() {
        setTitle("Follow", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = .clear
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1.4
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        isUserInteractionEnabled = true
        setImage(UIImage(), for: .normal)
    }
    
    private func setupUnfollowStyle() {
        setTitle("Unfollow", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = .clear
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.borderWidth = 1.4
        layer.cornerRadius = 5
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        isUserInteractionEnabled = true
        setImage(UIImage(), for: .normal)
    }
    
    private func setupUnsubscribeStyle() {
        setTitle("Unsubscribe", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = .clear
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.borderWidth = 1.4
        layer.cornerRadius = 5
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        isUserInteractionEnabled = true
        setImage(UIImage(), for: .normal)
    }
    
    private func setupHiddenStyle() {
        setTitle("", for: .normal)
        backgroundColor = .clear
        setImage(UIImage(), for: .normal)
        layer.borderColor = UIColor(white: 0, alpha: 0).cgColor
        isUserInteractionEnabled = false
    }
    
    private func setupGroupStyle() {
//        if self.group?.groupname != ""{
//            setTitle(String(self.group?.groupname.first?.description ?? ""), for: .normal)
//        }
//        else {
//            setTitle("G", for: .normal)
//        }
        setTitle("", for: .normal)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        setTitleColor(.black, for: .normal)
        backgroundColor = .clear
        setImage(UIImage(), for: .normal)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
//        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        layer.borderColor = UIColor(white: 0, alpha: 0).cgColor
        layer.cornerRadius = 5
        isUserInteractionEnabled = true
    }
    
    private func setupDecisionStyle() {
        let image = #imageLiteral(resourceName: "decision")
//        button.frame = CGRectMake(100, 100, 100, 100)
        setTitle("", for: .normal)
        setImage(image, for: .normal)
        tintColor = .black
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        layer.cornerRadius = 5
//        layer.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 5, width: 50, height: 50)
        isUserInteractionEnabled = true
    }
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        return iv
    }()
    
}
