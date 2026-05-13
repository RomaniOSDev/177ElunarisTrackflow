//
//  ContentView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var store = AppDataStore.shared

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .background(LayeredAppBackground())
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .onAppear {
            Feedback.prepare()
        }
    }
}

#Preview {
    ContentView()
}
