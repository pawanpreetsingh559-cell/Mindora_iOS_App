import UIKit

// MARK: - Points Tier
enum PointsTier {
    case bronze    // 200
    case silver    // 350
    case gold      // 600
    case sapphire  // 800
    case amethyst  // 1200
    case diamond   // 2000

    var gradientColors: [CGColor] {
        switch self {
        case .bronze:
            return [
                UIColor(red: 0.90, green: 0.60, blue: 0.30, alpha: 1).cgColor,
                UIColor(red: 0.65, green: 0.35, blue: 0.10, alpha: 1).cgColor
            ]
        case .silver:
            return [
                UIColor(red: 0.88, green: 0.88, blue: 0.95, alpha: 1).cgColor,
                UIColor(red: 0.58, green: 0.62, blue: 0.75, alpha: 1).cgColor
            ]
        case .gold:
            return [
                UIColor(red: 1.00, green: 0.88, blue: 0.20, alpha: 1).cgColor,
                UIColor(red: 0.90, green: 0.60, blue: 0.05, alpha: 1).cgColor
            ]
        case .sapphire:
            return [
                UIColor(red: 0.20, green: 0.55, blue: 1.00, alpha: 1).cgColor,
                UIColor(red: 0.05, green: 0.25, blue: 0.80, alpha: 1).cgColor
            ]
        case .amethyst:
            return [
                UIColor(red: 0.75, green: 0.35, blue: 1.00, alpha: 1).cgColor,
                UIColor(red: 0.45, green: 0.10, blue: 0.75, alpha: 1).cgColor
            ]
        case .diamond:
            return [
                UIColor(red: 0.70, green: 0.95, blue: 1.00, alpha: 1).cgColor,
                UIColor(red: 0.35, green: 0.70, blue: 0.95, alpha: 1).cgColor
            ]
        }
    }

    var glowColor: UIColor {
        switch self {
        case .bronze:   return UIColor(red: 0.80, green: 0.50, blue: 0.20, alpha: 1)
        case .silver:   return UIColor(red: 0.65, green: 0.68, blue: 0.80, alpha: 1)
        case .gold:     return UIColor(red: 1.00, green: 0.80, blue: 0.10, alpha: 1)
        case .sapphire: return UIColor(red: 0.15, green: 0.45, blue: 0.95, alpha: 1)
        case .amethyst: return UIColor(red: 0.65, green: 0.25, blue: 0.90, alpha: 1)
        case .diamond:  return UIColor(red: 0.50, green: 0.85, blue: 1.00, alpha: 1)
        }
    }

    var ringColor: UIColor {
        switch self {
        case .bronze:   return UIColor(red: 0.75, green: 0.45, blue: 0.15, alpha: 1)
        case .silver:   return UIColor(red: 0.55, green: 0.60, blue: 0.75, alpha: 1)
        case .gold:     return UIColor(red: 0.90, green: 0.70, blue: 0.05, alpha: 1)
        case .sapphire: return UIColor(red: 0.15, green: 0.40, blue: 0.90, alpha: 1)
        case .amethyst: return UIColor(red: 0.60, green: 0.20, blue: 0.85, alpha: 1)
        case .diamond:  return UIColor(red: 0.40, green: 0.80, blue: 0.95, alpha: 1)
        }
    }

    var label: String {
        switch self {
        case .bronze:   return "BRONZE"
        case .silver:   return "SILVER"
        case .gold:     return "GOLD"
        case .sapphire: return "SAPPHIRE"
        case .amethyst: return "AMETHYST"
        case .diamond:  return "DIAMOND"
        }
    }

    var gemCount: Int {
        switch self {
        case .bronze:   return 1
        case .silver:   return 2
        case .gold:     return 3
        case .sapphire: return 4
        case .amethyst: return 5
        case .diamond:  return 6
        }
    }

    var gemIcon: String {
        switch self {
        case .bronze:   return "circle.fill"
        case .silver:   return "diamond.fill"
        case .gold:     return "star.fill"
        case .sapphire: return "rhombus.fill"
        case .amethyst: return "hexagon.fill"
        case .diamond:  return "sparkle"
        }
    }

    static func tier(for points: Int) -> PointsTier {
        switch points {
        case ..<350:    return .bronze
        case 350..<600: return .silver
        case 600..<800: return .gold
        case 800..<1200: return .sapphire
        case 1200..<2000: return .amethyst
        default:        return .diamond
        }
    }
}

// MARK: - Large Points Badge (Detail Screen)
class PointsBadgeView: UIView {

    private let outerRingLayer  = CAShapeLayer()
    private let gradientLayer   = CAGradientLayer()
    private let diamondMask     = CAShapeLayer()
    private let glowLayer       = CALayer()
    private let innerRingLayer  = CAShapeLayer()
    private let shimmerLayer    = CAGradientLayer()

    private let iconImageView   = UIImageView()
    private let pointsLabel     = UILabel()
    private let ptsWordLabel    = UILabel()
    private let tierLabel       = UILabel()
    private let gemsStack       = UIStackView()

    private var tier: PointsTier = .bronze

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

        glowLayer.shadowRadius  = 24
        glowLayer.shadowOpacity = 0.55
        glowLayer.shadowOffset  = .zero
        layer.addSublayer(glowLayer)

        outerRingLayer.fillColor      = UIColor.clear.cgColor
        outerRingLayer.lineWidth      = 0
        outerRingLayer.lineDashPattern = nil
        layer.addSublayer(outerRingLayer)

        gradientLayer.startPoint = CGPoint(x: 0.1, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.9, y: 1)
        layer.addSublayer(gradientLayer)

        // Shimmer overlay
        shimmerLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.18).cgColor,
            UIColor.clear.cgColor
        ]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(shimmerLayer)

        innerRingLayer.fillColor   = UIColor.clear.cgColor
        innerRingLayer.lineWidth   = 1.5
        innerRingLayer.opacity     = 0.35
        innerRingLayer.strokeColor = UIColor.white.cgColor
        layer.addSublayer(innerRingLayer)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        pointsLabel.textColor     = .white
        pointsLabel.textAlignment = .center
        pointsLabel.font          = .systemFont(ofSize: 24, weight: .black)
        pointsLabel.adjustsFontSizeToFitWidth = true
        pointsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pointsLabel)

        ptsWordLabel.textColor     = UIColor.white.withAlphaComponent(0.85)
        ptsWordLabel.textAlignment = .center
        ptsWordLabel.font          = .systemFont(ofSize: 9, weight: .bold)
        ptsWordLabel.text          = "POINTS"
        ptsWordLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ptsWordLabel)

        tierLabel.textAlignment = .center
        tierLabel.font          = .systemFont(ofSize: 9, weight: .heavy)
        tierLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tierLabel)

        gemsStack.axis         = .horizontal
        gemsStack.spacing      = 3
        gemsStack.alignment    = .center
        gemsStack.distribution = .fillEqually
        gemsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gemsStack)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.28),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            pointsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            pointsLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),
            pointsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            pointsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            ptsWordLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            ptsWordLabel.topAnchor.constraint(equalTo: pointsLabel.bottomAnchor, constant: 0),

            tierLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            tierLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),

            gemsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            gemsStack.bottomAnchor.constraint(equalTo: tierLabel.topAnchor, constant: -4),
            gemsStack.heightAnchor.constraint(equalToConstant: 10)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let size   = min(bounds.width, bounds.height)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let outerR = size / 2 - 4

        let outerPath = UIBezierPath(arcCenter: center, radius: outerR,
                                     startAngle: 0, endAngle: .pi * 2, clockwise: true)
        outerRingLayer.path  = outerPath.cgPath
        outerRingLayer.frame = bounds

        // Diamond / octagon shape
        let diamondPath = makeDiamondPath(in: bounds.insetBy(dx: 16, dy: 16))
        gradientLayer.frame = bounds
        diamondMask.path    = diamondPath.cgPath
        gradientLayer.mask  = diamondMask

        shimmerLayer.frame = bounds
        shimmerLayer.mask  = { let m = CAShapeLayer(); m.path = diamondPath.cgPath; return m }()

        innerRingLayer.path  = diamondPath.cgPath
        innerRingLayer.frame = bounds

        glowLayer.frame        = bounds.insetBy(dx: 14, dy: 14)
        glowLayer.cornerRadius = glowLayer.bounds.width / 2
    }

    // Rounded octagon (gem-like)
    private func makeDiamondPath(in rect: CGRect) -> UIBezierPath {
        let cx = rect.midX, cy = rect.midY
        let r  = min(rect.width, rect.height) / 2
        let path = UIBezierPath()
        let cornerR: CGFloat = 8
        var points: [CGPoint] = []
        for i in 0..<8 {
            let angle = CGFloat(i) * .pi / 4 - .pi / 8
            points.append(CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle)))
        }
        for (i, pt) in points.enumerated() {
            let prev = points[(i + 7) % 8]
            let next = points[(i + 1) % 8]
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

    func configure(tier: PointsTier, points: Int, iconName: String, isLocked: Bool) {
        self.tier = tier

        if isLocked {
            gradientLayer.colors       = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            outerRingLayer.strokeColor = UIColor.systemGray3.cgColor
            glowLayer.shadowColor      = UIColor.clear.cgColor
            iconImageView.image        = UIImage(systemName: "lock.fill")
            iconImageView.tintColor    = .systemGray
            pointsLabel.text           = "\(points)"
            pointsLabel.textColor      = .systemGray
            ptsWordLabel.textColor     = .systemGray2
            tierLabel.text             = tier.label
            tierLabel.textColor        = .systemGray2
        } else {
            gradientLayer.colors       = tier.gradientColors
            outerRingLayer.strokeColor = tier.ringColor.cgColor
            glowLayer.shadowColor      = tier.glowColor.cgColor
            iconImageView.image        = UIImage(systemName: iconName)
            iconImageView.tintColor    = .white
            pointsLabel.text           = "\(points)"
            pointsLabel.textColor      = .white
            ptsWordLabel.textColor     = UIColor.white.withAlphaComponent(0.85)
            tierLabel.text             = tier.label
            tierLabel.textColor        = UIColor.white.withAlphaComponent(0.9)
            pulseGlow()
            addShimmerAnimation()
        }

        buildGems(count: tier.gemCount, isLocked: isLocked)
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func buildGems(count: Int, isLocked: Bool) {
        gemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let color: UIColor = isLocked ? .systemGray3 : .white
        for _ in 0..<count {
            let iv = UIImageView(image: UIImage(systemName: tier.gemIcon))
            iv.tintColor = color
            iv.contentMode = .scaleAspectFit
            iv.widthAnchor.constraint(equalToConstant: 9).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 9).isActive = true
            gemsStack.addArrangedSubview(iv)
        }
    }

    private func pulseGlow() {
        let pulse = CABasicAnimation(keyPath: "shadowRadius")
        pulse.fromValue    = 18
        pulse.toValue      = 32
        pulse.duration     = 1.8
        pulse.autoreverses = true
        pulse.repeatCount  = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(pulse, forKey: "glowPulse")

        let opPulse = CABasicAnimation(keyPath: "shadowOpacity")
        opPulse.fromValue    = 0.35
        opPulse.toValue      = 0.70
        opPulse.duration     = 1.8
        opPulse.autoreverses = true
        opPulse.repeatCount  = .infinity
        opPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(opPulse, forKey: "opacityPulse")
    }

    private func addShimmerAnimation() {
        let shimmer = CABasicAnimation(keyPath: "locations")
        shimmer.fromValue  = [-0.5, -0.25, 0.0]
        shimmer.toValue    = [1.0, 1.25, 1.5]
        shimmer.duration   = 2.4
        shimmer.repeatCount = .infinity
        shimmer.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shimmerLayer.add(shimmer, forKey: "shimmer")
    }
}

// MARK: - Small Points Badge (Collection Cell)
class PointsHexagonBadgeView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let shapeLayer    = CAShapeLayer()
    private let glowLayer     = CALayer()
    private let iconImageView = UIImageView()
    private let ptsLabel      = UILabel()

    private var tier: PointsTier = .bronze

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

        gradientLayer.startPoint = CGPoint(x: 0.1, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.9, y: 1)
        layer.addSublayer(gradientLayer)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        ptsLabel.textColor     = .white
        ptsLabel.textAlignment = .center
        ptsLabel.font          = .systemFont(ofSize: 8, weight: .black)
        ptsLabel.adjustsFontSizeToFitWidth = true
        ptsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(ptsLabel)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.40),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            ptsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            ptsLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),
            ptsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            ptsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = makeDiamondPath(in: bounds)
        shapeLayer.path     = path.cgPath
        gradientLayer.frame = bounds
        gradientLayer.mask  = shapeLayer
        glowLayer.frame     = bounds.insetBy(dx: 4, dy: 4)
        glowLayer.cornerRadius = glowLayer.bounds.width / 2
    }

    private func makeDiamondPath(in rect: CGRect) -> UIBezierPath {
        let cx = rect.midX, cy = rect.midY
        let r  = min(rect.width, rect.height) / 2
        let path = UIBezierPath()
        let cornerR: CGFloat = 6
        var points: [CGPoint] = []
        for i in 0..<8 {
            let angle = CGFloat(i) * .pi / 4 - .pi / 8
            points.append(CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle)))
        }
        for (i, pt) in points.enumerated() {
            let prev = points[(i + 7) % 8]
            let next = points[(i + 1) % 8]
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

    func configure(tier: PointsTier, points: Int, iconName: String, isLocked: Bool) {
        self.tier = tier
        if isLocked {
            gradientLayer.colors    = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            glowLayer.shadowColor   = UIColor.clear.cgColor
            iconImageView.image     = UIImage(systemName: "lock.fill")
            iconImageView.tintColor = .systemGray
            ptsLabel.text           = "\(points)pt"
            ptsLabel.textColor      = .systemGray2
        } else {
            gradientLayer.colors    = tier.gradientColors
            glowLayer.shadowColor   = tier.glowColor.cgColor
            iconImageView.image     = UIImage(systemName: iconName)
            iconImageView.tintColor = .white
            ptsLabel.text           = "\(points)pt"
            ptsLabel.textColor      = .white
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}
