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
            ("Privacy Policy", "Last updated: March 2026\n\nYour privacy is central to Mindora. This policy formally outlines the data we access, collect, and process, in strict compliance with iOS App Store privacy guidelines."),
            ("1. Information We Collect", "We only collect data necessary to provide Mindora's core experience:\n\n• Account Data: Name and email address.\n• Wellness Data: Your logged mood scores, session history, and achievements.\n• Photo Library: If you upload a custom avatar, we access your device's photo library solely for that purpose. We do not access or collect any other photos.\n• ARKit & Camera: The AR Garden uses your device's camera to place the 3D garden in your physical space. No camera feeds, environmental data, or facial data are recorded, stored, or transmitted."),
            ("2. How We Use Your Data", "Your data is strictly used to:\n\n• Securely authenticate your account.\n• Track your mindfulness progress and mood trends.\n• Present the interactive AR Garden.\n\nMindora does NOT sell your data, use it for targeted advertising, or share it with data brokers."),
            ("3. Data Storage & Security", "All data (including your avatar image and wellness records) is encrypted and securely synced using Supabase cloud infrastructure. We employ industry-standard security protocols to protect your personal information at rest and in transit."),
            ("4. Data Retention & Deletion", "Your data is retained only as long as your account is active. \n\nYou can instantly and permanently delete your account—and all associated cloud data—via the 'Delete Account' button in your Profile tab. Uninstalling the app does not automatically delete your cloud data."),
            ("5. Third-Party Services", "Mindora uses Supabase for backend infrastructure (database, storage, and authentication). We do not include third-party analytics trackers, third-party ads, or marketing SDKs."),
            ("6. Children's Privacy", "Mindora is not intended for use by children under the age of 13. We do not knowingly gather personal data from minors."),
            ("7. Your Rights", "Under global privacy frameworks, you have the right to access, amend, or completely erase your personal information through the app's Profile settings."),
            ("8. Contact & Updates", "We may periodically update this policy to reflect new features. For privacy-related inquiries or data requests, please reach out to us at mindora.icodesquad@gmail.com.")
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
