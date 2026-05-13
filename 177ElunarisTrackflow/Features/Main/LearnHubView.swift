//
//  LearnHubView.swift
//  177ElunarisTrackflow
//

import SwiftUI

enum LearnHubSection: String, CaseIterable, Identifiable {
    case quiz
    case mixed
    case progress

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quiz: return "Quiz"
        case .mixed: return "Review"
        case .progress: return "Progress"
        }
    }
}

struct LearnHubView: View {
    @State private var section: LearnHubSection = .quiz

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                StudySectionHeader("Study hub")
                    .padding(.horizontal, 16)
                StudyCardContainer(cornerRadius: 16) {
                    Picker("Learn", selection: $section) {
                        ForEach(LearnHubSection.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(12)
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            Group {
                switch section {
                case .quiz:
                    QuickQuizView()
                case .mixed:
                    MixedReviewRootView()
                case .progress:
                    ProgressTrackerView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
