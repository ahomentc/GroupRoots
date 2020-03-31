import UIKit
import Firebase

//MARK: - NotificationCellDelegate

protocol NotificationCellDelegate {
    func handleShowGroup(group: Group)
    func handleShowUser(user: User)
    func didTapPost(group: Group, post: GroupPost)
    func groupJoinAlert(group: Group)
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
        profileImageView.layer.cornerRadius = 5
        
        addSubview(postImageView)
        postImageView.anchor(right: rightAnchor, paddingRight: 8, width: 50, height: 50)
        postImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        postImageView.layer.cornerRadius = 5
        postImageView.image = UIImage()
        postImageView.layer.borderWidth = 0
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, paddingTop: 16, paddingLeft: 12)
        
        addSubview(notificationsLabel)
        notificationsLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, paddingTop: 24, paddingLeft: 12)
        
        addSubview(actionButton)
        actionButton.anchor(top: topAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 15, paddingBottom: 15, paddingRight: 8)
        
    }
    
    private func configureCell() {
        guard let notification = notification else { return }
        
        usernameLabel.text = (notification.from.username ?? "GroupRoots")
        if notification.type == NotificationType.newFollow {
            notificationsLabel.text = "followed you"
        }
        else if notification.type == NotificationType.groupJoinInvitation {
            notificationsLabel.text = "invited you to join " + (notification.group!.groupname)
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.newGroupJoin {
            notificationsLabel.text = "joined " + (notification.group!.groupname)
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.groupJoinRequest {
            notificationsLabel.text = "requested to join " + (notification.group!.groupname)
            notificationsLabel.isUserInteractionEnabled = true
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowGroup))
            notificationsLabel.addGestureRecognizer(gestureRecognizer)
        }
        else if notification.type == NotificationType.groupPostComment {
            notificationsLabel.text = "commented on " + (notification.group!.groupname) + "'s post "
        }
        else if notification.type == NotificationType.groupPostLiked {
            notificationsLabel.text = "liked " + (notification.group!.groupname) + "'s post "
        }
        else if notification.type == NotificationType.newGroupPost {
            notificationsLabel.text = "posted in " + (notification.group!.groupname)
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
            
        Database.database().hasNotificationBeenSeen(notificationId: notification.id, completion: { (seen) in
            if seen {
                self.backgroundColor = .white
            } else {
                self.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            }
        })
    }
    
    private func reloadActionButton() {
        guard let userId = self.notification?.from.uid else { return }
        
        actionButton.type = .hidden
        
        if notification!.type == NotificationType.newFollow {
            actionButton.type = .loading
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
        else if notification!.type == NotificationType.newGroupJoin || notification?.type == NotificationType.groupJoinRequest {
            Database.database().isInGroup(groupId: (self.notification?.group!.groupId)!, completion: { (inGroup) in
                if inGroup{
                    self.actionButton.group = self.notification?.group
                }
            }) { (err) in
                return
            }
        }
        else if notification?.type == NotificationType.groupPostComment || notification!.type == NotificationType.newGroupPost {
            postImageView.loadImage(urlString: self.notification?.groupPost?.imageUrl ?? "")
            postImageView.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
            postImageView.layer.borderWidth = 0.5
            postImageView.layer.zPosition = 4;
            postImageView.isUserInteractionEnabled = true
        }
        else if notification?.type == NotificationType.groupJoinInvitation {
            Database.database().isInGroup(groupId: (self.notification?.group!.groupId)!, completion: { (inGroup) in
                if inGroup{
                    self.actionButton.type = .hidden
                    print("hidden")
                }
                else {
                    self.actionButton.group = self.notification?.group
                    self.actionButton.type = .join
                }
            }) { (err) in
                return
            }
            
        }
    }
    
    @objc private func handleTap() {
        guard let notification = notification else { return }
        Database.database().viewNotification(notificationId: notification.id) { (err) in
            if err != nil {
                return
            }
            self.backgroundColor = .white
        }
        
        guard let currentLoggedInUser = Auth.auth().currentUser?.uid else { return }
//        actionButton.type = .hidden
        if notification.type == NotificationType.newFollow {
            let previousButtonType = actionButton.type
            actionButton.type = .loading
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
        else if notification.type == NotificationType.groupJoinInvitation {
            Database.database().isInGroup(groupId: (self.notification?.group!.groupId)!, completion: { (inGroup) in
                if inGroup{
                    // leave the group action here
                }
                else {
                    // join the group action
                    Database.database().acceptIntoGroup(withUID: currentLoggedInUser, groupId: (self.notification?.group!.groupId)!){ (err) in
                        if err != nil {
                            return
                        }
                        Database.database().removeFromGroupInvited(withUID: currentLoggedInUser, groupId: (self.notification?.group!.groupId)!) { (err) in
                            if err != nil {
                                return
                            }
                            // notification that member is now in group
                            Database.database().fetchUser(withUID: currentLoggedInUser, completion: { (user) in
                                Database.database().fetchGroup(groupId: (self.notification?.group!.groupId)!, completion: { (group) in
                                    Database.database().fetchGroupMembers(groupId: (self.notification?.group!.groupId)!, completion: { (members) in
                                        members.forEach({ (member) in
                                            if user.uid != member.uid {
                                                Database.database().createNotification(to: member, notificationType: NotificationType.newGroupJoin, subjectUser: user, group: group) { (err) in
                                                    if err != nil {
                                                        return
                                                    }
                                                    self.reloadActionButton()
                                                    self.delegate?.groupJoinAlert(group: group)
                                                    self.delegate?.handleShowGroup(group: group)
                                                }
                                            }
                                        })
                                    }) { (_) in}
                                })
                            })

                            // notification to refresh
                            NotificationCenter.default.post(name: NSNotification.Name("updateMembers"), object: nil)
                        }
                    }
                }
            }) { (err) in
                return
            }
        }
        else if notification.type == NotificationType.newGroupJoin || notification.type == NotificationType.newGroupPost || notification.type == NotificationType.groupJoinRequest {
            self.handleShowGroup()
        }
        NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
    }
    
    @objc private func handleShowGroup() {
        guard let notification = notification else { return }
        Database.database().viewNotification(notificationId: notification.id) { (err) in
            if err != nil {
                return
            }
            self.backgroundColor = .white
        }
        
        delegate?.handleShowGroup(group: (self.notification?.group!)!)
        self.reloadActionButton()
    }
    
    @objc private func handleDidTapFromUser() {
        guard let notification = notification else { return }
        Database.database().viewNotification(notificationId: notification.id) { (err) in
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
        Database.database().viewNotification(notificationId: notification.id) { (err) in
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
    case loading, follow, unfollow, join, hidden
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
    }
    
    private func setupJoinStyle() {
        setTitle("Join", for: .normal)
//        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = .clear
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1.4
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        isUserInteractionEnabled = true
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
    }
    
    private func setupUnfollowStyle() {
        setTitle("Unfollow", for: .normal)
//        setTitleColor(.white, for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
//        backgroundColor = UIColor.mainBlue
        backgroundColor = .clear
//        UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
//        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.borderWidth = 1.4
        layer.cornerRadius = 5
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        isUserInteractionEnabled = true
    }
    
    private func setupHiddenStyle() {
        setTitle("", for: .normal)
        backgroundColor = .clear
        layer.borderColor = UIColor(white: 0, alpha: 0).cgColor
        isUserInteractionEnabled = false
    }
    
    private func setupGroupStyle() {
        if self.group?.groupname != ""{
            setTitle(String(self.group?.groupname.first?.description ?? ""), for: .normal)
        }
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        setTitleColor(.black, for: .normal)
        backgroundColor = .clear
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 25)
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
