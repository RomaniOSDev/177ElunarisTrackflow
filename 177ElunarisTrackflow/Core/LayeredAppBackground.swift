//
//  LayeredAppBackground.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct LayeredAppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.appBackground,
                    Color.appSurface.opacity(0.42),
                    Color.appBackground.opacity(0.94),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.appPrimary.opacity(0.14), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 220
                            )
                        )
                        .frame(width: 420, height: 420)
                        .position(x: w * 0.12, y: h * 0.08)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.appAccent.opacity(0.11), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 380, height: 380)
                        .position(x: w * 0.92, y: h * 0.28)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.appPrimary.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 240
                            )
                        )
                        .frame(width: 460, height: 460)
                        .position(x: w * 0.55, y: h * 0.92)
                    }
                    .allowsHitTesting(false)
            }

            Canvas { context, size in
                let step: CGFloat = 32
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width + step {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x - size.height, y: size.height))
                    x += step
                }
                context.stroke(path, with: .color(Color.appPrimary.opacity(0.04)), lineWidth: 1)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}
