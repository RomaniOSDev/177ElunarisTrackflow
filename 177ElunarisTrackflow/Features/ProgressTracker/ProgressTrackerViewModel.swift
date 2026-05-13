//
//  ProgressTrackerViewModel.swift
//  177ElunarisTrackflow
//

import Combine
import Foundation

enum ProgressSegment: String, CaseIterable, Identifiable {
    case overview
    case weekly
    case bookmarks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .weekly: return "Weekly Stats"
        case .bookmarks: return "Bookmarks"
        }
    }
}

final class ProgressTrackerViewModel: ObservableObject {
    @Published var segment: ProgressSegment = .overview
}
