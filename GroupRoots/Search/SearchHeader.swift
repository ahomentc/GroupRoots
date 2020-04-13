//
//  SearchHeader.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/31/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

// Will contain a toolbar with two buttons: Users and Requesting Users

//MARK: - UsersHeaderDelegate

protocol SearchHeaderDelegate {
    func didChangeToUsersView()
    func didChangeToGroupsView()
}

//MARK: - UsersHeader

class SearchHeader: UICollectionViewCell {

    var delegate: SearchHeaderDelegate?

    private lazy var groupsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Group", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font =  UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor(white: 0, alpha: 0.6).cgColor
        button.addTarget(self, action: #selector(handleChangeToGroupsView), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()

    private lazy var usersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("User", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font =  UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor(white: 0, alpha: 0.6).cgColor
        button.addTarget(self, action: #selector(handleChangeToUsersView), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()

    private let padding: CGFloat = 12

    static var headerId = "usersHeaderId"

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    private func sharedInit() {
        usersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        layoutBottomToolbar()
    }

    private func layoutBottomToolbar() {
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor(white: 0, alpha: 0.2)

        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor(white: 0, alpha: 0.2)

        let stackView = UIStackView(arrangedSubviews: [usersButton, groupsButton])
        stackView.distribution = .fillEqually

        addSubview(stackView)
        addSubview(topDividerView)
        addSubview(bottomDividerView)

        topDividerView.anchor(top: stackView.topAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
        bottomDividerView.anchor(top: stackView.bottomAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
        stackView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, height: 44)
    }

    @objc private func handleChangeToGroupsView() {
        groupsButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        usersButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
        delegate?.didChangeToGroupsView()
    }

    @objc private func handleChangeToUsersView() {
        usersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        groupsButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
        delegate?.didChangeToUsersView()
    }
}
