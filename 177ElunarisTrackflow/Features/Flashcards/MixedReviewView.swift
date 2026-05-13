//
//  MixedReviewView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct MixedReviewRootView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var sessionItems: [MixedReviewItem] = []
    @State private var showSession = false
    @State private var showNothingAlert = false

    private var stats: (due: Int, learning: Int, total: Int) {
        store.reviewQueueStats()
    }

    private var previewQueue: [MixedReviewItem] {
        store.mixedReviewQueue(limit: 6)
    }

    private var dueFraction: CGFloat {
        guard stats.total > 0 else { return 0 }
        return CGFloat(stats.due) / CGFloat(stats.total)
    }

    var body: some View {
        ZStack {
            LayeredAppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StudySectionHeader("Mixed review")

                    StudyCardContainer {
                        HStack(spacing: 14) {
                            ZStack {
                                StudyRingGauge(fraction: dueFraction, lineWidth: 6)
                                    .frame(width: 72, height: 72)
                                Text("\(Int(dueFraction * 100))%")
                                    .font(.caption2.weight(.bold).monospacedDigit())
                                    .foregroundStyle(Color.appTextPrimary)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Queue snapshot")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.appTextSecondary)
                                    .textCase(.uppercase)
                                HStack(spacing: 8) {
                                    StudyInfoChip(text: "\(stats.due) due", prominent: stats.due > 0)
                                    StudyInfoChip(text: "\(stats.learning) learning", prominent: false)
                                    StudyInfoChip(text: "\(stats.total) total", prominent: false)
                                }
                                Text("Start a session to work the top items in priority order.")
                                    .font(.caption)
                                    .foregroundStyle(Color.appTextSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(16)
                    }

                    StudyCardContainer {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                StudySymbolTile(systemName: "square.stack.3d.up.fill", size: 48)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Spaced session")
                                        .font(.headline)
                                        .foregroundStyle(Color.appTextPrimary)
                                    Text("Same SRS schedule as when you rate cards in a topic.")
                                        .font(.caption)
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                            }
                            Button {
                                beginSession()
                            } label: {
                                Text("Start session")
                                    .font(.headline)
                                    .foregroundStyle(Color.appBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(StudySurfaceStyle.primaryCTAFill)
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                .blendMode(.plusLighter)
                                        }
                                        .compositingGroup()
                                        .shadow(color: Color.appPrimary.opacity(0.26), radius: 8, x: 0, y: 4)
                                    }
                            }
                            .buttonStyle(.plain)
                            .disabled(store.topics.flatMap(\.cards).isEmpty)
                        }
                        .padding(16)
                    }

                    if !previewQueue.isEmpty {
                        StudySectionHeader("Next in queue")
                        LazyVStack(spacing: 10) {
                            ForEach(previewQueue) { item in
                                MixedReviewPreviewRow(item: item, bucket: store.mixedReviewBucketLabel(for: item.card.id))
                            }
                        }
                    }

                    if store.topics.flatMap(\.cards).isEmpty {
                        StudyCardContainer {
                            HStack(spacing: 12) {
                                StudySymbolTile(systemName: "tray", size: 44)
                                Text("Add flashcards first to build a mixed review queue.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                            .padding(16)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showSession) {
            NavigationStack {
                MixedReviewSessionView(items: sessionItems)
                    .environmentObject(store)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                Feedback.tap()
                                showSession = false
                            } label: {
                                Text("Close")
                            }
                        }
                    }
            }
        }
        .alert("Nothing to queue", isPresented: $showNothingAlert) {
            Button("OK", role: .cancel) { Feedback.tap() }
        } message: {
            Text("Create topics and cards—you will see them here sorted by urgency.")
        }
    }

    private func beginSession() {
        Feedback.mediumTap()
        sessionItems = store.mixedReviewQueue(limit: 60)
        guard !sessionItems.isEmpty else {
            showNothingAlert = true
            return
        }
        showSession = true
    }
}

private struct MixedReviewPreviewRow: View {
    let item: MixedReviewItem
    let bucket: String

    var body: some View {
        StudyCardContainer(cornerRadius: 14, elevation: .flat) {
            HStack(alignment: .top, spacing: 12) {
                StudySymbolTile(systemName: "doc.text", size: 44)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.topicTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        StudyInfoChip(text: bucket, prominent: bucket == "Due")
                    }
                    Text(item.card.prompt)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(2)
                }
            }
            .padding(12)
        }
    }
}

struct MixedReviewSessionView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let items: [MixedReviewItem]

    @State private var selection = 0
    @State private var showSeal = false

    var body: some View {
        ZStack {
            LayeredAppBackground()
            Group {
                if items.isEmpty {
                    Text("Nothing to review.")
                        .foregroundStyle(Color.appTextSecondary)
                        .onAppear { dismiss() }
                } else {
                    content
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(spacing: 14) {
            StudyCardContainer(cornerRadius: 14) {
                HStack {
                    Text(items[selection].topicTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Spacer()
                    StudyInfoChip(
                        text: "\(selection + 1)/\(items.count)",
                        prominent: false
                    )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)

            ZStack {
                TabView(selection: $selection) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        MixedReviewCardPage(card: item.card) { quality in
                            store.recordReviewQuality(for: item.card.id, quality: quality)
                            pulseSeal()
                            Feedback.mediumTap()
                        }
                        .tag(index)
                        .padding(.horizontal, 12)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(maxHeight: .infinity)

                if showSeal {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.appAccent.opacity(0.92))
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }

            StudyCardContainer(cornerRadius: 14) {
                Button {
                    Feedback.tap()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(Color.appBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appPrimary.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(10)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
    }

    private func pulseSeal() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            showSeal = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 950_000_000)
            withAnimation(.easeOut(duration: 0.22)) {
                showSeal = false
            }
        }
    }
}

private struct MixedReviewCardPage: View {
    let card: FlashCardModel
    let onQuality: (Int) -> Void

    var body: some View {
        ZStack {
            StudyElevatedPanelBackground(cornerRadius: 24)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(card.prompt)
                        .font(.title3.bold())
                        .foregroundStyle(Color.appTextPrimary)
                    Divider().background(Color.appTextSecondary.opacity(0.35))
                    if !card.tags.isEmpty {
                        FlowTagRow(tags: card.tags)
                    }
                    Text(card.answer)
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                    if let ex = card.exampleSentence, !ex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(ex)
                            .font(.footnote)
                            .foregroundStyle(Color.appTextSecondary.opacity(0.95))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.appPrimary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    speakRow
                    qualityRow
                }
                .padding(20)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    private var speakLine: String {
        let hint = card.pronunciationHint?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return hint.isEmpty ? card.answer : hint
    }

    private var speakRow: some View {
        Button {
            Feedback.tap()
            StudySpeech.speak(speakLine)
        } label: {
            Label("Speak", systemImage: "speaker.wave.2.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.appPrimary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var qualityRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How well did you recall this?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(0 ... 5, id: \.self) { value in
                    Button {
                        onQuality(value)
                    } label: {
                        Text("\(value)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.appBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.appPrimary.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Recall quality \(value)")
                }
            }
            Text("0 = complete blank · 5 = instant recall.")
                .font(.caption2)
                .foregroundStyle(Color.appTextSecondary)
        }
    }
}

private struct FlowTagRow: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tags")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.appAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.appPrimary.opacity(0.15)))
                    }
                }
            }
        }
    }
}
