//
//  SubscriptionCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 3/7/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

class SubscriptionCell: UICollectionViewCell {
    
    var group: Group? {
        didSet {
            configureCell()
        }
    }
    
    private lazy var subscribeButton: SubscribeButton = {
        let button = SubscribeButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        return button
    }()

    private let profileImageView: CustomImageView = {
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
        iv.layer.borderWidth = 0
        return iv
    }()
    
    private let userTwoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 0
        return iv
    }()
    
    private let groupnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        return label
    }()
    
    static var cellId = "subscriptionCellId"
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
        profileImageView.anchor(left: leftAnchor, paddingLeft: 8, width: 60, height: 60)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 60 / 2
        profileImageView.isHidden = false
        
        addSubview(userOneImageView)
        userOneImageView.anchor(left: leftAnchor, paddingTop: 10, paddingLeft: 28, width: 40, height: 40)
        userOneImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userOneImageView.layer.cornerRadius = 40/2
        userOneImageView.isHidden = true
        userOneImageView.image = UIImage()
        
        addSubview(userTwoImageView)
        userTwoImageView.anchor(left: leftAnchor, paddingTop: 0, paddingLeft: 8, width: 44, height: 44)
        userTwoImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userTwoImageView.layer.cornerRadius = 44/2
        userTwoImageView.isHidden = true
        userOneImageView.image = UIImage()
        
        addSubview(groupnameLabel)
        groupnameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 12)
        
        addSubview(subscribeButton)
        subscribeButton.anchor(top: topAnchor, right: rightAnchor, paddingTop: padding, paddingRight: padding, height: 40)
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.2)

    }
    
    private func configureCell() {
        guard let group = group else { return }
        
        groupnameLabel.text = group.groupname.replacingOccurrences(of: "_-a-_", with: " ")
        Database.database().fetchFirstNGroupMembers(groupId: group.groupId, n: 3, completion: { (first_n_users) in
            if group.groupname != "" {
                self.groupnameLabel.text = group.groupname.replacingOccurrences(of: "_-a-_", with: " ")
            }
            else {
                if first_n_users.count > 2 {
                    var usernames = first_n_users[0].username + " & " + first_n_users[1].username + " & " + first_n_users[2].username
                    if usernames.count > 15 {
                        usernames = String(usernames.prefix(15)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                    self.groupnameLabel.text = usernames
                }
                else if first_n_users.count == 2 {
                    var usernames = first_n_users[0].username + " & " + first_n_users[1].username
                    if usernames.count > 15 {
                        usernames = String(usernames.prefix(15)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                    self.groupnameLabel.text = usernames
                }
                else if first_n_users.count == 1 {
                    var usernames = first_n_users[0].username
                    if usernames.count > 15 {
                        usernames = String(usernames.prefix(15)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                    self.groupnameLabel.text = usernames
                }
            }

            if let groupProfileImageUrl = group.groupProfileImageUrl {
                self.profileImageView.loadImage(urlString: groupProfileImageUrl)
                self.profileImageView.isHidden = false
                self.userOneImageView.isHidden = true
                self.userTwoImageView.isHidden = true
            } else {
                self.profileImageView.isHidden = true
                self.userOneImageView.isHidden = false
                self.userTwoImageView.isHidden = true
                
                if let userOneImageUrl = first_n_users[0].profileImageUrl {
                    self.userOneImageView.loadImage(urlString: userOneImageUrl)
                } else {
                    self.userOneImageView.image = #imageLiteral(resourceName: "user")
                    self.userOneImageView.backgroundColor = .white
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
        
        reloadSubscriptionsButton()
    }
    
    private func reloadSubscriptionsButton() {
        guard let groupId = group?.groupId else { return }
        let previousButtonType = subscribeButton.type
        subscribeButton.type = .loading
        Database.database().isFollowingGroup(groupId: groupId, completion: { (is_subscribed) in
            if is_subscribed {
                self.subscribeButton.type = .unsubscribe
            } else {
                self.subscribeButton.type = .subscribe
            }
        }) { (err) in
            self.subscribeButton.type = previousButtonType
        }
    }
    
    @objc private func handleTap() {
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
                self.reloadSubscriptionsButton() // put this in callback
                NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
            }
            
            
        } else if previousButtonType == .unsubscribe {
            Database.database().removeGroupFromUserFollowing(withUID: currentLoggedInUserId, groupId: groupId) { (err) in
                if err != nil {
                    self.subscribeButton.type = previousButtonType
                    return
                }
                self.reloadSubscriptionsButton() // put this in callback
                NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name.updateHomeFeed, object: nil)
    }
}

//MARK: - SubscribeButtonType

private enum SubscribeButtonType {
    case loading, subscribe, unsubscribe
}

//MARK: - SubscribeButton

private class SubscribeButton: UIButton {
    
    var type: SubscribeButtonType = .loading {
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
        layer.borderColor = UIColor(white: 0, alpha: 0).cgColor
        isUserInteractionEnabled = false
    }
    
    private func setupSubscribeStyle() {
        setTitle("Subscribe", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = UIColor.white
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layer.cornerRadius = 5
        layer.borderWidth = 1.2
        isUserInteractionEnabled = true
    }
    
    private func setupUnsubscribeStyle() {
        setTitle("Unsubscribe", for: .normal)
        setTitleColor(.black, for: .normal)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        backgroundColor = .white
        isUserInteractionEnabled = true
    }
    
}
