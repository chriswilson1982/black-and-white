# Black & White for iOS (SpriteKit)

A native iOS version of the Pythonista game in the root of this repository, rebuilt with SpriteKit for the game and SwiftUI for the menus.

## Running it

1. Open `ios/BlackAndWhite.xcodeproj` in **Xcode 16 or later**.
2. Select the **BlackAndWhite** target → *Signing & Capabilities* and choose your team (or change the bundle identifier `com.chriswilson.blackandwhite`).
3. Pick an iPhone or iPad simulator or device and press **Run**.

Requires iOS 17. The game runs in portrait on iPhone and iPad.

Run the unit tests with **Product → Test** (⌘U). They cover the grid rules, scoring and the solver (`BlackAndWhiteTests/BoardTests.swift`).

## Tutorial

On first launch, a short guided tutorial (`Views/TutorialView.swift`) runs before the first game. It uses a 4×4 practice grid where the player makes one real move and tests the path, then covers scoring, power-ups and the timer. The game's clock waits until the tutorial and the name prompt are done. It can be replayed from **Settings → Tutorial**.

## Every grid can be won

When a round starts, the game checks that the grid can be won with normal taps alone (no power-ups) and re-rolls it if not. The check lives in `Board.solve()`:

- Squares on the winning path are never tapped, so each one is flipped once by every tapped neighbour, in any order.
- That turns "is there a path?" into a small set of XOR (GF(2)) equations. These are solved as a depth-first search builds the path out from the start square.
- The search has a step budget. A grid that runs out of budget counts as unproven and is re-rolled too (about 3% of the largest grids). That keeps the check to a few milliseconds.

## Game Center

There is one Game Center leaderboard per difficulty. Scores are submitted when a game ends with a score above zero, the same rule as the local high score table. The high scores screen has a **Game Center leaderboard** button once the player is signed in. On first launch, the player's Game Center nickname is suggested as their name.

Leaderboard IDs (set in `Support/GameCenter.swift`):

| Difficulty | Leaderboard ID |
| --- | --- |
| Easy | `com.chriswilson.blackandwhite.easy` |
| Regular | `com.chriswilson.blackandwhite.regular` |
| Hard | `com.chriswilson.blackandwhite.hard` |

### Setup in App Store Connect / developer account

1. **App ID:** in *Certificates, Identifiers & Profiles*, make sure the app's identifier (`com.chriswilson.blackandwhite`, or your own) has **Game Center** enabled. With automatic signing, Xcode usually does this when it sees the entitlement in `BlackAndWhite.entitlements`. If you change the bundle ID, change it in the build settings too.
2. **App record:** create the app in App Store Connect with that bundle ID.
3. **Enable Game Center:** in the app's *Services* tab (older layouts: the version page's *Game Center* section), turn on Game Center.
4. **Create three leaderboards** under *Services → Game Center → Leaderboards*. For each one:
   - Type **Classic**, Leaderboard ID exactly as in the table above.
   - Score format **Integer**, sort **High to Low**, submission type **Best Score**.
   - Optional score range: minimum 1.
   - Add at least one localization (e.g. English: "Easy", "Regular", "Hard"; format "1 point / 2 points"), plus an optional 512×512 image.
5. **Attach to the version:** in the app version's *Game Center* section, add all three leaderboards so they ship with that version. Leaderboards that are live can't be deleted, and their IDs can't be reused.
6. **Testing:** leaderboards work in development builds and on TestFlight before release. Sign in to Game Center on the test device (Settings → Game Center). In the Simulator you can sign in with a sandbox account, or Game Center simply stays off.

If you use different leaderboard IDs, update `GameCenter.leaderboardID(for:)` to match.

## How it maps to the Python version

| Python (Pythonista) | Swift |
| --- | --- |
| `black_white.py` – `Game(Scene)` | `Game/GameScene.swift` |
| Grid rules, path check, scoring | `Game/Board.swift` (no UI code) |
| `square.py`, `powerup.py`, timer drawing | `Game/Nodes.swift` |
| `config.ini` messages | `Game/Messages.swift` |
| `config.ini` settings + `configuration.py` | `Support/GameSettings.swift` (saved in UserDefaults) |
| `database.py` (SQLite) | `Support/HighScoreStore.swift` (JSON file) + `Support/GameCenter.swift` |
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
