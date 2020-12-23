//
//  SchoolLabelCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 12/21/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit

class SchoolLabelCell: UICollectionViewCell {
    
    private let membershipsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.text = "Your School's Groups"
        label.numberOfLines = 0
        label.textColor = .black
        label.textAlignment = .center
//        label.backgroundColor = .blue
        return label
    }()
    
    private lazy var newGroupButton: UIButton = {
        let button = UIButton()
//        button.addTarget(self, action: #selector(handleShowNewGroup), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Create a Group", for: .normal)
        return button
    }()
    
    var selectedSchool: String? {
        didSet {
            guard let selectedSchool = selectedSchool else { return }
            self.membershipsLabel.text = selectedSchool + " Groups"
        }
    }
    
    static var cellId = "schoolLabelCellId"
    
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
        
        addSubview(membershipsLabel)
        membershipsLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 15, paddingRight: 15, height: 60)
        
        newGroupButton.layer.cornerRadius = 14
        self.insertSubview(newGroupButton, at: 4)
        newGroupButton.anchor(top: membershipsLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 10, paddingLeft: UIScreen.main.bounds.width/2-150, paddingRight: UIScreen.main.bounds.width/2-150, height: 50)

//        let separatorView = UIView()
//        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.2)
//        addSubview(separatorView)
//        separatorView.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 10, paddingRight: 10, height: 0.5)
    }
}
