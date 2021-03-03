//
//  GroupProfilePhotoGridCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit

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
            }
        }
    }
    
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
        hourglassButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
        hourglassButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 5).isActive = true
        hourglassButton.anchor(top: topAnchor, right: rightAnchor, paddingTop: 5, paddingRight: 5)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playButton.isHidden = true
        photoImageView.image = CustomImageView.imageWithColor(color: .white)
        groupPost = nil
        hourglassButton.isHidden = true
        hourglassButton.setImage(#imageLiteral(resourceName: "hourglass1").withRenderingMode(.alwaysOriginal), for: .normal)
    }
}

