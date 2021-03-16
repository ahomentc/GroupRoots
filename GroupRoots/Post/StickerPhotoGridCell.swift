//
//  StickerPhotoGridCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/12/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import UIKit

class StickerPhotoGridCell: UICollectionViewCell {
    
    var sticker: Sticker? {
        didSet {
            guard let sticker = sticker else { return }
            photoImageView.loadImage(urlString: sticker.imageUrl)
        }
    }
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.clear
        iv.image = CustomImageView.imageWithColor(color: .white)
        return iv
    }()
    
    static var cellId = "stickerPhotoGridCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        self.backgroundColor = .clear
        
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: CGFloat(2), paddingLeft: CGFloat(2), paddingBottom: CGFloat(2), paddingRight: CGFloat(2), width: 0, height: 0)
        photoImageView.layer.cornerRadius = 3
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = CustomImageView.imageWithColor(color: .white)
        sticker = nil
    }
}



