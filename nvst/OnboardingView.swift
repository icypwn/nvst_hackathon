//
//  OnboardingView.swift
//  nvst
//
//  Created by Ethan Harbinger on 3/7/26.
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @ObservedObject var manager: ScreenTimeManager
    @Environment(\.dismiss) private var dismiss
    @State private var isRequesting = false
    @State private var showError = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                // Drag indicator
                Capsule()
                    .fill(Color(white: 0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                Spacer()

                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.green)

                VStack(spacing: 10) {
                    HStack(spacing: 0) {
                        Text("Time")
                            .foregroundColor(.white)
                        Text("Invest")
                            .foregroundColor(.green)
                    }
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                    Text("Invest your screen time into\nthe companies you use most.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 20) {
                    // Permission explanation
                    VStack(spacing: 12) {
                        permissionRow(
                            icon: "clock.badge.checkmark",
                            title: "Screen Time Access",
                            detail: "See which apps you use and for how long"
                        )
                        permissionRow(
                            icon: "bell.badge",
                            title: "Notifications",
                            detail: "Get alerts when it's time to invest"
                        )
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.1))
                    )

                    Text("We'll ask you to approve Screen Time\naccess in the next step.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Button {
                        authorize()
                    } label: {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "lock.shield")
                                Text("Approve Screen Time Access")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Capsule().fill(.green))
                    }
                    .disabled(isRequesting)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
        }
        .alert("Permission Denied", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text("Screen Time access is required. Please enable it in Settings > Screen Time.")
        }
    }

    private func permissionRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }

    private func authorize() {
        isRequesting = true
        Task {
            do {
                try await manager.requestAuthorization()
                try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run { showError = true }
            }
            await MainActor.run { isRequesting = false }
        }
    }
}
