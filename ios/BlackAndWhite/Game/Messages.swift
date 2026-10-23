import Foundation

/// In-game messages, carried over from the original config.ini.
enum Messages {
    static let win = [
        "Well done!", "Nice one!", "Keep going!", "Excellent!", "More points!",
        "Ready for another?", "Good work!", "Congratulations!", "Good!",
    ]
    static let fail = [
        "Poor show!", "Failure!", "Rubbish!", "Not so good!", "All things come to an end!",
        "Better luck next time!", "Try harder!", "Game over!", "Unlucky or unskilled?",
        "Embarrassing!", "Stop trying to win and win!",
    ]
    static let zero = [
        "Pointless!", "Zero score!", "Sweet nothing!", "Exactly zero? Wow!", "Big fat nothing!", "Zero!",
    ]
    static let negative = [
        "You lost points!", "You're going backwards!", "A higher score is better!",
        "Going down?", "That's not sustainable!",
    ]
    static let noWhite = ["White square bonus!"]
    static let reward = ["Power-up bonus!"]
    static let punishment = [
        "Time for a tiny grid!", "Small and tricky!", "Time for 4x4 action!", "Small but beautiful",
    ]
    static let hurry = ["Hurry up!", "The clock is ticking!", "There's not much time!", "Don't panic!"]
    static let zeroFail = ["Finish where you started", "You finish with nothing!"]
    static let negativeFail = ["We don't record negative scores", "Why did you even bother?"]
    static let quickFail = ["Fell at the first hurdle", "Quickest fail ever!"]

    static func pick(_ list: [String]) -> String {
        list.randomElement() ?? ""
    }
}
