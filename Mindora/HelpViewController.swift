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

    private var sections: [FAQSection] = [
        FAQSection(title: "Getting Started", items: [
            FAQItem(question: "What is Mindora?",
                    answer: "Mindora is your personal mental wellness companion. It helps you build mindfulness habits through breathing exercises, mood tracking, and a dynamic 3D AR Garden that grows with your progress."),
            FAQItem(question: "Is my data private?",
                    answer: "Yes, absolutely. All your data is securely stored and synced to your personal cloud account. See our Privacy Policy for full details.")
        ]),
        FAQSection(title: "Mindfulness & Mood", items: [
            FAQItem(question: "How do the breathing sessions work?",
                    answer: "We offer tailored exercises like the 2-Minute Reset and Advanced Calming. Just follow the visual cues. If you receive a phone call, your session will automatically pause and resume when you're done."),
            FAQItem(question: "How do I log my mood?",
                    answer: "After completing a session, or via the dashboard, you can log your mood on a scale from 1 (very low) to 5 (energized). Tracking this daily helps you spot patterns over time.")
        ]),
        FAQSection(title: "Achievements & Growth", items: [
            FAQItem(question: "What are growth stages?",
                    answer: "As you continue your wellness journey, you will progress through natural life stages: Egg → Caterpillar → Cocoon → Butterfly. Consistent use naturally shapes your evolution."),
            FAQItem(question: "How do I earn badges?",
                    answer: "You unlock achievements automatically by using the app — completing sessions, logging moods, maintaining streaks, and collecting points. Check your milestones on the Achievements page.")
        ]),
        FAQSection(title: "Your AR Garden", items: [
            FAQItem(question: "What is the 3D Garden?",
                    answer: "The Garden is a beautiful AR sanctuary reflecting your inner calm. By dedicating time to yourself and earning butterflies, your garden becomes more vibrant and alive."),
            FAQItem(question: "How do I interact with the AR Garden?",
                    answer: "In the AR view, you can use pinch-to-zoom to resize your garden and use two-finger rotation to view it from any angle in your physical space.")
        ]),
        FAQSection(title: "Profile & Support", items: [
            FAQItem(question: "How do I customize my profile?",
                    answer: "Tap your avatar on the Edit Profile page. You can customize it with a personal photo or select one of our curated themes."),
            FAQItem(question: "How do I delete my account?",
                    answer: "Go to the Profile tab and tap 'Delete Account'. This will permanently wipe all your data (analytics, garden progress, profile) from our servers irreversibly."),
            FAQItem(question: "How do I contact support?",
                    answer: "We're here to help! Reach out to us anytime at mindora.icodesquad@gmail.com")
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
