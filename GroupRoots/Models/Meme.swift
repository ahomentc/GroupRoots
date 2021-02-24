//
//  Meme.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/23/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import Foundation

struct Meme: Codable {
    
    let name: String
    let url: String
    let width: Int
    let height: Int
    let box_count: Int
    
    init(dictionary: [String: Any]) {
        self.name = dictionary["name"] as? String ?? ""
        self.url = dictionary["url"] as? String ?? ""
        self.width = dictionary["width"] as? Int ?? 0
        self.height = dictionary["height"] as? Int ?? 0
        self.box_count = dictionary["url"] as? Int ?? 0
    }
}
