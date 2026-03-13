import UIKit

// MARK: - Sessions Tier
enum SessionsTier {
    case bronze   // 10 sessions
    case silver   // 20 sessions
    case gold     // 40 sessions
    case platinum // 80 sessions

    var gradientColors: [CGColor] {
        switch self {
        case .bronze:
            return [
                UIColor(red: 0.55, green: 0.40, blue: 0.90, alpha: 1).cgColor,
                UIColor(red: 0.35, green: 0.20, blue: 0.75, alpha: 1).cgColor
            ]
        case .silver:
            return [
                UIColor(red: 0.40, green: 0.65, blue: 1.00, alpha: 1).cgColor,
                UIColor(red: 0.20, green: 0.40, blue: 0.90, alpha: 1).cgColor
            ]
        case .gold:
            return [
                UIColor(red: 0.30, green: 0.85, blue: 0.80, alpha: 1).cgColor,
                UIColor(red: 0.10, green: 0.55, blue: 0.75, alpha: 1).cgColor
            ]
        case .platinum:
            return [
                UIColor(red: 0.90, green: 0.40, blue: 0.80, alpha: 1).cgColor,
                UIColor(red: 0.55, green: 0.10, blue: 0.65, alpha: 1).cgColor
            ]
        }
    }

    var glowColor: UIColor {
        switch self {
        case .bronze:   return UIColor(red: 0.55, green: 0.35, blue: 0.90, alpha: 1)
        case .silver:   return UIColor(red: 0.30, green: 0.55, blue: 1.00, alpha: 1)
        case .gold:     return UIColor(red: 0.20, green: 0.80, blue: 0.75, alpha: 1)
        case .platinum: return UIColor(red: 0.85, green: 0.30, blue: 0.80, alpha: 1)
        }
    }

    var ringColor: UIColor {
        switch self {
        case .bronze:   return UIColor(red: 0.50, green: 0.30, blue: 0.85, alpha: 1)
        case .silver:   return UIColor(red: 0.25, green: 0.50, blue: 0.95, alpha: 1)
        case .gold:     return UIColor(red: 0.15, green: 0.70, blue: 0.70, alpha: 1)
        case .platinum: return UIColor(red: 0.80, green: 0.20, blue: 0.75, alpha: 1)
        }
    }

    var label: String {
        switch self {
        case .bronze:   return "BRONZE"
        case .silver:   return "SILVER"
        case .gold:     return "GOLD"
        case .platinum: return "PLATINUM"
        }
    }

    var starCount: Int {
        switch self {
        case .bronze:   return 1
        case .silver:   return 2
        case .gold:     return 3
        case .platinum: return 4
        }
    }

    static func tier(for sessions: Int) -> SessionsTier {
        switch sessions {
        case 10:       return .bronze
        case 11...20:  return .silver
        case 21...40:  return .gold
        default:       return .platinum  // 80+
        }
    }
}

// MARK: - Sessions Badge View (for Detail Screen)
class SessionsBadgeView: UIView {

    // MARK: - Layers
    private let outerRingLayer  = CAShapeLayer()
    private let innerRingLayer  = CAShapeLayer()
    private let gradientLayer   = CAGradientLayer()
    private let maskLayer       = CAShapeLayer()
    private let glowLayer       = CALayer()

    // MARK: - Subviews
    private let iconImageView   = UIImageView()
    private let countLabel      = UILabel()
    private let unitLabel       = UILabel()
    private let tierLabel       = UILabel()
    private let starsStack      = UIStackView()

    // MARK: - State
    private var tier: SessionsTier = .bronze
    private var isLocked: Bool = false

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup
    private func setup() {
        backgroundColor = .clear

        // Glow
        glowLayer.cornerRadius = 60
        glowLayer.shadowRadius = 24
        glowLayer.shadowOpacity = 0.55
        glowLayer.shadowOffset = .zero
        layer.addSublayer(glowLayer)

        // Outer dashed ring
        outerRingLayer.fillColor = UIColor.clear.cgColor
        outerRingLayer.lineWidth = 0
        outerRingLayer.lineDashPattern = nil
        layer.addSublayer(outerRingLayer)

        // Gradient fill (circle shape)
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.8, y: 1)
        layer.addSublayer(gradientLayer)

        // Inner ring
        innerRingLayer.fillColor   = UIColor.clear.cgColor
        innerRingLayer.lineWidth   = 2
        innerRingLayer.opacity     = 0.4
        innerRingLayer.strokeColor = UIColor.white.cgColor
        layer.addSublayer(innerRingLayer)

        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        // Session count
        countLabel.textColor     = .white
        countLabel.textAlignment = .center
        countLabel.font          = .systemFont(ofSize: 28, weight: .black)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)

        // "SESSIONS" unit label
        unitLabel.textColor     = UIColor.white.withAlphaComponent(0.85)
        unitLabel.textAlignment = .center
        unitLabel.font          = .systemFont(ofSize: 9, weight: .bold)
        unitLabel.text          = "SESSIONS"
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(unitLabel)

        // Tier label
        tierLabel.textAlignment = .center
        tierLabel.font          = .systemFont(ofSize: 9, weight: .heavy)
        tierLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tierLabel)

        // Stars stack
        starsStack.axis         = .horizontal
        starsStack.spacing      = 3
        starsStack.alignment    = .center
        starsStack.distribution = .fillEqually
        starsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(starsStack)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.28),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),

            unitLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            unitLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 0),

            tierLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            tierLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),

            starsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            starsStack.bottomAnchor.constraint(equalTo: tierLabel.topAnchor, constant: -4),
            starsStack.heightAnchor.constraint(equalToConstant: 12)
        ])
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        let size   = min(bounds.width, bounds.height)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let outerR = size / 2 - 4

        // Outer dashed ring (circle)
        let outerPath = UIBezierPath(arcCenter: center, radius: outerR,
                                     startAngle: 0, endAngle: .pi * 2, clockwise: true)
        outerRingLayer.path  = outerPath.cgPath
        outerRingLayer.frame = bounds

        // Circle shape for gradient fill
        let innerR = size / 2 - 18
        let circlePath = UIBezierPath(arcCenter: center, radius: innerR,
                                      startAngle: 0, endAngle: .pi * 2, clockwise: true)
        gradientLayer.frame = bounds
        maskLayer.path      = circlePath.cgPath
        gradientLayer.mask  = maskLayer

        // Inner ring follows circle
        innerRingLayer.path  = circlePath.cgPath
        innerRingLayer.frame = bounds

        // Glow
        glowLayer.frame        = bounds.insetBy(dx: 16, dy: 16)
        glowLayer.cornerRadius = glowLayer.bounds.width / 2
    }

    // MARK: - Configure
    func configure(tier: SessionsTier, sessions: Int, iconName: String, isLocked: Bool) {
        self.tier     = tier
        self.isLocked = isLocked

        if isLocked {
            gradientLayer.colors       = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            outerRingLayer.strokeColor = UIColor.systemGray3.cgColor
            glowLayer.shadowColor      = UIColor.clear.cgColor
            iconImageView.image        = UIImage(systemName: "lock.fill")
            iconImageView.tintColor    = .systemGray
            countLabel.text            = "\(sessions)"
            countLabel.textColor       = .systemGray
            unitLabel.textColor        = .systemGray2
            tierLabel.text             = tier.label
            tierLabel.textColor        = .systemGray2
        } else {
            gradientLayer.colors       = tier.gradientColors
            outerRingLayer.strokeColor = tier.ringColor.cgColor
            glowLayer.shadowColor      = tier.glowColor.cgColor
            iconImageView.image        = UIImage(systemName: iconName)
            iconImageView.tintColor    = .white
            countLabel.text            = "\(sessions)"
            countLabel.textColor       = .white
            unitLabel.textColor        = UIColor.white.withAlphaComponent(0.85)
            tierLabel.text             = tier.label
            tierLabel.textColor        = UIColor.white.withAlphaComponent(0.9)
            pulseGlow()
        }

        buildStars(count: tier.starCount, isLocked: isLocked)
        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: - Stars
    private func buildStars(count: Int, isLocked: Bool) {
        starsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let color: UIColor = isLocked ? .systemGray3 : .white
        for _ in 0..<count {
            let iv = UIImageView(image: UIImage(systemName: "star.fill"))
            iv.tintColor = color
            iv.contentMode = .scaleAspectFit
            iv.widthAnchor.constraint(equalToConstant: 10).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 10).isActive = true
            starsStack.addArrangedSubview(iv)
        }
    }

    // MARK: - Glow Pulse Animation
    private func pulseGlow() {
        let pulse = CABasicAnimation(keyPath: "shadowRadius")
        pulse.fromValue      = 18
        pulse.toValue        = 30
        pulse.duration       = 1.6
        pulse.autoreverses   = true
        pulse.repeatCount    = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(pulse, forKey: "glowPulse")

        let opacityPulse = CABasicAnimation(keyPath: "shadowOpacity")
        opacityPulse.fromValue      = 0.35
        opacityPulse.toValue        = 0.70
        opacityPulse.duration       = 1.6
        opacityPulse.autoreverses   = true
        opacityPulse.repeatCount    = .infinity
        opacityPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(opacityPulse, forKey: "opacityPulse")
    }
}

// MARK: - Small Sessions Badge (for Collection Cell)
class SessionsHexagonBadgeView: UIView {

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
        glowLayer.shadowOpacity = 0.4
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
        // Use the same shield path as other hexagon badges for visual consistency
        let path = makeShieldPath(in: bounds)
        shapeLayer.path     = path.cgPath
        gradientLayer.frame = bounds
        gradientLayer.mask  = shapeLayer
        glowLayer.frame     = bounds.insetBy(dx: 4, dy: 4)
        glowLayer.cornerRadius = glowLayer.bounds.width / 2
    }

    private func makeShieldPath(in rect: CGRect) -> UIBezierPath {
        let w = rect.width, h = rect.height
        let x = rect.minX,  y = rect.minY
        let r: CGFloat = 10
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x + r, y: y))
        path.addLine(to: CGPoint(x: x + w - r, y: y))
        path.addQuadCurve(to: CGPoint(x: x + w, y: y + r), controlPoint: CGPoint(x: x + w, y: y))
        path.addLine(to: CGPoint(x: x + w, y: y + h * 0.60))
        path.addQuadCurve(to: CGPoint(x: x + w / 2, y: y + h), controlPoint: CGPoint(x: x + w, y: y + h))
        path.addQuadCurve(to: CGPoint(x: x, y: y + h * 0.60), controlPoint: CGPoint(x: x, y: y + h))
        path.addLine(to: CGPoint(x: x, y: y + r))
        path.addQuadCurve(to: CGPoint(x: x + r, y: y), controlPoint: CGPoint(x: x, y: y))
        path.close()
        return path
    }

    func configure(tier: SessionsTier, sessions: Int, iconName: String, isLocked: Bool) {
        if isLocked {
            gradientLayer.colors    = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            glowLayer.shadowColor   = UIColor.clear.cgColor
            iconImageView.image     = UIImage(systemName: "lock.fill")
            iconImageView.tintColor = .systemGray
            countLabel.text         = "\(sessions)"
            countLabel.textColor    = .systemGray2
        } else {
            gradientLayer.colors    = tier.gradientColors
            glowLayer.shadowColor   = tier.glowColor.cgColor
            iconImageView.image     = UIImage(systemName: iconName)
            iconImageView.tintColor = .white
            countLabel.text         = "\(sessions)"
            countLabel.textColor    = .white
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}
