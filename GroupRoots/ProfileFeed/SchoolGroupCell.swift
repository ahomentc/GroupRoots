//
//  SchoolGroupCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 1/5/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol SchoolGroupCellDelegate {
    func didTapGroup(group: Group)
    func didTapUser(user: User)
}

class SchoolGroupCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var group: Group? {
        didSet {
            configureGroupHeader()
        }
    }
    
    var user: User? {
        didSet {
            configureGroupCell()
        }
    }
    var groupMembers: [User]? {
        didSet {
            configureGroupHeader()
//            configureGroupCell()
        }
    }
    
    var isInFollowPending: Bool? {
        didSet {
            configureGroupCell()
        }
    }
    
    var isFollowingGroup: Bool? {
        didSet {
            configureGroupCell()
        }
    }
    
    var delegate: SchoolGroupCellDelegate?
    
    
    private lazy var groupnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .left
        label.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleGroupTap))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
//        label.isUserInteractionEnabled = false
        // ^^^ is false because the background to it (the whole cell) takes you to group
        return label
    }()
    
    private lazy var subscribeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleSubscribeTap), for: .touchUpInside)
        button.setTitle("Follow", for: .normal)
        button.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        button.backgroundColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        button.layer.cornerRadius = 7
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.isUserInteractionEnabled = true
        button.isHidden = true
        return button
    }()
    
    private lazy var unsubscribeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleUnsubscribeTap), for: .touchUpInside)
        button.setTitle("Unfollow", for: .normal)
        button.backgroundColor = UIColor.clear
        button.setTitleColor(.black, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        button.layer.cornerRadius = 7
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.isUserInteractionEnabled = true
        button.isHidden = true
        return button
    }()
    
    private lazy var requestedButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleRequestedTap), for: .touchUpInside)
        button.setTitle("Requested", for: .normal)
        button.backgroundColor = UIColor.clear
        button.setTitleColor(.black, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        button.layer.cornerRadius = 7
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.isUserInteractionEnabled = true
        button.isHidden = true
        return button
    }()
    
    private lazy var viewGroupButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleGroupTap), for: .touchUpInside)
        button.setTitle("Open Group Profile", for: .normal)
//        button.backgroundColor = UIColor.clear
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        button.layer.cornerRadius = 10
//        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.isUserInteractionEnabled = true
        button.isHidden = false
        return button
    }()
    
    let lastPostedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .lightGray
        label.textAlignment = .right
        label.text = ""
        return label
    }()
    
    var headerCollectionView: UICollectionView!
    
    static var cellId = "fullGroupCellId"
    
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
        self.backgroundColor = UIColor(white: 0, alpha: 0)
        self.group = nil
        
        self.groupnameLabel.text = ""
        let emptyString = NSMutableAttributedString(string:"")
        self.groupnameLabel.attributedText = emptyString
        self.lastPostedLabel.text = ""
        
        self.isInFollowPending = nil
        self.isFollowingGroup = nil
        
        subscribeButton.isHidden = true
        requestedButton.isHidden = true
    }
    
    private func sharedInit() {
        self.backgroundColor = UIColor(white: 0, alpha: 0)
        
//        contentView.addSubview(groupnameLabel)
//        groupnameLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 130, paddingLeft: 30, height: 30)
        
        contentView.addSubview(subscribeButton)
        subscribeButton.anchor(top: topAnchor, right: rightAnchor, paddingTop: 120, paddingRight: 35, height: 40)
        
        contentView.addSubview(unsubscribeButton)
        unsubscribeButton.anchor(top: topAnchor, right: rightAnchor, paddingTop: 120, paddingRight: 35, height: 40)
        
        contentView.addSubview(requestedButton)
        requestedButton.anchor(top: topAnchor, right: rightAnchor, paddingTop: 120, paddingRight: 35, height: 40)
        
//        contentView.addSubview(viewGroupButton)
//        viewGroupButton.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 180, paddingLeft: 80, paddingRight: 80, height: 40)
        
        contentView.addSubview(viewGroupButton)
        viewGroupButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: 120, paddingLeft: 30, width: 200, height: 40)
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.25)
        contentView.addSubview(separatorView)
        separatorView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 20, paddingRight: 20, height: 0.5)
        
        // need this because group will already be loaded but order might change so need to reload cell
//        configureCell()
        
        let header_layout = UICollectionViewFlowLayout()
        header_layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
//        header_layout.itemSize = CGSize(width: 60, height: 60)
//        header_layout.minimumLineSpacing = CGFloat(20)
        
        headerCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 105), collectionViewLayout: header_layout)
        headerCollectionView.delegate = self
        headerCollectionView.dataSource = self
        headerCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        headerCollectionView.register(GroupProfileHeaderCell.self, forCellWithReuseIdentifier: GroupProfileHeaderCell.cellId)
        headerCollectionView.register(MemberHeaderCell.self, forCellWithReuseIdentifier: MemberHeaderCell.cellId)
        headerCollectionView.showsHorizontalScrollIndicator = false
        headerCollectionView.isUserInteractionEnabled = true
        headerCollectionView.allowsSelection = true
        headerCollectionView.backgroundColor = UIColor.clear
        headerCollectionView.showsHorizontalScrollIndicator = false
        contentView.insertSubview(headerCollectionView, at: 5)
    }
    
    // doing this here to load faster
    private func configureGroupHeader(){
        guard let groupMembers = groupMembers else { return }
        guard let group = group else { return }
        
        let lockImage = #imageLiteral(resourceName: "lock")
        let lockIcon = NSTextAttachment()
        lockIcon.image = lockImage
        let lockIconString = NSAttributedString(attachment: lockIcon)

        let balanceFontSize: CGFloat = 16
        let balanceFont = UIFont.boldSystemFont(ofSize: balanceFontSize)
        //Setting up font and the baseline offset of the string, so that it will be centered
        let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, .foregroundColor: UIColor.black, .baselineOffset: (lockImage.size.height - balanceFontSize) / 2 - balanceFont.descender / 2]
        
        if group.groupname != "" {
            let balanceString = NSMutableAttributedString(string: group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘") + " ", attributes: balanceAttr)
            if group.isPrivate ?? false {
                balanceString.append(lockIconString)
            }
            self.groupnameLabel.attributedText = balanceString
        }
        else {
            if groupMembers.count > 2 {
                var usernames = groupMembers[0].username + " & " + groupMembers[1].username + " & " + groupMembers[2].username
                if usernames.count > 21 {
                    usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                    usernames = usernames + "..."
                }
                let balanceString = NSMutableAttributedString(string: usernames.replacingOccurrences(of: "_-a-_", with: " ") + " ", attributes: balanceAttr)
                if group.isPrivate ?? false {
                    balanceString.append(lockIconString)
                }
                self.groupnameLabel.attributedText = balanceString
            }
            else if groupMembers.count == 2 {
                var usernames = groupMembers[0].username + " & " + groupMembers[1].username
                if usernames.count > 21 {
                    usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                    usernames = usernames + "..."
                }
                let balanceString = NSMutableAttributedString(string: usernames.replacingOccurrences(of: "_-a-_", with: " ") + " ", attributes: balanceAttr)
                if group.isPrivate ?? false {
                    balanceString.append(lockIconString)
                }
                self.groupnameLabel.attributedText = balanceString
            }
            else if groupMembers.count == 1 {
                var usernames = groupMembers[0].username
                if usernames.count > 21 {
                    usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                    usernames = usernames + "..."
                }
                let balanceString = NSMutableAttributedString(string: usernames.replacingOccurrences(of: "_-a-_", with: " ") + " ", attributes: balanceAttr)
                if group.isPrivate ?? false {
                    balanceString.append(lockIconString)
                }
                self.groupnameLabel.attributedText = balanceString
            }
        }
        self.headerCollectionView.reloadData()
    }
    
    private func configureGroupCell(){
        guard isInFollowPending != nil else { return }
        guard isFollowingGroup != nil else { return }
        
        if isFollowingGroup ?? false {
            subscribeButton.isHidden = true
            requestedButton.isHidden = true
            unsubscribeButton.isHidden = false
        }
        else if isInFollowPending ?? false {
            subscribeButton.isHidden = true
            requestedButton.isHidden = false
            unsubscribeButton.isHidden = true
        }
        else {
            subscribeButton.isHidden = false
            requestedButton.isHidden = true
            unsubscribeButton.isHidden = true
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (groupMembers?.count ?? 0) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let group = group else {
            // if group not set yet just set an empty cell
            let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: MemberHeaderCell.cellId, for: indexPath) as! MemberHeaderCell
            cell.layer.backgroundColor = UIColor.clear.cgColor
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
            cell.layer.shadowOpacity = 0.2
            cell.layer.shadowRadius = 2.0
            return cell
        }
        
        if group.groupProfileImageUrl != nil && group.groupProfileImageUrl != "" {
            if indexPath.item == 0 {
                let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: GroupProfileHeaderCell.cellId, for: indexPath) as! GroupProfileHeaderCell
                cell.profileImageUrl = group.groupProfileImageUrl
                cell.groupname = group.groupname
                if groupMembers?.count ?? 0 > 0 {
                    if groupMembers?[0].profileImageUrl != nil {
                        cell.userOneImageUrl = groupMembers?[0].profileImageUrl
                    }
                    else {
                        cell.userOneImageUrl = ""
                    }
                }
                else {
                    cell.userOneImageUrl = ""
                }
                
                cell.layer.backgroundColor = UIColor.clear.cgColor
                cell.layer.shadowColor = UIColor.black.cgColor
                cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                cell.layer.shadowOpacity = 0.2
                cell.layer.shadowRadius = 4.0
                return cell
            }
            else {
                let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: MemberHeaderCell.cellId, for: indexPath) as! MemberHeaderCell
                if groupMembers?.count == 0 {
                    // do soemting
                }
                if indexPath.item-1 < groupMembers?.count ?? 0 {
                    cell.user = groupMembers?[indexPath.item-1]
                }
                cell.group_has_profile_image = true
                cell.layer.backgroundColor = UIColor.clear.cgColor
                cell.layer.shadowColor = UIColor.black.cgColor
                cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                cell.layer.shadowOpacity = 0.2
                cell.layer.shadowRadius = 2.0
                return cell
            }
        }
        else {
            if indexPath.item == 0 {
                // modify this to be two small user cells
                let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: GroupProfileHeaderCell.cellId, for: indexPath) as! GroupProfileHeaderCell
                cell.groupname = group.groupname
//                    cell.group = group
                if groupMembers?.count ?? 0 > 0 {
                    if groupMembers?[0].profileImageUrl != nil {
                        cell.userOneImageUrl = groupMembers?[0].profileImageUrl
                    }
                    else {
                        cell.userOneImageUrl = ""
                    }
                }
                else {
                    cell.userOneImageUrl = ""
                }
                if groupMembers?.count ?? 0 > 1 {
                    if groupMembers?[1].profileImageUrl != nil {
                        cell.userTwoImageUrl = groupMembers?[1].profileImageUrl
                    }
                    else {
                        cell.userTwoImageUrl = ""
                    }
                }
                else {
                    cell.userTwoImageUrl = ""
                }
                cell.layer.backgroundColor = UIColor.clear.cgColor
                cell.layer.shadowColor = UIColor.black.cgColor
                cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                cell.layer.shadowOpacity = 0.2
                cell.layer.shadowRadius = 4.0
                return cell
            }
            else {
                let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: MemberHeaderCell.cellId, for: indexPath) as! MemberHeaderCell
                if groupMembers?.count == 0 {
                    // do something
                }
                cell.user = groupMembers?[indexPath.item-1]
                cell.group_has_profile_image = false
                cell.layer.backgroundColor = UIColor.clear.cgColor
                cell.layer.shadowColor = UIColor.black.cgColor
                cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
                cell.layer.shadowOpacity = 0.2
                cell.layer.shadowRadius = 2.0
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            guard let group = group else { return }
            delegate?.didTapGroup(group: group)
        }
        else {
            guard let groupMembers = self.groupMembers else { return }
            delegate?.didTapUser(user: groupMembers[indexPath.row - 1])
        }
    }

    @objc private func handleGroupTap(){
        guard let group = group else { return }
        delegate?.didTapGroup(group: group)
    }
    
    @objc private func handleSubscribeTap() {
        guard let groupId = group?.groupId else { return }
        guard let isPrivate = group?.isPrivate else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        // set button to loading here before we decide if it should be requested or unfollow
        subscribeButton.isHidden = true
        
        if isPrivate {
            requestedButton.isHidden = false
            unsubscribeButton.isHidden = true
        }
        else {
            requestedButton.isHidden = true
            unsubscribeButton.isHidden = false
        }
        
        Database.database().subscribeToGroup(groupId: groupId) { (err) in
            
            NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
//            NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
            NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
            
            // sending notification
            Database.database().groupExists(groupId: groupId, completion: { (exists) in
                if exists {
                    Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                        Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
                            Database.database().fetchGroupMembers(groupId: groupId, completion: { (members) in
                                members.forEach({ (member) in
                                    if user.uid != member.uid {
                                        if isPrivate {
                                            // send notification for subscription request to all members of group
                                            Database.database().createNotification(to: member, notificationType: NotificationType.groupSubscribeRequest, subjectUser: user, group: group) { (err) in
                                                if err != nil {
                                                    return
                                                }
                                            }
                                        }
                                        else {
                                            // send notification for did subscribe to all members of group
                                            Database.database().createNotification(to: member, notificationType: NotificationType.newGroupSubscribe, subjectUser: user, group: group) { (err) in
                                                if err != nil {
                                                    return
                                                }
                                            }
                                        }
                                    }
                                })
                            }) { (_) in}
                        })
                    })
                }
            })
        }
    }
    
    @objc private func handleRequestedTap() {
        guard let groupId = group?.groupId else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        subscribeButton.isHidden = false
        requestedButton.isHidden = true
        unsubscribeButton.isHidden = true
        
        Database.database().removeUserFromGroupPending(withUID: currentLoggedInUserId, groupId: groupId) { (err) in
            if err != nil {
                return
            }
        }
    }
    
    @objc private func handleUnsubscribeTap() {
        guard let groupId = group?.groupId else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        subscribeButton.isHidden = false
        requestedButton.isHidden = true
        unsubscribeButton.isHidden = true
        
        Database.database().removeGroupFromUserFollowing(withUID: currentLoggedInUserId, groupId: groupId) { (err) in
            if err != nil {
                return
            }
            NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
        }
    }
}

extension SchoolGroupCell: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 70, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
    }

}

