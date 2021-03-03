//
//  SelectGroupCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/2/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol SelectGroupCellDelegate {
    func didSelectGroup(group: Group)
}

class SelectGroupCell: UICollectionViewCell {
    
    var delegate: SelectGroupCellDelegate?
    
    var group: Group? {
        didSet {
            configureCell()
        }
    }
    
    var user: User? {
        didSet {
            configureCell()
        }
    }
    
    private let hiddenIcon: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "hide_eye").withRenderingMode(.alwaysOriginal), for: .normal)
        button.isHidden = true
        button.layer.zPosition = 1
        return button
    }()
    
//    private let profileImageView: CustomImageView = {
//        let iv = CustomImageView()
//        iv.contentMode = .scaleAspectFill
//        iv.clipsToBounds = true
//        iv.image = #imageLiteral(resourceName: "user")
//        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
//        iv.layer.borderWidth = 0.5
//        return iv
//    }()
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 2
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
        iv.layer.borderWidth = 0
        iv.layer.zPosition = 1
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
        iv.layer.zPosition = 1
        return iv
    }()
    
    private let groupnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = .black
        label.layer.zPosition = 1
        return label
    }()
    
    public lazy var backView: UIButton = {
        let view = UIButton()
        view.layer.cornerRadius = 10
        view.layer.zPosition = 0
        view.backgroundColor = .white
        view.isHidden = true
        view.addTarget(self, action: #selector(handleSelectGroup), for: .touchUpInside)
        return view
    }()
    
    static var cellId = "selectGroupCellId"
    
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
        self.group = nil
        self.userOneImageView.image = CustomImageView.imageWithColor(color: .white)
        self.userTwoImageView.image = CustomImageView.imageWithColor(color: .white)
        self.groupnameLabel.text = ""
        self.backView.isHidden = true
    }
    
    private func sharedInit() {
        
        addSubview(backView)
        backView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 1, paddingLeft: 10, paddingBottom: 1, paddingRight: 10)
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 20, paddingLeft: 8 + 12, width: 44, height: 44)
        profileImageView.layer.cornerRadius = 44/2
        profileImageView.isHidden = true
        profileImageView.image = UIImage()

        
        addSubview(userOneImageView)
        userOneImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 16, paddingLeft: 22 + 12, width: 40, height: 40)
//        userOneImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userOneImageView.layer.cornerRadius = 40/2
        userOneImageView.isHidden = true
        userOneImageView.image = UIImage()
        
        addSubview(userTwoImageView)
        userTwoImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 20, paddingLeft: 8 + 12, width: 44, height: 44)
//        userTwoImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userTwoImageView.layer.cornerRadius = 44/2
        userTwoImageView.isHidden = true
        userTwoImageView.image = UIImage()
        
        addSubview(hiddenIcon)
        hiddenIcon.anchor(top: topAnchor, bottom: bottomAnchor, right: rightAnchor, paddingRight: 12 + 12)
        
        addSubview(groupnameLabel)
        groupnameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, paddingLeft: 18 + 12)
        
        self.backView.addTarget(self, action: #selector(self.backViewDown), for: .touchDown)
        self.backView.addTarget(self, action: #selector(self.backViewDown), for: .touchDragInside)
        self.backView.addTarget(self, action: #selector(self.backViewUp), for: .touchDragExit)
        self.backView.addTarget(self, action: #selector(self.backViewUp), for: .touchCancel)
        self.backView.addTarget(self, action: #selector(self.backViewUp), for: .touchUpInside)
        
//        let separatorView = UIView()
//        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        
        // need this because group will already be loaded but order might change so need to reload cell
        configureCell()
    }
    
    private func configureCell() {
        guard let group = group else { return }
        guard let user = user else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        self.userTwoImageView.layer.borderWidth = 0
        
        // then actually hide it, but can't use "isGroupHiddenOnProfile" because current user will be different
        Database.database().isGroupHiddenOnProfile(groupId: group.groupId, completion: { (isHidden) in
            // only allow this if is in group
            if isHidden && currentLoggedInUserId == user.uid {
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
                self.groupnameLabel.text = group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
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
                self.userOneImageView.isHidden = false
                self.userTwoImageView.isHidden = true
                
                if first_n_users.count > 0 {
                    if let userOneImageUrl = first_n_users[0].profileImageUrl {
                        self.userOneImageView.loadImage(urlString: userOneImageUrl)
                    } else {
                        self.userOneImageView.image = #imageLiteral(resourceName: "user")
                        self.userOneImageView.backgroundColor = .white
                    }
                }
                else {
                    self.userOneImageView.image = #imageLiteral(resourceName: "user")
                    self.userOneImageView.backgroundColor = .white
                }
            } else {
                self.profileImageView.isHidden = true
                self.userOneImageView.isHidden = false
                self.userTwoImageView.isHidden = true
                
                if first_n_users.count > 0 {
                    if let userOneImageUrl = first_n_users[0].profileImageUrl {
                        self.userOneImageView.loadImage(urlString: userOneImageUrl)
                    } else {
                        self.userOneImageView.image = #imageLiteral(resourceName: "user")
                        self.userOneImageView.backgroundColor = .white
                    }
                }
                else {
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
                else {
                    self.userTwoImageView.image = #imageLiteral(resourceName: "user")
                    self.userTwoImageView.backgroundColor = .white
                    self.userTwoImageView.layer.borderWidth = 2
                }
            }
            
            Timer.scheduledTimer(withTimeInterval: Double(self.tag) * 0.05, repeats: false) { timer in
                self.backView.isHidden = false
                self.backView.animateButtonDownBig()
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                    self.backView.animateButtonUp()
                }
            }

        }) { (_) in }
    }
    
    @objc private func backViewDown(){
        self.backView.animateButtonDown()
    }
    
    @objc private func backViewUp(){
        self.backView.animateButtonUp()
    }
    
    @objc private func handleSelectGroup() {
        guard let group = self.group else { return }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            self.delegate?.didSelectGroup(group: group)
        }
        
    }
}


extension UIButton {
    @objc func animateButtonDownBig() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
            self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }, completion: nil)
    }
}
