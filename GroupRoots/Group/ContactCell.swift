//
//  ContactCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 8/29/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit

class ContactCell: UICollectionViewCell {
    
    var contact: Contact? {
        didSet {
            configureCell()
        }
    }
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    static var cellId = "contactCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(profileImageView)
        profileImageView.anchor(left: leftAnchor, paddingLeft: 8, width: 50, height: 50)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 50 / 2
        
        addSubview(nameLabel)
        nameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, paddingLeft: 8)
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        addSubview(separatorView)
        separatorView.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingLeft: 20, paddingRight: 20, height: 0.5)
    }
    
    private func configureCell() {
        guard let contact = contact else { return }
        nameLabel.text = contact.given_name + " " + contact.family_name
    }
}

class MiniContactCell: UICollectionViewCell {
    
    var contact: Contact? {
        didSet {
            configureCell()
        }
    }
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    static var cellId = "contactCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        self.backgroundColor = UIColor.init(white: 0.9, alpha: 1)
        
        addSubview(profileImageView)
        profileImageView.anchor(left: leftAnchor, paddingLeft: 8, width: 30, height: 30)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 30 / 2
        
        addSubview(nameLabel)
        nameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, paddingLeft: 8)
    }
    
    private func configureCell() {
        guard let contact = contact else { return }
        nameLabel.text = contact.given_name + " " + contact.family_name
    }
}
