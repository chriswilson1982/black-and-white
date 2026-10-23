import SwiftUI

struct HighScoresView: View {
    let store: HighScoreStore
    @State private var difficulty: Difficulty
    @Environment(\.dismiss) private var dismiss
    private let gameCenterAvailable: Bool
    private let onShowGameCenter: (Difficulty) -> Void

    init(store: HighScoreStore, difficulty: Difficulty, gameCenterAvailable: Bool = false,
         onShowGameCenter: @escaping (Difficulty) -> Void = { _ in }) {
        self.store = store
        _difficulty = State(initialValue: difficulty)
        self.gameCenterAvailable = gameCenterAvailable
        self.onShowGameCenter = onShowGameCenter
    }

    private var gameCenterFooter: String {
        "Compare your best \(difficulty.name.lowercased()) score with players everywhere. "
            + "The table below shows scores on this device."
    }

    var body: some View {
        NavigationStack {
            let rows = store.leaderboard(for: difficulty)
            List {
                Section {
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases) { level in
                            Text(level.name).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if gameCenterAvailable {
                    Section {
                        Button {
                            onShowGameCenter(difficulty)
                        } label: {
                            Label("Game Center leaderboard", systemImage: "gamecontroller.fill")
                        }
                    } footer: {
                        Text(gameCenterFooter)
                    }
                }

                if rows.isEmpty {
                    ContentUnavailableView("No scores yet", systemImage: "trophy",
                                           description: Text("Finish a game with a score above zero to get on the board."))
                } else {
                    Section {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            HStack {
                                Text("\(index + 1)")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, alignment: .leading)
                                Text(row.name)
                                if index == 0 {
                                    Image(systemName: "crown.fill").foregroundStyle(.yellow)
                                }
                                Spacer()
                                Text("\(row.score)")
                                    .monospacedDigit()
                                    .bold()
                            }
                        }
                    }
                }
            }
            .navigationTitle("High Scores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
