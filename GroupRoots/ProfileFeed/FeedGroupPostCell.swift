//
//  FeedGroupPostCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 5/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import SGImageCache
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import NVActivityIndicatorView

class FeedGroupPostCell: UICollectionViewCell {
    
    var readyToSetPicture = false
    
    var viewedPost: Bool? {
        didSet {
            guard let viewedPost = viewedPost else { return }
            if viewedPost {
                self.newDot.isHidden = true
            }
            else {
                self.newDot.isHidden = false
            }
        }
    }
    
    private let upperCoverView: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 3)
        backgroundView.clipsToBounds = true
        backgroundView.isHidden = true
        return backgroundView
    }()
    
    private let coverView: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 3)
        backgroundView.clipsToBounds = true
        backgroundView.isHidden = true
        return backgroundView
    }()
    
    var commentsReference = DatabaseReference()
    
    var groupPost: GroupPost? {
        didSet {
            guard let groupPost = self.groupPost else { return }
            if groupPost.id == "" {
                return
            }
            
            guard var imageUrl = self.groupPost?.imageUrl else { return }
            guard var videoUrl = self.groupPost?.videoUrl else { return }
            guard let groupId = self.groupPost?.group.groupId else { return }
            guard let postId = self.groupPost?.id else { return }
            guard let isTempPost = self.groupPost?.isTempPost else { return }
            guard let creationDate = self.groupPost?.creationDate else { return }
            
//            self.photoImageView.backgroundColor = UIColor(red: CGFloat(groupPost.avgRed), green: CGFloat(groupPost.avgGreen), blue: CGFloat(groupPost.avgBlue), alpha: CGFloat(groupPost.avgAlpha))
            self.photoImageView.backgroundColor = .clear
            
            if isTempPost {
                hourglassButton.isHidden = false
                let timeAgo = creationDate.timeAgo()
                var pic_number = Int(floor((16*Double(timeAgo))/24)) + 1
                if pic_number > 15 {
                    pic_number = 15
                }
                hourglassButton.setImage(UIImage(named: "hourglass" + String(pic_number) + ".png"), for: .normal)
                
                // hour    x
                // ---- = ----
                //  24     15
                // (15 * hour) / 24 = x = pic_number
                // floor((16*hour)/24) with max of 15
            }
            
            let sync = DispatchGroup()
            sync.enter()
            if imageUrl == "" {
                // need to use new folder system for this instead
                let storageRef = Storage.storage().reference()
                let imagesRef = storageRef.child("group_post_images")
                let videosRef = storageRef.child("group_post_videos")
                let groupId = groupId
                let fileName = postId
                let postImageRef = imagesRef.child(groupId).child(fileName + ".jpeg")
                let postVideoRef = videosRef.child(groupId).child(fileName)
                
                sync.enter()
                postImageRef.downloadURL { url, error in
                    if let error = error {
                        print(error)
                    } else {
                        imageUrl = url!.absoluteString
                    }
                    sync.leave()
                }
                
                sync.enter()
                postVideoRef.downloadURL { url, error in
                    if let error = error {
                        print(error)
                    } else {
                        videoUrl = url!.absoluteString
                    }
                    sync.leave()
                }
                sync.leave()
            }
            else {
                sync.leave()
            }
            
            sync.notify(queue: .main) {
                if let image = SGImageCache.image(forURL: imageUrl) {
                    self.photoImageView.image = image   // image loaded immediately from cache
                    self.photoImageBackgroundView.image = image
                    self.upperCoverView.isHidden = false
                    self.coverView.isHidden = false
                    self.photoImageBackgroundView.contentMode = .scaleAspectFill
                    if image.size.width >  image.size.height {
                        self.photoImageView.contentMode = .scaleAspectFit
                    }
                    else {
                        self.photoImageView.contentMode = .scaleAspectFill
                    }
//                    self.photoImageView.contentMode = .scaleAspectFill
                } else {
                    self.photoImageView.image = CustomImageView.imageWithColor(color: .white)
                    self.photoImageBackgroundView.image = CustomImageView.imageWithColor(color: .white)
                    self.readyToSetPicture = true
                    
                    // using a timer here to fix diagonal issue. Bandaid solution
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
                        if self.groupPost != nil {
                            SGImageCache.getImage(url: self.groupPost!.imageUrl) { [weak self] image in
                                if image?.size.width ?? 0 >  image?.size.height ?? 0 {
                                    self?.photoImageView.contentMode = .scaleAspectFit
                                }
                                else {
                                    self?.photoImageView.contentMode = .scaleAspectFill
                                }
                                if self?.readyToSetPicture ?? false {
                                    self?.photoImageView.image = image   // image loaded async
                                    self?.photoImageBackgroundView.image = image
                                }
                            }
                        }
                    })
                }
                
                // set a playButton (not clickable) for video previews
                if self.groupPost != nil {
                    if self.groupPost!.videoUrl != "" {
                        self.playButton.isHidden = false
                    }
                }
                
                // for when the picture is loaded without the data above this being set
                // viewing a picture wouldn't reload the whole collectionview so viewed info stored in viewdPosts
                self.reloadNewDot()
                
                self.listenForLastComment()
            }
        }
    }
    
    var lastComment: Comment? {
        didSet {
            // make an icon that shows whether there is an unread comment or not
            // whenever read a comment, mark the id as the most recent one and save it in device memory or firebase
            // (maybe firebase better since if you log out and log in it'll mark all as unread)
            // compare last comment id or date with that
//            print(lastComment!)
            if lastComment != nil && lastComment!.creationDate.timeIntervalSince1970 > 0 {
                self.reloadMessageIcon()
            }
        }
    }

    public let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 1, alpha: 0.1)
        return iv
    }()
    
    public let photoImageBackgroundView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 1, alpha: 0.1)
        return iv
    }()
    
    let blurredEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.clipsToBounds = true
        blurredEffectView.layer.cornerRadius = 10
        blurredEffectView.isUserInteractionEnabled = false
        return blurredEffectView
    }()
    
    let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.white
        button.isUserInteractionEnabled = false
        button.setImage(#imageLiteral(resourceName: "play").withRenderingMode(.alwaysOriginal), for: .normal)
        button.isHidden = true
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.35
        button.layer.shadowRadius = 2.5
        return button
    }()
    
    let newDot: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 10/2
        view.isHidden = true
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        view.layer.shadowOpacity = 0.35
        view.layer.shadowRadius = 2.5
        return view
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
//        iv.layer.cornerRadius = 5
//        let path = UIBezierPath(roundedRect: iv.frame, cornerRadius: 50.0)
//        iv.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.pic.frame cornerRadius:50.0].CGPath;
        return iv
    }()
    
    let hourglassButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.white
        button.isUserInteractionEnabled = false
        button.setImage(#imageLiteral(resourceName: "hourglass1").withRenderingMode(.alwaysOriginal), for: .normal)
        button.isHidden = true
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.35
        button.layer.shadowRadius = 2.5
        return button
    }()
    
    static var cellId = "feedGroupPostCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        contentView.insertSubview(photoImageBackgroundView, at: 1)
        photoImageBackgroundView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: CGFloat(1), paddingLeft: CGFloat(1), paddingBottom: CGFloat(1), paddingRight: CGFloat(1), width: 0, height: 0)
        photoImageBackgroundView.layer.cornerRadius = 10
        photoImageBackgroundView.layer.borderColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1).cgColor
        photoImageBackgroundView.layer.borderWidth = 1
        photoImageBackgroundView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        photoImageBackgroundView.layer.zPosition = 1
        self.layer.borderWidth = 0
        
        contentView.insertSubview(blurredEffectView, at: 2)
        blurredEffectView.layer.zPosition = 2
        blurredEffectView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: CGFloat(1), paddingLeft: CGFloat(1), paddingBottom: CGFloat(1), paddingRight: CGFloat(1), width: 0, height: 0)
        
        contentView.insertSubview(photoImageView, at: 4)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: CGFloat(1), paddingLeft: CGFloat(1), paddingBottom: CGFloat(1), paddingRight: CGFloat(1), width: 0, height: 0)
        photoImageView.layer.cornerRadius = 10
        photoImageView.layer.borderColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1).cgColor
        photoImageView.layer.borderWidth = 1
        photoImageView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        photoImageView.layer.zPosition = 4
        self.layer.borderWidth = 0
        
        insertSubview(playButton, at: 6)
        playButton.layer.zPosition = 6
        playButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor)
        
        insertSubview(newDot, at: 6)
        newDot.layer.zPosition = 6
        newDot.heightAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        newDot.widthAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        newDot.anchor(top: topAnchor, right: rightAnchor, paddingTop: 10, paddingRight: 10)
        
        insertSubview(unreadMessageIcon, at: 6)
        unreadMessageIcon.layer.zPosition = 6
        unreadMessageIcon.heightAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        unreadMessageIcon.widthAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        unreadMessageIcon.anchor(bottom: bottomAnchor, right: rightAnchor, paddingBottom: 15, paddingRight: 15)
//        let path = UIBezierPath(roundedRect: unreadMessageIcon.frame, cornerRadius: 10)
//        unreadMessageIcon.layer.shadowPath = path.cgPath
        
        insertSubview(hourglassButton, at: 6)
        hourglassButton.layer.zPosition = 6
        hourglassButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        hourglassButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        hourglassButton.anchor(left: leftAnchor, bottom: bottomAnchor, paddingLeft: 10, paddingBottom: 10)
        
        self.readyToSetPicture = false
        
//        contentView.insertSubview(coverView, at: 5)
//        coverView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: CGFloat(2), paddingBottom: CGFloat(2), paddingRight: CGFloat(2), height: 20)
//        coverView.layer.cornerRadius = 10
//        coverView.isUserInteractionEnabled = false
//        
//        contentView.insertSubview(upperCoverView, at: 5)
//        upperCoverView.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: CGFloat(2), paddingLeft: CGFloat(2), paddingRight: CGFloat(2), height: 20)
//        upperCoverView.layer.cornerRadius = 10
//        upperCoverView.isUserInteractionEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadNewDot), name: NSNotification.Name(rawValue: "reloadViewedPosts"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadMessageIcon), name: NSNotification.Name(rawValue: "reloadNumMessages"), object: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
                
        photoImageView.image = CustomImageView.imageWithColor(color: .white)
        photoImageView.layer.borderColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1).cgColor
        photoImageView.layer.borderWidth = 1
        photoImageView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        self.layer.borderWidth = 0
        
        photoImageBackgroundView.image = CustomImageView.imageWithColor(color: .white)
        photoImageBackgroundView.layer.borderColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1).cgColor
        photoImageBackgroundView.layer.borderWidth = 1
        photoImageBackgroundView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        
        playButton.isHidden = true
        hourglassButton.isHidden = true
        hourglassButton.setImage(#imageLiteral(resourceName: "hourglass1").withRenderingMode(.alwaysOriginal), for: .normal)
        newDot.isHidden = true
        unreadMessageIcon.image = #imageLiteral(resourceName: "read_message")
        unreadMessageIcon.isHidden = true
        groupPost = nil
        viewedPost = nil
        lastComment = nil
        
        self.upperCoverView.isHidden = true
        self.coverView.isHidden = true
        
        self.readyToSetPicture = false
        
        // remove listener
        commentsReference.removeAllObservers()
    }
    
    @objc func reloadNewDot(){
        guard let groupPost = groupPost else { return }
        if groupPost.id == "" {
            return
        }
        if let viewedPostsRetrieved = UserDefaults.standard.object(forKey: "viewedPosts") as? Data {
            guard let allViewedPosts = try? JSONDecoder().decode([String: Bool].self, from: viewedPostsRetrieved) else {
                print("Error: Couldn't decode data into Blog")
                return
            }
            let viewedPost = allViewedPosts[groupPost.id] != nil
            if viewedPost {
                self.newDot.isHidden = true
            }
        }
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
