//
//  MemberHeaderCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 4/6/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit

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
        iv.layer.borderWidth = 0
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
        profileImageView.anchor(left: leftAnchor, width: 75, height: 75)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 75 / 2
        
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
            configureCell()
        }
    }
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "group_profile_3")
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 0
        iv.backgroundColor = .white
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
        profileImageView.image = #imageLiteral(resourceName: "group_profile_3")
    }
    
    private func sharedInit() {
        addSubview(profileImageView)
        profileImageView.anchor(left: leftAnchor, paddingLeft: 0, width: 75, height: 75)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 75 / 2
    }
    
    private func configureCell() {
        if let profileImageUrl = profileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        } else {
            profileImageView.image = #imageLiteral(resourceName: "user")
        }
    }
}
