//
//  AchievementBannerView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct AchievementBannerView: View {
    @ObservedObject private var controller = AchievementBannerController.shared

    var body: some View {
        VStack {
            if let achievement = controller.activeAchievement {
                HStack(spacing: 12) {
                    Image(systemName: achievement.systemImage)
                        .foregroundStyle(Color.appBackground)
                        .padding(10)
                        .background {
                            Circle()
                                .fill(StudySurfaceStyle.primaryCTAFill)
                                .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1).blendMode(.plusLighter))
                        }
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Achievement unlocked")
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                        Text(achievement.title)
                            .font(.headline)
                            .foregroundStyle(Color.appTextPrimary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background {
                    let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
                    ZStack {
                        shape.fill(StudySurfaceStyle.cardFaceGradient)
                        shape.fill(StudySurfaceStyle.topSheen)
                        shape.stroke(StudySurfaceStyle.rimStroke, lineWidth: 1)
                    }
                    .compositingGroup()
                    .shadow(color: Color.black.opacity(0.22), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.top, 12)
        .allowsHitTesting(false)
    }
}
