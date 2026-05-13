//
//  StatsAchievementsView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct StatsAchievementsView: View {
    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredAppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        summaryCard
                        StudySectionHeader("Achievements")
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(AchievementCatalog.all) { achievement in
                                achievementCell(achievement)
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var summaryCard: some View {
        StudyCardContainer {
            VStack(alignment: .leading, spacing: 14) {
                StudySectionHeader("Summary")
                LazyVGrid(columns: columns, spacing: 12) {
                    SummaryTile(
                        title: "Items reviewed",
                        value: "\(store.cardsReviewed)",
                        systemName: "rectangle.on.rectangle.angled"
                    )
                    SummaryTile(
                        title: "Sessions",
                        value: "\(store.totalSessionsCompleted)",
                        systemName: "checkmark.circle.fill"
                    )
                    SummaryTile(
                        title: "Minutes",
                        value: "\(store.totalMinutesUsed)",
                        systemName: "clock.fill"
                    )
                    SummaryTile(
                        title: "Streak",
                        value: "\(store.streakDays)d",
                        systemName: "flame.fill"
                    )
                }
            }
            .padding(16)
        }
    }

    private func achievementCell(_ achievement: AchievementCatalog.Item) -> some View {
        let unlocked = achievement.isUnlocked(
            cardsReviewed: store.cardsReviewed,
            quizzesCompleted: store.quizzesCompleted,
            studyMinutes: store.totalMinutesUsed,
            streakDays: store.streakDays
        )
        return StudyCardContainer(cornerRadius: 16, elevation: .flat) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                unlocked
                                    ? LinearGradient(
                                        colors: [Color.appPrimary.opacity(0.46), Color.appPrimary.opacity(0.18)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.appSurface.opacity(0.58), Color.appSurface.opacity(0.38)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.appPrimary.opacity(unlocked ? 0.42 : 0.12), lineWidth: 1)
                            )
                        Image(systemName: achievement.systemImage)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(unlocked ? Color.appAccent : Color.appTextSecondary)
                    }
                    Spacer(minLength: 8)
                    if unlocked {
                        StudyInfoChip(text: "Unlocked", prominent: true)
                    }
                }
                Text(achievement.title)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                Text(achievement.detail)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(4)
            }
            .padding(14)
        }
        .opacity(unlocked ? 1 : 0.55)
    }
}

// MARK: - Summary tile

private struct SummaryTile: View {
    let title: String
    let value: String
    let systemName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemName)
                .font(.title3)
                .foregroundStyle(Color.appPrimary)
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.appAccent)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(StudySurfaceStyle.summaryInsetWell)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appAccent.opacity(0.22), lineWidth: 1)
        )
    }
}
