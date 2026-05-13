//
//  FlashcardTopicDetailView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct FlashcardTopicDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let topicId: UUID

    @State private var selection: Int = 0
    @State private var showKnownCelebration = false
    @State private var editingCard: FlashCardModel?

    private var topicBinding: FlashcardTopicModel? {
        store.topic(for: topicId)
    }

    var body: some View {
        ZStack {
            LayeredAppBackground()
            Group {
                if let topic = topicBinding {
                    content(for: topic)
                } else {
                    Text("Topic unavailable.")
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(topicBinding?.title ?? "Topic")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingCard) { card in
            if let topic = topicBinding {
                EditCardSheet(topicId: topic.id, card: card)
                    .environmentObject(store)
            }
        }
    }

    @ViewBuilder
    private func content(for topic: FlashcardTopicModel) -> some View {
        VStack(spacing: 16) {
            ZStack {
                TabView(selection: $selection) {
                    ForEach(Array(topic.cards.enumerated()), id: \.element.id) { index, card in
                        TopicFlashcardPageView(
                            card: card,
                            onEdit: {
                                Feedback.tap()
                                editingCard = card
                            },
                            onQuality: { quality in
                                Feedback.mediumTap()
                                store.recordReviewQuality(for: card.id, quality: quality)
                                if quality >= 4 {
                                    Feedback.playSystemSound(1103)
                                } else {
                                    Feedback.playSystemSound(1003)
                                }
                                if quality >= 4 {
                                    triggerKnownCelebration()
                                }
                            }
                        )
                        .tag(index)
                        .padding(.horizontal, 12)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(maxHeight: .infinity)

                if showKnownCelebration {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.appAccent)
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }

            Button {
                Feedback.tap()
                appendCard(topic: topic)
            } label: {
                Label("Add Card", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(Color.appBackground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(DetailScaleButtonStyle())
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private func triggerKnownCelebration() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            showKnownCelebration = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation(.easeOut(duration: 0.25)) {
                showKnownCelebration = false
            }
        }
    }

    private func appendCard(topic: FlashcardTopicModel) {
        store.addCard(to: topic.id, prompt: "New prompt", answer: "New answer")
        if let updated = store.topic(for: topic.id) {
            selection = max(0, updated.cards.count - 1)
        }
        Feedback.success()
        Feedback.playSystemSound(1057)
    }
}

private struct TopicFlashcardPageView: View {
    let card: FlashCardModel
    let onEdit: () -> Void
    let onQuality: (Int) -> Void

    var body: some View {
        ZStack {
            StudyElevatedPanelBackground(cornerRadius: 24)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Spacer(minLength: 0)
                        Button(action: onEdit) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.appPrimary, Color.appSurface.opacity(0.35))
                        }
                        .accessibilityLabel("Edit card")
                    }
                    Text(card.prompt)
                        .font(.title3.bold())
                        .foregroundStyle(Color.appTextPrimary)
                    Divider().background(Color.appTextSecondary.opacity(0.4))
                    if !card.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(card.tags, id: \.self) { tag in
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
                    if let hint = card.pronunciationHint, !hint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(hint)
                            .font(.footnote.italic())
                            .foregroundStyle(Color.appTextSecondary)
                    }

                    Button {
                        Feedback.tap()
                        StudySpeech.speak(speakTarget)
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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recall quality")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(0 ... 5, id: \.self) { q in
                                Button {
                                    onQuality(q)
                                } label: {
                                    Text("\(q)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.appBackground)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.appPrimary.opacity(0.92))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Quality \(q)")
                            }
                        }
                        Text("Feeds the spaced repetition schedule.")
                            .font(.caption2)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    private var speakTarget: String {
        let trimmed = card.pronunciationHint?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? card.answer : trimmed
    }
}

struct EditCardSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let topicId: UUID
    let card: FlashCardModel

    @State private var prompt: String = ""
    @State private var answer: String = ""
    @State private var example: String = ""
    @State private var pronunciation: String = ""
    @State private var tagsLine: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredAppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        StudySectionHeader("Card content")
                        StudyCardContainer {
                            VStack(spacing: 14) {
                                StudyLabeledTextField(title: "Front text", text: $prompt)
                                StudyLabeledTextField(title: "Back text", text: $answer)
                                StudyLabeledTextField(
                                    title: "Example (optional)",
                                    text: $example,
                                    axis: .vertical,
                                    lineLimitRange: 2 ... 4
                                )
                                StudyLabeledTextField(
                                    title: "Pronunciation / reading (optional)",
                                    text: $pronunciation
                                )
                                StudyLabeledTextField(
                                    title: "Tags (optional)",
                                    prompt: "Comma-separated",
                                    text: $tagsLine
                                )
                            }
                            .padding(14)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Edit card")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                prompt = card.prompt
                answer = card.answer
                example = card.exampleSentence ?? ""
                pronunciation = card.pronunciationHint ?? ""
                tagsLine = card.tags.joined(separator: ", ")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        Feedback.tap()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let p = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !p.isEmpty, !a.isEmpty else {
            Feedback.warning()
            return
        }
        guard var topic = store.topic(for: topicId),
              let idx = topic.cards.firstIndex(where: { $0.id == card.id }) else {
            Feedback.warning()
            return
        }
        let exTrim = example.trimmingCharacters(in: .whitespacesAndNewlines)
        let pronTrim = pronunciation.trimmingCharacters(in: .whitespacesAndNewlines)
        topic.cards[idx] = FlashCardModel(
            id: card.id,
            prompt: p,
            answer: a,
            exampleSentence: exTrim.isEmpty ? nil : exTrim,
            pronunciationHint: pronTrim.isEmpty ? nil : pronTrim,
            tags: StudyText.tagsFromCommaList(tagsLine)
        )
        Feedback.mediumTap()
        store.updateTopic(topic)
        Feedback.success()
        dismiss()
    }
}

private struct DetailScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
