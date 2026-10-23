import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var coordinator = GameCoordinator()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(uiColor: coordinator.settings.background.uiColor)
                if let scene = coordinator.scene {
                    SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                }
            }
            .ignoresSafeArea()
            .onAppear {
                let insets = proxy.safeAreaInsets
                let fullSize = CGSize(width: proxy.size.width + insets.leading + insets.trailing,
                                      height: proxy.size.height + insets.top + insets.bottom)
                coordinator.prepareScene(size: fullSize, insets: UIEdgeInsets(insets))
            }
            .onChange(of: proxy.safeAreaInsets) { _, newInsets in
                coordinator.scene?.safeInsets = UIEdgeInsets(newInsets)
            }
            .alert("Start again?", isPresented: $coordinator.confirmingRestart) {
                Button("Restart", role: .destructive) { coordinator.restartConfirmed() }
                Button("Cancel", role: .cancel) { coordinator.restartCancelled() }
            } message: {
                Text("Your score will be reset to zero!")
            }
        }
        .statusBarHidden()
        .sheet(item: $coordinator.activeSheet, onDismiss: { coordinator.sheetDismissed() }) { sheet in
            switch sheet {
            case .settings:
                SettingsView(settings: coordinator.settings) { coordinator.pendingSettings = $0 }
            case .highScores:
                HighScoresView(store: coordinator.scores, difficulty: coordinator.settings.difficulty)
            }
        }
        .alert(coordinator.announcement?.title ?? "",
               isPresented: Binding(get: { coordinator.announcement != nil },
                                    set: { if !$0 { coordinator.announcement = nil } }),
               presenting: coordinator.announcement) { _ in
            Button("OK") {}
        } message: { announcement in
            Text(announcement.message)
        }
        .background {
            Color.clear
                .alert("Enter your name", isPresented: $coordinator.askingForName) {
                    TextField("Name", text: $coordinator.nameDraft)
                        .textInputAutocapitalization(.words)
                    Button("OK") { coordinator.saveName() }
                } message: {
                    Text("This will be used on the high score leaderboard!")
                }
        }
    }
}

private extension UIEdgeInsets {
    init(_ insets: EdgeInsets) {
        self.init(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing)
    }
}
