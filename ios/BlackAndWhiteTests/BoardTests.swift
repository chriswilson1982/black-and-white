import Testing
@testable import BlackAndWhite

/// Builds a board from rows of "B" (black) and "W" (white).
private func board(_ rows: [String], start: Int = 0, finish: Int = 0) -> Board {
    let tones = rows.flatMap { row in row.map { $0 == "B" ? Tone.black : Tone.white } }
    return Board(rows: rows.count, cols: rows[0].count, startRow: start, finishRow: finish, tones: tones)
}

private func p(_ row: Int, _ col: Int) -> GridPoint { GridPoint(row: row, col: col) }

@Suite("Moves")
struct MoveTests {
    @Test func lockFlipsAllEightNeighbours() {
        var b = board(["BBB", "BBB", "BBB"])
        let flipped = b.lock(p(1, 1))
        #expect(flipped.count == 8)
        #expect(b.isLocked(p(1, 1)))
        #expect(b.tone(at: p(1, 1)) == .black, "Locked square keeps its colour")
        for q in b.surrounding(p(1, 1)) {
            #expect(b.tone(at: q) == .white)
        }
    }

    @Test func cornerHasThreeNeighbours() {
        var b = board(["WWW", "WWW", "WWW"])
        #expect(b.lock(p(0, 0)).count == 3)
        #expect(b.tone(at: p(2, 2)) == .white)
    }

    @Test func lockedSquaresDoNotFlip() {
        var b = board(["WWW"])
        _ = b.lock(p(0, 0))
        let flipped = b.lock(p(0, 1))
        #expect(flipped == [p(0, 2)])
        #expect(b.tone(at: p(0, 0)) == .white)
        #expect(b.lock(p(0, 1)).isEmpty, "Can't lock twice")
    }

    @Test func unlockRestoresSquare() {
        var b = board(["WB"])
        _ = b.lock(p(0, 0))
        #expect(b.unlock(p(0, 0)))
        #expect(!b.isLocked(p(0, 0)))
        #expect(b.tone(at: p(0, 0)) == .white)
        #expect(!b.unlock(p(0, 0)))
    }

    @Test func flipAllSkipsLockedSquares() {
        var b = board(["WBW"])
        _ = b.lock(p(0, 0))
        let flipped = b.flipAll()
        #expect(Set(flipped) == [p(0, 1), p(0, 2)])
        #expect(b.tone(at: p(0, 0)) == .white)
    }

    @Test func toggleOnlyAffectsOneSquare() {
        var b = board(["BBB"])
        #expect(b.toggle(p(0, 1)))
        #expect(b.cells(of: .white) == [p(0, 1)])
    }

    @Test func lockingTheStarSquareDestroysIt() {
        var b = board(["WW"])
        b.star = p(0, 1)
        _ = b.lock(p(0, 0))
        #expect(b.star == p(0, 1), "Flipping the star square keeps the star")
        _ = b.lock(p(0, 1))
        #expect(b.star == nil)
    }
}

@Suite("Scoring")
struct ScoringTests {
    @Test func straightWhiteRowWins() {
        let r = board(["WWWW", "BBBB"]).evaluate()
        #expect(r.won)
        #expect(r.pathCount == 4)
        #expect(r.leftoverWhites == 0)
        #expect(r.noWhites)
        #expect(r.noWhitesBonus == 2 + 4)
        #expect(r.total == 4 + 6)
    }

    @Test func blackStartSquareLoses() {
        let r = board(["BWWW"]).evaluate()
        #expect(!r.won)
        #expect(r.path.isEmpty)
    }

    @Test func diagonalsDoNotConnect() {
        let r = board(["WB", "BW"], start: 0, finish: 1).evaluate()
        #expect(!r.won)
    }

    @Test func pathFollowsEdgesToAnotherRow() {
        let r = board(["WWB", "BWW"], start: 0, finish: 1).evaluate()
        #expect(r.won)
        #expect(r.pathCount == 4)
    }

    @Test func leftoverWhitesAndLockedSquaresCost() {
        var b = board(["WWWW", "BBBB", "WBBB"])
        _ = b.lock(p(2, 3))   // turns (1,2), (1,3) and (2,2) white; they join the path
        let r = b.evaluate()
        #expect(r.won)
        #expect(r.pathCount == 7)
        #expect(r.leftoverWhites == 1)   // (2,0), cut off by black squares
        #expect(r.lockedCount == 1)
        #expect(!r.noWhites)
        #expect(r.total == 7 - 1 - 1)
    }

    @Test func pathLayersSpreadFromStart() {
        let layers = board(["WWW"]).pathLayers()
        #expect(layers == [[p(0, 0)], [p(0, 1)], [p(0, 2)]])
    }
}

@Suite("Difficulty")
struct DifficultyTests {
    @Test func startingPowerups() {
        #expect(Difficulty.easy.startingPowerups == 6)
        #expect(Difficulty.regular.startingPowerups == 3)
        #expect(Difficulty.hard.startingPowerups == 0)
    }

    @Test func clockShrinksWithLevelButNotBelowFive() {
        #expect(Difficulty.regular.timeAllowed(level: 1) == 40)
        #expect(Difficulty.regular.timeAllowed(level: 2) == 39)
        #expect(Difficulty.hard.timeAllowed(level: 100) == 5)
    }
}

@Suite("Solver")
struct SolverTests {
    /// Applies the solution's taps in the given order and checks the board is won.
    private func check(_ solution: Solution, on original: Board, shuffled: Bool = false) -> Bool {
        var b = original
        let taps = shuffled ? solution.taps.shuffled() : solution.taps
        for tap in taps { _ = b.lock(tap) }
        return b.evaluate().won
    }

    @Test func alreadyWonNeedsNoTaps() throws {
        guard case .solvable(let s) = board(["WWW"]).solve() else {
            Issue.record("Expected solvable")
            return
        }
        #expect(s.taps.isEmpty)
    }

    @Test func singleBlackSquareCannotBeFixed() {
        guard case .unsolvable = board(["B"]).solve() else {
            Issue.record("Expected unsolvable")
            return
        }
    }

    @Test func singleRowWithABlackSquareIsUnsolvable() {
        // Every square must be on the path, so nothing can be tapped.
        guard case .unsolvable = board(["WBW"]).solve() else {
            Issue.record("Expected unsolvable")
            return
        }
    }

    @Test func tapBelowClearsTopRow() {
        let b = board(["BB", "BB"])
        guard case .solvable(let s) = b.solve() else {
            Issue.record("Expected solvable")
            return
        }
        #expect(s.taps.count == 1)
        #expect(check(s, on: b))
    }

    @Test(arguments: [false, true])
    func solutionsWinOnRandomBoards(punishment: Bool) {
        var solved = 0
        for _ in 0..<200 {
            let b = Board.random(punishment: punishment)
            if case .solvable(let s) = b.solve() {
                solved += 1
                #expect(check(s, on: b), "Taps should win in the given order")
                #expect(check(s, on: b, shuffled: true), "Tap order shouldn't matter for the path")
                #expect(s.path.first == b.startPoint)
                #expect(s.path.last == b.finishPoint)
                #expect(Set(s.taps).isDisjoint(with: s.path))
            }
        }
        #expect(solved > 150, "Almost all random boards should be solvable")
    }

    @Test func randomSolvableBoardsAreSolvable() {
        for _ in 0..<50 {
            guard case .solvable = Board.randomSolvable(punishment: false).solve() else {
                Issue.record("randomSolvable returned a board that isn't provably solvable")
                return
            }
        }
    }
}
