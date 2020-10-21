//
//  GroupProfileEmptyStateCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol GroupProfileEmptyStateCellDelegate {
    func postToGroup()
}

class GroupProfileEmptyStateCell: UICollectionViewCell {
    
    var delegate: GroupProfileEmptyStateCellDelegate?
    
    var group: Group? {
        didSet {
            configureNoPostsLabel()
        }
    }
    
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
    
    private lazy var emptyPostButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(postToGroup), for: .touchUpInside)
        button.setTitle("Post", for: .normal)
        button.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        button.backgroundColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.isUserInteractionEnabled = true
        button.isHidden = true
        return button
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
        noPostsLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: UIScreen.main.bounds.height / 8)
        
        addSubview(emptyPostButton)
        emptyPostButton.anchor(top: noPostsLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 20, paddingLeft: UIScreen.main.bounds.width/3, paddingRight: UIScreen.main.bounds.width/3, height: 40)
    }
    
    private func configureNoPostsLabel(){
        guard let canView = self.canView else { return }
        guard let isInFollowPending = self.isInFollowPending else { return }
        guard let group = group else { return }
        
        if canView {
            noPostsLabel.text = "No posts yet."
        }
        else if isInFollowPending {
            noPostsLabel.text = "This group is private.\n Your subscription is pending."
        }
        else {
            noPostsLabel.text = "This group is private.\n Subscribe to see their posts."
        }
        
        Database.database().isInGroup(groupId: group.groupId, completion: { (inGroup) in
            if inGroup {
                self.emptyPostButton.isHidden = false
            }
        }) { (err) in
            return
        }
    }
    
    @objc func postToGroup(){
        self.delegate?.postToGroup()
    }
}
