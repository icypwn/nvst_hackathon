//
//  ScreenTimeManager.swift
//  nvst
//
//  Created by Ethan Harbinger on 3/7/26.
//

import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

// MARK: - Constants

let appGroupID = "group.com.nvst.shared"

extension DeviceActivityName {
    static let reblock = DeviceActivityName("com.nvst.reblock")
}

// MARK: - Manager

class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private let sharedDefaults = UserDefaults(suiteName: appGroupID)

    @Published var selection = FamilyActivitySelection() {
        didSet { applyShield() }
    }
    @Published var isAuthorized = false

    private init() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        await MainActor.run { isAuthorized = true }
    }

    // MARK: - Blocking

    func applyShield() {
        let tokens = selection.applicationTokens

        if tokens.isEmpty {
            // IMPORTANT: nil = no apps blocked, empty set = ALL apps blocked
            store.shield.applications = nil
            sharedDefaults?.set(false, forKey: "hasSelectedApps")
        } else {
            store.shield.applications = tokens
            sharedDefaults?.set(true, forKey: "hasSelectedApps")
        }

        // Persist tokens as base64-encoded JSON for extensions to read
        saveTokensToAppGroup(tokens)
    }

    func removeAllShields() {
        store.shield.applications = nil
        sharedDefaults?.set(false, forKey: "hasSelectedApps")
    }

    // MARK: - Scheduling

    func unlockAndScheduleReblock(minutes: Int) {
        // 1. Unblock immediately
        store.shield.applications = nil

        // 2. Stop any existing monitoring
        center.stopMonitoring([.reblock])

        // 3. Schedule reblock after X minutes
        let reblockTime = Calendar.current.date(byAdding: .minute, value: minutes, to: Date())!
        let safetyTime = Calendar.current.date(byAdding: .minute, value: minutes + 1, to: reblockTime)!

        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: reblockTime),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: safetyTime),
            repeats: false
        )

        do {
            try center.startMonitoring(.reblock, during: schedule)
        } catch {
            print("Failed to schedule reblock: \(error)")
            // Safety: re-block immediately if scheduling fails
            applyShield()
        }
    }

    // MARK: - Token Persistence (base64-encoded JSON)

    private func saveTokensToAppGroup(_ tokens: Set<ApplicationToken>) {
        let encoded: [String] = tokens.compactMap { token in
            guard let data = try? JSONEncoder().encode(token) else { return nil }
            return data.base64EncodedString()
        }
        sharedDefaults?.set(encoded, forKey: "savedBlockedTokens")
    }
}
