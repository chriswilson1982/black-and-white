import SwiftUI
import UIKit

/// A short guided tutorial on a small practice grid, shown on first launch and from Settings.
/// The player makes one real move, tests the path, then sees how scoring, power-ups and the timer work.
struct TutorialView: View {
    let settings: GameSettings
    /// Called when the tutorial ends. If nil, the view dismisses itself (when pushed from Settings).
    var onFinish: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    private enum Step: Int, CaseIterable {
        case goal, tap, commit, scored, powerups, ready
    }

    @State private var step: Step = .goal
    @State private var board = TutorialView.makeBoard()
    @State private var spins: [GridPoint: Double] = [:]
    @State private var path: Set<GridPoint> = []
    @State private var result: RoundResult?
    @State private var pulse = false
    @State private var hint: String?
    @State private var committing = false

    /// One tap here clears row 1: the path then scores 5 - 3 leftover whites - 1 locked = 1 point.
    private static let target = GridPoint(row: 0, col: 1)

    private static func makeBoard() -> Board {
        let rows = ["WBWB", "BBBW", "BWBB", "WBWW"]
        let tones = rows.flatMap { row in row.map { $0 == "B" ? Tone.black : Tone.white } }
        return Board(rows: 4, cols: 4, startRow: 1, finishRow: 1, tones: tones)
    }

    private var textColor: Color { Color(uiColor: settings.textColor) }
    private var backgroundColor: Color { settings.background.color }
    private var pathColor: Color { settings.pathColor.color }
    private var lockColor: Color { settings.lockColor.color }

    var body: some View {
        VStack(spacing: 20) {
            header

            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.title.bold())
                Text(message)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(step)
            .transition(.opacity)

            Spacer(minLength: 0)

            switch step {
            case .goal, .tap, .commit:
                grid
            case .scored:
                VStack(spacing: 24) {
                    grid
                    scoreBreakdown
                }
            case .powerups:
                powerupList
            case .ready:
                Image(systemName: "flag.checkered")
                    .font(.system(size: 80))
            }

            Spacer(minLength: 0)

            footer
        }
        .padding(24)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(textColor)
        .background(backgroundColor.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    // MARK: Text

    private var title: String {
        switch step {
        case .goal: return "Clear a path"
        case .tap: return "Tap to flip"
        case .commit: return "Test your path"
        case .scored: return "Scoring"
        case .powerups: return "Power-ups"
        case .ready: return "You're ready!"
        }
    }

    private var message: String {
        switch step {
        case .goal:
            return "Make an unbroken line of white squares from the start on the left to the finish "
                + "on the right. Squares join through their edges, not their corners."
        case .tap:
            return "Tapping a square locks it, turning it red, and flips the colour of the eight squares "
                + "around it. Tap the highlighted square."
        case .commit:
            return "The path is clear! Tap the check button to test it. This happens automatically "
                + "when the timer runs out."
        case .scored:
            return "Use as many squares as you can in the path and tap as few as possible. "
                + "Score zero or less and the next grid is a tricky 4×4."
        case .powerups:
            return "You start each game with a few of each. Collect stars on your path to earn more."
        case .ready:
            return "The clock gets quicker every level. After each round, tap the timer to carry on. "
                + "You can replay this tutorial from Settings."
        }
    }

    // MARK: Pieces

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(Step.allCases, id: \.rawValue) { s in
                    Circle()
                        .fill(textColor.opacity(s.rawValue <= step.rawValue ? 1 : 0.2))
                        .frame(width: 7, height: 7)
                }
            }
            .accessibilityHidden(true)
            Spacer()
            if step != .ready {
                Button("Skip") { finish() }
                    .font(.body.weight(.semibold))
            }
        }
    }

    private var grid: some View {
        let side: CGFloat = 56
        return HStack(spacing: 0) {
            markerColumn(row: board.startRow, color: pathColor, side: side)
            VStack(spacing: 0) {
                ForEach(0..<board.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<board.cols, id: \.self) { col in
                            cell(GridPoint(row: row, col: col), side: side)
                        }
                    }
                }
            }
            .overlay(Rectangle().stroke(textColor, lineWidth: 1))
            .padding(6)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(textColor, lineWidth: 4))
            markerColumn(row: board.finishRow, color: result?.won == true ? pathColor : .white, side: side)
        }
        .accessibilityElement(children: .contain)
    }

    private func markerColumn(row: Int, color: Color, side: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<board.rows, id: \.self) { r in
                Rectangle()
                    .fill(r == row ? color : Color.clear)
                    .overlay(Rectangle().stroke(r == row ? textColor : Color.clear, lineWidth: 1))
                    .frame(width: side * 0.7, height: side)
            }
        }
        .padding(.vertical, 6)
    }

    private func cell(_ p: GridPoint, side: CGFloat) -> some View {
        let color: Color
        if path.contains(p) {
            color = pathColor
        } else if board.isLocked(p) {
            color = lockColor
        } else if board.tone(at: p) == .black {
            color = .black
        } else {
            color = .white.opacity(0.85)
        }
        let isTarget = step == .tap && p == Self.target

        return Rectangle()
            .fill(color)
            .overlay(Rectangle().stroke(Color.gray.opacity(0.25), lineWidth: 0.5))
            .frame(width: side, height: side)
            .rotation3DEffect(.degrees(spins[p, default: 0]), axis: (x: 0, y: 1, z: 0))
            .overlay {
                if isTarget {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(pathColor, lineWidth: 4)
                        .scaleEffect(pulse ? 0.95 : 0.7)
                        .opacity(pulse ? 1 : 0.4)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { tapped(p) }
            .accessibilityLabel(accessibilityLabel(for: p, isTarget: isTarget))
            .accessibilityAddTraits(.isButton)
    }

    private func accessibilityLabel(for p: GridPoint, isTarget: Bool) -> String {
        let state = path.contains(p) ? "path" : board.isLocked(p) ? "locked"
            : (board.tone(at: p) == .black ? "black" : "white")
        return "Row \(p.row + 1), column \(p.col + 1), \(state)" + (isTarget ? ", tap here" : "")
    }

    private var scoreBreakdown: some View {
        let r = result
        return VStack(alignment: .leading, spacing: 8) {
            scoreRow("+\(r?.pathCount ?? 0)", "squares in the path", color: pathColor)
            scoreRow("−\(r?.leftoverWhites ?? 0)", "white squares left over", color: textColor)
            scoreRow("−\(r?.lockedCount ?? 0)", "locked square", color: lockColor)
            Divider().overlay(textColor)
            scoreRow("\(r?.total ?? 0)", "point this round", color: textColor)
        }
        .frame(maxWidth: 320)
    }

    private func scoreRow(_ value: String, _ label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
                .shadow(color: .black.opacity(color == .white ? 0.6 : 0), radius: 1)
                .frame(width: 56, alignment: .trailing)
            Text(label)
            Spacer()
        }
    }

    private var powerupList: some View {
        VStack(alignment: .leading, spacing: 18) {
            powerupRow("shuffle", "Flip all squares")
            powerupRow("xmark", "Unlock a square you tapped")
            powerupRow("circle.lefthalf.filled", "Flip one square, without its neighbours")
            powerupRow("star.fill", "Get a star into your path for an extra power-up")
        }
        .frame(maxWidth: 360, alignment: .leading)
    }

    private func powerupRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.black)
                .frame(width: 52, height: 34)
                .background(RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.85)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black, lineWidth: 1))
            Text(text)
        }
    }

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 12) {
            if let hint = hint {
                Text(hint)
                    .font(.callout.weight(.semibold))
                    .transition(.opacity)
            }
            switch step {
            case .goal:
                primaryButton("Next") { advance(to: .tap) }
            case .tap:
                Text("Tap the highlighted square")
                    .font(.callout)
                    .opacity(0.7)
                    .frame(height: 50)
            case .commit:
                commitButton
            case .scored:
                primaryButton("Next") { advance(to: .powerups) }
            case .powerups:
                primaryButton("Next") { advance(to: .ready) }
            case .ready:
                primaryButton("Play") { finish() }
            }
        }
    }

    /// Looks like the game's centre button.
    private var commitButton: some View {
        Button(action: commit) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(.black)
                RoundedRectangle(cornerRadius: 5)
                    .fill(pathColor)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(.white, lineWidth: 2))
                    .padding(5)
                Image(systemName: "checkmark")
                    .font(.title2.bold())
                    .foregroundStyle(textColor)
            }
            .frame(width: 96, height: 54)
            .scaleEffect(pulse ? 1.05 : 0.95)
        }
        .disabled(committing)
        .accessibilityLabel("Test the path")
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(backgroundColor)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(RoundedRectangle(cornerRadius: 12).fill(textColor))
        }
    }

    // MARK: Actions

    private func advance(to next: Step) {
        SoundEngine.shared.play(.button)
        withAnimation(.easeInOut(duration: 0.25)) {
            hint = nil
            step = next
        }
    }

    private func tapped(_ p: GridPoint) {
        switch step {
        case .tap:
            break
        case .commit:
            withAnimation { hint = "Now tap the check button below." }
            return
        default:
            return
        }
        guard p == Self.target else {
            SoundEngine.shared.play(.button)
            withAnimation { hint = "Try the highlighted square." }
            return
        }
        let flipped = board.lock(p)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        SoundEngine.shared.play(.tap)
        withAnimation(.easeInOut(duration: 0.35)) {
            hint = nil
            spins[p, default: 0] += 180
            for n in flipped { spins[n, default: 0] += 180 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 0.25)) { step = .commit }
        }
    }

    private func commit() {
        guard !committing else { return }
        committing = true
        hint = nil
        SoundEngine.shared.play(.button)
        let outcome = board.evaluate()
        let stepDelay = 0.08
        for (i, layer) in outcome.pathLayers.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDelay * Double(i)) {
                withAnimation(.easeOut(duration: 0.25)) { path.formUnion(layer) }
            }
        }
        let done = stepDelay * Double(outcome.pathLayers.count) + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + done) {
            result = outcome
            SoundEngine.shared.play(.win)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeInOut(duration: 0.3)) { step = .scored }
        }
    }

    private func finish() {
        SoundEngine.shared.play(.button)
        if let onFinish = onFinish {
            onFinish()
        } else {
            dismiss()
        }
    }
}
