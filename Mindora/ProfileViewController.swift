import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    
    // Stat boxes outlets
    @IBOutlet weak var completedCountLabel: UILabel!
    @IBOutlet weak var ongoingCountLabel: UILabel!
    @IBOutlet weak var greenCardView: UIView! // Green stat card container
    @IBOutlet weak var blueCardView: UIView! // Blue stat card container
    
    // MARK: - Lifecycle
    private var skipNextPhotoLoad = false  // set true after photo removal to prevent reload
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFixedHeader()
        setupUI()
        setupBubbleAnimations()
        setupProfileCardTap()
        setupInfoRowTaps()
    }
    
    private func setupFixedHeader() {
        guard let scrollView = self.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView,
              let contentView = scrollView.subviews.first else { return }
        
        var originalTitle: UILabel?
        var originalSubtitle: UILabel?
        
        for view in contentView.subviews {
            if let label = view as? UILabel {
                if label.text == "Profile" {
                    originalTitle = label
                    label.alpha = 0
                } else if label.text?.trimmingCharacters(in: .whitespaces) == "Manage your account" {
                    originalSubtitle = label
                    label.alpha = 0
                }
            }
        }
        
        guard let oTitle = originalTitle, let oSubtitle = originalSubtitle else { return }
        
        let headerView = UIView()
        headerView.backgroundColor = UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1.0)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(headerView)
        
        let pinnedTitle = UILabel()
        pinnedTitle.text = oTitle.text
        pinnedTitle.font = oTitle.font
        pinnedTitle.textColor = oTitle.textColor
        pinnedTitle.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(pinnedTitle)
        
        let pinnedSubtitle = UILabel()
        pinnedSubtitle.text = oSubtitle.text
        pinnedSubtitle.font = oSubtitle.font
        pinnedSubtitle.textColor = oSubtitle.textColor
        pinnedSubtitle.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(pinnedSubtitle)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: self.view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: pinnedSubtitle.bottomAnchor, constant: 16),
            
            pinnedTitle.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            pinnedTitle.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            pinnedSubtitle.topAnchor.constraint(equalTo: pinnedTitle.bottomAnchor, constant: 8),
            pinnedSubtitle.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20)
        ])
        
        // Pull scroll content up to reduce gap below the pinned header
        scrollView.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data every time view appears
        updateUserData()
    }
    
    func setupUI() {
        // Style the avatar image view if it exists in the view hierarchy
        if let avatarView = findAvatarImageView() {
            avatarView.layer.cornerRadius = 40
            avatarView.clipsToBounds = true
            avatarView.contentMode = .scaleAspectFill
        }
        setupDeleteAccountButton()
    }
    
    private func setupDeleteAccountButton() {
        guard let logoutButton = logoutButton, let parentView = logoutButton.superview else { return }
        
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Delete Account", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteAccountTapped), for: .touchUpInside)
        
        parentView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            deleteButton.centerXAnchor.constraint(equalTo: logoutButton.centerXAnchor),
            deleteButton.topAnchor.constraint(equalTo: logoutButton.bottomAnchor, constant: 16)
        ])
    }
    
    @objc private func deleteAccountTapped() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to permanently delete your account? This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.performDeleteAccount()
        })
        present(alert, animated: true)
    }
    
    private func performDeleteAccount() {
        let alert = UIAlertController(title: "Deleting...", message: "\nPlease wait.", preferredStyle: .alert)
        present(alert, animated: true)
        
        DataManager.shared.deleteAccount { [weak self] success, errorMsg in
            alert.dismiss(animated: true) {
                if success {
                    self?.navigateToLogin()
                } else {
                    let errAlert = UIAlertController(title: "Error", message: errorMsg ?? "Could not delete account.", preferredStyle: .alert)
                    errAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(errAlert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Profile Card Tap (Edit Profile)
    private func setupProfileCardTap() {
        guard let card = nameLabel?.superview else { return }
        card.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(openEditProfile))
        card.addGestureRecognizer(tap)

        // Chevron right indicator
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)))
        chevron.tintColor = UIColor.systemGray3
        chevron.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Info Row Taps
    private func setupInfoRowTaps() {
        // Find info rows by traversing the view hierarchy
        // The info rows are in a vertical stack view below the stat boxes
        guard let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView,
              let contentView = scrollView.subviews.first else { return }
        
        // Find all stack views in the content view
        let stackViews = contentView.subviews.compactMap { $0 as? UIStackView }
        
        // The info rows stack is the vertical one with 4 row views
        for stackView in stackViews where stackView.axis == .vertical {
            let rowViews = stackView.arrangedSubviews
            if rowViews.count == 4 {
                // Tighter spacing between the 4 rows
                stackView.spacing = 4
                // Apply corner radius to each row
                for row in rowViews {
                    row.layer.cornerRadius = 12
                    row.layer.cornerCurve = .continuous
                    row.clipsToBounds = true
                }
                // Help row
                addTap(to: rowViews[0], action: #selector(openHelp))
                // About row
                addTap(to: rowViews[1], action: #selector(openAbout))
                // Privacy Policy row
                addTap(to: rowViews[2], action: #selector(openPrivacy))
                // Disclaimer row
                addTap(to: rowViews[3], action: #selector(openDisclaimer))
            }
        }
    }
    
    private func addTap(to view: UIView, action: Selector) {
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: action)
        view.addGestureRecognizer(tap)
    }
    
    // MARK: - Edit Profile
    @objc private func openEditProfile() {
        let sb = UIStoryboard(name: "EditProfile", bundle: nil)
        guard let vc = sb.instantiateInitialViewController() as? EditProfileViewController else { return }
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.setNavigationBarHidden(true, animated: false)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    // MARK: - Info Row Navigation
    private func presentInfoScreen(storyboardName: String) {
        let sb = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = sb.instantiateInitialViewController()!
        let nav = UINavigationController(rootViewController: vc)
        nav.setNavigationBarHidden(true, animated: false)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    @objc private func openHelp() {
        presentInfoScreen(storyboardName: "Help")
    }
    
    @objc private func openAbout() {
        presentInfoScreen(storyboardName: "About")
    }
    
    @objc private func openPrivacy() {
        presentInfoScreen(storyboardName: "PrivacyPolicy")
    }
    
    @objc private func openDisclaimer() {
        presentInfoScreen(storyboardName: "Disclaimer")
    }
    
    // MARK: - Data Update
    func updateUserData() {
        if let user = DataManager.shared.getCurrentUser() {
            nameLabel?.text = user.name
            emailLabel?.text = user.email
        } else {
            nameLabel?.text = "Guest User"
            emailLabel?.text = "Please log in"
        }
        
        // Load and display profile photo
        if let avatarView = findAvatarImageView() {
            avatarView.layer.cornerRadius = 40
            avatarView.clipsToBounds = true

            // Show initials first as placeholder
            if let name = DataManager.shared.getCurrentUser()?.name {
                avatarView.image = generateInitialsImage(name: name, size: CGSize(width: 80, height: 80))
                avatarView.tintColor = nil
            }

            // Skip network load if photo was just removed; clear the flag only
            // inside the async block so a second viewWillAppear during the
            // dismiss animation cannot sneak a stale photo back in.
            if skipNextPhotoLoad {
                skipNextPhotoLoad = false
                // Do NOT kick off a network load — the initials placeholder above is correct.
            } else {
                DataManager.shared.loadProfilePhoto { photo in
                    if let photo = photo {
                        avatarView.image = photo
                        avatarView.tintColor = nil
                    }
                }
            }
        }
        
        updateStatBoxes()
    }
    
    private func findAvatarImageView() -> UIImageView? {
        guard let card = nameLabel?.superview else { return nil }
        return firstImageView(in: card)
    }

    private func firstImageView(in view: UIView) -> UIImageView? {
        for sub in view.subviews {
            if let iv = sub as? UIImageView { return iv }
            if let found = firstImageView(in: sub) { return found }
        }
        return nil
    }
    
    // MARK: - Initials Avatar Generator
    private func generateInitialsImage(name: String, size: CGSize) -> UIImage {
        return DataManager.shared.generateInitialsImage(name: name, size: size)
    }
    
    func updateStatBoxes() {
        // Green box: Total completed gardens
        let completedGardens = DataManager.shared.getCompletedGardens()
        completedCountLabel?.text = "\(completedGardens)"
        
        // Blue box: Average mood score of current week
        // Uses ONLY days that have actual mood data (non-nil, non-zero),
        // which matches what the graph blue bars visually show — bar height = that day's mood score.
        // Average of only the bars that have height > 0 is what the user intuitively reads.
        let weekData = DataManager.shared.getFixedWeekComparison()
        
        // compactMap removes nil (future days), then filter removes 0 (days with no mood logged)
        let daysWithData = weekData.current.compactMap { $0 }.filter { $0 > 0 }
        
        if daysWithData.isEmpty {
            ongoingCountLabel?.text = "0"
        } else {
            let average = daysWithData.reduce(0.0, +) / Double(daysWithData.count)
            ongoingCountLabel?.text = String(format: "%.1f", average)
        }
    }
    
    // MARK: - Logout Action
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            // Perform logout
            DataManager.shared.logoutUser()
            
            // Navigate to login screen
            self?.navigateToLogin()
        })
        
        present(alert, animated: true)
    }
    
    private func navigateToLogin() {
        // Navigate to the initial splash screen which handles the proper flow
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let initialVC = storyboard.instantiateInitialViewController() {
            // Set as root view controller to reset the navigation stack
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = initialVC
                window.makeKeyAndVisible()
                
                // Optional: Add a fade transition
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            }
        }
    }
    
    // MARK: - Bubble Animation
    func setupBubbleAnimations() {
        // Add bubbles to green card
        if let greenCard = greenCardView {
            addBubblesToCard(greenCard, bubbleCount: 6)
        }
        
        // Add bubbles to blue card
        if let blueCard = blueCardView {
            addBubblesToCard(blueCard, bubbleCount: 6)
        }
    }
    
    private func addBubblesToCard(_ cardView: UIView, bubbleCount: Int) {
        for _ in 0..<bubbleCount {
            let size = CGFloat.random(in: 15...35)
            let bubble = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
            
            bubble.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            bubble.layer.cornerRadius = size / 2
            bubble.layer.shadowColor = UIColor.white.cgColor
            bubble.layer.shadowOpacity = 0.7
            bubble.layer.shadowRadius = 15
            
            let maxX = cardView.bounds.width - size
            let maxY = cardView.bounds.height - size
            bubble.frame.origin = CGPoint(x: CGFloat.random(in: 0...maxX), y: CGFloat.random(in: 0...maxY))
            
            cardView.addSubview(bubble)
            animateBubble(bubble, in: cardView)
        }
    }
    
    private func animateBubble(_ bubble: UIView, in parentView: UIView) {
        let size = bubble.frame.width
        let endX = CGFloat.random(in: 0...(parentView.bounds.width - size))
        let endY = CGFloat.random(in: 0...(parentView.bounds.height - size))
        
        UIView.animate(withDuration: Double.random(in: 4.0...7.0),
                       delay: 0,
                       options: [.curveEaseInOut, .allowUserInteraction],
                       animations: {
            bubble.frame.origin = CGPoint(x: endX, y: endY)
        }) { [weak self] _ in
            self?.animateBubble(bubble, in: parentView)
        }
    }
}

// MARK: - EditProfileDelegate
extension ProfileViewController: EditProfileDelegate {
    func didUpdateProfile(photoRemoved: Bool) {
        // Set flag so the upcoming viewWillAppear call skips the network photo load.
        // Do NOT call updateUserData() here — viewWillAppear fires automatically
        // after the dismiss animation and will call it exactly once, respecting the flag.
        if photoRemoved {
            skipNextPhotoLoad = true
        }
    }
}
