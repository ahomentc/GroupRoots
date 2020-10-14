//
//  PostLocation.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 10/13/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Foundation

struct PostLocation: Codable {
    
    let name: String
    let longitude: String
    let latitude: String
    let address: String
    
    init(name: String?, longitude: String?, latitude: String?, address: String? = nil) {
        self.name = name ?? ""
        self.longitude = longitude ?? ""
        self.latitude = latitude ?? ""
        self.address = address ?? ""
    }
}

