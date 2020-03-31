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
        }
    }
    
    private let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.95, alpha: 1)
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
    }
}

