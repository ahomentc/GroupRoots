import UIKit
import Firebase

//MARK: - UserProfileHeaderDelegate

protocol UserProfileHeaderDelegate {
    func didChangeToListView()
    func didChangeToGridView()
    func handleShowNewGroup()
    func handleInviteGroup()
    func didSelectFollowPage(showFollowers: Bool)
    func didSelectSubscriptionsPage()
}

//MARK: - UserProfileHeader

class UserProfileHeader: UICollectionViewCell {
   
    var delegate: UserProfileHeaderDelegate?
    
    var user: User? {
        didSet {
            reloadData()
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
    
    private lazy var followersLabel: UserProfileStatsLabel = {
        let label = UserProfileStatsLabel(value: 0, title: "followers")
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowFollowersPage))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private lazy var followingLabel: UserProfileStatsLabel = {
        let label = UserProfileStatsLabel(value: 0, title: "following")
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowFollowingPage))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private lazy var subscriptionsLabel: UserProfileStatsLabel = {
        let label = UserProfileStatsLabel(value: 0, title: "subscriptions")
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowSubscriptionsPage))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private lazy var followButton: UserProfileFollowButton = {
        let button = UserProfileFollowButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return button
    }()
    
    private lazy var GroupButton: GroupRecruitButton = {
        let button = GroupRecruitButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleGroupMembership), for: .touchUpInside)
        return button
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        return label
    }()
    
    private let padding: CGFloat = 12
    
    static var headerId = "userProfileHeaderId"
    
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
//        profileImageView.layer.cornerRadius = 80 / 2
        profileImageView.layer.cornerRadius = 32
        
        let stackView = UIStackView(arrangedSubviews: [followingLabel, followersLabel, subscriptionsLabel])
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        addSubview(stackView)
        stackView.anchor(top: topAnchor, left: profileImageView.rightAnchor, right: rightAnchor, paddingTop: padding + 10, paddingLeft: padding - 5, paddingRight: padding - 5)
        
//        addSubview(GroupButton)
//        GroupButton.anchor(top: stackView.bottomAnchor, left: profileImageView.rightAnchor, right: rightAnchor, paddingTop: padding, paddingLeft: padding + 10, paddingRight: padding, height: 34)
//
//        addSubview(followButton)
//        followButton.anchor(top: GroupButton.bottomAnchor, left: profileImageView.rightAnchor, right: rightAnchor, paddingTop: padding, paddingLeft: padding + 10, paddingRight: padding, height: 34)
        
        addSubview(GroupButton)
        GroupButton.anchor(top: stackView.bottomAnchor, right: rightAnchor, paddingTop: padding, paddingLeft: padding + 10, paddingRight: padding, height: 34)
        
        addSubview(followButton)
        followButton.anchor(top: stackView.bottomAnchor, left: profileImageView.rightAnchor, right: GroupButton.leftAnchor, paddingTop: padding, paddingLeft: padding + 10, paddingRight: padding, height: 34)
                
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name.updateUserProfile, object: nil)
    }
    
    @objc func reloadData() {
        guard let user = user else { return }
        usernameLabel.text = user.username
        reloadFollowButton()
        reloadGroupButton()
        reloadUserStats()
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        }
    }
    
    private func reloadFollowButton() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let userId = user?.uid else { return }
        
        if currentLoggedInUserId == userId {
            followButton.type = .edit
            return
        }
        
        let previousButtonType = followButton.type
        followButton.type = .loading
        Database.database().isFollowingUser(withUID: userId, completion: { (following) in
            if following {
                self.followButton.type = .unfollow
            } else {
                self.followButton.type = .follow
            }
        }) { (err) in
            self.followButton.type = previousButtonType
        }
    }
    
    private func reloadGroupButton() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let userId = user?.uid else { return }
        
        if currentLoggedInUserId == userId {
            GroupButton.type = .new
        }
        else {
            GroupButton.type = .invite
        }
    }
    
    private func reloadUserStats() {
        guard let uid = user?.uid else { return }
        
        Database.database().numberOfFollowersForUser(withUID: uid) { (count) in
            self.followersLabel.setValue(count)
        }
        
        Database.database().numberOfUsersFollowingForUser(withUID: uid) { (count) in
            self.followingLabel.setValue(count)
        }
        
        Database.database().numberOfSubscriptionsForUser(withUID: uid) { (count) in
            self.subscriptionsLabel.setValue(count)
        }
    }
    
    // this is the follow function
    // needs to be renamed
    @objc private func handleTap() {
        guard let userId = user?.uid else { return }
        if followButton.type == .edit { return }
        
        let previousButtonType = followButton.type
        followButton.type = .loading
        
        if previousButtonType == .follow {
            Database.database().followUser(withUID: userId) { (err) in
                if err != nil {
                    self.followButton.type = previousButtonType
                    return
                }
                self.reloadFollowButton()
                self.reloadUserStats()
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfile, object: nil) // updates user who tapped's profile
                Database.database().createNotification(to: self.user!, notificationType: NotificationType.newFollow) { (err) in
                    if err != nil {
                        return
                    }
                }
            }
            
        } else if previousButtonType == .unfollow {
            Database.database().unfollowUser(withUID: userId) { (err) in
                if err != nil {
                    self.followButton.type = previousButtonType
                    return
                }
                self.reloadFollowButton()
                self.reloadUserStats()
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfile, object: nil) // updates user who tapped's profile
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
    }
    
    @objc private func handleGroupMembership(){
        if GroupButton.type == .new{
            delegate?.handleShowNewGroup()
        }
        else if GroupButton.type == .invite{
            delegate?.handleInviteGroup()
        }
    }
    
    @objc private func handleChangeToGridView() {
        delegate?.didChangeToGridView()
    }
    
    @objc private func handleChangeToListView() {
        delegate?.didChangeToListView()
    }
    
    @objc private func handleShowFollowersPage() {
        delegate?.didSelectFollowPage(showFollowers: true)
    }
    
    @objc private func handleShowFollowingPage() {
        delegate?.didSelectFollowPage(showFollowers: false)
    }
    
    @objc private func handleShowSubscriptionsPage() {
        delegate?.didSelectSubscriptionsPage()
    }
}

//MARK: - UserProfileStatsLabel

private class UserProfileStatsLabel: UILabel {
    
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
//        textAlignment = .left
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

//MARK: - FollowButtonType

private enum FollowButtonType {
    case loading, edit, follow, unfollow
}

//MARK: - UserProfileFollowButton

private class UserProfileFollowButton: UIButton {
    
    var type: FollowButtonType = .loading {
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
        case .edit:
            setupEditStyle()
        case .follow:
            setupFollowStyle()
        case .unfollow:
            setupUnfollowStyle()
        }
    }
    
    private func setupLoadingStyle() {
        setTitle("Loading", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
        layer.borderColor = UIColor(white: 0, alpha: 0).cgColor
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        isUserInteractionEnabled = false
    }
    
    private func setupEditStyle() {
//        setTitle("Edit Profile", for: .normal)
//        setTitleColor(.black, for: .normal)
//        backgroundColor = .white
//        contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
//        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
//        isUserInteractionEnabled = true
        
        setTitle("", for: .normal)
        backgroundColor = .white
        layer.borderColor = UIColor(white: 0, alpha: 0).cgColor
        isUserInteractionEnabled = false
    }
    
    private func setupFollowStyle() {
        setTitle("Follow", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = UIColor.white
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)   
        layer.cornerRadius = 5
        layer.borderWidth = 1.2
        isUserInteractionEnabled = true
    }
    
    private func setupUnfollowStyle() {
        setTitle("Unfollow", for: .normal)
        setTitleColor(.black, for: .normal)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        backgroundColor = .white
        isUserInteractionEnabled = true
    }
    
}

//MARK: - RecruitButtonType

private enum RecruitButtonType {
    case new, invite
}

//MARK: - GroupRecruitButton

private class GroupRecruitButton: UIButton {
    
    var type: RecruitButtonType = .new {
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
        configureButton()
    }
    
    private func configureButton() {
        switch type {
        case .new:
            setupNewStyle()
        case .invite:
            setupInviteStyle()
        }
    }
    
    private func setupNewStyle() {
        setTitle("New Group", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = UIColor.white
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1.2
        contentEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        isUserInteractionEnabled = true
    }
    
    private func setupInviteStyle() {
        setTitle("Invite to a Group", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = UIColor.white
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1.2
        contentEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        isUserInteractionEnabled = true
    }
    
}
