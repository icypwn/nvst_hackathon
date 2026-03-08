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
    @Published var isUnlocked = false

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
        // 1. Unblock only the specific app that triggered the unlock
        isUnlocked = true
        sharedDefaults?.set(true, forKey: "isUnlocked")

        var currentTokens = loadTokensFromAppGroup()
        if currentTokens.isEmpty {
            currentTokens = selection.applicationTokens
        }

        if let encodedToken = sharedDefaults?.string(forKey: "lastBlockedToken"),
           let data = Data(base64Encoded: encodedToken),
           let token = try? JSONDecoder().decode(ApplicationToken.self, from: data) {
            currentTokens.remove(token)
        } else {
            // If we don't know which app requested unlock, temporarily unblock all.
            currentTokens.removeAll()
        }

        if currentTokens.isEmpty {
            store.shield.applications = nil
        } else {
            store.shield.applications = currentTokens
        }
        saveTokensToAppGroup(currentTokens)

        // 2. Stop any existing monitoring
        center.stopMonitoring([.reblock])

        // Schedule isUnlocked reset and reblock after the timer
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(minutes * 60)) { [weak self] in
            self?.isUnlocked = false
            self?.sharedDefaults?.set(false, forKey: "isUnlocked")
            self?.applyShield()
        }

        // 3. Schedule a 15-minute reblock interval starting X minutes from now
        let reblockTime = Calendar.current.date(byAdding: .minute, value: minutes, to: Date())!
        let safetyTime = Calendar.current.date(byAdding: .minute, value: 15, to: reblockTime)!

        let schedule = DeviceActivitySchedule(
            intervalStart: Calendar.current.dateComponents([.hour, .minute, .second], from: reblockTime),
            intervalEnd: Calendar.current.dateComponents([.hour, .minute, .second], from: safetyTime),
            repeats: false
        )

        do {
            try center.startMonitoring(.reblock, during: schedule)
        } catch {
            print("Failed to schedule reblock: \(error)")
            applyShield()
        }
    }

    // MARK: - Unlock Request Detection

    /// Check if the shield action set the didTapUnlock flag and show time selection
    func checkForUnlockRequest() -> Bool {
        guard let sharedDefaults = sharedDefaults,
              sharedDefaults.bool(forKey: "didTapUnlock") else { return false }
        sharedDefaults.set(false, forKey: "didTapUnlock")
        return true
    }

    // MARK: - Token Persistence (base64-encoded JSON)

    private func saveTokensToAppGroup(_ tokens: Set<ApplicationToken>) {
        let encoded: [String] = tokens.compactMap { token in
            guard let data = try? JSONEncoder().encode(token) else { return nil }
            return data.base64EncodedString()
        }
        sharedDefaults?.set(encoded, forKey: "savedBlockedTokens")
    }

    private func loadTokensFromAppGroup() -> Set<ApplicationToken> {
        guard let encoded = sharedDefaults?.array(forKey: "savedBlockedTokens") as? [String] else {
            return []
        }
        let decoded = encoded.compactMap { base64 -> ApplicationToken? in
            guard let data = Data(base64Encoded: base64) else { return nil }
            return try? JSONDecoder().decode(ApplicationToken.self, from: data)
        }
        return Set(decoded)
    }
}
