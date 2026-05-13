//
//  QuickQuizView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct QuickQuizView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = QuickQuizViewModel()
    @State private var path = NavigationPath()
    @State private var quizMode: QuizSessionMode = .practice

    private var sessionGoal: Double { 10 }
    private var practiceProgress: CGFloat {
        CGFloat(min(1, Double(store.quizSessions.count) / sessionGoal))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LayeredAppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerCard
                        modeCard
                        if store.topics.isEmpty {
                            emptyNoTopics
                        } else {
                            topicPickerSection
                            pastSessions
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Quick Quiz")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: UUID.self) { topicId in
                if let topic = store.topic(for: topicId) {
                    quizSession(for: topic)
                } else {
                    Text("Topic unavailable.")
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func quizSession(for topic: FlashcardTopicModel) -> some View {
        QuizSessionFlowView(
            topic: topic,
            questions: viewModel.buildQuestions(from: topic),
            mode: quizMode,
            examDurationSeconds: quizMode == .exam ? QuickQuizViewModel.examSeconds(for: topic.cards.count) : nil
        )
        .environmentObject(store)
    }

    private var headerCard: some View {
        StudyCardContainer {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    StudyRingGauge(fraction: practiceProgress, lineWidth: 6)
                        .frame(width: 64, height: 64)
                    Text("\(min(store.quizSessions.count, Int(sessionGoal)))/\(Int(sessionGoal))")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.appTextPrimary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Practice goal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text("Complete quizzes to build a steady habit.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextPrimary)
                    ProgressView(value: Double(practiceProgress))
                        .tint(Color.appAccent)
                        .scaleEffect(x: 1, y: 1.35, anchor: .center)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
        }
    }

    private var modeCard: some View {
        StudyCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("Quiz style")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Picker("Mode", selection: $quizMode) {
                    Text("Practice").tag(QuizSessionMode.practice)
                    Text("Exam").tag(QuizSessionMode.exam)
                }
                .pickerStyle(.segmented)
                Text(
                    quizMode == .exam
                        ? "Timer, no hints, one question at a time. Score still counts partly if you ran out of time."
                        : "All question types, optional hints (−25% credit per hint on that item)."
                )
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
        }
    }

    private var emptyNoTopics: some View {
        StudyCardContainer {
            VStack(spacing: 16) {
                StudySymbolTile(systemName: "lightbulb.fill", size: 64)
                Text("Take your first quiz")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                Text("Create a topic with flashcards under Flashcards—quizzes unlock automatically.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
    }

    private var topicPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.quizSessions.isEmpty && store.activeQuiz == nil {
                StudyCardContainer {
                    VStack(spacing: 12) {
                        QuestionMarkIllustration()
                            .frame(height: 100)
                        Text("Sessions and scores will show up here after you finish a quiz.")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                }
            }

            StudySectionHeader("Choose a topic")

            LazyVStack(spacing: 12) {
                ForEach(store.topics) { topic in
                    Button {
                        Feedback.tap()
                        guard !topic.cards.isEmpty else {
                            Feedback.warning()
                            return
                        }
                        path.append(topic.id)
                    } label: {
                        QuizTopicRow(topic: topic)
                    }
                    .buttonStyle(.plain)
                    .environmentObject(store)
                }
            }
        }
    }

    private var pastSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            StudySectionHeader("Recent sessions")
            if store.quizSessions.isEmpty {
                StudyCardContainer {
                    Text("No completed sessions yet.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(store.quizSessions.prefix(8)) { session in
                        QuizSessionRow(session: session)
                    }
                }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Rows

private struct QuizTopicRow: View {
    @EnvironmentObject private var store: AppDataStore
    let topic: FlashcardTopicModel

    private var lastSession: QuizSessionRecord? {
        store.latestQuizSession(forTopicTitle: topic.title)
    }

    var body: some View {
        StudyCardContainer(elevation: .flat) {
            HStack(alignment: .top, spacing: 14) {
                StudySymbolTile(systemName: "rectangle.stack.fill", size: 52)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(topic.title)
                            .font(.headline)
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.appPrimary, Color.appSurface.opacity(0.45))
                    }

                    Text(topic.detail)
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        StudyInfoChip(
                            text: topic.cards.isEmpty ? "No cards" : "\(topic.cards.count) cards",
                            prominent: false
                        )
                        if let last = lastSession {
                            StudyInfoChip(text: "Last \(last.score)/\(last.totalQuestions)", prominent: true)
                        }
                    }
                }
            }
            .padding(16)
        }
        .opacity(topic.cards.isEmpty ? 0.55 : 1)
    }
}

private struct QuizSessionRow: View {
    let session: QuizSessionRecord

    private var fraction: CGFloat {
        guard session.totalQuestions > 0 else { return 0 }
        return CGFloat(session.score) / CGFloat(session.totalQuestions)
    }

    var body: some View {
        StudyCardContainer(elevation: .flat) {
            HStack(spacing: 14) {
                ZStack {
                    StudyRingGauge(fraction: fraction, lineWidth: 5)
                        .frame(width: 48, height: 48)
                    Text("\(Int(round(fraction * 100)))%")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.appTextPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.topic)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text(session.completedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                        if session.mode == .exam {
                            Text("Exam")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.appBackground)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background {
                                    Capsule()
                                        .fill(StudySurfaceStyle.accentCTAFill)
                                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5).blendMode(.plusLighter))
                                }
                        }
                        if let hints = session.hintsUsed, hints > 0 {
                            Text("\(hints) hints")
                                .font(.caption2)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }
                }

                Spacer(minLength: 8)

                StudyScoreBadge(correct: session.score, total: session.totalQuestions)
            }
            .padding(14)
        }
    }
}

private struct QuestionMarkIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appAccent.opacity(0.6), lineWidth: 6)
                .frame(width: 110, height: 110)
            Path { path in
                path.move(to: CGPoint(x: 70, y: 35))
                path.addQuadCurve(to: CGPoint(x: 95, y: 70), control: CGPoint(x: 95, y: 40))
                path.addQuadCurve(to: CGPoint(x: 70, y: 95), control: CGPoint(x: 95, y: 95))
            }
            .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 10, height: 10)
                .offset(x: 8, y: 32)
        }
    }
}

