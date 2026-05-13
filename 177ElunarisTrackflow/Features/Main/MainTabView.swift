//
//  MainTabView.swift
//  177ElunarisTrackflow
//

import SwiftUI

enum RootTab: Int, CaseIterable, Identifiable {
    case home
    case flashcards
    case learn
    case stats
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .flashcards: return "Flashcards"
        case .learn: return "Learn"
        case .stats: return "Stats"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .flashcards: return "rectangle.stack.fill"
        case .learn: return "bolt.horizontal.circle.fill"
        case .stats: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selection: RootTab = .home

    var body: some View {
        ZStack {
            LayeredAppBackground()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .all)

            Group {
                switch selection {
                case .home:
                    HomeView(selectedTab: $selection)
                case .flashcards:
                    FlashcardsView()
                case .learn:
                    LearnHubView()
                case .stats:
                    StatsAchievementsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .overlay(alignment: .top) {
            AchievementBannerView()
        }
        .ignoresSafeArea(.keyboard)
    }

    private var customTabBar: some View {
        HStack(spacing: 4) {
            ForEach(RootTab.allCases) { tab in
                Button {
                    Feedback.tap()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(selection == tab ? Color.appBackground : Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        Group {
                            if selection == tab {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(StudySurfaceStyle.primaryCTAFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                                            .blendMode(.plusLighter)
                                    )
                                    .compositingGroup()
                                    .shadow(color: Color.appPrimary.opacity(0.22), radius: 4, x: 0, y: 2)
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.clear)
                            }
                        }
                    }
                }
                .buttonStyle(TabScaleButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appSurface.opacity(0.97), Color.appSurface.opacity(0.86)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.appPrimary.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.24), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }
}

private struct TabScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
