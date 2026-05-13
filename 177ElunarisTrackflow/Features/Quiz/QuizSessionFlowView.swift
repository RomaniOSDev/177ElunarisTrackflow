//
//  QuizSessionFlowView.swift
//  177ElunarisTrackflow
//

import Combine
import SwiftUI

struct QuizSessionFlowView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let topic: FlashcardTopicModel
    let questions: [QuizQuestionModel]
    var mode: QuizSessionMode = .practice
    var examDurationSeconds: Int?

    @State private var index: Int = 0
    @State private var answers: [PerQuestionAnswer] = []
    @State private var showConfetti = false
    @State private var didFinish = false
    @State private var secondsLeft: Int = 0
    @State private var examEndsAt: Date?
    @State private var hiddenMCOptions: [Int: Set<Int>] = [:]
    @State private var textHintShown: Set<Int> = []
    @State private var tfHintRevealed: Set<Int> = []

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LayeredAppBackground()
            Group {
                if questions.isEmpty {
                    Text("Add more cards to start a quiz.")
                        .foregroundStyle(Color.appTextSecondary)
                        .padding()
                } else {
                    quizBody
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTitle(mode == .exam ? "Exam" : "Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: bootstrap)
        .onChange(of: index) { _ in
            syncMatchingShape()
            persist()
        }
        .onChange(of: answers) { _ in
            persist()
        }
        .onReceive(tick) { _ in
            guard mode == .exam, !didFinish, let end = examEndsAt else { return }
            secondsLeft = max(0, Int(end.timeIntervalSinceNow.rounded(.down)))
            if secondsLeft <= 0 {
                finishQuiz()
            }
        }
        .overlay(alignment: .top) {
            if showConfetti {
                ConfettiView()
                    .frame(maxHeight: .infinity)
                    .transition(.opacity)
            }
        }
    }

    private var quizBody: some View {
        VStack(spacing: 12) {
            if mode == .exam {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(Color.appAccent)
                    Text("\(secondsLeft)s left")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(secondsLeft <= 30 ? Color.red : Color.appTextPrimary)
                    Spacer()
                    Text("Question \(index + 1)/\(questions.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(.horizontal)

                ProgressView(value: Double(index + 1), total: Double(max(questions.count, 1)))
                    .tint(Color.appAccent)
                    .padding(.horizontal)
            } else {
                ProgressView(value: Double(index + 1), total: Double(max(questions.count, 1)))
                    .tint(Color.appAccent)
                    .padding(.horizontal)
            }

            Group {
                if mode == .exam {
                    questionBody(questions[index], position: index)
                        .padding(.horizontal, 8)
                } else {
                    TabView(selection: $index) {
                        ForEach(Array(questions.enumerated()), id: \.element.id) { position, question in
                            questionBody(question, position: position)
                                .tag(position)
                                .padding(.horizontal, 12)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                }
            }
            .frame(maxHeight: .infinity)

            if mode == .practice {
                hintRow
                    .padding(.horizontal, 12)
            }

            submitButton
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
    }

    private var hintRow: some View {
        Button {
            Feedback.tap()
            applyHint(at: index)
        } label: {
            Text("Hint (−25% of this question if correct)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(StudySurfaceStyle.accentCTAFill)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        .blendMode(.plusLighter)
                )
        }
        .buttonStyle(.plain)
        .disabled(didFinish)
    }

    @ViewBuilder
    private func questionBody(_ question: QuizQuestionModel, position: Int) -> some View {
        ScrollView {
            StudyCardContainer(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    kindBadge(question.kind)
                    Text(question.prompt)
                        .font(.title3.bold())
                        .foregroundStyle(Color.appTextPrimary)

                    switch question.kind {
                    case .multipleChoice:
                        multipleChoiceBlock(question, position: position)
                    case .textEntry:
                        textEntryBlock(question, position: position)
                    case .trueFalse:
                        trueFalseBlock(question, position: position)
                    case .matching:
                        matchingBlock(question, position: position)
                    }
                }
                .padding(16)
            }
            .padding(.vertical, 4)
        }
    }

    private func kindBadge(_ kind: QuizQuestionKind) -> some View {
        Text(kind.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.appAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.28), Color.appPrimary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                Capsule()
                    .stroke(Color.appAccent.opacity(0.25), lineWidth: 1)
            )
    }

    private func multipleChoiceBlock(_ question: QuizQuestionModel, position: Int) -> some View {
        let hidden = hiddenMCOptions[position, default: []]
        return VStack(spacing: 10) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { choiceIndex, choice in
                if !hidden.contains(choiceIndex) {
                    choiceButton(choice, choiceIndex: choiceIndex, position: position, isSelected: answers[position].mcIndex == choiceIndex)
                }
            }
        }
    }

    private func choiceButton(_ title: String, choiceIndex: Int, position: Int, isSelected: Bool) -> some View {
        Button {
            Feedback.tap()
            guard answers.indices.contains(position) else { return }
            answers[position].mcIndex = choiceIndex
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.appAccent)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? StudySurfaceStyle.quizRowSelectedWell : StudySurfaceStyle.quizRowNeutralWell)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? Color.appAccent.opacity(0.55) : Color.appPrimary.opacity(0.22),
                        lineWidth: isSelected ? 1.25 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func textEntryBlock(_ question: QuizQuestionModel, position: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Your answer", text: bindingText(position))
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(Color.appTextPrimary)
                .autocorrectionDisabled()
            if textHintShown.contains(position), let first = question.acceptableTextAnswers.first, let ch = first.first {
                Text("Starts with: “\(String(ch))…”")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }

    private func trueFalseBlock(_ question: QuizQuestionModel, position: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let statement = question.trueFalseStatement {
                Text(statement)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)
            }
            if let expected = question.trueFalseCorrect {
                HStack(spacing: 12) {
                    tfAnswerButton(title: "True", value: 1, position: position, expected: expected, revealed: tfHintRevealed.contains(position))
                    tfAnswerButton(title: "False", value: 0, position: position, expected: expected, revealed: tfHintRevealed.contains(position))
                }
            }
        }
    }

    private func tfAnswerButton(title: String, value: Int, position: Int, expected: Bool, revealed: Bool) -> some View {
        let pickedTrue = value == 1
        let isCorrectSide = pickedTrue == expected
        let selected = answers.indices.contains(position) && answers[position].tfSelected == value
        let glow = revealed && isCorrectSide
        return Button {
            Feedback.tap()
            guard answers.indices.contains(position) else { return }
            answers[position].tfSelected = value
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selected ? StudySurfaceStyle.quizRowSelectedWell : StudySurfaceStyle.quizRowNeutralWell)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(glow ? Color.appAccent : Color.appPrimary.opacity(0.2), lineWidth: glow ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func matchingBlock(_ question: QuizQuestionModel, position: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(question.matchingRows.enumerated()), id: \.offset) { rowIndex, row in
                VStack(alignment: .leading, spacing: 6) {
                    Text(row.promptFragment)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Picker("Match", selection: bindingMatch(position, rowIndex, count: question.matchingRightOptions.count)) {
                        Text("Select…").tag(-1)
                        ForEach(Array(question.matchingRightOptions.enumerated()), id: \.offset) { idx, opt in
                            Text(opt).tag(idx)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.appPrimary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(StudySurfaceStyle.embeddedWell)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.appPrimary.opacity(0.18), lineWidth: 1)
                )
            }
        }
    }

    private func bindingText(_ position: Int) -> Binding<String> {
        Binding(
            get: {
                guard answers.indices.contains(position) else { return "" }
                return answers[position].typedText
            },
            set: { newValue in
                guard answers.indices.contains(position) else { return }
                answers[position].typedText = newValue
            }
        )
    }

    private func bindingMatch(_ position: Int, _ rowIndex: Int, count: Int) -> Binding<Int> {
        Binding(
            get: {
                guard answers.indices.contains(position),
                      rowIndex < answers[position].matchingPicks.count else { return -1 }
                return answers[position].matchingPicks[rowIndex]
            },
            set: { newValue in
                guard answers.indices.contains(position),
                      rowIndex < answers[position].matchingPicks.count else { return }
                answers[position].matchingPicks[rowIndex] = newValue
            }
        )
    }

    private var submitButton: some View {
        let ready = currentAnswerReady
        return Button {
            handleSubmit()
        } label: {
            Text(mode == .exam && index >= questions.count - 1 ? "Finish" : "Submit")
                .font(.headline)
                .foregroundStyle(ready ? Color.appBackground : Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background {
                    let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
                    ZStack {
                        shape.fill(ready ? StudySurfaceStyle.primaryCTAFill : StudySurfaceStyle.mutedCTAFill)
                        shape.stroke(Color.white.opacity(ready ? 0.22 : 0.06), lineWidth: 1)
                            .blendMode(.plusLighter)
                    }
                }
                .compositingGroup()
                .shadow(color: Color.black.opacity(ready ? 0.22 : 0), radius: ready ? 8 : 0, x: 0, y: ready ? 4 : 0)
        }
        .disabled(!ready || didFinish)
        .buttonStyle(QuizSessionScaleButtonStyle())
    }

    private var currentAnswerReady: Bool {
        guard questions.indices.contains(index), answers.indices.contains(index) else { return false }
        let q = questions[index]
        let a = answers[index]
        switch q.kind {
        case .multipleChoice:
            return a.mcIndex >= 0
        case .textEntry:
            return !a.typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .trueFalse:
            return a.tfSelected >= 0
        case .matching:
            guard q.matchingRows.count == a.matchingPicks.count else { return false }
            return a.matchingPicks.allSatisfy { $0 >= 0 }
        }
    }

    private func bootstrap() {
        if answers.count != questions.count {
            answers = (0 ..< questions.count).map { _ in PerQuestionAnswer() }
        }
        syncMatchingShape()
        restoreIfNeeded()
        if mode == .exam {
            let total = examDurationSeconds ?? QuickQuizViewModel.examSeconds(for: questions.count)
            if examEndsAt == nil {
                examEndsAt = Date().addingTimeInterval(TimeInterval(total))
                secondsLeft = total
            } else if let end = examEndsAt {
                secondsLeft = max(0, Int(end.timeIntervalSinceNow.rounded(.down)))
            }
        }
    }

    private func syncMatchingShape() {
        guard answers.count == questions.count else { return }
        for idx in questions.indices where questions[idx].kind == .matching {
            let n = questions[idx].matchingRows.count
            if answers[idx].matchingPicks.count != n {
                answers[idx].matchingPicks = Array(repeating: -1, count: n)
            }
        }
    }

    private func applyHint(at position: Int) {
        guard mode == .practice, questions.indices.contains(position), answers.indices.contains(position) else { return }
        let q = questions[position]
        answers[position].hintsUsed += 1
        switch q.kind {
        case .multipleChoice:
            var hidden = hiddenMCOptions[position, default: []]
            if let strike = q.choices.enumerated().first(where: { $0.offset != q.correctIndex && !hidden.contains($0.offset) })?.offset {
                hidden.insert(strike)
                hiddenMCOptions[position] = hidden
            }
        case .textEntry:
            textHintShown.insert(position)
        case .trueFalse:
            tfHintRevealed.insert(position)
        case .matching:
            if let rowIx = answers[position].matchingPicks.enumerated().first(where: { $0.element < 0 })?.offset
                ?? answers[position].matchingPicks.indices.first {
                let correct = q.matchingRows[rowIx].correctIndexInRight
                answers[position].matchingPicks[rowIx] = correct
            }
        }
    }

    private func handleSubmit() {
        guard questions.indices.contains(index) else { return }
        if index < questions.count - 1 {
            Feedback.mediumTap()
            Feedback.playSystemSound(1003)
            withAnimation(.easeInOut(duration: 0.3)) {
                index += 1
                if mode == .exam {
                    persist()
                }
            }
        } else {
            finishQuiz()
        }
    }

    private func finishQuiz() {
        guard !didFinish else { return }
        didFinish = true
        let result = QuizGrading.sessionPoints(questions: questions, answers: answers)
        let session = QuizSessionRecord(
            id: UUID(),
            topic: topic.title,
            completedAt: Date(),
            score: result.scoreRounded,
            totalQuestions: questions.count,
            mode: mode,
            hintsUsed: result.hintsUsed
        )
        store.appendQuizSession(session)
        Feedback.mediumTap()
        Feedback.playSystemSound(1105)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
            showConfetti = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation {
                showConfetti = false
            }
            dismiss()
        }
    }

    private func persist() {
        guard !didFinish else { return }
        let state = ActiveQuizState(
            topicId: topic.id,
            topicTitle: topic.title,
            questions: questions,
            currentQuestionIndex: index,
            answers: answers,
            mode: mode,
            examEndsAt: examEndsAt
        )
        store.persistActiveQuiz(state)
    }

    private func restoreIfNeeded() {
        guard let active = store.activeQuiz,
              active.topicId == topic.id,
              active.questions.count == questions.count,
              active.questions.map(\.id) == questions.map(\.id) else { return }
        if active.answers.count == questions.count {
            answers = active.answers
        } else {
            answers = (0 ..< questions.count).map { idx in
                idx < active.answers.count ? active.answers[idx] : PerQuestionAnswer()
            }
        }
        syncMatchingShape()
        index = min(max(active.currentQuestionIndex, 0), max(questions.count - 1, 0))
        examEndsAt = active.examEndsAt
    }
}

extension QuizQuestionKind {
    var label: String {
        switch self {
        case .multipleChoice: return "Multiple choice"
        case .textEntry: return "Type answer"
        case .trueFalse: return "True / False"
        case .matching: return "Matching"
        }
    }
}

private struct QuizSessionScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
