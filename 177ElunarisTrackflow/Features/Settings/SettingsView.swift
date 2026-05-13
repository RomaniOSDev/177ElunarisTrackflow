//
//  SettingsView.swift
//  177ElunarisTrackflow
//

import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetConfirm = false

    private var versionString: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }

    private var totalEntries: Int {
        store.topics.reduce(0) { partial, topic in
            partial + topic.cards.count
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredAppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        StudySectionHeader("Your stats")
                        StudyCardContainer {
                            VStack(spacing: 0) {
                                SettingsMetricRow(title: "Total entries created", value: "\(totalEntries)")
                                Divider().opacity(0.25)
                                SettingsMetricRow(title: "Total minutes used", value: "\(store.totalMinutesUsed)")
                                Divider().opacity(0.25)
                                SettingsMetricRow(title: "Current streak", value: "\(store.streakDays) days")
                                Divider().opacity(0.25)
                                SettingsMetricRow(title: "Sessions completed", value: "\(store.totalSessionsCompleted)")
                            }
                            .padding(.vertical, 6)
                        }

                        StudySectionHeader("Support")
                        StudyCardContainer {
                            VStack(spacing: 0) {
                                SettingsNavigationRow(
                                    title: "Rate Us",
                                    systemName: "star.fill",
                                    action: {
                                        rateApp()
                                    }
                                )
                                Divider().opacity(0.25)
                                SettingsNavigationRow(
                                    title: "Privacy Policy",
                                    systemName: "hand.raised.fill",
                                    action: {
                                        openExternalURL(.privacyPolicy)
                                    }
                                )
                                Divider().opacity(0.25)
                                SettingsNavigationRow(
                                    title: "Terms",
                                    systemName: "doc.text.fill",
                                    action: {
                                        openExternalURL(.termsOfUse)
                                    }
                                )
                                Divider().opacity(0.25)
                                SettingsNavigationRow(
                                    title: "Contact support",
                                    systemName: "envelope.fill",
                                    tintChevron: false,
                                    action: {
                                        Feedback.tap()
                                        openSupportEmail()
                                    }
                                )
                            }
                            .padding(.vertical, 4)
                        }

                        StudySectionHeader("Data")
                        StudyCardContainer {
                            Button(role: .destructive) {
                                Feedback.tap()
                                showResetConfirm = true
                            } label: {
                                HStack {
                                    StudySymbolTile(systemName: "trash.fill", size: 44)
                                    Text("Reset all data")
                                        .font(.headline)
                                        .foregroundStyle(Color.red)
                                    Spacer()
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(Color.appAccent)
                                }
                                .padding(14)
                            }
                            .buttonStyle(.plain)
                        }

                        Text("Version \(versionString)")
                            .font(.footnote)
                            .foregroundStyle(Color.appTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset all data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {
                    Feedback.tap()
                }
                Button("Reset", role: .destructive) {
                    Feedback.mediumTap()
                    store.resetAllData()
                    Feedback.success()
                    Feedback.playSystemSound(1057)
                }
            } message: {
                Text("This removes your topics, quizzes, progress, and achievements from this device.")
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func openSupportEmail() {
        guard let url = URL(string: "mailto:support@example.com") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func openExternalURL(_ link: AppExternalLink) {
        Feedback.tap()
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        Feedback.tap()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

private struct SettingsMetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.appAccent)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct SettingsNavigationRow: View {
    let title: String
    let systemName: String
    var tintChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                StudySymbolTile(systemName: systemName, size: 44)
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tintChevron ? Color.appTextSecondary : Color.appPrimary)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
