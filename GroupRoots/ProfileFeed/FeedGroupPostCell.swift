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
    
    var groupPost: GroupPost? {
        didSet {
            guard let groupPost = self.groupPost else { return }
            guard var imageUrl = self.groupPost?.imageUrl else { return }
            guard var videoUrl = self.groupPost?.videoUrl else { return }
            guard let groupId = self.groupPost?.group.groupId else { return }
            guard let postId = self.groupPost?.id else { return }
            guard let isTempPost = self.groupPost?.isTempPost else { return }
            guard let creationDate = self.groupPost?.creationDate else { return }
            
            self.photoImageView.backgroundColor = UIColor(red: CGFloat(groupPost.avgRed), green: CGFloat(groupPost.avgGreen), blue: CGFloat(groupPost.avgBlue), alpha: CGFloat(groupPost.avgAlpha))
            
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
                    self.upperCoverView.isHidden = false
                    self.coverView.isHidden = false
                    if image.size.width >  image.size.height {
                        self.photoImageView.contentMode = .scaleAspectFit
                    }
                    else {
                        self.photoImageView.contentMode = .scaleAspectFill
                    }
                } else {
                    self.photoImageView.image = CustomImageView.imageWithColor(color: .white)
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
    
    let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.white
        button.isUserInteractionEnabled = false
        button.setImage(#imageLiteral(resourceName: "play").withRenderingMode(.alwaysOriginal), for: .normal)
        button.isHidden = true
        return button
    }()
    
    let newDot: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 10/2
        view.isHidden = true
        return view
    }()
    
    let hourglassButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.white
        button.isUserInteractionEnabled = false
        button.setImage(#imageLiteral(resourceName: "hourglass1").withRenderingMode(.alwaysOriginal), for: .normal)
        button.isHidden = true
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
        contentView.insertSubview(photoImageView, at: 4)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: CGFloat(1), paddingLeft: CGFloat(1), paddingBottom: CGFloat(1), paddingRight: CGFloat(1), width: 0, height: 0)
        photoImageView.layer.cornerRadius = 10
        photoImageView.layer.borderColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1).cgColor
        photoImageView.layer.borderWidth = 1
        photoImageView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        self.layer.borderWidth = 0
        
        insertSubview(playButton, at: 6)
        playButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor)
        
        insertSubview(newDot, at: 6)
        newDot.heightAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        newDot.widthAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        newDot.anchor(bottom: bottomAnchor, right: rightAnchor, paddingBottom: 10, paddingRight: 10)
        
        insertSubview(hourglassButton, at: 6)
        hourglassButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        hourglassButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        hourglassButton.anchor(top: topAnchor, right: rightAnchor, paddingTop: 10, paddingRight: 10)
        
        self.readyToSetPicture = false
        
        contentView.insertSubview(coverView, at: 5)
        coverView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: CGFloat(2), paddingBottom: CGFloat(2), paddingRight: CGFloat(2), height: 20)
        coverView.layer.cornerRadius = 10
        coverView.isUserInteractionEnabled = false
        
        contentView.insertSubview(upperCoverView, at: 5)
        upperCoverView.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: CGFloat(2), paddingLeft: CGFloat(2), paddingRight: CGFloat(2), height: 20)
        upperCoverView.layer.cornerRadius = 10
        upperCoverView.isUserInteractionEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadNewDot), name: NSNotification.Name(rawValue: "reloadViewedPosts"), object: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
                
        photoImageView.image = CustomImageView.imageWithColor(color: .white)
        photoImageView.layer.borderColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1).cgColor
        photoImageView.layer.borderWidth = 1
        photoImageView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        self.layer.borderWidth = 0
        
        playButton.isHidden = true
        hourglassButton.isHidden = true
        hourglassButton.setImage(#imageLiteral(resourceName: "hourglass1").withRenderingMode(.alwaysOriginal), for: .normal)
        newDot.isHidden = true
        groupPost = nil
        viewedPost = nil
        
        self.upperCoverView.isHidden = true
        self.coverView.isHidden = true
        
        self.readyToSetPicture = false
    }
    
    @objc func reloadNewDot(){
        guard let groupPost = groupPost else { return }
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
}
