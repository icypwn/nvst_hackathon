//
//  DeviceActivityMonitorExtension.swift
//  nvstMonitor
//
//  Created by Ethan Harbinger on 3/7/26.
//

import DeviceActivity
import ManagedSettings
import Foundation
import os

extension DeviceActivityName {
    static let reblock = DeviceActivityName("com.nvst.reblock")
}

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    let store = ManagedSettingsStore()
    let logger = Logger(subsystem: "com.nvst.monitor", category: "monitor")
    let sharedDefaults = UserDefaults(suiteName: "group.com.nvst.shared")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        logger.log("intervalDidStart for \(activity.rawValue)")

        if activity == .reblock {
            reapplyShields()
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logger.log("intervalDidEnd for \(activity.rawValue)")

        if activity == .reblock {
            reapplyShields()
        }
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
    }

    private func reapplyShields() {
        guard let hasSelectedApps = sharedDefaults?.bool(forKey: "hasSelectedApps"),
              hasSelectedApps else {
            logger.log("No selected apps flag - skipping reblock")
            store.shield.applications = nil
            return
        }

        guard let tokenStrings = sharedDefaults?.stringArray(forKey: "savedBlockedTokens"),
              !tokenStrings.isEmpty else {
            logger.log("No saved tokens found")
            store.shield.applications = nil
            return
        }

        var tokensToBlock = Set<ApplicationToken>()

        for base64String in tokenStrings {
            if let data = Data(base64Encoded: base64String),
               let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
                tokensToBlock.insert(token)
            }
        }

        if tokensToBlock.isEmpty {
            store.shield.applications = nil
            logger.log("Decoded 0 tokens - clearing shields")
        } else {
            store.shield.applications = tokensToBlock
            logger.log("Re-blocked \(tokensToBlock.count) apps")
        }
    }
}
