import UIKit

class PrivacyPolicyViewController: UIViewController {

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
        let sections: [(String, String)] = [
            ("Privacy Policy", "Last updated: February 2026\n\nYour privacy is important to us. This policy explains what information Mindora collects, how it is used, and your rights regarding your data."),
            ("1. Information We Collect", "Mindora collects only the information you provide directly:\n\n• Mood entries and scores you log\n• Breathing exercise session data\n• Achievement progress and points\n• Profile name and email (stored locally)\n\nWe do not collect device identifiers, location data, or any sensitive personal information beyond what you voluntarily enter."),
            ("2. How We Use Your Data", "Your data is used solely to:\n\n• Display your mood history and trends\n• Track your achievements and growth stages\n• Personalise your in-app experience\n• Generate your weekly mood insights\n\nWe do not use your data for advertising, profiling, or any commercial purpose."),
            ("3. Data Storage", "All data is stored locally on your device using secure on-device storage. We do not transmit your personal data to any external servers or third parties.\n\nIf you delete the app, all associated data is permanently removed from your device."),
            ("4. Third-Party Services", "Mindora does not integrate with any third-party analytics, advertising, or tracking services. Your data stays entirely on your device."),
            ("5. Children's Privacy", "Mindora is not directed at children under the age of 13. We do not knowingly collect personal information from children. If you believe a child has provided us with personal information, please contact us."),
            ("6. Your Rights", "You have the right to:\n\n• Access the data stored in the app at any time\n• Delete all your data by removing the app\n• Opt out of any future data collection features\n\nFor any privacy-related requests, contact us at privacy@mindora.app."),
            ("7. Changes to This Policy", "We may update this Privacy Policy from time to time. Any changes will be reflected in the app with an updated date. Continued use of the app after changes constitutes acceptance of the updated policy."),
            ("8. Contact Us", "If you have questions about this Privacy Policy, please contact:\n\nEmail: privacy@mindora.app\nWebsite: www.mindora.app")
        ]

        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 20

        for (index, (title, body)) in sections.enumerated() {
            if index == 0 {
                let titleLbl = makeLabel(title, font: .systemFont(ofSize: 28, weight: .bold), color: .label)
                let bodyLbl = makeLabel(body, font: .systemFont(ofSize: 14, weight: .regular), color: .secondaryLabel)
                mainStack.addArrangedSubview(titleLbl)
                mainStack.addArrangedSubview(bodyLbl)
                mainStack.setCustomSpacing(8, after: titleLbl)
                mainStack.setCustomSpacing(28, after: bodyLbl)
            } else {
                let card = makeSectionCard(title: title, body: body)
                mainStack.addArrangedSubview(card)
            }
        }

        contentView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }

    // MARK: - Helpers
    private func makeLabel(_ text: String, font: UIFont, color: UIColor) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = font
        l.textColor = color
        l.numberOfLines = 0
        return l
    }

    private func makeSectionCard(title: String, body: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 14
        card.layer.cornerCurve = .continuous

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLbl.textColor = .label
        titleLbl.textAlignment = .left
        titleLbl.numberOfLines = 0

        let bodyLbl = UILabel()
        bodyLbl.text = body
        bodyLbl.font = .systemFont(ofSize: 14, weight: .regular)
        bodyLbl.textColor = .secondaryLabel
        bodyLbl.textAlignment = .left
        bodyLbl.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLbl, bodyLbl])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        return card
    }
}
