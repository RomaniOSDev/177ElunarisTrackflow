//
//  Feedback.swift
//  177ElunarisTrackflow
//

import AudioToolbox
import SwiftUI
import UIKit

enum Feedback {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        notification.prepare()
    }

    static func tap() {
        lightImpact.impactOccurred()
    }

    static func mediumTap() {
        mediumImpact.impactOccurred()
    }

    static func success() {
        notification.notificationOccurred(.success)
    }

    static func warning() {
        notification.notificationOccurred(.warning)
    }

    static func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
}
