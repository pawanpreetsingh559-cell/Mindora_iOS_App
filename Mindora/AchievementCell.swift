import UIKit

// MARK: - Hexagon Badge View
@IBDesignable
class HexagonBadgeView: UIView {
    private let shapeLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let iconImageView = UIImageView()
    private let borderLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Gradient
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        layer.addSublayer(gradientLayer)
        
        // Mask
        layer.mask = shapeLayer
        
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 0
        borderLayer.strokeColor = UIColor.systemGray4.cgColor
        layer.addSublayer(borderLayer)
        
        // Icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        addSubview(iconImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5),
            iconImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        borderLayer.frame = bounds
        
        let path = createHexagonPath(in: bounds)
        shapeLayer.path = path.cgPath
        borderLayer.path = path.cgPath
    }
    
    
    // MARK: - Interface Builder Support
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        // Set default gradient colors for IB preview
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.8).cgColor,
            UIColor.systemBlue.cgColor
        ]
        
        // Set default icon for preview
        iconImageView.image = UIImage(systemName: "star.fill")
        iconImageView.tintColor = .white
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func createHexagonPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height
        
        // Pointy-topped hexagon
        let p1 = CGPoint(x: width / 2, y: 0)
        let p2 = CGPoint(x: width, y: height * 0.25)
        let p3 = CGPoint(x: width, y: height * 0.75)
        let p4 = CGPoint(x: width / 2, y: height)
        let p5 = CGPoint(x: 0, y: height * 0.75)
        let p6 = CGPoint(x: 0, y: height * 0.25)
        
        path.move(to: p1)
        path.addLine(to: p2)
        path.addLine(to: p3)
        path.addLine(to: p4)
        path.addLine(to: p5)
        path.addLine(to: p6)
        path.close()
        
        return path
    }
    
    func configure(color: UIColor, iconName: String, isLocked: Bool) {
        if isLocked {
            gradientLayer.colors = [
                UIColor.systemGray4.cgColor,
                UIColor.systemGray3.cgColor
            ]
            iconImageView.tintColor = .systemGray
            iconImageView.image = UIImage(systemName: "lock.fill")
            borderLayer.lineWidth = 1
        } else {
            // Create a gradient from the base color
            let lighter = color.lighter(by: 20) ?? color
            let darker = color.darker(by: 10) ?? color
            
            gradientLayer.colors = [
                lighter.cgColor,
                darker.cgColor
            ]
            iconImageView.tintColor = .white
            iconImageView.image = UIImage(systemName: iconName)
            borderLayer.lineWidth = 0
            
            layer.shadowColor = color.cgColor
            layer.shadowOpacity = 0.3
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.shadowRadius = 8
        }
    }
}

// MARK: - Achievement Cell
class AchievementCell: UICollectionViewCell {
    static let reuseIdentifier = "AchievementCell"
    
    // MARK: - IBOutlets
    @IBOutlet weak var cardContainer: UIView!
    @IBOutlet weak var badgeView: HexagonBadgeView!
    @IBOutlet weak var cardTitleLabel: UILabel!
    @IBOutlet weak var cardDescLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!

    // Streak-specific badge
    private var streakBadgeView: StreakHexagonBadgeView?
    // Garden-specific badge
    private var gardenBadgeView: GardenHexagonBadgeView?
    // Points-specific badge
    private var pointsBadgeView: PointsHexagonBadgeView?
    // Growth-specific badge
    private var growthBadgeView: GrowthStageHexagonBadgeView?
    // Mindfulness-specific badge
    private var mindfulnessBadgeView: MindfulnessHexagonBadgeView?
    // Sessions-specific badge
    private var sessionsBadgeView: SessionsHexagonBadgeView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellAppearance()
    }
    
    private func setupCellAppearance() {
        // Card container styling
        cardContainer.layer.cornerRadius = 20
        cardContainer.layer.cornerCurve = .continuous
        cardContainer.layer.shadowColor = UIColor.black.cgColor
        cardContainer.layer.shadowOpacity = 0.08
        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        cardContainer.layer.shadowRadius = 12
        cardContainer.layer.borderWidth = 1
        cardContainer.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        
        // Progress bar styling
        progressBar.layer.cornerRadius = 2
        progressBar.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        badgeView.layer.removeAllAnimations()
        streakBadgeView?.removeFromSuperview(); streakBadgeView = nil
        gardenBadgeView?.removeFromSuperview(); gardenBadgeView = nil
        pointsBadgeView?.removeFromSuperview(); pointsBadgeView = nil
        growthBadgeView?.removeFromSuperview(); growthBadgeView = nil
        mindfulnessBadgeView?.removeFromSuperview(); mindfulnessBadgeView = nil
        sessionsBadgeView?.removeFromSuperview(); sessionsBadgeView = nil
        badgeView.alpha = 1
    }
    
    func configure(with achievement: Achievement) {
        let color = colorForCategory(achievement.category)
        let isLocked = !achievement.isUnlocked && !achievement.isSecret

        // --- Streak: use special shield badge ---
        if achievement.category == .streak {
            badgeView.alpha = 0
            let sbv = StreakHexagonBadgeView()
            sbv.translatesAutoresizingMaskIntoConstraints = false
            badgeView.superview?.addSubview(sbv)
            NSLayoutConstraint.activate([
                sbv.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
                sbv.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
                sbv.widthAnchor.constraint(equalTo: badgeView.widthAnchor),
                sbv.heightAnchor.constraint(equalTo: badgeView.heightAnchor)
            ])
            streakBadgeView = sbv
            let tier = StreakTier.tier(for: achievement.requiredValue)
            sbv.configure(tier: tier, days: achievement.requiredValue,
                          iconName: achievement.iconName, isLocked: isLocked)

            if achievement.isSecret && !achievement.isUnlocked {
                cardTitleLabel.text = "???"
                cardDescLabel.text  = "Keep exploring..."
                progressBar.isHidden = true
            } else if achievement.isUnlocked {
                cardTitleLabel.text  = achievement.title
                cardDescLabel.text   = streakShortDesc(for: achievement.id)
                progressBar.isHidden = true
            } else {
                cardTitleLabel.text = achievement.title
                progressBar.isHidden = true
                progressBar.progress = achievement.progress
                progressBar.progressTintColor = StreakTier.tier(for: achievement.requiredValue).ringColor
                let perc = Int(achievement.progress * 100)
                cardDescLabel.text = "\(perc)%"
            }
            return
        }

        // --- Garden: use special hexagon badge ---
        if achievement.category == .garden {
            badgeView.alpha = 0
            let gbv = GardenHexagonBadgeView()
            gbv.translatesAutoresizingMaskIntoConstraints = false
            badgeView.superview?.addSubview(gbv)
            NSLayoutConstraint.activate([
                gbv.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
                gbv.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
                gbv.widthAnchor.constraint(equalTo: badgeView.widthAnchor),
                gbv.heightAnchor.constraint(equalTo: badgeView.heightAnchor)
            ])
            gardenBadgeView = gbv
            let tier = GardenTier.tier(for: achievement.requiredValue)
            gbv.configure(tier: tier, count: achievement.requiredValue,
                          iconName: achievement.iconName, isLocked: isLocked)

            if achievement.isSecret && !achievement.isUnlocked {
                cardTitleLabel.text  = "???"
                cardDescLabel.text   = "Keep exploring..."
                progressBar.isHidden = true
            } else if achievement.isUnlocked {
                cardTitleLabel.text  = achievement.title
                cardDescLabel.text   = gardenShortDesc(for: achievement.id)
                progressBar.isHidden = true
            } else {
                cardTitleLabel.text = achievement.title
                progressBar.isHidden = true
                progressBar.progress = achievement.progress
                progressBar.progressTintColor = GardenTier.tier(for: achievement.requiredValue).ringColor
                let perc = Int(achievement.progress * 100)
                cardDescLabel.text = "\(perc)%"
            }
            return
        }

        // --- Points: use gem-shaped badge ---
        if achievement.category == .points {
            badgeView.alpha = 0
            let pbv = PointsHexagonBadgeView()
            pbv.translatesAutoresizingMaskIntoConstraints = false
            badgeView.superview?.addSubview(pbv)
            NSLayoutConstraint.activate([
                pbv.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
                pbv.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
                pbv.widthAnchor.constraint(equalTo: badgeView.widthAnchor),
                pbv.heightAnchor.constraint(equalTo: badgeView.heightAnchor)
            ])
            pointsBadgeView = pbv
            let tier = PointsTier.tier(for: achievement.requiredValue)
            pbv.configure(tier: tier, points: achievement.requiredValue,
                          iconName: achievement.iconName, isLocked: isLocked)

            if achievement.isSecret && !achievement.isUnlocked {
                cardTitleLabel.text  = "???"
                cardDescLabel.text   = "Keep exploring..."
                progressBar.isHidden = true
            } else if achievement.isUnlocked {
                cardTitleLabel.text  = achievement.title
                cardDescLabel.text   = pointsShortDesc(for: achievement.id)
                progressBar.isHidden = true
            } else {
                cardTitleLabel.text = achievement.title
                progressBar.isHidden = true
                progressBar.progress = achievement.progress
                progressBar.progressTintColor = PointsTier.tier(for: achievement.requiredValue).ringColor
                let perc = Int(achievement.progress * 100)
                cardDescLabel.text = "\(perc)%"
            }
            return
        }

        // --- Growth: use egg-shaped badge ---
        if achievement.category == .growth {
            badgeView.alpha = 0
            let gbv = GrowthStageHexagonBadgeView()
            gbv.translatesAutoresizingMaskIntoConstraints = false
            badgeView.superview?.addSubview(gbv)
            NSLayoutConstraint.activate([
                gbv.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
                gbv.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
                gbv.widthAnchor.constraint(equalTo: badgeView.widthAnchor),
                gbv.heightAnchor.constraint(equalTo: badgeView.heightAnchor)
            ])
            growthBadgeView = gbv
            let tier = GrowthStageTier.tier(for: achievement.id)
            gbv.configure(tier: tier, isLocked: isLocked)

            if achievement.isSecret && !achievement.isUnlocked {
                cardTitleLabel.text  = "???"
                cardDescLabel.text   = "Keep exploring..."
                progressBar.isHidden = true
            } else if achievement.isUnlocked {
                cardTitleLabel.text  = achievement.title
                cardDescLabel.text   = growthShortDesc(for: achievement.id)
                progressBar.isHidden = true
            } else {
                cardTitleLabel.text = achievement.title
                progressBar.isHidden = true
                progressBar.progress = achievement.progress
                progressBar.progressTintColor = GrowthStageTier.tier(for: achievement.id).ringColor
                let perc = Int(achievement.progress * 100)
                cardDescLabel.text = "\(perc)%"
            }
            return
        }

        // --- Mindfulness: use lotus-shaped badge ---
        if achievement.category == .mindfulness {
            badgeView.alpha = 0
            let mbv = MindfulnessHexagonBadgeView()
            mbv.translatesAutoresizingMaskIntoConstraints = false
            badgeView.superview?.addSubview(mbv)
            NSLayoutConstraint.activate([
                mbv.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
                mbv.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
                mbv.widthAnchor.constraint(equalTo: badgeView.widthAnchor),
                mbv.heightAnchor.constraint(equalTo: badgeView.heightAnchor)
            ])
            mindfulnessBadgeView = mbv
            let tier = MindfulnessTier.tier(for: achievement.id)
            mbv.configure(tier: tier, isLocked: isLocked)

            if achievement.isSecret && !achievement.isUnlocked {
                cardTitleLabel.text  = "???"
                cardDescLabel.text   = "Keep exploring..."
                progressBar.isHidden = true
            } else if achievement.isUnlocked {
                cardTitleLabel.text  = achievement.title
                cardDescLabel.text   = mindfulnessShortDesc(for: achievement.id)
                progressBar.isHidden = true
            } else {
                cardTitleLabel.text = achievement.title
                progressBar.isHidden = true
                progressBar.progress = achievement.progress
                progressBar.progressTintColor = MindfulnessTier.tier(for: achievement.id).ringColor
                let perc = Int(achievement.progress * 100)
                cardDescLabel.text = "\(perc)%"
            }
            return
        }

        // --- Sessions: use sessions badge ---
        if achievement.category == .sessions {
            badgeView.alpha = 0
            let sbv = SessionsHexagonBadgeView()
            sbv.translatesAutoresizingMaskIntoConstraints = false
            badgeView.superview?.addSubview(sbv)
            NSLayoutConstraint.activate([
                sbv.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
                sbv.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
                sbv.widthAnchor.constraint(equalTo: badgeView.widthAnchor),
                sbv.heightAnchor.constraint(equalTo: badgeView.heightAnchor)
            ])
            sessionsBadgeView = sbv
            let tier = SessionsTier.tier(for: achievement.requiredValue)
            sbv.configure(tier: tier, sessions: achievement.requiredValue,
                          iconName: achievement.iconName, isLocked: isLocked)

            if achievement.isSecret && !achievement.isUnlocked {
                cardTitleLabel.text  = "???"
                cardDescLabel.text   = "Keep exploring..."
                progressBar.isHidden = true
            } else if achievement.isUnlocked {
                cardTitleLabel.text  = achievement.title
                cardDescLabel.text   = sessionsShortDesc(for: achievement.id)
                progressBar.isHidden = true
            } else {
                cardTitleLabel.text = achievement.title
                progressBar.isHidden = true
                progressBar.progress = achievement.progress
                progressBar.progressTintColor = SessionsTier.tier(for: achievement.requiredValue).ringColor
                let perc = Int(achievement.progress * 100)
                cardDescLabel.text = "\(perc)%"
            }
            return
        }

        // --- Default badge ---
        badgeView.alpha = 1
        if achievement.isSecret && !achievement.isUnlocked {
            cardTitleLabel.text = "???"
            cardDescLabel.text  = "Keep exploring..."
            progressBar.isHidden = true
            badgeView.configure(color: .systemGray5, iconName: "questionmark", isLocked: true)
        } else if achievement.isUnlocked {
            cardTitleLabel.text  = achievement.title
            cardDescLabel.text   = achievement.description
            progressBar.isHidden = true
            badgeView.configure(color: color, iconName: achievement.iconName, isLocked: false)
        } else {
            cardTitleLabel.text = achievement.title
            if achievement.requiredValue > 1 {
                progressBar.isHidden = true
                progressBar.progress = achievement.progress
                let perc = Int(achievement.progress * 100)
                cardDescLabel.text = "\(perc)%"
            } else {
                progressBar.isHidden = true
                cardDescLabel.text = achievement.description
            }
            if achievement.category == .points {
                progressBar.progressTintColor = color
            } else {
                progressBar.progressTintColor = .systemBlue
            }
            badgeView.configure(color: color, iconName: achievement.iconName, isLocked: true)
        }
    }

    private func streakShortDesc(for id: String) -> String {
        switch id {
        case "streak_3":  return "3 days strong 🔥"
        case "streak_7":  return "7 days of flow ⚡️"
        case "streak_30": return "30 days mastered 🛡"
        case "streak_60": return "60 days unbreakable 👑"
        default:          return "Streak achieved!"
        }
    }

    private func gardenShortDesc(for id: String) -> String {
        switch id {
        case "garden_1":   return "First seed planted 🌱"
        case "garden_10":  return "10 gardens blooming 🌿"
        case "garden_25":  return "25 gardens flourishing 🌸"
        case "garden_50":  return "50 gardens — ancient grove 🌳"
        case "garden_75":  return "75 gardens — forest keeper 🌲"
        case "garden_100": return "100 gardens — Eden achieved ✨"
        default:           return "Garden milestone reached!"
        }
    }

    private func pointsShortDesc(for id: String) -> String {
        switch id {
        case "points_200":  return "200 pts — Calm Builder 🥉"
        case "points_350":  return "350 pts — Mind Strengthening 🥈"
        case "points_600":  return "600 pts — Growth Accelerator 🥇"
        case "points_800":  return "800 pts — Inner Stability 💎"
        case "points_1200": return "1200 pts — Serenity Architect 💜"
        case "points_2000": return "2000 pts — Mindora Champion 💠"
        default:            return "Points milestone reached!"
        }
    }

    private func growthShortDesc(for id: String) -> String {
        switch id {
        case "growth_egg":         return "Stage 1 — First Egg 🥚"
        case "growth_caterpillar": return "Stage 2 — Caterpillar Born 🐛"
        case "growth_cocoon":      return "Stage 3 — Into the Cocoon 🫘"
        case "growth_butterfly":   return "Stage 4 — Butterfly Emerges 🦋"
        default:                   return "Growth milestone!"
        }
    }

    private func mindfulnessShortDesc(for id: String) -> String {
        switch id {
        case "mind_double": return "2 sessions today 🧘"
        case "mind_triple": return "3 sessions today 🌊"
        case "mind_4":      return "4 sessions today 💜"
        case "mind_deep":   return "5 sessions today 🌌"
        default:            return "Mindfulness milestone!"
        }
    }

    private func sessionsShortDesc(for id: String) -> String {
        switch id {
        case "session_10": return "10 sessions — First Steps 🌱"
        case "session_20": return "20 sessions — Steady Rhythm 🌊"
        case "session_40": return "40 sessions — Deep Commitment 💜"
        case "session_80": return "80 sessions — Mindful Master ✨"
        default:           return "Sessions milestone!"
        }
    }
    
    private func colorForCategory(_ category: AchievementCategory) -> UIColor {
        switch category {
        case .growth:      return UIColor.systemGreen
        case .streak:      return UIColor.systemOrange
        case .butterfly:   return UIColor.systemPink
        case .sessions:    return UIColor(red: 0.50, green: 0.30, blue: 0.85, alpha: 1)
        case .mindfulness: return UIColor.systemTeal
        case .garden:      return UIColor(red: 0.20, green: 0.65, blue: 0.35, alpha: 1)
        case .points:      return UIColor.systemYellow
        case .user:        return UIColor(red: 0.30, green: 0.55, blue: 1.00, alpha: 1)
        }
    }
}

// MARK: - Color Helpers
extension UIColor {
    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }
}
