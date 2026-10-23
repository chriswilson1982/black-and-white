import SwiftUI
import UIKit

/// A colour that can be saved to disk.
struct RGBA: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(_ color: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, &g, &b, &a)
        func clamp(_ v: CGFloat) -> Double { Double(min(max(v, 0), 1)) }
        self.init(clamp(r), clamp(g), clamp(b), clamp(a))
    }

    var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: alpha) }
    var color: Color { Color(uiColor: uiColor) }
}

/// Player settings, saved in UserDefaults.
struct GameSettings: Codable, Equatable {
    var difficulty: Difficulty = .regular
    var username: String = "Player"
    var whiteText: Bool = false
    var background = RGBA(1, 1, 1)
    /// Colour of locked (tapped) squares. "color3" in the original.
    var lockColor = RGBA(1, 0, 0)
    /// Colour of the cleared path. "color4" in the original.
    var pathColor = RGBA(0, 1, 0)
    var soundEnabled = true
    var hasChosenName = false
    var hasSeenTutorial = false

    init() {}

    enum CodingKeys: String, CodingKey {
        case difficulty, username, whiteText, background, lockColor, pathColor
        case soundEnabled, hasChosenName, hasSeenTutorial
    }

    var textColor: UIColor { whiteText ? .white : .black }

    mutating func resetColors() {
        let defaults = GameSettings()
        whiteText = defaults.whiteText
        background = defaults.background
        lockColor = defaults.lockColor
        pathColor = defaults.pathColor
    }

    private static let storageKey = "settings.v1"

    static func load() -> GameSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(GameSettings.self, from: data)
        else { return GameSettings() }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

// Decoding tolerates missing keys, so settings saved by an older version still load
// (any new setting takes its default value).
extension GameSettings {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        difficulty = try c.decodeIfPresent(Difficulty.self, forKey: .difficulty) ?? difficulty
        username = try c.decodeIfPresent(String.self, forKey: .username) ?? username
        whiteText = try c.decodeIfPresent(Bool.self, forKey: .whiteText) ?? whiteText
        background = try c.decodeIfPresent(RGBA.self, forKey: .background) ?? background
        lockColor = try c.decodeIfPresent(RGBA.self, forKey: .lockColor) ?? lockColor
        pathColor = try c.decodeIfPresent(RGBA.self, forKey: .pathColor) ?? pathColor
        soundEnabled = try c.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? soundEnabled
        hasChosenName = try c.decodeIfPresent(Bool.self, forKey: .hasChosenName) ?? hasChosenName
        hasSeenTutorial = try c.decodeIfPresent(Bool.self, forKey: .hasSeenTutorial) ?? hasSeenTutorial
    }
}
