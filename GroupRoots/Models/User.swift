//
//  User.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/30/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import Foundation

struct User: Equatable, Codable {
    
    let uid: String
    let username: String
    let name: String
    let bio: String
    let profileImageUrl: String?
    
    init(uid: String, dictionary: [String: Any]) {
        self.uid = uid
        self.username = dictionary["username"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        self.bio = dictionary["bio"] as? String ?? ""
        self.profileImageUrl = dictionary["profileImageUrl"] as? String ?? nil
    }
    
    static func ==(lhs: User, rhs: User) -> Bool {
        return lhs.uid == rhs.uid
    }
}
