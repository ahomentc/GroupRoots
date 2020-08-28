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
    
    var hasGroupMemberRequestors: Bool? {
        didSet {
            setButtonColors()
        }
    }
    
    var isInGroup: Bool? {
        didSet {
            if isInGroup!{
                layoutBottomToolbar()
            }
        }
    }
    
    var isMembersView: Bool? {
        didSet{
            setButtonColors()
        }
    }
    
    private func setButtonColors(){
        guard let isMembersView = isMembersView else { return }
        guard let hasGroupMemberRequestors = hasGroupMemberRequestors else { return }
        
        if isMembersView {
//            membersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
//            requestsButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
            setAttributedTextBasicForMembers(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
            if hasGroupMemberRequestors {
                setAttributedTextWithDotForRequests(color: UIColor(white: 0, alpha: 0.2))
            }
            else {
                setAttributedTextBasicForRequests(color: UIColor(white: 0, alpha: 0.2))
            }
        }
        else {
//            requestsButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
//            membersButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
            setAttributedTextBasicForMembers(color: UIColor(white: 0, alpha: 0.2))
            if hasGroupMemberRequestors {
                setAttributedTextWithDotForRequests(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
            }
            else {
                setAttributedTextBasicForRequests(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
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
//        membersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        setAttributedTextBasicForMembers(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
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
        setAttributedTextBasicForMembers(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
        delegate?.didChangeToMembersView()
        self.isMembersView = true
        guard hasGroupMemberRequestors != nil else {
            setAttributedTextBasicForRequests(color: UIColor(white: 0, alpha: 0.2))
            return
        }
        setAttributedTextWithDotForRequests(color: UIColor(white: 0, alpha: 0.2))
    }

    @objc func handleChangeToRequestsView() {
        setAttributedTextBasicForMembers(color: UIColor(white: 0, alpha: 0.2))
        delegate?.didChangeToRequestsView()
        self.isMembersView = false
        guard hasGroupMemberRequestors != nil else {
            setAttributedTextBasicForRequests(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
            return
        }
        setAttributedTextWithDotForRequests(color: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1))
    }
    
    private func setAttributedTextBasicForMembers(color: UIColor){
        let balanceFontSize: CGFloat = 15
        let balanceFont = UIFont.systemFont(ofSize: balanceFontSize)
        let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, NSAttributedString.Key.foregroundColor : color]
        let attributedText = NSMutableAttributedString(string: "Members", attributes: balanceAttr)
        self.membersButton.setAttributedTitle(attributedText, for: .normal)
    }
    
    // this loads first while we wait to see if has members requesting in database
    private func setAttributedTextBasicForRequests(color: UIColor){
        let balanceFontSize: CGFloat = 15
        let balanceFont = UIFont.systemFont(ofSize: balanceFontSize)
        let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, NSAttributedString.Key.foregroundColor : color]
        let attributedText = NSMutableAttributedString(string: "Requesting members", attributes: balanceAttr)
        self.requestsButton.setAttributedTitle(attributedText, for: .normal)
    }
    
    private func setAttributedTextWithDotForRequests(color: UIColor) {
        guard let hasGroupMemberRequestors = hasGroupMemberRequestors else { return }
        
        let balanceFontSize: CGFloat = 15
        let balanceFont = UIFont.systemFont(ofSize: balanceFontSize)
        
        if hasGroupMemberRequestors {
            let dotImage = #imageLiteral(resourceName: "dot")
            let dotIcon = NSTextAttachment()
            dotIcon.image = dotImage
            let dotIconString = NSAttributedString(attachment: dotIcon)

            //Setting up font and the baseline offset of the string, so that it will be centered
            let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, .baselineOffset: (dotImage.size.height - balanceFontSize + 2) / 2 - balanceFont.descender / 2, NSAttributedString.Key.foregroundColor : color]
            let attributedText = NSMutableAttributedString(string: "Requesting members", attributes: balanceAttr)
            attributedText.insert(NSAttributedString(string: "  ", attributes: [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)]), at: 0)
            attributedText.insert(dotIconString, at: 0)
            self.requestsButton.setAttributedTitle(attributedText, for: .normal)
        }
        else {
            let balanceAttr: [NSAttributedString.Key: Any] = [.font: balanceFont, NSAttributedString.Key.foregroundColor : color]
            let attributedText = NSMutableAttributedString(string: "Requesting members", attributes: balanceAttr)
            self.requestsButton.setAttributedTitle(attributedText, for: .normal)
        }
    }
}

