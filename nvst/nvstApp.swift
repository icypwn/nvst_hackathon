//
//  nvstApp.swift
//  nvst
//
//  Created by Ethan Harbinger on 3/7/26.
//

import SwiftUI
import UserNotifications
import ManagedSettings

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        if let encodedToken = userInfo["encodedToken"] as? String {
            // Store which token triggered the unlock request
            let sharedDefaults = UserDefaults(suiteName: "group.com.nvst.shared")
            sharedDefaults?.set(encodedToken, forKey: "lastBlockedToken")
        }

        // Open the time selection sheet
        NotificationCenter.default.post(name: .showTimeSelection, object: nil)
    }
}

@main
struct nvstApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
