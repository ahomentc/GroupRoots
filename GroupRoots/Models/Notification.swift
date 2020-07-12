//
//  Notification.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/25/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Foundation

/*
 
 User notifications:
  - newFollow
  
 Group notifications:
 - groupJoinRequest
 - newGroupJoin
 - groupJoinInvitation
 -* newGroupSubscribe
 -* newGroupSubscribeRequest
 -* groupProfileNameEdit
 -* groupPrivacyChange
 -* groupProfilePicEdit
 
 Group Post notifications:
 - groupPostComment
 - newGroupPost
 
 */

public enum NotificationType {
 /*      User */ case newFollow,
 /*     Group */ groupJoinRequest, newGroupJoin, groupJoinInvitation, newGroupSubscribe, groupSubscribeRequest, groupProfileNameEdit, groupProfilePicEdit, groupPrivacyChange, unsubscribeRequest,
 /* GroupPost */ groupPostComment, newGroupPost
}

struct Notification {
    
    var id: String

    let from: User
    let to: User
    let type: NotificationType
    let group: Group?
    let message: String?
    let groupPost: GroupPost?
    let creationDate: Date

    init(group: Group? = nil, groupPost: GroupPost? = nil, from: User? = nil, to: User, type: NotificationType, dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.from = from ?? User(uid: "", dictionary: ["" : ""])
        self.to = to
        self.type = type
        self.group = group
//        self.group = group ?? Group(groupId: "", dictionary: ["" : ""])
        self.groupPost = groupPost
//        self.groupPost = groupPost ?? GroupPost(group: Group(groupId: "", dictionary: ["" : ""]), user: User(uid: "", dictionary: ["" : ""]), dictionary: ["" : ""])
        self.message = dictionary["message"] as? String ?? ""

        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
    }
}

