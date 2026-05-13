//
//  AppDataStore.swift
//  177ElunarisTrackflow
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    private let defaults = UserDefaults.standard
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let topics = "flashcardTopicsPayload"
        static let flashcardStatus = "flashcardStatusPayload"
        static let quizSessions = "quizSessionsPayload"
        static let activeQuiz = "activeQuizPayload"
        static let topicsProgress = "topicsProgressPayload"
        static let weeklyStudyTime = "weeklyStudyTimePayload"
        static let dailyStudyTime = "dailyStudyTimePayload"
        static let bookmarkedItems = "bookmarkedItemsPayload"
        static let quizzesCompleted = "quizzesCompletedCount"
        static let totalMinutesUsed = "totalMinutesUsedCount"
        static let streakDays = "streakDaysCount"
        static let lastActivity = "lastActivityTimestamp"
        static let achievementsUnlocked = "achievementsUnlockedPayload"
        static let cardsReviewed = "cardsReviewedCount"
        static let cardSRS = "cardSRSPayload"
    }

    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var hasSeenOnboarding: Bool
    @Published private(set) var topics: [FlashcardTopicModel]
    @Published private(set) var flashcardStatus: [UUID: FlashcardStatus]
    @Published private(set) var quizSessions: [QuizSessionRecord]
    @Published private(set) var activeQuiz: ActiveQuizState?
    @Published private(set) var topicsProgress: [String: Float]
    @Published private(set) var weeklyStudyTime: [String: Int]
    @Published private(set) var dailyStudyTime: [String: Int]
    @Published private(set) var bookmarkedItems: [String]
    @Published private(set) var quizzesCompleted: Int
    @Published private(set) var totalMinutesUsed: Int
    @Published private(set) var streakDays: Int
    @Published private(set) var lastActivityDate: Date?
    @Published private(set) var achievementsUnlocked: [String: Date]
    @Published private(set) var cardsReviewed: Int

    private var srsByCard: [UUID: CardSRSState] = [:]

    var totalSessionsCompleted: Int { quizzesCompleted }

    private init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        topics = Self.decode([FlashcardTopicModel].self, from: defaults.data(forKey: Keys.topics)) ?? []
        flashcardStatus = Self.decodeStatus(from: defaults.data(forKey: Keys.flashcardStatus))
        quizSessions = Self.decode([QuizSessionRecord].self, from: defaults.data(forKey: Keys.quizSessions)) ?? []
        activeQuiz = Self.decode(ActiveQuizState.self, from: defaults.data(forKey: Keys.activeQuiz))
        topicsProgress = Self.decode([String: Float].self, from: defaults.data(forKey: Keys.topicsProgress)) ?? [:]
        weeklyStudyTime = Self.decode([String: Int].self, from: defaults.data(forKey: Keys.weeklyStudyTime)) ?? [:]
        dailyStudyTime = Self.decode([String: Int].self, from: defaults.data(forKey: Keys.dailyStudyTime)) ?? [:]
        bookmarkedItems = Self.decode([String].self, from: defaults.data(forKey: Keys.bookmarkedItems)) ?? []
        quizzesCompleted = defaults.integer(forKey: Keys.quizzesCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        if defaults.object(forKey: Keys.lastActivity) != nil {
            lastActivityDate = Date(timeIntervalSince1970: defaults.double(forKey: Keys.lastActivity))
        } else {
            lastActivityDate = nil
        }
        achievementsUnlocked = Self.decode([String: Date].self, from: defaults.data(forKey: Keys.achievementsUnlocked)) ?? [:]
        cardsReviewed = defaults.integer(forKey: Keys.cardsReviewed)
        srsByCard = Self.decodeSRS(from: defaults.data(forKey: Keys.cardSRS))
        synchronizeAchievementDatesWithProgress()
        NotificationCenter.default.publisher(for: .dataReset)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reloadAfterExternalReset()
            }
            .store(in: &cancellables)
    }

    private func reloadAfterExternalReset() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        topics = Self.decode([FlashcardTopicModel].self, from: defaults.data(forKey: Keys.topics)) ?? []
        flashcardStatus = Self.decodeStatus(from: defaults.data(forKey: Keys.flashcardStatus))
        quizSessions = Self.decode([QuizSessionRecord].self, from: defaults.data(forKey: Keys.quizSessions)) ?? []
        activeQuiz = Self.decode(ActiveQuizState.self, from: defaults.data(forKey: Keys.activeQuiz))
        topicsProgress = Self.decode([String: Float].self, from: defaults.data(forKey: Keys.topicsProgress)) ?? [:]
        weeklyStudyTime = Self.decode([String: Int].self, from: defaults.data(forKey: Keys.weeklyStudyTime)) ?? [:]
        dailyStudyTime = Self.decode([String: Int].self, from: defaults.data(forKey: Keys.dailyStudyTime)) ?? [:]
        bookmarkedItems = Self.decode([String].self, from: defaults.data(forKey: Keys.bookmarkedItems)) ?? []
        quizzesCompleted = defaults.integer(forKey: Keys.quizzesCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        if defaults.object(forKey: Keys.lastActivity) != nil {
            lastActivityDate = Date(timeIntervalSince1970: defaults.double(forKey: Keys.lastActivity))
        } else {
            lastActivityDate = nil
        }
        achievementsUnlocked = Self.decode([String: Date].self, from: defaults.data(forKey: Keys.achievementsUnlocked)) ?? [:]
        cardsReviewed = defaults.integer(forKey: Keys.cardsReviewed)
        srsByCard = Self.decodeSRS(from: defaults.data(forKey: Keys.cardSRS))
        synchronizeAchievementDatesWithProgress()
        objectWillChange.send()
    }

    private static func decodeStatus(from data: Data?) -> [UUID: FlashcardStatus] {
        guard let raw = decode([String: FlashcardStatus].self, from: data) else { return [:] }
        var output: [UUID: FlashcardStatus] = [:]
        for (key, value) in raw {
            if let uuid = UUID(uuidString: key) {
                output[uuid] = value
            }
        }
        return output
    }

    private static func decodeSRS(from data: Data?) -> [UUID: CardSRSState] {
        guard let raw = decode([String: CardSRSState].self, from: data) else { return [:] }
        var output: [UUID: CardSRSState] = [:]
        for (key, value) in raw {
            if let uuid = UUID(uuidString: key) {
                output[uuid] = value
            }
        }
        return output
    }

    private func persistSRS() {
        let encoded = srsByCard.reduce(into: [String: CardSRSState]()) { partial, pair in
            partial[pair.key.uuidString] = pair.value
        }
        if let data = encode(encoded) {
            defaults.set(data, forKey: Keys.cardSRS)
        }
        objectWillChange.send()
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T) -> Data? {
        try? encoder.encode(value)
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
        objectWillChange.send()
    }

    func addTopic(
        title: String,
        detail: String,
        initialPrompt: String,
        initialAnswer: String,
        exampleSentence: String? = nil,
        pronunciationHint: String? = nil,
        tags: [String] = []
    ) {
        let card = FlashCardModel(
            prompt: initialPrompt,
            answer: initialAnswer,
            exampleSentence: exampleSentence,
            pronunciationHint: pronunciationHint,
            tags: tags
        )
        let topic = FlashcardTopicModel(id: UUID(), title: title, detail: detail, cards: [card])
        topics.append(topic)
        persistTopics()
        registerMeaningfulActivity()
        addStudyMinutes(1)
    }

    func updateTopic(_ topic: FlashcardTopicModel) {
        guard let index = topics.firstIndex(where: { $0.id == topic.id }) else { return }
        topics[index] = topic
        persistTopics()
    }

    func deleteTopic(id: UUID) {
        guard let topic = topics.first(where: { $0.id == id }) else { return }
        for card in topic.cards {
            flashcardStatus.removeValue(forKey: card.id)
            srsByCard.removeValue(forKey: card.id)
        }
        topics.removeAll { $0.id == id }
        bookmarkedItems.removeAll { $0 == id.uuidString }
        topicsProgress.removeValue(forKey: id.uuidString)
        persistTopics()
        persistStatus()
        persistBookmarks()
        persistTopicsProgress()
        persistSRS()
    }

    func addCard(to topicId: UUID, prompt: String, answer: String, exampleSentence: String? = nil, pronunciationHint: String? = nil, tags: [String] = []) {
        guard let index = topics.firstIndex(where: { $0.id == topicId }) else { return }
        topics[index].cards.append(
            FlashCardModel(prompt: prompt, answer: answer, exampleSentence: exampleSentence, pronunciationHint: pronunciationHint, tags: tags)
        )
        persistTopics()
    }

    func setStatus(for cardId: UUID, status: FlashcardStatus) {
        flashcardStatus[cardId] = status
        persistStatus()
        registerMeaningfulActivity()
        incrementCardsReviewed()
        recomputeTopicProgress(forCard: cardId)
    }

    func recordCardSwipeReview(cardId: UUID) {
        incrementCardsReviewed()
        registerMeaningfulActivity()
        addStudyMinutes(1)
        recomputeTopicProgress(forCard: cardId)
    }

    func srsState(for cardId: UUID) -> CardSRSState {
        srsByCard[cardId] ?? .newCard()
    }

    func mixedReviewQueue(limit: Int = 50) -> [MixedReviewItem] {
        struct Row {
            let item: MixedReviewItem
            let bucket: Int
            let date: Date
        }

        let now = Date()
        var rows: [Row] = []
        for topic in topics {
            for card in topic.cards {
                let srs = srsByCard[card.id] ?? .newCard()
                let due = srs.nextReviewAt <= now
                let learning = flashcardStatus[card.id] == .learning
                let bucket: Int
                if due {
                    bucket = 0
                } else if learning {
                    bucket = 1
                } else {
                    bucket = 2
                }
                rows.append(
                    Row(
                        item: MixedReviewItem(topicId: topic.id, topicTitle: topic.title, card: card),
                        bucket: bucket,
                        date: srs.nextReviewAt
                    )
                )
            }
        }
        rows.sort { a, b in
            if a.bucket != b.bucket { return a.bucket < b.bucket }
            return a.date < b.date
        }
        return Array(rows.prefix(limit).map(\.item))
    }

    /// Snapshot counts for the mixed-review dashboard (not the full sorted queue).
    func reviewQueueStats() -> (due: Int, learning: Int, total: Int) {
        let now = Date()
        var due = 0
        var learningCt = 0
        var total = 0
        for topic in topics {
            for card in topic.cards {
                total += 1
                let srs = srsByCard[card.id] ?? .newCard()
                if srs.nextReviewAt <= now {
                    due += 1
                } else if flashcardStatus[card.id] == .learning {
                    learningCt += 1
                }
            }
        }
        return (due, learningCt, total)
    }

    /// Label for UI when showing queue priority.
    func mixedReviewBucketLabel(for cardId: UUID) -> String {
        let now = Date()
        let srs = srsState(for: cardId)
        if srs.nextReviewAt <= now {
            return "Due"
        }
        if flashcardStatus[cardId] == .learning {
            return "Learning"
        }
        return "Scheduled"
    }

    func recordReviewQuality(for cardId: UUID, quality: Int) {
        let q = min(5, max(0, quality))
        switch q {
        case 0 ... 3:
            flashcardStatus[cardId] = .learning
        case 4 ... 5:
            flashcardStatus[cardId] = .known
        default:
            break
        }
        persistStatus()
        incrementCardsReviewed()
        registerMeaningfulActivity()
        addStudyMinutes(1)

        var state = srsByCard[cardId] ?? .newCard()
        let now = Date()
        let calendar = Calendar.current
        let isNewReset = state.nextReviewAt == Date.distantPast && abs(state.intervalDays) < .ulpOfOne

        func add(days: Double) -> Date {
            let minutes = max(10, Int(days * 24 * 60))
            return calendar.date(byAdding: .minute, value: minutes, to: now) ?? now.addingTimeInterval(days * 86400)
        }

        switch q {
        case 0:
            state.intervalDays = 0.01
            state.nextReviewAt = now.addingTimeInterval(600)
            state.ease = max(1.3, state.ease - 0.2)
        case 1:
            state.intervalDays = 0.25
            state.nextReviewAt = add(days: state.intervalDays)
            state.ease = max(1.3, state.ease - 0.15)
        case 2:
            state.intervalDays = 1
            state.nextReviewAt = add(days: 1)
        case 3:
            let base = isNewReset ? 1 : max(0.5, state.intervalDays)
            state.intervalDays = max(1, base * 1.6)
            state.nextReviewAt = add(days: state.intervalDays)
        case 4:
            let base = isNewReset ? 1 : max(0.5, state.intervalDays)
            state.intervalDays = max(1, base * 2.2)
            state.nextReviewAt = add(days: state.intervalDays)
        case 5:
            let base = isNewReset ? 2 : max(0.5, state.intervalDays)
            state.intervalDays = max(1, base * 3)
            state.nextReviewAt = add(days: state.intervalDays)
        default:
            break
        }

        srsByCard[cardId] = state
        persistSRS()
        recomputeTopicProgress(forCard: cardId)
        objectWillChange.send()
    }

    private func incrementCardsReviewed() {
        cardsReviewed += 1
        defaults.set(cardsReviewed, forKey: Keys.cardsReviewed)
        unlockAchievementsIfNeeded()
    }

    func persistActiveQuiz(_ state: ActiveQuizState?) {
        activeQuiz = state
        if let data = encode(state) {
            defaults.set(data, forKey: Keys.activeQuiz)
        } else {
            defaults.removeObject(forKey: Keys.activeQuiz)
        }
        objectWillChange.send()
    }

    func appendQuizSession(_ session: QuizSessionRecord) {
        quizSessions.insert(session, at: 0)
        if let data = encode(quizSessions) {
            defaults.set(data, forKey: Keys.quizSessions)
        }
        quizzesCompleted += 1
        defaults.set(quizzesCompleted, forKey: Keys.quizzesCompleted)
        addStudyMinutes(max(2, session.totalQuestions))
        registerMeaningfulActivity()
        updateWeeklyMinutes(delta: max(2, session.totalQuestions))
        recomputeProgressAfterQuiz(topicTitle: session.topic, score: session.score, total: session.totalQuestions)
        persistActiveQuiz(nil)
        unlockAchievementsIfNeeded()
        objectWillChange.send()
    }

    func setTopicProgress(topicKey: String, value: Float) {
        topicsProgress[topicKey] = min(1, max(0, value))
        persistTopicsProgress()
        registerMeaningfulActivity()
        Feedback.tap()
        Feedback.playSystemSound(1103)
        unlockAchievementsIfNeeded()
        objectWillChange.send()
    }

    func toggleBookmark(topicId: UUID) {
        let key = topicId.uuidString
        if let index = bookmarkedItems.firstIndex(of: key) {
            bookmarkedItems.remove(at: index)
        } else {
            bookmarkedItems.append(key)
        }
        persistBookmarks()
        registerMeaningfulActivity()
        Feedback.tap()
        Feedback.playSystemSound(1103)
        unlockAchievementsIfNeeded()
        objectWillChange.send()
    }

    func reorderTopics(from offsets: IndexSet, to offset: Int) {
        topics.move(fromOffsets: offsets, toOffset: offset)
        persistTopics()
    }

    func registerMeaningfulActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let last = lastActivityDate {
            let lastDay = calendar.startOfDay(for: last)
            if today == lastDay {
                lastActivityDate = Date()
                defaults.set(lastActivityDate?.timeIntervalSince1970 ?? 0, forKey: Keys.lastActivity)
                return
            }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
               calendar.isDate(lastDay, inSameDayAs: yesterday) {
                streakDays += 1
            } else {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }
        lastActivityDate = Date()
        defaults.set(streakDays, forKey: Keys.streakDays)
        defaults.set(lastActivityDate?.timeIntervalSince1970 ?? 0, forKey: Keys.lastActivity)
        objectWillChange.send()
    }

    private func addStudyMinutes(_ delta: Int) {
        let safeDelta = max(0, delta)
        totalMinutesUsed += safeDelta
        defaults.set(totalMinutesUsed, forKey: Keys.totalMinutesUsed)
        let dayKey = Self.dayKey(for: Date())
        dailyStudyTime[dayKey, default: 0] += safeDelta
        if let data = encode(dailyStudyTime) {
            defaults.set(data, forKey: Keys.dailyStudyTime)
        }
        unlockAchievementsIfNeeded()
        objectWillChange.send()
    }

    private func updateWeeklyMinutes(delta: Int) {
        let key = Self.weekKey(for: Date())
        weeklyStudyTime[key, default: 0] += delta
        if let data = encode(weeklyStudyTime) {
            defaults.set(data, forKey: Keys.weeklyStudyTime)
        }
        objectWillChange.send()
    }

    private static func weekKey(for date: Date) -> String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        return "\(year)-W\(week)"
    }

    private static func dayKey(for date: Date) -> String {
        let day = Calendar.current.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: day)
    }

    func studyMinutesLastSevenDays() -> [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).map { offset in
            guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: today) else { return 0 }
            let key = Self.dayKey(for: date)
            return dailyStudyTime[key] ?? 0
        }
    }

    private func recomputeTopicProgress(forCard cardId: UUID) {
        guard let topic = topics.first(where: { topic in topic.cards.contains(where: { $0.id == cardId }) }) else { return }
        let known = topic.cards.filter { flashcardStatus[$0.id] == .known }.count
        let ratio = topic.cards.isEmpty ? 0 : Float(known) / Float(topic.cards.count)
        topicsProgress[topic.id.uuidString] = ratio
        persistTopicsProgress()
    }

    private func recomputeProgressAfterQuiz(topicTitle: String, score: Int, total: Int) {
        guard let topic = topics.first(where: { $0.title == topicTitle }) else { return }
        let ratio = total == 0 ? 0 : Float(score) / Float(total)
        let previous = topicsProgress[topic.id.uuidString] ?? 0
        let blended = min(1, max(previous, ratio))
        topicsProgress[topic.id.uuidString] = blended
        persistTopicsProgress()
    }

    private func persistTopics() {
        if let data = encode(topics) {
            defaults.set(data, forKey: Keys.topics)
        }
        objectWillChange.send()
    }

    private func persistStatus() {
        let encoded: [String: FlashcardStatus] = flashcardStatus.reduce(into: [:]) { partial, pair in
            partial[pair.key.uuidString] = pair.value
        }
        if let data = encode(encoded) {
            defaults.set(data, forKey: Keys.flashcardStatus)
        }
        objectWillChange.send()
    }

    private func persistBookmarks() {
        if let data = encode(bookmarkedItems) {
            defaults.set(data, forKey: Keys.bookmarkedItems)
        }
        objectWillChange.send()
    }

    private func persistTopicsProgress() {
        if let data = encode(topicsProgress) {
            defaults.set(data, forKey: Keys.topicsProgress)
        }
        objectWillChange.send()
    }

    func resetAllData() {
        let keys = [
            Keys.hasSeenOnboarding,
            Keys.topics,
            Keys.flashcardStatus,
            Keys.quizSessions,
            Keys.activeQuiz,
            Keys.topicsProgress,
            Keys.weeklyStudyTime,
            Keys.dailyStudyTime,
            Keys.bookmarkedItems,
            Keys.quizzesCompleted,
            Keys.totalMinutesUsed,
            Keys.streakDays,
            Keys.lastActivity,
            Keys.achievementsUnlocked,
            Keys.cardsReviewed,
            Keys.cardSRS
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }
        NotificationCenter.default.post(name: .dataReset, object: nil)
        reloadAfterExternalReset()
    }

    private func synchronizeAchievementDatesWithProgress() {
        var updated = achievementsUnlocked
        let now = Date()
        for achievement in AchievementCatalog.all {
            if achievement.isUnlocked(
                cardsReviewed: cardsReviewed,
                quizzesCompleted: quizzesCompleted,
                studyMinutes: totalMinutesUsed,
                streakDays: streakDays
            ), updated[achievement.id] == nil {
                updated[achievement.id] = now
            }
        }
        if updated != achievementsUnlocked {
            achievementsUnlocked = updated
            if let data = encode(updated) {
                defaults.set(data, forKey: Keys.achievementsUnlocked)
            }
            objectWillChange.send()
        }
    }

    private func unlockAchievementsIfNeeded() {
        let previous = Set(achievementsUnlocked.keys)
        synchronizeAchievementDatesWithProgress()
        let newlyUnlocked = Set(achievementsUnlocked.keys).subtracting(previous)
        let ordered = AchievementCatalog.all.filter { newlyUnlocked.contains($0.id) }
        for item in ordered {
            AchievementBannerController.shared.enqueue(achievement: item)
        }
    }

    func clearAllBookmarks() {
        bookmarkedItems.removeAll()
        persistBookmarks()
        objectWillChange.send()
    }

    func topic(for id: UUID) -> FlashcardTopicModel? {
        topics.first { $0.id == id }
    }

    func latestQuizSession(forTopicTitle topicTitle: String) -> QuizSessionRecord? {
        quizSessions
            .filter { $0.topic == topicTitle }
            .max(by: { $0.completedAt < $1.completedAt })
    }
}

struct AchievementCatalog {
    struct Item: Identifiable {
        let id: String
        let title: String
        let detail: String
        let systemImage: String

        func isUnlocked(cardsReviewed: Int, quizzesCompleted: Int, studyMinutes: Int, streakDays: Int) -> Bool {
            switch id {
            case "first_steps":
                return cardsReviewed >= 1
            case "quiz_novice":
                return quizzesCompleted >= 1
            case "diligent_learner":
                return studyMinutes >= 30
            case "consistent_student":
                return streakDays >= 3
            case "getting_going":
                return cardsReviewed >= 10
            case "power_user":
                return cardsReviewed >= 50
            case "active_user":
                return quizzesCompleted >= 10
            case "dedicated_user":
                return quizzesCompleted >= 50
            default:
                return false
            }
        }
    }

    static let all: [Item] = [
        Item(id: "first_steps", title: "First Steps", detail: "Reviewed the first flashcard.", systemImage: "figure.walk"),
        Item(id: "quiz_novice", title: "Quiz Novice", detail: "Completed the first quiz.", systemImage: "sparkles"),
        Item(id: "diligent_learner", title: "Diligent Learner", detail: "Studied for a total of 30 minutes.", systemImage: "clock.fill"),
        Item(id: "consistent_student", title: "Consistent Student", detail: "Maintained a 3-day study streak.", systemImage: "flame.fill"),
        Item(id: "getting_going", title: "Getting Going", detail: "Reached 10 items.", systemImage: "chart.line.uptrend.xyaxis"),
        Item(id: "power_user", title: "Power User", detail: "Reached 50 items.", systemImage: "bolt.fill"),
        Item(id: "active_user", title: "Active User", detail: "Completed 10 sessions.", systemImage: "rectangle.stack.fill"),
        Item(id: "dedicated_user", title: "Dedicated User", detail: "Completed 50 sessions.", systemImage: "star.fill")
    ]
}
