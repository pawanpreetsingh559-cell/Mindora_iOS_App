//
//  ProfileViewController.swift
//  Mindora
//
//  Created by Anirudh
//

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
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBubbleAnimations()
        setupProfileCardTap()
        setupInfoRowTaps()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data every time view appears
        updateUserData()
    }
    
    // MARK: - Setup UI
    func setupUI() {
        // Style the avatar image view if it exists in the view hierarchy
        if let avatarView = findAvatarImageView() {
            avatarView.layer.cornerRadius = 40
            avatarView.clipsToBounds = true
            avatarView.contentMode = .scaleAspectFill
        }
    }
    
    // MARK: - Profile Card Tap (Edit Profile)
    private func setupProfileCardTap() {
        // Find the profile card view (the card containing name/email/avatar)
        // It's the view containing the nameLabel
        if let card = nameLabel?.superview {
            card.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(openEditProfile))
            card.addGestureRecognizer(tap)
        }
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
            
            // Load photo from Supabase asynchronously
            DataManager.shared.loadProfilePhoto { photo in
                if let photo = photo {
                    avatarView.image = photo
                    avatarView.tintColor = nil
                }
            }
        }
        
        updateStatBoxes()
    }
    
    // MARK: - Find Avatar Image View
    private func findAvatarImageView() -> UIImageView? {
        // The avatar is the UIImageView inside the profile card (nameLabel's superview)
        guard let card = nameLabel?.superview else { return nil }
        return card.subviews.compactMap { $0 as? UIImageView }.first
    }
    
    // MARK: - Initials Avatar Generator
    private func generateInitialsImage(name: String, size: CGSize) -> UIImage {
        let initials = name.components(separatedBy: " ")
            .compactMap { $0.first.map { String($0) } }
            .prefix(2).joined().uppercased()
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        let colors = [UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0),
                      UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0)]
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map { $0.cgColor } as CFArray,
            locations: [0, 1])!
        ctx.drawLinearGradient(gradient,
                               start: .zero,
                               end: CGPoint(x: size.width, y: size.height),
                               options: [])
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size.width * 0.35, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let str = initials as NSString
        let strSize = str.size(withAttributes: attrs)
        str.draw(at: CGPoint(x: (size.width - strSize.width) / 2,
                             y: (size.height - strSize.height) / 2),
                 withAttributes: attrs)
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
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
            ongoingCountLabel?.text = "—"
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
    func didUpdateProfile() {
        updateUserData()
    }
}
