import SwiftUI

struct HighScoresView: View {
    let store: HighScoreStore
    @State private var difficulty: Difficulty
    @Environment(\.dismiss) private var dismiss

    init(store: HighScoreStore, difficulty: Difficulty) {
        self.store = store
        _difficulty = State(initialValue: difficulty)
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
