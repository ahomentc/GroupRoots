//
//  GroupProfileEmptyStateCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit

class GroupProfileEmptyStateCell: UICollectionViewCell {
    
    var canView: Bool? {
        didSet {
            configureNoPostsLabel()
        }
    }
    
    var isInFollowPending: Bool? {
        didSet {
            configureNoPostsLabel()
        }
    }
    
    private let noPostsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.text = ""
        label.numberOfLines = 2
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    static var cellId = "groupProfileEmptyStateCellId"
    
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
    
    private func configureNoPostsLabel(){
        guard let canView = self.canView else { return }
        guard let isInFollowPending = self.isInFollowPending else { return }
        if canView {
            noPostsLabel.text = "No posts yet."
        }
        else if isInFollowPending {
            noPostsLabel.text = "This Group is Private.\n Your subscription is pending."
        }
        else {
            noPostsLabel.text = "This Group is Private.\n Subscribe to see their posts."
        }
    }
}
