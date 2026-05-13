//
//  AddTopicSheet.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct AddTopicSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var detail = ""
    @State private var prompt = ""
    @State private var answer = ""
    @State private var example = ""
    @State private var pronunciation = ""
    @State private var tagsLine = ""
    @State private var shakeAmount: CGFloat = 0
    @State private var helperText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredAppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        StudySectionHeader("Topic")
                        StudyCardContainer {
                            VStack(spacing: 14) {
                                StudyLabeledTextField(title: "Title", prompt: "Name this topic", text: $title)
                                StudyLabeledTextField(
                                    title: "Description",
                                    prompt: "Optional summary",
                                    text: $detail,
                                    axis: .vertical,
                                    lineLimitRange: 2 ... 4
                                )
                            }
                            .padding(14)
                        }

                        StudySectionHeader("First card")
                        StudyCardContainer {
                            VStack(spacing: 14) {
                                StudyLabeledTextField(title: "Front text", prompt: "Question or term", text: $prompt)
                                StudyLabeledTextField(title: "Back text", prompt: "Answer or definition", text: $answer)
                                StudyLabeledTextField(
                                    title: "Example (optional)",
                                    prompt: "Use in a sentence",
                                    text: $example,
                                    axis: .vertical,
                                    lineLimitRange: 2 ... 4
                                )
                                StudyLabeledTextField(
                                    title: "Pronunciation / reading (optional)",
                                    prompt: "Phonetic hint for Speak",
                                    text: $pronunciation
                                )
                                StudyLabeledTextField(
                                    title: "Tags (optional)",
                                    prompt: "Comma-separated, e.g. verb, exam",
                                    text: $tagsLine
                                )
                            }
                            .padding(14)
                        }

                        if let helperText {
                            StudyCardContainer(cornerRadius: 14) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(Color.red.opacity(0.9))
                                    Text(helperText)
                                        .font(.footnote)
                                        .foregroundStyle(Color.red.opacity(0.9))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .navigationTitle("New Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Feedback.tap()
                        dismiss()
                    } label: {
                        Text("Close")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Text("Save")
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedPrompt.isEmpty, !trimmedAnswer.isEmpty else {
            Feedback.warning()
            helperText = "Please fill in title, front, and back text."
            withAnimation(.default) {
                shakeAmount += 1
            }
            return
        }

        Feedback.mediumTap()
        Feedback.success()
        Feedback.playSystemSound(1057)
        let ex = example.trimmingCharacters(in: .whitespacesAndNewlines)
        let pron = pronunciation.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addTopic(
            title: trimmedTitle,
            detail: trimmedDetail,
            initialPrompt: trimmedPrompt,
            initialAnswer: trimmedAnswer,
            exampleSentence: ex.isEmpty ? nil : ex,
            pronunciationHint: pron.isEmpty ? nil : pron,
            tags: StudyText.tagsFromCommaList(tagsLine)
        )
        dismiss()
    }
}
