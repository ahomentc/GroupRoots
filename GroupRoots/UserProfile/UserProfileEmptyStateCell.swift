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
//        label.font = UIFont.systemFont(ofSize: 18)
//        label.text = "Group Memberships"
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        let attributedText = NSMutableAttributedString(string: "Group Memberships", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)])
        label.attributedText = attributedText
        return label
    }()
    
    var numberOfGroups: Int = 0 {
        didSet {
            if numberOfGroups == 1 {
                let attributedText = NSMutableAttributedString(string: "1", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)])
                attributedText.append(NSAttributedString(string: " Group Membership", attributes: [NSAttributedString.Key.foregroundColor: UIColor.init(white: 0.1, alpha: 1), NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)]))
                self.membershipsLabel.attributedText = attributedText
            }
            else if numberOfGroups > 1 {
                let attributedText = NSMutableAttributedString(string: String(numberOfGroups), attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)])
                attributedText.append(NSAttributedString(string: " Group Memberships", attributes: [NSAttributedString.Key.foregroundColor: UIColor.init(white: 0.1, alpha: 1), NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)]))
                self.membershipsLabel.attributedText = attributedText
            }
        }
    }
    
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
        
        self.backgroundColor = .white
        
//        let separatorView = UIView()
//        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.2)
//        addSubview(separatorView)
//        separatorView.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 10, paddingRight: 10, height: 0.5)
    }
}
