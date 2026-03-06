import SwiftUI

// MARK: - ChatThreadListView

/// Root view for the Coach tab. Shows all persisted thread threads and allows creating new ones.
struct ChatThreadListView: View {
    @ObservedObject var coordinator: ChatCoordinator
    @ObservedObject var model: DevineAppModel

    /// Drives programmatic NavigationStack push (nudge threads, new thread creation).
    @State private var navigationPath: [UUID] = []
    @State private var threadToRename: ChatThread?
    @State private var renameText = ""

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                DevineTheme.Colors.bgPrimary.ignoresSafeArea()

                if coordinator.threads.isEmpty {
                    emptyState
                } else {
                    threadList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    coachTitle
                }
                ToolbarItem(placement: .topBarTrailing) {
                    newThreadButton
                }
            }
            .navigationDestination(for: UUID.self) { threadID in
                ChatView(threadID: threadID, coordinator: coordinator, model: model)
            }
        }
        // Auto-push when a CoachNudge thread is created
        .onChange(of: coordinator.pendingNavigationThreadID) { _, id in
            guard let id else { return }
            coordinator.pendingNavigationThreadID = nil
            navigationPath = [id]
        }
        // Rename sheet
        .sheet(item: $threadToRename) { thread in
            renameSheet(thread: thread)
        }
    }

    // MARK: Navigation title

    private var coachTitle: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(DevineTheme.Colors.ctaPrimary.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text("✦")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.ctaPrimary)
            }
            Text("Coach")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(DevineTheme.Colors.textPrimary)
        }
    }

    // MARK: New thread button

    private var newThreadButton: some View {
        Button {
            let thread = coordinator.createThread()
            navigationPath.append(thread.id)
            DevineHaptic.tap.fire()
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.ctaPrimary)
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(DevineTheme.Colors.ctaPrimary.opacity(0.08))
                        .frame(width: 96, height: 96)
                    Circle()
                        .fill(DevineTheme.Colors.ctaPrimary.opacity(0.12))
                        .frame(width: 70, height: 70)
                    Text("✦")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: DevineTheme.Gradients.primaryCTA,
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 8) {
                    Text("Start a conversation")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(DevineTheme.Colors.textPrimary)
                    Text("Ask your AI glow coach anything about\nyour routine, plan, or habits")
                        .font(.system(size: 14))
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }

            Button {
                let thread = coordinator.createThread()
                navigationPath.append(thread.id)
                DevineHaptic.tap.fire()
            } label: {
                Text("Start chatting")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 220)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: DevineTheme.Gradients.primaryCTA,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: Thread list

    private var threadList: some View {
        List {
            ForEach(coordinator.threads) { thread in
                ThreadRow(thread: thread)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        navigationPath.append(thread.id)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            coordinator.deleteThread(thread.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            threadToRename = thread
                            renameText = thread.title
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Button {
                            coordinator.pinThread(thread.id, pinned: !thread.isPinned)
                        } label: {
                            Label(
                                thread.isPinned ? "Unpin" : "Pin",
                                systemImage: thread.isPinned ? "pin.slash" : "pin"
                            )
                        }

                        Divider()

                        Button(role: .destructive) {
                            coordinator.deleteThread(thread.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowBackground(DevineTheme.Colors.bgPrimary)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DevineTheme.Colors.bgPrimary)
    }

    // MARK: Rename sheet

    @ViewBuilder
    private func renameSheet(thread: ChatThread) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Rename conversation")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)
            }
            .padding(.top, 24)

            TextField("Conversation title", text: $renameText)
                .font(.system(size: 16))
                .foregroundStyle(DevineTheme.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous)
                        .fill(DevineTheme.Colors.bgSecondary)
                )
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button("Cancel") {
                    threadToRename = nil
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous)
                        .fill(DevineTheme.Colors.bgSecondary)
                )

                Button("Save") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        coordinator.renameThread(thread.id, title: trimmed)
                    }
                    threadToRename = nil
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: DevineTheme.Gradients.primaryCTA,
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous))
                .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
        .background(DevineTheme.Colors.bgPrimary.ignoresSafeArea())
    }
}

// MARK: - ThreadRow

private struct ThreadRow: View {
    let thread: ChatThread

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: DevineTheme.Gradients.primaryCTA.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                if thread.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                } else {
                    Text("✦")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DevineTheme.Colors.ctaPrimary)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(thread.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(DevineTheme.Colors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(thread.updatedAt.relativeShort)
                        .font(.system(size: 12))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                }

                HStack(spacing: 4) {
                    // Role indicator dot
                    if let role = thread.lastMessageRole {
                        Circle()
                            .fill(role == .user
                                  ? DevineTheme.Colors.ctaPrimary
                                  : DevineTheme.Colors.textMuted.opacity(0.5))
                            .frame(width: 5, height: 5)
                    }

                    Text(thread.lastMessagePreview)
                        .font(.system(size: 13))
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textMuted.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DevineTheme.Radius.lg, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
        )
    }
}

// MARK: - Date relative formatting helper

private extension Date {
    /// Short relative string: "now", "2m", "1h", "Mon", "Jan 5"
    var relativeShort: String {
        let diff = Date.now.timeIntervalSince(self)
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(Int(diff / 60))m" }
        if diff < 86400 { return "\(Int(diff / 3600))h" }
        if diff < 604800 {
            return formatted(.dateTime.weekday(.abbreviated))
        }
        return formatted(.dateTime.month(.abbreviated).day())
    }
}
