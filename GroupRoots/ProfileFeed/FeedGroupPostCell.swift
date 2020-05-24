//
//  FeedGroupPostCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 5/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import SGImageCache

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
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: CGFloat(1), paddingLeft: CGFloat(1), paddingBottom: CGFloat(1), paddingRight: CGFloat(1), width: 0, height: 0)
        photoImageView.layer.cornerRadius = 10
        photoImageView.layer.borderColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        photoImageView.layer.borderWidth = 0
        photoImageView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        self.layer.borderWidth = 0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = CustomImageView.imageWithColor(color: .white)
        photoImageView.layer.borderColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        photoImageView.layer.borderWidth = 0
        photoImageView.backgroundColor = UIColor(white: 1, alpha: 0.1)
        self.layer.borderWidth = 0
    }
}

