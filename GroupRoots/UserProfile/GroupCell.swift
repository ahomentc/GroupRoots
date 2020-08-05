//
//  GroupCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

class GroupCell: UICollectionViewCell {
    
    var group: Group? {
        didSet {
            configureCell()
        }
    }
    
    private let hiddenIcon: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "hide_eye").withRenderingMode(.alwaysOriginal), for: .normal)
        button.isHidden = true
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
    
    static var cellId = "groupCellId"
    
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
        self.backgroundColor = UIColor.clear
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
        userTwoImageView.image = UIImage()
        
        addSubview(hiddenIcon)
        hiddenIcon.anchor(top: topAnchor, bottom: bottomAnchor, right: rightAnchor, paddingRight: 12)
        
        addSubview(groupnameLabel)
        groupnameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, paddingLeft: 12)
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        
        // need this because group will already be loaded but order might change so need to reload cell
        configureCell()
    }
    
    private func configureCell() {
        guard let group = group else { return }
        self.userTwoImageView.layer.borderWidth = 0
        
        // then actually hide it, but can't use "isGroupHiddenOnProfile" because current user will be different
        Database.database().isGroupHiddenOnProfile(groupId: group.groupId, completion: { (isHidden) in
            // only allow this if is in group
            if isHidden {
                self.hiddenIcon.isHidden = false
            }
            else {
               self.hiddenIcon.isHidden = true
            }
        }) { (err) in
            return
        }
        
        Database.database().fetchFirstNGroupMembers(groupId: group.groupId, n: 3, completion: { (first_n_users) in
            if group.groupname != "" {
                self.groupnameLabel.text = group.groupname.replacingOccurrences(of: "_-a-_", with: " ")
            }
            else {
                if first_n_users.count > 2 {
                    var usernames = first_n_users[0].username + " & " + first_n_users[1].username + " & " + first_n_users[2].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                    self.groupnameLabel.text = usernames
                }
                else if first_n_users.count == 2 {
                    var usernames = first_n_users[0].username + " & " + first_n_users[1].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                    self.groupnameLabel.text = usernames
                }
                else if first_n_users.count == 1 {
                    var usernames = first_n_users[0].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
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
    }
}
