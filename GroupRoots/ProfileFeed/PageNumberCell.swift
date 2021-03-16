//
//  PageNumberCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/14/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit

class PageNumberCell: UICollectionViewCell {
    
    var number: Int? {
        didSet {
            guard let number = number else { return }
            numberLabel.text = String(number)
        }
    }
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .center
        label.textColor = UIColor.init(white: 0.4, alpha: 1)
        return label
    }()
    
    static var cellId = "PageNumberCellId"
    
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
        self.number = nil
        self.numberLabel.text = ""
    }
    
    private func sharedInit() {

        addSubview(numberLabel)
        numberLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor)
    }
}
