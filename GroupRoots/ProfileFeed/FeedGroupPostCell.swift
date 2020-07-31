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
import NVActivityIndicatorView

class FeedGroupPostCell: UICollectionViewCell {
    
    var readyToSetPicture = false
    
    var groupPost: GroupPost? {
        didSet {
//            print("setting groupPost 0 ", groupPost?.id, " for tag ", self.tag)
            guard let imageUrl = self.groupPost?.imageUrl else { return }
            if let image = SGImageCache.image(forURL: imageUrl) {
                self.photoImageView.image = image   // image loaded immediately from cache
            } else {
//                self.photoImageView.image = CustomImageView.imageWithColor(color: .white)
//                SGImageCache.getImage(url: imageUrl) { [weak self] image in
//                    self?.photoImageView.image = image   // image loaded async
//                }
                self.photoImageView.image = CustomImageView.imageWithColor(color: .white)
                self.readyToSetPicture = true
                
                // using a timer here to fix diagonal issue. Bandaid solution
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { timer in
                    SGImageCache.getImage(url: self.groupPost?.imageUrl ?? "") { [weak self] image in
//                        self?.photoImageView.image = image   // image loaded async
                        if self?.readyToSetPicture ?? false {
                            self?.photoImageView.image = image   // image loaded async
//                            print("setting image ", imageUrl, " for tag ", self?.tag)
//                            print("setting groupPost 1 ", self?.groupPost?.id, " for tag ", self?.tag)
                        }
                    }
                })
            }

//            self.photoImageView.image = CustomImageView.imageWithColor(color: .white)
//            self.readyToSetPicture = true
//            SGImageCache.getImage(url: imageUrl) { [weak self] image in
//                if self?.readyToSetPicture ?? false {
//                    self?.photoImageView.image = image   // image loaded async
//                }
//            }
            
            // set a playButton (not clickable) for video previews
            guard let videoUrl = self.groupPost?.videoUrl else { return }
            if videoUrl != "" {
                self.playButton.isHidden = false
            }
            
            // set newDot as visible or not
            guard let post_id = self.groupPost?.id else { return }
            Database.database().hasViewedPost(postId: post_id, completion: { (hasViewed) in
                if hasViewed{
                    self.newDot.isHidden = true
                }
                else {
                    self.newDot.isHidden = false
                }
            }) { (err) in return }
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
        
        self.readyToSetPicture = false
    }
}
