//
//  FeedPostCellHeader.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/23/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol FeedPostCellHeaderDelegate {
    func didTapGroup()
    func didTapOptions()
}

class FeedPostCellHeader: UIView {
    
    var group: Group? {
        didSet {
            configureGroup()
        }
    }
    
    var groupMembers: [User]? {
        didSet {
            configureGroup()
        }
    }
    
    var delegate: FeedPostCellHeaderDelegate?
    
    private var padding: CGFloat = 8
    
    private lazy var groupProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))
        iv.isUserInteractionEnabled  = true
        return iv
    }()
    
    private lazy var firstMemberImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))
        iv.isUserInteractionEnabled  = true
        return iv
    }()
    
    private lazy var secondMemberImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))
        iv.isUserInteractionEnabled  = true
        return iv
    }()
    
    private lazy var thirdMemberImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0
        iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))
        iv.isUserInteractionEnabled  = true
        return iv
    }()
    
    private lazy var usernameButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(.black, for: .normal)
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        label.contentHorizontalAlignment = .left
        label.isUserInteractionEnabled = true
        label.addTarget(self, action: #selector(handleGroupTap), for: .touchUpInside)
        return label
    }()
    
    private let optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("•••", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.addTarget(self, action: #selector(handleOptionsTap), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(groupProfileImageView)
        groupProfileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, paddingTop: padding + 20, paddingLeft: padding + 20, paddingBottom: padding, width: 50 , height: 50)
        groupProfileImageView.layer.cornerRadius = 50/2
        groupProfileImageView.layer.zPosition = 8
        groupProfileImageView.layer.borderWidth = 0
        groupProfileImageView.layer.borderColor = UIColor.white.cgColor
        groupProfileImageView.isUserInteractionEnabled = true
        groupProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))
        groupProfileImageView.image = #imageLiteral(resourceName: "user")
        
        addSubview(firstMemberImageView)
        firstMemberImageView.anchor(top: topAnchor, left: groupProfileImageView.rightAnchor, bottom: bottomAnchor, paddingTop: padding + 20, paddingLeft: -20, paddingBottom: padding, width: 50 , height: 50)
        firstMemberImageView.layer.cornerRadius = 50/2
        firstMemberImageView.layer.borderWidth = 0
        firstMemberImageView.layer.borderColor = UIColor.white.cgColor
        firstMemberImageView.layer.zPosition = 7
        firstMemberImageView.isUserInteractionEnabled = true
        firstMemberImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))
        firstMemberImageView.image = #imageLiteral(resourceName: "user")

        addSubview(secondMemberImageView)
        secondMemberImageView.anchor(top: topAnchor, left: firstMemberImageView.rightAnchor, bottom: bottomAnchor, paddingTop: padding + 20, paddingLeft: -20, paddingBottom: padding, width: 50, height: 50)
        secondMemberImageView.layer.cornerRadius = 50/2
        secondMemberImageView.layer.borderWidth = 0
        secondMemberImageView.layer.borderColor = UIColor.white.cgColor
        secondMemberImageView.layer.zPosition = 6
        secondMemberImageView.isUserInteractionEnabled = true
        secondMemberImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))
        secondMemberImageView.image = UIImage()
        
//        addSubview(thirdMemberImageView)
//        thirdMemberImageView.anchor(top: topAnchor, left: secondMemberImageView.rightAnchor, bottom: bottomAnchor, paddingTop: padding + 20, paddingLeft: padding, paddingBottom: padding, width: 50, height: 50)
//        thirdMemberImageView.layer.cornerRadius = 20
//        thirdMemberImageView.isUserInteractionEnabled = true
//        thirdMemberImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))
//        thirdMemberImageView.image = UIImage()
         
        addSubview(usernameButton)
        usernameButton.anchor(top: firstMemberImageView.bottomAnchor, left: leftAnchor, paddingTop: padding, paddingLeft: padding + 20)
        usernameButton.isUserInteractionEnabled = true
        usernameButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))
        
//        addSubview(optionsButton)
//        optionsButton.anchor(top: topAnchor, bottom: bottomAnchor, right: rightAnchor, paddingRight: padding, width: 44)
    }
    
    open func clearPastCell() {
        self.groupProfileImageView.image = CustomImageView.imageWithColor(color: .clear)
        self.firstMemberImageView.image = CustomImageView.imageWithColor(color: .clear)
        self.secondMemberImageView.image = CustomImageView.imageWithColor(color: .clear)
        self.thirdMemberImageView.image = CustomImageView.imageWithColor(color: .clear)
        
        self.groupProfileImageView.backgroundColor = .clear
        self.firstMemberImageView.backgroundColor = .clear
        self.secondMemberImageView.backgroundColor = .clear
        self.thirdMemberImageView.backgroundColor = .clear
    }
    
    private func configureGroup() {
        clearPastCell()
        
        guard let group = group else { return }
        guard let groupMembers = groupMembers else { return }
        if groupMembers.count == 0 { return }
        
        // set groupname
        usernameButton.setTitle(group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘"), for: .normal)
        usernameButton.setTitleColor(.white, for: .normal)
                
        // set group and profile images
        configureMemberImages(group: group)
        
        // set up groupname if there is none
        Database.database().fetchFirstNGroupMembers(groupId: group.groupId, n: 3, completion: { (first_n_users) in
            if group.groupname == "" {
                if first_n_users.count > 2 {
                    var usernames = first_n_users[0].username + " & " + first_n_users[1].username + " & " + first_n_users[2].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                    self.usernameButton.setTitle(usernames, for: .normal)
                }
                else if first_n_users.count == 2 {
                    var usernames = first_n_users[0].username + " & " + first_n_users[1].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                    self.usernameButton.setTitle(usernames, for: .normal)
                }
                else if first_n_users.count == 1 {
                    var usernames = first_n_users[0].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                    self.usernameButton.setTitle(usernames, for: .normal)
                }
            }
        }) { (_) in }
    }
    
    func configureMemberImages(group: Group){
        guard let groupMembers = groupMembers else { return }
        self.groupProfileImageView.layer.borderWidth = 0
        self.firstMemberImageView.layer.borderWidth = 0
        self.secondMemberImageView.layer.borderWidth = 0
        self.thirdMemberImageView.layer.borderWidth = 0
        
        var image_count = 0
        
        if let profileImageUrl = group.groupProfileImageUrl {
            self.groupProfileImageView.loadImage(urlString: profileImageUrl)
            self.groupProfileImageView.layer.borderWidth = 2
            self.groupProfileImageView.layer.borderColor = UIColor.white.cgColor
            for user in groupMembers {
                if image_count < 3 {
                    if image_count == 0 {
                        self.firstMemberImageView.layer.borderWidth = 2
                        if let profileImageUrl = user.profileImageUrl {
                            self.firstMemberImageView.loadImage(urlString: profileImageUrl)
                        }
                        else {
                            self.firstMemberImageView.image = #imageLiteral(resourceName: "user")
                            self.firstMemberImageView.backgroundColor = .white
                        }
                    }
                    else if image_count == 1 {
                        self.secondMemberImageView.layer.borderWidth = 2
                        if let profileImageUrl = user.profileImageUrl {
                            self.secondMemberImageView.loadImage(urlString: profileImageUrl)
                        }
                        else {
                            self.secondMemberImageView.image = #imageLiteral(resourceName: "user")
                            self.secondMemberImageView.backgroundColor = .white
                        }
                    }
                    else if image_count > 1 {
                        self.thirdMemberImageView.layer.borderWidth = 2
                        if let profileImageUrl = user.profileImageUrl {
                            self.thirdMemberImageView.loadImage(urlString: profileImageUrl)
                        }
                        else {
                            self.thirdMemberImageView.image = #imageLiteral(resourceName: "user")
                            self.thirdMemberImageView.backgroundColor = .white
                        }
                    }
                    image_count += 1
                }
                else{
                    break
                }
            }
        } else {
            for user in groupMembers {
                if image_count < 3 {
                    if image_count == 0 {
                        self.groupProfileImageView.layer.borderWidth = 2
                        if let profileImageUrl = user.profileImageUrl {
                            self.groupProfileImageView.loadImage(urlString: profileImageUrl)
                        }
                        else {
                            self.groupProfileImageView.image = #imageLiteral(resourceName: "user")
                            self.groupProfileImageView.backgroundColor = .white
                        }
                    }
                    else if image_count == 1 {
                        self.firstMemberImageView.layer.borderWidth = 2
                        if let profileImageUrl = user.profileImageUrl {
                            self.firstMemberImageView.loadImage(urlString: profileImageUrl)
                        }
                        else {
                            self.firstMemberImageView.image = #imageLiteral(resourceName: "user")
                            self.firstMemberImageView.backgroundColor = .white
                        }
                    }
                    else if image_count == 2 {
                        self.secondMemberImageView.layer.borderWidth = 2
                        if let profileImageUrl = user.profileImageUrl {
                            self.secondMemberImageView.loadImage(urlString: profileImageUrl)
                        }
                        else {
                            self.secondMemberImageView.image = #imageLiteral(resourceName: "user")
                            self.secondMemberImageView.backgroundColor = .white
                        }
                    }
                    image_count += 1
                }
                else{
                    break
                }
            }
        }
    }
    
    @objc private func handleGroupTap() {
        delegate?.didTapGroup()
    }
    
    @objc private func handleOptionsTap() {
        delegate?.didTapOptions()
    }
}





