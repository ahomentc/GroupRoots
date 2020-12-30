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
            let name = selectedSchool.replacingOccurrences(of: "_-a-_", with: " ").components(separatedBy: ",")[0]
            let name_lines = getLines(text: name, maxCharsInLine: 32)
            let name_string = convertLinesToString(lines: name_lines)
            self.schoolLabel.text = name_string
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
        schoolLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 15, paddingRight: 15, height: 60)

    }
    
    func getLines(text: String, maxCharsInLine: Int) -> [String] {
        let words = text.components(separatedBy: " ")
        var lines = [String]()
        
        var currentLine = ""
        
        for word in words {
            let numChars = (currentLine + word).count
            if numChars < maxCharsInLine {
                currentLine += " " + word
            }
            else {
                lines.append(currentLine)
                currentLine = word
            }
        }
        lines.append(currentLine)
        return lines
    }
    
    func convertLinesToString(lines: [String]) -> String {
        var text = ""
        for line in lines {
            text += line + "\n"
        }
        text.removeLast()
        return text
    }
}
