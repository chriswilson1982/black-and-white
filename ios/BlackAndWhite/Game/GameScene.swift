import CoreMotion
import SpriteKit
import UIKit

protocol GameSceneDelegate: AnyObject {
    func gameSceneWantsSettings(_ scene: GameScene)
    func gameSceneWantsHighScores(_ scene: GameScene)
    func gameSceneWantsRestartConfirmation(_ scene: GameScene)
    func gameScene(_ scene: GameScene, didEndGameWithScore score: Int)
}

/// Drawing order. The scene ignores sibling order, so every node gets an explicit z.
private enum Z {
    static let background: CGFloat = 0
    static let border: CGFloat = 3
    static let barBackdrop: CGFloat = 4
    static let bar: CGFloat = 4.5
    static let square: CGFloat = 5
    static let lockedSquare: CGFloat = 5.5
    static let cross: CGFloat = 6.5
    static let star: CGFloat = 7
    static let counter: CGFloat = 7.5
    static let preview: CGFloat = 7.8
    static let urgency: CGFloat = 7.9
    static let messageBar: CGFloat = 8
    static let message: CGFloat = 9
    static let controls: CGFloat = 10
    static let popup: CGFloat = 20
    static let sparkle: CGFloat = 22
    static let flying: CGFloat = 25
}

final class GameScene: SKScene {
    enum Phase {
        /// Squares are flying into place.
        case dealing
        /// The clock is running.
        case playing
        /// The path is being checked and animated.
        case resolving
        /// Round won; tap the timer or the button for the next level.
        case won
        /// Game over; tap the timer or the button for a new game.
        case lost
    }

    enum Mode {
        case normal
        /// Power-up 2 armed: tap a locked square to unlock it.
        case unlock
        /// Power-up 3 armed: tap a square to flip just that square.
        case flipSingle
    }

    weak var gameDelegate: GameSceneDelegate?

    private(set) var settings: GameSettings

    var safeInsets: UIEdgeInsets {
        didSet {
            let changed = oldValue.top != safeInsets.top || oldValue.bottom != safeInsets.bottom
                || oldValue.left != safeInsets.left || oldValue.right != safeInsets.right
            if changed && isBuilt { relayout() }
        }
    }

    // MARK: Game state

    private var board: Board
    private(set) var phase: Phase = .dealing
    private var mode: Mode = .normal
    private var level = 1
    private var score = 0 {
        didSet { scoreLabel?.text = "\(score)" }
    }
    private var powerupCounts = [0, 0, 0]
    private var punishNext = false
    private var resultPath: Set<GridPoint> = []
    private var resultWon = false
    /// White squares currently connected to the start square (tinted while playing).
    private var livePath: Set<GridPoint> = []
    private var pathReady: Bool { livePath.contains(board.finishPoint) }

    /// Square under the player's finger, previewed until they lift it.
    private var pressedCell: GridPoint?
    private var trackingGrid = false
    private var previewNodes: [SKNode] = []

    private var elapsed: TimeInterval = 0
    private var lastUpdate: TimeInterval?
    private var warned = false
    private var lowTime = false
    private var lastTick: Int?
    /// True while a sheet or alert is covering the game. The clock stops and taps are ignored.
    private var isHeld = false

    private var message = "" {
        didSet {
            guard let label = messageLabel, message != oldValue else { return }
            label.text = message
            guard !Motion.reduced else { return }
            label.removeAction(forKey: "pop")
            label.setScale(1)
            label.run(.sequence([.scale(to: 1.1, duration: 0.07).timing(.easeOut),
                                 .scale(to: 1, duration: 0.12).timing(.easeIn)]), withKey: "pop")
        }
    }

    private var settingsAvailable: Bool {
        phase == .lost || (level == 1 && (phase == .dealing || phase == .playing))
    }

    private var highScoresAvailable: Bool {
        !(phase == .playing && lowTime)
    }

    // MARK: Layout

    private struct Layout {
        var s: CGFloat = 40
        var titleY: CGFloat = 0
        var powerupY: CGFloat = 0
        var messageY: CGFloat = 0
        var bottomY: CGFloat = 0
        var sideButtonInset: CGFloat = 30
        var gridCenter: CGPoint = .zero
    }

    private var layout = Layout()
    private var isBuilt = false

    // MARK: Nodes

    private struct BackgroundSquare {
        let node: SKSpriteNode
        let speed: CGFloat
        let direction: CGFloat
    }

    private var bgSquares: [BackgroundSquare] = []
    private var squares: [GridPoint: SquareNode] = [:]
    private var gridDecor: [SKNode] = []
    private var crosses: [SKNode] = []
    private var starNode: SKSpriteNode?
    private var scorePopup: SKNode?

    private var titleLabel: SKLabelNode!
    private var ampersandLabel: SKLabelNode!
    private var settingsButton: SKSpriteNode!
    private var scoresButton: SKSpriteNode!
    private var powerupNodes: [PowerupNode] = []
    private var messageBar: SKSpriteNode!
    private var messageLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var commitButton: SKNode!
    private var commitInner: SKShapeNode!
    private var commitIcon: SKSpriteNode!
    private var commitSize: CGSize = .zero
    private var timerNode: TimerNode!
    private var blackCounter: SKLabelNode!
    private var whiteCounter: SKLabelNode!
    private var startBar: SKSpriteNode!
    private var startBackdrop: SKSpriteNode!
    private var finishBar: SKSpriteNode!
    private var finishBackdrop: SKSpriteNode!
    /// Red glow around the screen edges during the final countdown.
    private var urgencyFrame: SKShapeNode!

    private let motion = CMMotionManager()
    private let tapHaptic = UIImpactFeedbackGenerator(style: .light)
    private let resultHaptic = UINotificationFeedbackGenerator()
    private let selectionHaptic = UISelectionFeedbackGenerator()

    // MARK: Colours

    private var textColor: UIColor { settings.textColor }
    private var lockColor: UIColor { settings.lockColor.uiColor }
    private var pathColor: UIColor { settings.pathColor.uiColor }
    private var backdropColor: UIColor { settings.background.uiColor }

    // MARK: Init

    init(size: CGSize, settings: GameSettings, safeInsets: UIEdgeInsets) {
        self.settings = settings
        self.safeInsets = safeInsets
        self.board = Board.random(punishment: false)
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didMove(to view: SKView) {
        if motion.isAccelerometerAvailable {
            motion.accelerometerUpdateInterval = 1.0 / 30
            motion.startAccelerometerUpdates()
        }
        guard !isBuilt, size.width > 0 else { return }
        buildChrome()
        startRound(afterWin: false)
    }

    override func willMove(from view: SKView) {
        motion.stopAccelerometerUpdates()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard isBuilt, size != oldSize, size.width > 0 else { return }
        relayout()
    }

    // MARK: Public controls (used by the SwiftUI host)

    func setHeld(_ held: Bool) {
        isHeld = held
    }

    func startNewGame() {
        startRound(afterWin: false)
    }

    /// New colours without restarting: the screen is redrawn around the current round.
    func updateTheme(_ newSettings: GameSettings) {
        settings = newSettings
        if isBuilt { relayout() }
    }

    func apply(settings newSettings: GameSettings) {
        settings = newSettings
        buildChrome()
        startRound(afterWin: false)
    }

    /// The player confirmed they want to abandon the current game.
    func confirmRestart() {
        isHeld = false
        let finalScore = score
        if finalScore != 0 {
            gameDelegate?.gameScene(self, didEndGameWithScore: finalScore)
        }
        startRound(afterWin: false)
    }

    // MARK: Building the screen

    private func computeLayout() {
        let w = size.width
        let h = size.height
        let top = h - max(safeInsets.top, 12)
        let bottom = max(safeInsets.bottom, 12)
        let usable = top - bottom
        let s = floor(min((w - 16) / 8, usable / 16.8, 80))

        var l = Layout()
        l.s = s
        l.titleY = top - 0.9 * s
        l.powerupY = l.titleY - 1.5 * s
        l.bottomY = bottom + 0.85 * s
        l.messageY = l.bottomY + 1.3 * s
        l.sideButtonInset = max(0.8 * s, 28)
        let gridTop = l.powerupY - 0.75 * s
        let gridBottom = l.messageY + 0.6 * s
        l.gridCenter = CGPoint(x: w / 2, y: (gridTop + gridBottom) / 2)
        layout = l
    }

    /// Creates everything except the grid itself. Called at launch and whenever the colours change.
    private func buildChrome() {
        removeAllChildren()
        removeAllActions()
        squares = [:]
        gridDecor = []
        crosses = []
        previewNodes = []
        pressedCell = nil
        trackingGrid = false
        starNode = nil
        scorePopup = nil

        backgroundColor = backdropColor
        computeLayout()
        let s = layout.s
        let w = size.width

        // Drifting background squares, nudged by tilting the device.
        bgSquares = (0..<Int.random(in: 20..<100)).map { i -> BackgroundSquare in
            let node = SKSpriteNode(texture: Art.roundedSquare, size: CGSize(width: s, height: s))
            node.colorBlendFactor = 1
            node.color = randomPaletteColor()
            node.alpha = 0.05 * CGFloat(Int.random(in: 1...8))
            node.position = randomScreenPoint()
            node.zPosition = Z.background
            addChild(node)
            return BackgroundSquare(node: node, speed: CGFloat(Int.random(in: 1...5)),
                                    direction: i % 2 == 0 ? 1 : -1)
        }

        // Title: "black & white" with a bold ampersand.
        titleLabel = makeLabel("black   white", font: "HelveticaNeue-Light", size: s, color: textColor)
        titleLabel.position = CGPoint(x: w / 2, y: layout.titleY)
        addChild(titleLabel)
        ampersandLabel = makeLabel("&", font: "HelveticaNeue-Bold", size: s, color: textColor)
        ampersandLabel.position = titleLabel.position
        addChild(ampersandLabel)

        settingsButton = makeIconSprite("gearshape.fill", pointSize: s * 0.55)
        settingsButton.position = CGPoint(x: layout.sideButtonInset, y: layout.titleY)
        addChild(settingsButton)

        scoresButton = makeIconSprite("trophy.fill", pointSize: s * 0.55)
        scoresButton.position = CGPoint(x: w - layout.sideButtonInset, y: layout.titleY)
        addChild(scoresButton)

        // Power-ups.
        powerupNodes = PowerupNode.Kind.allCases.map { kind -> PowerupNode in
            let node = PowerupNode(kind: kind, size: CGSize(width: 1.5 * s, height: 0.8 * s), maxColor: pathColor)
            node.position = CGPoint(x: w / 2 + CGFloat(kind.rawValue - 1) * 2.1 * s, y: layout.powerupY)
            node.zPosition = Z.controls
            addChild(node)
            return node
        }

        // Message strip.
        messageBar = SKSpriteNode(color: backdropColor, size: CGSize(width: w, height: 0.62 * s))
        messageBar.alpha = 0.7
        messageBar.position = CGPoint(x: w / 2, y: layout.messageY)
        messageBar.zPosition = Z.messageBar
        addChild(messageBar)
        messageLabel = makeLabel(message, font: "HelveticaNeue-Bold", size: 0.45 * s, color: textColor)
        messageLabel.position = messageBar.position
        messageLabel.zPosition = Z.message
        addChild(messageLabel)

        // Score (bottom left).
        scoreLabel = makeLabel("\(score)", font: "HelveticaNeue-Bold", size: 0.85 * s, color: textColor)
        scoreLabel.position = CGPoint(x: w / 2 - 2.5 * s, y: layout.bottomY)
        addChild(scoreLabel)

        // Commit button (bottom centre).
        commitSize = CGSize(width: 2 * s, height: 1.15 * s)
        commitButton = SKNode()
        commitButton.position = CGPoint(x: w / 2, y: layout.bottomY)
        commitButton.zPosition = Z.controls
        let outer = SKShapeNode(rectOf: commitSize, cornerRadius: 8)
        outer.fillColor = .black
        outer.strokeColor = .clear
        commitButton.addChild(outer)
        commitInner = SKShapeNode(rectOf: CGSize(width: commitSize.width - 10, height: commitSize.height - 10),
                                  cornerRadius: 5)
        commitInner.fillColor = pathColor
        commitInner.strokeColor = .white
        commitInner.lineWidth = 2
        commitInner.zPosition = 0.1
        commitButton.addChild(commitInner)
        commitIcon = SKSpriteNode()
        commitIcon.zPosition = 0.2
        commitButton.addChild(commitIcon)
        addChild(commitButton)

        // Timer (bottom right).
        timerNode = TimerNode(radius: 0.6 * s, pathColor: pathColor, lockColor: lockColor,
                              background: backdropColor, ringColor: textColor)
        timerNode.position = CGPoint(x: w / 2 + 2.5 * s, y: layout.bottomY)
        timerNode.zPosition = Z.controls
        addChild(timerNode)

        // Black and white square counters, shown on top of a square of the matching colour.
        blackCounter = makeLabel("0", font: "HelveticaNeue", size: 0.65 * s, color: .white)
        blackCounter.zPosition = Z.counter
        addChild(blackCounter)
        whiteCounter = makeLabel("0", font: "HelveticaNeue", size: 0.65 * s, color: .black)
        whiteCounter.zPosition = Z.counter
        addChild(whiteCounter)

        // Start (left) and finish (right) markers.
        let barWidth = w + 2 * s
        startBackdrop = SKSpriteNode(color: textColor, size: CGSize(width: barWidth, height: s + 10))
        startBackdrop.anchorPoint = CGPoint(x: 1, y: 0.5)
        startBackdrop.zPosition = Z.barBackdrop
        addChild(startBackdrop)
        startBar = SKSpriteNode(color: pathColor, size: CGSize(width: barWidth, height: s))
        startBar.anchorPoint = CGPoint(x: 1, y: 0.5)
        startBar.zPosition = Z.bar
        addChild(startBar)
        finishBackdrop = SKSpriteNode(color: textColor, size: CGSize(width: barWidth, height: s + 10))
        finishBackdrop.anchorPoint = CGPoint(x: 0, y: 0.5)
        finishBackdrop.zPosition = Z.barBackdrop
        addChild(finishBackdrop)
        finishBar = SKSpriteNode(color: .white, size: CGSize(width: barWidth, height: s))
        finishBar.anchorPoint = CGPoint(x: 0, y: 0.5)
        finishBar.zPosition = Z.bar
        addChild(finishBar)

        urgencyFrame = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        urgencyFrame.strokeColor = lockColor
        urgencyFrame.fillColor = .clear
        urgencyFrame.lineWidth = 0.6 * s
        urgencyFrame.alpha = 0
        urgencyFrame.zPosition = Z.urgency
        addChild(urgencyFrame)

        isBuilt = true
        refreshPowerups()
        applyChromeForPhase()
    }

    /// Rebuilds the screen after a size change, keeping the current round.
    private func relayout() {
        buildChrome()
        renderBoard(animated: false)
        if phase == .lost {
            // Locked squares and the failed path already drifted away.
            for (p, node) in squares where board.isLocked(p) || resultPath.contains(p) {
                node.removeFromParent()
                squares[p] = nil
            }
        }
        switch phase {
        case .dealing:
            beginPlay()
        case .resolving:
            finishRound(board.evaluate())
        case .playing, .won, .lost:
            break
        }
        if phase == .won { bgSquares.forEach { $0.node.color = pathColor } }
        if phase == .lost { bgSquares.forEach { $0.node.color = lockColor } }
        if phase == .playing && mode != .normal {
            // Restore the armed power-up's crosses or pulses.
            setMode(mode)
        }
        applyChromeForPhase()
    }

    // MARK: Rounds

    private func startRound(afterWin: Bool) {
        removeAction(forKey: "deal")
        removeAction(forKey: "resolve")

        if afterWin {
            level += 1
        } else {
            level = 1
            score = 0
            powerupCounts = Array(repeating: settings.difficulty.startingPowerups, count: 3)
            punishNext = false
        }
        let punished = punishNext
        punishNext = false

        board = Board.randomSolvable(punishment: punished)
        phase = .dealing
        mode = .normal
        resultPath = []
        resultWon = false
        livePath = Set(board.pathLayers().joined())
        clearPreview()
        elapsed = 0
        warned = false
        lowTime = false
        lastTick = nil
        message = punished ? Messages.pick(Messages.punishment) : levelText

        scorePopup?.removeFromParent()
        scorePopup = nil
        timerNode.reset()

        // Shuffle the background.
        for bg in bgSquares {
            bg.node.removeAllActions()
            bg.node.color = randomPaletteColor()
            let target = randomScreenPoint()
            if Motion.reduced {
                bg.node.position = target
            } else {
                bg.node.run(.move(to: target, duration: Double.random(in: 0.1...1)))
            }
        }

        renderBoard(animated: true)
        refreshPowerups()
        applyChromeForPhase()
        showLevelCard(subtitle: punished ? message : nil)

        run(.sequence([.wait(forDuration: 1.1), .run { [weak self] in self?.beginPlay() }]), withKey: "deal")
        SoundEngine.shared.play(.newGame)
    }

    private func beginPlay() {
        phase = .playing
        elapsed = 0
        lastTick = nil
        applyChromeForPhase()
    }

    private var levelText: String { "Level \(level)" }

    /// Lays out the grid for the current board. When animated, old squares scatter
    /// into the background and new ones fly in from it.
    private func renderBoard(animated: Bool) {
        let s = layout.s

        for node in squares.values {
            if animated {
                scatter(node, delay: 0, duration: 2)
            } else {
                node.removeFromParent()
            }
        }
        squares = [:]
        gridDecor.forEach { $0.removeFromParent() }
        gridDecor = []
        clearCrosses()
        if let star = starNode {
            starNode = nil
            star.run(.sequence([.group([.scale(to: 0.3, duration: 0.6), .fadeOut(withDuration: 0.6)]),
                                .removeFromParent()]))
        }

        let gridSize = CGSize(width: CGFloat(board.cols) * s, height: CGFloat(board.rows) * s)
        let border = SKShapeNode(rectOf: CGSize(width: gridSize.width + 20, height: gridSize.height + 20),
                                 cornerRadius: 4)
        border.strokeColor = textColor
        border.fillColor = .clear
        border.lineWidth = 6
        let fine = SKShapeNode(rectOf: gridSize)
        fine.strokeColor = textColor
        fine.fillColor = .clear
        fine.lineWidth = 1
        for node in [border, fine] {
            node.position = layout.gridCenter
            node.zPosition = Z.border
            addChild(node)
            gridDecor.append(node)
        }

        for p in board.allPoints {
            let node = SquareNode(point: p, side: s, rounded: settings.roundedSquares)
            node.position = cellPosition(p)
            node.home = node.position
            addChild(node)
            squares[p] = node
            styleSquare(p)

            guard animated else { continue }
            let target = node.position
            let targetAlpha = node.alpha
            if Motion.reduced {
                node.alpha = 0
                node.run(.fadeAlpha(to: targetAlpha, duration: 0.4), withKey: "deal")
                continue
            }
            node.position = randomScreenPoint()
            node.setScale(0)
            node.alpha = 0
            node.zRotation = CGFloat.random(in: 0..<6)
            let d = Double.random(in: 0.4...0.9)
            node.run(.group([
                .scale(to: 1, duration: d),
                .fadeAlpha(to: targetAlpha, duration: d),
                .rotate(toAngle: 0, duration: d, shortestUnitArc: true),
                .move(to: target, duration: d).timing(.easeInEaseOut),
            ]), withKey: "deal")
        }

        positionBars(animated: animated)

        if let star = board.star {
            let node = SKSpriteNode()
            node.position = cellPosition(star)
            node.zPosition = Z.star
            addChild(node)
            starNode = node
            refreshStar()
            if animated {
                node.alpha = 0
                node.run(.sequence([.wait(forDuration: 0.7), .fadeIn(withDuration: 0.3)]))
            }
        }

        refreshCounters()
        if animated {
            for counter in [blackCounter!, whiteCounter!] where counter.alpha > 0 {
                counter.alpha = 0
                counter.run(.sequence([.wait(forDuration: 0.8), .fadeIn(withDuration: 0.3)]))
            }
        }
    }

    private func positionBars(animated: Bool) {
        let s = layout.s
        let halfWidth = CGFloat(board.cols) * s / 2
        let gridLeft = layout.gridCenter.x - halfWidth
        let gridRight = layout.gridCenter.x + halfWidth
        let startY = cellPosition(board.startPoint).y
        let finishY = cellPosition(board.finishPoint).y

        let moves: [(SKNode, CGPoint)] = [
            (startBar, CGPoint(x: gridLeft, y: startY)),
            (startBackdrop, CGPoint(x: gridLeft - 0.25 * s, y: startY)),
            (finishBar, CGPoint(x: gridRight, y: finishY)),
            (finishBackdrop, CGPoint(x: gridRight + 0.25 * s, y: finishY)),
        ]
        for (node, target) in moves {
            node.removeAllActions()
            if animated {
                node.run(.move(to: target, duration: 0.3))
            } else {
                node.position = target
            }
        }
    }

    // MARK: Per-frame update

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate.map { min(currentTime - $0, 0.1) } ?? 0
        lastUpdate = currentTime
        guard isBuilt else { return }

        driftBackground(dt)

        guard phase == .playing, !isHeld else { return }
        elapsed += dt
        let allowed = settings.difficulty.timeAllowed(level: level)
        let remaining = allowed - elapsed
        timerNode.setProgress(CGFloat(elapsed / allowed))

        if remaining <= 0 {
            timerNode.setHandsVisible(false)
            sparkle(color: lockColor, at: timerNode.position, texture: Art.circle,
                    side: layout.s * 0.4, spread: 50, count: 20)
            commit()
            return
        }
        if remaining <= 8 && !warned {
            warned = true
            message = Messages.pick(Messages.hurry)
        }
        if remaining <= 5 {
            if !lowTime {
                lowTime = true
                applyChromeForPhase()
            }
            let second = Int(remaining.rounded(.up))
            if second != lastTick {
                lastTick = second
                message = "\(second)"
                SoundEngine.shared.play(.tick)
                flashUrgency()
            }
        }
    }

    private func driftBackground(_ dt: TimeInterval) {
        guard !Motion.reduced else { return }
        var gravity = CGVector(dx: 0, dy: -0.1)
        if let a = motion.accelerometerData?.acceleration {
            gravity = CGVector(dx: a.x, dy: a.y)
        }
        let margin = layout.s
        let w = size.width
        let h = size.height
        for bg in bgSquares where !bg.node.hasActions() {
            let factor = 6 * bg.speed * bg.direction * CGFloat(dt)
            var p = bg.node.position
            p.x += gravity.dx * factor
            p.y += gravity.dy * factor
            if p.x < -margin { p.x = w + margin }
            if p.x > w + margin { p.x = -margin }
            if p.y < -margin { p.y = h + margin }
            if p.y > h + margin { p.y = -margin }
            bg.node.position = p
        }
    }

    // MARK: Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isBuilt, !isHeld else { return }
        let p = touch.location(in: self)

        if hit(commitButton, size: commitSize, p) {
            commitTapped()
        } else if timerNode.contains(scenePoint: p) {
            timerTapped()
        } else if hit(scoresButton, size: CGSize(width: layout.s, height: layout.s), p) {
            highScoresTapped()
        } else if let node = powerupNodes.first(where: { $0.contains(scenePoint: p) }) {
            powerupTapped(node.kind)
        } else if hit(settingsButton, size: CGSize(width: layout.s, height: layout.s), p) {
            settingsTapped()
        } else if phase == .playing, let tapped = cell(at: p) {
            // Grid squares act when the finger lifts; while it's down, show what will flip.
            trackingGrid = true
            pressedCell = tapped
            showPreview(tapped)
            selectionHaptic.prepare()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard trackingGrid, let touch = touches.first else { return }
        let current = phase == .playing ? cell(at: touch.location(in: self)) : nil
        guard current != pressedCell else { return }
        pressedCell = current
        showPreview(current)
        if current != nil { selectionHaptic.selectionChanged() }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard trackingGrid else { return }
        let target = pressedCell
        endGridTracking()
        if let target = target, phase == .playing, !isHeld {
            squareTapped(target)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endGridTracking()
    }

    private func endGridTracking() {
        trackingGrid = false
        pressedCell = nil
        clearPreview()
    }

    /// Previews a move: the pressed square is outlined and each square that would flip
    /// shows a small chip of the colour it will become.
    private func showPreview(_ p: GridPoint?) {
        clearPreview()
        guard let p = p, phase == .playing, let node = squares[p] else { return }
        let s = layout.s

        var outlineColor = lockColor
        var targets: [GridPoint] = []
        switch mode {
        case .unlock where board.isLocked(p):
            outlineColor = .white
        case .flipSingle:
            guard !board.isLocked(p) else { return }
            outlineColor = pathColor
            targets = [p]
        default:
            guard !board.isLocked(p) else { return }
            targets = board.surrounding(p).filter { !board.isLocked($0) }
        }

        let outline = SKShapeNode(rectOf: CGSize(width: s - 4, height: s - 4), cornerRadius: s * 0.1)
        outline.strokeColor = outlineColor
        outline.lineWidth = 3
        outline.fillColor = .clear
        outline.position = node.home
        outline.zPosition = Z.preview
        addChild(outline)
        previewNodes.append(outline)

        for t in targets {
            let chip = SKSpriteNode(texture: Art.roundedSquare, size: CGSize(width: 0.42 * s, height: 0.42 * s))
            chip.colorBlendFactor = 1
            chip.color = board.tone(at: t) == .black ? .white : .black
            chip.position = cellPosition(t)
            chip.zPosition = Z.preview
            addChild(chip)
            previewNodes.append(chip)
            if !Motion.reduced {
                chip.setScale(0.2)
                chip.run(.scale(to: 1, duration: 0.1).timing(.easeOut))
            }
        }
    }

    private func clearPreview() {
        previewNodes.forEach { $0.removeFromParent() }
        previewNodes = []
    }

    private func hit(_ node: SKNode, size: CGSize, _ p: CGPoint, slop: CGFloat = 8) -> Bool {
        abs(p.x - node.position.x) <= size.width / 2 + slop && abs(p.y - node.position.y) <= size.height / 2 + slop
    }

    private func commitTapped() {
        switch phase {
        case .playing:
            commitButton.run(pressAction(0.85))
            commit()
        case .won, .lost:
            advance()
        case .dealing, .resolving:
            break
        }
    }

    private func timerTapped() {
        switch phase {
        case .won, .lost:
            advance()
        case .playing:
            timerNode.run(pressAction(0.7))
            SoundEngine.shared.play(.button)
            if level > 1 || score != 0 {
                isHeld = true
                gameDelegate?.gameSceneWantsRestartConfirmation(self)
            } else {
                startRound(afterWin: false)
            }
        case .dealing, .resolving:
            break
        }
    }

    /// Moves on after a round: next level after a win, new game after a loss.
    private func advance() {
        SoundEngine.shared.play(.button)
        timerNode.run(pressAction(0.7))
        startRound(afterWin: phase == .won)
    }

    private func settingsTapped() {
        guard settingsAvailable else { return }
        SoundEngine.shared.play(.button)
        settingsButton.run(pressAction(0.7))
        isHeld = true
        gameDelegate?.gameSceneWantsSettings(self)
    }

    private func highScoresTapped() {
        guard highScoresAvailable else { return }
        SoundEngine.shared.play(.button)
        scoresButton.run(pressAction(0.7))
        isHeld = true
        gameDelegate?.gameSceneWantsHighScores(self)
    }

    private func squareTapped(_ p: GridPoint) {
        switch mode {
        case .unlock:
            if board.isLocked(p) {
                board.unlock(p)
                powerupCounts[PowerupNode.Kind.unlock.rawValue] -= 1
                SoundEngine.shared.play(.unlock)
                flipSquare(p)
                ripple(at: cellPosition(p), color: .white)
                refreshLivePath(flipping: [p])
                setMode(.normal)
                message = levelText
                refreshStar()
                refreshCounters()
                tapHaptic.impactOccurred()
                return
            }
            // Tapping an unlocked square cancels the power-up and plays a normal move.
            setMode(.normal)
        case .flipSingle:
            guard !board.isLocked(p) else {
                rejectTap(p)
                return
            }
            board.toggle(p)
            powerupCounts[PowerupNode.Kind.flipOne.rawValue] -= 1
            setMode(.normal)
            SoundEngine.shared.play(.unlock)
            flipSquare(p)
            ripple(at: cellPosition(p), color: pathColor)
            sparkleSquare(p)
            refreshLivePath(flipping: [p])
            message = levelText
            refreshStar()
            refreshCounters()
            tapHaptic.impactOccurred()
            return
        case .normal:
            break
        }

        guard !board.isLocked(p) else {
            rejectTap(p)
            return
        }
        let hadStar = board.star == p
        let flipped = board.lock(p)
        tapHaptic.impactOccurred()

        if let node = squares[p] {
            node.zPosition = Z.lockedSquare
            node.stamp(color: lockColor)
        }
        ripple(at: cellPosition(p), color: lockColor)
        if hadStar, let star = starNode {
            starNode = nil
            star.run(.sequence([Motion.reduced ? SKAction.fadeOut(withDuration: 0.4) : SKAction.scale(to: 0, duration: 0.5),
                                .removeFromParent()]))
            SoundEngine.shared.play(.starAway)
            message = "Goodbye star!"
        } else {
            SoundEngine.shared.play(.tap)
        }
        // Neighbours flip in a quick ripple: edges first, then corners.
        for n in flipped {
            let isCorner = n.row != p.row && n.col != p.col
            flipSquare(n, delay: isCorner ? 0.07 : 0.03, from: p)
            sparkleSquare(n)
        }
        refreshLivePath(flipping: Set(flipped + [p]))
        refreshStar()
        refreshCounters()
    }

    private func powerupTapped(_ kind: PowerupNode.Kind) {
        guard phase == .playing, powerupCounts[kind.rawValue] > 0 else { return }
        let node = powerupNodes[kind.rawValue]

        switch kind {
        case .flipAll:
            setMode(.normal)
            powerupCounts[kind.rawValue] -= 1
            node.run(pressAction(0.9))
            // A wave sweeping across from the left.
            let flippedAll = board.flipAll()
            for p in flippedAll {
                flipSquare(p, delay: Double(p.col) * 0.04 + Double(p.row) * 0.015)
            }
            refreshLivePath(flipping: Set(flippedAll))
            message = "Flip all squares"
            SoundEngine.shared.play(.flip)
            refreshStar()
            refreshCounters()
            refreshPowerups()

        case .unlock:
            SoundEngine.shared.play(.button)
            if mode == .unlock {
                setMode(.normal)
                message = levelText
                return
            }
            guard board.lockedCount > 0 else {
                message = "No locked squares yet"
                return
            }
            node.run(pressAction(0.9))
            setMode(.unlock)
            message = "Unlock a tapped square"

        case .flipOne:
            SoundEngine.shared.play(.button)
            if mode == .flipSingle {
                setMode(.normal)
                message = levelText
                return
            }
            node.run(pressAction(0.9))
            setMode(.flipSingle)
            message = "Flip a single square"
        }
    }

    private func setMode(_ newMode: Mode) {
        clearCrosses()
        for node in squares.values { node.stopPulse() }
        for node in pulseExtras {
            node.removeAction(forKey: "pulse")
            node.setScale(1)
        }

        mode = newMode
        switch newMode {
        case .normal:
            break
        case .unlock:
            // Pulsing crosses over the locked squares, in the colour each square will return to.
            for p in board.allPoints where board.isLocked(p) {
                let color: UIColor = board.tone(at: p) == .black ? .black : .white
                let art = Art.icon("xmark", color: color, pointSize: layout.s * 0.5, weight: .bold)
                let cross = SKSpriteNode(texture: art.texture, size: art.size)
                cross.position = cellPosition(p)
                cross.zPosition = Z.cross
                if !Motion.reduced { cross.run(pulseAction(), withKey: "pulse") }
                addChild(cross)
                crosses.append(cross)
            }
        case .flipSingle:
            for (p, node) in squares where !board.isLocked(p) {
                node.startPulse()
            }
            for node in pulseExtras where !Motion.reduced {
                node.run(pulseAction(), withKey: "pulse")
            }
        }
        refreshPowerups()
    }

    /// Counters and the star pulse along with the squares while "flip a single square" is armed.
    private var pulseExtras: [SKNode] {
        var nodes: [SKNode] = [blackCounter!, whiteCounter!]
        if let star = starNode { nodes.append(star) }
        return nodes
    }

    private func clearCrosses() {
        for cross in crosses {
            cross.run(.sequence([.scale(to: 0, duration: 0.2), .removeFromParent()]))
        }
        crosses = []
    }

    // MARK: Ending a round

    private func commit() {
        guard phase == .playing else { return }
        endGridTracking()
        setMode(.normal)
        phase = .resolving
        applyChromeForPhase()
        SoundEngine.shared.play(.button)

        // Finish any flips still running so they can't overwrite the path colours.
        for (p, node) in squares {
            node.settle()
            styleSquare(p)
        }

        let result = board.evaluate()
        resultPath = result.path
        resultWon = result.won

        // Flood the path out from the start square.
        let step = 0.03
        for (i, layer) in result.pathLayers.enumerated() {
            for p in layer {
                squares[p]?.pop(after: Double(i) * step)
                squares[p]?.run(.sequence([
                    .wait(forDuration: Double(i) * step),
                    .run { [weak self] in
                        guard let self = self else { return }
                        self.styleSquare(p)
                        self.sparkle(color: result.won ? self.pathColor : self.lockColor,
                                     at: self.cellPosition(p), texture: Art.roundedSquare,
                                     side: self.layout.s * 0.4, spread: self.layout.s * 0.6, count: 3)
                    },
                ]))
            }
        }
        let duration = Double(result.pathLayers.count) * step + 0.25
        run(.sequence([.wait(forDuration: duration),
                       .run { [weak self] in self?.finishRound(result) }]), withKey: "resolve")
    }

    private func finishRound(_ result: RoundResult) {
        if result.won {
            win(result)
        } else {
            lose()
        }
    }

    private enum StarOutcome { case none, powerup, points }

    private func win(_ result: RoundResult) {
        phase = .won
        resultWon = true
        resultHaptic.notificationOccurred(.success)
        let total = result.total
        var starOutcome = StarOutcome.none

        // Bonus star on the path: an extra power-up, or points if they're all full.
        if let star = board.star, result.path.contains(star), let node = starNode {
            starNode = nil
            let open = PowerupNode.Kind.allCases.filter { powerupCounts[$0.rawValue] < Board.maxPowerups }
            let target: CGPoint
            if let kind = open.randomElement() {
                starOutcome = .powerup
                let powerup = powerupNodes[kind.rawValue]
                target = powerup.position
                powerupCounts[kind.rawValue] = min(powerupCounts[kind.rawValue] + 1, Board.maxPowerups)
                run(.sequence([.wait(forDuration: 1.8), .run { [weak self] in
                    guard let self = self else { return }
                    self.refreshPowerups()
                    SoundEngine.shared.play(.powerup)
                    powerup.run(self.bounceAction())
                }]))
            } else {
                starOutcome = .points
                target = scoreLabel.position
                score += level
                let bonus = makeLabel("+\(level)", font: "HelveticaNeue-Bold", size: 0.7 * layout.s, color: textColor)
                bonus.position = CGPoint(x: node.position.x, y: node.position.y + 0.7 * layout.s)
                bonus.zPosition = Z.flying
                addChild(bonus)
                bonus.run(.sequence([
                    .wait(forDuration: 0.2),
                    .group([.move(to: CGPoint(x: target.x, y: target.y + layout.s), duration: 1.8).timing(.easeInEaseOut),
                            .fadeOut(withDuration: 1.9)]),
                    .removeFromParent(),
                ]))
                for powerup in powerupNodes {
                    sparkle(color: pathColor, at: powerup.position, texture: Art.star, side: layout.s * 0.4)
                    powerup.run(.sequence([.scale(to: 1.2, duration: 0.4), .scale(to: 1, duration: 0.4)]))
                }
            }
            sparkle(color: textColor, at: node.position, texture: Art.star, side: layout.s * 0.4, z: Z.flying)
            node.zPosition = Z.flying
            if Motion.reduced {
                node.run(.sequence([.fadeOut(withDuration: 0.6), .removeFromParent()]))
            } else {
                node.run(.sequence([
                .scale(to: 1.2, duration: 0.1),
                .scale(to: 1, duration: 0.1),
                .group([.move(to: target, duration: 1.8).timing(.easeInEaseOut),
                        .fadeOut(withDuration: 1.8).timing(.easeIn),
                        .rotate(byAngle: 2 * .pi, duration: 2)]),
                .removeFromParent(),
            ]))
            }
        }

        showScorePopup(result)

        if result.noWhites {
            if total < board.rows * board.cols {
                message = Messages.pick(Messages.noWhite)
            } else {
                // Big round with no whites left: one of each power-up.
                let anyRoom = powerupCounts.contains { $0 < Board.maxPowerups }
                message = Messages.pick(anyRoom ? Messages.reward : Messages.noWhite)
                for powerup in powerupNodes where powerupCounts[powerup.kind.rawValue] < Board.maxPowerups {
                    powerupCounts[powerup.kind.rawValue] += 1
                    powerup.run(bounceAction())
                    sparkle(color: pathColor, at: powerup.position, texture: Art.roundedSquare, side: layout.s * 0.4)
                }
                refreshPowerups()
            }
        } else if total > 0 {
            message = Messages.pick(Messages.win)
        } else {
            // A pointless or negative round means a tiny grid next.
            message = Messages.pick(total == 0 ? Messages.zero : Messages.negative)
            punishNext = true
        }

        score += total
        animateScoreChange(total)
        if total > 0 {
            // Bigger rounds get more confetti; a reward round gets the lot.
            let rewarded = result.noWhites && total >= board.rows * board.cols
            confetti(count: rewarded ? 140 : min(12 + total * 3, 110))
        }
        bgSquares.forEach { $0.node.color = pathColor }
        refreshCounters()
        applyChromeForPhase()

        switch starOutcome {
        case .points:
            SoundEngine.shared.play(.starBonus)
        case .powerup, .none:
            if starOutcome == .powerup { SoundEngine.shared.play(.star) }
            if result.noWhites {
                SoundEngine.shared.play(.noWhite)
            } else if total <= 0 {
                SoundEngine.shared.play(.negative)
            } else {
                SoundEngine.shared.play(.win)
            }
        }
    }

    private func lose() {
        phase = .lost
        resultWon = false
        resultHaptic.notificationOccurred(.error)
        let finalScore = score

        if level == 1 {
            message = Messages.pick(Messages.quickFail)
        } else if finalScore == 0 {
            message = Messages.pick(Messages.zeroFail)
        } else if finalScore < 0 {
            message = Messages.pick(Messages.negativeFail)
        } else {
            message = Messages.pick(Messages.fail)
        }

        if let star = starNode {
            starNode = nil
            star.zPosition = Z.flying
            star.run(.sequence([Motion.reduced ? SKAction.fadeOut(withDuration: 0.6) : SKAction.scale(to: 0, duration: 1),
                                .removeFromParent()]))
        }

        // Locked squares and the failed path drift off into the background.
        let doomed = squares.filter { board.isLocked($0.key) || resultPath.contains($0.key) }
        for (p, node) in doomed {
            squares[p] = nil
            node.color = lockColor
            node.alpha = 1
            scatter(node, delay: Double.random(in: 1...2), duration: 2)
        }

        if finalScore != 0 {
            animateScoreChange(-finalScore, isLoss: true)
        }
        score = 0
        bgSquares.forEach { $0.node.color = lockColor }
        refreshCounters()
        applyChromeForPhase()
        SoundEngine.shared.play(.fail)
        gameDelegate?.gameScene(self, didEndGameWithScore: finalScore)
    }

    /// The black card that rises up showing path points, white squares and locked squares.
    private func showScorePopup(_ result: RoundResult) {
        let s = layout.s
        let popup = SKNode()
        popup.position = CGPoint(x: size.width / 2, y: layout.bottomY + s)
        popup.zPosition = Z.popup
        popup.alpha = 0

        let back = SKShapeNode(rectOf: CGSize(width: 4 * s - 14, height: 4 * s - 14), cornerRadius: 6)
        back.fillColor = .black
        back.strokeColor = .clear
        back.alpha = 0.75
        popup.addChild(back)

        let lines: [(String, UIColor)] = [
            ("+\(result.pathCount)", pathColor),
            (result.noWhites ? "+\(result.noWhitesBonus)" : "-\(result.leftoverWhites)", .white),
            ("-\(result.lockedCount)", lockColor),
        ]
        for (i, line) in lines.enumerated() {
            let label = makeLabel(line.0, font: "HelveticaNeue", size: 0.9 * s, color: line.1)
            label.position = CGPoint(x: 0, y: 1.15 * s * CGFloat(1 - i))
            label.zPosition = 0.1
            popup.addChild(label)
        }
        addChild(popup)
        scorePopup = popup

        if Motion.reduced { popup.position.y = layout.gridCenter.y }
        popup.run(.sequence([
            .group([Motion.reduced ? SKAction.wait(forDuration: 0) : SKAction.moveTo(y: layout.gridCenter.y, duration: 1).timing(.easeOut),
                    .fadeIn(withDuration: 0.7)]),
            .wait(forDuration: 2),
            .fadeOut(withDuration: 0.5),
            .removeFromParent(),
        ]))
    }

    /// The round's points float from the score towards the centre button while the score updates.
    private func animateScoreChange(_ delta: Int, isLoss: Bool = false) {
        let text = delta < 0 ? "\(delta)" : "+\(delta)"
        let label = makeLabel(text, font: "HelveticaNeue-Bold", size: 0.85 * layout.s,
                              color: delta < 0 || isLoss ? lockColor : textColor)
        label.position = scoreLabel.position
        label.zPosition = Z.popup
        addChild(label)
        label.run(.sequence([
            .wait(forDuration: 1),
            .group([Motion.reduced ? SKAction.wait(forDuration: 0) : SKAction.move(to: commitButton.position, duration: 2).timing(.easeInEaseOut),
                    .fadeOut(withDuration: 2)]),
            .removeFromParent(),
        ]))
        scoreLabel.removeAllActions()
        scoreLabel.run(.sequence([.fadeAlpha(to: 0, duration: 0), .wait(forDuration: 1.8),
                                  .fadeIn(withDuration: 0.5)]))
    }

    // MARK: Refreshing visuals from state

    /// How a square should look for the current state.
    private func appearance(_ p: GridPoint) -> (color: UIColor, alpha: CGFloat, z: CGFloat) {
        if resultPath.contains(p) {
            return (resultWon ? pathColor : lockColor, 1, Z.square)
        } else if board.isLocked(p) {
            return (lockColor, 1, Z.lockedSquare)
        } else if board.tone(at: p) == .black {
            return (.black, 1, Z.square)
        } else if livePath.contains(p) && (phase == .playing || phase == .dealing) {
            // Already connected to the start: a light wash of the path colour.
            return (UIColor.white.blended(with: pathColor, amount: 0.35), 0.9, Z.square)
        } else {
            return (.white, 0.8, Z.square)
        }
    }

    private func styleSquare(_ p: GridPoint) {
        guard let node = squares[p] else { return }
        let look = appearance(p)
        node.color = look.color
        node.alpha = look.alpha
        node.zPosition = look.z
    }

    /// Animates a square to its current colour with a card flip. When `origin` is given,
    /// squares directly above or below it flip top-to-bottom, others side-to-side.
    private func flipSquare(_ p: GridPoint, delay: TimeInterval = 0, from origin: GridPoint? = nil) {
        guard let node = squares[p] else { return }
        node.zPosition = appearance(p).z + 0.2
        let axis: SquareNode.FlipAxis = (origin?.col == p.col) ? .horizontal : .vertical
        node.flip(delay: delay, axis: axis) { [weak self] in
            guard let self = self else { return (.white, 0.8) }
            let look = self.appearance(p)
            return (look.color, look.alpha)
        }
    }

    /// Recomputes which squares connect to the start and re-tints the ones that changed.
    /// Squares in `flipping` are skipped: their flip picks up the new colour itself.
    private func refreshLivePath(flipping: Set<GridPoint> = []) {
        let wasReady = pathReady
        let updated = Set(board.pathLayers().joined())
        let changed = updated.symmetricDifference(livePath)
        livePath = updated
        for p in changed where !flipping.contains(p) {
            let look = appearance(p)
            squares[p]?.recolor(to: look.color, alpha: look.alpha)
        }
        guard pathReady != wasReady else { return }
        if pathReady && phase == .playing {
            // Connected all the way across: a little cue that it's ready to test.
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            sparkle(color: pathColor, at: CGPoint(x: finishBar.position.x + layout.s * 0.5, y: finishBar.position.y),
                    texture: Art.roundedSquare, side: layout.s * 0.3, spread: layout.s * 0.8, count: 5)
        }
        applyChromeForPhase()
    }

    /// An outline that grows out of a square and fades.
    private func ripple(at point: CGPoint, color: UIColor) {
        guard !Motion.reduced else { return }
        let s = layout.s
        let ring = SKShapeNode(rectOf: CGSize(width: s, height: s), cornerRadius: s * 0.12)
        ring.strokeColor = color
        ring.fillColor = .clear
        ring.lineWidth = 2
        ring.position = point
        ring.zPosition = Z.cross
        addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 2.8, duration: 0.45).timing(.easeOut),
                    .fadeOut(withDuration: 0.45)]),
            .removeFromParent(),
        ]))
    }

    /// A tap that can't do anything: the square wobbles.
    private func rejectTap(_ p: GridPoint) {
        squares[p]?.shake()
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.6)
    }

    /// Star icon contrasts with the square under it.
    private func refreshStar() {
        guard let p = board.star, let node = starNode else { return }
        let color: UIColor = board.tone(at: p) == .black ? .white : .black
        let art = Art.icon("star.fill", color: color, pointSize: layout.s * 0.55)
        node.texture = art.texture
        node.size = art.size
    }

    private func refreshCounters() {
        let blacks = board.cells(of: .black).filter { !resultPath.contains($0) }
        let whites = board.cells(of: .white).filter { !resultPath.contains($0) }
        blackCounter.text = "\(blacks.count)"
        whiteCounter.text = "\(whites.count)"
        place(blackCounter, on: blacks.filter { $0 != board.star }.randomElement())
        place(whiteCounter, on: whites.filter { $0 != board.star }.randomElement())
    }

    private func place(_ label: SKLabelNode, on p: GridPoint?) {
        label.removeAllActions()
        label.setScale(1)
        if let p = p {
            label.position = cellPosition(p)
            label.alpha = 1
        } else {
            label.alpha = 0
        }
    }

    private func refreshPowerups() {
        for node in powerupNodes {
            let style: PowerupNode.Style
            switch (node.kind, mode) {
            case (.unlock, .unlock): style = .highlighted(lockColor)
            case (.flipOne, .flipSingle): style = .inverted
            default: style = .normal
            }
            node.update(count: powerupCounts[node.kind.rawValue], style: style)
        }
    }

    /// Updates buttons and markers to match the current phase.
    private func applyChromeForPhase() {
        guard isBuilt else { return }
        let won = phase == .won
        let lost = phase == .lost

        commitInner.fillColor = lost ? lockColor : pathColor
        let iconName = lost ? "xmark" : (won ? "arrow.right" : "checkmark")
        let art = Art.icon(iconName, color: textColor, pointSize: layout.s * 0.55, weight: .bold)
        commitIcon.texture = art.texture
        commitIcon.size = art.size

        timerNode.setIcon(won ? "checkmark" : "arrow.clockwise")
        timerNode.setLow(lost || lowTime)
        startBar.color = lost ? lockColor : pathColor
        let ready = phase == .playing && pathReady
        finishBar.color = won ? pathColor : (ready ? UIColor.white.blended(with: pathColor, amount: 0.5) : .white)
        if ready && !Motion.reduced {
            if commitButton.action(forKey: "ready") == nil {
                commitButton.run(.repeatForever(.sequence([
                    .scale(to: 1.07, duration: 0.45).timing(.easeInEaseOut),
                    .scale(to: 1, duration: 0.45).timing(.easeInEaseOut),
                ])), withKey: "ready")
            }
        } else if commitButton.action(forKey: "ready") != nil {
            commitButton.removeAction(forKey: "ready")
            commitButton.run(.scale(to: 1, duration: 0.15))
        }
        if !(phase == .playing && lowTime) {
            urgencyFrame.removeAllActions()
            urgencyFrame.alpha = 0
        }
        scoreLabel.fontColor = lost ? lockColor : textColor

        settingsButton.alpha = settingsAvailable ? 1 : 0.25
        scoresButton.alpha = highScoresAvailable ? 1 : 0.25
    }

    // MARK: Helpers

    private func cellPosition(_ p: GridPoint) -> CGPoint {
        let s = layout.s
        let left = layout.gridCenter.x - CGFloat(board.cols) * s / 2
        let top = layout.gridCenter.y + CGFloat(board.rows) * s / 2
        return CGPoint(x: left + (CGFloat(p.col) + 0.5) * s, y: top - (CGFloat(p.row) + 0.5) * s)
    }

    private func cell(at point: CGPoint) -> GridPoint? {
        let s = layout.s
        let left = layout.gridCenter.x - CGFloat(board.cols) * s / 2
        let top = layout.gridCenter.y + CGFloat(board.rows) * s / 2
        let p = GridPoint(row: Int(floor((top - point.y) / s)), col: Int(floor((point.x - left) / s)))
        return board.contains(p) ? p : nil
    }

    private func randomScreenPoint() -> CGPoint {
        CGPoint(x: CGFloat.random(in: 0...max(size.width, 1)), y: CGFloat.random(in: 0...max(size.height, 1)))
    }

    private func randomPaletteColor() -> UIColor {
        [UIColor.black, UIColor.white, lockColor, pathColor].randomElement()!
    }

    /// Sends a square off into the background, shrinking and fading.
    private func scatter(_ node: SKNode, delay: TimeInterval, duration: TimeInterval) {
        node.removeAllActions()
        if Motion.reduced {
            node.run(.sequence([.wait(forDuration: delay), .fadeOut(withDuration: duration * 0.5),
                                .removeFromParent()]))
            return
        }
        let target = bgSquares.randomElement()?.node.position ?? randomScreenPoint()
        node.run(.sequence([
            .wait(forDuration: delay),
            .group([.scale(to: 0, duration: duration * 1.5),
                    .fadeOut(withDuration: duration),
                    .move(to: target, duration: duration).timing(.easeInEaseOut)]),
            .removeFromParent(),
        ]))
    }

    private func sparkle(color: UIColor, at point: CGPoint, texture: SKTexture = Art.sparkle,
                         side: CGFloat? = nil, spread: CGFloat = 40, count: Int = 6, z: CGFloat = Z.sparkle) {
        guard !Motion.reduced else { return }
        let side = side ?? layout.s * 0.5
        for _ in 0..<count {
            let particle = SKSpriteNode(texture: texture, size: CGSize(width: side, height: side))
            particle.color = color
            particle.colorBlendFactor = 1
            particle.alpha = 0.5
            particle.position = point
            particle.zPosition = z
            addChild(particle)
            let move = SKAction.moveBy(x: CGFloat.random(in: -spread...spread),
                                       y: CGFloat.random(in: -spread...spread),
                                       duration: 0.8).timing(.easeOut)
            particle.run(.sequence([.group([.scale(to: 0, duration: 0.8), move]), .removeFromParent()]))
        }
    }

    private func sparkleSquare(_ p: GridPoint) {
        guard let node = squares[p] else { return }
        sparkle(color: appearance(p).color, at: node.home, texture: Art.roundedSquare,
                side: layout.s * 0.5, spread: layout.s, count: 2)
    }

    /// One beat of the final countdown: the screen edges flash and the timer thumps.
    private func flashUrgency() {
        urgencyFrame.removeAllActions()
        urgencyFrame.alpha = 0.55
        urgencyFrame.run(.fadeAlpha(to: 0.08, duration: 0.85).timing(.easeOut))
        timerNode.pulseTick()
    }

    /// Burst of confetti from the middle of the grid that arcs up and falls away.
    private func confetti(count: Int) {
        guard !Motion.reduced, count > 0 else { return }
        let colors: [UIColor] = [pathColor, .white, .black, pathColor.blended(with: .white, amount: 0.5)]
        let w = size.width
        let h = size.height
        for i in 0..<count {
            let side = layout.s * CGFloat.random(in: 0.15...0.3)
            let piece = SKSpriteNode(texture: Art.roundedSquare,
                                     size: CGSize(width: side, height: side * CGFloat.random(in: 0.5...1)))
            piece.color = colors[i % colors.count]
            piece.colorBlendFactor = 1
            piece.position = layout.gridCenter
            piece.zPosition = Z.flying
            addChild(piece)
            let dx = CGFloat.random(in: -0.55 * w...0.55 * w)
            let rise = CGFloat.random(in: 0.15 * h...0.4 * h)
            let up = SKAction.moveBy(x: dx * 0.6, y: rise, duration: 0.5).timing(.easeOut)
            let fall = SKAction.moveBy(x: dx * 0.4, y: -(rise + 0.6 * h), duration: 1.5).timing(.easeIn)
            piece.run(.sequence([
                .wait(forDuration: Double.random(in: 0...0.12)),
                .group([.sequence([up, fall]),
                        .rotate(byAngle: CGFloat.random(in: -9...9), duration: 2),
                        .sequence([.wait(forDuration: 1.3), .fadeOut(withDuration: 0.7)])]),
                .removeFromParent(),
            ]))
        }
    }

    /// "Level N" banner that sweeps across the grid while the squares deal in.
    private func showLevelCard(subtitle: String?) {
        let s = layout.s
        let w = size.width
        let card = SKNode()
        card.zPosition = Z.popup
        let back = SKShapeNode(rectOf: CGSize(width: w + 20, height: subtitle == nil ? 1.5 * s : 2 * s))
        back.fillColor = textColor
        back.strokeColor = .clear
        back.alpha = 0.9
        card.addChild(back)
        let title = makeLabel(levelText, font: "HelveticaNeue-Bold", size: 0.8 * s, color: backdropColor)
        title.position = CGPoint(x: 0, y: subtitle == nil ? 0 : 0.25 * s)
        title.zPosition = 0.1
        card.addChild(title)
        if let subtitle = subtitle {
            let sub = makeLabel(subtitle, font: "HelveticaNeue", size: 0.4 * s, color: backdropColor)
            sub.position = CGPoint(x: 0, y: -0.5 * s)
            sub.zPosition = 0.1
            card.addChild(sub)
        }
        addChild(card)

        let centre = CGPoint(x: w / 2, y: layout.gridCenter.y)
        if Motion.reduced {
            card.position = centre
            card.alpha = 0
            card.run(.sequence([.fadeIn(withDuration: 0.15), .wait(forDuration: 0.6),
                                .fadeOut(withDuration: 0.25), .removeFromParent()]))
        } else {
            card.position = CGPoint(x: centre.x + w, y: centre.y)
            card.run(.sequence([
                .move(to: centre, duration: 0.25).timing(.easeOut),
                .wait(forDuration: 0.5),
                .move(to: CGPoint(x: centre.x - w, y: centre.y), duration: 0.25).timing(.easeIn),
                .removeFromParent(),
            ]))
        }
    }

    private func makeLabel(_ text: String, font: String, size: CGFloat, color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: font)
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = Z.controls
        return label
    }

    private func makeIconSprite(_ name: String, pointSize: CGFloat) -> SKSpriteNode {
        let art = Art.icon(name, color: textColor, pointSize: pointSize)
        let sprite = SKSpriteNode(texture: art.texture, size: art.size)
        sprite.zPosition = Z.controls
        return sprite
    }

    private func pressAction(_ scale: CGFloat) -> SKAction {
        .sequence([.scale(to: scale, duration: 0.1), .scale(to: 1, duration: 0.1)])
    }

    private func bounceAction() -> SKAction {
        .sequence([.scale(to: 1.2, duration: 0.2), .scale(to: 1, duration: 0.2)])
    }

    private func pulseAction() -> SKAction {
        .repeatForever(.sequence([
            .scale(to: 0.85, duration: 0.4).timing(.easeInEaseOut),
            .scale(to: 0.95, duration: 0.4).timing(.easeInEaseOut),
        ]))
    }
}
