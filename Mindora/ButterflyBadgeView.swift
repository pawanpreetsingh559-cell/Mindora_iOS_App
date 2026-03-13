import UIKit

// MARK: - ButterflyDetailTier

enum ButterflyDetailTier {
    case bronze, silver, gold, platinum

    static func tier(for count: Int) -> ButterflyDetailTier {
        switch count {
        case ..<15:  return .bronze
        case ..<30:  return .silver
        case ..<60:  return .gold
        default:     return .platinum
        }
    }

    var gradientColors: [CGColor] {
        switch self {
        case .bronze:
            return [UIColor(red: 0.95, green: 0.60, blue: 0.40, alpha: 1).cgColor,
                    UIColor(red: 0.80, green: 0.40, blue: 0.20, alpha: 1).cgColor]
        case .silver:
            return [UIColor(red: 0.75, green: 0.80, blue: 0.90, alpha: 1).cgColor,
                    UIColor(red: 0.55, green: 0.60, blue: 0.75, alpha: 1).cgColor]
        case .gold:
            return [UIColor(red: 1.00, green: 0.85, blue: 0.30, alpha: 1).cgColor,
                    UIColor(red: 0.90, green: 0.65, blue: 0.10, alpha: 1).cgColor]
        case .platinum:
            return [UIColor(red: 0.85, green: 0.55, blue: 1.00, alpha: 1).cgColor,
                    UIColor(red: 0.55, green: 0.25, blue: 0.90, alpha: 1).cgColor]
        }
    }

    var glowColor: UIColor {
        switch self {
        case .bronze:   return UIColor(red: 0.95, green: 0.60, blue: 0.40, alpha: 1)
        case .silver:   return UIColor(red: 0.70, green: 0.75, blue: 0.90, alpha: 1)
        case .gold:     return UIColor(red: 1.00, green: 0.85, blue: 0.30, alpha: 1)
        case .platinum: return UIColor(red: 0.85, green: 0.55, blue: 1.00, alpha: 1)
        }
    }

    var ringColor: UIColor { glowColor }

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
}

// MARK: - ButterflyDetailBadgeView (large — used on detail screen)

class ButterflyDetailBadgeView: UIView {

    private let circleLayer   = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let glowLayer     = CALayer()
    private let iconImageView = UIImageView()
    private let countLabel    = UILabel()
    private let tierLabel     = UILabel()
    private var starViews: [UIImageView] = []

    private var tier: ButterflyDetailTier = .bronze
    private var isLocked: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        backgroundColor = .clear

        // Glow
        glowLayer.shadowRadius  = 20
        glowLayer.shadowOpacity = 0.6
        glowLayer.shadowOffset  = .zero
        layer.addSublayer(glowLayer)

        // Gradient circle
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradientLayer)

        // Ring
        circleLayer.fillColor   = UIColor.clear.cgColor
        circleLayer.lineWidth   = 3
        layer.addSublayer(circleLayer)

        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white
        addSubview(iconImageView)

        // Count label
        countLabel.textAlignment = .center
        countLabel.textColor     = .white
        countLabel.font          = .systemFont(ofSize: 28, weight: .heavy)
        addSubview(countLabel)

        // Tier label
        tierLabel.textAlignment = .center
        tierLabel.textColor     = UIColor.white.withAlphaComponent(0.85)
        tierLabel.font          = .systemFont(ofSize: 11, weight: .bold)
        addSubview(tierLabel)
    }

    func configure(tier: ButterflyDetailTier, count: Int, iconName: String, isLocked: Bool) {
        self.tier     = tier
        self.isLocked = isLocked

        if isLocked {
            gradientLayer.colors = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            circleLayer.strokeColor = UIColor.systemGray3.cgColor
            glowLayer.shadowColor   = UIColor.clear.cgColor
            iconImageView.image     = UIImage(systemName: "lock.fill")
            iconImageView.tintColor = UIColor.systemGray3
            countLabel.text         = "?"
            countLabel.textColor    = .systemGray3
            tierLabel.text          = "LOCKED"
            tierLabel.textColor     = .systemGray3
        } else {
            gradientLayer.colors    = tier.gradientColors
            circleLayer.strokeColor = tier.ringColor.cgColor
            glowLayer.shadowColor   = tier.glowColor.cgColor
            iconImageView.image     = UIImage(systemName: iconName)
            iconImageView.tintColor = .white
            countLabel.text         = "\(count)"
            countLabel.textColor    = .white
            tierLabel.text          = tier.label
            tierLabel.textColor     = UIColor.white.withAlphaComponent(0.85)
        }

        // Stars
        starViews.forEach { $0.removeFromSuperview() }
        starViews.removeAll()
        if !isLocked {
            for _ in 0..<tier.starCount {
                let iv = UIImageView(image: UIImage(systemName: "star.fill"))
                iv.tintColor = UIColor.white.withAlphaComponent(0.9)
                iv.contentMode = .scaleAspectFit
                addSubview(iv)
                starViews.append(iv)
            }
        }

        setNeedsLayout()
        if !isLocked { pulseGlow() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let size   = min(bounds.width, bounds.height)
        let radius = size / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path   = UIBezierPath(arcCenter: center, radius: radius - 4,
                                  startAngle: 0, endAngle: .pi * 2, clockwise: true)

        circleLayer.path   = path.cgPath
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = radius

        glowLayer.frame       = bounds
        glowLayer.cornerRadius = radius
        glowLayer.shadowPath  = UIBezierPath(ovalIn: bounds).cgPath

        let iconSize: CGFloat = size * 0.30
        iconImageView.frame = CGRect(x: center.x - iconSize / 2,
                                     y: center.y - iconSize / 2 - 14,
                                     width: iconSize, height: iconSize)

        countLabel.frame = CGRect(x: 0, y: iconImageView.frame.maxY + 4,
                                  width: bounds.width, height: 34)
        tierLabel.frame  = CGRect(x: 0, y: countLabel.frame.maxY + 2,
                                  width: bounds.width, height: 16)

        // Stars row
        let starSize: CGFloat = 12
        let starSpacing: CGFloat = 4
        let totalStarWidth = CGFloat(starViews.count) * starSize + CGFloat(max(0, starViews.count - 1)) * starSpacing
        var starX = center.x - totalStarWidth / 2
        let starY = tierLabel.frame.maxY + 6
        for sv in starViews {
            sv.frame = CGRect(x: starX, y: starY, width: starSize, height: starSize)
            starX += starSize + starSpacing
        }
    }

    private func pulseGlow() {
        let pulse = CABasicAnimation(keyPath: "shadowRadius")
        pulse.fromValue  = 14
        pulse.toValue    = 26
        pulse.duration   = 1.4
        pulse.autoreverses = true
        pulse.repeatCount  = .infinity
        glowLayer.add(pulse, forKey: "pulse")
    }
}

// MARK: - ButterflyHexagonBadgeView (small — used in collection cells)

class ButterflyHexagonBadgeView: UIView {

    private let shapeLayer    = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let glowLayer     = CALayer()
    private let iconImageView = UIImageView()
    private let lockImageView = UIImageView()

    private var tier: ButterflyDetailTier = .bronze
    private var isLocked: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        backgroundColor = .clear

        glowLayer.shadowRadius  = 10
        glowLayer.shadowOpacity = 0.5
        glowLayer.shadowOffset  = .zero
        layer.addSublayer(glowLayer)

        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradientLayer)

        shapeLayer.fillColor   = UIColor.clear.cgColor
        shapeLayer.lineWidth   = 2.5
        layer.addSublayer(shapeLayer)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor   = .white
        addSubview(iconImageView)

        lockImageView.image       = UIImage(systemName: "lock.fill")
        lockImageView.contentMode = .scaleAspectFit
        lockImageView.tintColor   = UIColor.white.withAlphaComponent(0.7)
        lockImageView.isHidden    = true
        addSubview(lockImageView)
    }

    func configure(tier: ButterflyDetailTier, count: Int, iconName: String, isLocked: Bool) {
        self.tier     = tier
        self.isLocked = isLocked

        if isLocked {
            gradientLayer.colors    = [UIColor.systemGray5.cgColor, UIColor.systemGray4.cgColor]
            shapeLayer.strokeColor  = UIColor.systemGray3.cgColor
            glowLayer.shadowColor   = UIColor.clear.cgColor
            iconImageView.isHidden  = true
            lockImageView.isHidden  = false
        } else {
            gradientLayer.colors    = tier.gradientColors
            shapeLayer.strokeColor  = tier.ringColor.cgColor
            glowLayer.shadowColor   = tier.glowColor.cgColor
            iconImageView.image     = UIImage(systemName: iconName)
            iconImageView.isHidden  = false
            lockImageView.isHidden  = true
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let w = bounds.width, h = bounds.height
        let hexPath = hexagonPath(in: bounds)

        shapeLayer.path   = hexPath.cgPath
        gradientLayer.frame = bounds
        gradientLayer.mask = {
            let m = CAShapeLayer()
            m.path = hexPath.cgPath
            return m
        }()

        glowLayer.frame      = bounds
        glowLayer.shadowPath = hexPath.cgPath

        let iconSize = min(w, h) * 0.42
        iconImageView.frame = CGRect(x: (w - iconSize) / 2, y: (h - iconSize) / 2,
                                     width: iconSize, height: iconSize)
        lockImageView.frame = iconImageView.frame
    }

    private func hexagonPath(in rect: CGRect) -> UIBezierPath {
        let cx = rect.midX, cy = rect.midY
        let r  = min(rect.width, rect.height) / 2 - 2
        let path = UIBezierPath()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
            i == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        path.close()
        return path
    }
}
