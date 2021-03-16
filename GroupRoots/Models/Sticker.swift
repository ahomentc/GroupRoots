//
//  Sticker.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/12/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import Foundation

struct Sticker: Codable {
    
    let id: String
    let imageUrl: String
    let userUploadedId: String
    let groupId: String
    
    init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.userUploadedId = dictionary["userUploaded"] as? String ?? ""
        self.groupId = dictionary["groupId"] as? String ?? ""
    }
}
