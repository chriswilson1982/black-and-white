import Foundation
import Observation

struct ScoreEntry: Codable, Identifiable {
    var id = UUID()
    let name: String
    let score: Int
    let date: Date
    let difficulty: Difficulty
}

struct LeaderboardRow: Identifiable {
    let name: String
    let score: Int
    var id: String { name }
}

enum HighScoreResult {
    case champion
    case personalBest
}

/// Local high score table, one per difficulty. Replaces the original SQLite database.
@Observable
final class HighScoreStore {
    private(set) var entries: [ScoreEntry] = []

    private let fileURL: URL

    init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("scores.json")
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([ScoreEntry].self, from: data) {
            entries = saved
        }
    }

    /// Saves a finished game's score. Scores of zero or less are not recorded.
    /// Returns whether it is a new overall or personal best.
    @discardableResult
    func record(name: String, score: Int, difficulty: Difficulty) -> HighScoreResult? {
        guard score > 0 else { return nil }
        let sameLevel = entries.filter { $0.difficulty == difficulty }
        let best = sameLevel.map(\.score).max() ?? 0
        let personal = sameLevel.filter { $0.name == name }.map(\.score).max() ?? 0

        entries.append(ScoreEntry(name: name, score: score, date: Date(), difficulty: difficulty))
        save()

        if score > best { return .champion }
        if score > personal { return .personalBest }
        return nil
    }

    /// Best score for each player, highest first.
    func leaderboard(for difficulty: Difficulty) -> [LeaderboardRow] {
        var best: [String: ScoreEntry] = [:]
        for entry in entries where entry.difficulty == difficulty {
            if let current = best[entry.name], current.score >= entry.score { continue }
            best[entry.name] = entry
        }
        return best.values
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.date < $1.date }
            .map { LeaderboardRow(name: $0.name, score: $0.score) }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
