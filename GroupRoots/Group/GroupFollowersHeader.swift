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
    
    var hasSubscriptionRequestors: Bool? {
        didSet {
            setButtonColors()
        }
    }

    var showPendingButton: Bool? {
        didSet {
            if showPendingButton! {
                layoutBottomToolbar()
            }
        }
    }
    
    var isFollowersView: Bool? {
        didSet{
            setButtonColors()
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
//        followersButton.setTitleColor(UIColor.mainBlue, for: .normal)
        setAttributedTextBasicForSubscribers(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
        setAttributedTextBasicForRequests(color: UIColor(white: 0, alpha: 0.2))
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
    
    @objc private func handleChangeToFollowersView() {
        if self.isFollowersView ?? false {
            return
        }
        delegate?.didChangeToFollowersView()
        setAttributedTextBasicForSubscribers(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
        self.isFollowersView = true
        guard hasSubscriptionRequestors != nil else {
            setAttributedTextBasicForRequests(color: UIColor(white: 0, alpha: 0.2))
            return
        }
        setAttributedTextWithDotForRequests(color: UIColor(white: 0, alpha: 0.2))
    }

    @objc private func handleChangeToPendingFollowersView() {
        if !(self.isFollowersView ?? true) {
            return
        }
        delegate?.didChangeToPendingFollowersView()
        self.isFollowersView = false
        setAttributedTextBasicForSubscribers(color: UIColor(white: 0, alpha: 0.2))
        guard hasSubscriptionRequestors != nil else {
            setAttributedTextBasicForRequests(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
            return
        }
        setAttributedTextWithDotForRequests(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
    }
    
    private func setButtonColors(){
        guard let isFollowersView = isFollowersView else { return }
        guard let hasSubscriptionRequestors = hasSubscriptionRequestors else { return }
        
        if isFollowersView {
            setAttributedTextBasicForSubscribers(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
            if hasSubscriptionRequestors {
                setAttributedTextWithDotForRequests(color: UIColor(white: 0, alpha: 0.2))
            }
            else {
                setAttributedTextBasicForRequests(color: UIColor(white: 0, alpha: 0.2))
            }
        }
        else {
            setAttributedTextBasicForSubscribers(color: UIColor(white: 0, alpha: 0.2))
            if hasSubscriptionRequestors {
                setAttributedTextWithDotForRequests(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
            }
            else {
                setAttributedTextBasicForRequests(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
            }
        }
    }
    
    private func setAttributedTextBasicForSubscribers(color: UIColor){
        let balanceFontSize: CGFloat = 15
        let balanceFont = UIFont.systemFont(ofSize: balanceFontSize)
        let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, NSAttributedString.Key.foregroundColor : color]
        let attributedText = NSMutableAttributedString(string: "Subscribers", attributes: balanceAttr)
        self.followersButton.setAttributedTitle(attributedText, for: .normal)
    }
    
    // this loads first while we wait to see if has members requesting in database
    private func setAttributedTextBasicForRequests(color: UIColor){
        let balanceFontSize: CGFloat = 15
        let balanceFont = UIFont.systemFont(ofSize: balanceFontSize)
        let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, NSAttributedString.Key.foregroundColor : color]
        let attributedText = NSMutableAttributedString(string: "Pending Subscribers", attributes: balanceAttr)
        self.pendingFollowersButton.setAttributedTitle(attributedText, for: .normal)
    }
    
    private func setAttributedTextWithDotForRequests(color: UIColor) {
        guard let hasSubscriptionRequestors = hasSubscriptionRequestors else { return }
        
        let balanceFontSize: CGFloat = 15
        let balanceFont = UIFont.systemFont(ofSize: balanceFontSize)
        
        if hasSubscriptionRequestors {
            let dotImage = #imageLiteral(resourceName: "dot")
            let dotIcon = NSTextAttachment()
            dotIcon.image = dotImage
            let dotIconString = NSAttributedString(attachment: dotIcon)

            //Setting up font and the baseline offset of the string, so that it will be centered
            let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, .baselineOffset: (dotImage.size.height - balanceFontSize + 2) / 2 - balanceFont.descender / 2, NSAttributedString.Key.foregroundColor : color]
            let attributedText = NSMutableAttributedString(string: "Pending Subscribers", attributes: balanceAttr)
            attributedText.insert(NSAttributedString(string: "  ", attributes: [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]), at: 0)
            attributedText.insert(dotIconString, at: 0)
            self.pendingFollowersButton.setAttributedTitle(attributedText, for: .normal)
        }
        else {
            let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, NSAttributedString.Key.foregroundColor : color]
            let attributedText = NSMutableAttributedString(string: "Pending Subscribers", attributes: balanceAttr)
            self.pendingFollowersButton.setAttributedTitle(attributedText, for: .normal)
        }
    }
}


