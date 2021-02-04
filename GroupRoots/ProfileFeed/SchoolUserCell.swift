//
//  SchoolUserCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 12/24/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class SchoolUserCell: UICollectionViewCell {
        
    var user: User? {
        didSet {
            configureCell()
        }
    }
    
    var num_groups: Int? {
        didSet {
            configureCell()
        }
    }
    
    var is_following: Bool? {
        didSet {
            configureCell()
        }
    }
    
    var group_has_profile_image: Bool? {
        didSet {
            configureCell()
        }
    }

    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 1
        return iv
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()
    
    private let numGroupsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    private lazy var followButton: UserProfileFollowButton = {
        let button = UserProfileFollowButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return button
    }()
    
    static var cellId = "schoolUserCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.backgroundColor = UIColor.clear
        self.user = nil
        self.profileImageView.image = CustomImageView.imageWithColor(color: .white)
        self.usernameLabel.text = ""
    }
    
    private func configureCell() {
        guard group_has_profile_image != nil else { return }
        guard let user = user else { return }
        guard let num_groups = num_groups else { return }
        guard let is_following = is_following else { return }
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 10, paddingLeft: 20, width: 60, height: 60)
        profileImageView.layer.cornerRadius = 60 / 2
        profileImageView.layer.shadowColor = UIColor.black.cgColor
        profileImageView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        profileImageView.layer.shadowOpacity = 0.2
        profileImageView.layer.shadowRadius = 5.0
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.backgroundColor = UIColor.white.cgColor
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 5, paddingRight: 0)
        
        addSubview(numGroupsLabel)
        numGroupsLabel.anchor(top: usernameLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 2, paddingRight: 0)
        
        addSubview(followButton)
        followButton.anchor(top: numGroupsLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 5, paddingRight: 5, height: 34)
        
        var username = user.username
        if username.count > 10 { // change to 10
            username = String(username.prefix(10)) // keep only the first 10 characters
            username = username + "..."
        }
        usernameLabel.text = username
        
        if num_groups == 1 {
            numGroupsLabel.text = String(num_groups) + " group"
        }
        else {
            numGroupsLabel.text = String(num_groups) + " groups"
        }
        
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        } else {
            profileImageView.image = #imageLiteral(resourceName: "user")
        }
        
        reloadFollowButton(isFollowing: is_following)
    }
    
    private func reloadFollowButton(isFollowing: Bool) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let userId = user?.uid else { return }

        if currentLoggedInUserId == userId {
            followButton.type = .hidden
            return
        }
        
        if isFollowing {
            self.followButton.type = .unfollow
        }
        else {
            self.followButton.type = .follow
        }
    }
    
    @objc private func handleTap() {
        guard let userId = user?.uid else { return }
//        guard let isBlocked = isBlocked else { return }
//
//        if isBlocked {
//            return
//        }
                
        let previousButtonType = followButton.type
        followButton.type = .loading
        
        if previousButtonType == .follow {
            Database.database().followUser(withUID: userId) { (err) in
                if err != nil {
                    self.followButton.type = previousButtonType
                    return
                }
                self.loadFollowButtonData()
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfile, object: nil) // updates user who tapped's profile
                
                // check if this is the first time the user has followed someone and if so, show the popup
                Database.database().hasFollowedSomeone(completion: { (hasFollowed) in
                    if !hasFollowed {
                        // add them to followed someone
                        // send notification to show popup
                        Database.database().followedSomeone() { (err) in }
                        NotificationCenter.default.post(name: NSNotification.Name("showFirstFollowPopupHomescreen"), object: nil)
                    }
                })
                
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
                self.loadFollowButtonData()
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfile, object: nil) // updates user who tapped's profile
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
    }
    
    private func loadFollowButtonData() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let userId = user?.uid else { return }

        if currentLoggedInUserId == userId {
            followButton.type = .hidden
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
}

private enum UserProfileFollowButtonType {
    case loading, follow, unfollow, hidden, edit
}

//MARK: - ActionButton

private class UserProfileFollowButton: UIButton {
    
    var type: UserProfileFollowButtonType = .hidden {
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
        case .follow:
            setupFollowStyle()
        case .unfollow:
            setupUnfollowStyle()
        case .hidden:
            setupHiddenStyle()
        case .edit:
            setupEditStyle()
        }
    }
    
    private func setupLoadingStyle() {
        setTitle("Loading", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .clear
//        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        layer.cornerRadius = 5
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        isUserInteractionEnabled = false
        setImage(UIImage(), for: .normal)
    }
    
    private func setupFollowStyle() {
        setTitle("Follow", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = .clear
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
//        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.cornerRadius = 5
//        layer.borderWidth = 1.4
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        isUserInteractionEnabled = true
        setImage(UIImage(), for: .normal)
    }
    
    private func setupUnfollowStyle() {
        setTitle("Unfollow", for: .normal)
        setTitleColor(.black, for: .normal)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
//        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        backgroundColor = .white
        isUserInteractionEnabled = true
    }
    
    private func setupEditStyle() {
        setTitle("Edit", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
//        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        layer.cornerRadius = 5
        isUserInteractionEnabled = true
    }
    
    private func setupHiddenStyle() {
        setTitle("", for: .normal)
        backgroundColor = .clear
        setImage(UIImage(), for: .normal)
        layer.borderColor = UIColor(white: 0, alpha: 0).cgColor
        isUserInteractionEnabled = false
    }
    
}




// MARK: UnlockUserCell
class UnlockSchoolUserCell: UICollectionViewCell {

    private let unlockLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: "+", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 25), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        attributedText.append(NSMutableAttributedString(string: "\nSee More", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.darkGray]))
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    static var cellId = "unlockSchoolUserCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        configureCell()
    }
    
    private func configureCell() {        
//        addSubview(unlockLabel)
//        unlockLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, height: 80)
        
        addSubview(unlockLabel)
        unlockLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 15, paddingBottom: 5, paddingRight: 15)
    }
}

