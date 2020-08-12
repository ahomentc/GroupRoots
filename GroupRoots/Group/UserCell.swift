//
//  UserCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/18/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol UserDecisionCellDelegate {
    func acceptUserRequest()
}


class UserCell: UICollectionViewCell {
    
    var delegate: UserDecisionCellDelegate?
    
    var user: User? {
        didSet {
            configureCell()
        }
    }
    
    var isMembersView : Bool? {
        didSet {
            if isMembersView!{
                self.acceptButton.type = .hide
                self.denyButton.type = .hide
            }
            else{
                self.acceptButton.type = .accept
                self.denyButton.type = .deny
            }
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
    
    private lazy var acceptButton: AcceptDenyButton = {
        let button = AcceptDenyButton(type: .system)
        button.type = .accept
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleAcceptRequest), for: .touchUpInside)
        return button
    }()
    
    private lazy var denyButton: AcceptDenyButton = {
        let button = AcceptDenyButton(type: .system)
        button.type = .deny
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleDenyRequest), for: .touchUpInside)
        return button
    }()
    
    static var cellId = "userSearchCellId"
    
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
        
        addSubview(acceptButton)
        acceptButton.anchor(top: topAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 10, paddingBottom: 10, paddingRight: 8)
        
        addSubview(denyButton)
        denyButton.anchor(top: topAnchor, bottom: bottomAnchor, right: acceptButton.leftAnchor, paddingTop: 10, paddingBottom: 10, paddingRight: 8)
        
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
    
    @objc private func handleAcceptRequest(){
        // accept in backend
        Database.database().acceptIntoGroup(withUID:user!.uid,groupId: group.groupId){ (err) in
            if err != nil {
                return
            }
            guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
            // notification that member is now in group
            Database.database().fetchGroupMembers(groupId: self.group.groupId, completion: { (members) in
                members.forEach({ (member) in
                    if member.uid != currentLoggedInUserId{
                        Database.database().createNotification(to: member, notificationType: NotificationType.newGroupJoin, subjectUser: self.user!, group: self.group!) { (err) in
                            if err != nil {
                                return
                            }
                        }
                    }
                })
            }) { (_) in}
            
            // notification to refresh
            NotificationCenter.default.post(name: NSNotification.Name("updateMembers"), object: nil)
        }
    }
    
    @objc private func handleDenyRequest(){
        Database.database().denyFromGroup(withUID:user!.uid,groupId: group.groupId){ (err) in
            if err != nil {
                return
            }
            // notification to refresh
            NotificationCenter.default.post(name: NSNotification.Name("updateMembers"), object: nil)
        }
    }
}

//MARK: - JoinButtonType

private enum JoinButtonType {
    case loading, accept, deny, hide
}

//MARK: - AcceptDenyButton

private class AcceptDenyButton: UIButton {
    
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
        case .accept:
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
        backgroundColor = UIColor.white
        layer.borderColor = UIColor.gray.cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray.cgColor
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        isUserInteractionEnabled = true
    }
    
    private func setupAcceptStyle() {
        setTitle("Accept", for: .normal)
        setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        backgroundColor = UIColor.white
        layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 1.2
        contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        isUserInteractionEnabled = true
    }
    
    private func setupHideStyle() {
        setTitle("", for: .normal)
        setTitleColor(.white, for: .normal)
        backgroundColor = UIColor.white
        layer.borderColor = UIColor(white: 0, alpha: 0).cgColor
        isUserInteractionEnabled = false
    }
}



