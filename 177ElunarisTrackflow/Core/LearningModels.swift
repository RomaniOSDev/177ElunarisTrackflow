//
//  LearningModels.swift
//  177ElunarisTrackflow
//

import Foundation

// MARK: - Flashcards

struct FlashCardModel: Codable, Identifiable, Hashable {
    var id: UUID
    var prompt: String
    var answer: String
    /// Optional example sentence (shown on back).
    var exampleSentence: String?
    /// Optional phonetic or reading hint; also used for Speak.
    var pronunciationHint: String?
    /// Simple tags (e.g. "verb", "exam").
    var tags: [String]

    init(
        id: UUID = UUID(),
        prompt: String,
        answer: String,
        exampleSentence: String? = nil,
        pronunciationHint: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.prompt = prompt
        self.answer = answer
        self.exampleSentence = exampleSentence
        self.pronunciationHint = pronunciationHint
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case id, prompt, answer, exampleSentence, pronunciationHint, tags
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        prompt = try c.decode(String.self, forKey: .prompt)
        answer = try c.decode(String.self, forKey: .answer)
        exampleSentence = try c.decodeIfPresent(String.self, forKey: .exampleSentence)
        pronunciationHint = try c.decodeIfPresent(String.self, forKey: .pronunciationHint)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

struct FlashcardTopicModel: Codable, Identifiable, Hashable {
    var id: UUID
    var title: String
    var detail: String
    var cards: [FlashCardModel]
}

// MARK: - SRS (local)

struct CardSRSState: Codable, Hashable {
    /// Current interval in days (minimum fraction for “due soon”).
    var intervalDays: Double
    var nextReviewAt: Date
    var ease: Double

    static func newCard() -> CardSRSState {
        CardSRSState(intervalDays: 0, nextReviewAt: Date.distantPast, ease: 2.5)
    }
}

enum FlashcardStatus: String, Codable {
    case known
    case learning
}

// MARK: - Quiz

enum QuizSessionMode: String, Codable {
    case practice
    case exam
}

enum QuizQuestionKind: String, Codable {
    case multipleChoice
    case textEntry
    case trueFalse
    case matching
}

/// One row in a matching exercise: pick the answer index from `rightOptions`.
struct QuizMatchRow: Codable, Hashable {
    var promptFragment: String
    var correctIndexInRight: Int
}

struct QuizQuestionModel: Codable, Identifiable, Hashable {
    var id: UUID
    var kind: QuizQuestionKind
    /// Main prompt (front text, stem, etc.).
    var prompt: String
    /// Multiple choice: shuffled options.
    var choices: [String]
    var correctIndex: Int
    /// Text entry: normalized acceptable forms (lowercased, trimmed).
    var acceptableTextAnswers: [String]
    /// True/false: displayed statement; user picks true/false.
    var trueFalseStatement: String?
    var trueFalseCorrect: Bool?
    /// Matching: fixed left labels; `rightOptions` is shuffled; each row maps to index in `rightOptions`.
    var matchingRows: [QuizMatchRow]
    var matchingRightOptions: [String]

    init(
        id: UUID = UUID(),
        kind: QuizQuestionKind,
        prompt: String,
        choices: [String] = [],
        correctIndex: Int = 0,
        acceptableTextAnswers: [String] = [],
        trueFalseStatement: String? = nil,
        trueFalseCorrect: Bool? = nil,
        matchingRows: [QuizMatchRow] = [],
        matchingRightOptions: [String] = []
    ) {
        self.id = id
        self.kind = kind
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.acceptableTextAnswers = acceptableTextAnswers
        self.trueFalseStatement = trueFalseStatement
        self.trueFalseCorrect = trueFalseCorrect
        self.matchingRows = matchingRows
        self.matchingRightOptions = matchingRightOptions
    }

    enum CodingKeys: String, CodingKey {
        case id, kind, prompt, choices, correctIndex
        case acceptableTextAnswers, trueFalseStatement, trueFalseCorrect
        case matchingRows, matchingRightOptions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        kind = try c.decodeIfPresent(QuizQuestionKind.self, forKey: .kind) ?? .multipleChoice
        prompt = try c.decode(String.self, forKey: .prompt)
        choices = try c.decodeIfPresent([String].self, forKey: .choices) ?? []
        correctIndex = try c.decodeIfPresent(Int.self, forKey: .correctIndex) ?? 0
        acceptableTextAnswers = try c.decodeIfPresent([String].self, forKey: .acceptableTextAnswers) ?? []
        trueFalseStatement = try c.decodeIfPresent(String.self, forKey: .trueFalseStatement)
        trueFalseCorrect = try c.decodeIfPresent(Bool.self, forKey: .trueFalseCorrect)
        matchingRows = try c.decodeIfPresent([QuizMatchRow].self, forKey: .matchingRows) ?? []
        matchingRightOptions = try c.decodeIfPresent([String].self, forKey: .matchingRightOptions) ?? []
    }
}

struct PerQuestionAnswer: Codable, Equatable {
    var mcIndex: Int = -1
    var typedText: String = ""
    /// 0 = False, 1 = True, -1 = unset.
    var tfSelected: Int = -1
    /// Selected index in `matchingRightOptions` for each `matchingRows` element.
    var matchingPicks: [Int] = []
    var hintsUsed: Int = 0
}

struct ActiveQuizState: Codable, Equatable {
    var topicId: UUID
    var topicTitle: String
    var questions: [QuizQuestionModel]
    var currentQuestionIndex: Int
    var answers: [PerQuestionAnswer]
    var mode: QuizSessionMode
    var examEndsAt: Date?
}

struct QuizSessionRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var topic: String
    var completedAt: Date
    /// Whole points credited (after hint penalties).
    var score: Int
    var totalQuestions: Int
    var mode: QuizSessionMode?
    /// Number of hints used across the session.
    var hintsUsed: Int?

    enum CodingKeys: String, CodingKey {
        case id, topic, completedAt, score, totalQuestions, mode, hintsUsed
    }

    init(
        id: UUID = UUID(),
        topic: String,
        completedAt: Date,
        score: Int,
        totalQuestions: Int,
        mode: QuizSessionMode? = nil,
        hintsUsed: Int? = nil
    ) {
        self.id = id
        self.topic = topic
        self.completedAt = completedAt
        self.score = score
        self.totalQuestions = totalQuestions
        self.mode = mode
        self.hintsUsed = hintsUsed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        topic = try c.decode(String.self, forKey: .topic)
        completedAt = try c.decode(Date.self, forKey: .completedAt)
        score = try c.decode(Int.self, forKey: .score)
        totalQuestions = try c.decode(Int.self, forKey: .totalQuestions)
        mode = try c.decodeIfPresent(QuizSessionMode.self, forKey: .mode)
        hintsUsed = try c.decodeIfPresent(Int.self, forKey: .hintsUsed)
    }
}

// MARK: - Text helpers (quiz typing)

enum StudyText {
    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale.current)
    }

    static func textAnswerMatches(user raw: String, acceptable: [String]) -> Bool {
        let trimmed = normalize(raw)
        guard !trimmed.isEmpty else { return false }
        for cand in acceptable {
            let n = normalize(cand)
            if trimmed == n { return true }
            if n.count >= 6, trimmed.count >= Int(Double(n.count) * 0.65), trimmed.count <= Int(Double(n.count) * 1.35) {
                let dist = levenshtein(trimmed, n)
                let maxLen = max(trimmed.count, n.count)
                if maxLen > 0, Double(dist) / Double(maxLen) <= 0.22 { return true }
            }
        }
        return false
    }

    /// Small strings only (study answers).
    private static func levenshtein(_ a: Substring, _ b: Substring) -> Int {
        let aa = Array(a)
        let bb = Array(b)
        guard !aa.isEmpty, !bb.isEmpty else { return max(aa.count, bb.count) }
        var row = Array(0 ... bb.count)
        for i in 1 ... aa.count {
            var prev = row[0]
            row[0] = i
            for j in 1 ... bb.count {
                let temp = row[j]
                let cost = aa[i - 1] == bb[j - 1] ? 0 : 1
                row[j] = min(row[j - 1] + 1, row[j] + 1, prev + cost)
                prev = temp
            }
        }
        return row[bb.count]
    }

    private static func levenshtein(_ a: String, _ b: String) -> Int {
        levenshtein(a[...], b[...])
    }

    /// Comma-separated tags from a single input field.
    static func tagsFromCommaList(_ raw: String) -> [String] {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Mixed review

struct MixedReviewItem: Identifiable, Hashable {
    var topicId: UUID
    var topicTitle: String
    var card: FlashCardModel

    var id: UUID { card.id }
}

// MARK: - Quiz grading

enum QuizGrading {
    static func isCorrect(question: QuizQuestionModel, answer: PerQuestionAnswer) -> Bool {
        switch question.kind {
        case .multipleChoice:
            return answer.mcIndex >= 0 && answer.mcIndex == question.correctIndex
        case .textEntry:
            return StudyText.textAnswerMatches(user: answer.typedText, acceptable: question.acceptableTextAnswers)
        case .trueFalse:
            guard let expected = question.trueFalseCorrect else { return false }
            guard answer.tfSelected >= 0 else { return false }
            return (answer.tfSelected == 1) == expected
        case .matching:
            guard question.matchingRows.count == answer.matchingPicks.count else { return false }
            guard answer.matchingPicks.allSatisfy({ $0 >= 0 }) else { return false }
            for i in question.matchingRows.indices where answer.matchingPicks[i] != question.matchingRows[i].correctIndexInRight {
                return false
            }
            return true
        }
    }

    static func sessionPoints(questions: [QuizQuestionModel], answers: [PerQuestionAnswer]) -> (scoreRounded: Int, hintsUsed: Int) {
        var earned = 0.0
        var hints = 0
        for idx in questions.indices {
            guard idx < answers.count else { continue }
            let q = questions[idx]
            let a = answers[idx]
            hints += a.hintsUsed
            guard isCorrect(question: q, answer: a) else { continue }
            let penalty = 0.25 * Double(min(a.hintsUsed, 3))
            earned += max(0, 1 - penalty)
        }
        let scoreRounded = max(0, Int(round(earned)))
        return (scoreRounded, hints)
    }
}
