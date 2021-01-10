//
//  ImportContactsCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 9/27/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import NVActivityIndicatorView

protocol ImportContactsCellDelegate {
    func didTapImportContacts()
}

class ImportContactsCell: UICollectionViewCell {
    
    let padding: CGFloat = 12
    
    var delegate: ImportContactsCellDelegate?
    
    private lazy var profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "contacts_2")
        iv.layer.borderWidth = 0
        return iv
    }()
    
    private lazy var importLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(white: 0, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Connect contacts\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSMutableAttributedString(string: "Find people you know", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11)]))
        label.attributedText = attributedText
        return label
    }()
  
    private lazy var connectButton: UIButton = {
        let button = UIButton()
        
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        
        button.widthAnchor.constraint(equalToConstant: 80).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        button.setTitle("Connect", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 0
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        button.isUserInteractionEnabled = true
        
        button.addTarget(self, action: #selector(didTapImportContacts), for: .touchUpInside)
        return button
    }()
    
    static var cellId = "importContactsCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        let attributedText = NSMutableAttributedString(string: "Connect contacts\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 15)])
        attributedText.append(NSMutableAttributedString(string: "Find people you know", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)]))
        self.importLabel.attributedText = attributedText
        
        self.connectButton.isHidden = false
    }

    private func sharedInit() {
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 18, paddingLeft: 40, width: 60, height: 60)
        profileImageView.layer.cornerRadius = 30
        
        addSubview(importLabel)
        importLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 0, height: 60)

        addSubview(connectButton)
        connectButton.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, paddingTop: 58, paddingLeft: 30)
        
        self.backgroundColor = .white
        
        self.contentView.layer.cornerRadius = 20.0
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true
    }
    
    @objc private func didTapImportContacts() {
        self.importLabel.attributedText = NSMutableAttributedString(string: "Connecting", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 15)])
        self.connectButton.isHidden = true
        self.delegate?.didTapImportContacts()
    }
}




