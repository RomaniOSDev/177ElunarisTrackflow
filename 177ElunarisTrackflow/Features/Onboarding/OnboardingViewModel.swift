//
//  OnboardingViewModel.swift
//  177ElunarisTrackflow
//

import Combine
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var pageIndex = 0

    let pages: [(title: String, message: String)] = [
        (
            "Master Subjects",
            "Enhance your knowledge through tailored learning tools."
        ),
        (
            "Create Flashcards",
            "Easily create and review personalized flashcards to boost memory."
        ),
        (
            "Start Your Journey",
            "Begin by selecting a topic of interest to explore."
        )
    ]

    var isLastPage: Bool {
        pageIndex == pages.count - 1
    }

    func advance(store: AppDataStore) {
        if isLastPage {
            Feedback.mediumTap()
            Feedback.playSystemSound(1057)
            Feedback.success()
            store.completeOnboarding()
        } else {
            Feedback.tap()
            withAnimation(.easeInOut(duration: 0.3)) {
                pageIndex += 1
            }
        }
    }
}
