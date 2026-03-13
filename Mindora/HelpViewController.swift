import UIKit

struct FAQItem {
    let question: String
    let answer: String
    var isExpanded: Bool = false
}

struct FAQSection {
    let title: String
    var items: [FAQItem]
}

class HelpViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Properties
    private var sections: [FAQSection] = [
        FAQSection(title: "Getting Started", items: [
            FAQItem(question: "What is Mindora?",
                    answer: "Mindora is a mental wellness app designed to help you track your mood, build mindfulness habits, and grow through daily reflection. Think of it as your personal mental health companion."),
            FAQItem(question: "How do I log my mood?",
                    answer: "Tap the Home tab and use the mood check-in card. Select how you're feeling on a scale of 1–5 and optionally add a note. Your entries are saved automatically."),
            FAQItem(question: "Is my data private?",
                    answer: "Yes. All your data is stored locally on your device. We do not share or sell your personal information. See our Privacy Policy for full details.")
        ]),
        FAQSection(title: "Mood Tracking", items: [
            FAQItem(question: "How often should I log my mood?",
                    answer: "We recommend logging once a day, ideally at the same time each day. Consistency helps you spot patterns and trends in your emotional wellbeing."),
            FAQItem(question: "Can I edit a past mood entry?",
                    answer: "Currently, mood entries are saved as-is. We are working on an edit feature for a future update."),
            FAQItem(question: "What do the mood scores mean?",
                    answer: "Scores range from 1 (very low) to 5 (very high). 1–2 indicates a difficult day, 3 is neutral, and 4–5 represents a positive, energised state.")
        ]),
        FAQSection(title: "Achievements", items: [
            FAQItem(question: "How do I earn achievements?",
                    answer: "Achievements are unlocked automatically as you use the app — logging moods, completing breathing exercises, maintaining streaks, and exploring features all earn you points and badges."),
            FAQItem(question: "What are growth stages?",
                    answer: "Growth stages (Egg → Caterpillar → Cocoon → Butterfly) represent your overall progress in the app. Each stage requires more points to reach, encouraging consistent engagement."),
            FAQItem(question: "Do achievements reset?",
                    answer: "No. Once an achievement is unlocked, it stays unlocked permanently.")
        ]),
        FAQSection(title: "Garden", items: [
            FAQItem(question: "How does the Garden work?",
                    answer: "Your Garden fills with butterflies as you earn them through consistent use. Collect 10 butterflies to complete your garden and start a new cycle."),
            FAQItem(question: "What are butterflies?",
                    answer: "Butterflies are rewards earned by completing daily check-ins and activities. They represent your growth and consistency over time.")
        ]),
        FAQSection(title: "Technical", items: [
            FAQItem(question: "Does Mindora work offline?",
                    answer: "Yes! Mindora works fully offline. All data is stored on your device, so you can use it anywhere without an internet connection."),
            FAQItem(question: "How do I reset the app?",
                    answer: "You can log out from the Profile tab. To fully reset all data, delete and reinstall the app. Note: this action is irreversible."),
            FAQItem(question: "How do I contact support?",
                    answer: "You can reach us at support@mindora.app. We aim to respond within 2 business days.")
        ])
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1)
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Setup
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FAQCell.self, forCellReuseIdentifier: FAQCell.reuseID)
        tableView.backgroundColor = UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1)
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56

        // Header with title
        let header = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 60))
        let titleLabel = UILabel()
        titleLabel.text = "Help & FAQ"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        header.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])
        tableView.tableHeaderView = header
    }

    // MARK: - Actions
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension HelpViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FAQCell.reuseID, for: indexPath) as! FAQCell
        let item = sections[indexPath.section].items[indexPath.row]
        cell.configure(with: item)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension HelpViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        sections[indexPath.section].items[indexPath.row].isExpanded.toggle()
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - FAQCell
class FAQCell: UITableViewCell {
    static let reuseID = "FAQCell"

    private let questionLabel = UILabel()
    private let answerLabel = UILabel()
    private let chevron = UIImageView()
    private let stack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        contentView.backgroundColor = .clear
        backgroundColor = UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1)

        questionLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        questionLabel.textColor = .label
        questionLabel.textAlignment = .left
        questionLabel.numberOfLines = 0

        answerLabel.font = .systemFont(ofSize: 14, weight: .regular)
        answerLabel.textColor = .secondaryLabel
        answerLabel.textAlignment = .left
        answerLabel.numberOfLines = 0
        answerLabel.isHidden = true

        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        chevron.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.widthAnchor.constraint(equalToConstant: 16).isActive = true
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.setContentCompressionResistancePriority(.required, for: .horizontal)

        let topRow = UIStackView(arrangedSubviews: [questionLabel, chevron])
        topRow.axis = .horizontal
        topRow.spacing = 8
        topRow.alignment = .center

        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .fill
        stack.addArrangedSubview(topRow)
        stack.addArrangedSubview(answerLabel)

        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    func configure(with item: FAQItem) {
        questionLabel.text = item.question
        answerLabel.text = item.answer
        answerLabel.isHidden = !item.isExpanded
        let angle: CGFloat = item.isExpanded ? .pi : 0
        UIView.animate(withDuration: 0.2) {
            self.chevron.transform = CGAffineTransform(rotationAngle: angle)
        }
    }
}
