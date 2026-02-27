import SwiftUI

/// Reveals text character by character, like a message being typed in real time.
struct TypewriterText: View {
    let text: String
    var speed: Double = 40   // characters per second
    var font: Font = .body
    var color: Color = DevineTheme.Colors.textPrimary
    var onComplete: (() -> Void)? = nil

    @State private var displayed = ""
    @State private var timer: Timer?

    var body: some View {
        Text(displayed)
            .font(font)
            .foregroundColor(color)
            .onAppear { startTypewriter() }
            .onDisappear { timer?.invalidate() }
    }

    private func startTypewriter() {
        displayed = ""
        timer?.invalidate()

        var index = text.startIndex
        let interval = 1.0 / speed

        let t = Timer(timeInterval: interval, repeats: true) { t in
            if index < text.endIndex {
                displayed.append(text[index])
                index = text.index(after: index)
            } else {
                t.invalidate()
                onComplete?()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}

// MARK: - Multi-message Typewriter

/// Sequences through multiple messages.
/// Completed messages are rendered as static `Text` (never re-animated).
/// Only the current active message uses `TypewriterText`, keyed by index
/// so SwiftUI always creates a fresh view — preventing re-stream on state changes.
struct TypewriterSequence: View {
    struct Message: Identifiable {
        let id = UUID()
        let text: String
        var speed: Double = 40
        var font: Font = .body
        var pauseAfter: Double = 0.6   // seconds before showing next message
    }

    let messages: [Message]
    var color: Color = DevineTheme.Colors.textPrimary
    var onAllComplete: (() -> Void)? = nil

    // Index of the message currently being typed (nil = all done)
    @State private var currentIndex: Int = 0
    // Messages that have already finished typing — shown as static Text
    @State private var completedTexts: [(text: String, font: Font)] = []
    @State private var allDone = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Already-completed messages — static, never re-animated
            ForEach(Array(completedTexts.enumerated()), id: \.offset) { _, entry in
                Text(entry.text)
                    .font(entry.font)
                    .foregroundColor(color)
            }

            // Currently-animating message, keyed by index for fresh view each time
            if !allDone, currentIndex < messages.count {
                let msg = messages[currentIndex]
                TypewriterText(
                    text: msg.text,
                    speed: msg.speed,
                    font: msg.font,
                    color: color
                ) {
                    handleMessageComplete(index: currentIndex)
                }
                .id(currentIndex)   // forces SwiftUI to create a new view per message
            }
        }
        .onAppear {
            // Start with index 0 already set; body renders the first TypewriterText
        }
    }

    private func handleMessageComplete(index: Int) {
        let msg = messages[index]
        let next = index + 1

        DispatchQueue.main.asyncAfter(deadline: .now() + msg.pauseAfter) {
            withAnimation(DevineTheme.Motion.quick) {
                completedTexts.append((text: msg.text, font: msg.font))
            }

            if next < messages.count {
                currentIndex = next
            } else {
                allDone = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onAllComplete?()
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TypewriterText(
            text: "hi, i'm devine ✨",
            speed: 35,
            font: .system(size: 28, weight: .semibold),
            color: .white
        )
        .padding()
    }
}
