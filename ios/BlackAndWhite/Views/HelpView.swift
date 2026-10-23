import SwiftUI

/// In-game instructions, adapted from the original html/info.html.
struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Black & White is a grid-based puzzle game. Score points by clearing a white path "
                     + "across the grid against the clock.")
                    .font(.title3)

                section("How to play") {
                    Text("Tapping a square locks it and flips the colour of the eight squares around it.")
                    Text("Make an unbroken path of white squares from the start marker on the left to the "
                         + "finish marker on the right. Squares only connect through their edges, not corners.")
                    row("checkmark", "When the path is clear, tap the big button at the bottom to test it. "
                        + "This happens automatically when the time runs out.")
                    row("arrow.clockwise", "The timer is in the bottom right. After a round, tap it to go to "
                        + "the next level, or to start a new game if you failed. It gets quicker every level!")
                    Text("The numbers on the grid show how many black and white squares there are.")
                }

                section("Scoring") {
                    Text("You get a point for every square in the path, and lose a point for every white square "
                         + "left over and every locked square (ones you tapped).")
                    Text("You can score nothing, or even lose points. If that happens, your reward is a tricky "
                         + "4x4 grid in the next level!")
                }

                section("Power-ups") {
                    Text("There are three power-ups at the top of the screen:")
                    row("shuffle", "Flip all squares")
                    row("xmark", "Unlock a tapped square")
                    row("circle.lefthalf.filled", "Flip a single square, without its neighbours")
                    Text("They can be very helpful, but not using them may have other advantages...")
                }

                section("Bonuses") {
                    Text("Leave no white squares outside the path for a bonus. If that round's score is bigger "
                         + "than the number of squares in the grid, you also get extra power-ups.")
                    row("star.fill", "Get a star into your path to earn a power-up. If your power-ups are "
                        + "already full, you get bonus points instead. Tapping the star's square destroys it.")
                }

                section("Settings and high scores") {
                    row("gearshape.fill", "Choose a difficulty (affects the timer and power-ups), set your own "
                        + "colours and change your name. Available at the start of a game or after it ends.")
                    row("trophy.fill", "The high score table, with a separate table for each difficulty.")
                }

                Text("Black & White was created by Chris Wilson, originally in Python using Pythonista.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("How to play")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.title2.bold())
            content()
        }
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 28)
            Text(text)
        }
    }
}
