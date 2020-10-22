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
    
    var groupPost: GroupPost? {
        didSet {
            guard var imageUrl = self.groupPost?.imageUrl else { return }
            guard var videoUrl = self.groupPost?.videoUrl else { return }
            guard let groupId = self.groupPost?.group.groupId else { return }
            guard let postId = self.groupPost?.id else { return }
            
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
                } else {
                    self.photoImageView.image = CustomImageView.imageWithColor(color: .white)
                    self.readyToSetPicture = true
                    
                    // using a timer here to fix diagonal issue. Bandaid solution
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
                        if self.groupPost != nil {
                            SGImageCache.getImage(url: self.groupPost!.imageUrl) { [weak self] image in
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
        insertSubview(photoImageView, at: 4)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: CGFloat(1), paddingLeft: CGFloat(1), paddingBottom: CGFloat(1), paddingRight: CGFloat(1), width: 0, height: 0)
        photoImageView.layer.cornerRadius = 10
        photoImageView.layer.borderColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1).cgColor
        photoImageView.layer.borderWidth = 1
        photoImageView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        self.layer.borderWidth = 0
        
        insertSubview(playButton, at: 5)
        playButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor)
        
        insertSubview(newDot, at: 5)
        newDot.heightAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        newDot.widthAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        newDot.anchor(bottom: bottomAnchor, right: rightAnchor, paddingBottom: 10, paddingRight: 10)
        
        self.readyToSetPicture = false
        
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
        newDot.isHidden = true
        groupPost = nil
        viewedPost = nil
        
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
