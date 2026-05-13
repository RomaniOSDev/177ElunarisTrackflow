//
//  ProgressTrackerView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct ProgressTrackerView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = ProgressTrackerViewModel()
    @State private var editMode: EditMode = .inactive
    @State private var path = NavigationPath()
    @State private var showClearBookmarksConfirm = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LayeredAppBackground()
                VStack(alignment: .leading, spacing: 14) {
                    if store.topics.isEmpty {
                        StudyCardContainer {
                            VStack(spacing: 14) {
                                StudySymbolTile(systemName: "books.vertical.fill", size: 56)
                                Text("No topics yet.")
                                    .font(.headline)
                                    .foregroundStyle(Color.appTextPrimary)
                                Text("Add flashcards first—your completion and bookmarks will show here.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.appTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }

                    StudyCardContainer(cornerRadius: 16) {
                        Picker("Section", selection: $viewModel.segment) {
                            ForEach(ProgressSegment.allCases) { segment in
                                Text(segment.title).tag(segment)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(12)
                    }
                    .padding(.horizontal, 16)

                    Group {
                        switch viewModel.segment {
                        case .overview:
                            overviewSection
                        case .weekly:
                            ScrollView {
                                weeklySection
                            }
                        case .bookmarks:
                            bookmarksSection
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(.bottom, 4)
            .navigationTitle("Progress Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        if viewModel.segment == .overview {
                            EditButton()
                                .foregroundStyle(Color.appPrimary)
                        }
                        Menu {
                            Button(role: .destructive) {
                                Feedback.tap()
                                showClearBookmarksConfirm = true
                            } label: {
                                Label("Clear Bookmarks", systemImage: "bookmark.slash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(Color.appPrimary)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .navigationDestination(for: UUID.self) { topicId in
                if let topic = store.topic(for: topicId) {
                    ProgressTopicDetailView(topic: topic)
                        .environmentObject(store)
                } else {
                    Text("Topic unavailable.")
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .confirmationDialog("Clear all bookmarks?", isPresented: $showClearBookmarksConfirm, titleVisibility: .visible) {
                Button("Clear", role: .destructive) {
                    Feedback.mediumTap()
                    store.clearAllBookmarks()
                }
                Button("Cancel", role: .cancel) {
                    Feedback.tap()
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var overviewSection: some View {
        Group {
            if store.topics.isEmpty {
                Color.clear.frame(height: 0)
            } else {
                List {
                    ForEach(store.topics) { topic in
                        NavigationLink(value: topic.id) {
                            ProgressOverviewRow(topic: topic)
                                .environmentObject(store)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button {
                                Feedback.tap()
                                store.toggleBookmark(topicId: topic.id)
                            } label: {
                                Label("Bookmark", systemImage: "bookmark")
                            }
                            .tint(Color.appAccent)
                        }
                    }
                    .onMove { indices, newOffset in
                        Feedback.tap()
                        store.reorderTopics(from: indices, to: newOffset)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 320)
            }
        }
    }

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if store.studyMinutesLastSevenDays().allSatisfy({ $0 == 0 }) {
                StudyCardContainer {
                    VStack(spacing: 12) {
                        ChartPlaceholderIllustration()
                            .frame(height: 120)
                        Text("Study a few minutes on any day this week to light up the chart.")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                }
            }
            StudyCardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    StudySectionHeader("Minutes (last 7 days)")
                    WeeklyBarsChart(values: store.studyMinutesLastSevenDays())
                        .frame(height: 200)
                        .padding(.vertical, 4)
                }
                .padding(16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var bookmarksSection: some View {
        let marked = store.topics.filter { store.bookmarkedItems.contains($0.id.uuidString) }
        return Group {
            if marked.isEmpty {
                StudyCardContainer {
                    VStack(spacing: 12) {
                        ListPlaceholderIllustration()
                            .frame(height: 100)
                        Text("Swipe a topic on the overview tab and tap Bookmark—or use the leading swipe where available.")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                }
                .padding(.horizontal, 16)
            } else {
                List {
                    ForEach(marked) { topic in
                        NavigationLink(value: topic.id) {
                            BookmarkRow(topic: topic)
                                .environmentObject(store)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 280)
            }
        }
    }
}

// MARK: - Rows

private struct ProgressOverviewRow: View {
    @EnvironmentObject private var store: AppDataStore
    let topic: FlashcardTopicModel

    private var topicKey: String { topic.id.uuidString }

    private var progress: CGFloat {
        CGFloat(store.topicsProgress[topicKey, default: 0])
    }

    private var isBookmarked: Bool {
        store.bookmarkedItems.contains(topicKey)
    }

    var body: some View {
        StudyCardContainer {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    StudyRingGauge(fraction: progress, lineWidth: 6)
                        .frame(width: 56, height: 56)
                    Text("\(Int(round(progress * 100)))%")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.appTextPrimary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(topic.title)
                            .font(.headline)
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        if isBookmarked {
                            Image(systemName: "bookmark.fill")
                                .font(.body)
                                .foregroundStyle(Color.appAccent)
                        }
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.appPrimary, Color.appSurface.opacity(0.45))
                    }
                    ProgressView(value: Double(progress))
                        .tint(Color.appAccent)
                    HStack(spacing: 8) {
                        StudyInfoChip(text: "\(topic.cards.count) cards", prominent: false)
                        StudyInfoChip(text: "Open for details", prominent: false)
                    }
                }
            }
            .padding(14)
        }
    }
}

private struct BookmarkRow: View {
    @EnvironmentObject private var store: AppDataStore
    let topic: FlashcardTopicModel

    private var topicKey: String { topic.id.uuidString }

    private var progress: CGFloat {
        CGFloat(store.topicsProgress[topicKey, default: 0])
    }

    var body: some View {
        StudyCardContainer {
            HStack(spacing: 14) {
                StudySymbolTile(systemName: "bookmark.fill", size: 48)
                VStack(alignment: .leading, spacing: 6) {
                    Text(topic.title)
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        StudyInfoChip(text: "\(Int(round(progress * 100)))% done", prominent: progress >= 1)
                        StudyInfoChip(text: "\(topic.cards.count) cards", prominent: false)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }
            .padding(14)
        }
    }
}

private struct WeeklyBarsChart: View {
    let values: [Int]

    var body: some View {
        GeometryReader { geo in
            let maxValue = max(values.max() ?? 0, 1)
            Canvas { context, size in
                let barWidth = (size.width - 32) / CGFloat(max(values.count, 1))
                for (idx, value) in values.enumerated() {
                    let height = CGFloat(value) / CGFloat(maxValue) * (size.height - 40)
                    let x = 16 + CGFloat(idx) * barWidth + barWidth * 0.2
                    let rect = CGRect(x: x, y: size.height - height - 24, width: barWidth * 0.6, height: height)
                    let path = Path(roundedRect: rect, cornerRadius: 6)
                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [Color.appAccent, Color.appPrimary.opacity(0.82)]),
                            startPoint: CGPoint(x: rect.midX, y: rect.maxY),
                            endPoint: CGPoint(x: rect.midX, y: rect.minY)
                        )
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct ChartPlaceholderIllustration: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 16, y: size.height - 24))
            for index in 0 ..< 6 {
                let x = 16 + CGFloat(index) * (size.width - 32) / 5
                let y = size.height - 24 - CGFloat((index * 17) % Int(size.height - 48))
                path.addLine(to: CGPoint(x: x, y: y))
            }
            context.stroke(path, with: .color(Color.appPrimary.opacity(0.5)), lineWidth: 3)
        }
    }
}

private struct ListPlaceholderIllustration: View {
    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0.92), Color.appSurface.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appPrimary.opacity(0.08), lineWidth: 1)
                )
                .frame(height: 14)
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0.78), Color.appSurface.opacity(0.58)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appPrimary.opacity(0.06), lineWidth: 1)
                )
                .frame(height: 14)
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0.62), Color.appSurface.opacity(0.42)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appPrimary.opacity(0.05), lineWidth: 1)
                )
                .frame(height: 14)
        }
        .padding(.horizontal, 24)
    }
}

struct ProgressTopicDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let topic: FlashcardTopicModel

    @State private var manualProgress: Double = 0

    private var topicKey: String { topic.id.uuidString }

    var body: some View {
        ZStack {
            LayeredAppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StudyCardContainer {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(topic.detail)
                                .font(.subheadline)
                                .foregroundStyle(Color.appTextSecondary)
                            HStack(spacing: 8) {
                                StudyInfoChip(text: "\(topic.cards.count) cards", prominent: false)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                    }

                    StudySectionHeader("Completion")
                    StudyCardContainer {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                ZStack {
                                    StudyRingGauge(fraction: CGFloat(manualProgress), lineWidth: 7)
                                        .frame(width: 72, height: 72)
                                    Text("\(Int(manualProgress * 100))%")
                                        .font(.caption.weight(.bold).monospacedDigit())
                                        .foregroundStyle(Color.appTextPrimary)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Drag the slider to match how much of this topic you have covered.")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                            }
                            Slider(value: $manualProgress, in: 0 ... 1, step: 0.05)
                                .tint(Color.appAccent)
                            Button {
                                Feedback.mediumTap()
                                store.setTopicProgress(topicKey: topicKey, value: Float(manualProgress))
                                Feedback.success()
                                Feedback.playSystemSound(1057)
                            } label: {
                                Text("Save progress")
                                    .font(.headline)
                                    .foregroundStyle(Color.appBackground)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.appPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(ProgressScaleButtonStyle())
                        }
                        .padding(16)
                    }
                }
                .padding(16)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            manualProgress = Double(store.topicsProgress[topicKey, default: 0])
        }
    }
}

private struct ProgressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
