//
//  HomeView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppDataStore
    @Binding var selectedTab: RootTab

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var dateLine: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    private var totalCards: Int {
        store.topics.reduce(0) { $0 + $1.cards.count }
    }

    private var reviewStats: (due: Int, learning: Int, total: Int) {
        store.reviewQueueStats()
    }

    private var lastSevenDaysBuckets: [Int] {
        store.studyMinutesLastSevenDays()
    }

    /// Last 7 days — sum for a simple weekly goal ring.
    private var minutesLastSevenDays: Int {
        lastSevenDaysBuckets.reduce(0, +)
    }

    private var weeklyGoalMinutes: Int { 120 }

    private var weeklyProgress: CGFloat {
        guard weeklyGoalMinutes > 0 else { return 0 }
        return CGFloat(min(1, Double(minutesLastSevenDays) / Double(weeklyGoalMinutes)))
    }

    private let stickerSymbols = [
        "brain.head.profile", "books.vertical.fill", "graduationcap.fill", "leaf.fill",
        "flame.fill", "star.fill", "wand.and.stars", "lightbulb.fill",
        "character.bubble.fill", "chart.line.uptrend.xyaxis", "clock.fill", "trophy.fill",
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredAppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        heroCard

                        if let active = store.activeQuiz {
                            resumeQuizCard(active)
                        }

                        StudySectionHeader("At a glance")

                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            statPill(
                                title: "Topics",
                                value: "\(store.topics.count)",
                                caption: "collections",
                                icon: "folder.fill"
                            )
                            statPill(
                                title: "Cards",
                                value: "\(totalCards)",
                                caption: "in your library",
                                icon: "rectangle.stack.fill"
                            )
                            statPill(
                                title: "Due",
                                value: "\(reviewStats.due)",
                                caption: "\(reviewStats.learning) learning",
                                icon: "bell.badge.fill"
                            )
                            statPill(
                                title: "Streak",
                                value: "\(store.streakDays)d",
                                caption: "daily practice",
                                icon: "flame.fill"
                            )
                        }

                        weeklyActivityWidget

                        StudySectionHeader("Shortcuts")
                        shortcutsGrid

                        if let last = store.quizSessions.first {
                            StudySectionHeader("Last session")
                            lastSessionCard(last)
                        }

                        StudySectionHeader("Toolkit")
                        stickerStrip

                        StudySectionHeader("Study tip")
                        tipCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var heroCard: some View {
        StudyCardContainer(cornerRadius: 24) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(greeting)
                        .font(.title2.bold())
                        .foregroundStyle(Color.appTextPrimary)
                    Text(dateLine)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                    Text("Warm up with flashcards, tighten recall in a quiz, or clear your review queue.")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HomeHeroCluster()
                    .frame(width: 132, height: 128)
                    .accessibilityHidden(true)
            }
            .padding(18)
        }
    }

    private func resumeQuizCard(_ active: ActiveQuizState) -> some View {
        StudyCardContainer(cornerRadius: 20) {
            Button {
                Feedback.tap()
                withAnimation(.easeInOut(duration: 0.22)) {
                    selectedTab = .learn
                }
            } label: {
                HStack(spacing: 14) {
                    StudySymbolTile(systemName: "play.circle.fill", size: 54)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Resume quiz")
                            .font(.headline)
                            .foregroundStyle(Color.appTextPrimary)
                        Text(active.topicTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appPrimary)
                        Text(quizProgressLine(active))
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
        }
    }

    private func modeLabel(_ mode: QuizSessionMode) -> String {
        switch mode {
        case .practice: return "Practice"
        case .exam: return "Exam"
        }
    }

    private func quizProgressLine(_ active: ActiveQuizState) -> String {
        let q = max(active.questions.count, 1)
        let idx = min(active.currentQuestionIndex + 1, q)
        return "Question \(idx) of \(q) · \(modeLabel(active.mode))"
    }

    private func statPill(title: String, value: String, caption: String, icon: String) -> some View {
        StudyCardContainer(cornerRadius: 18, elevation: .flat) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text(value)
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(Color.appTextPrimary)
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(Color.appTextSecondary.opacity(0.9))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }

    private var weeklyMinuteBars: some View {
        let buckets = lastSevenDaysBuckets
        let maxM = max(buckets.max() ?? 1, 1)
        return HStack(spacing: 4) {
            ForEach(Array(buckets.enumerated()), id: \.offset) { _, minutes in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.85), Color.appAccent.opacity(0.65)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 10, height: max(4, 4 + CGFloat(minutes) / CGFloat(maxM) * 28))
            }
        }
    }

    private var weeklyActivityWidget: some View {
        StudyCardContainer(cornerRadius: 20) {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    StudyRingGauge(fraction: weeklyProgress, lineWidth: 8)
                        .frame(width: 72, height: 72)
                    Text("\(minutesLastSevenDays)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.appTextPrimary)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Last 7 days")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("You logged \(minutesLastSevenDays) study minutes. Goal: \(weeklyGoalMinutes) min/week.")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    weeklyMinuteBars
                        .frame(height: 36, alignment: .bottom)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
    }

    private var shortcutsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            shortcutTile(
                title: "Flashcards",
                subtitle: "Browse decks",
                icon: "rectangle.stack.fill",
                tab: .flashcards
            )
            shortcutTile(
                title: "Learn",
                subtitle: "Quiz & review",
                icon: "bolt.horizontal.circle.fill",
                tab: .learn
            )
            shortcutTile(
                title: "Stats",
                subtitle: "Progress & badges",
                icon: "chart.bar.fill",
                tab: .stats
            )
            shortcutTile(
                title: "Settings",
                subtitle: "Preferences",
                icon: "gearshape.fill",
                tab: .settings
            )
        }
    }

    private func shortcutTile(title: String, subtitle: String, icon: String, tab: RootTab) -> some View {
        Button {
            Feedback.tap()
            withAnimation(.easeInOut(duration: 0.22)) {
                selectedTab = tab
            }
        } label: {
            StudyCardContainer(cornerRadius: 18, elevation: .flat) {
                HStack(spacing: 12) {
                    StudySymbolTile(systemName: icon, size: 46)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func lastSessionCard(_ session: QuizSessionRecord) -> some View {
        StudyCardContainer(cornerRadius: 18) {
            Button {
                Feedback.tap()
                withAnimation(.easeInOut(duration: 0.22)) {
                    selectedTab = .stats
                }
            } label: {
                HStack(spacing: 14) {
                    StudySymbolTile(systemName: "clock.arrow.circlepath", size: 48)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.topic)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(2)
                        Text(
                            "\(session.score)/\(session.totalQuestions) pts · \(relativeDate(session.completedAt))"
                        )
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(14)
            }
            .buttonStyle(.plain)
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var stickerStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(stickerSymbols, id: \.self) { name in
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.14))
                            .frame(width: 58, height: 58)
                            .overlay(
                                Circle()
                                    .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
                            )
                        Image(systemName: name)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.appPrimary, Color.appAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var tipCard: some View {
        StudyCardContainer(cornerRadius: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.appPrimary.opacity(0.22))
                    )
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grade honestly")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Use mixed review and the 0–5 scale on cards so due dates match how well you really know each item.")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
    }
}

// MARK: - Decorative hero cluster (SF Symbols only — rich visuals without bitmap assets)

private struct HomeHeroCluster: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appAccent.opacity(0.52), Color.appAccent.opacity(0.06), Color.clear],
                        center: .center,
                        startRadius: 2,
                        endRadius: 48
                    )
                )
                .frame(width: 84, height: 84)
                .offset(x: 38, y: -28)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appPrimary.opacity(0.5), Color.appPrimary.opacity(0.06), Color.clear],
                        center: .center,
                        startRadius: 2,
                        endRadius: 40
                    )
                )
                .frame(width: 72, height: 72)
                .offset(x: -42, y: 36)

            Image(systemName: "book.pages.fill")
                .font(.system(size: 52, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.95), Color.appAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolRenderingMode(.hierarchical)
                .offset(x: -8, y: 6)

            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .offset(x: 54, y: -42)

            Image(systemName: "bookmark.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.appPrimary.opacity(0.9))
                .offset(x: 44, y: 34)

            Image(systemName: "calendar")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary.opacity(0.55))
                .offset(x: -52, y: -36)
        }
        .allowsHitTesting(false)
    }
}
