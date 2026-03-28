import UIKit

// MARK: - Data model
private struct CalmingTechnique {
    let title: String
    let subtitle: String
    let badge: String       // short research tag
    let iconName: String    // SF Symbol
    let exerciseType: String
    let gradient: (UIColor, UIColor)
}

class AdvancedCalmingViewController: UIViewController {

    // MARK: - Data
    private let techniques: [CalmingTechnique] = [
        CalmingTechnique(
            title: "Physiological Sigh",
            subtitle: "Double inhale + long exhale — Stanford-backed stress reset",
            badge: "Stanford Research",
            iconName: "wind",
            exerciseType: "physiologicalSigh",
            // Mid sky blue
            gradient: (UIColor(red:0.35,green:0.58,blue:0.88,alpha:1),
                       UIColor(red:0.23,green:0.43,blue:0.75,alpha:1))
        ),
        CalmingTechnique(
            title: "Coherent Breathing",
            subtitle: "5 sec inhale · 5 sec exhale — improves heart-rate variability",
            badge: "HRV Research",
            iconName: "waveform.path.ecg",
            exerciseType: "coherentBreathing",
            // Mid teal green
            gradient: (UIColor(red:0.26,green:0.70,blue:0.59,alpha:1),
                       UIColor(red:0.17,green:0.53,blue:0.45,alpha:1))
        ),
        CalmingTechnique(
            title: "Progressive Muscle Release",
            subtitle: "Clench & release muscle groups — clinically proven PMR",
            badge: "Clinical PMR",
            iconName: "figure.strengthtraining.traditional",
            exerciseType: "progressiveMuscle",
            // Mid violet purple
            gradient: (UIColor(red:0.63,green:0.41,blue:0.90,alpha:1),
                       UIColor(red:0.47,green:0.28,blue:0.76,alpha:1))
        ),
        CalmingTechnique(
            title: "Body Scan Relaxation",
            subtitle: "Gently scan and release tension from head to toe",
            badge: "Mindfulness",
            iconName: "figure.mind.and.body",
            exerciseType: "grounding54321",
            // Mid warm orange
            gradient: (UIColor(red:0.91,green:0.56,blue:0.28,alpha:1),
                       UIColor(red:0.78,green:0.40,blue:0.19,alpha:1))
        ),
        CalmingTechnique(
            title: "Guided Imagery",
            subtitle: "Peaceful visualisation that boosts alpha brain waves",
            badge: "Alpha-Wave",
            iconName: "mountain.2",
            exerciseType: "guidedImagery",
            // Mid cerulean sky
            gradient: (UIColor(red:0.29,green:0.68,blue:0.85,alpha:1),
                       UIColor(red:0.19,green:0.51,blue:0.71,alpha:1))
        ),
        CalmingTechnique(
            title: "Box Breathing",
            subtitle: "4-4-4-4 breath cycle used by Navy SEALs",
            badge: "Navy SEALs",
            iconName: "square",
            exerciseType: "boxBreathing",
            // Mid cornflower indigo
            gradient: (UIColor(red:0.32,green:0.47,blue:0.83,alpha:1),
                       UIColor(red:0.21,green:0.34,blue:0.69,alpha:1))
        ),
        CalmingTechnique(
            title: "Heart-Focused Breathing",
            subtitle: "Breathe through your heart — HeartMath emotional reset",
            badge: "HeartMath",
            iconName: "heart.fill",
            exerciseType: "heartBreathing",
            // Mid rose pink
            gradient: (UIColor(red:0.88,green:0.33,blue:0.49,alpha:1),
                       UIColor(red:0.73,green:0.23,blue:0.38,alpha:1))
        ),
    ]

    // MARK: - UI
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private lazy var contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red:0.97,green:0.96,blue:0.93,alpha:1)
        title = "Advanced Calm"
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupLayout()
        buildCards()
    }

    override var hidesBottomBarWhenPushed: Bool {
        get { true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }

    // MARK: - Layout
    private func setupLayout() {
        // App Logo
        let logoImageView = UIImageView(image: UIImage(named: "Image"))
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit

        // Header
        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "Advanced Calm"
        headerLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        headerLabel.textColor = UIColor(red:0.08,green:0.08,blue:0.12,alpha:1)

        let subLabel = UILabel()
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.text = "7 science-backed techniques · tap to begin"
        subLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        subLabel.textColor = UIColor(red:0.02,green:0.71,blue:0.50,alpha:1)

        let headerStack = UIStackView(arrangedSubviews: [logoImageView, headerLabel, subLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 6
        headerStack.alignment = .center
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])

        contentStack.addArrangedSubview(headerStack)
    }

    // MARK: - Cards
    private func buildCards() {
        for (index, technique) in techniques.enumerated() {
            let card = makeTechniqueCard(technique, index: index)
            contentStack.addArrangedSubview(card)
        }
    }

    private func makeTechniqueCard(_ t: CalmingTechnique, index: Int) -> UIView {
        // Container
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.clipsToBounds = true
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 12
        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        // (accent bar removed)

        // Gradient icon box
        let iconBox = UIView()
        iconBox.translatesAutoresizingMaskIntoConstraints = false
        iconBox.layer.cornerRadius = 18
        iconBox.clipsToBounds = true

        let gradLayer = CAGradientLayer()
        gradLayer.colors = [t.gradient.0.cgColor, t.gradient.1.cgColor]
        gradLayer.startPoint = CGPoint(x: 0, y: 0)
        gradLayer.endPoint   = CGPoint(x: 1, y: 1)
        gradLayer.frame      = CGRect(x: 0, y: 0, width: 70, height: 70)
        iconBox.layer.addSublayer(gradLayer)

        let iconImgView = UIImageView()
        iconImgView.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium)
        iconImgView.image = UIImage(systemName: t.iconName, withConfiguration: cfg)
        iconImgView.tintColor = .white
        iconImgView.contentMode = .scaleAspectFit
        iconBox.addSubview(iconImgView)

        NSLayoutConstraint.activate([
            iconImgView.centerXAnchor.constraint(equalTo: iconBox.centerXAnchor),
            iconImgView.centerYAnchor.constraint(equalTo: iconBox.centerYAnchor),
            iconImgView.widthAnchor.constraint(equalToConstant: 28),
            iconImgView.heightAnchor.constraint(equalToConstant: 28),
        ])

        // Research badge — compact pill that fits the text snugly
        let badgePill = PaddedLabel()
        badgePill.translatesAutoresizingMaskIntoConstraints = false
        badgePill.text = t.badge
        badgePill.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        badgePill.textColor = t.gradient.0
        badgePill.backgroundColor = t.gradient.0.withAlphaComponent(0.12)
        badgePill.layer.cornerRadius = 6
        badgePill.clipsToBounds = true
        badgePill.textInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = t.title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = UIColor(red:0.08,green:0.08,blue:0.12,alpha:1)
        titleLabel.numberOfLines = 1

        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = t.subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = UIColor(red:0.45,green:0.45,blue:0.50,alpha:1)
        subtitleLabel.numberOfLines = 2

        // Text stack
        let textStack = UIStackView(arrangedSubviews: [badgePill, titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        // Chevron
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.tintColor = UIColor(red:0.75,green:0.75,blue:0.80,alpha:1)
        chevron.contentMode = .scaleAspectFit

        // Assemble into card
        card.addSubview(iconBox)
        card.addSubview(textStack)
        card.addSubview(chevron)

        NSLayoutConstraint.activate([
            iconBox.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconBox.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconBox.widthAnchor.constraint(equalToConstant: 70),
            iconBox.heightAnchor.constraint(equalToConstant: 70),
            iconBox.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 14),
            iconBox.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -14),

            textStack.leadingAnchor.constraint(equalTo: iconBox.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 20),
        ])

        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
        card.tag = index

        return card
    }

    // MARK: - Navigation
    @objc private func cardTapped(_ gr: UITapGestureRecognizer) {
        guard let card = gr.view else { return }
        let idx = card.tag
        guard idx < techniques.count else { return }

        // Guard: sessions require internet to sync progress with Supabase
        guard NetworkMonitor.shared.isConnected else {
            showNoInternetAlert()
            return
        }

        let t = techniques[idx]

        // Tap feedback
        UIView.animate(withDuration: 0.10, animations: {
            card.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { _ in
            UIView.animate(withDuration: 0.12) { card.transform = .identity }
        }

        let ex = AdvancedExercise(
            title: t.title,
            subtitle: t.subtitle,
            iconName: t.iconName,
            exerciseType: t.exerciseType,
            color1: t.gradient.0,
            color2: t.gradient.1
        )
        let vc = AdvancedExerciseViewController()
        vc.exercise = ex
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - PaddedLabel
// UILabel subclass that supports content insets for the badge pill
final class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width:  size.width  + textInsets.left + textInsets.right,
            height: size.height + textInsets.top  + textInsets.bottom
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let inner = CGSize(width: size.width  - textInsets.left - textInsets.right,
                           height: size.height - textInsets.top  - textInsets.bottom)
        let s = super.sizeThatFits(inner)
        return CGSize(width:  s.width  + textInsets.left + textInsets.right,
                      height: s.height + textInsets.top  + textInsets.bottom)
    }
}
