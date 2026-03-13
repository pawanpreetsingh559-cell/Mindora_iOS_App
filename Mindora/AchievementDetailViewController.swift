import UIKit

class AchievementDetailViewController: UIViewController {

    // MARK: - Properties
    var achievement: Achievement?

    // MARK: - IBOutlets (generic views — used for non-streak achievements)
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var statusContainer: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var unlockDateLabel: UILabel!

    // MARK: - Streak Detail Views (programmatic — rich custom layout)
    private var streakDetailView: UIView?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if achievement?.category == .streak {
            setupStreakDetailUI()
        } else if achievement?.category == .garden {
            setupGardenDetailUI()
        } else if achievement?.category == .points {
            setupPointsDetailUI()
        } else if achievement?.category == .growth {
            setupGrowthDetailUI()
        } else if achievement?.category == .mindfulness {
            setupMindfulnessDetailUI()
        } else if achievement?.category == .butterfly {
            setupButterflyDetailUI()
        } else if achievement?.category == .sessions {
            setupSessionsDetailUI()
        } else if achievement?.category == .user {
            setupUserDetailUI()
        } else {
            configure()
        }
    }

    // MARK: - Generic Configure (non-streak)
    func configure() {
        guard let achievement = achievement else { return }

        let isSecret = achievement.isSecret && !achievement.isUnlocked

        if isSecret {
            titleLabel.text = "???"
            categoryLabel.text = "Secret Achievement"
            descriptionLabel.text = "Keep exploring to reveal this path."
            iconImageView.image = UIImage(systemName: "questionmark.circle.fill")
            iconImageView.tintColor = .systemGray
        } else {
            titleLabel.text = achievement.title
            categoryLabel.text = achievement.category.rawValue.uppercased()
            descriptionLabel.text = achievement.description
            iconImageView.image = UIImage(systemName: achievement.iconName)
            iconImageView.tintColor = achievement.isUnlocked ? .systemYellow : .systemGray
        }

        if achievement.isUnlocked {
            progressView.isHidden = true
            progressLabel.text = "Unlocked"
            progressLabel.textColor = .systemGreen
            progressLabel.font = .boldSystemFont(ofSize: 18)

            if let date = achievement.dateUnlocked {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                unlockDateLabel.text = "Unlocked on \(formatter.string(from: date))"
            } else {
                unlockDateLabel.text = "Unlocked"
            }
            unlockDateLabel.isHidden = false

        } else if isSecret {
            progressView.isHidden = true
            progressLabel.isHidden = true
            unlockDateLabel.text = "???"
            unlockDateLabel.isHidden = false

        } else {
            progressView.isHidden = false
            progressView.progress = achievement.progress

            let perc = Int(achievement.progress * 100)
            progressLabel.text = "\(perc)% Completed"
            progressLabel.isHidden = false

            unlockDateLabel.text = "Reach \(achievement.requiredValue) to unlock."
            unlockDateLabel.isHidden = false
        }
    }

    // MARK: - Streak Detail UI (fully programmatic, beautiful)
    private func setupStreakDetailUI() {
        guard let achievement = achievement else { return }

        // Hide the storyboard generic layout
        scrollView.isHidden = true

        let tier = StreakTier.tier(for: achievement.requiredValue)
        let isLocked = !achievement.isUnlocked

        // Root scroll
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(container)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            container.topAnchor.constraint(equalTo: scroll.topAnchor),
            container.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        streakDetailView = container

        // Background gradient header
        let headerView = makeHeaderGradient(tier: tier, isLocked: isLocked)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerView)

        // Badge
        let badge = StreakBadgeView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.configure(tier: tier,
                        days: achievement.requiredValue,
                        iconName: achievement.iconName,
                        isLocked: isLocked)
        container.addSubview(badge)

        // Title
        let titleLbl = UILabel()
        titleLbl.text = achievement.title
        titleLbl.font = .systemFont(ofSize: 26, weight: .bold)
        titleLbl.textAlignment = .center
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLbl)

        // Tier pill
        let tierPill = makeTierPill(tier: tier, isLocked: isLocked)
        tierPill.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tierPill)

        // Description card
        let descCard = makeDescriptionCard(achievement: achievement, tier: tier, isLocked: isLocked)
        descCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descCard)

        // Milestone row
        let milestoneRow = makeMilestoneRow(achievement: achievement, tier: tier)
        milestoneRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(milestoneRow)

        // Progress / Unlock status
        let statusCard = makeStatusCard(achievement: achievement, tier: tier)
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusCard)

        // All 4 streak milestones
        let roadmapCard = makeRoadmapCard(currentAchievement: achievement)
        roadmapCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(roadmapCard)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),

            badge.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: headerView.bottomAnchor),
            badge.widthAnchor.constraint(equalToConstant: 160),
            badge.heightAnchor.constraint(equalToConstant: 180),

            titleLbl.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            tierPill.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 8),
            tierPill.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descCard.topAnchor.constraint(equalTo: tierPill.bottomAnchor, constant: 20),
            descCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            descCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            milestoneRow.topAnchor.constraint(equalTo: descCard.bottomAnchor, constant: 16),
            milestoneRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            milestoneRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statusCard.topAnchor.constraint(equalTo: milestoneRow.bottomAnchor, constant: 16),
            statusCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statusCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            roadmapCard.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 16),
            roadmapCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            roadmapCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            roadmapCard.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -32)
        ])

        // Animate badge entrance
        badge.alpha = 0
        badge.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.55, delay: 0.1, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5) {
            badge.alpha = 1
            badge.transform = .identity
        }
    }

    // MARK: - Header Gradient
    private func makeHeaderGradient(tier: StreakTier, isLocked: Bool) -> UIView {
        let v = UIView()
        v.clipsToBounds = true

        let grad = CAGradientLayer()
        if isLocked {
            grad.colors = [UIColor.systemGray5.cgColor, UIColor.systemGray4.cgColor]
        } else {
            grad.colors = tier.gradientColors
        }
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 1)

        v.layer.insertSublayer(grad, at: 0)

        // Decorative circles
        for (size, alpha, offset) in [(CGFloat(220), 0.12, CGPoint(x: -40, y: -60)),
                                       (CGFloat(140), 0.10, CGPoint(x: 280, y: 20))] {
            let circle = UIView()
            circle.backgroundColor = UIColor.white.withAlphaComponent(alpha)
            circle.layer.cornerRadius = size / 2
            circle.frame = CGRect(x: offset.x, y: offset.y, width: size, height: size)
            v.addSubview(circle)
        }

        v.layoutIfNeeded()
        grad.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        return v
    }

    // MARK: - Tier Pill
    private func makeTierPill(tier: StreakTier, isLocked: Bool) -> UIView {
        let pill = UIView()
        pill.layer.cornerRadius = 12
        pill.clipsToBounds = true

        let grad = CAGradientLayer()
        if isLocked {
            grad.colors = [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
        } else {
            grad.colors = tier.gradientColors
        }
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 0)
        grad.cornerRadius = 12
        pill.layer.insertSublayer(grad, at: 0)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(stack)

        // Stars
        for _ in 0..<tier.starCount {
            let iv = UIImageView(image: UIImage(systemName: "star.fill"))
            iv.tintColor = .white
            iv.widthAnchor.constraint(equalToConstant: 12).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 12).isActive = true
            stack.addArrangedSubview(iv)
        }

        let lbl = UILabel()
        lbl.text = tier.label
        lbl.font = .systemFont(ofSize: 12, weight: .heavy)
        lbl.textColor = .white
        stack.addArrangedSubview(lbl)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -7),
            stack.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -14)
        ])

        pill.layoutIfNeeded()
        grad.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        return pill
    }

    // MARK: - Description Card
    private func makeDescriptionCard(achievement: Achievement, tier: StreakTier, isLocked: Bool) -> UIView {
        let card = makeCard()

        let quoteIcon = UIImageView(image: UIImage(systemName: "quote.opening"))
        quoteIcon.tintColor = isLocked ? .systemGray3 : tier.ringColor
        quoteIcon.contentMode = .scaleAspectFit
        quoteIcon.translatesAutoresizingMaskIntoConstraints = false
        quoteIcon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        quoteIcon.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let desc = UILabel()
        desc.text = achievement.description
        desc.font = .systemFont(ofSize: 16, weight: .regular)
        desc.textColor = .label
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.translatesAutoresizingMaskIntoConstraints = false

        let motiveLine = UILabel()
        motiveLine.text = streakMotivation(for: achievement.id, isLocked: isLocked)
        motiveLine.font = .systemFont(ofSize: 13, weight: .medium)
        motiveLine.textColor = isLocked ? .systemGray3 : tier.ringColor
        motiveLine.numberOfLines = 0
        motiveLine.textAlignment = .center
        motiveLine.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(quoteIcon)
        card.addSubview(desc)
        card.addSubview(motiveLine)

        NSLayoutConstraint.activate([
            quoteIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            quoteIcon.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            desc.topAnchor.constraint(equalTo: quoteIcon.bottomAnchor, constant: 10),
            desc.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            desc.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            motiveLine.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 12),
            motiveLine.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            motiveLine.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            motiveLine.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    // MARK: - Milestone Row (3 stats)
    private func makeMilestoneRow(achievement: Achievement, tier: StreakTier) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12

        let items: [(String, String, String)] = [
            ("flame.fill",    "\(achievement.requiredValue)", "Days"),
            ("star.fill",     "\(tier.starCount)",            "Stars"),
            ("shield.fill",   tier.label,                     "Tier")
        ]

        for (icon, value, subtitle) in items {
            let card = makeCard()
            card.layer.cornerRadius = 14

            let iv = UIImageView(image: UIImage(systemName: icon))
            iv.tintColor = achievement.isUnlocked ? tier.ringColor : .systemGray3
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 22).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 22).isActive = true

            let valLbl = UILabel()
            valLbl.text = value
            valLbl.font = .systemFont(ofSize: 18, weight: .bold)
            valLbl.textColor = .label
            valLbl.textAlignment = .center
            valLbl.translatesAutoresizingMaskIntoConstraints = false

            let subLbl = UILabel()
            subLbl.text = subtitle
            subLbl.font = .systemFont(ofSize: 11, weight: .medium)
            subLbl.textColor = .secondaryLabel
            subLbl.textAlignment = .center
            subLbl.translatesAutoresizingMaskIntoConstraints = false

            let vStack = UIStackView(arrangedSubviews: [iv, valLbl, subLbl])
            vStack.axis = .vertical
            vStack.alignment = .center
            vStack.spacing = 4
            vStack.translatesAutoresizingMaskIntoConstraints = false

            card.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8)
            ])

            stack.addArrangedSubview(card)
        }

        return stack
    }

    // MARK: - Status Card
    private func makeStatusCard(achievement: Achievement, tier: StreakTier) -> UIView {
        let card = makeCard()

        if achievement.isUnlocked {
            // Unlocked state
            let checkIV = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
            checkIV.tintColor = tier.ringColor
            checkIV.contentMode = .scaleAspectFit
            checkIV.translatesAutoresizingMaskIntoConstraints = false
            checkIV.widthAnchor.constraint(equalToConstant: 36).isActive = true
            checkIV.heightAnchor.constraint(equalToConstant: 36).isActive = true

            let unlockedLbl = UILabel()
            unlockedLbl.text = "Achievement Unlocked!"
            unlockedLbl.font = .systemFont(ofSize: 17, weight: .bold)
            unlockedLbl.textColor = tier.ringColor
            unlockedLbl.textAlignment = .center
            unlockedLbl.translatesAutoresizingMaskIntoConstraints = false

            var dateText = ""
            if let date = achievement.dateUnlocked {
                let fmt = DateFormatter()
                fmt.dateStyle = .long
                dateText = "Earned on \(fmt.string(from: date))"
            }
            let dateLbl = UILabel()
            dateLbl.text = dateText
            dateLbl.font = .systemFont(ofSize: 13)
            dateLbl.textColor = .secondaryLabel
            dateLbl.textAlignment = .center
            dateLbl.translatesAutoresizingMaskIntoConstraints = false

            let vStack = UIStackView(arrangedSubviews: [checkIV, unlockedLbl, dateLbl])
            vStack.axis = .vertical
            vStack.alignment = .center
            vStack.spacing = 6
            vStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(vStack)

            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])

        } else {
            // In-progress state
            let headerLbl = UILabel()
            headerLbl.text = "Your Progress"
            headerLbl.font = .systemFont(ofSize: 14, weight: .semibold)
            headerLbl.textColor = .secondaryLabel
            headerLbl.translatesAutoresizingMaskIntoConstraints = false

            let progressBar = UIProgressView(progressViewStyle: .default)
            progressBar.progress = achievement.progress
            progressBar.progressTintColor = tier.ringColor
            progressBar.trackTintColor = .systemGray5
            progressBar.layer.cornerRadius = 4
            progressBar.clipsToBounds = true
            progressBar.translatesAutoresizingMaskIntoConstraints = false

            let percLbl = UILabel()
            let perc = Int(achievement.progress * 100)
            percLbl.text = "\(achievement.currentValue) / \(achievement.requiredValue) days  (\(perc)%)"
            percLbl.font = .systemFont(ofSize: 13, weight: .medium)
            percLbl.textColor = tier.ringColor
            percLbl.textAlignment = .center
            percLbl.translatesAutoresizingMaskIntoConstraints = false

            let goalLbl = UILabel()
            goalLbl.text = "Keep going — \(achievement.requiredValue - achievement.currentValue) more days to unlock!"
            goalLbl.font = .systemFont(ofSize: 12)
            goalLbl.textColor = .secondaryLabel
            goalLbl.textAlignment = .center
            goalLbl.numberOfLines = 0
            goalLbl.translatesAutoresizingMaskIntoConstraints = false

            card.addSubview(headerLbl)
            card.addSubview(progressBar)
            card.addSubview(percLbl)
            card.addSubview(goalLbl)

            NSLayoutConstraint.activate([
                headerLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                headerLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),

                progressBar.topAnchor.constraint(equalTo: headerLbl.bottomAnchor, constant: 12),
                progressBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
                progressBar.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
                progressBar.heightAnchor.constraint(equalToConstant: 8),

                percLbl.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 10),
                percLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),

                goalLbl.topAnchor.constraint(equalTo: percLbl.bottomAnchor, constant: 6),
                goalLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                goalLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                goalLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
            ])
        }

        return card
    }

    // MARK: - Roadmap Card (all 4 streak milestones)
    private func makeRoadmapCard(currentAchievement: Achievement) -> UIView {
        let card = makeCard()

        let titleLbl = UILabel()
        titleLbl.text = "Streak Roadmap"
        titleLbl.font = .systemFont(ofSize: 15, weight: .bold)
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLbl)

        let milestones: [(String, Int, StreakTier, String)] = [
            ("Spark of Habit",  3,  .bronze,   "flame"),
            ("Weekly Warrior",  7,  .silver,   "flame.fill"),
            ("Monthly Master",  30, .gold,     "shield.fill"),
            ("Unbreakable",     60, .platinum, "crown.fill")
        ]

        var lastView: UIView = titleLbl

        for (i, (name, days, tier, icon)) in milestones.enumerated() {
            let isCurrentOrPast = days <= currentAchievement.requiredValue
            let isCurrent = days == currentAchievement.requiredValue

            // Connector line (skip first)
            if i > 0 {
                let line = UIView()
                line.backgroundColor = isCurrentOrPast ? tier.ringColor.withAlphaComponent(0.4) : .systemGray5
                line.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(line)
                NSLayoutConstraint.activate([
                    line.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 35),
                    line.widthAnchor.constraint(equalToConstant: 2),
                    line.topAnchor.constraint(equalTo: lastView.bottomAnchor),
                    line.heightAnchor.constraint(equalToConstant: 12)
                ])
                lastView = line
            }

            let row = makeMilestoneRowItem(name: name, days: days, tier: tier, icon: icon,
                                           isCurrentOrPast: isCurrentOrPast, isCurrent: isCurrent)
            row.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(row)

            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: i == 0 ? 12 : 0),
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
            lastView = row
        }

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            lastView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        return card
    }

    private func makeMilestoneRowItem(name: String, days: Int, tier: StreakTier, icon: String,
                                      isCurrentOrPast: Bool, isCurrent: Bool) -> UIView {
        let row = UIView()

        // Circle indicator
        let circle = UIView()
        circle.layer.cornerRadius = 18
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.widthAnchor.constraint(equalToConstant: 36).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 36).isActive = true

        if isCurrentOrPast {
            let grad = CAGradientLayer()
            grad.colors = tier.gradientColors
            grad.startPoint = CGPoint(x: 0, y: 0)
            grad.endPoint   = CGPoint(x: 1, y: 1)
            grad.cornerRadius = 18
            grad.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
            circle.layer.insertSublayer(grad, at: 0)
        } else {
            circle.backgroundColor = .systemGray5
        }

        if isCurrent {
            circle.layer.borderWidth = 2.5
            circle.layer.borderColor = tier.ringColor.cgColor
        }

        let iconIV = UIImageView(image: UIImage(systemName: isCurrentOrPast ? icon : "lock.fill"))
        iconIV.tintColor = isCurrentOrPast ? .white : .systemGray3
        iconIV.contentMode = .scaleAspectFit
        iconIV.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(iconIV)
        NSLayoutConstraint.activate([
            iconIV.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            iconIV.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            iconIV.widthAnchor.constraint(equalToConstant: 16),
            iconIV.heightAnchor.constraint(equalToConstant: 16)
        ])

        // Name label
        let nameLbl = UILabel()
        nameLbl.text = name
        nameLbl.font = isCurrent ? .systemFont(ofSize: 14, weight: .bold) : .systemFont(ofSize: 14, weight: .medium)
        nameLbl.textColor = isCurrentOrPast ? .label : .secondaryLabel
        nameLbl.translatesAutoresizingMaskIntoConstraints = false

        // Days label
        let daysLbl = UILabel()
        daysLbl.text = "\(days) days"
        daysLbl.font = .systemFont(ofSize: 12)
        daysLbl.textColor = isCurrentOrPast ? tier.ringColor : .tertiaryLabel
        daysLbl.translatesAutoresizingMaskIntoConstraints = false

        // Tier badge
        let tierLbl = UILabel()
        tierLbl.text = tier.label
        tierLbl.font = .systemFont(ofSize: 10, weight: .heavy)
        tierLbl.textColor = isCurrentOrPast ? tier.ringColor : .systemGray3
        tierLbl.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [nameLbl, daysLbl])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(circle)
        row.addSubview(textStack)
        row.addSubview(tierLbl)

        NSLayoutConstraint.activate([
            circle.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            circle.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            tierLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            tierLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            row.heightAnchor.constraint(equalToConstant: 52)
        ])

        return row
    }

    // MARK: - Garden Detail UI
    private func setupGardenDetailUI() {
        guard let achievement = achievement else { return }

        scrollView.isHidden = true

        let tier = GardenTier.tier(for: achievement.requiredValue)
        let isLocked = !achievement.isUnlocked

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(container)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.topAnchor.constraint(equalTo: scroll.topAnchor),
            container.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        // Header
        let headerView = makeGardenHeaderGradient(tier: tier, isLocked: isLocked)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerView)

        // Badge
        let badge = GardenBadgeView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.configure(tier: tier, count: achievement.requiredValue,
                        iconName: achievement.iconName, isLocked: isLocked)
        container.addSubview(badge)

        // Title
        let titleLbl = UILabel()
        titleLbl.text = achievement.title
        titleLbl.font = .systemFont(ofSize: 26, weight: .bold)
        titleLbl.textAlignment = .center
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLbl)

        // Tier pill
        let tierPill = makeGardenTierPill(tier: tier, isLocked: isLocked)
        tierPill.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tierPill)

        // Description card
        let descCard = makeGardenDescCard(achievement: achievement, tier: tier, isLocked: isLocked)
        descCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descCard)

        // Stats row
        let statsRow = makeGardenStatsRow(achievement: achievement, tier: tier)
        statsRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statsRow)

        // Status card
        let statusCard = makeGardenStatusCard(achievement: achievement, tier: tier)
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusCard)

        // Roadmap
        let roadmapCard = makeGardenRoadmapCard(currentAchievement: achievement)
        roadmapCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(roadmapCard)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),

            badge.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: headerView.bottomAnchor),
            badge.widthAnchor.constraint(equalToConstant: 160),
            badge.heightAnchor.constraint(equalToConstant: 180),

            titleLbl.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            tierPill.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 8),
            tierPill.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descCard.topAnchor.constraint(equalTo: tierPill.bottomAnchor, constant: 20),
            descCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            descCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statsRow.topAnchor.constraint(equalTo: descCard.bottomAnchor, constant: 16),
            statsRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statsRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statusCard.topAnchor.constraint(equalTo: statsRow.bottomAnchor, constant: 16),
            statusCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statusCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            roadmapCard.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 16),
            roadmapCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            roadmapCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            roadmapCard.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -32)
        ])

        badge.alpha = 0
        badge.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.55, delay: 0.1, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5) {
            badge.alpha = 1
            badge.transform = .identity
        }
    }

    private func makeGardenHeaderGradient(tier: GardenTier, isLocked: Bool) -> UIView {
        let v = UIView()
        v.clipsToBounds = true
        let grad = CAGradientLayer()
        grad.colors = isLocked
            ? [UIColor.systemGray5.cgColor, UIColor.systemGray4.cgColor]
            : tier.gradientColors
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 1)
        v.layer.insertSublayer(grad, at: 0)
        for (size, alpha, offset) in [(CGFloat(200), 0.10, CGPoint(x: -30, y: -50)),
                                       (CGFloat(130), 0.08, CGPoint(x: 270, y: 30))] {
            let circle = UIView()
            circle.backgroundColor = UIColor.white.withAlphaComponent(alpha)
            circle.layer.cornerRadius = size / 2
            circle.frame = CGRect(x: offset.x, y: offset.y, width: size, height: size)
            v.addSubview(circle)
        }
        grad.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        return v
    }

    private func makeGardenTierPill(tier: GardenTier, isLocked: Bool) -> UIView {
        let pill = UIView()
        pill.layer.cornerRadius = 12
        pill.clipsToBounds = true
        let grad = CAGradientLayer()
        grad.colors = isLocked
            ? [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            : tier.gradientColors
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 0)
        grad.cornerRadius = 12
        pill.layer.insertSublayer(grad, at: 0)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 5
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(stack)

        for _ in 0..<tier.leafCount {
            let iv = UIImageView(image: UIImage(systemName: "leaf.fill"))
            iv.tintColor = .white
            iv.widthAnchor.constraint(equalToConstant: 11).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 11).isActive = true
            stack.addArrangedSubview(iv)
        }

        let lbl = UILabel()
        lbl.text = tier.label
        lbl.font = .systemFont(ofSize: 12, weight: .heavy)
        lbl.textColor = .white
        stack.addArrangedSubview(lbl)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -7),
            stack.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -14)
        ])
        grad.frame = CGRect(x: 0, y: 0, width: 220, height: 40)
        return pill
    }

    private func makeGardenDescCard(achievement: Achievement, tier: GardenTier, isLocked: Bool) -> UIView {
        let card = makeCard()
        let quoteIcon = UIImageView(image: UIImage(systemName: "leaf.circle.fill"))
        quoteIcon.tintColor = isLocked ? .systemGray3 : tier.ringColor
        quoteIcon.contentMode = .scaleAspectFit
        quoteIcon.translatesAutoresizingMaskIntoConstraints = false
        quoteIcon.widthAnchor.constraint(equalToConstant: 26).isActive = true
        quoteIcon.heightAnchor.constraint(equalToConstant: 26).isActive = true

        let desc = UILabel()
        desc.text = achievement.description
        desc.font = .systemFont(ofSize: 16, weight: .regular)
        desc.textColor = .label
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.translatesAutoresizingMaskIntoConstraints = false

        let motiveLine = UILabel()
        motiveLine.text = gardenMotivation(for: achievement.id, isLocked: isLocked)
        motiveLine.font = .systemFont(ofSize: 13, weight: .medium)
        motiveLine.textColor = isLocked ? .systemGray3 : tier.ringColor
        motiveLine.numberOfLines = 0
        motiveLine.textAlignment = .center
        motiveLine.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(quoteIcon)
        card.addSubview(desc)
        card.addSubview(motiveLine)

        NSLayoutConstraint.activate([
            quoteIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            quoteIcon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            desc.topAnchor.constraint(equalTo: quoteIcon.bottomAnchor, constant: 10),
            desc.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            desc.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            motiveLine.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 12),
            motiveLine.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            motiveLine.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            motiveLine.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeGardenStatsRow(achievement: Achievement, tier: GardenTier) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12

        let items: [(String, String, String)] = [
            ("leaf.fill",   "\(achievement.requiredValue)", "Gardens"),
            ("leaf.fill",   "\(tier.leafCount)",            "Leaves"),
            ("tree.fill",   tier.label,                     "Tier")
        ]

        for (icon, value, subtitle) in items {
            let card = makeCard()
            card.layer.cornerRadius = 14
            let iv = UIImageView(image: UIImage(systemName: icon))
            iv.tintColor = achievement.isUnlocked ? tier.ringColor : .systemGray3
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 22).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 22).isActive = true
            let valLbl = UILabel()
            valLbl.text = value
            valLbl.font = .systemFont(ofSize: 18, weight: .bold)
            valLbl.textColor = .label
            valLbl.textAlignment = .center
            valLbl.translatesAutoresizingMaskIntoConstraints = false
            let subLbl = UILabel()
            subLbl.text = subtitle
            subLbl.font = .systemFont(ofSize: 11, weight: .medium)
            subLbl.textColor = .secondaryLabel
            subLbl.textAlignment = .center
            subLbl.translatesAutoresizingMaskIntoConstraints = false
            let vStack = UIStackView(arrangedSubviews: [iv, valLbl, subLbl])
            vStack.axis = .vertical
            vStack.alignment = .center
            vStack.spacing = 4
            vStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8)
            ])
            stack.addArrangedSubview(card)
        }
        return stack
    }

    private func makeGardenStatusCard(achievement: Achievement, tier: GardenTier) -> UIView {
        let card = makeCard()
        if achievement.isUnlocked {
            let checkIV = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
            checkIV.tintColor = tier.ringColor
            checkIV.contentMode = .scaleAspectFit
            checkIV.translatesAutoresizingMaskIntoConstraints = false
            checkIV.widthAnchor.constraint(equalToConstant: 36).isActive = true
            checkIV.heightAnchor.constraint(equalToConstant: 36).isActive = true
            let unlockedLbl = UILabel()
            unlockedLbl.text = "Garden Milestone Unlocked!"
            unlockedLbl.font = .systemFont(ofSize: 17, weight: .bold)
            unlockedLbl.textColor = tier.ringColor
            unlockedLbl.textAlignment = .center
            unlockedLbl.translatesAutoresizingMaskIntoConstraints = false
            var dateText = ""
            if let date = achievement.dateUnlocked {
                let fmt = DateFormatter(); fmt.dateStyle = .long
                dateText = "Earned on \(fmt.string(from: date))"
            }
            let dateLbl = UILabel()
            dateLbl.text = dateText
            dateLbl.font = .systemFont(ofSize: 13)
            dateLbl.textColor = .secondaryLabel
            dateLbl.textAlignment = .center
            dateLbl.translatesAutoresizingMaskIntoConstraints = false
            let vStack = UIStackView(arrangedSubviews: [checkIV, unlockedLbl, dateLbl])
            vStack.axis = .vertical; vStack.alignment = .center; vStack.spacing = 6
            vStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
        } else {
            let headerLbl = UILabel()
            headerLbl.text = "Your Progress"
            headerLbl.font = .systemFont(ofSize: 14, weight: .semibold)
            headerLbl.textColor = .secondaryLabel
            headerLbl.translatesAutoresizingMaskIntoConstraints = false
            let progressBar = UIProgressView(progressViewStyle: .default)
            progressBar.progress = achievement.progress
            progressBar.progressTintColor = tier.ringColor
            progressBar.trackTintColor = .systemGray5
            progressBar.layer.cornerRadius = 4
            progressBar.clipsToBounds = true
            progressBar.translatesAutoresizingMaskIntoConstraints = false
            let perc = Int(achievement.progress * 100)
            let percLbl = UILabel()
            percLbl.text = "\(achievement.currentValue) / \(achievement.requiredValue) gardens  (\(perc)%)"
            percLbl.font = .systemFont(ofSize: 13, weight: .medium)
            percLbl.textColor = tier.ringColor
            percLbl.textAlignment = .center
            percLbl.translatesAutoresizingMaskIntoConstraints = false
            let goalLbl = UILabel()
            goalLbl.text = "Complete \(achievement.requiredValue - achievement.currentValue) more gardens to unlock!"
            goalLbl.font = .systemFont(ofSize: 12)
            goalLbl.textColor = .secondaryLabel
            goalLbl.textAlignment = .center
            goalLbl.numberOfLines = 0
            goalLbl.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(headerLbl)
            card.addSubview(progressBar)
            card.addSubview(percLbl)
            card.addSubview(goalLbl)
            NSLayoutConstraint.activate([
                headerLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                headerLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                progressBar.topAnchor.constraint(equalTo: headerLbl.bottomAnchor, constant: 12),
                progressBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
                progressBar.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
                progressBar.heightAnchor.constraint(equalToConstant: 8),
                percLbl.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 10),
                percLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                goalLbl.topAnchor.constraint(equalTo: percLbl.bottomAnchor, constant: 6),
                goalLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                goalLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                goalLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
            ])
        }
        return card
    }

    private func makeGardenRoadmapCard(currentAchievement: Achievement) -> UIView {
        let card = makeCard()
        let titleLbl = UILabel()
        titleLbl.text = "Garden Roadmap"
        titleLbl.font = .systemFont(ofSize: 15, weight: .bold)
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLbl)

        let milestones: [(String, Int, GardenTier, String)] = [
            ("First Seed",      1,   .seed,   "leaf"),
            ("Sprouting Life",  10,  .sprout, "sprout.fill"),
            ("Blooming Garden", 25,  .bloom,  "leaf.circle.fill"),
            ("Ancient Grove",   50,  .tree,   "tree.fill"),
            ("Forest Keeper",   75,  .grove,  "camera.macro"),
            ("Eden",            100, .eden,   "sparkles")
        ]

        var lastView: UIView = titleLbl
        for (i, (name, count, tier, icon)) in milestones.enumerated() {
            let isCurrentOrPast = count <= currentAchievement.requiredValue
            let isCurrent = count == currentAchievement.requiredValue

            if i > 0 {
                let line = UIView()
                line.backgroundColor = isCurrentOrPast ? tier.ringColor.withAlphaComponent(0.4) : .systemGray5
                line.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(line)
                NSLayoutConstraint.activate([
                    line.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 35),
                    line.widthAnchor.constraint(equalToConstant: 2),
                    line.topAnchor.constraint(equalTo: lastView.bottomAnchor),
                    line.heightAnchor.constraint(equalToConstant: 10)
                ])
                lastView = line
            }

            let row = makeGardenRoadmapRow(name: name, count: count, tier: tier, icon: icon,
                                           isCurrentOrPast: isCurrentOrPast, isCurrent: isCurrent)
            row.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: i == 0 ? 12 : 0),
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
            lastView = row
        }

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            lastView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeGardenRoadmapRow(name: String, count: Int, tier: GardenTier, icon: String,
                                      isCurrentOrPast: Bool, isCurrent: Bool) -> UIView {
        let row = UIView()
        let circle = UIView()
        circle.layer.cornerRadius = 18
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.widthAnchor.constraint(equalToConstant: 36).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 36).isActive = true
        if isCurrentOrPast {
            let grad = CAGradientLayer()
            grad.colors = tier.gradientColors
            grad.startPoint = CGPoint(x: 0, y: 0)
            grad.endPoint   = CGPoint(x: 1, y: 1)
            grad.cornerRadius = 18
            grad.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
            circle.layer.insertSublayer(grad, at: 0)
        } else {
            circle.backgroundColor = .systemGray5
        }
        if isCurrent {
            circle.layer.borderWidth = 2.5
            circle.layer.borderColor = tier.ringColor.cgColor
        }
        let iconIV = UIImageView(image: UIImage(systemName: isCurrentOrPast ? icon : "lock.fill"))
        iconIV.tintColor = isCurrentOrPast ? .white : .systemGray3
        iconIV.contentMode = .scaleAspectFit
        iconIV.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(iconIV)
        NSLayoutConstraint.activate([
            iconIV.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            iconIV.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            iconIV.widthAnchor.constraint(equalToConstant: 16),
            iconIV.heightAnchor.constraint(equalToConstant: 16)
        ])
        let nameLbl = UILabel()
        nameLbl.text = name
        nameLbl.font = isCurrent ? .systemFont(ofSize: 14, weight: .bold) : .systemFont(ofSize: 14, weight: .medium)
        nameLbl.textColor = isCurrentOrPast ? .label : .secondaryLabel
        nameLbl.translatesAutoresizingMaskIntoConstraints = false
        let countLbl = UILabel()
        countLbl.text = "\(count) gardens"
        countLbl.font = .systemFont(ofSize: 12)
        countLbl.textColor = isCurrentOrPast ? tier.ringColor : .tertiaryLabel
        countLbl.translatesAutoresizingMaskIntoConstraints = false
        let tierLbl = UILabel()
        tierLbl.text = tier.label
        tierLbl.font = .systemFont(ofSize: 10, weight: .heavy)
        tierLbl.textColor = isCurrentOrPast ? tier.ringColor : .systemGray3
        tierLbl.translatesAutoresizingMaskIntoConstraints = false
        let textStack = UIStackView(arrangedSubviews: [nameLbl, countLbl])
        textStack.axis = .vertical; textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(circle)
        row.addSubview(textStack)
        row.addSubview(tierLbl)
        NSLayoutConstraint.activate([
            circle.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            circle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            tierLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            tierLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            row.heightAnchor.constraint(equalToConstant: 50)
        ])
        return row
    }

    private func gardenMotivation(for id: String, isLocked: Bool) -> String {
        if isLocked {
            switch id {
            case "garden_1":   return "✦ Complete your first garden to earn this."
            case "garden_10":  return "✦ Tend to 10 gardens and watch life grow."
            case "garden_25":  return "✦ 25 gardens of dedication await you."
            case "garden_50":  return "✦ Fifty gardens — a true ancient grove."
            case "garden_75":  return "✦ Seventy-five gardens. Become the forest keeper."
            case "garden_100": return "✦ One hundred gardens. Build your Eden."
            default:           return "✦ Keep growing your garden to unlock this."
            }
        } else {
            switch id {
            case "garden_1":   return "✦ Every forest begins with a single seed."
            case "garden_10":  return "✦ Ten gardens. Your roots are growing deep."
            case "garden_25":  return "✦ Twenty-five. Your garden is in full bloom."
            case "garden_50":  return "✦ Fifty gardens. You are an ancient force of nature."
            case "garden_75":  return "✦ Seventy-five. The forest bows to its keeper."
            case "garden_100": return "✦ One hundred. You have created paradise."
            default:           return "✦ Your garden grows with every session."
            }
        }
    }

    // MARK: - Points Detail UI
    private func setupPointsDetailUI() {
        guard let achievement = achievement else { return }

        scrollView.isHidden = true

        let tier = PointsTier.tier(for: achievement.requiredValue)
        let isLocked = !achievement.isUnlocked

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(container)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.topAnchor.constraint(equalTo: scroll.topAnchor),
            container.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        let headerView = makePointsHeaderGradient(tier: tier, isLocked: isLocked)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerView)

        let badge = PointsBadgeView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.configure(tier: tier, points: achievement.requiredValue,
                        iconName: achievement.iconName, isLocked: isLocked)
        container.addSubview(badge)

        let titleLbl = UILabel()
        titleLbl.text = achievement.title
        titleLbl.font = .systemFont(ofSize: 26, weight: .bold)
        titleLbl.textAlignment = .center
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLbl)

        let tierPill = makePointsTierPill(tier: tier, isLocked: isLocked)
        tierPill.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tierPill)

        let descCard = makePointsDescCard(achievement: achievement, tier: tier, isLocked: isLocked)
        descCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descCard)

        let statsRow = makePointsStatsRow(achievement: achievement, tier: tier)
        statsRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statsRow)

        let statusCard = makePointsStatusCard(achievement: achievement, tier: tier)
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusCard)

        let roadmapCard = makePointsRoadmapCard(currentAchievement: achievement)
        roadmapCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(roadmapCard)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),

            badge.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: headerView.bottomAnchor),
            badge.widthAnchor.constraint(equalToConstant: 160),
            badge.heightAnchor.constraint(equalToConstant: 180),

            titleLbl.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            tierPill.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 8),
            tierPill.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descCard.topAnchor.constraint(equalTo: tierPill.bottomAnchor, constant: 20),
            descCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            descCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statsRow.topAnchor.constraint(equalTo: descCard.bottomAnchor, constant: 16),
            statsRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statsRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statusCard.topAnchor.constraint(equalTo: statsRow.bottomAnchor, constant: 16),
            statusCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statusCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            roadmapCard.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 16),
            roadmapCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            roadmapCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            roadmapCard.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -32)
        ])

        badge.alpha = 0
        badge.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.55, delay: 0.1, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5) {
            badge.alpha = 1
            badge.transform = .identity
        }
    }

    private func makePointsHeaderGradient(tier: PointsTier, isLocked: Bool) -> UIView {
        let v = UIView()
        v.clipsToBounds = true
        let grad = CAGradientLayer()
        grad.colors = isLocked
            ? [UIColor.systemGray5.cgColor, UIColor.systemGray4.cgColor]
            : tier.gradientColors
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 1)
        v.layer.insertSublayer(grad, at: 0)
        for (size, alpha, offset) in [(CGFloat(200), 0.12, CGPoint(x: -30, y: -50)),
                                       (CGFloat(130), 0.09, CGPoint(x: 270, y: 30))] {
            let circle = UIView()
            circle.backgroundColor = UIColor.white.withAlphaComponent(alpha)
            circle.layer.cornerRadius = size / 2
            circle.frame = CGRect(x: offset.x, y: offset.y, width: size, height: size)
            v.addSubview(circle)
        }
        grad.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        return v
    }

    private func makePointsTierPill(tier: PointsTier, isLocked: Bool) -> UIView {
        let pill = UIView()
        pill.layer.cornerRadius = 12
        pill.clipsToBounds = true
        let grad = CAGradientLayer()
        grad.colors = isLocked
            ? [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            : tier.gradientColors
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 0)
        grad.cornerRadius = 12
        pill.layer.insertSublayer(grad, at: 0)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(stack)

        for _ in 0..<tier.gemCount {
            let iv = UIImageView(image: UIImage(systemName: tier.gemIcon))
            iv.tintColor = .white
            iv.widthAnchor.constraint(equalToConstant: 10).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 10).isActive = true
            stack.addArrangedSubview(iv)
        }

        let lbl = UILabel()
        lbl.text = tier.label
        lbl.font = .systemFont(ofSize: 12, weight: .heavy)
        lbl.textColor = .white
        stack.addArrangedSubview(lbl)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -7),
            stack.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -14)
        ])
        grad.frame = CGRect(x: 0, y: 0, width: 240, height: 40)
        return pill
    }

    private func makePointsDescCard(achievement: Achievement, tier: PointsTier, isLocked: Bool) -> UIView {
        let card = makeCard()
        let gemIcon = UIImageView(image: UIImage(systemName: "star.circle.fill"))
        gemIcon.tintColor = isLocked ? .systemGray3 : tier.ringColor
        gemIcon.contentMode = .scaleAspectFit
        gemIcon.translatesAutoresizingMaskIntoConstraints = false
        gemIcon.widthAnchor.constraint(equalToConstant: 26).isActive = true
        gemIcon.heightAnchor.constraint(equalToConstant: 26).isActive = true

        let desc = UILabel()
        desc.text = achievement.description
        desc.font = .systemFont(ofSize: 16, weight: .regular)
        desc.textColor = .label
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.translatesAutoresizingMaskIntoConstraints = false

        let motiveLine = UILabel()
        motiveLine.text = pointsMotivation(for: achievement.id, isLocked: isLocked)
        motiveLine.font = .systemFont(ofSize: 13, weight: .medium)
        motiveLine.textColor = isLocked ? .systemGray3 : tier.ringColor
        motiveLine.numberOfLines = 0
        motiveLine.textAlignment = .center
        motiveLine.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(gemIcon)
        card.addSubview(desc)
        card.addSubview(motiveLine)

        NSLayoutConstraint.activate([
            gemIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            gemIcon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            desc.topAnchor.constraint(equalTo: gemIcon.bottomAnchor, constant: 10),
            desc.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            desc.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            motiveLine.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 12),
            motiveLine.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            motiveLine.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            motiveLine.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makePointsStatsRow(achievement: Achievement, tier: PointsTier) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12

        let items: [(String, String, String)] = [
            ("star.fill",    "\(achievement.requiredValue)", "Points"),
            (tier.gemIcon,   "\(tier.gemCount)",             "Gems"),
            ("crown.fill",   tier.label,                     "Tier")
        ]

        for (icon, value, subtitle) in items {
            let card = makeCard()
            card.layer.cornerRadius = 14
            let iv = UIImageView(image: UIImage(systemName: icon))
            iv.tintColor = achievement.isUnlocked ? tier.ringColor : .systemGray3
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 22).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 22).isActive = true
            let valLbl = UILabel()
            valLbl.text = value
            valLbl.font = .systemFont(ofSize: 16, weight: .bold)
            valLbl.textColor = .label
            valLbl.textAlignment = .center
            valLbl.adjustsFontSizeToFitWidth = true
            valLbl.translatesAutoresizingMaskIntoConstraints = false
            let subLbl = UILabel()
            subLbl.text = subtitle
            subLbl.font = .systemFont(ofSize: 11, weight: .medium)
            subLbl.textColor = .secondaryLabel
            subLbl.textAlignment = .center
            subLbl.translatesAutoresizingMaskIntoConstraints = false
            let vStack = UIStackView(arrangedSubviews: [iv, valLbl, subLbl])
            vStack.axis = .vertical
            vStack.alignment = .center
            vStack.spacing = 4
            vStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8)
            ])
            stack.addArrangedSubview(card)
        }
        return stack
    }

    private func makePointsStatusCard(achievement: Achievement, tier: PointsTier) -> UIView {
        let card = makeCard()
        if achievement.isUnlocked {
            let checkIV = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
            checkIV.tintColor = tier.ringColor
            checkIV.contentMode = .scaleAspectFit
            checkIV.translatesAutoresizingMaskIntoConstraints = false
            checkIV.widthAnchor.constraint(equalToConstant: 36).isActive = true
            checkIV.heightAnchor.constraint(equalToConstant: 36).isActive = true
            let unlockedLbl = UILabel()
            unlockedLbl.text = "\(tier.label) Tier Unlocked!"
            unlockedLbl.font = .systemFont(ofSize: 17, weight: .bold)
            unlockedLbl.textColor = tier.ringColor
            unlockedLbl.textAlignment = .center
            unlockedLbl.translatesAutoresizingMaskIntoConstraints = false
            var dateText = ""
            if let date = achievement.dateUnlocked {
                let fmt = DateFormatter(); fmt.dateStyle = .long
                dateText = "Earned on \(fmt.string(from: date))"
            }
            let dateLbl = UILabel()
            dateLbl.text = dateText
            dateLbl.font = .systemFont(ofSize: 13)
            dateLbl.textColor = .secondaryLabel
            dateLbl.textAlignment = .center
            dateLbl.translatesAutoresizingMaskIntoConstraints = false
            let vStack = UIStackView(arrangedSubviews: [checkIV, unlockedLbl, dateLbl])
            vStack.axis = .vertical; vStack.alignment = .center; vStack.spacing = 6
            vStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
        } else {
            let headerLbl = UILabel()
            headerLbl.text = "Your Progress"
            headerLbl.font = .systemFont(ofSize: 14, weight: .semibold)
            headerLbl.textColor = .secondaryLabel
            headerLbl.translatesAutoresizingMaskIntoConstraints = false
            let progressBar = UIProgressView(progressViewStyle: .default)
            progressBar.progress = achievement.progress
            progressBar.progressTintColor = tier.ringColor
            progressBar.trackTintColor = .systemGray5
            progressBar.layer.cornerRadius = 4
            progressBar.clipsToBounds = true
            progressBar.translatesAutoresizingMaskIntoConstraints = false
            let perc = Int(achievement.progress * 100)
            let percLbl = UILabel()
            percLbl.text = "\(achievement.currentValue) / \(achievement.requiredValue) pts  (\(perc)%)"
            percLbl.font = .systemFont(ofSize: 13, weight: .medium)
            percLbl.textColor = tier.ringColor
            percLbl.textAlignment = .center
            percLbl.translatesAutoresizingMaskIntoConstraints = false
            let goalLbl = UILabel()
            goalLbl.text = "Earn \(achievement.requiredValue - achievement.currentValue) more points to unlock!"
            goalLbl.font = .systemFont(ofSize: 12)
            goalLbl.textColor = .secondaryLabel
            goalLbl.textAlignment = .center
            goalLbl.numberOfLines = 0
            goalLbl.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(headerLbl)
            card.addSubview(progressBar)
            card.addSubview(percLbl)
            card.addSubview(goalLbl)
            NSLayoutConstraint.activate([
                headerLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                headerLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                progressBar.topAnchor.constraint(equalTo: headerLbl.bottomAnchor, constant: 12),
                progressBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
                progressBar.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
                progressBar.heightAnchor.constraint(equalToConstant: 8),
                percLbl.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 10),
                percLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                goalLbl.topAnchor.constraint(equalTo: percLbl.bottomAnchor, constant: 6),
                goalLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                goalLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                goalLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
            ])
        }
        return card
    }

    private func makePointsRoadmapCard(currentAchievement: Achievement) -> UIView {
        let card = makeCard()
        let titleLbl = UILabel()
        titleLbl.text = "Points Roadmap"
        titleLbl.font = .systemFont(ofSize: 15, weight: .bold)
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLbl)

        let milestones: [(String, Int, PointsTier)] = [
            ("Calm Builder",       200,  .bronze),
            ("Mind Strengthening", 350,  .silver),
            ("Growth Accelerator", 600,  .gold),
            ("Inner Stability",    800,  .sapphire),
            ("Serenity Architect", 1200, .amethyst),
            ("Mindora Champion",   2000, .diamond)
        ]

        var lastView: UIView = titleLbl
        for (i, (name, pts, tier)) in milestones.enumerated() {
            let isCurrentOrPast = pts <= currentAchievement.requiredValue
            let isCurrent = pts == currentAchievement.requiredValue

            if i > 0 {
                let line = UIView()
                line.backgroundColor = isCurrentOrPast ? tier.ringColor.withAlphaComponent(0.4) : .systemGray5
                line.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(line)
                NSLayoutConstraint.activate([
                    line.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 35),
                    line.widthAnchor.constraint(equalToConstant: 2),
                    line.topAnchor.constraint(equalTo: lastView.bottomAnchor),
                    line.heightAnchor.constraint(equalToConstant: 10)
                ])
                lastView = line
            }

            let row = makePointsRoadmapRow(name: name, pts: pts, tier: tier,
                                           isCurrentOrPast: isCurrentOrPast, isCurrent: isCurrent)
            row.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: i == 0 ? 12 : 0),
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
            lastView = row
        }

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            lastView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makePointsRoadmapRow(name: String, pts: Int, tier: PointsTier,
                                      isCurrentOrPast: Bool, isCurrent: Bool) -> UIView {
        let row = UIView()
        let circle = UIView()
        circle.layer.cornerRadius = 18
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.widthAnchor.constraint(equalToConstant: 36).isActive = true
        circle.heightAnchor.constraint(equalToConstant: 36).isActive = true
        if isCurrentOrPast {
            let grad = CAGradientLayer()
            grad.colors = tier.gradientColors
            grad.startPoint = CGPoint(x: 0, y: 0)
            grad.endPoint   = CGPoint(x: 1, y: 1)
            grad.cornerRadius = 18
            grad.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
            circle.layer.insertSublayer(grad, at: 0)
        } else {
            circle.backgroundColor = .systemGray5
        }
        if isCurrent {
            circle.layer.borderWidth = 2.5
            circle.layer.borderColor = tier.ringColor.cgColor
        }
        let iconIV = UIImageView(image: UIImage(systemName: isCurrentOrPast ? tier.gemIcon : "lock.fill"))
        iconIV.tintColor = isCurrentOrPast ? .white : .systemGray3
        iconIV.contentMode = .scaleAspectFit
        iconIV.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(iconIV)
        NSLayoutConstraint.activate([
            iconIV.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            iconIV.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
            iconIV.widthAnchor.constraint(equalToConstant: 16),
            iconIV.heightAnchor.constraint(equalToConstant: 16)
        ])
        let nameLbl = UILabel()
        nameLbl.text = name
        nameLbl.font = isCurrent ? .systemFont(ofSize: 14, weight: .bold) : .systemFont(ofSize: 14, weight: .medium)
        nameLbl.textColor = isCurrentOrPast ? .label : .secondaryLabel
        nameLbl.translatesAutoresizingMaskIntoConstraints = false
        let ptsLbl = UILabel()
        ptsLbl.text = "\(pts) pts"
        ptsLbl.font = .systemFont(ofSize: 12)
        ptsLbl.textColor = isCurrentOrPast ? tier.ringColor : .tertiaryLabel
        ptsLbl.translatesAutoresizingMaskIntoConstraints = false
        let tierLbl = UILabel()
        tierLbl.text = tier.label
        tierLbl.font = .systemFont(ofSize: 10, weight: .heavy)
        tierLbl.textColor = isCurrentOrPast ? tier.ringColor : .systemGray3
        tierLbl.translatesAutoresizingMaskIntoConstraints = false
        let textStack = UIStackView(arrangedSubviews: [nameLbl, ptsLbl])
        textStack.axis = .vertical; textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(circle)
        row.addSubview(textStack)
        row.addSubview(tierLbl)
        NSLayoutConstraint.activate([
            circle.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            circle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            tierLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            tierLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            row.heightAnchor.constraint(equalToConstant: 50)
        ])
        return row
    }

    private func pointsMotivation(for id: String, isLocked: Bool) -> String {
        if isLocked {
            switch id {
            case "points_200":  return "✦ Earn 200 points to claim your first gem."
            case "points_350":  return "✦ 350 points of dedication awaits you."
            case "points_600":  return "✦ 600 points — where transformation begins."
            case "points_800":  return "✦ 800 points. Forge your inner stability."
            case "points_1200": return "✦ 1200 points. Architect your serenity."
            case "points_2000": return "✦ 2000 points. Become the Mindora Champion."
            default:            return "✦ Keep earning points to unlock this."
            }
        } else {
            switch id {
            case "points_200":  return "✦ Every point is a step toward peace."
            case "points_350":  return "✦ Your mind is growing stronger every day."
            case "points_600":  return "✦ You have crossed the threshold of real growth."
            case "points_800":  return "✦ Stillness that the world cannot shake."
            case "points_1200": return "✦ You are designing your life around mindfulness."
            case "points_2000": return "✦ A true champion of mind, breath, and spirit."
            default:            return "✦ Your points reflect your dedication."
            }
        }
    }

    // MARK: - Helpers
    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 18
        v.layer.cornerCurve = .continuous
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.shadowRadius = 10
        return v
    }

    private func streakMotivation(for id: String, isLocked: Bool) -> String {
        if isLocked {
            switch id {
            case "streak_3":  return "✦ Show up 3 days in a row to earn this."
            case "streak_7":  return "✦ A full week of consistency unlocks this."
            case "streak_30": return "✦ 30 days of dedication — you've got this."
            case "streak_60": return "✦ 60 days. The ultimate streak challenge."
            default:          return "✦ Keep your streak alive to unlock this."
            }
        } else {
            switch id {
            case "streak_3":  return "✦ Every great journey begins with a single step."
            case "streak_7":  return "✦ A week of showing up. That's discipline."
            case "streak_30": return "✦ A month of growth. You are unstoppable."
            case "streak_60": return "✦ Two months. You've made this part of your identity."
            default:          return "✦ You earned this. Be proud."
            }
        }
    }

    // MARK: - Growth Detail UI
    private func setupGrowthDetailUI() {
        guard let achievement = achievement else { return }
        scrollView.isHidden = true
        let tier = GrowthStageTier.tier(for: achievement.id)
        let isLocked = !achievement.isUnlocked

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(container)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.topAnchor.constraint(equalTo: scroll.topAnchor),
            container.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        // Header
        let headerView = UIView()
        headerView.clipsToBounds = true
        headerView.translatesAutoresizingMaskIntoConstraints = false
        let headerGrad = CAGradientLayer()
        headerGrad.colors = isLocked
            ? [UIColor.systemGray5.cgColor, UIColor.systemGray4.cgColor]
            : tier.gradientColors
        headerGrad.startPoint = CGPoint(x: 0, y: 0)
        headerGrad.endPoint   = CGPoint(x: 1, y: 1)
        headerGrad.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        headerView.layer.insertSublayer(headerGrad, at: 0)
        container.addSubview(headerView)

        // Badge
        let badge = GrowthStageBadgeView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.configure(tier: tier, isLocked: isLocked)
        container.addSubview(badge)

        // Title
        let titleLbl = UILabel()
        titleLbl.text = achievement.title
        titleLbl.font = .systemFont(ofSize: 26, weight: .bold)
        titleLbl.textAlignment = .center
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLbl)

        // Stage pill
        let stagePill = makeGrowthStagePill(tier: tier, isLocked: isLocked)
        stagePill.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stagePill)

        // Description card
        let descCard = makeGrowthDescCard(achievement: achievement, tier: tier, isLocked: isLocked)
        descCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descCard)

        // Status card
        let statusCard = makeGrowthStatusCard(achievement: achievement, tier: tier)
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusCard)

        // Roadmap
        let roadmapCard = makeGrowthRoadmapCard(currentTier: tier, isCurrentUnlocked: achievement.isUnlocked)
        roadmapCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(roadmapCard)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),

            badge.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: headerView.bottomAnchor),
            badge.widthAnchor.constraint(equalToConstant: 160),
            badge.heightAnchor.constraint(equalToConstant: 180),

            titleLbl.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            stagePill.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 8),
            stagePill.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descCard.topAnchor.constraint(equalTo: stagePill.bottomAnchor, constant: 20),
            descCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            descCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statusCard.topAnchor.constraint(equalTo: descCard.bottomAnchor, constant: 16),
            statusCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statusCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            roadmapCard.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 16),
            roadmapCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            roadmapCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            roadmapCard.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -32)
        ])

        badge.alpha = 0; badge.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.55, delay: 0.1, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5) {
            badge.alpha = 1; badge.transform = .identity
        }
    }

    private func makeGrowthStagePill(tier: GrowthStageTier, isLocked: Bool) -> UIView {
        let pill = UIView()
        pill.layer.cornerRadius = 12; pill.clipsToBounds = true
        let grad = CAGradientLayer()
        grad.colors = isLocked ? [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor] : tier.gradientColors
        grad.startPoint = CGPoint(x: 0, y: 0); grad.endPoint = CGPoint(x: 1, y: 0)
        grad.cornerRadius = 12; grad.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        pill.layer.insertSublayer(grad, at: 0)
        let stack = UIStackView(); stack.axis = .horizontal; stack.spacing = 6; stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false; pill.addSubview(stack)
        let iv = UIImageView(image: UIImage(systemName: tier.icon))
        iv.tintColor = .white; iv.widthAnchor.constraint(equalToConstant: 14).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 14).isActive = true; stack.addArrangedSubview(iv)
        let lbl = UILabel(); lbl.text = "Stage \(tier.stageNumber) · \(tier.label)"
        lbl.font = .systemFont(ofSize: 12, weight: .heavy); lbl.textColor = .white
        stack.addArrangedSubview(lbl)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -7),
            stack.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -14)
        ])
        return pill
    }

    private func makeGrowthDescCard(achievement: Achievement, tier: GrowthStageTier, isLocked: Bool) -> UIView {
        let card = makeCard()
        let iv = UIImageView(image: UIImage(systemName: tier.icon))
        iv.tintColor = isLocked ? .systemGray3 : tier.ringColor
        iv.contentMode = .scaleAspectFit; iv.translatesAutoresizingMaskIntoConstraints = false
        iv.widthAnchor.constraint(equalToConstant: 28).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let desc = UILabel(); desc.text = achievement.description
        desc.font = .systemFont(ofSize: 16); desc.textColor = .label
        desc.numberOfLines = 0; desc.textAlignment = .center
        desc.translatesAutoresizingMaskIntoConstraints = false
        let quote = UILabel(); quote.text = growthMotivation(for: achievement.id, isLocked: isLocked)
        quote.font = .systemFont(ofSize: 13, weight: .medium)
        quote.textColor = isLocked ? .systemGray3 : tier.ringColor
        quote.numberOfLines = 0; quote.textAlignment = .center
        quote.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iv); card.addSubview(desc); card.addSubview(quote)
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            iv.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            desc.topAnchor.constraint(equalTo: iv.bottomAnchor, constant: 10),
            desc.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            desc.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            quote.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 12),
            quote.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            quote.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            quote.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeGrowthStatusCard(achievement: Achievement, tier: GrowthStageTier) -> UIView {
        let card = makeCard()
        if achievement.isUnlocked {
            let iv = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
            iv.tintColor = tier.ringColor; iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 36).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 36).isActive = true
            let lbl = UILabel(); lbl.text = "\(tier.label) Stage Unlocked!"
            lbl.font = .systemFont(ofSize: 17, weight: .bold); lbl.textColor = tier.ringColor
            lbl.textAlignment = .center; lbl.translatesAutoresizingMaskIntoConstraints = false
            var dateText = ""
            if let d = achievement.dateUnlocked { let f = DateFormatter(); f.dateStyle = .long; dateText = "Earned on \(f.string(from: d))" }
            let dateLbl = UILabel(); dateLbl.text = dateText; dateLbl.font = .systemFont(ofSize: 13)
            dateLbl.textColor = .secondaryLabel; dateLbl.textAlignment = .center
            dateLbl.translatesAutoresizingMaskIntoConstraints = false
            let vs = UIStackView(arrangedSubviews: [iv, lbl, dateLbl])
            vs.axis = .vertical; vs.alignment = .center; vs.spacing = 6
            vs.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(vs)
            NSLayoutConstraint.activate([
                vs.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
                vs.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
                vs.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                vs.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
        } else {
            let hdr = UILabel(); hdr.text = "Your Progress"
            hdr.font = .systemFont(ofSize: 14, weight: .semibold); hdr.textColor = .secondaryLabel
            hdr.translatesAutoresizingMaskIntoConstraints = false
            let pb = UIProgressView(progressViewStyle: .default)
            pb.progress = achievement.progress; pb.progressTintColor = tier.ringColor
            pb.trackTintColor = .systemGray5; pb.layer.cornerRadius = 4; pb.clipsToBounds = true
            pb.translatesAutoresizingMaskIntoConstraints = false
            let perc = Int(achievement.progress * 100)
            let percLbl = UILabel()
            percLbl.text = achievement.id == "growth_egg"
                ? (achievement.currentValue >= 1 ? "Ready to unlock!" : "Complete your first session")
                : "\(achievement.currentValue) / \(achievement.requiredValue) pts (\(perc)%)"
            percLbl.font = .systemFont(ofSize: 13, weight: .medium); percLbl.textColor = tier.ringColor
            percLbl.textAlignment = .center; percLbl.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(hdr); card.addSubview(pb); card.addSubview(percLbl)
            NSLayoutConstraint.activate([
                hdr.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                hdr.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                pb.topAnchor.constraint(equalTo: hdr.bottomAnchor, constant: 12),
                pb.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
                pb.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
                pb.heightAnchor.constraint(equalToConstant: 8),
                percLbl.topAnchor.constraint(equalTo: pb.bottomAnchor, constant: 10),
                percLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                percLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
            ])
        }
        return card
    }

    private func makeGrowthRoadmapCard(currentTier: GrowthStageTier, isCurrentUnlocked: Bool) -> UIView {
        let card = makeCard()
        let titleLbl = UILabel(); titleLbl.text = "Growth Journey"
        titleLbl.font = .systemFont(ofSize: 15, weight: .bold); titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(titleLbl)

        let stages: [(String, String, GrowthStageTier, String)] = [
            ("First Egg",        "1 session",  .egg,         "🥚"),
            ("Caterpillar Born", "25 points",  .caterpillar, "🐛"),
            ("Into the Cocoon",  "75 points",  .cocoon,      "🫘"),
            ("Butterfly Emerges","150 points", .butterfly,   "🦋")
        ]

        var lastView: UIView = titleLbl
        for (i, (name, req, stageTier, emoji)) in stages.enumerated() {
            let isPast = stageTier.stageNumber < currentTier.stageNumber
            let isCurrent = stageTier.stageNumber == currentTier.stageNumber
            let isActive = isPast || (isCurrent && isCurrentUnlocked)

            if i > 0 {
                let line = UIView()
                line.backgroundColor = isActive ? stageTier.ringColor.withAlphaComponent(0.4) : .systemGray5
                line.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(line)
                NSLayoutConstraint.activate([
                    line.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 35),
                    line.widthAnchor.constraint(equalToConstant: 2),
                    line.topAnchor.constraint(equalTo: lastView.bottomAnchor),
                    line.heightAnchor.constraint(equalToConstant: 10)
                ])
                lastView = line
            }

            let row = UIView(); row.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(row)
            let circle = UIView(); circle.layer.cornerRadius = 18
            circle.translatesAutoresizingMaskIntoConstraints = false
            circle.widthAnchor.constraint(equalToConstant: 36).isActive = true
            circle.heightAnchor.constraint(equalToConstant: 36).isActive = true
            if isActive {
                let g = CAGradientLayer(); g.colors = stageTier.gradientColors
                g.startPoint = CGPoint(x: 0, y: 0); g.endPoint = CGPoint(x: 1, y: 1)
                g.cornerRadius = 18; g.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
                circle.layer.insertSublayer(g, at: 0)
            } else { circle.backgroundColor = .systemGray5 }
            if isCurrent { circle.layer.borderWidth = 2.5; circle.layer.borderColor = stageTier.ringColor.cgColor }
            let emojiLbl = UILabel(); emojiLbl.text = emoji; emojiLbl.font = .systemFont(ofSize: 18)
            emojiLbl.textAlignment = .center; emojiLbl.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(emojiLbl)
            NSLayoutConstraint.activate([
                emojiLbl.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
                emojiLbl.centerYAnchor.constraint(equalTo: circle.centerYAnchor)
            ])
            let nameLbl = UILabel(); nameLbl.text = name
            nameLbl.font = isCurrent ? .systemFont(ofSize: 14, weight: .bold) : .systemFont(ofSize: 14, weight: .medium)
            nameLbl.textColor = isActive ? .label : .secondaryLabel
            nameLbl.translatesAutoresizingMaskIntoConstraints = false
            let reqLbl = UILabel(); reqLbl.text = req; reqLbl.font = .systemFont(ofSize: 12)
            reqLbl.textColor = isActive ? stageTier.ringColor : .tertiaryLabel
            reqLbl.translatesAutoresizingMaskIntoConstraints = false
            let ts = UIStackView(arrangedSubviews: [nameLbl, reqLbl])
            ts.axis = .vertical; ts.spacing = 2; ts.translatesAutoresizingMaskIntoConstraints = false
            let stageLbl = UILabel(); stageLbl.text = "Stage \(stageTier.stageNumber)"
            stageLbl.font = .systemFont(ofSize: 10, weight: .heavy)
            stageLbl.textColor = isActive ? stageTier.ringColor : .systemGray3
            stageLbl.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(circle); row.addSubview(ts); row.addSubview(stageLbl)
            NSLayoutConstraint.activate([
                circle.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                circle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                ts.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 12),
                ts.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                stageLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                stageLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                row.heightAnchor.constraint(equalToConstant: 50),
                row.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: i == 0 ? 12 : 0),
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
            lastView = row
        }
        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            lastView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func growthMotivation(for id: String, isLocked: Bool) -> String {
        if isLocked {
            switch id {
            case "growth_egg":         return "✦ Complete your first session to hatch your egg."
            case "growth_caterpillar": return "✦ Reach 25 points to begin your crawl."
            case "growth_cocoon":      return "✦ 75 points of stillness will wrap you in your cocoon."
            case "growth_butterfly":   return "✦ 150 points. Your wings are waiting."
            default:                   return "✦ Keep growing to unlock this stage."
            }
        } else {
            switch id {
            case "growth_egg":         return "✦ Every journey begins with a single step."
            case "growth_caterpillar": return "✦ Slow and steady. You are growing."
            case "growth_cocoon":      return "✦ In stillness, transformation happens."
            case "growth_butterfly":   return "✦ You have emerged. Beautiful and free."
            default:                   return "✦ Growth is always happening."
            }
        }
    }

    // MARK: - Mindfulness Detail UI
    private func setupMindfulnessDetailUI() {
        guard let achievement = achievement else { return }
        scrollView.isHidden = true
        let tier = MindfulnessTier.tier(for: achievement.id)
        let isLocked = !achievement.isUnlocked

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(container)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.topAnchor.constraint(equalTo: scroll.topAnchor),
            container.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        // Header
        let headerView = UIView()
        headerView.clipsToBounds = true
        headerView.translatesAutoresizingMaskIntoConstraints = false
        let headerGrad = CAGradientLayer()
        headerGrad.colors = isLocked
            ? [UIColor.systemGray5.cgColor, UIColor.systemGray4.cgColor]
            : tier.gradientColors
        headerGrad.startPoint = CGPoint(x: 0, y: 0); headerGrad.endPoint = CGPoint(x: 1, y: 1)
        headerGrad.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        headerView.layer.insertSublayer(headerGrad, at: 0)
        container.addSubview(headerView)

        // Badge
        let badge = MindfulnessBadgeView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.configure(tier: tier, isLocked: isLocked)
        container.addSubview(badge)

        // Title
        let titleLbl = UILabel(); titleLbl.text = achievement.title
        titleLbl.font = .systemFont(ofSize: 26, weight: .bold)
        titleLbl.textAlignment = .center; titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false; container.addSubview(titleLbl)

        // Tier pill
        let tierPill = makeMindfulnessTierPill(tier: tier, isLocked: isLocked)
        tierPill.translatesAutoresizingMaskIntoConstraints = false; container.addSubview(tierPill)

        // Description card
        let descCard = makeMindfulnessDescCard(achievement: achievement, tier: tier, isLocked: isLocked)
        descCard.translatesAutoresizingMaskIntoConstraints = false; container.addSubview(descCard)

        // Stats row
        let statsRow = makeMindfulnessStatsRow(achievement: achievement, tier: tier)
        statsRow.translatesAutoresizingMaskIntoConstraints = false; container.addSubview(statsRow)

        // Status card
        let statusCard = makeMindfulnessStatusCard(achievement: achievement, tier: tier)
        statusCard.translatesAutoresizingMaskIntoConstraints = false; container.addSubview(statusCard)

        // Ladder card
        let ladderCard = makeMindfulnessLadderCard(currentTier: tier, isCurrentUnlocked: achievement.isUnlocked)
        ladderCard.translatesAutoresizingMaskIntoConstraints = false; container.addSubview(ladderCard)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),

            badge.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: headerView.bottomAnchor),
            badge.widthAnchor.constraint(equalToConstant: 160),
            badge.heightAnchor.constraint(equalToConstant: 180),

            titleLbl.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            tierPill.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 8),
            tierPill.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descCard.topAnchor.constraint(equalTo: tierPill.bottomAnchor, constant: 20),
            descCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            descCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statsRow.topAnchor.constraint(equalTo: descCard.bottomAnchor, constant: 16),
            statsRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statsRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statusCard.topAnchor.constraint(equalTo: statsRow.bottomAnchor, constant: 16),
            statusCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statusCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            ladderCard.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 16),
            ladderCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            ladderCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            ladderCard.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -32)
        ])

        badge.alpha = 0; badge.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.55, delay: 0.1, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5) {
            badge.alpha = 1; badge.transform = .identity
        }
    }

    private func makeMindfulnessTierPill(tier: MindfulnessTier, isLocked: Bool) -> UIView {
        let pill = UIView(); pill.layer.cornerRadius = 12; pill.clipsToBounds = true
        let grad = CAGradientLayer()
        grad.colors = isLocked ? [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor] : tier.gradientColors
        grad.startPoint = CGPoint(x: 0, y: 0); grad.endPoint = CGPoint(x: 1, y: 0)
        grad.cornerRadius = 12; grad.frame = CGRect(x: 0, y: 0, width: 240, height: 40)
        pill.layer.insertSublayer(grad, at: 0)
        let stack = UIStackView(); stack.axis = .horizontal; stack.spacing = 6; stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false; pill.addSubview(stack)
        let iv = UIImageView(image: UIImage(systemName: tier.icon))
        iv.tintColor = .white; iv.widthAnchor.constraint(equalToConstant: 14).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 14).isActive = true; stack.addArrangedSubview(iv)
        let lbl = UILabel(); lbl.text = tier.label
        lbl.font = .systemFont(ofSize: 12, weight: .heavy); lbl.textColor = .white
        stack.addArrangedSubview(lbl)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -7),
            stack.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -14)
        ])
        return pill
    }

    private func makeMindfulnessDescCard(achievement: Achievement, tier: MindfulnessTier, isLocked: Bool) -> UIView {
        let card = makeCard()
        let iv = UIImageView(image: UIImage(systemName: tier.icon))
        iv.tintColor = isLocked ? .systemGray3 : tier.ringColor
        iv.contentMode = .scaleAspectFit; iv.translatesAutoresizingMaskIntoConstraints = false
        iv.widthAnchor.constraint(equalToConstant: 28).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let desc = UILabel(); desc.text = achievement.description
        desc.font = .systemFont(ofSize: 16); desc.textColor = .label
        desc.numberOfLines = 0; desc.textAlignment = .center
        desc.translatesAutoresizingMaskIntoConstraints = false
        let quote = UILabel(); quote.text = mindfulnessMotivation(for: achievement.id, isLocked: isLocked)
        quote.font = .systemFont(ofSize: 13, weight: .medium)
        quote.textColor = isLocked ? .systemGray3 : tier.ringColor
        quote.numberOfLines = 0; quote.textAlignment = .center
        quote.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iv); card.addSubview(desc); card.addSubview(quote)
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            iv.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            desc.topAnchor.constraint(equalTo: iv.bottomAnchor, constant: 10),
            desc.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            desc.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            quote.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 12),
            quote.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            quote.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            quote.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeMindfulnessStatsRow(achievement: Achievement, tier: MindfulnessTier) -> UIView {
        let stack = UIStackView(); stack.axis = .horizontal
        stack.distribution = .fillEqually; stack.spacing = 12
        let items: [(String, String, String)] = [
            (tier.icon, "\(tier.sessionCount)", "Sessions"),
            ("sun.max.fill", "1 Day", "Window"),
            ("brain.head.profile", tier.label.components(separatedBy: " ").first ?? tier.label, "Level")
        ]
        for (icon, value, subtitle) in items {
            let card = makeCard(); card.layer.cornerRadius = 14
            let iv = UIImageView(image: UIImage(systemName: icon))
            iv.tintColor = achievement.isUnlocked ? tier.ringColor : .systemGray3
            iv.contentMode = .scaleAspectFit; iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 22).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 22).isActive = true
            let valLbl = UILabel(); valLbl.text = value
            valLbl.font = .systemFont(ofSize: 15, weight: .bold); valLbl.textColor = .label
            valLbl.textAlignment = .center; valLbl.adjustsFontSizeToFitWidth = true
            valLbl.translatesAutoresizingMaskIntoConstraints = false
            let subLbl = UILabel(); subLbl.text = subtitle
            subLbl.font = .systemFont(ofSize: 11, weight: .medium); subLbl.textColor = .secondaryLabel
            subLbl.textAlignment = .center; subLbl.translatesAutoresizingMaskIntoConstraints = false
            let vs = UIStackView(arrangedSubviews: [iv, valLbl, subLbl])
            vs.axis = .vertical; vs.alignment = .center; vs.spacing = 4
            vs.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(vs)
            NSLayoutConstraint.activate([
                vs.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                vs.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
                vs.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
                vs.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8)
            ])
            stack.addArrangedSubview(card)
        }
        return stack
    }

    private func makeMindfulnessStatusCard(achievement: Achievement, tier: MindfulnessTier) -> UIView {
        let card = makeCard()
        if achievement.isUnlocked {
            let iv = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
            iv.tintColor = tier.ringColor; iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 36).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 36).isActive = true
            let lbl = UILabel(); lbl.text = "\(tier.label) Unlocked!"
            lbl.font = .systemFont(ofSize: 17, weight: .bold); lbl.textColor = tier.ringColor
            lbl.textAlignment = .center; lbl.translatesAutoresizingMaskIntoConstraints = false
            var dateText = ""
            if let d = achievement.dateUnlocked { let f = DateFormatter(); f.dateStyle = .long; dateText = "Earned on \(f.string(from: d))" }
            let dateLbl = UILabel(); dateLbl.text = dateText; dateLbl.font = .systemFont(ofSize: 13)
            dateLbl.textColor = .secondaryLabel; dateLbl.textAlignment = .center
            dateLbl.translatesAutoresizingMaskIntoConstraints = false
            let vs = UIStackView(arrangedSubviews: [iv, lbl, dateLbl])
            vs.axis = .vertical; vs.alignment = .center; vs.spacing = 6
            vs.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(vs)
            NSLayoutConstraint.activate([
                vs.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
                vs.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
                vs.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                vs.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
        } else {
            let hdr = UILabel(); hdr.text = "Today's Sessions"
            hdr.font = .systemFont(ofSize: 14, weight: .semibold); hdr.textColor = .secondaryLabel
            hdr.translatesAutoresizingMaskIntoConstraints = false
            let pb = UIProgressView(progressViewStyle: .default)
            pb.progress = achievement.progress; pb.progressTintColor = tier.ringColor
            pb.trackTintColor = .systemGray5; pb.layer.cornerRadius = 4; pb.clipsToBounds = true
            pb.translatesAutoresizingMaskIntoConstraints = false
            let percLbl = UILabel()
            percLbl.text = "\(achievement.currentValue) / \(achievement.requiredValue) sessions today"
            percLbl.font = .systemFont(ofSize: 13, weight: .medium); percLbl.textColor = tier.ringColor
            percLbl.textAlignment = .center; percLbl.translatesAutoresizingMaskIntoConstraints = false
            let goalLbl = UILabel()
            goalLbl.text = "\(achievement.requiredValue - achievement.currentValue) more sessions needed today"
            goalLbl.font = .systemFont(ofSize: 12); goalLbl.textColor = .secondaryLabel
            goalLbl.textAlignment = .center; goalLbl.numberOfLines = 0
            goalLbl.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(hdr); card.addSubview(pb); card.addSubview(percLbl); card.addSubview(goalLbl)
            NSLayoutConstraint.activate([
                hdr.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                hdr.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                pb.topAnchor.constraint(equalTo: hdr.bottomAnchor, constant: 12),
                pb.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
                pb.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
                pb.heightAnchor.constraint(equalToConstant: 8),
                percLbl.topAnchor.constraint(equalTo: pb.bottomAnchor, constant: 10),
                percLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                goalLbl.topAnchor.constraint(equalTo: percLbl.bottomAnchor, constant: 6),
                goalLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                goalLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                goalLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
            ])
        }
        return card
    }

    private func makeMindfulnessLadderCard(currentTier: MindfulnessTier, isCurrentUnlocked: Bool) -> UIView {
        let card = makeCard()
        let titleLbl = UILabel(); titleLbl.text = "Mindfulness Depth Ladder"
        titleLbl.font = .systemFont(ofSize: 15, weight: .bold); titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(titleLbl)

        let tiers: [(MindfulnessTier, String)] = [
            (.double,   "mind_double"),
            (.triple,   "mind_triple"),
            (.presence, "mind_4"),
            (.deep,     "mind_deep")
        ]

        var lastView: UIView = titleLbl
        for (i, (t, _)) in tiers.enumerated() {
            let isPast = t.sessionCount < currentTier.sessionCount
            let isCurrent = t.sessionCount == currentTier.sessionCount
            let isActive = isPast || (isCurrent && isCurrentUnlocked)

            if i > 0 {
                let line = UIView()
                line.backgroundColor = isActive ? t.ringColor.withAlphaComponent(0.4) : .systemGray5
                line.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(line)
                NSLayoutConstraint.activate([
                    line.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 35),
                    line.widthAnchor.constraint(equalToConstant: 2),
                    line.topAnchor.constraint(equalTo: lastView.bottomAnchor),
                    line.heightAnchor.constraint(equalToConstant: 10)
                ])
                lastView = line
            }

            let row = UIView(); row.translatesAutoresizingMaskIntoConstraints = false; card.addSubview(row)
            let circle = UIView(); circle.layer.cornerRadius = 18
            circle.translatesAutoresizingMaskIntoConstraints = false
            circle.widthAnchor.constraint(equalToConstant: 36).isActive = true
            circle.heightAnchor.constraint(equalToConstant: 36).isActive = true
            if isActive {
                let g = CAGradientLayer(); g.colors = t.gradientColors
                g.startPoint = CGPoint(x: 0, y: 0); g.endPoint = CGPoint(x: 1, y: 1)
                g.cornerRadius = 18; g.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
                circle.layer.insertSublayer(g, at: 0)
            } else { circle.backgroundColor = .systemGray5 }
            if isCurrent { circle.layer.borderWidth = 2.5; circle.layer.borderColor = t.ringColor.cgColor }
            let iv = UIImageView(image: UIImage(systemName: isActive ? t.icon : "lock.fill"))
            iv.tintColor = isActive ? .white : .systemGray3
            iv.contentMode = .scaleAspectFit; iv.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(iv)
            NSLayoutConstraint.activate([
                iv.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
                iv.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
                iv.widthAnchor.constraint(equalToConstant: 16), iv.heightAnchor.constraint(equalToConstant: 16)
            ])
            let nameLbl = UILabel(); nameLbl.text = t.label
            nameLbl.font = isCurrent ? .systemFont(ofSize: 13, weight: .bold) : .systemFont(ofSize: 13, weight: .medium)
            nameLbl.textColor = isActive ? .label : .secondaryLabel
            nameLbl.translatesAutoresizingMaskIntoConstraints = false
            let sessLbl = UILabel(); sessLbl.text = "\(t.sessionCount) sessions in a day"
            sessLbl.font = .systemFont(ofSize: 11); sessLbl.textColor = isActive ? t.ringColor : .tertiaryLabel
            sessLbl.translatesAutoresizingMaskIntoConstraints = false
            let ts = UIStackView(arrangedSubviews: [nameLbl, sessLbl])
            ts.axis = .vertical; ts.spacing = 2; ts.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(circle); row.addSubview(ts)
            NSLayoutConstraint.activate([
                circle.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                circle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                ts.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 12),
                ts.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                row.heightAnchor.constraint(equalToConstant: 50),
                row.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: i == 0 ? 12 : 0),
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
            lastView = row
        }
        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            lastView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func mindfulnessMotivation(for id: String, isLocked: Bool) -> String {
        if isLocked {
            switch id {
            case "mind_double": return "✦ Complete 2 sessions today to earn this."
            case "mind_triple": return "✦ Three sessions in one day. You can do this."
            case "mind_4":      return "✦ Four sessions. A day of deep presence awaits."
            case "mind_deep":   return "✦ Five sessions. The deepest reset of all."
            default:            return "✦ Keep practicing to unlock this."
            }
        } else {
            switch id {
            case "mind_double": return "✦ You returned to stillness twice. That is devotion."
            case "mind_triple": return "✦ Three times today. You are building something real."
            case "mind_4":      return "✦ Four sessions. You are living mindfulness."
            case "mind_deep":   return "✦ Five sessions. You dove to the deepest level."
            default:            return "✦ Your practice speaks for itself."
            }
        }
    }

    // MARK: - IBAction
    @IBAction func dismissSelf(_ sender: Any) {
        dismiss(animated: true)
    }

    // MARK: - Butterfly Detail UI
    private func setupButterflyDetailUI() {
        guard let achievement = achievement else { return }

        scrollView.isHidden = true

        let tier = ButterflyDetailTier.tier(for: achievement.requiredValue)
        let isLocked = !achievement.isUnlocked

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(container)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.topAnchor.constraint(equalTo: scroll.topAnchor),
            container.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        let headerView = makeButterflyHeaderGradient(tier: tier, isLocked: isLocked)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerView)

        let badge = ButterflyDetailBadgeView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.configure(tier: tier, count: achievement.requiredValue,
                        iconName: achievement.iconName, isLocked: isLocked)
        container.addSubview(badge)

        let titleLbl = UILabel()
        titleLbl.text = achievement.title
        titleLbl.font = .systemFont(ofSize: 26, weight: .bold)
        titleLbl.textAlignment = .center
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLbl)

        let tierPill = makeButterflyTierPill(tier: tier, isLocked: isLocked)
        tierPill.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tierPill)

        let descCard = makeButterflyDescCard(achievement: achievement, tier: tier, isLocked: isLocked)
        descCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descCard)

        let statsRow = makeButterflyStatsRow(achievement: achievement, tier: tier)
        statsRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statsRow)

        let statusCard = makeButterflyStatusCard(achievement: achievement, tier: tier)
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusCard)

        let roadmapCard = makeButterflyRoadmapCard(currentAchievement: achievement)
        roadmapCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(roadmapCard)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),

            badge.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: headerView.bottomAnchor),
            badge.widthAnchor.constraint(equalToConstant: 160),
            badge.heightAnchor.constraint(equalToConstant: 180),

            titleLbl.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            tierPill.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 8),
            tierPill.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descCard.topAnchor.constraint(equalTo: tierPill.bottomAnchor, constant: 20),
            descCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            descCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statsRow.topAnchor.constraint(equalTo: descCard.bottomAnchor, constant: 16),
            statsRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statsRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statusCard.topAnchor.constraint(equalTo: statsRow.bottomAnchor, constant: 16),
            statusCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statusCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            roadmapCard.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 16),
            roadmapCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            roadmapCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            roadmapCard.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -32)
        ])

        badge.alpha = 0
        badge.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.55, delay: 0.1, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5) {
            badge.alpha = 1
            badge.transform = .identity
        }
    }

    private func makeButterflyHeaderGradient(tier: ButterflyDetailTier, isLocked: Bool) -> UIView {
        let v = UIView()
        v.clipsToBounds = true
        let grad = CAGradientLayer()
        grad.colors = isLocked
            ? [UIColor.systemGray5.cgColor, UIColor.systemGray4.cgColor]
            : tier.gradientColors
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 1)
        v.layer.insertSublayer(grad, at: 0)
        for (size, alpha, offset) in [(CGFloat(200), 0.12, CGPoint(x: -30, y: -50)),
                                       (CGFloat(130), 0.10, CGPoint(x: 270, y: 30))] {
            let circle = UIView()
            circle.backgroundColor = UIColor.white.withAlphaComponent(alpha)
            circle.layer.cornerRadius = size / 2
            circle.frame = CGRect(x: offset.x, y: offset.y, width: size, height: size)
            v.addSubview(circle)
        }
        v.layoutIfNeeded()
        grad.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        return v
    }

    private func makeButterflyTierPill(tier: ButterflyDetailTier, isLocked: Bool) -> UIView {
        let pill = UIView()
        pill.layer.cornerRadius = 12
        pill.clipsToBounds = true
        let grad = CAGradientLayer()
        grad.colors = isLocked
            ? [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            : tier.gradientColors
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 0)
        grad.cornerRadius = 12
        pill.layer.insertSublayer(grad, at: 0)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(stack)

        for _ in 0..<tier.starCount {
            let iv = UIImageView(image: UIImage(systemName: "star.fill"))
            iv.tintColor = .white
            iv.widthAnchor.constraint(equalToConstant: 12).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 12).isActive = true
            stack.addArrangedSubview(iv)
        }
        let lbl = UILabel()
        lbl.text = tier.label
        lbl.font = .systemFont(ofSize: 12, weight: .heavy)
        lbl.textColor = .white
        stack.addArrangedSubview(lbl)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -7),
            stack.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -14)
        ])
        pill.layoutIfNeeded()
        grad.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        return pill
    }

    private func makeButterflyDescCard(achievement: Achievement, tier: ButterflyDetailTier, isLocked: Bool) -> UIView {
        let card = makeCard()
        let quoteIcon = UIImageView(image: UIImage(systemName: "quote.opening"))
        quoteIcon.tintColor = isLocked ? .systemGray3 : tier.ringColor
        quoteIcon.contentMode = .scaleAspectFit
        quoteIcon.translatesAutoresizingMaskIntoConstraints = false
        quoteIcon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        quoteIcon.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let desc = UILabel()
        desc.text = achievement.description
        desc.font = .systemFont(ofSize: 16, weight: .regular)
        desc.textColor = .label
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.translatesAutoresizingMaskIntoConstraints = false

        let motiveLine = UILabel()
        motiveLine.text = butterflyMotivation(for: achievement.id, isLocked: isLocked)
        motiveLine.font = .systemFont(ofSize: 13, weight: .medium)
        motiveLine.textColor = isLocked ? .systemGray3 : tier.ringColor
        motiveLine.numberOfLines = 0
        motiveLine.textAlignment = .center
        motiveLine.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(quoteIcon)
        card.addSubview(desc)
        card.addSubview(motiveLine)

        NSLayoutConstraint.activate([
            quoteIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            quoteIcon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            desc.topAnchor.constraint(equalTo: quoteIcon.bottomAnchor, constant: 10),
            desc.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            desc.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            motiveLine.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 12),
            motiveLine.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            motiveLine.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            motiveLine.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeButterflyStatsRow(achievement: Achievement, tier: ButterflyDetailTier) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12

        let items: [(String, String, String)] = [
            ("ladybug.fill",  "\(achievement.requiredValue)", "Butterflies"),
            ("star.fill",     "\(tier.starCount)",            "Stars"),
            ("shield.fill",   tier.label,                     "Tier")
        ]

        for (icon, value, subtitle) in items {
            let card = makeCard()
            card.layer.cornerRadius = 14
            let iv = UIImageView(image: UIImage(systemName: icon))
            iv.tintColor = achievement.isUnlocked ? tier.ringColor : .systemGray3
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 22).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 22).isActive = true

            let valLbl = UILabel()
            valLbl.text = value
            valLbl.font = .systemFont(ofSize: 18, weight: .bold)
            valLbl.textColor = .label
            valLbl.textAlignment = .center
            valLbl.translatesAutoresizingMaskIntoConstraints = false

            let subLbl = UILabel()
            subLbl.text = subtitle
            subLbl.font = .systemFont(ofSize: 11, weight: .medium)
            subLbl.textColor = .secondaryLabel
            subLbl.textAlignment = .center
            subLbl.translatesAutoresizingMaskIntoConstraints = false

            let vStack = UIStackView(arrangedSubviews: [iv, valLbl, subLbl])
            vStack.axis = .vertical
            vStack.alignment = .center
            vStack.spacing = 4
            vStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8)
            ])
            stack.addArrangedSubview(card)
        }
        return stack
    }

    private func makeButterflyStatusCard(achievement: Achievement, tier: ButterflyDetailTier) -> UIView {
        let card = makeCard()
        if achievement.isUnlocked {
            let checkIV = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
            checkIV.tintColor = tier.ringColor
            checkIV.contentMode = .scaleAspectFit
            checkIV.translatesAutoresizingMaskIntoConstraints = false
            checkIV.widthAnchor.constraint(equalToConstant: 36).isActive = true
            checkIV.heightAnchor.constraint(equalToConstant: 36).isActive = true

            let unlockedLbl = UILabel()
            unlockedLbl.text = "Achievement Unlocked!"
            unlockedLbl.font = .systemFont(ofSize: 17, weight: .bold)
            unlockedLbl.textColor = tier.ringColor
            unlockedLbl.textAlignment = .center
            unlockedLbl.translatesAutoresizingMaskIntoConstraints = false

            var dateText = ""
            if let date = achievement.dateUnlocked {
                let fmt = DateFormatter(); fmt.dateStyle = .long
                dateText = "Earned on \(fmt.string(from: date))"
            }
            let dateLbl = UILabel()
            dateLbl.text = dateText
            dateLbl.font = .systemFont(ofSize: 13)
            dateLbl.textColor = .secondaryLabel
            dateLbl.textAlignment = .center
            dateLbl.translatesAutoresizingMaskIntoConstraints = false

            let vStack = UIStackView(arrangedSubviews: [checkIV, unlockedLbl, dateLbl])
            vStack.axis = .vertical; vStack.alignment = .center; vStack.spacing = 6
            vStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
        } else {
            let headerLbl = UILabel()
            headerLbl.text = "Your Progress"
            headerLbl.font = .systemFont(ofSize: 14, weight: .semibold)
            headerLbl.textColor = .secondaryLabel
            headerLbl.translatesAutoresizingMaskIntoConstraints = false

            let progressBar = UIProgressView(progressViewStyle: .default)
            progressBar.progress = achievement.progress
            progressBar.progressTintColor = tier.ringColor
            progressBar.trackTintColor = .systemGray5
            progressBar.layer.cornerRadius = 4
            progressBar.clipsToBounds = true
            progressBar.translatesAutoresizingMaskIntoConstraints = false

            let percLbl = UILabel()
            let perc = Int(achievement.progress * 100)
            percLbl.text = "\(achievement.currentValue) / \(achievement.requiredValue) butterflies  (\(perc)%)"
            percLbl.font = .systemFont(ofSize: 13, weight: .medium)
            percLbl.textColor = tier.ringColor
            percLbl.textAlignment = .center
            percLbl.translatesAutoresizingMaskIntoConstraints = false

            let goalLbl = UILabel()
            goalLbl.text = "Collect \(achievement.requiredValue - achievement.currentValue) more butterflies to unlock!"
            goalLbl.font = .systemFont(ofSize: 12)
            goalLbl.textColor = .secondaryLabel
            goalLbl.textAlignment = .center
            goalLbl.numberOfLines = 0
            goalLbl.translatesAutoresizingMaskIntoConstraints = false

            card.addSubview(headerLbl)
            card.addSubview(progressBar)
            card.addSubview(percLbl)
            card.addSubview(goalLbl)
            NSLayoutConstraint.activate([
                headerLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                headerLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                progressBar.topAnchor.constraint(equalTo: headerLbl.bottomAnchor, constant: 12),
                progressBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
                progressBar.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
                progressBar.heightAnchor.constraint(equalToConstant: 8),
                percLbl.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 10),
                percLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                goalLbl.topAnchor.constraint(equalTo: percLbl.bottomAnchor, constant: 6),
                goalLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                goalLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                goalLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
            ])
        }
        return card
    }

    private func makeButterflyRoadmapCard(currentAchievement: Achievement) -> UIView {
        let card = makeCard()
        let titleLbl = UILabel()
        titleLbl.text = "Butterfly Roadmap"
        titleLbl.font = .systemFont(ofSize: 15, weight: .bold)
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLbl)

        let milestones: [(String, Int, ButterflyDetailTier, String)] = [
            ("Flutter",         5,  .bronze,   "ladybug"),
            ("Swarm of Grace",  15, .silver,   "ladybug.fill"),
            ("Butterfly Garden",30, .gold,     "sparkles"),
            ("Monarch of Calm", 60, .platinum, "crown.fill")
        ]

        var lastView: UIView = titleLbl
        for (i, (name, count, tier, icon)) in milestones.enumerated() {
            let isCurrentOrPast = count <= currentAchievement.requiredValue
            let isCurrent = count == currentAchievement.requiredValue

            if i > 0 {
                let line = UIView()
                line.backgroundColor = isCurrentOrPast ? tier.ringColor.withAlphaComponent(0.4) : .systemGray5
                line.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(line)
                NSLayoutConstraint.activate([
                    line.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 35),
                    line.widthAnchor.constraint(equalToConstant: 2),
                    line.topAnchor.constraint(equalTo: lastView.bottomAnchor),
                    line.heightAnchor.constraint(equalToConstant: 12)
                ])
                lastView = line
            }

            let circle = UIView()
            circle.layer.cornerRadius = 18
            circle.translatesAutoresizingMaskIntoConstraints = false
            circle.widthAnchor.constraint(equalToConstant: 36).isActive = true
            circle.heightAnchor.constraint(equalToConstant: 36).isActive = true

            if isCurrentOrPast {
                let grad = CAGradientLayer()
                grad.colors = tier.gradientColors
                grad.startPoint = CGPoint(x: 0, y: 0)
                grad.endPoint   = CGPoint(x: 1, y: 1)
                grad.cornerRadius = 18
                grad.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
                circle.layer.insertSublayer(grad, at: 0)
            } else {
                circle.backgroundColor = .systemGray5
            }
            if isCurrent {
                circle.layer.borderWidth = 2.5
                circle.layer.borderColor = tier.ringColor.cgColor
            }

            let iconIV = UIImageView(image: UIImage(systemName: isCurrentOrPast ? icon : "lock.fill"))
            iconIV.tintColor = isCurrentOrPast ? .white : .systemGray3
            iconIV.contentMode = .scaleAspectFit
            iconIV.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(iconIV)
            NSLayoutConstraint.activate([
                iconIV.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
                iconIV.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
                iconIV.widthAnchor.constraint(equalToConstant: 16),
                iconIV.heightAnchor.constraint(equalToConstant: 16)
            ])

            let nameLbl = UILabel()
            nameLbl.text = name
            nameLbl.font = isCurrent ? .systemFont(ofSize: 14, weight: .bold) : .systemFont(ofSize: 14, weight: .medium)
            nameLbl.textColor = isCurrentOrPast ? .label : .secondaryLabel
            nameLbl.translatesAutoresizingMaskIntoConstraints = false

            let countLbl = UILabel()
            countLbl.text = "\(count) butterflies"
            countLbl.font = .systemFont(ofSize: 12)
            countLbl.textColor = isCurrentOrPast ? tier.ringColor : .tertiaryLabel
            countLbl.translatesAutoresizingMaskIntoConstraints = false

            let tierLbl = UILabel()
            tierLbl.text = tier.label
            tierLbl.font = .systemFont(ofSize: 10, weight: .heavy)
            tierLbl.textColor = isCurrentOrPast ? tier.ringColor : .systemGray3
            tierLbl.translatesAutoresizingMaskIntoConstraints = false

            let textStack = UIStackView(arrangedSubviews: [nameLbl, countLbl])
            textStack.axis = .vertical; textStack.spacing = 2
            textStack.translatesAutoresizingMaskIntoConstraints = false

            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(circle)
            row.addSubview(textStack)
            row.addSubview(tierLbl)
            card.addSubview(row)

            NSLayoutConstraint.activate([
                circle.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                circle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                textStack.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 12),
                textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                tierLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                tierLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                row.heightAnchor.constraint(equalToConstant: 52),
                row.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: i == 0 ? 12 : 0),
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
            lastView = row
        }

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            lastView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func butterflyMotivation(for id: String, isLocked: Bool) -> String {
        if isLocked {
            switch id {
            case "butterfly_5":  return "✦ Collect 5 butterflies to begin your garden."
            case "butterfly_15": return "✦ 15 butterflies — a swarm of grace awaits you."
            case "butterfly_30": return "✦ 30 butterflies — your sanctuary is almost complete."
            case "butterfly_60": return "✦ 60 butterflies — become the Monarch of Calm."
            default:             return "✦ Keep collecting to unlock this."
            }
        } else {
            switch id {
            case "butterfly_5":  return "✦ Your garden has come alive with wings and wonder."
            case "butterfly_15": return "✦ They gather around you — a testament to your patience."
            case "butterfly_30": return "✦ Your inner world is a sanctuary of beauty."
            case "butterfly_60": return "✦ You are the Monarch — rare, extraordinary, free."
            default:             return "✦ Your butterfly collection speaks for itself."
            }
        }
    }

    // MARK: - Sessions Detail UI
    private func setupSessionsDetailUI() {
        guard let achievement = achievement else { return }

        scrollView.isHidden = true

        let tier = SessionsTier.tier(for: achievement.requiredValue)
        let isLocked = !achievement.isUnlocked

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(container)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.topAnchor.constraint(equalTo: scroll.topAnchor),
            container.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        let headerView = makeSessionsHeaderGradient(tier: tier, isLocked: isLocked)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerView)

        let badge = SessionsBadgeView()
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.configure(tier: tier, sessions: achievement.requiredValue,
                        iconName: achievement.iconName, isLocked: isLocked)
        container.addSubview(badge)

        let titleLbl = UILabel()
        titleLbl.text = achievement.title
        titleLbl.font = .systemFont(ofSize: 26, weight: .bold)
        titleLbl.textAlignment = .center
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLbl)

        let tierPill = makeSessionsTierPill(tier: tier, isLocked: isLocked)
        tierPill.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tierPill)

        let descCard = makeSessionsDescCard(achievement: achievement, tier: tier, isLocked: isLocked)
        descCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descCard)

        let statsRow = makeSessionsStatsRow(achievement: achievement, tier: tier)
        statsRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statsRow)

        let statusCard = makeSessionsStatusCard(achievement: achievement, tier: tier)
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusCard)

        let roadmapCard = makeSessionsRoadmapCard(currentAchievement: achievement)
        roadmapCard.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(roadmapCard)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),

            badge.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: headerView.bottomAnchor),
            badge.widthAnchor.constraint(equalToConstant: 160),
            badge.heightAnchor.constraint(equalToConstant: 160),

            titleLbl.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLbl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            tierPill.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 8),
            tierPill.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descCard.topAnchor.constraint(equalTo: tierPill.bottomAnchor, constant: 20),
            descCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            descCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statsRow.topAnchor.constraint(equalTo: descCard.bottomAnchor, constant: 16),
            statsRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statsRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            statusCard.topAnchor.constraint(equalTo: statsRow.bottomAnchor, constant: 16),
            statusCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            statusCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            roadmapCard.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 16),
            roadmapCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            roadmapCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            roadmapCard.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -32)
        ])

        badge.alpha = 0
        badge.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.55, delay: 0.1, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5) {
            badge.alpha = 1
            badge.transform = .identity
        }
    }

    private func makeSessionsHeaderGradient(tier: SessionsTier, isLocked: Bool) -> UIView {
        let v = UIView()
        v.clipsToBounds = true
        let grad = CAGradientLayer()
        grad.colors = isLocked
            ? [UIColor.systemGray5.cgColor, UIColor.systemGray4.cgColor]
            : tier.gradientColors
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 1)
        v.layer.insertSublayer(grad, at: 0)
        for (size, alpha, offset) in [(CGFloat(200), 0.12, CGPoint(x: -30, y: -50)),
                                       (CGFloat(130), 0.10, CGPoint(x: 270, y: 30))] {
            let circle = UIView()
            circle.backgroundColor = UIColor.white.withAlphaComponent(alpha)
            circle.layer.cornerRadius = size / 2
            circle.frame = CGRect(x: offset.x, y: offset.y, width: size, height: size)
            v.addSubview(circle)
        }
        v.layoutIfNeeded()
        grad.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        return v
    }

    private func makeSessionsTierPill(tier: SessionsTier, isLocked: Bool) -> UIView {
        let pill = UIView()
        pill.layer.cornerRadius = 12
        pill.clipsToBounds = true
        let grad = CAGradientLayer()
        grad.colors = isLocked
            ? [UIColor.systemGray4.cgColor, UIColor.systemGray3.cgColor]
            : tier.gradientColors
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 0)
        grad.cornerRadius = 12
        pill.layer.insertSublayer(grad, at: 0)

        let stack = UIStackView()
        stack.axis = .horizontal; stack.spacing = 6; stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(stack)

        for _ in 0..<tier.starCount {
            let iv = UIImageView(image: UIImage(systemName: "star.fill"))
            iv.tintColor = .white
            iv.widthAnchor.constraint(equalToConstant: 12).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 12).isActive = true
            stack.addArrangedSubview(iv)
        }
        let lbl = UILabel()
        lbl.text = tier.label
        lbl.font = .systemFont(ofSize: 12, weight: .heavy)
        lbl.textColor = .white
        stack.addArrangedSubview(lbl)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: pill.topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -7),
            stack.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -14)
        ])
        pill.layoutIfNeeded()
        grad.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        return pill
    }

    private func makeSessionsDescCard(achievement: Achievement, tier: SessionsTier, isLocked: Bool) -> UIView {
        let card = makeCard()
        let quoteIcon = UIImageView(image: UIImage(systemName: "quote.opening"))
        quoteIcon.tintColor = isLocked ? .systemGray3 : tier.ringColor
        quoteIcon.contentMode = .scaleAspectFit
        quoteIcon.translatesAutoresizingMaskIntoConstraints = false
        quoteIcon.widthAnchor.constraint(equalToConstant: 24).isActive = true
        quoteIcon.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let desc = UILabel()
        desc.text = achievement.description
        desc.font = .systemFont(ofSize: 16, weight: .regular)
        desc.textColor = .label
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.translatesAutoresizingMaskIntoConstraints = false

        let motiveLine = UILabel()
        motiveLine.text = sessionsMotivation(for: achievement.id, isLocked: isLocked)
        motiveLine.font = .systemFont(ofSize: 13, weight: .medium)
        motiveLine.textColor = isLocked ? .systemGray3 : tier.ringColor
        motiveLine.numberOfLines = 0
        motiveLine.textAlignment = .center
        motiveLine.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(quoteIcon)
        card.addSubview(desc)
        card.addSubview(motiveLine)
        NSLayoutConstraint.activate([
            quoteIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            quoteIcon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            desc.topAnchor.constraint(equalTo: quoteIcon.bottomAnchor, constant: 10),
            desc.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            desc.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            motiveLine.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 12),
            motiveLine.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            motiveLine.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            motiveLine.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeSessionsStatsRow(achievement: Achievement, tier: SessionsTier) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal; stack.distribution = .fillEqually; stack.spacing = 12

        let items: [(String, String, String)] = [
            ("figure.mind.and.body", "\(achievement.requiredValue)", "Sessions"),
            ("star.fill",            "\(tier.starCount)",            "Stars"),
            ("shield.fill",          tier.label,                     "Tier")
        ]

        for (icon, value, subtitle) in items {
            let card = makeCard()
            card.layer.cornerRadius = 14
            let iv = UIImageView(image: UIImage(systemName: icon))
            iv.tintColor = achievement.isUnlocked ? tier.ringColor : .systemGray3
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: 22).isActive = true
            iv.heightAnchor.constraint(equalToConstant: 22).isActive = true

            let valLbl = UILabel()
            valLbl.text = value
            valLbl.font = .systemFont(ofSize: 18, weight: .bold)
            valLbl.textColor = .label; valLbl.textAlignment = .center
            valLbl.translatesAutoresizingMaskIntoConstraints = false

            let subLbl = UILabel()
            subLbl.text = subtitle
            subLbl.font = .systemFont(ofSize: 11, weight: .medium)
            subLbl.textColor = .secondaryLabel; subLbl.textAlignment = .center
            subLbl.translatesAutoresizingMaskIntoConstraints = false

            let vStack = UIStackView(arrangedSubviews: [iv, valLbl, subLbl])
            vStack.axis = .vertical; vStack.alignment = .center; vStack.spacing = 4
            vStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8)
            ])
            stack.addArrangedSubview(card)
        }
        return stack
    }

    private func makeSessionsStatusCard(achievement: Achievement, tier: SessionsTier) -> UIView {
        let card = makeCard()
        if achievement.isUnlocked {
            let checkIV = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
            checkIV.tintColor = tier.ringColor; checkIV.contentMode = .scaleAspectFit
            checkIV.translatesAutoresizingMaskIntoConstraints = false
            checkIV.widthAnchor.constraint(equalToConstant: 36).isActive = true
            checkIV.heightAnchor.constraint(equalToConstant: 36).isActive = true

            let unlockedLbl = UILabel()
            unlockedLbl.text = "Achievement Unlocked!"
            unlockedLbl.font = .systemFont(ofSize: 17, weight: .bold)
            unlockedLbl.textColor = tier.ringColor; unlockedLbl.textAlignment = .center
            unlockedLbl.translatesAutoresizingMaskIntoConstraints = false

            var dateText = ""
            if let date = achievement.dateUnlocked {
                let fmt = DateFormatter(); fmt.dateStyle = .long
                dateText = "Earned on \(fmt.string(from: date))"
            }
            let dateLbl = UILabel()
            dateLbl.text = dateText; dateLbl.font = .systemFont(ofSize: 13)
            dateLbl.textColor = .secondaryLabel; dateLbl.textAlignment = .center
            dateLbl.translatesAutoresizingMaskIntoConstraints = false

            let vStack = UIStackView(arrangedSubviews: [checkIV, unlockedLbl, dateLbl])
            vStack.axis = .vertical; vStack.alignment = .center; vStack.spacing = 6
            vStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(vStack)
            NSLayoutConstraint.activate([
                vStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
                vStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
                vStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                vStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
        } else {
            let headerLbl = UILabel()
            headerLbl.text = "Your Progress"
            headerLbl.font = .systemFont(ofSize: 14, weight: .semibold)
            headerLbl.textColor = .secondaryLabel
            headerLbl.translatesAutoresizingMaskIntoConstraints = false

            let progressBar = UIProgressView(progressViewStyle: .default)
            progressBar.progress = achievement.progress
            progressBar.progressTintColor = tier.ringColor
            progressBar.trackTintColor = .systemGray5
            progressBar.layer.cornerRadius = 4; progressBar.clipsToBounds = true
            progressBar.translatesAutoresizingMaskIntoConstraints = false

            let percLbl = UILabel()
            let perc = Int(achievement.progress * 100)
            percLbl.text = "\(achievement.currentValue) / \(achievement.requiredValue) sessions  (\(perc)%)"
            percLbl.font = .systemFont(ofSize: 13, weight: .medium)
            percLbl.textColor = tier.ringColor; percLbl.textAlignment = .center
            percLbl.translatesAutoresizingMaskIntoConstraints = false

            let goalLbl = UILabel()
            goalLbl.text = "Complete \(achievement.requiredValue - achievement.currentValue) more sessions to unlock!"
            goalLbl.font = .systemFont(ofSize: 12)
            goalLbl.textColor = .secondaryLabel; goalLbl.textAlignment = .center
            goalLbl.numberOfLines = 0
            goalLbl.translatesAutoresizingMaskIntoConstraints = false

            card.addSubview(headerLbl); card.addSubview(progressBar)
            card.addSubview(percLbl); card.addSubview(goalLbl)
            NSLayoutConstraint.activate([
                headerLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                headerLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                progressBar.topAnchor.constraint(equalTo: headerLbl.bottomAnchor, constant: 12),
                progressBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
                progressBar.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
                progressBar.heightAnchor.constraint(equalToConstant: 8),
                percLbl.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 10),
                percLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                goalLbl.topAnchor.constraint(equalTo: percLbl.bottomAnchor, constant: 6),
                goalLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                goalLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                goalLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
            ])
        }
        return card
    }

    private func makeSessionsRoadmapCard(currentAchievement: Achievement) -> UIView {
        let card = makeCard()
        let titleLbl = UILabel()
        titleLbl.text = "Sessions Roadmap"
        titleLbl.font = .systemFont(ofSize: 15, weight: .bold)
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLbl)

        let milestones: [(String, Int, SessionsTier, String)] = [
            ("First Steps",      10, .bronze,   "figure.mind.and.body"),
            ("Steady Rhythm",    20, .silver,   "waveform.path.ecg"),
            ("Deep Commitment",  40, .gold,     "brain.head.profile"),
            ("Mindful Master",   80, .platinum, "sparkles")
        ]

        var lastView: UIView = titleLbl
        for (i, (name, count, tier, icon)) in milestones.enumerated() {
            let isCurrentOrPast = count <= currentAchievement.requiredValue
            let isCurrent = count == currentAchievement.requiredValue

            if i > 0 {
                let line = UIView()
                line.backgroundColor = isCurrentOrPast ? tier.ringColor.withAlphaComponent(0.4) : .systemGray5
                line.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(line)
                NSLayoutConstraint.activate([
                    line.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 35),
                    line.widthAnchor.constraint(equalToConstant: 2),
                    line.topAnchor.constraint(equalTo: lastView.bottomAnchor),
                    line.heightAnchor.constraint(equalToConstant: 12)
                ])
                lastView = line
            }

            let circle = UIView()
            circle.layer.cornerRadius = 18
            circle.translatesAutoresizingMaskIntoConstraints = false
            circle.widthAnchor.constraint(equalToConstant: 36).isActive = true
            circle.heightAnchor.constraint(equalToConstant: 36).isActive = true

            if isCurrentOrPast {
                let grad = CAGradientLayer()
                grad.colors = tier.gradientColors
                grad.startPoint = CGPoint(x: 0, y: 0); grad.endPoint = CGPoint(x: 1, y: 1)
                grad.cornerRadius = 18; grad.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
                circle.layer.insertSublayer(grad, at: 0)
            } else {
                circle.backgroundColor = .systemGray5
            }
            if isCurrent {
                circle.layer.borderWidth = 2.5
                circle.layer.borderColor = tier.ringColor.cgColor
            }

            let iconIV = UIImageView(image: UIImage(systemName: isCurrentOrPast ? icon : "lock.fill"))
            iconIV.tintColor = isCurrentOrPast ? .white : .systemGray3
            iconIV.contentMode = .scaleAspectFit
            iconIV.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(iconIV)
            NSLayoutConstraint.activate([
                iconIV.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
                iconIV.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
                iconIV.widthAnchor.constraint(equalToConstant: 16),
                iconIV.heightAnchor.constraint(equalToConstant: 16)
            ])

            let nameLbl = UILabel()
            nameLbl.text = name
            nameLbl.font = isCurrent ? .systemFont(ofSize: 14, weight: .bold) : .systemFont(ofSize: 14, weight: .medium)
            nameLbl.textColor = isCurrentOrPast ? .label : .secondaryLabel
            nameLbl.translatesAutoresizingMaskIntoConstraints = false

            let countLbl = UILabel()
            countLbl.text = "\(count) sessions"
            countLbl.font = .systemFont(ofSize: 12)
            countLbl.textColor = isCurrentOrPast ? tier.ringColor : .tertiaryLabel
            countLbl.translatesAutoresizingMaskIntoConstraints = false

            let tierLbl = UILabel()
            tierLbl.text = tier.label
            tierLbl.font = .systemFont(ofSize: 10, weight: .heavy)
            tierLbl.textColor = isCurrentOrPast ? tier.ringColor : .systemGray3
            tierLbl.translatesAutoresizingMaskIntoConstraints = false

            let textStack = UIStackView(arrangedSubviews: [nameLbl, countLbl])
            textStack.axis = .vertical; textStack.spacing = 2
            textStack.translatesAutoresizingMaskIntoConstraints = false

            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(circle); row.addSubview(textStack); row.addSubview(tierLbl)
            card.addSubview(row)

            NSLayoutConstraint.activate([
                circle.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                circle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                textStack.leadingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 12),
                textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                tierLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                tierLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                row.heightAnchor.constraint(equalToConstant: 52),
                row.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: i == 0 ? 12 : 0),
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
            ])
            lastView = row
        }

        NSLayoutConstraint.activate([
            titleLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            lastView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func sessionsMotivation(for id: String, isLocked: Bool) -> String {
        if isLocked {
            switch id {
            case "session_10": return "✦ Complete 10 sessions to take your first real steps."
            case "session_20": return "✦ 20 sessions — find your steady rhythm."
            case "session_40": return "✦ 40 sessions — make the promise to yourself."
            case "session_80": return "✦ 80 sessions — cross into mastery."
            default:           return "✦ Keep practicing to unlock this."
            }
        } else {
            switch id {
            case "session_10": return "✦ The journey has begun — and it is already changing you."
            case "session_20": return "✦ Your natural pace is forming — steady, consistent, deeply yours."
            case "session_40": return "✦ This is no longer a habit. It is a promise you keep."
            case "session_80": return "✦ You are not just practicing mindfulness — you are living it."
            default:           return "✦ Your dedication speaks for itself."
            }
        }
    }

    // MARK: - User Detail UI

    private func setupUserDetailUI() {
        guard let achievement = achievement else { return }

        view.backgroundColor = UIColor.systemBackground
        scrollView.isHidden = true

        // Full-screen scroll container
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        // Header gradient
        let header = makeUserHeaderGradient()
        content.addSubview(header)

        // Avatar badge
        let badge = makeUserAvatarBadge(achievement: achievement)
        content.addSubview(badge)

        // Welcome title
        let titleLbl = UILabel()
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        titleLbl.text = achievement.title
        titleLbl.font = .systemFont(ofSize: 26, weight: .bold)
        titleLbl.textAlignment = .center
        titleLbl.textColor = UIColor.label
        content.addSubview(titleLbl)

        let subtitleLbl = UILabel()
        subtitleLbl.translatesAutoresizingMaskIntoConstraints = false
        subtitleLbl.text = "Your journey starts here"
        subtitleLbl.font = .systemFont(ofSize: 14, weight: .medium)
        subtitleLbl.textAlignment = .center
        subtitleLbl.textColor = UIColor.secondaryLabel
        content.addSubview(subtitleLbl)

        // Description card
        let descCard = makeUserDescCard(achievement: achievement)
        content.addSubview(descCard)

        // Stats row
        let statsRow = makeUserStatsRow(achievement: achievement)
        content.addSubview(statsRow)

        // Quote card
        let quoteCard = makeUserQuoteCard()
        content.addSubview(quoteCard)

        // Layout
        let pad: CGFloat = 20
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: content.topAnchor),
            header.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 220),

            badge.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            badge.centerYAnchor.constraint(equalTo: header.bottomAnchor),
            badge.widthAnchor.constraint(equalToConstant: 110),
            badge.heightAnchor.constraint(equalToConstant: 110),

            titleLbl.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 14),
            titleLbl.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            titleLbl.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),

            subtitleLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 4),
            subtitleLbl.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            subtitleLbl.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),

            descCard.topAnchor.constraint(equalTo: subtitleLbl.bottomAnchor, constant: 20),
            descCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            descCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),

            statsRow.topAnchor.constraint(equalTo: descCard.bottomAnchor, constant: 14),
            statsRow.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            statsRow.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),
            statsRow.heightAnchor.constraint(equalToConstant: 80),

            quoteCard.topAnchor.constraint(equalTo: statsRow.bottomAnchor, constant: 14),
            quoteCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: pad),
            quoteCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -pad),
            quoteCard.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -40)
        ])
    }

    private func makeUserHeaderGradient() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = true

        let grad = CAGradientLayer()
        grad.colors = [
            UIColor(red: 0.18, green: 0.40, blue: 0.95, alpha: 1).cgColor,
            UIColor(red: 0.45, green: 0.25, blue: 0.90, alpha: 1).cgColor
        ]
        grad.startPoint = CGPoint(x: 0, y: 0)
        grad.endPoint   = CGPoint(x: 1, y: 1)
        v.layer.addSublayer(grad)

        v.layoutIfNeeded()
        DispatchQueue.main.async { grad.frame = v.bounds }
        return v
    }

    private func makeUserAvatarBadge(achievement: Achievement) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Glow ring
        let ring = UIView()
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.backgroundColor = UIColor(red: 0.30, green: 0.55, blue: 1.00, alpha: 0.3)
        ring.layer.cornerRadius = 55
        container.addSubview(ring)

        // White circle background
        let circle = UIView()
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.backgroundColor = .white
        circle.layer.cornerRadius = 50
        circle.layer.shadowColor  = UIColor(red: 0.30, green: 0.55, blue: 1.00, alpha: 1).cgColor
        circle.layer.shadowRadius = 16
        circle.layer.shadowOpacity = 0.5
        circle.layer.shadowOffset  = .zero
        container.addSubview(circle)

        // Icon
        let icon = UIImageView(image: UIImage(systemName: "person.circle.fill"))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.tintColor = UIColor(red: 0.30, green: 0.55, blue: 1.00, alpha: 1)
        container.addSubview(icon)

        // Unlocked checkmark
        let check = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
        check.translatesAutoresizingMaskIntoConstraints = false
        check.contentMode = .scaleAspectFit
        check.tintColor = UIColor(red: 0.18, green: 0.75, blue: 0.45, alpha: 1)
        container.addSubview(check)

        NSLayoutConstraint.activate([
            ring.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            ring.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ring.widthAnchor.constraint(equalToConstant: 110),
            ring.heightAnchor.constraint(equalToConstant: 110),

            circle.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: 100),
            circle.heightAnchor.constraint(equalToConstant: 100),

            icon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 64),
            icon.heightAnchor.constraint(equalToConstant: 64),

            check.trailingAnchor.constraint(equalTo: circle.trailingAnchor, constant: 2),
            check.bottomAnchor.constraint(equalTo: circle.bottomAnchor, constant: 2),
            check.widthAnchor.constraint(equalToConstant: 26),
            check.heightAnchor.constraint(equalToConstant: 26)
        ])
        return container
    }

    private func makeUserDescCard(achievement: Achievement) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor.secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.cornerCurve  = .continuous

        // Accent bar
        let bar = UIView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = UIColor(red: 0.30, green: 0.55, blue: 1.00, alpha: 1)
        bar.layer.cornerRadius = 2
        card.addSubview(bar)

        let descLbl = UILabel()
        descLbl.translatesAutoresizingMaskIntoConstraints = false
        descLbl.text = achievement.description
        descLbl.font = .systemFont(ofSize: 15, weight: .regular)
        descLbl.textColor = UIColor.label
        descLbl.numberOfLines = 0
        card.addSubview(descLbl)

        let unlockedLbl = UILabel()
        unlockedLbl.translatesAutoresizingMaskIntoConstraints = false
        if let date = achievement.dateUnlocked {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            unlockedLbl.text = "✓ Unlocked on \(fmt.string(from: date))"
        } else {
            unlockedLbl.text = "✓ Unlocked"
        }
        unlockedLbl.font = .systemFont(ofSize: 12, weight: .semibold)
        unlockedLbl.textColor = UIColor(red: 0.18, green: 0.75, blue: 0.45, alpha: 1)
        card.addSubview(unlockedLbl)

        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            bar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            bar.widthAnchor.constraint(equalToConstant: 4),
            bar.bottomAnchor.constraint(equalTo: unlockedLbl.bottomAnchor),

            descLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            descLbl.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: 12),
            descLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            unlockedLbl.topAnchor.constraint(equalTo: descLbl.bottomAnchor, constant: 10),
            unlockedLbl.leadingAnchor.constraint(equalTo: bar.trailingAnchor, constant: 12),
            unlockedLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            unlockedLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }

    private func makeUserStatsRow(achievement: Achievement) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        func makeStat(icon: String, value: String, label: String, color: UIColor) -> UIView {
            let card = UIView()
            card.translatesAutoresizingMaskIntoConstraints = false
            card.backgroundColor = UIColor.secondarySystemBackground
            card.layer.cornerRadius = 14
            card.layer.cornerCurve  = .continuous

            let iv = UIImageView(image: UIImage(systemName: icon))
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.contentMode = .scaleAspectFit
            iv.tintColor = color

            let valLbl = UILabel()
            valLbl.translatesAutoresizingMaskIntoConstraints = false
            valLbl.text = value
            valLbl.font = .systemFont(ofSize: 18, weight: .bold)
            valLbl.textColor = UIColor.label
            valLbl.textAlignment = .center

            let lbl = UILabel()
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.text = label
            lbl.font = .systemFont(ofSize: 10, weight: .medium)
            lbl.textColor = UIColor.secondaryLabel
            lbl.textAlignment = .center

            card.addSubview(iv)
            card.addSubview(valLbl)
            card.addSubview(lbl)

            NSLayoutConstraint.activate([
                iv.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
                iv.centerXAnchor.constraint(equalTo: card.centerXAnchor),
                iv.widthAnchor.constraint(equalToConstant: 20),
                iv.heightAnchor.constraint(equalToConstant: 20),
                valLbl.topAnchor.constraint(equalTo: iv.bottomAnchor, constant: 4),
                valLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
                valLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
                lbl.topAnchor.constraint(equalTo: valLbl.bottomAnchor, constant: 2),
                lbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
                lbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
                lbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
            ])
            return card
        }

        let totalAch = AchievementManager.shared.achievements.count
        let unlocked = AchievementManager.shared.achievements.filter { $0.isUnlocked }.count

        let s1 = makeStat(icon: "trophy.fill",      value: "\(unlocked)",   label: "Unlocked",  color: UIColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1))
        let s2 = makeStat(icon: "list.star",         value: "\(totalAch)",   label: "Total",     color: UIColor(red: 0.30, green: 0.55, blue: 1.00, alpha: 1))
        let s3 = makeStat(icon: "checkmark.circle.fill", value: "✓",         label: "Member",    color: UIColor(red: 0.18, green: 0.75, blue: 0.45, alpha: 1))

        [s1, s2, s3].forEach { row.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = true }

        row.layoutIfNeeded()

        let stack = UIStackView(arrangedSubviews: [s1, s2, s3])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        row.addSubview(stack)
        [s1, s2, s3].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: row.topAnchor),
            stack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])
        return row
    }

    private func makeUserQuoteCard() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(red: 0.18, green: 0.40, blue: 0.95, alpha: 0.08)
        card.layer.cornerRadius = 16
        card.layer.cornerCurve  = .continuous
        card.layer.borderWidth  = 1
        card.layer.borderColor  = UIColor(red: 0.30, green: 0.55, blue: 1.00, alpha: 0.25).cgColor

        let quoteIcon = UIImageView(image: UIImage(systemName: "quote.opening"))
        quoteIcon.translatesAutoresizingMaskIntoConstraints = false
        quoteIcon.contentMode = .scaleAspectFit
        quoteIcon.tintColor = UIColor(red: 0.30, green: 0.55, blue: 1.00, alpha: 0.6)
        card.addSubview(quoteIcon)

        let quoteLbl = UILabel()
        quoteLbl.translatesAutoresizingMaskIntoConstraints = false
        quoteLbl.text = "The journey of a thousand miles begins with a single step. You have taken yours."
        quoteLbl.font = UIFont(name: "Georgia-Italic", size: 15) ?? .italicSystemFont(ofSize: 15)
        quoteLbl.textColor = UIColor.label
        quoteLbl.numberOfLines = 0
        quoteLbl.textAlignment = .center
        card.addSubview(quoteLbl)

        let authorLbl = UILabel()
        authorLbl.translatesAutoresizingMaskIntoConstraints = false
        authorLbl.text = "— Lao Tzu"
        authorLbl.font = .systemFont(ofSize: 12, weight: .medium)
        authorLbl.textColor = UIColor.secondaryLabel
        authorLbl.textAlignment = .center
        card.addSubview(authorLbl)

        NSLayoutConstraint.activate([
            quoteIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            quoteIcon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            quoteIcon.widthAnchor.constraint(equalToConstant: 28),
            quoteIcon.heightAnchor.constraint(equalToConstant: 28),

            quoteLbl.topAnchor.constraint(equalTo: quoteIcon.bottomAnchor, constant: 12),
            quoteLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            quoteLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),

            authorLbl.topAnchor.constraint(equalTo: quoteLbl.bottomAnchor, constant: 10),
            authorLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            authorLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            authorLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
        return card
    }
}
