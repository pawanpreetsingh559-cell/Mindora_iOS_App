import UIKit

class DisclaimerViewController: UIViewController {

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
        let warningCard = makeWarningBanner()

        let sections: [(String, String)] = [
            ("1. Not a Medical Device", "Mindora is a personal wellness, self-reflection, and mindfulness tool. It is not a medical device, clinical service, or substitute for professional medical or mental health care.\n\nThe app does not diagnose, treat, cure, or prevent any physical or mental condition."),
            ("2. Seek Professional Advice", "Always seek the advice of a physician, therapist, or other qualified health provider with any questions you may have regarding a medical or mental health condition before making any health-related decisions."),
            ("3. Not a Crisis Service", "Mindora is not designed for use in mental health emergencies. If you are experiencing a mental health crisis, thoughts of self-harm, or are in immediate danger, please contact emergency services or a crisis helpline immediately.\n\nFor support, reach us at: mindora.icodesquad@gmail.com"),
            ("4. App Purpose", "Mindora is intended to support emotional awareness and general wellbeing through mood journaling, breathing sessions, and interactive AR mindfulness spaces. These tools are strictly complementary to — not a replacement for — professional mental health support."),
            ("5. Accuracy & Reliance", "While we strive to provide helpful mindfulness content, Mindora makes no warranties regarding the clinical validity, reliability, or accuracy of any information within the app. Content is for general informational purposes only."),
            ("6. Limitation of Liability", "To the fullest extent permitted by law, Mindora and its developers shall not be liable for any direct, indirect, incidental, or consequential damages arising from your use of the app or reliance on its content. Your use of Mindora is entirely at your own discretion and risk."),
            ("7. Changes to This Disclaimer", "We reserve the right to update this Disclaimer at any time. Changes will be reflected in the app with an updated date. Continued use of the app constitutes acceptance of the revised Disclaimer."),
            ("8. Contact", "For questions about this Disclaimer, please reach out to us at:\n\nmindora.icodesquad@gmail.com")
        ]

        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 20

        // Page title
        let titleLbl = makeLabel("Disclaimer", font: .systemFont(ofSize: 28, weight: .bold), color: .label)
        let dateLbl = makeLabel("Last updated: March 2026", font: .systemFont(ofSize: 14, weight: .regular), color: .secondaryLabel)
        mainStack.addArrangedSubview(titleLbl)
        mainStack.addArrangedSubview(dateLbl)
        mainStack.setCustomSpacing(4, after: titleLbl)
        mainStack.setCustomSpacing(20, after: dateLbl)
        mainStack.addArrangedSubview(warningCard)
        mainStack.setCustomSpacing(24, after: warningCard)

        for (title, body) in sections {
            let card = makeSectionCard(title: title, body: body)
            mainStack.addArrangedSubview(card)
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

    private func makeWarningBanner() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        card.layer.cornerRadius = 14
        card.layer.cornerCurve = .continuous
        card.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.3).cgColor
        card.layer.borderWidth = 1

        let icon = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        icon.image = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: config)
        icon.tintColor = .systemOrange
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let lbl = UILabel()
        lbl.text = "Mindora is not a medical service. It does not replace professional mental health care. If you are in crisis, please contact emergency services immediately."
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = UIColor.systemOrange
        lbl.numberOfLines = 0

        let row = UIStackView(arrangedSubviews: [icon, lbl])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .top
        card.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])
        return card
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
