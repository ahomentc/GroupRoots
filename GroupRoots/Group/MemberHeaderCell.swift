//
//  MemberHeaderCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 4/6/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class MemberHeaderCell: UICollectionViewCell {
    
//    var delegate: GroupFollowersCellDelegate?
    
    var user: User? {
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
    
    static var cellId = "membersHeaderCellId"
    
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
    
    private func configureCell() {
        guard group_has_profile_image != nil else { return }
        guard let user = user else { return }
        
        addSubview(profileImageView)
        profileImageView.anchor(left: leftAnchor, width: 60, height: 60)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 60 / 2
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 5, paddingRight: 0)
        
        var username = user.username
        if username.count > 10 { // change to 10
            username = String(username.prefix(10)) // keep only the first 10 characters
            username = username + "..."
        }
        usernameLabel.text = username
        
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        } else {
            profileImageView.image = #imageLiteral(resourceName: "user")
        }
    }
}


// --------------------- GroupProfileHeaderCell ---------------------------


class GroupProfileHeaderCell: UICollectionViewCell {
    
    var profileImageUrl: String? {
        didSet {
            configureCellForGroupImage()
        }
    }
    
    var userOneImageUrl: String? {
        didSet {
            configureCellForUserImage()
            configureCellForGroupImage()
        }
    }
    
    var userTwoImageUrl: String? {
        didSet {
            configureCellForUserImage()
        }
    }
    
    var groupname: String? {
        didSet {
            setGroupname()
        }
    }
    
    private let groupLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "Group"
        label.textAlignment = .center
        return label
    }()
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = CustomImageView.imageWithColor(color: .white)
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 1
        iv.backgroundColor = .white
        iv.layer.zPosition = 10
        return iv
    }()
    
    private let userOneImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 1
        return iv
    }()
    
    private let userTwoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 1
        return iv
    }()
    
    static var cellId = "groupHeaderCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = CustomImageView.imageWithColor(color: .white)
        self.userOneImageView.image = CustomImageView.imageWithColor(color: .white)
        self.userTwoImageView.image = CustomImageView.imageWithColor(color: .white)
    }
    
    private func sharedInit() {
//        addSubview(profileImageView)
//        profileImageView.anchor(left: leftAnchor, paddingLeft: 0, width: 60, height: 60)
//        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//        profileImageView.layer.cornerRadius = 60 / 2
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 2, paddingLeft: -5, width: 60, height: 60)
        profileImageView.layer.cornerRadius = 60/2
        profileImageView.isHidden = true
        profileImageView.image = UIImage()
        
        addSubview(userOneImageView)
        userOneImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: -2, paddingLeft: 10, width: 58, height: 58)
//        userOneImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userOneImageView.layer.cornerRadius = 58/2
        userOneImageView.isHidden = true
        userOneImageView.image = UIImage()
        
        addSubview(userTwoImageView)
        userTwoImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 2, paddingLeft: -5, width: 60, height: 60)
//        userTwoImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userTwoImageView.layer.cornerRadius = 60/2
        userTwoImageView.isHidden = true
        userTwoImageView.image = UIImage()
        
        addSubview(groupLabel)
        groupLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 5, paddingRight: 0)
    }
    
    private func setGroupname() {
        guard var groupname = groupname else { return }
        
        if groupname == "" {
            groupLabel.text = "Group"
        }
        else {
            groupname = groupname.replacingOccurrences(of: "_-a-_", with: " ")
            if groupname.count > 10 { // change to 10
                groupname = String(groupname.prefix(10)) // keep only the first 10 characters
                groupname = groupname + "..."
            }
            groupLabel.text = groupname
        }
    }
    
    private func configureCellForGroupImage() {
        guard let profileImageUrl = profileImageUrl else { return }
        guard let userOneImageUrl = userOneImageUrl else { return }
        self.profileImageView.isHidden = false
        self.userOneImageView.isHidden = false
        self.userTwoImageView.isHidden = true
        if profileImageUrl != "" {
            profileImageView.loadImage(urlString: profileImageUrl)
        }
        if userOneImageUrl != "" {
            self.userOneImageView.loadImage(urlString: userOneImageUrl)
        }
        else {
            self.userOneImageView.image = #imageLiteral(resourceName: "user")
            self.userOneImageView.backgroundColor = .white
        }
    }
    
    private func configureCellForUserImage() {
        guard let userOneImageUrl = userOneImageUrl else { return }
        guard let userTwoImageUrl = userTwoImageUrl else { return }
        self.profileImageView.isHidden = true
        self.userOneImageView.isHidden = false
        self.userTwoImageView.isHidden = false
        
        if userOneImageUrl != "" {
            self.userOneImageView.loadImage(urlString: userOneImageUrl)
        }
        else {
            self.userOneImageView.image = #imageLiteral(resourceName: "user")
            self.userOneImageView.backgroundColor = .white
        }
        
        if userTwoImageUrl != "" {
            self.userTwoImageView.loadImage(urlString: userTwoImageUrl)
        }
        else {
            self.userTwoImageView.image = #imageLiteral(resourceName: "user")
            self.userTwoImageView.backgroundColor = .white
        }
    }
}
