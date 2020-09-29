//
//  UserCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/18/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

//protocol UserFollowCellDelegate {
//    func acceptUserRequest()
//}


class FollowPageCell: UICollectionViewCell {
    
    var delegate: UserDecisionCellDelegate?
    
    var user: User? {
        didSet {
            configureCell()
        }
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
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    private lazy var followButton: FollowButton = {
        let button = FollowButton(type: .system)
        button.type = .follow
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return button
    }()

    static var cellId = "userFollowCellId"
    private let padding: CGFloat = 12
    
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
        profileImageView.anchor(left: leftAnchor, paddingLeft: 8, width: 50, height: 50)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 50/2
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 8)
        
        addSubview(followButton)
        followButton.anchor(top: topAnchor, right: rightAnchor, paddingTop: padding, paddingRight: padding, height: 40)
        
//        let separatorView = UIView()
//        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.2)
//        addSubview(separatorView)
//        separatorView.anchor(left: usernameLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, height: 0.5)
        
    }
    
    private func configureCell() {
        usernameLabel.text = user?.username
        if let profileImageUrl = user?.profileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        } else {
            profileImageView.image = #imageLiteral(resourceName: "user")
        }
        reloadFollowButton()
    }
    
    private func reloadFollowButton() {
        guard let uid = user?.uid else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let previousButtonType = followButton.type
        followButton.type = .loading
        if uid == currentLoggedInUserId {
            self.followButton.type = .hide
        }
        else {
            Database.database().isFollowingUser(withUID: uid, completion: { (is_following) in
                if is_following {
                    self.followButton.type = .unfollow
                } else {
                    self.followButton.type = .follow
                }
            }) { (err) in
                self.followButton.type = previousButtonType
            }
        }
    }
    
    @objc private func handleTap(){
        guard let userId = user?.uid else { return }
        
        let previousButtonType = followButton.type
        followButton.type = .loading
        
        if previousButtonType == .follow {
            // when you subscribe to group and group is in removedGroups, bypass that and remove the group from that list
            
            // check if a private group or not
            // remove from groupsBlocked if its there
            Database.database().followUser(withUID: userId) { (err) in
                if err != nil {
                    self.followButton.type = previousButtonType
                    return
                }
                self.reloadFollowButton() // put this in callback
                NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
            }
            
            
        } else if previousButtonType == .unfollow {
            Database.database().unfollowUser(withUID: userId) { (err) in
                if err != nil {
                    self.followButton.type = previousButtonType
                    return
                }
                print("done")
                self.reloadFollowButton() // put this in callback
                NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
    }
}

//MARK: - JoinButtonType

private enum FollowButtonType {
    case loading, follow, unfollow, hide
}

//MARK: - FollowButton

private class FollowButton: UIButton {

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
        case .follow:
            setupFollowStyle()
        case .unfollow:
            setupUnfollowStyle()
        case .hide:
            setupHideStyle()
        }
    }

    private func setupLoadingStyle() {
        setTitle("Loading", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
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

    private func setupHideStyle() {
        setTitle("", for: .normal)
        setTitleColor(.white, for: .normal)
        backgroundColor = UIColor.white
        layer.borderColor = UIColor(white: 0, alpha: 0).cgColor
        isUserInteractionEnabled = false
    }
}



