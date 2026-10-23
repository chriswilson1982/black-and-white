# Black & White for iOS (SpriteKit)

A native iOS version of the Pythonista game in the root of this repository, rebuilt with SpriteKit for the game and SwiftUI for the menus.

## Running it

1. Open `ios/BlackAndWhite.xcodeproj` in **Xcode 16 or later**.
2. Select the **BlackAndWhite** target → *Signing & Capabilities* and choose your team (or change the bundle identifier `com.chriswilson.blackandwhite`).
3. Pick an iPhone or iPad simulator or device and press **Run**.

Requires iOS 17. The game runs in portrait on iPhone and iPad.

## How it maps to the Python version

| Python (Pythonista) | Swift |
| --- | --- |
| `black_white.py` – `Game(Scene)` | `Game/GameScene.swift` |
| Grid rules, path check, scoring | `Game/Board.swift` (no UI code) |
| `square.py`, `powerup.py`, timer drawing | `Game/Nodes.swift` |
| `config.ini` messages | `Game/Messages.swift` |
| `config.ini` settings + `configuration.py` | `Support/GameSettings.swift` (saved in UserDefaults) |
| `database.py` (SQLite) | `Support/HighScoreStore.swift` (JSON file) |
| `ui/settings.pyui` | `Views/SettingsView.swift` |
| `ui/highscores.pyui` | `Views/HighScoresView.swift` |
| `html/info.html` | `Views/HelpView.swift` |

## Differences from the original

- **Sounds**: Pythonista's built-in sound effects aren't available on iOS, so `Support/SoundEngine.swift` generates similar retro tones at launch. Swap in real audio files there if you prefer. Sounds respect the silent switch and can be turned off in Settings.
- **Icons**: SF Symbols replace the Pythonista icon set.
- **Colours**: the settings screen uses the system colour picker instead of RGB sliders.
- **Haptics**: light taps on moves, and success/error feedback at the end of a round.
- **After a round**, either the timer or the centre button moves you on.
- Small fixes: the first level is "Level 1" (the original sometimes showed "Level 0"), and the no-white-squares bonus is worked out when you commit rather than whenever whites happen to hit zero.
- High scores are stored per device; scores from the Python version's `db/scores.db` are not imported.
