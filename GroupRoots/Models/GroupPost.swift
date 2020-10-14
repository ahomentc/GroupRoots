//
//  GroupPost.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Foundation

struct GroupPost: Equatable, Codable {
    
    var id: String
    
    let user: User
    let group: Group
    let imageUrl: String
    let videoUrl: String
    let caption: String
    let creationDate: Date
    let avgRed: Double
    let avgGreen: Double
    let avgBlue: Double
    let avgAlpha: Double
    let location: PostLocation?
    
    var likes: Int = 0
    var likedByCurrentUser = false
    
    init(group: Group, user: User?, dictionary: [String: Any]) {
        self.group = group
        self.user = user ?? User(uid: "", dictionary: ["" : ""])
        self.imageUrl = dictionary["imageUrl"] as? String ?? ""
        self.videoUrl = dictionary["videoUrl"] as? String ?? ""
        self.caption = dictionary["caption"] as? String ?? ""
        self.id = dictionary["id"] as? String ?? ""
        
        let secondsFrom1970 = dictionary["creationDate"] as? Double ?? 0
        self.creationDate = Date(timeIntervalSince1970: secondsFrom1970)
        
        self.avgRed = dictionary["avgRed"] as? Double ?? 0
        self.avgGreen = dictionary["avgGreen"] as? Double ?? 0
        self.avgBlue = dictionary["avgBlue"] as? Double ?? 0
        self.avgAlpha = dictionary["avgAlpha"] as? Double ?? 1

        let location_data_string = (dictionary["location"] as? String ?? "").fromBase64()
        let location_data = location_data_string?.data(using: .utf8)
        let decoder = JSONDecoder()
        do {
            if location_data != nil {
                self.location = try decoder.decode(PostLocation.self, from: location_data!)
            }
            else {
                self.location = nil
            }
        }
        catch {
            self.location = nil
        }
    }
    
    static func ==(lhs: GroupPost, rhs: GroupPost) -> Bool {
        return lhs.id == rhs.id
    }
    
}
