//
//  FlashcardsView.swift
//  177ElunarisTrackflow
//

import SwiftUI

struct FlashcardsView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = FlashcardsViewModel()
    @State private var showAddSheet = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                LayeredAppBackground()
                Group {
                    if store.topics.isEmpty {
                        emptyState
                    } else {
                        topicList
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Flashcards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Filter", selection: $viewModel.filter) {
                            ForEach(FlashcardTopicFilter.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.appPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Filter")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Feedback.tap()
                        showAddSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.appPrimary, Color.appSurface)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Add topic")
                }
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .sheet(isPresented: $showAddSheet) {
                AddTopicSheet()
                    .environmentObject(store)
            }
            .navigationDestination(for: UUID.self) { topicId in
                FlashcardTopicDetailView(topicId: topicId)
                    .environmentObject(store)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var emptyState: some View {
        ScrollView {
            StudyCardContainer {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.appPrimary.opacity(0.32), Color.appPrimary.opacity(0.06), Color.clear],
                                    center: .center,
                                    startRadius: 4,
                                    endRadius: 58
                                )
                            )
                            .frame(width: 116, height: 116)
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(Color.appPrimary)
                    }
                    VStack(spacing: 8) {
                        Text("Start creating your flashcards")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appTextPrimary)
                            .multilineTextAlignment(.center)
                        Text("Organize topics, add cards, and mark what you already know—everything stays on your device.")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    Button {
                        Feedback.mediumTap()
                        showAddSheet = true
                    } label: {
                        Text("Create first topic")
                            .font(.headline)
                            .foregroundStyle(Color.appBackground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(StudySurfaceStyle.primaryCTAFill)
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                                        .blendMode(.plusLighter)
                                }
                                .compositingGroup()
                                .shadow(color: Color.appPrimary.opacity(0.28), radius: 10, x: 0, y: 5)
                            }
                    }
                    .buttonStyle(.plain)
                }
                .padding(22)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .frame(maxWidth: .infinity)
        }
    }

    private var topicList: some View {
        List {
            Section {
                StudySectionHeader("Topics (\(viewModel.filteredTopics(from: store.topics, status: store.flashcardStatus).count))")
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            ForEach(viewModel.filteredTopics(from: store.topics, status: store.flashcardStatus)) { topic in
                Button {
                    Feedback.tap()
                    navigationPath.append(topic.id)
                } label: {
                    TopicFlashcardCell(topic: topic)
                }
                .buttonStyle(.plain)
                .environmentObject(store)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .contextMenu {
                    Button(role: .destructive) {
                        Feedback.tap()
                        store.deleteTopic(id: topic.id)
                    } label: {
                        Label("Delete Topic", systemImage: "trash")
                    }
                    Button {
                        Feedback.tap()
                        navigationPath.append(topic.id)
                    } label: {
                        Label("Open Topic", systemImage: "rectangle.stack")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        Feedback.mediumTap()
                        topic.cards.forEach { store.setStatus(for: $0.id, status: .known) }
                        Feedback.success()
                        Feedback.playSystemSound(1057)
                    } label: {
                        Label("Known", systemImage: "checkmark")
                    }
                    .tint(Color.appPrimary)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        Feedback.mediumTap()
                        topic.cards.forEach { store.setStatus(for: $0.id, status: .learning) }
                        Feedback.playSystemSound(1003)
                    } label: {
                        Label("Learning", systemImage: "hourglass")
                    }
                    .tint(Color.appAccent)
                    Button(role: .destructive) {
                        Feedback.tap()
                        store.deleteTopic(id: topic.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Topic cell

private struct TopicFlashcardCell: View {
    @EnvironmentObject private var store: AppDataStore
    let topic: FlashcardTopicModel

    private var knownCount: Int {
        topic.cards.filter { store.flashcardStatus[$0.id] == .known }.count
    }

    var body: some View {
        StudyCardContainer(elevation: .flat) {
            HStack(alignment: .top, spacing: 14) {
                StudySymbolTile(systemName: "rectangle.on.rectangle.angled", size: 52)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(topic.title)
                            .font(.headline)
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.appPrimary, Color.appSurface.opacity(0.4))
                    }
                    Text(topic.detail)
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        StudyInfoChip(text: "\(topic.cards.count) cards", prominent: false)
                        StudyInfoChip(text: "\(knownCount) known", prominent: knownCount == topic.cards.count && !topic.cards.isEmpty)
                    }

                    HStack(spacing: 10) {
                        StudyIconAction(
                            systemName: "checkmark.circle.fill",
                            isActive: topic.cards.allSatisfy { store.flashcardStatus[$0.id] == .known },
                            accessibility: "Mark all known"
                        ) {
                            Feedback.mediumTap()
                            topic.cards.forEach { store.setStatus(for: $0.id, status: .known) }
                            Feedback.success()
                            Feedback.playSystemSound(1057)
                        }
                        StudyIconAction(
                            systemName: "hourglass",
                            isActive: topic.cards.contains { store.flashcardStatus[$0.id] == .learning },
                            accessibility: "Mark in progress"
                        ) {
                            Feedback.mediumTap()
                            topic.cards.forEach { store.setStatus(for: $0.id, status: .learning) }
                            Feedback.playSystemSound(1003)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
    }
}
