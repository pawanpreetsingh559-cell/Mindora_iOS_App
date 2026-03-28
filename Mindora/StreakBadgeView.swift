import UIKit

// MARK: - Streak Tier
enum StreakTier {
    case bronze   // 3 days
    case silver   // 7 days
    case gold     // 30 days
    case platinum // 60 days

    var gradientColors: [CGColor] {
        switch self {
        case .bronze:
            return [
                UIColor(red: 1.0,  green: 0.60, blue: 0.20, alpha: 1).cgColor,
                UIColor(red: 0.85, green: 0.35, blue: 0.05, alpha: 1).cgColor
            ]
        case .silver:
            return [
                UIColor(red: 0.85, green: 0.85, blue: 0.95, alpha: 1).cgColor,
                UIColor(red: 0.55, green: 0.60, blue: 0.72, alpha: 1).cgColor
            ]
        case .gold:
            return [
                UIColor(red: 1.0,  green: 0.88, blue: 0.20, alpha: 1).cgColor,
                UIColor(red: 0.95, green: 0.60, blue: 0.05, alpha: 1).cgColor
            ]
        case .platinum:
            return [
                UIColor(red: 0.60, green: 0.90, blue: 1.0,  alpha: 1).cgColor,
                UIColor(red: 0.30, green: 0.55, blue: 0.95, alpha: 1).cgColor
            ]
        }
    }

    var glowColor: UIColor {
        switch self {
        case .bronze:   return UIColor(red: 1.0, green: 0.50, blue: 0.10, alpha: 1)
        case .silver:   return UIColor(red: 0.70, green: 0.75, blue: 0.90, alpha: 1)
        case .gold:     return UIColor(red: 1.0, green: 0.80, blue: 0.10, alpha: 1)
        case .platinum: return UIColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 1)
        }
    }

    var ringColor: UIColor {
        switch self {
        case .bronze:   return UIColor(red: 0.90, green: 0.45, blue: 0.10, alpha: 1)
        case .silver:   return UIColor(red: 0.60, green: 0.65, blue: 0.80, alpha: 1)
        case .gold:     return UIColor(red: 0.95, green: 0.75, blue: 0.05, alpha: 1)
        case .platinum: return UIColor(red: 0.30, green: 0.70, blue: 1.0, alpha: 1)
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

    static func tier(for days: Int) -> StreakTier {
        switch days {
        case 3:        return .bronze
        case 4...7:    return .silver
        case 8...30:   return .gold
        default:       return .platinum   // 60+
        }
    }
}

// MARK: - Streak Badge View (for Detail Screen)
class StreakBadgeView: UIView {

    // MARK: - Layers
    private let outerRingLayer   = CAShapeLayer()
    private let innerRingLayer   = CAShapeLayer()
    private let gradientLayer    = CAGradientLayer()
    private let shieldMaskLayer  = CAShapeLayer()
    private let glowLayer        = CALayer()

    // MARK: - Subviews
    private let iconImageView    = UIImageView()
    private let dayCountLabel    = UILabel()
    private let dayWordLabel     = UILabel()

    // MARK: - State
    private var tier: StreakTier = .bronze
    private var isLocked: Bool   = false

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

        // Outer decorative ring
        outerRingLayer.fillColor   = UIColor.clear.cgColor
        outerRingLayer.lineWidth   = 0
        outerRingLayer.lineDashPattern = nil
        layer.addSublayer(outerRingLayer)

        // Shield gradient fill
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

        // Day count
        dayCountLabel.textColor     = .white
        dayCountLabel.textAlignment = .center
        dayCountLabel.font          = .systemFont(ofSize: 28, weight: .black)
        dayCountLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dayCountLabel)

        // "DAYS" word
        dayWordLabel.textColor     = UIColor.white.withAlphaComponent(0.85)
        dayWordLabel.textAlignment = .center
        dayWordLabel.font          = .systemFont(ofSize: 10, weight: .bold)
        dayWordLabel.text          = "DAYS"
        dayWordLabel.letterSpacing = 2
        dayWordLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dayWordLabel)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.30),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            dayCountLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dayCountLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),

            dayWordLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dayWordLabel.topAnchor.constraint(equalTo: dayCountLabel.bottomAnchor, constant: 0)
        ])
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        let size   = min(bounds.width, bounds.height)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let outerR = size / 2 - 4

        // Outer dashed ring
        let outerPath = UIBezierPath(arcCenter: center, radius: outerR, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        outerRingLayer.path   = outerPath.cgPath
        outerRingLayer.frame  = bounds

        // Shield shape (rounded pentagon-ish)
        let shieldPath = makeShieldPath(in: bounds.insetBy(dx: 18, dy: 18))
        gradientLayer.frame = bounds
        shieldMaskLayer.path = shieldPath.cgPath
        gradientLayer.mask  = shieldMaskLayer

        // Inner ring follows shield
        innerRingLayer.path  = shieldPath.cgPath
        innerRingLayer.frame = bounds

        // Glow
        glowLayer.frame        = bounds.insetBy(dx: 16, dy: 16)
        glowLayer.cornerRadius = glowLayer.bounds.width / 2
    }

    // MARK: - Shield Path
    private func makeShieldPath(in rect: CGRect) -> UIBezierPath {
        let w = rect.width, h = rect.height
        let x = rect.minX,  y = rect.minY
        let r: CGFloat = 16

        let path = UIBezierPath()
        // Top-left corner
        path.move(to: CGPoint(x: x + r, y: y))
        // Top edge → top-right corner
        path.addLine(to: CGPoint(x: x + w - r, y: y))
        path.addQuadCurve(to: CGPoint(x: x + w, y: y + r), controlPoint: CGPoint(x: x + w, y: y))
        // Right edge → bottom-right curve
        path.addLine(to: CGPoint(x: x + w, y: y + h * 0.60))
        // Curve to bottom point
        path.addQuadCurve(to: CGPoint(x: x + w / 2, y: y + h),
                          controlPoint: CGPoint(x: x + w, y: y + h))
        // Left side
        path.addQuadCurve(to: CGPoint(x: x, y: y + h * 0.60),
                          controlPoint: CGPoint(x: x, y: y + h))
        // Left edge → top-left corner
        path.addLine(to: CGPoint(x: x, y: y + r))
        path.addQuadCurve(to: CGPoint(x: x + r, y: y), controlPoint: CGPoint(x: x, y: y))
        path.close()
        return path
    }

    // MARK: - Configure
    func configure(tier: StreakTier, days: Int, iconName: String, isLocked: Bool) {
        self.tier     = tier
        self.isLocked = isLocked

        if isLocked {
            gradientLayer.colors = [
                UIColor.systemGray4.cgColor,
                UIColor.systemGray3.cgColor
            ]
            outerRingLayer.strokeColor = UIColor.systemGray3.cgColor
            glowLayer.shadowColor      = UIColor.clear.cgColor
            iconImageView.image        = UIImage(systemName: "lock.fill")
            iconImageView.tintColor    = .systemGray
            dayCountLabel.text         = "\(days)"
            dayCountLabel.textColor    = .systemGray
            dayWordLabel.textColor     = .systemGray2
        } else {
            gradientLayer.colors       = tier.gradientColors
            outerRingLayer.strokeColor = tier.ringColor.cgColor
            glowLayer.shadowColor      = tier.glowColor.cgColor
            iconImageView.image        = UIImage(systemName: iconName)
            iconImageView.tintColor    = .white
            dayCountLabel.text         = "\(days)"
            dayCountLabel.textColor    = .white
            dayWordLabel.textColor     = UIColor.white.withAlphaComponent(0.85)
            pulseGlow()
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: - Glow Pulse Animation
    private func pulseGlow() {
        let pulse = CABasicAnimation(keyPath: "shadowRadius")
        pulse.fromValue  = 18
        pulse.toValue    = 30
        pulse.duration   = 1.6
        pulse.autoreverses = true
        pulse.repeatCount  = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(pulse, forKey: "glowPulse")

        let opacityPulse = CABasicAnimation(keyPath: "shadowOpacity")
        opacityPulse.fromValue   = 0.35
        opacityPulse.toValue     = 0.70
        opacityPulse.duration    = 1.6
        opacityPulse.autoreverses  = true
        opacityPulse.repeatCount   = .infinity
        opacityPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(opacityPulse, forKey: "opacityPulse")
    }
}

// MARK: - Small Streak Badge (for Collection Cell)
class StreakHexagonBadgeView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let shapeLayer    = CAShapeLayer()
    private let glowLayer     = CALayer()
    private let iconImageView = UIImageView()
    private let dayLabel      = UILabel()

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

        dayLabel.textColor     = .white
        dayLabel.textAlignment = .center
        dayLabel.font          = .systemFont(ofSize: 9, weight: .black)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dayLabel)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.42),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            dayLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dayLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = makeShieldPath(in: bounds)
        shapeLayer.path  = path.cgPath
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

    func configure(tier: StreakTier, days: Int, iconName: String, isLocked: Bool) {
        if isLocked {
            gradientLayer.colors   = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            glowLayer.shadowColor  = UIColor.clear.cgColor
            iconImageView.image    = UIImage(systemName: "lock.fill")
            iconImageView.tintColor = .systemGray
            dayLabel.text          = "\(days)d"
            dayLabel.textColor     = .systemGray2
        } else {
            gradientLayer.colors   = tier.gradientColors
            glowLayer.shadowColor  = tier.glowColor.cgColor
            iconImageView.image    = UIImage(systemName: iconName)
            iconImageView.tintColor = .white
            dayLabel.text          = "\(days)d"
            dayLabel.textColor     = .white
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - UILabel letter spacing helper
private extension UILabel {
    var letterSpacing: CGFloat {
        get { return 0 }
        set {
            guard let t = text else { return }
            let attr = NSMutableAttributedString(string: t)
            attr.addAttribute(.kern, value: newValue, range: NSRange(location: 0, length: attr.length))
            attributedText = attr
        }
    }
}
