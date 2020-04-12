//
//  FollowerCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 2/29/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

protocol GroupFollowersCellDelegate {
}


class GroupFollowerCell: UICollectionViewCell {
    
    var delegate: GroupFollowersCellDelegate?
    
    var showRemoveButton: Bool? {
        didSet {
            setButtons()
        }
    }
    
    var user: User? {
        didSet {
            configureCell()
        }
    }
    
    var isFollowersView : Bool? {
        didSet {
            setButtons()
        }
    }
    
    func setButtons(){
        guard let isFollowersView = isFollowersView else { return }
        guard let showRemoveButton = showRemoveButton else { return }
        // subscriptions page
        if isFollowersView{
            if showRemoveButton {
                self.actionButton.type = .removeFollow
                self.denyButton.type = .hide
            }
            else {
                self.actionButton.type = .hide
                self.denyButton.type = .hide
            }
        }
        // pending subscriptions page
        else{
            self.actionButton.type = .acceptFollow
            self.denyButton.type = .deny
        }
    }
    
    
    
    var group: Group!
    
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
    
    private lazy var actionButton: ActionButton = {
        let button = ActionButton(type: .system)
        button.type = .acceptFollow
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleActionButton), for: .touchUpInside)
        return button
    }()
    
    // accept and deny are in the pending subscribers scenario. That's why there are two buttons
    // actionButton is the accept button denyButton is to deny
    // actionButton is ALSO used as the remove follow button in the subscribers page
    private lazy var denyButton: ActionButton = {
        let button = ActionButton(type: .system)
        button.type = .deny
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleDenyButton), for: .touchUpInside)
        return button
    }()
    
    static var cellId = "groupFollowerCellId"
    
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
        profileImageView.layer.cornerRadius = 50 / 2
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 8)
        
        addSubview(actionButton)
        actionButton.anchor(top: topAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 10, paddingBottom: 10, paddingRight: 8)
        
        addSubview(denyButton)
        denyButton.anchor(top: topAnchor, bottom: bottomAnchor, right: actionButton.leftAnchor, paddingTop: 10, paddingBottom: 10, paddingRight: 8)
        
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
    }
    
    @objc private func handleDenyButton(){
        guard let user = user else { return }
        guard let group = group else { return }
        
        if self.denyButton.type == .deny {
            // Remove user from pending and add user to removed
            Database.database().removeUserFromGroupPending(withUID:user.uid,groupId: group.groupId){ (err) in
                if err != nil {
                    return
                }
                Database.database().addUserToGroupRemovedUsers(withUID: user.uid, groupId: group.groupId) { (err) in
                    if err != nil {
                        return
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
                }
            }
        }
    }
    
    @objc private func handleActionButton(){
        guard let user = user else { return }
        guard let group = group else { return }
        
        if self.actionButton.type == .removeFollow {
            Database.database().removeUserFromGroupFollowers(withUID:user.uid,groupId: group.groupId){ (err) in
                if err != nil {
                    return
                }
                // notification to refresh
                NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
            }
        }
        else if self.actionButton.type == .acceptFollow {
            // Remove user from pending and add user to followers
            Database.database().removeUserFromGroupPending(withUID:user.uid,groupId: group.groupId){ (err) in
                if err != nil {
                    return
                }

                Database.database().addToGroupFollowers(groupId: group.groupId, withUID: user.uid) { (err) in
                    if err != nil {
                        return
                    }
                    Database.database().addToGroupsFollowing(groupId: group.groupId, withUID: user.uid) { (err) in
                        if err != nil {
                            return
                        }
                        // notification to refresh
                        NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
                    }
                }
            }
        }
    }
}

//MARK: - JoinButtonType

private enum JoinButtonType {
    case loading, acceptFollow, deny, hide, removeFollow
}

//MARK: - ActionButton

private class ActionButton: UIButton {
    
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
        case .removeFollow:
            setupRemoveFollowStyle()
        case .acceptFollow:
            setupAcceptStyle()
        case .deny:
            setupDenyStyle()
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
    
    private func setupDenyStyle() {
        setTitle("Deny", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        layer.borderColor = UIColor.gray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 5
        isUserInteractionEnabled = true
    }
    
    private func setupAcceptStyle() {
        setTitle("Accept", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = UIColor.white
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1.4
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        isUserInteractionEnabled = true
    }
    
    private func setupHideStyle() {
        setTitle("", for: .normal)
        setTitleColor(.white, for: .normal)
        backgroundColor = UIColor.white
        layer.borderColor = UIColor(white: 0, alpha: 0).cgColor
        isUserInteractionEnabled = false
    }
    
    private func setupRemoveFollowStyle() {
        setTitle("Remove", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = UIColor.white
        layer.borderColor = UIColor.gray.cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray.cgColor
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        isUserInteractionEnabled = true
    }
}




