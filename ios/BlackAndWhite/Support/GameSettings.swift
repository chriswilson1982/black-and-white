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
