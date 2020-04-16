//
//  GroupFollowersHeader.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 2/29/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

// Will contain a toolbar with two buttons: Members and Requesting Members

//MARK: - MembersHeaderDelegate

protocol GroupFollowersHeaderDelegate {
    func didChangeToFollowersView()
    func didChangeToPendingFollowersView()
}

//MARK: - MembersHeader

class GroupFollowersHeader: UICollectionViewCell {

    var delegate: GroupFollowersHeaderDelegate?

    var showPendingButton: Bool? {
        didSet {
            if showPendingButton! {
                layoutBottomToolbar()
            }
        }
    }
    
    var isFollowersView: Bool? {
        didSet{
            if isFollowersView! {
                followersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
                pendingFollowersButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
            }
            else {
                pendingFollowersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
                followersButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
            }
        }
    }

    private lazy var pendingFollowersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Pending Subscribers", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor(white: 0, alpha: 0.6).cgColor
        button.addTarget(self, action: #selector(handleChangeToPendingFollowersView), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()

    private lazy var followersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Subscribers", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor(white: 0, alpha: 0.6).cgColor
        button.addTarget(self, action: #selector(handleChangeToFollowersView), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()

    private let padding: CGFloat = 12

    static var headerId = "groupFollowersHeaderId"

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    private func sharedInit() {
        followersButton.setTitleColor(UIColor.mainBlue, for: .normal)
    }

    private func layoutBottomToolbar() {
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor(white: 0, alpha: 0.2)

        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor(white: 0, alpha: 0.2)

        let stackView = UIStackView(arrangedSubviews: [followersButton, pendingFollowersButton])
        stackView.distribution = .fillEqually

        addSubview(stackView)
        addSubview(topDividerView)
        addSubview(bottomDividerView)

        topDividerView.anchor(top: stackView.topAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
        bottomDividerView.anchor(top: stackView.bottomAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
        stackView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, height: 44)
    }

    @objc private func handleChangeToPendingFollowersView() {
        pendingFollowersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        followersButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
        delegate?.didChangeToPendingFollowersView()
    }

    @objc private func handleChangeToFollowersView() {
        followersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        pendingFollowersButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
        delegate?.didChangeToFollowersView()
    }
}


