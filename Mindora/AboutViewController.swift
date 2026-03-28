import UIKit

class AboutViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1)
        setupContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Actions
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.dismiss(animated: true)
    }

    // MARK: - Content Setup
    private func setupContent() {
        // Page Title
        let pageTitle = makeLabel("About", font: .systemFont(ofSize: 34, weight: .bold), color: .label)



        // Version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let versionLabel = makeLabel("Version \(version) (\(build))", font: .systemFont(ofSize: 17, weight: .regular), color: .secondaryLabel, alignment: .left)

        // Divider
        let divider1 = makeDivider()

        // Description card
        let descCard = makeCard()
        let descTitle = makeLabel("Our Mission", font: .systemFont(ofSize: 16, weight: .semibold), color: .label)
        let descText = makeLabel(
            "Mindora was created with a simple but profound belief: true growth happens in stillness. In a constantly moving world, we provide a peaceful sanctuary where you can pause, breathe, and reconnect with yourself.\n\nOur mission is to help you transform, step by step, much like a butterfly emerging from its cocoon. By nurturing your mindfulness through guided sessions, tracking your feelings, and watching your 3D AR Garden bloom, we empower you to build lifelong habits of calm, clarity, and inner peace.",
            font: .systemFont(ofSize: 15, weight: .regular), color: .secondaryLabel)
        descText.numberOfLines = 0
        let descStack = UIStackView(arrangedSubviews: [descTitle, descText])
        descStack.axis = .vertical
        descStack.spacing = 8
        descCard.addSubview(descStack)
        descStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            descStack.topAnchor.constraint(equalTo: descCard.topAnchor, constant: 16),
            descStack.leadingAnchor.constraint(equalTo: descCard.leadingAnchor, constant: 16),
            descStack.trailingAnchor.constraint(equalTo: descCard.trailingAnchor, constant: -16),
            descStack.bottomAnchor.constraint(equalTo: descCard.bottomAnchor, constant: -16)
        ])

        // Features card
        let featCard = makeCard()
        let featTitle = makeLabel("Features", font: .systemFont(ofSize: 16, weight: .semibold), color: .label)
        let features: [(String, String)] = [
            ("face.smiling.fill", "Daily Mood Tracking"),
            ("wind", "Guided Breathing Sessions"),
            ("leaf.fill", "Interactive 3D AR Garden"),
            ("trophy.fill", "Achievements & Growth Stages"),
            ("chart.bar.fill", "Analytics & Insights"),
            ("person.crop.circle.badge.plus", "Customisable Avatars"),
            ("cloud.fill", "Secure Cloud Sync")
        ]
        let featStack = UIStackView(arrangedSubviews: [featTitle])
        featStack.axis = .vertical
        featStack.spacing = 12
        for (icon, text) in features {
            let row = makeFeatureRow(icon: icon, text: text)
            featStack.addArrangedSubview(row)
        }
        featCard.addSubview(featStack)
        featStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            featStack.topAnchor.constraint(equalTo: featCard.topAnchor, constant: 16),
            featStack.leadingAnchor.constraint(equalTo: featCard.leadingAnchor, constant: 16),
            featStack.trailingAnchor.constraint(equalTo: featCard.trailingAnchor, constant: -16),
            featStack.bottomAnchor.constraint(equalTo: featCard.bottomAnchor, constant: -16)
        ])

        // Divider
        let divider2 = makeDivider()

        // Footer
        let footer = makeLabel("Made with ❤️ by the Mindora Team\nmindora.icodesquad@gmail.com",
                               font: .systemFont(ofSize: 13, weight: .regular),
                               color: .tertiaryLabel, alignment: .center)
        footer.numberOfLines = 0

        // Layout all in vertical stack
        let mainStack = UIStackView(arrangedSubviews: [
            pageTitle, versionLabel,
            divider1, descCard, featCard, divider2, footer
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.alignment = .fill
        mainStack.setCustomSpacing(4, after: pageTitle)
        mainStack.setCustomSpacing(24, after: versionLabel)
        mainStack.setCustomSpacing(24, after: divider1)
        mainStack.setCustomSpacing(24, after: featCard)
        mainStack.setCustomSpacing(24, after: divider2)




        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])

        // Fix cards to full width
        for card in [descCard, featCard] {
            card.translatesAutoresizingMaskIntoConstraints = false
            card.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true
        }
        for div in [divider1, divider2] {
            div.widthAnchor.constraint(equalTo: mainStack.widthAnchor).isActive = true
        }
    }

    // MARK: - Helpers
    private func makeLabel(_ text: String, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = font
        l.textColor = color
        l.textAlignment = alignment
        l.numberOfLines = 0
        return l
    }

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 14
        v.layer.cornerCurve = .continuous
        return v
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }

    private func makeFeatureRow(icon: String, text: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center

        let img = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        img.image = UIImage(systemName: icon, withConfiguration: config)
        img.tintColor = .systemGreen
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        img.widthAnchor.constraint(equalToConstant: 24).isActive = true
        img.heightAnchor.constraint(equalToConstant: 24).isActive = true

        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 15, weight: .regular)
        lbl.textColor = .secondaryLabel

        row.addArrangedSubview(img)
        row.addArrangedSubview(lbl)
        return row
    }
}
