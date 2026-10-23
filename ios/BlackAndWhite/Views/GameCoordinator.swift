import Observation
import SwiftUI
import UIKit

/// Connects the SpriteKit scene to the SwiftUI screens (settings, high scores, alerts).
@Observable
final class GameCoordinator: GameSceneDelegate {
    enum Sheet: String, Identifiable {
        case settings, highScores
        var id: String { rawValue }
    }

    struct Announcement: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    var settings: GameSettings
    let scores = HighScoreStore()
    var scene: GameScene?

    var activeSheet: Sheet?
    var confirmingRestart = false
    var announcement: Announcement?
    var askingForName = false
    var nameDraft = ""
    /// True once the player is signed in to Game Center.
    var gameCenterReady = false

    /// Settings chosen on the settings screen, applied once it has closed.
    @ObservationIgnored var pendingSettings: GameSettings?
    @ObservationIgnored private var presentedSheet: Sheet?
    @ObservationIgnored private var gameCenterStarted = false
    @ObservationIgnored private var gameCenterAnswered = false
    @ObservationIgnored private var heldForSignIn = false
    @ObservationIgnored private var namePromptDone = false

    init() {
        settings = GameSettings.load()
        SoundEngine.shared.enabled = settings.soundEnabled
    }

    func prepareScene(size: CGSize, insets: UIEdgeInsets) {
        guard scene == nil, size.width > 0, size.height > 0 else { return }
        let newScene = GameScene(size: size, settings: settings, safeInsets: insets)
        newScene.gameDelegate = self
        scene = newScene

        // First launch: hold the clock and ask for a name once Game Center has signed in
        // (so the Game Center nickname can be suggested).
        if settings.hasChosenName {
            namePromptDone = true
        } else {
            newScene.setHeld(true)
            // In case Game Center never answers.
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                guard let self = self, !self.gameCenterAnswered else { return }
                self.askForNameIfNeeded(suggestion: nil)
            }
        }
        startGameCenter()
    }

    private func startGameCenter() {
        guard !gameCenterStarted else { return }
        gameCenterStarted = true
        let gameCenter = GameCenter.shared
        gameCenter.onPresentingSignIn = { [weak self] in
            guard let self = self else { return }
            self.gameCenterAnswered = true
            if self.namePromptDone {
                self.heldForSignIn = true
                self.scene?.setHeld(true)
            }
        }
        gameCenter.onAuthenticationFinished = { [weak self] authenticated, alias in
            guard let self = self else { return }
            self.gameCenterAnswered = true
            self.gameCenterReady = authenticated
            if self.heldForSignIn {
                self.heldForSignIn = false
                if self.activeSheet == nil && !self.confirmingRestart {
                    self.scene?.setHeld(false)
                }
            }
            self.askForNameIfNeeded(suggestion: alias)
        }
        gameCenter.authenticate()
    }

    private func askForNameIfNeeded(suggestion: String?) {
        guard !namePromptDone else { return }
        namePromptDone = true
        nameDraft = suggestion ?? ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.askingForName = true
        }
    }

    func showGameCenterLeaderboard(for difficulty: Difficulty) {
        GameCenter.shared.showLeaderboard(for: difficulty)
    }

    func saveName() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.username = trimmed.isEmpty ? "Player" : String(trimmed.prefix(20))
        settings.hasChosenName = true
        settings.save()
        scene?.setHeld(false)
    }

    func sheetDismissed() {
        guard let sheet = presentedSheet else { return }
        presentedSheet = nil
        switch sheet {
        case .settings:
            // As in the original, leaving settings always starts a fresh game.
            if let newSettings = pendingSettings {
                pendingSettings = nil
                settings = newSettings
                settings.save()
                SoundEngine.shared.enabled = newSettings.soundEnabled
                scene?.apply(settings: newSettings)
            } else {
                scene?.startNewGame()
            }
        case .highScores:
            break
        }
        scene?.setHeld(false)
    }

    func restartConfirmed() {
        scene?.confirmRestart()
    }

    func restartCancelled() {
        scene?.setHeld(false)
    }

    // MARK: GameSceneDelegate

    func gameSceneWantsSettings(_ scene: GameScene) {
        presentedSheet = .settings
        activeSheet = .settings
    }

    func gameSceneWantsHighScores(_ scene: GameScene) {
        presentedSheet = .highScores
        activeSheet = .highScores
    }

    func gameSceneWantsRestartConfirmation(_ scene: GameScene) {
        confirmingRestart = true
    }

    func gameScene(_ scene: GameScene, didEndGameWithScore score: Int) {
        GameCenter.shared.submit(score: score, difficulty: settings.difficulty)
        let name = settings.username
        guard let result = scores.record(name: name, score: score, difficulty: settings.difficulty) else { return }
        let announcement: Announcement
        switch result {
        case .champion:
            announcement = Announcement(title: "New High Score!",
                                        message: "Well done \(name)!\n\nYou are the new champion with a score of \(score).")
        case .personalBest:
            announcement = Announcement(title: "New Personal Best!",
                                        message: "Well done \(name)!\n\nYour top score is \(score).")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            SoundEngine.shared.play(.starBonus)
            self?.announcement = announcement
        }
    }
}
