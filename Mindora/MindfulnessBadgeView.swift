import UIKit

// MARK: - Mindfulness Depth Tier
enum MindfulnessTier {
    case double   // 2 sessions
    case triple   // 3 sessions
    case deep     // 5 sessions
    case presence // 4 sessions (mind_4)

    var gradientColors: [CGColor] {
        switch self {
        case .double:
            return [
                UIColor(red: 0.30, green: 0.75, blue: 0.85, alpha: 1).cgColor,
                UIColor(red: 0.10, green: 0.50, blue: 0.70, alpha: 1).cgColor
            ]
        case .triple:
            return [
                UIColor(red: 0.45, green: 0.55, blue: 0.95, alpha: 1).cgColor,
                UIColor(red: 0.20, green: 0.30, blue: 0.80, alpha: 1).cgColor
            ]
        case .presence:
            return [
                UIColor(red: 0.60, green: 0.35, blue: 0.90, alpha: 1).cgColor,
                UIColor(red: 0.35, green: 0.15, blue: 0.70, alpha: 1).cgColor
            ]
        case .deep:
            return [
                UIColor(red: 0.10, green: 0.20, blue: 0.60, alpha: 1).cgColor,
                UIColor(red: 0.05, green: 0.10, blue: 0.40, alpha: 1).cgColor
            ]
        }
    }

    var glowColor: UIColor {
        switch self {
        case .double:   return UIColor(red: 0.20, green: 0.65, blue: 0.80, alpha: 1)
        case .triple:   return UIColor(red: 0.35, green: 0.45, blue: 0.90, alpha: 1)
        case .presence: return UIColor(red: 0.50, green: 0.25, blue: 0.85, alpha: 1)
        case .deep:     return UIColor(red: 0.10, green: 0.15, blue: 0.55, alpha: 1)
        }
    }

    var ringColor: UIColor {
        switch self {
        case .double:   return UIColor(red: 0.20, green: 0.60, blue: 0.78, alpha: 1)
        case .triple:   return UIColor(red: 0.30, green: 0.40, blue: 0.88, alpha: 1)
        case .presence: return UIColor(red: 0.45, green: 0.20, blue: 0.80, alpha: 1)
        case .deep:     return UIColor(red: 0.08, green: 0.12, blue: 0.50, alpha: 1)
        }
    }

    var label: String {
        switch self {
        case .double:   return "DOUBLE CALM"
        case .triple:   return "TRIPLE FOCUS"
        case .presence: return "DEEP PRESENCE"
        case .deep:     return "DEEP RESET"
        }
    }

    var sessionCount: Int {
        switch self {
        case .double: return 2; case .triple: return 3
        case .presence: return 4; case .deep: return 5
        }
    }

    var icon: String {
        switch self {
        case .double:   return "figure.mind.and.body"
        case .triple:   return "brain.head.profile"
        case .presence: return "waveform.path.ecg"
        case .deep:     return "lungs.fill"
        }
    }

    static func tier(for id: String) -> MindfulnessTier {
        switch id {
        case "mind_double": return .double
        case "mind_triple": return .triple
        case "mind_4":      return .presence
        case "mind_deep":   return .deep
        default:            return .double
        }
    }
}

// MARK: - Large Mindfulness Badge (Detail Screen)
class MindfulnessBadgeView: UIView {

    private let outerRingLayer = CAShapeLayer()
    private let gradientLayer  = CAGradientLayer()
    private let shapeMask      = CAShapeLayer()
    private let glowLayer      = CALayer()
    private let shimmerLayer   = CAGradientLayer()

    private let iconImageView  = UIImageView()
    private let countLabel     = UILabel()
    private let sessLabel      = UILabel()
    private let tierLabel      = UILabel()
    private let waveStack      = UIStackView()

    private var tier: MindfulnessTier = .double

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
            UIColor.white.withAlphaComponent(0.18).cgColor,
            UIColor.clear.cgColor
        ]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(shimmerLayer)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        countLabel.textColor     = .white
        countLabel.textAlignment = .center
        countLabel.font          = .systemFont(ofSize: 28, weight: .black)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)

        sessLabel.textColor     = UIColor.white.withAlphaComponent(0.85)
        sessLabel.textAlignment = .center
        sessLabel.font          = .systemFont(ofSize: 9, weight: .bold)
        sessLabel.text          = "SESSIONS"
        sessLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sessLabel)

        tierLabel.textAlignment = .center
        tierLabel.font          = .systemFont(ofSize: 8, weight: .heavy)
        tierLabel.textColor     = UIColor.white.withAlphaComponent(0.85)
        tierLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tierLabel)

        waveStack.axis         = .horizontal
        waveStack.spacing      = 4
        waveStack.alignment    = .center
        waveStack.distribution = .fillEqually
        waveStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(waveStack)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -22),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.28),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),

            sessLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            sessLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 0),

            tierLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            tierLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18),

            waveStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            waveStack.bottomAnchor.constraint(equalTo: tierLabel.topAnchor, constant: -4),
            waveStack.heightAnchor.constraint(equalToConstant: 12)
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

        // Lotus / rounded pentagon shape
        let innerPath = makeLotusPath(in: bounds.insetBy(dx: 14, dy: 14))
        gradientLayer.frame = bounds
        shapeMask.path      = innerPath.cgPath
        gradientLayer.mask  = shapeMask

        shimmerLayer.frame = bounds
        shimmerLayer.mask  = { let m = CAShapeLayer(); m.path = innerPath.cgPath; return m }()

        glowLayer.frame        = bounds.insetBy(dx: 16, dy: 16)
        glowLayer.cornerRadius = glowLayer.bounds.width / 2
    }

    // Rounded pentagon (lotus-like)
    private func makeLotusPath(in rect: CGRect) -> UIBezierPath {
        let cx = rect.midX, cy = rect.midY
        let r  = min(rect.width, rect.height) / 2
        let path = UIBezierPath()
        let cornerR: CGFloat = 10
        var points: [CGPoint] = []
        for i in 0..<5 {
            let angle = CGFloat(i) * 2 * .pi / 5 - .pi / 2
            points.append(CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle)))
        }
        for (i, pt) in points.enumerated() {
            let prev = points[(i + 4) % 5]
            let next = points[(i + 1) % 5]
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

    func configure(tier: MindfulnessTier, isLocked: Bool) {
        self.tier = tier

        if isLocked {
            gradientLayer.colors       = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            outerRingLayer.strokeColor = UIColor.systemGray3.cgColor
            glowLayer.shadowColor      = UIColor.clear.cgColor
            iconImageView.image        = UIImage(systemName: "lock.fill")
            iconImageView.tintColor    = .systemGray
            countLabel.text            = "\(tier.sessionCount)"
            countLabel.textColor       = .systemGray
            sessLabel.textColor        = .systemGray2
            tierLabel.text             = tier.label
            tierLabel.textColor        = .systemGray2
        } else {
            gradientLayer.colors       = tier.gradientColors
            outerRingLayer.strokeColor = tier.ringColor.cgColor
            glowLayer.shadowColor      = tier.glowColor.cgColor
            iconImageView.image        = UIImage(systemName: tier.icon)
            iconImageView.tintColor    = .white
            countLabel.text            = "\(tier.sessionCount)"
            countLabel.textColor       = .white
            sessLabel.textColor        = UIColor.white.withAlphaComponent(0.85)
            tierLabel.text             = tier.label
            tierLabel.textColor        = UIColor.white.withAlphaComponent(0.90)
            pulseGlow()
            addShimmer()
        }

        buildWaves(count: tier.sessionCount, isLocked: isLocked)
        setNeedsLayout(); layoutIfNeeded()
    }

    private func buildWaves(count: Int, isLocked: Bool) {
        waveStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let color: UIColor = isLocked ? .systemGray3 : .white
        let heights: [CGFloat] = [6, 10, 8, 12, 7]
        for i in 0..<count {
            let bar = UIView()
            let h = heights[i % heights.count]
            bar.backgroundColor = color.withAlphaComponent(i < count ? 1.0 : 0.25)
            bar.layer.cornerRadius = 2
            bar.widthAnchor.constraint(equalToConstant: 4).isActive = true
            bar.heightAnchor.constraint(equalToConstant: h).isActive = true
            waveStack.addArrangedSubview(bar)
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

// MARK: - Small Mindfulness Badge (Collection Cell)
class MindfulnessHexagonBadgeView: UIView {

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

        gradientLayer.startPoint = CGPoint(x: 0.1, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.9, y: 1)
        layer.addSublayer(gradientLayer)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)

        countLabel.textColor     = .white
        countLabel.textAlignment = .center
        countLabel.font          = .systemFont(ofSize: 8, weight: .black)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.40),
            iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),

            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = makeLotusPath(in: bounds)
        shapeLayer.path     = path.cgPath
        gradientLayer.frame = bounds
        gradientLayer.mask  = shapeLayer
        glowLayer.frame     = bounds.insetBy(dx: 4, dy: 4)
        glowLayer.cornerRadius = glowLayer.bounds.width / 2
    }

    private func makeLotusPath(in rect: CGRect) -> UIBezierPath {
        let cx = rect.midX, cy = rect.midY
        let r  = min(rect.width, rect.height) / 2 - 2
        let path = UIBezierPath()
        let cornerR: CGFloat = 8
        var points: [CGPoint] = []
        for i in 0..<5 {
            let angle = CGFloat(i) * 2 * .pi / 5 - .pi / 2
            points.append(CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle)))
        }
        for (i, pt) in points.enumerated() {
            let prev = points[(i + 4) % 5]
            let next = points[(i + 1) % 5]
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

    func configure(tier: MindfulnessTier, isLocked: Bool) {
        if isLocked {
            gradientLayer.colors    = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            glowLayer.shadowColor   = UIColor.clear.cgColor
            iconImageView.image     = UIImage(systemName: "lock.fill")
            iconImageView.tintColor = .systemGray
            countLabel.text         = "\(tier.sessionCount)x"
            countLabel.textColor    = .systemGray2
        } else {
            gradientLayer.colors    = tier.gradientColors
            glowLayer.shadowColor   = tier.glowColor.cgColor
            iconImageView.image     = UIImage(systemName: tier.icon)
            iconImageView.tintColor = .white
            countLabel.text         = "\(tier.sessionCount)x"
            countLabel.textColor    = .white
        }
        setNeedsLayout(); layoutIfNeeded()
    }
}
