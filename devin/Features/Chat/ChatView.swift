import Combine
import SwiftUI

// MARK: - ChatViewModel

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isStreaming = false
    @Published var shareStats = false
    @Published var errorToast: String?
    @Published var applyingMessageID: UUID?

    private let service = DevineChatService()
    private var streamingID: UUID?

    let threadID: UUID
    private let coordinator: ChatCoordinator

    init(threadID: UUID, coordinator: ChatCoordinator) {
        self.threadID = threadID
        self.coordinator = coordinator
        self.messages = coordinator.loadMessages(for: threadID)
    }

    func initializeIfNeeded(name: String, goalLabel: String) {
        guard messages.isEmpty else { return }
        let welcome = ChatMessage(
            role: .assistant,
            content: "hey \(name)! 👋 I'm your Devine AI glow coach. I'm here to help you with your \(goalLabel.lowercased()) journey — ask me anything about your routine, plan, score, or habits. Let's glow! ✨"
        )
        messages.append(welcome)
        coordinator.saveMessages(messages, for: threadID)
    }

    func send(text: String, stats: ChatStats?) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }

        let userMsg = ChatMessage(role: .user, content: trimmed, attachedStats: shareStats && stats != nil)
        messages.append(userMsg)
        inputText = ""

        let aiID = UUID()
        streamingID = aiID
        messages.append(ChatMessage(id: aiID, role: .assistant, content: "", isStreaming: true))
        isStreaming = true
        errorToast = nil

        do {
            let statsToUse = shareStats ? stats : nil
            let history = Array(messages.dropLast())
            for try await chunk in service.sendMessage(text: trimmed, history: history, stats: statsToUse) {
                guard let idx = messages.firstIndex(where: { $0.id == aiID }) else { break }
                messages[idx].content += chunk
            }
            finalize(messageID: aiID)
        } catch {
            if let idx = messages.firstIndex(where: { $0.id == aiID }) {
                messages[idx].content = "Something went wrong — please try again ✨"
                messages[idx].isStreaming = false
            }
            errorToast = error.localizedDescription
            isStreaming = false
        }
    }

    func applyProposal(messageID: UUID, model: DevineAppModel) async {
        guard let idx = messages.firstIndex(where: { $0.id == messageID }),
              let proposal = messages[idx].planProposal,
              !proposal.isApplied else { return }

        applyingMessageID = messageID
        do {
            try await model.applyCoachPlanAdjustment(
                reason: proposal.reason,
                suggestedFocus: proposal.suggestedFocus,
                severity: proposal.severity
            )
            if let i = messages.firstIndex(where: { $0.id == messageID }) {
                messages[i].planProposal?.isApplied = true
                coordinator.markProposalApplied(threadID: threadID, messageID: messageID)
            }
            let confirmMsg = ChatMessage(
                role: .assistant,
                content: "Done! Your plan has been updated with the new focus — your upcoming days now reflect this change. Keep building on it ✨"
            )
            messages.append(confirmMsg)
            coordinator.saveMessages(messages, for: threadID)
            DevineHaptic.allActionsComplete.fire()
        } catch {
            errorToast = "Couldn't update plan — please try again"
        }
        applyingMessageID = nil
    }

    // MARK: Private

    private func finalize(messageID: UUID) {
        guard let idx = messages.firstIndex(where: { $0.id == messageID }) else {
            isStreaming = false
            return
        }
        let (clean, proposal) = service.extractProposal(from: messages[idx].content)
        messages[idx].content = clean
        messages[idx].planProposal = proposal
        messages[idx].isStreaming = false
        isStreaming = false
        streamingID = nil

        // Persist immediately after every finalized AI response
        coordinator.saveMessages(messages, for: threadID)
    }
}

// MARK: - ChatView

struct ChatView: View {
    @ObservedObject var coordinator: ChatCoordinator
    @ObservedObject var model: DevineAppModel
    let threadID: UUID

    @StateObject private var vm: ChatViewModel
    @FocusState private var inputFocused: Bool
    @FocusState private var titleFocused: Bool
    @State private var isRenamingTitle = false
    @State private var titleDraft = ""

    init(threadID: UUID, coordinator: ChatCoordinator, model: DevineAppModel) {
        self.threadID = threadID
        self.coordinator = coordinator
        self.model = model
        _vm = StateObject(wrappedValue: ChatViewModel(threadID: threadID, coordinator: coordinator))
    }

    private var chatStats: ChatStats { model.chatStats }

    private var threadTitle: String {
        coordinator.threads.first { $0.id == threadID }?.title ?? "Coach"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            DevineTheme.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                chatHeader
                Divider().opacity(0.3)

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            if vm.messages.isEmpty {
                                emptyState
                            } else {
                                ForEach(vm.messages) { msg in
                                    MessageRow(
                                        message: msg,
                                        isApplyingProposal: vm.applyingMessageID == msg.id,
                                        onApplyProposal: { Task { await vm.applyProposal(messageID: msg.id, model: model) } }
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                }
                            }
                            Color.clear.frame(height: 16).id("bottom")
                        }
                        .padding(.bottom, 8)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: vm.messages.count) {
                        withAnimation(DevineTheme.Motion.quick) { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                    .onChange(of: vm.messages.last?.content) {
                        withAnimation(.linear(duration: 0.1)) { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }

                inputBar
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            let name = model.userProfile?.name ?? "there"
            let goalLabel = model.chatStats.goalLabel
            vm.initializeIfNeeded(name: name, goalLabel: goalLabel)
        }
        .overlay(alignment: .top) {
            if let toast = vm.errorToast {
                ToastBanner(message: toast) { vm.errorToast = nil }
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(DevineTheme.Motion.standard, value: vm.errorToast != nil)
    }

    // MARK: Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(DevineTheme.Colors.ctaPrimary.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("✦")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.ctaPrimary)
            }

            // Thread title — tap to rename
            if isRenamingTitle {
                TextField("Thread title", text: $titleDraft)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)
                    .focused($titleFocused)
                    .submitLabel(.done)
                    .onSubmit { commitRename() }
                    .onAppear { titleFocused = true }
            } else {
                Button {
                    titleDraft = threadTitle
                    isRenamingTitle = true
                } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(threadTitle)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(DevineTheme.Colors.textPrimary)
                            .lineLimit(1)
                        Text("your glow coach")
                            .font(.system(size: 11))
                            .foregroundStyle(DevineTheme.Colors.textMuted)
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if isRenamingTitle {
                Button("Done") { commitRename() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.ctaPrimary)
            } else {
                // Status indicator
                HStack(spacing: 5) {
                    Circle()
                        .fill(vm.isStreaming ? DevineTheme.Colors.warningAccent : DevineTheme.Colors.successAccent)
                        .frame(width: 6, height: 6)
                        .animation(DevineTheme.Motion.quick, value: vm.isStreaming)
                    Text(vm.isStreaming ? "thinking..." : "ready")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DevineTheme.Colors.textMuted)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DevineTheme.Colors.bgPrimary)
    }

    private func commitRename() {
        let trimmed = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            coordinator.renameThread(threadID, title: trimmed)
        }
        isRenamingTitle = false
        titleFocused = false
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 60)

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(DevineTheme.Colors.ctaPrimary.opacity(0.08))
                        .frame(width: 80, height: 80)
                    Circle()
                        .fill(DevineTheme.Colors.ctaPrimary.opacity(0.12))
                        .frame(width: 60, height: 60)
                    Text("✦")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: DevineTheme.Gradients.primaryCTA,
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 6) {
                    Text("Ask me anything")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(DevineTheme.Colors.textPrimary)
                    Text("I'm your personal AI glow coach —\nspecifically trained for your journey")
                        .font(.system(size: 14))
                        .foregroundStyle(DevineTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }

            // Contextual quick prompts grid
            VStack(spacing: 10) {
                Text("Quick asks")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach(quickPrompts, id: \.self) { prompt in
                        QuickPromptChip(text: prompt) {
                            vm.inputText = prompt
                            Task { await vm.send(text: prompt, stats: chatStats) }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer(minLength: 100)
        }
    }

    // MARK: Quick Prompts

    private var quickPrompts: [String] {
        var prompts: [String] = []
        let goalLabel = chatStats.goalLabel

        if chatStats.completedToday == chatStats.totalToday, chatStats.totalToday > 0 {
            prompts.append("I finished all my tasks today! 🎉")
        }
        if let score = chatStats.glowScore {
            prompts.append("How do I boost my \(score) score?")
        }
        if chatStats.streakDays >= 3 {
            prompts.append("Tips to keep my streak going 🔥")
        } else {
            prompts.append("How do I stay consistent?")
        }
        prompts.append("Best habits for \(goalLabel.lowercased())")
        prompts.append("Adjust my plan focus")
        prompts.append("What should I do today?")

        return Array(prompts.prefix(4))
    }

    // MARK: Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            if !vm.messages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickPrompts, id: \.self) { prompt in
                            QuickPromptChip(text: prompt) {
                                vm.inputText = prompt
                                Task { await vm.send(text: prompt, stats: chatStats) }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(DevineTheme.Colors.bgPrimary)
            }

            Divider().opacity(0.2)

            HStack(alignment: .bottom, spacing: 12) {
                // Stats toggle
                Button {
                    withAnimation(DevineTheme.Motion.quick) { vm.shareStats.toggle() }
                    DevineHaptic.tap.fire()
                } label: {
                    ZStack {
                        Circle()
                            .fill(vm.shareStats
                                  ? DevineTheme.Colors.ctaPrimary.opacity(0.15)
                                  : DevineTheme.Colors.bgSecondary)
                            .frame(width: 40, height: 40)
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(vm.shareStats
                                             ? DevineTheme.Colors.ctaPrimary
                                             : DevineTheme.Colors.textMuted)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if vm.shareStats {
                        Circle()
                            .fill(DevineTheme.Colors.successAccent)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }

                // Text field
                TextField("Ask your coach...", text: $vm.inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.system(size: 15))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)
                    .focused($inputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: DevineTheme.Radius.pill, style: .continuous)
                            .fill(DevineTheme.Colors.bgSecondary)
                    )

                // Send button
                Button {
                    inputFocused = false
                    let text = vm.inputText
                    Task { await vm.send(text: text, stats: chatStats) }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isStreaming
                                ? AnyShapeStyle(DevineTheme.Colors.bgSecondary)
                                : AnyShapeStyle(LinearGradient(
                                    colors: DevineTheme.Gradients.primaryCTA,
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                            )
                            .frame(width: 40, height: 40)
                        Image(systemName: vm.isStreaming ? "stop.fill" : "arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(
                                vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isStreaming
                                ? DevineTheme.Colors.textMuted
                                : Color.white
                            )
                    }
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isStreaming)
                .animation(DevineTheme.Motion.quick, value: vm.inputText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .padding(.bottom, 4)
            .background(DevineTheme.Colors.bgPrimary)

            if vm.shareStats {
                statsContextPill
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(DevineTheme.Motion.quick, value: vm.shareStats)
        .background(DevineTheme.Colors.bgPrimary)
    }

    private var statsContextPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DevineTheme.Colors.ctaPrimary)

            Text("Sharing your stats with the coach")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textSecondary)

            Spacer()

            if let score = chatStats.glowScore {
                Text("\(score) glow · \(chatStats.streakDays)d streak")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.ctaPrimary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous)
                .fill(DevineTheme.Colors.ctaPrimary.opacity(0.08))
        )
    }
}

// MARK: - MessageRow

private struct MessageRow: View {
    let message: ChatMessage
    let isApplyingProposal: Bool
    let onApplyProposal: () -> Void

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 8) {
                if message.role == .assistant {
                    aiAvatar
                }

                if message.role == .user {
                    Spacer(minLength: 60)
                    userBubble
                } else {
                    aiBubble
                    Spacer(minLength: 60)
                }
            }

            if let proposal = message.planProposal {
                PlanProposalCard(proposal: proposal, isApplying: isApplyingProposal, onApply: onApplyProposal)
                    .padding(.leading, message.role == .assistant ? 44 : 0)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(DevineTheme.Motion.expressive, value: message.planProposal != nil)
    }

    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(DevineTheme.Colors.ctaPrimary.opacity(0.12))
                .frame(width: 32, height: 32)
            Text("✦")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DevineTheme.Colors.ctaPrimary)
        }
    }

    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if message.attachedStats {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 9, weight: .semibold))
                    Text("with your stats")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Capsule().fill(DevineTheme.Colors.ctaPrimary.opacity(0.3)))
            }

            Text(message.content)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: DevineTheme.Gradients.primaryCTA,
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(ChatBubbleShape(isUser: true))
        }
    }

    @ViewBuilder
    private func formattedAIText(_ content: String) -> some View {
        if let attributed = try? AttributedString(
            markdown: content,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attributed)
        } else {
            Text(content)
        }
    }

    private var aiBubble: some View {
        Group {
            if message.isStreaming && message.content.isEmpty {
                TypingDots()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(DevineTheme.Colors.surfaceCard)
                    .clipShape(ChatBubbleShape(isUser: false))
            } else {
                formattedAIText(message.content)
                    .font(.system(size: 15))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(DevineTheme.Colors.surfaceCard)
                    .clipShape(ChatBubbleShape(isUser: false))
            }
        }
    }
}

// MARK: - Plan Proposal Card

private struct PlanProposalCard: View {
    let proposal: ChatPlanProposal
    let isApplying: Bool
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(proposal.severity.color)

                Text("Plan suggestion")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)

                Spacer()

                Text(proposal.severity.label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(proposal.severity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(proposal.severity.color.opacity(0.12))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(proposal.reason)
                    .font(.system(size: 13))
                    .foregroundStyle(DevineTheme.Colors.textSecondary)

                Text("→ \(proposal.suggestedFocus)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.textPrimary)
            }

            if proposal.isApplied {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DevineTheme.Colors.successAccent)
                    Text("Applied to your plan")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DevineTheme.Colors.successAccent)
                }
            } else if isApplying {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                    Text("Updating your plan...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    LinearGradient(
                        colors: DevineTheme.Gradients.primaryCTA,
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            } else {
                Button(action: onApply) {
                    Text("Apply to my plan")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            LinearGradient(
                                colors: DevineTheme.Gradients.primaryCTA,
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DevineTheme.Radius.lg, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: DevineTheme.Radius.lg, style: .continuous)
                        .stroke(proposal.severity.color.opacity(0.25), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Quick Prompt Chip

private struct QuickPromptChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textPrimary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous)
                        .fill(DevineTheme.Colors.surfaceCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: DevineTheme.Radius.md, style: .continuous)
                                .stroke(DevineTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Typing Dots

private struct TypingDots: View {
    @State private var phases = [false, false, false]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(DevineTheme.Colors.textMuted)
                    .frame(width: 7, height: 7)
                    .scaleEffect(phases[i] ? 1.0 : 0.5)
                    .opacity(phases[i] ? 1 : 0.4)
            }
        }
        .onAppear {
            for i in 0..<3 {
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.18)
                ) {
                    phases[i] = true
                }
            }
        }
    }
}

// MARK: - Chat Bubble Shape

private struct ChatBubbleShape: Shape {
    let isUser: Bool
    private let radius: CGFloat = DevineTheme.Radius.lg

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, rect.height / 2)
        path.addRoundedRect(
            in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height),
            cornerSize: CGSize(width: r, height: r),
            style: .continuous
        )
        return path
    }
}

// MARK: - Toast Banner

private struct ToastBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DevineTheme.Colors.warningAccent)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DevineTheme.Colors.textPrimary)
                .lineLimit(2)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DevineTheme.Colors.textMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DevineTheme.Radius.lg, style: .continuous)
                .fill(DevineTheme.Colors.surfaceCard)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .padding(.horizontal, 16)
    }
}
