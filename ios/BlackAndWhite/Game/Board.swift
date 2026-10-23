import Foundation

/// The colour of an unlocked square.
enum Tone: Equatable {
    case black, white

    var flipped: Tone { self == .black ? .white : .black }
}

/// A cell on the grid. Row 0 is the top row, column 0 is the left column.
struct GridPoint: Hashable {
    var row: Int
    var col: Int
}

enum Difficulty: Int, CaseIterable, Codable, Identifiable {
    case easy = 1, regular = 2, hard = 3

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .easy: return "Easy"
        case .regular: return "Regular"
        case .hard: return "Hard"
        }
    }

    /// Each power-up starts with this many uses at the start of a game.
    var startingPowerups: Int { 9 - 3 * rawValue }

    /// Seconds on the clock. It shrinks each level, down to a floor of 5 seconds.
    func timeAllowed(level: Int) -> TimeInterval {
        let d = Double(rawValue)
        return max(61 - d * 10 - Double(level) * 0.5 * d, 5)
    }
}

/// The outcome of checking the path when the player commits.
struct RoundResult {
    /// White squares reached from the start, grouped by distance (used for the flood animation).
    let pathLayers: [[GridPoint]]
    let path: Set<GridPoint>
    let won: Bool
    /// White squares left over that are not part of the path.
    let leftoverWhites: Int
    let lockedCount: Int
    /// Bonus for leaving no white squares outside the path (rows + columns), otherwise 0.
    let noWhitesBonus: Int

    var pathCount: Int { path.count }
    var noWhites: Bool { noWhitesBonus > 0 }
    /// Points for the round: path squares, plus bonus, minus leftover whites and locked squares.
    var total: Int { pathCount + noWhitesBonus - leftoverWhites - lockedCount }
}

/// Pure game state for one round: the grid of squares, the start and finish rows and the bonus star.
struct Board {
    static let maxPowerups = 9

    let rows: Int
    let cols: Int
    let startRow: Int
    let finishRow: Int
    var star: GridPoint?
    private(set) var tones: [Tone]
    /// A locked square keeps the tone it had when it was tapped, so the unlock power-up can restore it.
    private(set) var locked: [Bool]

    init(rows: Int, cols: Int, startRow: Int, finishRow: Int, tones: [Tone], star: GridPoint? = nil) {
        precondition(tones.count == rows * cols, "Need one tone per square")
        self.rows = rows
        self.cols = cols
        self.startRow = startRow
        self.finishRow = finishRow
        self.tones = tones
        self.locked = Array(repeating: false, count: rows * cols)
        self.star = star
    }

    /// A random grid: 4, 6, 8 or 10 rows and 4 or 6 columns (a 4-row grid always has 6 columns).
    /// A "punishment" grid is a small 4x4 one.
    static func random(punishment: Bool) -> Board {
        let rows: Int
        let cols: Int
        if punishment {
            rows = 4
            cols = 4
        } else {
            rows = [4, 6, 8, 10].randomElement()!
            cols = rows == 4 ? 6 : [4, 6].randomElement()!
        }
        let tones = (0..<rows * cols).map { _ in Bool.random() ? Tone.black : Tone.white }
        var board = Board(rows: rows, cols: cols,
                          startRow: Int.random(in: 0..<rows),
                          finishRow: Int.random(in: 0..<rows),
                          tones: tones)
        if Bool.random() {
            board.star = GridPoint(row: Int.random(in: 0..<rows), col: Int.random(in: 0..<cols))
        }
        return board
    }

    // MARK: Queries

    var allPoints: [GridPoint] {
        var points: [GridPoint] = []
        points.reserveCapacity(rows * cols)
        for row in 0..<rows {
            for col in 0..<cols {
                points.append(GridPoint(row: row, col: col))
            }
        }
        return points
    }

    var startPoint: GridPoint { GridPoint(row: startRow, col: 0) }
    var finishPoint: GridPoint { GridPoint(row: finishRow, col: cols - 1) }

    func contains(_ p: GridPoint) -> Bool {
        p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols
    }

    private func index(_ p: GridPoint) -> Int { p.row * cols + p.col }

    func tone(at p: GridPoint) -> Tone { tones[index(p)] }

    func isLocked(_ p: GridPoint) -> Bool { locked[index(p)] }

    /// Unlocked squares of the given tone.
    func cells(of tone: Tone) -> [GridPoint] {
        allPoints.filter { !isLocked($0) && self.tone(at: $0) == tone }
    }

    var lockedCount: Int { locked.filter { $0 }.count }

    /// The up to eight squares around a point.
    func surrounding(_ p: GridPoint) -> [GridPoint] {
        var result: [GridPoint] = []
        for dr in -1...1 {
            for dc in -1...1 where !(dr == 0 && dc == 0) {
                let n = GridPoint(row: p.row + dr, col: p.col + dc)
                if contains(n) { result.append(n) }
            }
        }
        return result
    }

    /// The up to four squares sharing an edge with a point.
    func adjacent(_ p: GridPoint) -> [GridPoint] {
        [GridPoint(row: p.row - 1, col: p.col),
         GridPoint(row: p.row + 1, col: p.col),
         GridPoint(row: p.row, col: p.col - 1),
         GridPoint(row: p.row, col: p.col + 1)].filter(contains)
    }

    private func isOpenWhite(_ p: GridPoint) -> Bool {
        contains(p) && !isLocked(p) && tone(at: p) == .white
    }

    // MARK: Moves

    /// Flip one square. Locked squares don't change. Returns whether it flipped.
    @discardableResult
    mutating func toggle(_ p: GridPoint) -> Bool {
        guard contains(p), !isLocked(p) else { return false }
        tones[index(p)] = tones[index(p)].flipped
        return true
    }

    /// The main move: lock the tapped square and flip the eight around it.
    /// Locking the star square destroys the star. Returns the squares that flipped.
    mutating func lock(_ p: GridPoint) -> [GridPoint] {
        guard contains(p), !isLocked(p) else { return [] }
        locked[index(p)] = true
        if star == p { star = nil }
        var flipped: [GridPoint] = []
        for n in surrounding(p) where toggle(n) {
            flipped.append(n)
        }
        return flipped
    }

    /// Power-up 2: unlock a locked square, restoring the tone it had when it was tapped.
    @discardableResult
    mutating func unlock(_ p: GridPoint) -> Bool {
        guard contains(p), isLocked(p) else { return false }
        locked[index(p)] = false
        return true
    }

    /// Power-up 1: flip every unlocked square. Returns the squares that flipped.
    mutating func flipAll() -> [GridPoint] {
        var flipped: [GridPoint] = []
        for p in allPoints where toggle(p) {
            flipped.append(p)
        }
        return flipped
    }

    // MARK: Scoring

    /// Flood-fills from the start square through edge-connected white squares.
    func pathLayers() -> [[GridPoint]] {
        let start = startPoint
        guard isOpenWhite(start) else { return [] }
        var seen: Set<GridPoint> = [start]
        var layers: [[GridPoint]] = [[start]]
        var frontier = [start]
        while true {
            var next: [GridPoint] = []
            for p in frontier {
                for n in adjacent(p) where isOpenWhite(n) && !seen.contains(n) {
                    seen.insert(n)
                    next.append(n)
                }
            }
            if next.isEmpty { break }
            layers.append(next)
            frontier = next
        }
        return layers
    }

    func evaluate() -> RoundResult {
        let layers = pathLayers()
        let path = Set(layers.joined())
        let leftover = cells(of: .white).filter { !path.contains($0) }.count
        return RoundResult(
            pathLayers: layers,
            path: path,
            won: path.contains(finishPoint),
            leftoverWhites: leftover,
            lockedCount: lockedCount,
            noWhitesBonus: leftover == 0 ? rows + cols : 0
        )
    }
}
