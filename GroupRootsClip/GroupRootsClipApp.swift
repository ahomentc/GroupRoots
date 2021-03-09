//
//  GroupRootsClipApp.swift
//  GroupRootsClip
//
//  Created by Andrei Homentcovschi on 3/6/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import SwiftUI

@main
struct GroupRootsClipApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
