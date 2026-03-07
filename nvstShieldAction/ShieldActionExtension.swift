//
//  ShieldActionExtension.swift
//  nvstShieldAction
//
//  Created by Ethan Harbinger on 3/7/26.
//

import ManagedSettings
import UserNotifications

class ShieldActionExtension: ShieldActionDelegate {

    let sharedDefaults = UserDefaults(suiteName: "group.com.nvst.shared")

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            if let encoded = try? JSONEncoder().encode(application) {
                let base64Token = encoded.base64EncodedString()
                sharedDefaults?.set(base64Token, forKey: "lastBlockedToken")
                sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "lastBlockedTimestamp")
                sharedDefaults?.set(true, forKey: "didTapUnlock")
            }
            sendNotification()
            completionHandler(.defer)

        case .secondaryButtonPressed:
            completionHandler(.defer)

        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.defer)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.defer)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.defer)
        }
    }

    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Ready to invest?"
        content.body = "Tap to choose your screen time and invest."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "com.nvst.requestTime",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
