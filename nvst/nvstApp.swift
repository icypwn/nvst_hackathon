//
//  nvstApp.swift
//  nvst
//
//  Created by Ethan Harbinger on 3/7/26.
//

import SwiftUI

@main
struct nvstApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
