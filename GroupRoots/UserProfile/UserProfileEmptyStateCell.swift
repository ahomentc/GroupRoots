//
//  UserProfileEmptyStateCell.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 8/11/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit

class UserProfileEmptyStateCell: UICollectionViewCell {
    
    private let noPostsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.text = "Member of no groups yet"
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    static var cellId = "userProfileEmptyStateCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(noPostsLabel)
        noPostsLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor)
    }
}


class MembershipLabelCell: UICollectionViewCell {
    
    private let membershipsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = "Group Memberships"
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    static var cellId = "membershipLabelCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(membershipsLabel)
        membershipsLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 25)
    }
}
