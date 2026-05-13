//
//  StudyComponents.swift
//  177ElunarisTrackflow
//

import SwiftUI

// MARK: - Depth system (gradient volume, selective shadows — no backdrop blur)

/// Shadow is the main scrolling cost driver; use `.flat` inside `List` / long stacks.
enum StudyCardElevation {
    case lifted
    case flat
}

enum StudySurfaceStyle {
    /// Tuned smaller than before: cheaper to raster, still reads as elevation.
    static let liftedShadowRadius: CGFloat = 7
    static let liftedShadowY: CGFloat = 3

    /// Card shells (narrow controls, list rows).
    static var cardFaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appSurface.opacity(0.98),
                Color.appSurface.opacity(0.84),
                Color.appSurface.opacity(0.72),
            ],
            startPoint: UnitPoint(x: 0.12, y: 0),
            endPoint: UnitPoint(x: 0.88, y: 1)
        )
    }

    /// Large decks / reader panels (slightly deeper).
    static var panelFaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.appSurface.opacity(0.99),
                Color.appSurface.opacity(0.86),
                Color.appSurface.opacity(0.74),
            ],
            startPoint: UnitPoint(x: 0.1, y: 0),
            endPoint: UnitPoint(x: 0.92, y: 1)
        )
    }

    /// Fake top light — replaces heavy blur bloom.
    static var topSheen: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.07),
                Color.white.opacity(0.02),
                Color.clear,
            ],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.42)
        )
    }

    static var rimStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color.appPrimary.opacity(0.42),
                Color.appAccent.opacity(0.22),
                Color.appPrimary.opacity(0.14),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryCTAFill: LinearGradient {
        LinearGradient(
            colors: [Color.appPrimary, Color.appPrimary.opacity(0.76)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var mutedCTAFill: LinearGradient {
        LinearGradient(
            colors: [Color.appSurface.opacity(0.88), Color.appSurface.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentCTAFill: LinearGradient {
        LinearGradient(
            colors: [Color.appAccent.opacity(0.95), Color.appAccent.opacity(0.74)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var quizRowNeutralWell: LinearGradient {
        LinearGradient(
            colors: [Color.appSurface.opacity(0.96), Color.appSurface.opacity(0.78)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var quizRowSelectedWell: LinearGradient {
        LinearGradient(
            colors: [
                Color.appPrimary.opacity(0.32),
                Color.appPrimary.opacity(0.16),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var embeddedWell: LinearGradient {
        LinearGradient(
            colors: [Color.appSurface.opacity(0.92), Color.appSurface.opacity(0.78)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var summaryInsetWell: LinearGradient {
        LinearGradient(
            colors: [Color.appPrimary.opacity(0.14), Color.appPrimary.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Large reader / review panels

struct StudyElevatedPanelBackground: View {
    var cornerRadius: CGFloat = 24

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            shape.fill(StudySurfaceStyle.panelFaceGradient)
            shape.fill(StudySurfaceStyle.topSheen)
        }
        .overlay(shape.stroke(StudySurfaceStyle.rimStroke, lineWidth: 1))
        .allowsHitTesting(false)
    }
}

private struct StudyCardElevationModifier: ViewModifier {
    let elevation: StudyCardElevation

    func body(content: Content) -> some View {
        switch elevation {
        case .lifted:
            content
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.22), radius: StudySurfaceStyle.liftedShadowRadius, x: 0, y: StudySurfaceStyle.liftedShadowY)
        case .flat:
            content
        }
    }
}

// MARK: - Section chrome

struct StudySectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.92), Color.appAccent.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4, height: 14)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
                .textCase(.uppercase)
                .tracking(0.6)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Surfaces

struct StudyCardContainer<Content: View>: View {
    var cornerRadius: CGFloat = 18
    var elevation: StudyCardElevation = .lifted
    @ViewBuilder var content: () -> Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        content()
            .background {
                ZStack {
                    shape.fill(StudySurfaceStyle.cardFaceGradient)
                    shape.fill(StudySurfaceStyle.topSheen)
                }
            }
            .clipShape(shape)
            .overlay { shape.stroke(StudySurfaceStyle.rimStroke, lineWidth: 1) }
            .modifier(StudyCardElevationModifier(elevation: elevation))
    }
}

/// Leading icon plate for rows and cells.
struct StudySymbolTile: View {
    let systemName: String
    var size: CGFloat = 48

    var body: some View {
        let corner: CGFloat = 14
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        ZStack {
            shape
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.92), Color.appAccent.opacity(0.48)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            shape.fill(StudySurfaceStyle.topSheen)
            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(Color.appBackground)
        }
        .frame(width: size, height: size)
        .overlay(shape.stroke(Color.appBackground.opacity(0.42), lineWidth: 1))
        .overlay(
            shape
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                .allowsHitTesting(false)
        )
    }
}

// MARK: - Chips & badges

struct StudyInfoChip: View {
    let text: String
    var prominent: Bool = false

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(prominent ? Color.appBackground : Color.appAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule().fill(chipFill)
            }
            .overlay(
                Capsule().stroke(chipStrokeColor, lineWidth: prominent ? 0 : 1)
            )
    }

    private var chipFill: LinearGradient {
        if prominent {
            return StudySurfaceStyle.primaryCTAFill
        }
        return LinearGradient(
            colors: [Color.appPrimary.opacity(0.22), Color.appPrimary.opacity(0.11)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var chipStrokeColor: Color {
        prominent ? .clear : Color.appPrimary.opacity(0.35)
    }
}

struct StudyScoreBadge: View {
    let correct: Int
    let total: Int

    var body: some View {
        Text("\(correct)/\(total)")
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(Color.appBackground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appAccent.opacity(0.96), Color.appAccent.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.appPrimary.opacity(0.4), lineWidth: 1)
            )
    }
}

/// Circular ring showing 0…1 fraction (quiz result, readiness).
struct StudyRingGauge: View {
    var fraction: CGFloat
    var lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appPrimary.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(fraction, 0), 1)))
                .stroke(
                    AngularGradient(
                        colors: [Color.appPrimary, Color.appAccent, Color.appPrimary],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Row actions (flashcards toolbar)

struct StudyIconAction: View {
    let systemName: String
    var isActive: Bool = false
    let accessibility: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isActive ? Color.appAccent : Color.appTextPrimary)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(
                            isActive
                                ? StudySurfaceStyle.quizRowSelectedWell
                                : StudySurfaceStyle.quizRowNeutralWell
                        )
                }
                .overlay(
                    Circle()
                        .stroke(Color.appAccent.opacity(isActive ? 0.72 : 0.22), lineWidth: isActive ? 1.25 : 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibility))
    }
}

// MARK: - Misc

extension View {
    func studyMutedDivider() -> some View {
        overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.appPrimary.opacity(0.08))
                .frame(height: 1)
        }
    }
}

// MARK: - Form-style fields (sheets)

struct StudyLabeledTextField: View {
    let title: String
    var prompt: String = ""
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimitRange: ClosedRange<Int>?

    var body: some View {
        let fieldShape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            Group {
                if axis == .vertical, let range = lineLimitRange {
                    TextField(prompt.isEmpty ? title : prompt, text: $text, axis: .vertical)
                        .lineLimit(range)
                } else {
                    TextField(prompt.isEmpty ? title : prompt, text: $text)
                }
            }
            .font(.body)
            .foregroundStyle(Color.appTextPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                ZStack {
                    fieldShape.fill(Color.appPrimary.opacity(0.06))
                    fieldShape.fill(StudySurfaceStyle.topSheen)
                }
            }
            .overlay(
                fieldShape
                    .stroke(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.22), Color.appAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}
