//
//  LargeImageViewHeader.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/23/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

protocol LargeImageViewHeaderDelegate {
    func didTapGroup()
    func didTapOptions()
}

class LargeImageViewHeader: UIView {
    
    var group: Group? {
        didSet {
            configureUser()
        }
    }
    
    var groupPostMembers: [User]? {
        didSet {
            configureMemberImages()
        }
    }
    
    var delegate: LargeImageViewHeaderDelegate?
    
    private var padding: CGFloat = 8
    
    private lazy var userProfileImageView: CustomImageView = {
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

        addSubview(userProfileImageView)
        userProfileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, paddingTop: padding + 20, paddingLeft: padding + 20, paddingBottom: padding, width: 50 , height: 50)
        userProfileImageView.layer.cornerRadius = 20
        userProfileImageView.layer.borderWidth = 2
        userProfileImageView.layer.borderColor = UIColor.white.cgColor
        userProfileImageView.isUserInteractionEnabled = true
        userProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))
        userProfileImageView.image = #imageLiteral(resourceName: "user")
        
        addSubview(firstMemberImageView)
        firstMemberImageView.anchor(top: topAnchor, left: userProfileImageView.rightAnchor, bottom: bottomAnchor, paddingTop: padding + 20, paddingLeft: padding, paddingBottom: padding, width: 50 , height: 50)
        firstMemberImageView.layer.cornerRadius = 20
        firstMemberImageView.isUserInteractionEnabled = true
        firstMemberImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))
        firstMemberImageView.image = #imageLiteral(resourceName: "user")

        addSubview(secondMemberImageView)
        secondMemberImageView.anchor(top: topAnchor, left: firstMemberImageView.rightAnchor, bottom: bottomAnchor, paddingTop: padding + 20, paddingLeft: padding, paddingBottom: padding, width: 50, height: 50)
        secondMemberImageView.layer.cornerRadius = 20
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
    
    private func configureUser() {
        guard let group = group else { return }
        usernameButton.setTitle(group.groupname, for: .normal)
        usernameButton.setTitleColor(.white, for: .normal)
        if let profileImageUrl = group.groupProfileImageUrl {
            userProfileImageView.loadImage(urlString: profileImageUrl)
        } else {
            userProfileImageView.image = #imageLiteral(resourceName: "user")
        }
    }
    
    func configureMemberImages(){
        firstMemberImageView.image = UIImage()
        secondMemberImageView.image = UIImage()
        thirdMemberImageView.image = UIImage()
        var count = 0
        for user in groupPostMembers ?? []{
            if count < 3 {
                if count == 0 {
                    if let profileImageUrl = user.profileImageUrl {
                        self.firstMemberImageView.loadImage(urlString: profileImageUrl)
                        self.firstMemberImageView.layer.borderWidth = 0.5
                    }
                    else {
                        self.firstMemberImageView.image = #imageLiteral(resourceName: "user")
                    }
                }
                else if count == 1 {
                    if let profileImageUrl = user.profileImageUrl {
                        self.secondMemberImageView.loadImage(urlString: profileImageUrl)
                        self.secondMemberImageView.layer.borderWidth = 0.5
                    }
                    else {
                        self.secondMemberImageView.image = #imageLiteral(resourceName: "user")
                    }
                }
                else if count == 2 {
                    if let profileImageUrl = user.profileImageUrl {
                        self.thirdMemberImageView.loadImage(urlString: profileImageUrl)
                        self.thirdMemberImageView.layer.borderWidth = 0.5
                    }
                    else {
                        self.thirdMemberImageView.image = #imageLiteral(resourceName: "user")
                    }
                }
                count += 1
            }
            else{
                break
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





