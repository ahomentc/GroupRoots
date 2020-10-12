//
//  PlusCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 10/11/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit

class PlusCell: UICollectionViewCell {
    
    
    var parentCollectionViewSize: Int? {
        didSet {
            guard let parentCollectionViewSize = parentCollectionViewSize else { return }
            if parentCollectionViewSize > 1 {
                self.photoImageView.isHidden = false
                self.border.isHidden = false
                self.plusButton.isHidden = false
            }
        }
    }
    
    let border: UIView = {
        let border = UIView()
        border.backgroundColor = .clear
        border.layer.borderWidth = 1
//        border.layer.borderColor = UIColor.init(white: 0.8, alpha: 1).cgColor
        border.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        border.layer.cornerRadius = 12
        border.isHidden = true
        return border
    }()
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.white
        iv.image = #imageLiteral(resourceName: "simple_plus_2").withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        iv.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        iv.isHidden = true
        return iv
    }()
    
    private lazy var plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "simple_plus_2").withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: .normal)
        button.isUserInteractionEnabled = true
        button.isHidden = true
        button.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
//        button.addTarget(self, action: #selector(handleCloseFullscreen), for: .touchUpInside)
//        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }()
    
    static var cellId = "plusCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
//        let width = (UIScreen.main.bounds.width / 3) / 3 * 2
//        let height = (UIScreen.main.bounds.width / 3) / 3
//        let padding_width = width / 1.8
//        let padding_height = height / 1.8
//        addSubview(photoImageView)
//        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: CGFloat(padding_width), paddingLeft: CGFloat(padding_height), paddingBottom: CGFloat(padding_width), paddingRight: CGFloat(padding_height), width: 0, height: 0)
//        photoImageView.layer.cornerRadius = 3
        
        addSubview(plusButton)
        plusButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: CGFloat(0), paddingLeft: CGFloat(0), paddingBottom: CGFloat(0), paddingRight: CGFloat(0), width: 20, height: 20)
        plusButton.layer.cornerRadius = 3
        
        addSubview(border)
        border.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: CGFloat(2), paddingLeft: CGFloat(2), paddingBottom: CGFloat(2), paddingRight: CGFloat(2), width: 0, height: 0)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.photoImageView.isHidden = true
        self.border.isHidden = true
        self.parentCollectionViewSize = nil
    }
}


