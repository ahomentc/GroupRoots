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
//        iv.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.9).cgColor
//        iv.layer.borderWidth = 2.5
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 0
        return iv
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
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
//        addSubview(profileImageView)
//        profileImageView.anchor(left: leftAnchor, width: 80, height: 80)
//        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//        profileImageView.layer.cornerRadius = 80 / 2
        
//        addSubview(usernameLabel)
//        usernameLabel.anchor(top: profileImageView.bottomAnchor, paddingTop: 10)
    }
    
    private func configureCell() {
        guard let group_has_profile_image = group_has_profile_image else { return }
        guard let user = user else { return }
        
        if !group_has_profile_image {
            addSubview(profileImageView)
//            profileImageView.anchor(left: leftAnchor, paddingLeft: 10, width: 80, height: 80)
            profileImageView.anchor(left: leftAnchor, width: 75, height: 75)
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            profileImageView.layer.cornerRadius = 75 / 2
        }
        else {
            addSubview(profileImageView)
            profileImageView.anchor(left: leftAnchor, width: 75, height: 75)
            profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            profileImageView.layer.cornerRadius = 75 / 2
        }
        
        usernameLabel.text = user.username
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
//        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
//        iv.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
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
