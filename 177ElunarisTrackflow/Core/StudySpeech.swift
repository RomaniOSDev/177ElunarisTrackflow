//
//  StudySpeech.swift
//  177ElunarisTrackflow
//

import AVFoundation
import Foundation

enum StudySpeech {
    private static let synthesizer = AVSpeechSynthesizer()

    static func speak(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        synthesizer.speak(utterance)
    }
}
