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
    
    private let schoolLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.text = "Your School"
        label.numberOfLines = 0
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    var selectedSchool: String? {
        didSet {
            guard let selectedSchool = selectedSchool else { return }
            self.schoolLabel.text = selectedSchool.replacingOccurrences(of: "_-a-_", with: " ").components(separatedBy: ",")[0]
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
        self.backgroundColor = .clear
        
        addSubview(schoolLabel)
        schoolLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 15, paddingRight: 15, height: 40)

//        let separatorView = UIView()
//        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.2)
//        addSubview(separatorView)
//        separatorView.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 10, paddingRight: 10, height: 0.5)
    }
}
