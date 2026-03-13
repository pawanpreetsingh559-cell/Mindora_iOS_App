import UIKit

// MARK: - Growth Stage Tier
enum GrowthStageTier {
    case egg
    case caterpillar
    case cocoon
    case butterfly

    var gradientColors: [CGColor] {
        switch self {
        case .egg:
            return [
                UIColor(red: 0.95, green: 0.90, blue: 0.75, alpha: 1).cgColor,
                UIColor(red: 0.85, green: 0.75, blue: 0.55, alpha: 1).cgColor
            ]
        case .caterpillar:
            return [
                UIColor(red: 0.35, green: 0.80, blue: 0.40, alpha: 1).cgColor,
                UIColor(red: 0.15, green: 0.55, blue: 0.25, alpha: 1).cgColor
            ]
        case .cocoon:
            return [
                UIColor(red: 0.65, green: 0.50, blue: 0.85, alpha: 1).cgColor,
                UIColor(red: 0.40, green: 0.25, blue: 0.65, alpha: 1).cgColor
            ]
        case .butterfly:
            return [
                UIColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1).cgColor,
                UIColor(red: 0.90, green: 0.25, blue: 0.55, alpha: 1).cgColor
            ]
        }
    }

    var glowColor: UIColor {
        switch self {
        case .egg:         return UIColor(red: 0.85, green: 0.75, blue: 0.50, alpha: 1)
        case .caterpillar: return UIColor(red: 0.25, green: 0.70, blue: 0.30, alpha: 1)
        case .cocoon:      return UIColor(red: 0.55, green: 0.35, blue: 0.80, alpha: 1)
        case .butterfly:   return UIColor(red: 0.95, green: 0.40, blue: 0.35, alpha: 1)
        }
    }

    var ringColor: UIColor {
        switch self {
        case .egg:         return UIColor(red: 0.80, green: 0.70, blue: 0.45, alpha: 1)
        case .caterpillar: return UIColor(red: 0.20, green: 0.65, blue: 0.28, alpha: 1)
        case .cocoon:      return UIColor(red: 0.50, green: 0.30, blue: 0.75, alpha: 1)
        case .butterfly:   return UIColor(red: 0.90, green: 0.35, blue: 0.30, alpha: 1)
        }
    }

    var label: String {
        switch self {
        case .egg:         return "EGG"
        case .caterpillar: return "CATERPILLAR"
        case .cocoon:      return "COCOON"
        case .butterfly:   return "BUTTERFLY"
        }
    }

    var stageNumber: Int {
        switch self {
        case .egg: return 1; case .caterpillar: return 2
        case .cocoon: return 3; case .butterfly: return 4
        }
    }

    var icon: String {
        switch self {
        case .egg:         return "circle.fill"
        case .caterpillar: return "leaf.fill"
        case .cocoon:      return "capsule.fill"
        case .butterfly:   return "sparkles"
        }
    }

    static func tier(for id: String) -> GrowthStageTier {
        switch id {
        case "growth_egg":         return .egg
        case "growth_caterpillar": return .caterpillar
        case "growth_cocoon":      return .cocoon
        case "growth_butterfly":   return .butterfly
        default:                   return .egg
        }
    }
}

// MARK: - Large Growth Badge (Detail Screen)
class GrowthStageBadgeView: UIView {

    private let outerRingLayer  = CAShapeLayer()
    private let gradientLayer   = CAGradientLayer()
    private let shapeMask       = CAShapeLayer()
    private let glowLayer       = CALayer()
    private let shimmerLayer    = CAGradientLayer()

    private let iconImageView   = UIImageView()
    private let stageLabel      = UILabel()
    private let tierLabel       = UILabel()
    private let dotsStack       = UIStackView()

    private var tier: GrowthStageTier = .egg

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

        glowLayer.shadowRadius  = 22
        glowLayer.shadowOpacity = 0.50
        glowLayer.shadowOffset  = .zero
        layer.addSublayer(glowLayer)

        outerRingLayer.fillColor      = UIColor.clear.cgColor
        outerRingLayer.lineWidth      = 0
        outerRingLayer.lineDashPattern = nil
        layer.addSublayer(outerRingLayer)

        gradientLayer.startPoint = CGPoint(x: 0.1, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.9, y: 1)
        layer.addSublayer(gradientLayer)

        shimmerLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.20).cgColor,
            UIColor.clear.cgColor
        ]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(shimmerLayer)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        stageLabel.textColor     = .white
        stageLabel.textAlignment = .center
        stageLabel.font          = .systemFont(ofSize: 13, weight: .heavy)
        stageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stageLabel)

        tierLabel.textAlignment = .center
        tierLabel.font          = .systemFont(ofSize: 9, weight: .bold)
        tierLabel.textColor     = UIColor.white.withAlphaComponent(0.80)
        tierLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tierLabel)

        dotsStack.axis         = .horizontal
        dotsStack.spacing      = 5
        dotsStack.alignment    = .center
        dotsStack.distribution = .fillEqually
        dotsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dotsStack)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -18),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.32),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            stageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            stageLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 6),
            stageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            tierLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            tierLabel.topAnchor.constraint(equalTo: stageLabel.bottomAnchor, constant: 2),

            dotsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            dotsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),
            dotsStack.heightAnchor.constraint(equalToConstant: 10)
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

        let innerPath = makeEggPath(in: bounds.insetBy(dx: 14, dy: 14))
        gradientLayer.frame = bounds
        shapeMask.path      = innerPath.cgPath
        gradientLayer.mask  = shapeMask

        shimmerLayer.frame = bounds
        shimmerLayer.mask  = { let m = CAShapeLayer(); m.path = innerPath.cgPath; return m }()

        glowLayer.frame        = bounds.insetBy(dx: 16, dy: 16)
        glowLayer.cornerRadius = glowLayer.bounds.width / 2
    }

    // Egg-like oval shape
    private func makeEggPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let cx = rect.midX, cy = rect.midY
        let rx = rect.width / 2, ry = rect.height / 2
        // Slightly taller top for egg shape
        path.move(to: CGPoint(x: cx, y: cy - ry))
        path.addCurve(to: CGPoint(x: cx + rx, y: cy),
                      controlPoint1: CGPoint(x: cx + rx * 0.9, y: cy - ry),
                      controlPoint2: CGPoint(x: cx + rx, y: cy - ry * 0.4))
        path.addCurve(to: CGPoint(x: cx, y: cy + ry * 1.1),
                      controlPoint1: CGPoint(x: cx + rx, y: cy + ry * 0.7),
                      controlPoint2: CGPoint(x: cx + rx * 0.6, y: cy + ry * 1.1))
        path.addCurve(to: CGPoint(x: cx - rx, y: cy),
                      controlPoint1: CGPoint(x: cx - rx * 0.6, y: cy + ry * 1.1),
                      controlPoint2: CGPoint(x: cx - rx, y: cy + ry * 0.7))
        path.addCurve(to: CGPoint(x: cx, y: cy - ry),
                      controlPoint1: CGPoint(x: cx - rx, y: cy - ry * 0.4),
                      controlPoint2: CGPoint(x: cx - rx * 0.9, y: cy - ry))
        path.close()
        return path
    }

    func configure(tier: GrowthStageTier, isLocked: Bool) {
        self.tier = tier

        if isLocked {
            gradientLayer.colors       = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            outerRingLayer.strokeColor = UIColor.systemGray3.cgColor
            glowLayer.shadowColor      = UIColor.clear.cgColor
            iconImageView.image        = UIImage(systemName: "lock.fill")
            iconImageView.tintColor    = .systemGray
            stageLabel.text            = "???"
            stageLabel.textColor       = .systemGray
            tierLabel.text             = "LOCKED"
            tierLabel.textColor        = .systemGray2
        } else {
            gradientLayer.colors       = tier.gradientColors
            outerRingLayer.strokeColor = tier.ringColor.cgColor
            glowLayer.shadowColor      = tier.glowColor.cgColor
            iconImageView.image        = UIImage(systemName: tier.icon)
            iconImageView.tintColor    = .white
            stageLabel.text            = "Stage \(tier.stageNumber)"
            stageLabel.textColor       = .white
            tierLabel.text             = tier.label
            tierLabel.textColor        = UIColor.white.withAlphaComponent(0.85)
            pulseGlow()
            addShimmer()
        }

        buildDots(count: tier.stageNumber, isLocked: isLocked)
        setNeedsLayout(); layoutIfNeeded()
    }

    private func buildDots(count: Int, isLocked: Bool) {
        dotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for i in 0..<4 {
            let dot = UIView()
            dot.layer.cornerRadius = 4
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            dot.backgroundColor = (i < count && !isLocked) ? .white : UIColor.white.withAlphaComponent(0.25)
            dotsStack.addArrangedSubview(dot)
        }
    }

    private func pulseGlow() {
        let pulse = CABasicAnimation(keyPath: "shadowRadius")
        pulse.fromValue = 16; pulse.toValue = 30
        pulse.duration = 1.8; pulse.autoreverses = true; pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(pulse, forKey: "glow")
    }

    private func addShimmer() {
        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = [-0.5, -0.25, 0.0]; anim.toValue = [1.0, 1.25, 1.5]
        anim.duration = 2.2; anim.repeatCount = .infinity
        shimmerLayer.add(anim, forKey: "shimmer")
    }
}

// MARK: - Small Growth Badge (Collection Cell)
class GrowthStageHexagonBadgeView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let shapeLayer    = CAShapeLayer()
    private let glowLayer     = CALayer()
    private let iconImageView = UIImageView()
    private let stageNumLabel = UILabel()

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

        stageNumLabel.textColor     = .white
        stageNumLabel.textAlignment = .center
        stageNumLabel.font          = .systemFont(ofSize: 8, weight: .black)
        stageNumLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stageNumLabel)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.40),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            stageNumLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            stageNumLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),
            stageNumLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stageNumLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = makeEggPath(in: bounds)
        shapeLayer.path     = path.cgPath
        gradientLayer.frame = bounds
        gradientLayer.mask  = shapeLayer
        glowLayer.frame     = bounds.insetBy(dx: 4, dy: 4)
        glowLayer.cornerRadius = glowLayer.bounds.width / 2
    }

    private func makeEggPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let cx = rect.midX, cy = rect.midY
        let rx = rect.width / 2 - 2, ry = rect.height / 2 - 2
        path.move(to: CGPoint(x: cx, y: cy - ry))
        path.addCurve(to: CGPoint(x: cx + rx, y: cy),
                      controlPoint1: CGPoint(x: cx + rx * 0.9, y: cy - ry),
                      controlPoint2: CGPoint(x: cx + rx, y: cy - ry * 0.4))
        path.addCurve(to: CGPoint(x: cx, y: cy + ry * 1.1),
                      controlPoint1: CGPoint(x: cx + rx, y: cy + ry * 0.7),
                      controlPoint2: CGPoint(x: cx + rx * 0.6, y: cy + ry * 1.1))
        path.addCurve(to: CGPoint(x: cx - rx, y: cy),
                      controlPoint1: CGPoint(x: cx - rx * 0.6, y: cy + ry * 1.1),
                      controlPoint2: CGPoint(x: cx - rx, y: cy + ry * 0.7))
        path.addCurve(to: CGPoint(x: cx, y: cy - ry),
                      controlPoint1: CGPoint(x: cx - rx, y: cy - ry * 0.4),
                      controlPoint2: CGPoint(x: cx - rx * 0.9, y: cy - ry))
        path.close()
        return path
    }

    func configure(tier: GrowthStageTier, isLocked: Bool) {
        if isLocked {
            gradientLayer.colors    = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            glowLayer.shadowColor   = UIColor.clear.cgColor
            iconImageView.image     = UIImage(systemName: "lock.fill")
            iconImageView.tintColor = .systemGray
            stageNumLabel.text      = "Stage \(tier.stageNumber)"
            stageNumLabel.textColor = .systemGray2
        } else {
            gradientLayer.colors    = tier.gradientColors
            glowLayer.shadowColor   = tier.glowColor.cgColor
            iconImageView.image     = UIImage(systemName: tier.icon)
            iconImageView.tintColor = .white
            stageNumLabel.text      = "Stage \(tier.stageNumber)"
            stageNumLabel.textColor = .white
        }
        setNeedsLayout(); layoutIfNeeded()
    }
}
