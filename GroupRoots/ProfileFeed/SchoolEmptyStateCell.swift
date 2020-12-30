//
//  SchoolEmptyStateCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 12/22/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit

protocol SchoolEmptyStateCellDelegate {
    func handleShowNewGroupForSchool(school: String)
}


class SchoolEmptyStateCell: UICollectionViewCell {
    
    let scrollView = UIScrollView()
    
    var delegate: SchoolEmptyStateCellDelegate?
    
    private let groupsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.text = "Your High School"
        label.numberOfLines = 0
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let firstOneLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: "You're the first person from your school!", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)])
        attributedText.append(NSAttributedString(string: "\n\nWe're giving $50 Amazon codes to the first 2 people who create a friend group and have their friends join.", attributes: [NSAttributedString.Key.foregroundColor: UIColor.init(white: 0.1, alpha: 1), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]))
        attributedText.append(NSAttributedString(string: "\n\nThe first 3 friends that join each group get $20.", attributes: [NSAttributedString.Key.foregroundColor: UIColor.init(white: 0.1, alpha: 1), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]))
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
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
    
    private let instaPicture: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 10
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0, alpha: 1)
        return iv
    }()
    
    var selectedSchool: String? {
        didSet {
            guard let selectedSchool = selectedSchool else { return }
            let attributedText = NSMutableAttributedString(string: selectedSchool.replacingOccurrences(of: "_-a-_", with: " ").components(separatedBy: ",")[0], attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
            self.groupsLabel.attributedText = attributedText
        }
    }
    
    static var cellId = "schoolEmptyStateCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        self.addSubview(groupsLabel)
        groupsLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 15, paddingRight: 15)
        
        addSubview(firstOneLabel)
        firstOneLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: UIScreen.main.bounds.height/6, paddingLeft: 15, paddingRight: 15, height: 180)
    
        newGroupButton.layer.cornerRadius = 14
        self.insertSubview(newGroupButton, at: 4)
        newGroupButton.anchor(top: firstOneLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 30, paddingLeft: UIScreen.main.bounds.width/2-150, paddingRight: UIScreen.main.bounds.width/2-150, height: 50)
        
//        instaPicture.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height/3).isActive = true
//        instaPicture.layer.cornerRadius = 0
//        instaPicture.image =  #imageLiteral(resourceName: "story5")
//        instaPicture.backgroundColor = .white
//        instaPicture.contentMode = .scaleAspectFit
//        insertSubview(instaPicture, at: 10)
//        instaPicture.anchor(top: newGroupButton.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 15, paddingLeft: 10, paddingRight: 10)
        
    }
    
    @objc private func handleShowNewGroup() {
        guard let selectedSchool = selectedSchool else { return }
        self.delegate?.handleShowNewGroupForSchool(school: selectedSchool)
    }
}
