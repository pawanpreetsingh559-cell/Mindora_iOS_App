import UIKit

// MARK: - Garden Tier
enum GardenTier {
    case seed       // 1
    case sprout     // 10
    case bloom      // 25
    case tree       // 50
    case grove      // 75
    case eden       // 100

    var gradientColors: [CGColor] {
        switch self {
        case .seed:
            return [
                UIColor(red: 0.60, green: 0.85, blue: 0.55, alpha: 1).cgColor,
                UIColor(red: 0.25, green: 0.65, blue: 0.30, alpha: 1).cgColor
            ]
        case .sprout:
            return [
                UIColor(red: 0.40, green: 0.80, blue: 0.50, alpha: 1).cgColor,
                UIColor(red: 0.10, green: 0.55, blue: 0.30, alpha: 1).cgColor
            ]
        case .bloom:
            return [
                UIColor(red: 0.85, green: 0.65, blue: 0.95, alpha: 1).cgColor,
                UIColor(red: 0.55, green: 0.25, blue: 0.80, alpha: 1).cgColor
            ]
        case .tree:
            return [
                UIColor(red: 0.20, green: 0.70, blue: 0.45, alpha: 1).cgColor,
                UIColor(red: 0.05, green: 0.40, blue: 0.25, alpha: 1).cgColor
            ]
        case .grove:
            return [
                UIColor(red: 0.10, green: 0.55, blue: 0.40, alpha: 1).cgColor,
                UIColor(red: 0.05, green: 0.30, blue: 0.20, alpha: 1).cgColor
            ]
        case .eden:
            return [
                UIColor(red: 0.95, green: 0.85, blue: 0.30, alpha: 1).cgColor,
                UIColor(red: 0.30, green: 0.75, blue: 0.40, alpha: 1).cgColor
            ]
        }
    }

    var glowColor: UIColor {
        switch self {
        case .seed:   return UIColor(red: 0.40, green: 0.80, blue: 0.40, alpha: 1)
        case .sprout: return UIColor(red: 0.20, green: 0.70, blue: 0.40, alpha: 1)
        case .bloom:  return UIColor(red: 0.70, green: 0.40, blue: 0.90, alpha: 1)
        case .tree:   return UIColor(red: 0.10, green: 0.60, blue: 0.35, alpha: 1)
        case .grove:  return UIColor(red: 0.05, green: 0.45, blue: 0.30, alpha: 1)
        case .eden:   return UIColor(red: 0.80, green: 0.75, blue: 0.20, alpha: 1)
        }
    }

    var ringColor: UIColor {
        switch self {
        case .seed:   return UIColor(red: 0.30, green: 0.75, blue: 0.35, alpha: 1)
        case .sprout: return UIColor(red: 0.15, green: 0.65, blue: 0.35, alpha: 1)
        case .bloom:  return UIColor(red: 0.65, green: 0.30, blue: 0.85, alpha: 1)
        case .tree:   return UIColor(red: 0.10, green: 0.55, blue: 0.30, alpha: 1)
        case .grove:  return UIColor(red: 0.05, green: 0.40, blue: 0.25, alpha: 1)
        case .eden:   return UIColor(red: 0.70, green: 0.65, blue: 0.10, alpha: 1)
        }
    }

    var label: String {
        switch self {
        case .seed:   return "SEED"
        case .sprout: return "SPROUT"
        case .bloom:  return "BLOOM"
        case .tree:   return "TREE"
        case .grove:  return "GROVE"
        case .eden:   return "EDEN"
        }
    }

    var leafCount: Int {
        switch self {
        case .seed:   return 1
        case .sprout: return 2
        case .bloom:  return 3
        case .tree:   return 4
        case .grove:  return 5
        case .eden:   return 6
        }
    }

    static func tier(for count: Int) -> GardenTier {
        switch count {
        case 1:        return .seed
        case 2...10:   return .sprout
        case 11...25:  return .bloom
        case 26...50:  return .tree
        case 51...75:  return .grove
        default:       return .eden   // 76+
        }
    }
}

// MARK: - Large Garden Badge (Detail Screen)
class GardenBadgeView: UIView {

    private let outerRingLayer  = CAShapeLayer()
    private let gradientLayer   = CAGradientLayer()
    private let leafMaskLayer   = CAShapeLayer()
    private let glowLayer       = CALayer()
    private let innerRingLayer  = CAShapeLayer()

    private let iconImageView   = UIImageView()
    private let countLabel      = UILabel()
    private let countWordLabel  = UILabel()
    private let tierLabel       = UILabel()
    private let leavesStack     = UIStackView()

    private var tier: GardenTier = .seed

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        // Glow
        glowLayer.shadowRadius  = 22
        glowLayer.shadowOpacity = 0.50
        glowLayer.shadowOffset  = .zero
        layer.addSublayer(glowLayer)

        // Outer dashed ring
        outerRingLayer.fillColor      = UIColor.clear.cgColor
        outerRingLayer.lineWidth      = 0
        outerRingLayer.lineDashPattern = nil
        layer.addSublayer(outerRingLayer)

        // Leaf-shaped gradient fill
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.8, y: 1)
        layer.addSublayer(gradientLayer)

        // Inner ring
        innerRingLayer.fillColor   = UIColor.clear.cgColor
        innerRingLayer.lineWidth   = 1.5
        innerRingLayer.opacity     = 0.35
        innerRingLayer.strokeColor = UIColor.white.cgColor
        layer.addSublayer(innerRingLayer)

        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        // Count
        countLabel.textColor     = .white
        countLabel.textAlignment = .center
        countLabel.font          = .systemFont(ofSize: 28, weight: .black)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)

        // "GARDENS" word
        countWordLabel.textColor     = UIColor.white.withAlphaComponent(0.85)
        countWordLabel.textAlignment = .center
        countWordLabel.font          = .systemFont(ofSize: 9, weight: .bold)
        countWordLabel.text          = "GARDENS"
        countWordLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countWordLabel)

        // Tier label
        tierLabel.textAlignment = .center
        tierLabel.font          = .systemFont(ofSize: 9, weight: .heavy)
        tierLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tierLabel)

        // Leaves stack
        leavesStack.axis         = .horizontal
        leavesStack.spacing      = 3
        leavesStack.alignment    = .center
        leavesStack.distribution = .fillEqually
        leavesStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leavesStack)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.30),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),

            countWordLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countWordLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 0),

            tierLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            tierLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),

            leavesStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            leavesStack.bottomAnchor.constraint(equalTo: tierLabel.topAnchor, constant: -4),
            leavesStack.heightAnchor.constraint(equalToConstant: 12)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let size   = min(bounds.width, bounds.height)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let outerR = size / 2 - 4

        // Outer dashed ring
        let outerPath = UIBezierPath(arcCenter: center, radius: outerR, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        outerRingLayer.path  = outerPath.cgPath
        outerRingLayer.frame = bounds

        // Rounded hexagon shape for garden badge
        let hexPath = makeRoundedHexPath(in: bounds.insetBy(dx: 16, dy: 16))
        gradientLayer.frame = bounds
        leafMaskLayer.path  = hexPath.cgPath
        gradientLayer.mask  = leafMaskLayer

        innerRingLayer.path  = hexPath.cgPath
        innerRingLayer.frame = bounds

        glowLayer.frame        = bounds.insetBy(dx: 14, dy: 14)
        glowLayer.cornerRadius = glowLayer.bounds.width / 2
    }

    // Rounded hexagon (6-sided, nature feel)
    private func makeRoundedHexPath(in rect: CGRect) -> UIBezierPath {
        let cx = rect.midX, cy = rect.midY
        let r  = min(rect.width, rect.height) / 2
        let path = UIBezierPath()
        let cornerR: CGFloat = 10
        var points: [CGPoint] = []
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            points.append(CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle)))
        }
        for (i, pt) in points.enumerated() {
            let prev = points[(i + 5) % 6]
            let next = points[(i + 1) % 6]
            let d1 = CGPoint(x: pt.x - prev.x, y: pt.y - prev.y)
            let d2 = CGPoint(x: next.x - pt.x, y: next.y - pt.y)
            let len1 = sqrt(d1.x * d1.x + d1.y * d1.y)
            let len2 = sqrt(d2.x * d2.x + d2.y * d2.y)
            let cp1 = CGPoint(x: pt.x - cornerR * d1.x / len1, y: pt.y - cornerR * d1.y / len1)
            let cp2 = CGPoint(x: pt.x + cornerR * d2.x / len2, y: pt.y + cornerR * d2.y / len2)
            if i == 0 { path.move(to: cp1) } else { path.addLine(to: cp1) }
            path.addQuadCurve(to: cp2, controlPoint: pt)
        }
        path.close()
        return path
    }

    func configure(tier: GardenTier, count: Int, iconName: String, isLocked: Bool) {
        self.tier = tier

        if isLocked {
            gradientLayer.colors   = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            outerRingLayer.strokeColor = UIColor.systemGray3.cgColor
            glowLayer.shadowColor  = UIColor.clear.cgColor
            iconImageView.image    = UIImage(systemName: "lock.fill")
            iconImageView.tintColor = .systemGray
            countLabel.text        = "\(count)"
            countLabel.textColor   = .systemGray
            countWordLabel.textColor = .systemGray2
            tierLabel.text         = tier.label
            tierLabel.textColor    = .systemGray2
        } else {
            gradientLayer.colors       = tier.gradientColors
            outerRingLayer.strokeColor = tier.ringColor.cgColor
            glowLayer.shadowColor      = tier.glowColor.cgColor
            iconImageView.image        = UIImage(systemName: iconName)
            iconImageView.tintColor    = .white
            countLabel.text            = "\(count)"
            countLabel.textColor       = .white
            countWordLabel.textColor   = UIColor.white.withAlphaComponent(0.85)
            tierLabel.text             = tier.label
            tierLabel.textColor        = UIColor.white.withAlphaComponent(0.9)
            pulseGlow()
        }

        buildLeaves(count: tier.leafCount, isLocked: isLocked)
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func buildLeaves(count: Int, isLocked: Bool) {
        leavesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let color: UIColor = isLocked ? .systemGray3 : .white
        for _ in 0..<count {
            let iv = UIImageView(image: UIImage(systemName: "leaf.fill"))
            iv.tintColor = color
            iv.contentMode = .scaleAspectFit
            iv.widthAnchor.constraint(equalToConstant: 10).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 10).isActive = true
            leavesStack.addArrangedSubview(iv)
        }
    }

    private func pulseGlow() {
        let pulse = CABasicAnimation(keyPath: "shadowRadius")
        pulse.fromValue    = 16
        pulse.toValue      = 28
        pulse.duration     = 2.0
        pulse.autoreverses = true
        pulse.repeatCount  = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(pulse, forKey: "glowPulse")

        let opPulse = CABasicAnimation(keyPath: "shadowOpacity")
        opPulse.fromValue    = 0.30
        opPulse.toValue      = 0.65
        opPulse.duration     = 2.0
        opPulse.autoreverses = true
        opPulse.repeatCount  = .infinity
        opPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(opPulse, forKey: "opacityPulse")
    }
}

// MARK: - Small Garden Badge (Collection Cell)
class GardenHexagonBadgeView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let shapeLayer    = CAShapeLayer()
    private let glowLayer     = CALayer()
    private let iconImageView = UIImageView()
    private let countLabel    = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        glowLayer.shadowRadius  = 10
        glowLayer.shadowOpacity = 0.40
        glowLayer.shadowOffset  = .zero
        layer.addSublayer(glowLayer)

        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.8, y: 1)
        layer.addSublayer(gradientLayer)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        countLabel.textColor     = .white
        countLabel.textAlignment = .center
        countLabel.font          = .systemFont(ofSize: 9, weight: .black)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.42),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = makeRoundedHexPath(in: bounds)
        shapeLayer.path     = path.cgPath
        gradientLayer.frame = bounds
        gradientLayer.mask  = shapeLayer
        glowLayer.frame     = bounds.insetBy(dx: 4, dy: 4)
        glowLayer.cornerRadius = glowLayer.bounds.width / 2
    }

    private func makeRoundedHexPath(in rect: CGRect) -> UIBezierPath {
        let cx = rect.midX, cy = rect.midY
        let r  = min(rect.width, rect.height) / 2
        let path = UIBezierPath()
        let cornerR: CGFloat = 7
        var points: [CGPoint] = []
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            points.append(CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle)))
        }
        for (i, pt) in points.enumerated() {
            let prev = points[(i + 5) % 6]
            let next = points[(i + 1) % 6]
            let d1 = CGPoint(x: pt.x - prev.x, y: pt.y - prev.y)
            let d2 = CGPoint(x: next.x - pt.x, y: next.y - pt.y)
            let len1 = sqrt(d1.x * d1.x + d1.y * d1.y)
            let len2 = sqrt(d2.x * d2.x + d2.y * d2.y)
            let cp1 = CGPoint(x: pt.x - cornerR * d1.x / len1, y: pt.y - cornerR * d1.y / len1)
            let cp2 = CGPoint(x: pt.x + cornerR * d2.x / len2, y: pt.y + cornerR * d2.y / len2)
            if i == 0 { path.move(to: cp1) } else { path.addLine(to: cp1) }
            path.addQuadCurve(to: cp2, controlPoint: pt)
        }
        path.close()
        return path
    }

    func configure(tier: GardenTier, count: Int, iconName: String, isLocked: Bool) {
        if isLocked {
            gradientLayer.colors    = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            glowLayer.shadowColor   = UIColor.clear.cgColor
            iconImageView.image     = UIImage(systemName: "lock.fill")
            iconImageView.tintColor = .systemGray
            countLabel.text         = "\(count)"
            countLabel.textColor    = .systemGray2
        } else {
            gradientLayer.colors    = tier.gradientColors
            glowLayer.shadowColor   = tier.glowColor.cgColor
            iconImageView.image     = UIImage(systemName: iconName)
            iconImageView.tintColor = .white
            countLabel.text         = "\(count)"
            countLabel.textColor    = .white
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}
