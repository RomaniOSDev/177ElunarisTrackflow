//
//  FlashcardsViewModel.swift
//  177ElunarisTrackflow
//

import Combine
import Foundation

enum FlashcardTopicFilter: String, CaseIterable, Identifiable {
    case all
    case known
    case learning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .known: return "Known"
        case .learning: return "In Progress"
        }
    }
}

@MainActor
final class FlashcardsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var filter: FlashcardTopicFilter = .all

    func filteredTopics(from topics: [FlashcardTopicModel], status: [UUID: FlashcardStatus]) -> [FlashcardTopicModel] {
        topics.filter { topic in
            let passesSearch = searchText.isEmpty
                || topic.title.localizedCaseInsensitiveContains(searchText)
                || topic.detail.localizedCaseInsensitiveContains(searchText)

            let passesFilter: Bool
            switch filter {
            case .all:
                passesFilter = true
            case .known:
                passesFilter = !topic.cards.isEmpty && topic.cards.allSatisfy { status[$0.id] == .known }
            case .learning:
                passesFilter = topic.cards.contains { status[$0.id, default: .learning] != .known }
            }
            return passesSearch && passesFilter
        }
    }
}
