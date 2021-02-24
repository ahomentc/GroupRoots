//
//  MemePhotoGridCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/23/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import UIKit

class MemePhotoGridCell: UICollectionViewCell {
    
    var memeUrl: String? {
        didSet {
            guard let memeUrl = memeUrl else { return }
            photoImageView.loadImage(urlString: memeUrl)
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
    
    static var cellId = "memePhotoGridCellId"
    
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = CustomImageView.imageWithColor(color: .white)
        memeUrl = nil
    }
}


