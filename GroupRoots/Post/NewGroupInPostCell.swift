//
//  NewGroupInPostCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 10/11/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class NewGroupInPostCell: UICollectionViewCell {

    private let newGroupLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.text = "Post to a new group"
        label.textAlignment = .center
        return label
    }()
    
    private lazy var newGroupButton: UIButton = {
        let button = UIButton()
//        button.addTarget(self, action: #selector(didTapNewGroup), for: .touchUpInside)
        button.layer.zPosition = 4;
//        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Post to a new group", for: .normal)
        button.layer.cornerRadius = 14
        button.isUserInteractionEnabled = false
        return button
    }()
    
    static var cellId = "newGroupInPostCellId"
    
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
        self.backgroundColor = UIColor.clear
    }
    
    private func sharedInit() {
        addSubview(newGroupButton)
        newGroupButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 50, paddingBottom: 5, paddingRight: 50)
    }
}
