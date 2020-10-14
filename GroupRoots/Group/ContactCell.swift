//
//  ContactCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 8/29/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit

protocol ContactCellDelegate {
    func remove_contact(contact: Contact)
}

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
    
    private let nameIconLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.text = ""
        label.layer.borderColor = UIColor(white: 0, alpha: 0.35).cgColor
        label.layer.borderWidth = 0.5
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor =  UIColor(white: 0, alpha: 0.3)
        label.clipsToBounds = true
        return label
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
//        addSubview(profileImageView)
//        profileImageView.anchor(left: leftAnchor, paddingLeft: 8, width: 50, height: 50)
//        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//        profileImageView.layer.cornerRadius = 50 / 2
        
        addSubview(nameIconLabel)
        nameIconLabel.anchor(left: leftAnchor, paddingLeft: 8, width: 50, height: 50)
        nameIconLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        nameIconLabel.layer.cornerRadius = 50 / 2
        
        addSubview(nameLabel)
//        nameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, paddingLeft: 8)
        nameLabel.anchor(top: topAnchor, left: nameIconLabel.rightAnchor, bottom: bottomAnchor, paddingLeft: 8)
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        addSubview(separatorView)
        separatorView.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingLeft: 20, paddingRight: 20, height: 0.5)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = #imageLiteral(resourceName: "user")
        contact = nil
        nameIconLabel.text = ""
    }
    
    private func configureCell() {
        guard let contact = contact else { return }
        nameLabel.text = contact.given_name + " " + contact.family_name
        var firstInitial = ""
        var secondInitial = ""
        if contact.given_name.first != nil {
            firstInitial = String(contact.given_name.first!)
        }
        if contact.family_name.first != nil {
            secondInitial = String(contact.family_name.first!)
        }
        nameIconLabel.text = firstInitial.uppercased() + secondInitial.uppercased()
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
    
    private let nameIconLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.text = ""
        label.layer.borderColor = UIColor(white: 0, alpha: 0.35).cgColor
        label.layer.borderWidth = 0.5
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor =  UIColor(white: 0, alpha: 0.3)
        label.clipsToBounds = true
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    private lazy var removeButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "x").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(didRemove), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    static var cellId = "miniContactCellId"
    
    var delegate: ContactCellDelegate?
    
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
        
//        addSubview(profileImageView)
//        profileImageView.anchor(left: leftAnchor, paddingLeft: 8, width: 30, height: 30)
//        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//        profileImageView.layer.cornerRadius = 30 / 2
        
        addSubview(nameIconLabel)
        nameIconLabel.anchor(left: leftAnchor, paddingLeft: 8, width: 30, height: 30)
        nameIconLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        nameIconLabel.layer.cornerRadius = 30 / 2
        
        addSubview(nameLabel)
//        nameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, paddingLeft: 8)
        nameLabel.anchor(top: topAnchor, left: nameIconLabel.rightAnchor, bottom: bottomAnchor, paddingLeft: 8)
        
        addSubview(removeButton)
        removeButton.anchor(top: topAnchor, bottom: bottomAnchor, right: rightAnchor, paddingRight: 5, width: 30, height: 30)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = #imageLiteral(resourceName: "user")
        contact = nil
        nameIconLabel.text = ""
    }
    
    private func configureCell() {
        guard let contact = contact else { return }
        nameLabel.text = contact.given_name + " " + contact.family_name
        
        var firstInitial = ""
        var secondInitial = ""
        if contact.given_name.first != nil {
            firstInitial = String(contact.given_name.first!)
        }
        if contact.family_name.first != nil {
            secondInitial = String(contact.family_name.first!)
        }
        nameIconLabel.text = firstInitial.uppercased() + secondInitial.uppercased()
    }
    
    @objc private func didRemove() {
        guard let contact = contact else { return }
        delegate?.remove_contact(contact: contact)
    }
}
