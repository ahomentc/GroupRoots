//
//  MembersHeader.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/20/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

// Will contain a toolbar with two buttons: Members and Requesting Members

//MARK: - MembersHeaderDelegate

protocol MembersHeaderDelegate {
    func didChangeToMembersView()
    func didChangeToRequestsView()
}

//MARK: - MembersHeader

class MembersHeader: UICollectionViewCell {

    var delegate: MembersHeaderDelegate?

    var isInGroup: Bool? {
        didSet {
            if isInGroup!{
                layoutBottomToolbar()
            }
        }
    }
    
    var isMembersView: Bool? {
        didSet{
            if isMembersView! {
                membersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
                requestsButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
            }
            else {
                requestsButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
                membersButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
            }
        }
    }

    private lazy var requestsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Requesting Members", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor(white: 0, alpha: 0.6).cgColor
        button.addTarget(self, action: #selector(handleChangeToRequestsView), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()

    private lazy var membersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Members", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor(white: 0, alpha: 0.6).cgColor
        button.addTarget(self, action: #selector(handleChangeToMembersView), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()

    private let padding: CGFloat = 12

    static var headerId = "membersHeaderId"

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    private func sharedInit() {
        membersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
    }

    private func layoutBottomToolbar() {
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor(white: 0, alpha: 0.2)

        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor(white: 0, alpha: 0.2)

        let stackView = UIStackView(arrangedSubviews: [membersButton, requestsButton])
        stackView.distribution = .fillEqually

        addSubview(stackView)
        addSubview(topDividerView)
        addSubview(bottomDividerView)

        topDividerView.anchor(top: stackView.topAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
        bottomDividerView.anchor(top: stackView.bottomAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
        stackView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, height: 44)
    }
    
    @objc func handleChangeToMembersView() {
        membersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        requestsButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
        delegate?.didChangeToMembersView()
    }

    @objc func handleChangeToRequestsView() {
        requestsButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        membersButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
        delegate?.didChangeToRequestsView()
    }
    
}

