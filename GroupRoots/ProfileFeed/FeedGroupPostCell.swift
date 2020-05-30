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

class FeedGroupPostCell: UICollectionViewCell {
    
    var groupPost: GroupPost? {
        didSet {
            guard let imageUrl = groupPost?.imageUrl else { return }
            photoImageView.loadImage(urlString: imageUrl)
            
            if let image = SGImageCache.image(forURL: imageUrl) {
                photoImageView.image = image   // image loaded immediately from cache
                
            } else {
                self.photoImageView.image = CustomImageView.imageWithColor(color: .white)
                SGImageCache.getImage(url: imageUrl) { [weak self] image in
                    self?.photoImageView.image = image   // image loaded async
                }
            }
            
            // set a playButton (not clickable) for video previews
            guard let videoUrl = groupPost?.videoUrl else { return }
            if videoUrl != "" {
                playButton.isHidden = false
            }

            // set newDot as visible or not
            guard let post_id = groupPost?.id else { return }
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
//        iv.backgroundColor = .white
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
    
//    let newDot: UILabel = {
//        let view = UILabel()
//        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
//        view.textColor = .white
//        view.text = "new"
//        view.textAlignment = .center
//        view.layer.cornerRadius = 5
//        view.clipsToBounds = true
//        return view
//    }()
    
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
        
//        insertSubview(newDot, at: 5)
//        newDot.widthAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
//        newDot.anchor(bottom: bottomAnchor, right: rightAnchor, paddingBottom: 10, paddingRight: 10)
        
        insertSubview(newDot, at: 5)
        newDot.heightAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        newDot.widthAnchor.constraint(greaterThanOrEqualToConstant: 10).isActive = true
        newDot.anchor(bottom: bottomAnchor, right: rightAnchor, paddingBottom: 10, paddingRight: 10)
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
    }
}
