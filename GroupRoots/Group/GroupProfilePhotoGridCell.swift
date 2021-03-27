//
//  GroupProfilePhotoGridCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import FirebaseDatabase

class GroupProfilePhotoGridCell: UICollectionViewCell {
    
    var groupPost: GroupPost? {
        didSet {
            guard let imageUrl = groupPost?.imageUrl else { return }
            photoImageView.loadImage(urlString: imageUrl)
            
            if self.groupPost != nil {
                if self.groupPost!.videoUrl != "" {
                    self.playButton.isHidden = false
                }
                
                if self.groupPost!.isTempPost  {
                    self.hourglassButton.isHidden = false
                    let timeAgo = self.groupPost!.creationDate.timeAgo()
                    var pic_number = Int(floor((16*Double(timeAgo))/24)) + 1
                    if pic_number > 15 {
                        pic_number = 15
                    }
                    self.hourglassButton.setImage(UIImage(named: "hourglass" + String(pic_number) + ".png"), for: .normal)
                }
                
                self.listenForLastComment()
            }
        }
    }
    
    var lastComment: Comment? {
        didSet {
            if lastComment != nil && lastComment!.creationDate.timeIntervalSince1970 > 0 {
                self.reloadMessageIcon()
            }
        }
    }
    
    var commentsReference = DatabaseReference()
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.95, alpha: 1)
        iv.image = CustomImageView.imageWithColor(color: .white)
        return iv
    }()
    
    let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.white
        button.isUserInteractionEnabled = false
        button.setImage(#imageLiteral(resourceName: "play").withRenderingMode(.alwaysOriginal), for: .normal)
        button.isHidden = true
        return button
    }()
    
    let hourglassButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.white
        button.isUserInteractionEnabled = false
        button.setImage(#imageLiteral(resourceName: "hourglass1").withRenderingMode(.alwaysOriginal), for: .normal)
        button.isHidden = true
        return button
    }()
    
    public let unreadMessageIcon: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.clear
        iv.image = #imageLiteral(resourceName: "read_message")
        iv.isHidden = true
        
        iv.layer.shadowColor = UIColor.black.cgColor
        iv.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        iv.layer.shadowOpacity = 0.2
        iv.layer.shadowRadius = 1.5
        return iv
    }()
    
    static var cellId = "groupProfilePhotoGridCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: CGFloat(2), paddingLeft: CGFloat(2), paddingBottom: CGFloat(2), paddingRight: CGFloat(2), width: 0, height: 0)
        photoImageView.layer.cornerRadius = 3
        
        insertSubview(playButton, at: 5)
        playButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 30, paddingLeft: 30, paddingBottom: 30, paddingRight: 30)
        
        insertSubview(hourglassButton, at: 6)
//        hourglassButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
//        hourglassButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
        hourglassButton.anchor(left: leftAnchor, bottom: bottomAnchor, paddingLeft: 7, paddingBottom: 7, width: 25, height: 25)
        
        insertSubview(unreadMessageIcon, at: 6)
        unreadMessageIcon.layer.zPosition = 6
//        unreadMessageIcon.heightAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
//        unreadMessageIcon.widthAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
        unreadMessageIcon.anchor(bottom: bottomAnchor, right: rightAnchor, paddingBottom: 10, paddingRight: 10, width: 20, height: 20)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playButton.isHidden = true
        photoImageView.image = CustomImageView.imageWithColor(color: .white)
        groupPost = nil
        hourglassButton.isHidden = true
        hourglassButton.setImage(#imageLiteral(resourceName: "hourglass1").withRenderingMode(.alwaysOriginal), for: .normal)
        unreadMessageIcon.image = #imageLiteral(resourceName: "read_message")
        unreadMessageIcon.isHidden = true
        
//        commentsReference.removeAllObservers()
    }
    
    @objc func reloadMessageIcon() {
        guard let groupPost = groupPost else { return }
        if groupPost.id == "" {
            return
        }
        guard let lastComment = lastComment else { return }
        unreadMessageIcon.isHidden = false
        Database.database().fetchLastTimeUserViewedPostMessages(postId: groupPost.id, completion: {(time_viewed) in
            if Int(lastComment.creationDate.timeIntervalSince1970) > time_viewed && time_viewed > 0 {
                self.unreadMessageIcon.image = #imageLiteral(resourceName: "unread_message")
            }
            else {
                self.unreadMessageIcon.image = #imageLiteral(resourceName: "read_message")
            }
        }) { (err) in return }
    }
    
    func listenForLastComment() {
        guard let groupPost = groupPost else { return }
        // this will continuously listen for refreshes in comments to update the messages icon
        if groupPost.id != "" {
            self.commentsReference = Database.database().reference().child("comments").child(groupPost.id)
            self.commentsReference.queryOrderedByKey().queryLimited(toLast: 1).observe(.value) { snapshot in
                guard let dictionaries = snapshot.value as? [String: Any] else {
                    return
                }
                
                var comments = [Comment]()
                
                let sync = DispatchGroup()
                dictionaries.forEach({ (key, value) in
                    guard let commentDictionary = value as? [String: Any] else { return }
                    guard let uid = commentDictionary["uid"] as? String else { return }
                    sync.enter()
                    Database.database().userExists(withUID: uid, completion: { (exists) in
                        if exists{
                            Database.database().fetchUser(withUID: uid) { (user) in
                                let comment = Comment(user: user, dictionary: commentDictionary)
                                comments.append(comment)
                                sync.leave()
                            }
                        }
                        else{
                            sync.leave()
                        }
                    })
                })
                sync.notify(queue: .main) {
                    if comments.count > 0 {
                        self.lastComment = comments[0]
                    }
                }
            }
        }
    }
}

