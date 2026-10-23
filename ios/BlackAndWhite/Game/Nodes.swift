import SpriteKit
import UIKit

/// A square on the game grid.
final class SquareNode: SKSpriteNode {
    let point: GridPoint
    /// Resting position on the grid, used to settle after a shake.
    var home: CGPoint = .zero

    enum FlipAxis {
        /// Squashes sideways, like a card turning left to right.
        case vertical
        /// Squashes top to bottom.
        case horizontal
    }

    init(point: GridPoint, side: CGFloat) {
        self.point = point
        super.init(texture: nil, color: .black, size: CGSize(width: side, height: side))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Card flip: squash flat, swap colour at the midpoint, then open out again.
    func flip(to newColor: UIColor, alpha newAlpha: CGFloat, delay: TimeInterval = 0, axis: FlipAxis = .vertical) {
        removeAction(forKey: "flip")
        let half = 0.09
        let squash: SKAction
        let open: SKAction
        switch axis {
        case .vertical:
            squash = SKAction.scaleX(to: 0.04, duration: half).timing(.easeIn)
            open = SKAction.scaleX(to: 1, duration: half).timing(.easeOut)
        case .horizontal:
            squash = SKAction.scaleY(to: 0.04, duration: half).timing(.easeIn)
            open = SKAction.scaleY(to: 1, duration: half).timing(.easeOut)
        }
        let swap = SKAction.run { [weak self] in
            self?.color = newColor
            self?.alpha = newAlpha
        }
        run(.sequence([.wait(forDuration: delay), squash, swap, open, .scale(to: 1, duration: 0)]),
            withKey: "flip")
    }

    /// The tapped square: changes colour at once and "stamps" down then springs back.
    func stamp(color newColor: UIColor) {
        removeAction(forKey: "flip")
        color = newColor
        alpha = 1
        run(.sequence([
            .scale(to: 0.78, duration: 0.06).timing(.easeOut),
            .scale(to: 1.12, duration: 0.1).timing(.easeOut),
            .scale(to: 1, duration: 0.14).timing(.easeInEaseOut),
        ]), withKey: "flip")
    }

    /// Finishes any flip in progress immediately.
    func settle() {
        removeAction(forKey: "flip")
        setScale(1)
    }

    /// Quick side-to-side wobble for a tap that does nothing.
    func shake() {
        removeAction(forKey: "shake")
        position = home
        let d = max(3, size.width * 0.08)
        run(.sequence([
            .moveBy(x: d, y: 0, duration: 0.04),
            .moveBy(x: -2 * d, y: 0, duration: 0.08),
            .moveBy(x: d * 1.4, y: 0, duration: 0.06),
            .move(to: home, duration: 0.05),
        ]), withKey: "shake")
    }

    /// Little bounce as the path floods through.
    func pop(after delay: TimeInterval) {
        run(.sequence([.wait(forDuration: delay),
                       .scale(to: 1.15, duration: 0.08).timing(.easeOut),
                       .scale(to: 1, duration: 0.12).timing(.easeIn)]), withKey: "pop")
    }

    /// Gentle throb used while the "flip a single square" power-up is armed.
    func startPulse() {
        run(.repeatForever(.sequence([
            .scale(to: 0.85, duration: 0.4).timing(.easeInEaseOut),
            .scale(to: 0.95, duration: 0.4).timing(.easeInEaseOut),
        ])), withKey: "pulse")
    }

    func stopPulse() {
        guard action(forKey: "pulse") != nil else { return }
        removeAction(forKey: "pulse")
        setScale(1)
    }
}

/// One of the three power-up buttons at the top of the screen.
final class PowerupNode: SKNode {
    enum Kind: Int, CaseIterable {
        case flipAll, unlock, flipOne

        var symbol: String {
            switch self {
            case .flipAll: return "shuffle"
            case .unlock: return "xmark"
            case .flipOne: return "circle.lefthalf.filled"
            }
        }
    }

    enum Style {
        case normal
        /// Armed, shown with a coloured fill.
        case highlighted(UIColor)
        /// Armed, shown inverted (black fill, white icon).
        case inverted
    }

    let kind: Kind
    let size: CGSize
    private let body: SKShapeNode
    private let maxRing: SKShapeNode
    private let icon = SKSpriteNode()
    private let label = SKLabelNode(fontNamed: "HelveticaNeue")
    private var lastCount: Int?

    init(kind: Kind, size: CGSize, maxColor: UIColor) {
        self.kind = kind
        self.size = size
        body = SKShapeNode(rectOf: size, cornerRadius: 6)
        maxRing = SKShapeNode(rectOf: CGSize(width: size.width + 8, height: size.height + 8), cornerRadius: 9)
        super.init()

        body.lineWidth = 1
        body.strokeColor = .black
        addChild(body)

        maxRing.lineWidth = 4
        maxRing.strokeColor = maxColor
        maxRing.fillColor = .clear
        maxRing.zPosition = -0.1
        addChild(maxRing)

        icon.position = CGPoint(x: -size.width * 0.2, y: 0)
        icon.zPosition = 0.2
        addChild(icon)

        label.fontSize = size.height * 0.6
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: size.width * 0.24, y: 0)
        label.zPosition = 0.2
        addChild(label)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func update(count: Int, style: Style) {
        let foreground: UIColor
        switch style {
        case .normal:
            body.fillColor = UIColor(white: 1, alpha: 0.8)
            foreground = .black
        case .highlighted(let fill):
            body.fillColor = fill
            foreground = .black
        case .inverted:
            body.fillColor = .black
            foreground = .white
        }
        let art = Art.icon(kind.symbol, color: foreground, pointSize: size.height * 0.45)
        icon.texture = art.texture
        icon.size = art.size
        label.fontColor = foreground
        label.text = "\(count)"
        if let last = lastCount, last != count {
            // Count changed: the number pops (up for gains, down for spending).
            label.removeAction(forKey: "pop")
            label.setScale(1)
            label.run(.sequence([.scale(to: count > last ? 1.5 : 0.6, duration: 0.08),
                                 .scale(to: 1, duration: 0.15).timing(.easeOut)]), withKey: "pop")
        }
        lastCount = count
        maxRing.isHidden = count < Board.maxPowerups
        body.alpha = count == 0 ? 0.5 : 1
        icon.alpha = count == 0 ? 0.4 : 1
        label.alpha = icon.alpha
    }

    func contains(scenePoint p: CGPoint, slop: CGFloat = 6) -> Bool {
        abs(p.x - position.x) <= size.width / 2 + slop && abs(p.y - position.y) <= size.height / 2 + slop
    }
}

/// The countdown dial in the bottom right, which doubles as the restart / next level button.
/// The coloured disc shows time remaining; a background-coloured wedge grows clockwise over it.
final class TimerNode: SKNode {
    let radius: CGFloat
    private let disc: SKShapeNode
    private let wedge = SKShapeNode()
    private let ring: SKShapeNode
    private let hub: SKShapeNode
    private let fixedHand: SKSpriteNode
    private let movingHand: SKSpriteNode
    private let icon = SKSpriteNode()

    private let normalFill: UIColor
    private let lowFill: UIColor

    init(radius: CGFloat, pathColor: UIColor, lockColor: UIColor, background: UIColor, ringColor: UIColor) {
        self.radius = radius
        normalFill = pathColor
        lowFill = lockColor
        disc = SKShapeNode(circleOfRadius: radius)
        ring = SKShapeNode(circleOfRadius: radius)
        hub = SKShapeNode(circleOfRadius: radius * 0.6)
        let handSize = CGSize(width: max(3, radius * 0.12), height: radius - 1)
        fixedHand = SKSpriteNode(color: .black, size: handSize)
        movingHand = SKSpriteNode(color: .black, size: handSize)
        super.init()

        disc.fillColor = pathColor
        disc.strokeColor = .clear
        disc.zPosition = 0
        addChild(disc)

        wedge.fillColor = background
        wedge.strokeColor = background
        wedge.lineWidth = 1
        wedge.zPosition = 1
        addChild(wedge)

        for hand in [fixedHand, movingHand] {
            hand.anchorPoint = CGPoint(x: 0.5, y: 0)
            hand.zPosition = 2
            addChild(hand)
        }

        ring.fillColor = .clear
        ring.strokeColor = ringColor
        ring.lineWidth = 3
        ring.zPosition = 3
        addChild(ring)

        hub.fillColor = .white
        hub.strokeColor = .black
        hub.lineWidth = 1.5
        hub.zPosition = 4
        addChild(hub)

        icon.zPosition = 5
        addChild(icon)
        setIcon("arrow.clockwise")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// 0 = full time left, 1 = out of time.
    func setProgress(_ value: CGFloat) {
        let f = min(max(value, 0), 1)
        movingHand.zRotation = -2 * .pi * f
        guard f > 0 else {
            wedge.path = nil
            return
        }
        let r = radius
        let path = CGMutablePath()
        if f >= 1 {
            path.addEllipse(in: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r))
        } else {
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: 0, y: r))
            path.addArc(center: .zero, radius: r, startAngle: .pi / 2,
                        endAngle: .pi / 2 - 2 * .pi * f, clockwise: true)
            path.closeSubpath()
        }
        wedge.path = path
    }

    func setLow(_ low: Bool) {
        disc.fillColor = low ? lowFill : normalFill
    }

    func setHandsVisible(_ visible: Bool) {
        fixedHand.isHidden = !visible
        movingHand.isHidden = !visible
    }

    func setIcon(_ name: String) {
        let art = Art.icon(name, color: .black, pointSize: radius * 0.55, weight: .bold)
        icon.texture = art.texture
        icon.size = art.size
    }

    func reset() {
        setProgress(0)
        setLow(false)
        setHandsVisible(true)
        setIcon("arrow.clockwise")
        for node in [disc, hub, ring] as [SKNode] {
            node.setScale(0.6)
            node.run(.scale(to: 1, duration: 0.3))
        }
    }

    func contains(scenePoint p: CGPoint) -> Bool {
        hypot(p.x - position.x, p.y - position.y) <= radius + 10
    }
}
