//
//  InstaPromoCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 12/23/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth

protocol PromoDelegate {
    func refreshSchool()
}

class InstaPromoCell: UICollectionViewCell {

    var delegate: PromoDelegate?
    
    lazy var close_button: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.init(white: 0.8, alpha: 1)
        button.isUserInteractionEnabled = true
        button.setImage(#imageLiteral(resourceName: "x"), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        button.addTarget(self, action: #selector(removePromo), for: .touchUpInside)
        return button
    }()
    
    private lazy var right_arrow: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "arrow_right")
        iv.backgroundColor = UIColor.clear
        iv.layer.zPosition = 4
        return iv
    }()
    
    var selectedSchool: String? {
        didSet {
            guard let selectedSchool = selectedSchool else { return }
            Database.database().fetchSchoolPromoPayout(school: selectedSchool, completion: { (payout) in
                if payout > 0 {
                    let attributedText = NSMutableAttributedString(string: "You're one of the first people!\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
                    attributedText.append(NSMutableAttributedString(string: "Post the group you create on your Instagram\nStory for a $" + String(payout) + " Amazon gift card code.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)]))
                    self.promoLabel.attributedText = attributedText
                }
            }) { (_) in}
        }
    }
    
    private let promoLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: "You're one of the first people!\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSMutableAttributedString(string: "Post the group you create on your Instagram\nStory for a Amazon gift card code.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)]))
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    static var cellId = "InstaPromoCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        self.backgroundColor = .white
        
        let separatorViewTop = UIView()
        separatorViewTop.backgroundColor = UIColor(white: 0, alpha: 0.2)
        addSubview(separatorViewTop)
        separatorViewTop.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 30, paddingLeft: 20, paddingRight: 20, height: 0.5)
        
        addSubview(close_button)
        close_button.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, paddingTop: 20, paddingLeft: 0)
        
        addSubview(right_arrow)
        right_arrow.anchor(top: topAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 20, paddingRight: 15)
        
        addSubview(promoLabel)
        promoLabel.anchor(top: topAnchor, left: close_button.rightAnchor, bottom: bottomAnchor, right: right_arrow.leftAnchor, paddingTop: 20, paddingLeft: 10, paddingRight: 15)
        
        let separatorViewBottom = UIView()
        separatorViewBottom.backgroundColor = UIColor(white: 0, alpha: 0.2)
        addSubview(separatorViewBottom)
        separatorViewBottom.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 20, paddingBottom: 10, paddingRight: 20, height: 0.5)
    }
    
    @objc func removePromo() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let selectedSchool = self.selectedSchool else { return }
        let formatted_school = selectedSchool.replacingOccurrences(of: " ", with: "_-a-_")
        Database.database().blockPromoForUser(school: formatted_school, uid: currentLoggedInUserId) { (err) in
            if err != nil {
               return
            }
            self.delegate?.refreshSchool()
        }
    }
}

class InstaPromoExistingGroupCell: UICollectionViewCell {
    
    var delegate: PromoDelegate?
    
    var promoNotActive: Bool? {
        didSet {
            setPromoLabel()
        }
    }
    
    private lazy var right_arrow: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "arrow_right")
        iv.backgroundColor = UIColor.clear
        iv.layer.zPosition = 4
        return iv
    }()

    lazy var close_button: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.init(white: 0.8, alpha: 1)
        button.isUserInteractionEnabled = true
        button.setImage(#imageLiteral(resourceName: "x"), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        button.addTarget(self, action: #selector(removePromo), for: .touchUpInside)
        return button
    }()

    var selectedSchool: String? {
        didSet {
            setPromoLabel()
        }
    }
    
    private let promoLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: "You're one of the first people!\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSMutableAttributedString(string: "Post the group you're in on your Instagram\nStory for a Amazon gift card code.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)]))
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    static var cellId = "InstaPromoExistingGroupCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    func setPromoLabel() {
        guard let promoNotActive = promoNotActive else { return }
        
        if promoNotActive {
            let attributedText = NSMutableAttributedString(string: "Share your group reservation!\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
            attributedText.append(NSMutableAttributedString(string: "View the reservation picture\nfor the group you're in", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)]))
            self.promoLabel.attributedText = attributedText
        }
        else {
            let attributedText = NSMutableAttributedString(string: "You're one of the first people!\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
            attributedText.append(NSMutableAttributedString(string: "Post the group you're in on your Instagram\nStory for a $10 Amazon gift card code.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)]))
            self.promoLabel.attributedText = attributedText
        }
    }
    
    private func sharedInit() {
        self.backgroundColor = .white
        
        let separatorViewTop = UIView()
        separatorViewTop.backgroundColor = UIColor(white: 0, alpha: 0.2)
        addSubview(separatorViewTop)
        separatorViewTop.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 30, paddingLeft: 20, paddingRight: 20, height: 0.5)
        
        addSubview(close_button)
        close_button.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, paddingTop: 20, paddingLeft: 0)
        
        addSubview(right_arrow)
        right_arrow.anchor(top: topAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 20, paddingRight: 15)
        
        addSubview(promoLabel)
        promoLabel.anchor(top: topAnchor, left: close_button.rightAnchor, bottom: bottomAnchor, right: right_arrow.leftAnchor, paddingTop: 20, paddingLeft: 10, paddingRight: 15)
        
        let separatorViewBottom = UIView()
        separatorViewBottom.backgroundColor = UIColor(white: 0, alpha: 0.2)
        addSubview(separatorViewBottom)
        separatorViewBottom.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 20, paddingBottom: 10, paddingRight: 20, height: 0.5)
    }
    
    @objc func removePromo() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let selectedSchool = self.selectedSchool else { return }
        let formatted_school = selectedSchool.replacingOccurrences(of: " ", with: "_-a-_")
        Database.database().blockPromoForUser(school: formatted_school, uid: currentLoggedInUserId) { (err) in
            if err != nil {
               return
            }
            self.delegate?.refreshSchool()
        }
    }
}

class NoGroupsInSchoolCell: UICollectionViewCell {
    
    private let noGroupsLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: "No groups created yet.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    static var cellId = "NoGroupsInSchoolCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        self.backgroundColor = .white

        addSubview(noGroupsLabel)
        noGroupsLabel.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 15, paddingRight: 15)
    }
}

protocol CreateGroupCellDelegate {
    func handleShowNewGroupForSchool(school: String)
}

class CreateGroupCell: UICollectionViewCell {
    
    private lazy var newGroupButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleShowNewGroup), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Create a group", for: .normal)
        return button
    }()
    
    var selectedSchool: String?
    
    var delegate: CreateGroupCellDelegate?
    
    static var cellId = "CreateGroupCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        self.backgroundColor = .white
        
        newGroupButton.layer.cornerRadius = 14
        self.insertSubview(newGroupButton, at: 4)
        newGroupButton.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 20, paddingLeft: UIScreen.main.bounds.width/2-150, paddingRight: UIScreen.main.bounds.width/2-150, height: 50)
    }
    
    @objc private func handleShowNewGroup() {
        guard let selectedSchool = selectedSchool else { return }
        self.delegate?.handleShowNewGroupForSchool(school: selectedSchool)
    }
}

class YourGroupsCell: UICollectionViewCell {
    
    private let schoolGroupsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.textColor = .darkGray
//        label.text = "Friend group feed"
        // Friend groups in your school
        label.text = "Friend Groups"
        return label
    }()
    
    static var cellId = "YourGroupsCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        self.backgroundColor = .white
        
        addSubview(schoolGroupsLabel)
        schoolGroupsLabel.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 20)
    }
}
