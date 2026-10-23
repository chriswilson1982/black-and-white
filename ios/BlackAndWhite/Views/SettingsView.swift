import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var draft: GameSettings
    private let onSave: (GameSettings) -> Void

    init(settings: GameSettings, onSave: @escaping (GameSettings) -> Void) {
        _draft = State(initialValue: settings)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $draft.username)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                } header: {
                    Text("Player name")
                } footer: {
                    Text("Used on the high score table.")
                }

                Section {
                    Picker("Difficulty", selection: $draft.difficulty) {
                        ForEach(Difficulty.allCases) { level in
                            Text(level.name).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Difficulty")
                } footer: {
                    Text(difficultySummary)
                }

                Section {
                    Picker("Appearance", selection: $draft.appearance) {
                        ForEach(ColorTheme.allCases) { option in
                            Text(option.name).tag(option)
                        }
                    }
                    if draft.appearance == .custom {
                        ColorPicker("Background", selection: colorBinding(\.background), supportsOpacity: false)
                        Picker("Text and icons", selection: $draft.whiteText) {
                            Text("Black").tag(false)
                            Text("White").tag(true)
                        }
                    }
                    ColorPicker("Locked squares", selection: colorBinding(\.lockColor), supportsOpacity: false)
                    ColorPicker("Path", selection: colorBinding(\.pathColor), supportsOpacity: false)
                    ThemePreview(settings: resolvedDraft)
                    Button("Restore default colours") { draft.resetColors() }
                } header: {
                    Text("Colours")
                }

                Section {
                    Toggle("Sound effects", isOn: $draft.soundEnabled)
                } footer: {
                    Text("Closing settings starts a new game.")
                }

                Section {
                    NavigationLink("Tutorial") { TutorialView(settings: resolvedDraft) }
                    NavigationLink("How to play") { HelpView() }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var saved = draft
                        let name = saved.username.trimmingCharacters(in: .whitespacesAndNewlines)
                        saved.username = name.isEmpty ? "Player" : String(name.prefix(20))
                        saved.hasChosenName = true
                        onSave(saved)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }

    /// The draft as the game will draw it (Automatic follows the current light / dark mode).
    private var resolvedDraft: GameSettings {
        draft.resolved(systemIsDark: colorScheme == .dark)
    }

    private var difficultySummary: String {
        let powerups = draft.difficulty.startingPowerups
        let seconds = Int(draft.difficulty.timeAllowed(level: 1))
        return "Start with \(powerups) of each power-up and \(seconds) seconds on the clock. "
            + "The clock gets quicker every level."
    }

    private func colorBinding(_ keyPath: WritableKeyPath<GameSettings, RGBA>) -> Binding<Color> {
        Binding(
            get: { draft[keyPath: keyPath].color },
            set: { draft[keyPath: keyPath] = RGBA($0) }
        )
    }
}

/// A small sample of the grid in the chosen colours.
private struct ThemePreview: View {
    let settings: GameSettings

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 0) {
                swatch(.black)
                swatch(.white.opacity(0.8))
                swatch(settings.lockColor.color)
                swatch(settings.pathColor.color)
                swatch(settings.pathColor.color)
            }
            .overlay(Rectangle().stroke(Color(uiColor: settings.textColor), lineWidth: 1))
            Spacer()
            Text("black ").font(.system(size: 17, weight: .light))
                + Text("&").font(.system(size: 17, weight: .bold))
                + Text(" white").font(.system(size: 17, weight: .light))
        }
        .foregroundStyle(Color(uiColor: settings.textColor))
        .padding(12)
        .background(settings.background.color, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true)
    }

    private func swatch(_ color: Color) -> some View {
        Rectangle().fill(color).frame(width: 24, height: 24)
    }
}
