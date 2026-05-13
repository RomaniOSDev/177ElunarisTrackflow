//
//  ConfettiView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var color: Color
        var rotation: Double
    }

    @State private var pieces: [Piece] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
        GeometryReader { proxy in
            let width = max(proxy.size.width, 320)
            let height = max(proxy.size.height, 320)
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color.opacity(0.9))
                        .frame(width: 8, height: 12)
                        .rotationEffect(.degrees(piece.rotation + t * 60))
                        .position(
                            x: piece.x,
                            y: CGFloat((Double(piece.y) + t * 90).truncatingRemainder(dividingBy: Double(height + 40)))
                        )
                }
            }
            .frame(width: width, height: height)
            .onAppear {
                if pieces.isEmpty {
                    pieces = (0 ..< 36).map { index in
                        Piece(
                            x: CGFloat.random(in: 0 ... width),
                            y: CGFloat.random(in: 0 ... height * 0.4),
                            color: index % 2 == 0 ? Color.appPrimary : Color.appAccent,
                            rotation: Double.random(in: 0 ... 360)
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }
}
