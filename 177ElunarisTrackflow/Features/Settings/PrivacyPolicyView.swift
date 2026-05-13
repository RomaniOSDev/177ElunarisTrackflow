//
//  PrivacyPolicyView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private var markdownText: String {
        if let url = Bundle.main.url(forResource: "privacy_policy", withExtension: "md"),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        return "# Privacy Policy\nContent unavailable."
    }

    private var policyAttributed: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        if let parsed = try? AttributedString(markdown: markdownText, options: options) {
            return parsed
        }
        return AttributedString(markdownText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LayeredAppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        StudyCardContainer {
                            HStack(alignment: .top, spacing: 14) {
                                StudySymbolTile(systemName: "hand.raised.fill", size: 52)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Your data")
                                        .font(.headline)
                                        .foregroundStyle(Color.appTextPrimary)
                                    Text("Policy below applies to information handled in this app on your device.")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                            }
                            .padding(16)
                        }
                        StudyCardContainer(cornerRadius: 16) {
                            Text(policyAttributed)
                                .foregroundStyle(Color.appTextPrimary)
                                .tint(Color.appPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        Feedback.tap()
                        dismiss()
                    }
                    .foregroundStyle(Color.appPrimary)
                }
            }
        }
    }
}
