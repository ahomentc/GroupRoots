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
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
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
    
    private func configureCell() {
        guard group_has_profile_image != nil else { return }
        guard let user = user else { return }
        guard let num_groups = num_groups else { return }
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, width: 60, height: 60)
//        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 60 / 2
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 5, paddingRight: 0)
        
        addSubview(numGroupsLabel)
        numGroupsLabel.anchor(top: usernameLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 2, paddingRight: 0)
        
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
    }
}
