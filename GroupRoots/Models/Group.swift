//
//  Group.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Foundation

struct Group: Codable {
    
    let groupId: String
    let groupname: String
    let groupProfileImageUrl: String?
    let bio: String
    let isPrivate: Bool?
    let lastPostedDate: Double
    
    init(groupId: String, dictionary: [String: Any]) {
        self.groupId = groupId
        self.groupname = dictionary["groupname"] as? String ?? ""
        self.groupProfileImageUrl = dictionary["groupProfileImageUrl"] as? String ?? nil
        self.bio = dictionary["bio"] as? String ?? ""
        self.lastPostedDate = dictionary["lastPostedDate"] as? Double ?? 1
        let privateString = dictionary["private"] as? String ?? ""
        if privateString == "true" {
            self.isPrivate = true
        }
        else {
            self.isPrivate = false
        }
    }
}
