//
//  AchievementBannerController.swift
//  177ElunarisTrackflow
//

import Combine
import SwiftUI

@MainActor
final class AchievementBannerController: ObservableObject {
    static let shared = AchievementBannerController()

    @Published private(set) var activeAchievement: AchievementCatalog.Item?
    private var queue: [AchievementCatalog.Item] = []
    private var isPresenting = false

    func enqueue(achievement: AchievementCatalog.Item) {
        queue.append(achievement)
        presentNextIfNeeded()
    }

    private func presentNextIfNeeded() {
        guard !isPresenting, activeAchievement == nil, !queue.isEmpty else { return }
        let next = queue.removeFirst()
        isPresenting = true
        Feedback.success()
        Feedback.playSystemSound(1057)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            activeAchievement = next
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeInOut(duration: 0.35)) {
                activeAchievement = nil
            }
            try? await Task.sleep(nanoseconds: 350_000_000)
            isPresenting = false
            presentNextIfNeeded()
        }
    }
}
