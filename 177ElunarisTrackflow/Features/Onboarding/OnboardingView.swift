//
//  OnboardingView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = OnboardingViewModel()

    private var bottomPadding: CGFloat { 26 }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 12)

            TabView(selection: $viewModel.pageIndex) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(
                        title: page.title,
                        message: page.message,
                        illustrationIndex: index
                    )
                    .tag(index)
                    .padding(.horizontal, 20)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)

            pageIndicatorRail
                .padding(.horizontal, 20)
                .padding(.top, 14)

            primaryAction
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, bottomPadding)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            StudySectionHeader("Welcome")
            Text("Swipe through — your study flows stay offline and private.")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            StudyInfoChip(
                text: "Step \(min(viewModel.pageIndex + 1, viewModel.pages.count)) of \(viewModel.pages.count)",
                prominent: false
            )
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pageIndicatorRail: some View {
        StudyCardContainer(cornerRadius: 18, elevation: .flat) {
            HStack(spacing: 8) {
                ForEach(0 ..< viewModel.pages.count, id: \.self) { index in
                    Capsule()
                        .fill(segmentFill(isActive: index == viewModel.pageIndex))
                        .frame(width: index == viewModel.pageIndex ? 26 : 8, height: 8)
                        .overlay(
                            Capsule().stroke(segmentStroke(isActive: index == viewModel.pageIndex), lineWidth: index == viewModel.pageIndex ? 0 : 0.65)
                        )
                        .animation(.spring(response: 0.42, dampingFraction: 0.74), value: viewModel.pageIndex)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
        }
    }

    private func segmentFill(isActive: Bool) -> LinearGradient {
        if isActive {
            StudySurfaceStyle.primaryCTAFill
        } else {
            LinearGradient(
                colors: [
                    Color.appPrimary.opacity(0.16),
                    Color.appAccent.opacity(0.08),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private func segmentStroke(isActive: Bool) -> Color {
        isActive ? .clear : Color.appPrimary.opacity(0.35)
    }

    private var primaryAction: some View {
        Button(action: {
            viewModel.advance(store: store)
        }) {
            Text(viewModel.isLastPage ? "Get Started" : "Next")
                .font(.headline)
                .foregroundStyle(Color.appBackground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background {
                    let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
                    ZStack {
                        shape.fill(StudySurfaceStyle.primaryCTAFill)
                        shape.fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        shape.stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                    .compositingGroup()
                    .shadow(color: Color.appPrimary.opacity(0.32), radius: 14, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                }
        }
        .buttonStyle(ScalePressButtonStyle())
    }
}

private struct OnboardingPageView: View {
    let title: String
    let message: String
    let illustrationIndex: Int

    @State private var appeared = false

    private var onboardingDivider: some View {
        RoundedRectangle(cornerRadius: 1, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.appPrimary.opacity(0.35),
                        Color.appAccent.opacity(0.2),
                        Color.appPrimary.opacity(0.06),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 4)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            StudyCardContainer(cornerRadius: 22, elevation: .lifted) {
                VStack(spacing: 20) {
                    OnboardingHeroIllustration(index: illustrationIndex)
                        .frame(height: 208)
                        .scaleEffect(appeared ? 1 : 0.92)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.48, dampingFraction: 0.72), value: appeared)

                    onboardingDivider

                    VStack(spacing: 10) {
                        Text(title)
                            .font(.title2.bold())
                            .foregroundStyle(Color.appTextPrimary)
                            .multilineTextAlignment(.center)

                        Text(message)
                            .font(.body)
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 2)
                }
                .padding(20)
                .padding(.vertical, 2)
            }
            .padding(.vertical, 6)
        }
        .onAppear {
            appeared = false
            withAnimation(.spring(response: 0.48, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }
}

// MARK: - Hero illustration (panels + glyphs — optimized, no blur)

private struct OnboardingHeroIllustration: View {
    let index: Int

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    var body: some View {
        ZStack {
            StudyElevatedPanelBackground(cornerRadius: 20)

            onboardingGlowAccents

            Group {
                switch index {
                case 0:
                    trackAndNodesArt
                case 1:
                    flashcardStackArt
                default:
                    launchArt
                }
            }
            .padding(22)
        }
        .clipShape(panelShape)
    }

    private var onboardingGlowAccents: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appAccent.opacity(0.38), Color.appAccent.opacity(0.06), Color.clear],
                        center: .center,
                        startRadius: 2,
                        endRadius: 90
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: 96, y: -56)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appPrimary.opacity(0.42), Color.appPrimary.opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 2,
                        endRadius: 72
                    )
                )
                .frame(width: 130, height: 130)
                .offset(x: -104, y: 62)
        }
        .allowsHitTesting(false)
    }

    /// Page 1: learning path with gradient stroke.
    private var trackAndNodesArt: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 32, y: 154))
                path.addQuadCurve(to: CGPoint(x: 164, y: 36), control: CGPoint(x: 90, y: 198))
                path.addQuadCurve(to: CGPoint(x: 292, y: 132), control: CGPoint(x: 258, y: 32))
            }
            .stroke(
                LinearGradient(
                    colors: [Color.appAccent, Color.appPrimary, Color.appAccent.opacity(0.75)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round)
            )

            nodeDot(offset: CGSize(width: -86, height: 28))
            nodeDot(offset: CGSize(width: 48, height: -58))

            Image(systemName: "graduationcap.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(
                    LinearGradient(colors: [Color.appPrimary.opacity(0.95), Color.appAccent], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .symbolRenderingMode(.hierarchical)
                .offset(x: 108, y: 62)

            Image(systemName: "sparkles")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .offset(x: -118, y: -64)
        }
    }

    private func nodeDot(offset: CGSize) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.appPrimary.opacity(0.96), Color.appPrimary.opacity(0.55), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 18
                )
            )
            .frame(width: 22, height: 22)
            .overlay(Circle().stroke(Color.appBackground.opacity(0.55), lineWidth: 2))
            .offset(offset)
    }

    /// Page 2: stacked flashcard tiles.
    private var flashcardStackArt: some View {
        ZStack {
            stackedCard(dx: -10, dy: 16, tilt: -6, fade: 0.55)
            stackedCard(dx: 6, dy: 6, tilt: -2, fade: 0.72)
            stackedCard(dx: 0, dy: -8, tilt: 0, fade: 1)

            VStack(spacing: 8) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(Color.appAccent)
                    .shadow(color: Color.black.opacity(0.28), radius: 5, x: 0, y: 3)
                    .offset(y: -18)

                HStack(spacing: 14) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.appPrimary)
                        .font(.title3)
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .foregroundStyle(Color.appAccent.opacity(0.92))
                        .font(.title3)
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(Color.appPrimary.opacity(0.82))
                        .font(.title3)
                }
                .offset(y: 58)
            }
        }
    }

    private func stackedCard(dx: CGFloat, dy: CGFloat, tilt: Double, fade: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: 13, style: .continuous)
        return shape
            .fill(
                LinearGradient(
                    colors: [
                        Color.appPrimary.opacity(Double(0.78 * fade)),
                        Color.appAccent.opacity(Double(0.35 * fade)),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                shape.stroke(Color.appBackground.opacity(0.42), lineWidth: 1.5)
            )
            .overlay(
                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.appSurface.opacity(Double(0.55 + 0.25 * fade)))
                        .frame(height: 10)
                        .padding(.horizontal, 14)
                        .opacity(Double(fade))
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.appSurface.opacity(Double(0.45 + 0.2 * fade)))
                        .frame(height: 10)
                        .padding(.horizontal, 22)
                        .opacity(Double(fade * 0.85))
                }
                .padding(.vertical, 20)
                .opacity(Double(min(1, fade + 0.15)))
            )
            .frame(width: 174, height: 112)
            .rotationEffect(.degrees(tilt))
            .offset(x: dx, y: dy)
            .allowsHitTesting(false)
    }

    /// Page 3: forward motion / start.
    private var launchArt: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(colors: [Color.appPrimary.opacity(0.95), Color.appAccent.opacity(0.78)], startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: 230, height: 48)
                .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1.2))
                .offset(y: 56)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appAccent.opacity(0.5), Color.appAccent.opacity(0.12), Color.clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 48
                        )
                    )
                    .frame(width: 96, height: 96)

                Image(systemName: "arrow.forward.circle.fill")
                    .font(.system(size: 68, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appAccent, Color.appPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
                    .shadow(color: Color.black.opacity(0.22), radius: 4, x: 0, y: 2)
            }
            .offset(y: -28)

            Image(systemName: "wand.and.stars")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color.appAccent)
                .offset(x: 122, y: -48)
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.appPrimary.opacity(0.82))
                .offset(x: -122, y: 38)
        }
    }
}

private struct ScalePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}
