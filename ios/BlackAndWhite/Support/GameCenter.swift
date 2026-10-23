import GameKit
import UIKit

/// Game Center sign-in, score submission and the leaderboard screen.
/// There is one leaderboard per difficulty; their IDs must match App Store Connect.
final class GameCenter: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenter()

    static func leaderboardID(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy: return "com.chriswilson.blackandwhite.easy"
        case .regular: return "com.chriswilson.blackandwhite.regular"
        case .hard: return "com.chriswilson.blackandwhite.hard"
        }
    }

    private(set) var isAuthenticated = false

    /// Called each time sign-in finishes, successfully or not, with the player's Game Center alias.
    var onAuthenticationFinished: ((_ authenticated: Bool, _ alias: String?) -> Void)?
    /// Called when Game Center wants to show its sign-in screen.
    var onPresentingSignIn: (() -> Void)?
    /// Called when the leaderboard screen closes.
    var onLeaderboardClosed: (() -> Void)?

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            if let viewController = viewController {
                self.onPresentingSignIn?()
                Self.topViewController()?.present(viewController, animated: true)
                return
            }
            if let error = error {
                print("Game Center sign-in unavailable: \(error.localizedDescription)")
            }
            let player = GKLocalPlayer.local
            self.isAuthenticated = player.isAuthenticated
            self.onAuthenticationFinished?(player.isAuthenticated,
                                           player.isAuthenticated ? player.alias : nil)
        }
    }

    func submit(score: Int, difficulty: Difficulty) {
        guard isAuthenticated, score > 0 else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [Self.leaderboardID(for: difficulty)]) { error in
            if let error = error {
                print("Game Center score submission failed: \(error.localizedDescription)")
            }
        }
    }

    func showLeaderboard(for difficulty: Difficulty) {
        guard isAuthenticated else { return }
        let viewController = GKGameCenterViewController(leaderboardID: Self.leaderboardID(for: difficulty),
                                                        playerScope: .global, timeScope: .allTime)
        viewController.gameCenterDelegate = self
        Self.topViewController()?.present(viewController, animated: true)
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
        onLeaderboardClosed?()
    }

    /// The view controller currently on screen, including any presented sheet.
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }
}
