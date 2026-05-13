//
//  QuickQuizViewModel.swift
//  177ElunarisTrackflow
//

import Combine
import Foundation

final class QuickQuizViewModel: ObservableObject {
    static func examSeconds(for questionCount: Int) -> Int {
        max(120, questionCount * 45)
    }

    func buildQuestions(from topic: FlashcardTopicModel) -> [QuizQuestionModel] {
        topic.cards.map { QuickQuizQuestionBuilder.question(for: $0, topic: topic) }
    }
}

private enum QuickQuizQuestionBuilder {
    static func question(for card: FlashCardModel, topic: FlashcardTopicModel) -> QuizQuestionModel {
        switch kind(for: card.id) {
        case .multipleChoice:
            return multipleChoice(card: card, topic: topic)
        case .textEntry:
            return textEntry(card: card)
        case .trueFalse:
            return trueFalse(card: card, topic: topic)
        case .matching:
            return matching(card: card, topic: topic)
        }
    }

    private static func kind(for cardId: UUID) -> QuizQuestionKind {
        var hasher = Hasher()
        hasher.combine(cardId.uuidString)
        let value = abs(hasher.finalize()) % 100
        if value < 38 { return .multipleChoice }
        if value < 58 { return .textEntry }
        if value < 78 { return .trueFalse }
        return .matching
    }

    private static func multipleChoice(card: FlashCardModel, topic: FlashcardTopicModel) -> QuizQuestionModel {
        var choices: [String] = [card.answer]
        choices.append(contentsOf: topic.cards.filter { $0.id != card.id }.map(\.answer))
        let fillers = ["Needs follow-up", "Review again", "Not now", "Come back later"]
        for filler in fillers where choices.count < 4 {
            if !choices.contains(filler) {
                choices.append(filler)
            }
        }
        while choices.count < 4 {
            choices.append("Option \(choices.count + 1)")
        }
        let trimmed = Array(choices.prefix(4))
        let shuffled = trimmed.shuffled()
        let correctIndex = shuffled.firstIndex(of: card.answer) ?? 0
        return QuizQuestionModel(
            id: UUID(),
            kind: .multipleChoice,
            prompt: card.prompt,
            choices: shuffled,
            correctIndex: correctIndex
        )
    }

    private static func textEntry(card: FlashCardModel) -> QuizQuestionModel {
        var acceptable: [String] = []
        let normalized = StudyText.normalize(card.answer)
        if !normalized.isEmpty {
            acceptable.append(normalized)
        }
        let lowerTrim = card.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !lowerTrim.isEmpty, !acceptable.contains(lowerTrim) {
            acceptable.append(lowerTrim)
        }
        if acceptable.isEmpty {
            acceptable.append("answer")
        }
        return QuizQuestionModel(
            id: UUID(),
            kind: .textEntry,
            prompt: card.prompt,
            acceptableTextAnswers: acceptable
        )
    }

    private static func trueFalse(card: FlashCardModel, topic: FlashcardTopicModel) -> QuizQuestionModel {
        var hasher = Hasher()
        hasher.combine(card.id.uuidString)
        hasher.combine("tf")
        let truthful = abs(hasher.finalize()) % 2 == 0
        if truthful {
            return QuizQuestionModel(
                id: UUID(),
                kind: .trueFalse,
                prompt: card.prompt,
                trueFalseStatement: "The answer is: \(card.answer).",
                trueFalseCorrect: true
            )
        } else {
            let wrongAnswer = topic.cards.filter { $0.id != card.id }.map(\.answer).randomElement() ?? "(none)"
            return QuizQuestionModel(
                id: UUID(),
                kind: .trueFalse,
                prompt: card.prompt,
                trueFalseStatement: "The answer is: \(wrongAnswer).",
                trueFalseCorrect: false
            )
        }
    }

    private static func matching(card: FlashCardModel, topic: FlashcardTopicModel) -> QuizQuestionModel {
        let others = topic.cards.filter { $0.id != card.id }.shuffled()
        let extra = Array(others.prefix(2))
        let group = [card] + extra
        guard group.count >= 2 else {
            return multipleChoice(card: card, topic: topic)
        }
        let rightOptions = group.map(\.answer).shuffled()
        let rows: [QuizMatchRow] = group.map { rowCard in
            let idx = rightOptions.firstIndex(of: rowCard.answer) ?? 0
            return QuizMatchRow(promptFragment: rowCard.prompt, correctIndexInRight: idx)
        }
        return QuizQuestionModel(
            id: UUID(),
            kind: .matching,
            prompt: "Match each prompt to the correct answer.",
            matchingRows: rows,
            matchingRightOptions: rightOptions
        )
    }
}
