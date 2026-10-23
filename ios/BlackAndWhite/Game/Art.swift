import SpriteKit
import UIKit

/// Textures drawn in code. SF Symbols stand in for the Pythonista icon set.
enum Art {
    struct Icon {
        let texture: SKTexture
        let size: CGSize
    }

    private static var iconCache: [String: Icon] = [:]

    /// An SF Symbol drawn in a solid colour.
    static func icon(_ name: String, color: UIColor, pointSize: CGFloat,
                     weight: UIImage.SymbolWeight = .semibold) -> Icon {
        let key = "\(name)|\(color.cacheKey)|\(Int(pointSize * 10))|\(weight.rawValue)"
        if let cached = iconCache[key] { return cached }

        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        guard let symbol = UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
        else {
            return Icon(texture: SKTexture(), size: CGSize(width: pointSize, height: pointSize))
        }
        // Drawing the symbol into a bitmap first makes sure the tint colour is kept.
        let image = UIGraphicsImageRenderer(size: symbol.size).image { _ in
            symbol.draw(at: .zero)
        }
        let icon = Icon(texture: SKTexture(image: image), size: image.size)
        iconCache[key] = icon
        return icon
    }

    /// White shapes, tinted at runtime with `color` and `colorBlendFactor = 1`.
    static let roundedSquare: SKTexture = shape { rect in
        UIBezierPath(roundedRect: rect, cornerRadius: rect.width * 0.1).fill()
    }

    static let circle: SKTexture = shape { rect in
        UIBezierPath(ovalIn: rect).fill()
    }

    static let star: SKTexture = icon("star.fill", color: .white, pointSize: 40).texture
    static let sparkle: SKTexture = icon("sparkle", color: .white, pointSize: 40).texture

    private static func shape(_ draw: (CGRect) -> Void) -> SKTexture {
        let rect = CGRect(x: 0, y: 0, width: 64, height: 64)
        let image = UIGraphicsImageRenderer(size: rect.size).image { _ in
            UIColor.white.setFill()
            draw(rect)
        }
        return SKTexture(image: image)
    }
}

extension UIColor {
    var cacheKey: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, &g, &b, &a)
        return String(format: "%.3f,%.3f,%.3f,%.3f", r, g, b, a)
    }
}

extension SKAction {
    func timing(_ mode: SKActionTimingMode) -> SKAction {
        timingMode = mode
        return self
    }
}
