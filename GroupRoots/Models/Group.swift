//
//  Group.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Foundation

struct Group {
    
    let groupId: String
    let groupname: String
    let groupProfileImageUrl: String?
    let bio: String
    let isPrivate: Bool?
    
    init(groupId: String, dictionary: [String: Any]) {
        self.groupId = groupId
        self.groupname = dictionary["groupname"] as? String ?? ""
        self.groupProfileImageUrl = dictionary["imageUrl"] as? String ?? nil
        self.bio = dictionary["bio"] as? String ?? ""
        let privateString = dictionary["private"] as? String ?? ""
        if privateString == "true" {
            self.isPrivate = true
        }
        else {
            self.isPrivate = false
        }
    }
}
