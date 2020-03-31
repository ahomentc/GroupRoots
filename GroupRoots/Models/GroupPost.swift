//
//  GroupPost.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Foundation

struct GroupPost: Equatable {
    
    var id: String
    
    let user: User
    let group: Group
    let imageUrl: String
    let caption: String
    let creationDate: Date
    
    var likes: Int = 0
    var likedByCurrentUser = false
    
    init(group: Group, user: User?, dictionary: [String: Any]) {
        self.group = group
        self.user = user ?? User(uid: "", dictionary: ["" : ""])
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.caption = dictionary["caption"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
    }
    
    static func ==(lhs: GroupPost, rhs: GroupPost) -> Bool {
        return lhs.id == rhs.id
    }
}
