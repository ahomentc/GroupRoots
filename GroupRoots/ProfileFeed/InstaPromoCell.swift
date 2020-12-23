//
//  InstaPromoCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 12/23/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit

class InstaPromoCell: UICollectionViewCell {
    
    private let promoLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: "You're one of first people from your school!", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: "\nWe're giving $20 Amazon codes to the first 10 people who create or join a group and share it on their Instagram story!", attributes: [NSAttributedString.Key.foregroundColor: UIColor.init(white: 0.1, alpha: 1), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]))
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
        separatorViewTop.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingLeft: 10, paddingRight: 10, height: 0.5)
        
        addSubview(promoLabel)
        promoLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 15, paddingRight: 15)
        
        let separatorViewBottom = UIView()
        separatorViewBottom.backgroundColor = UIColor(white: 0, alpha: 0.2)
        addSubview(separatorViewBottom)
        separatorViewBottom.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 10, paddingRight: 10, height: 0.5)
        
        // underneath memberhsipLabel have a sort of button text label thing that says:
        // You're one of the first people in your school! We're giving $10 amazon codes for the first 10 people from school >
        
    }
}

