//
//  LoadMoreNotificationsCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 6/14/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol loadMoreNotificationsCellDelegate {
    func handleLoadMoreNotifications()
}

class LoadMoreNotificationsCell: UICollectionViewCell {
    var delegate: loadMoreNotificationsCellDelegate?
    
    var index: Int? {
        didSet {
            setLoadMoreVisibility(index: index!)
        }
    }
    
    private lazy var loadMoreButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(.black, for: .normal)
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        label.contentHorizontalAlignment = .center
        label.isUserInteractionEnabled = true
        label.text("Load More")
        label.isHidden = true
        label.addTarget(self, action: #selector(handleLoadMore), for: .touchUpInside)
        return label
    }()
    
    static var cellId = "loadMoreNotificationCellId"
    
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
        loadMoreButton.isHidden = true
    }
    
    private func sharedInit() {
        addSubview(loadMoreButton)
        loadMoreButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor)
    }
    
    func setLoadMoreVisibility(index: Int){
        if index < 6 {
            loadMoreButton.isHidden = true
            return
        }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().numberOfNotificationsForUser(withUID: currentLoggedInUserId, completion: { (numNotificationsTotal) in
            if index == numNotificationsTotal {
                self.loadMoreButton.isHidden = true
            }
            else {
                self.loadMoreButton.isHidden = false
            }
        })
    }
    
    @objc private func handleLoadMore(){
        self.delegate?.handleLoadMoreNotifications()
    }
}
