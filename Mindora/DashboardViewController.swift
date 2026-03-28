//
//  DashboardViewController.swift
//  Mindora final
//
//  Created by pawanpreet singh on 15/12/25.
//

import UIKit

class DashboardViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var blueCardView: UIView!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var quoteLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var lifecycleStageImageView: UIImageView!
    @IBOutlet weak var stageNameLabel: UILabel!
    @IBOutlet weak var stageDescriptionLabel: UILabel!
    @IBOutlet weak var myGardenView: UIView!
    @IBOutlet weak var achievementsCardView: UIView!
    @IBOutlet weak var advancedCalmingCardView: UIView!
    @IBOutlet weak var fireButton: UIButton!
    @IBOutlet weak var streakCountLabel: UILabel!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBubbleAnimation()
        setupMyGardenTapGesture()
        setupAchievementsTapGesture()
        setupAdvancedCalmingTapGesture()
        addChevron(to: myGardenView)
        addChevron(to: achievementsCardView)
        addChevron(to: advancedCalmingCardView)
        
        // Initial Data Load
        updateGreeting()
        updateDailyQuote()
        updateLifecycleStageImage()
        updateStreakBadgeCount()
        
        fireButton?.isUserInteractionEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleProfileUpdate), name: NSNotification.Name("UserProfileUpdated"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleProfileUpdate() {
        DispatchQueue.main.async {
            self.updateGreeting()
            self.updateLifecycleStageImage()
            self.updateStreakBadgeCount()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        updateGreeting()
        updateLifecycleStageImage()
        updateStreakBadgeCount()
    }
    
    // MARK: - Actions
    @IBAction func fireButtonTapped(_ sender: UIButton) {
        // Intentionally disabled — fire/streak button is display-only
    }
    
    @objc func myGardenViewTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let gardenVC = storyboard.instantiateViewController(withIdentifier: "gardenVC") as? GardenViewController {
            navigationController?.pushViewController(gardenVC, animated: true)
        }
    }
    
    private func setupMyGardenTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(myGardenViewTapped))
        myGardenView?.addGestureRecognizer(tapGesture)
        myGardenView?.isUserInteractionEnabled = true
    }
    
    @objc func achievementsCardViewTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let achievementVC = storyboard.instantiateViewController(withIdentifier: "achievementVC") as? AchievementViewController {
            achievementVC.hidesBottomBarWhenPushed = true
            navigationController?.setNavigationBarHidden(false, animated: false)
            navigationController?.pushViewController(achievementVC, animated: true)
        }
    }
    
    private func setupAchievementsTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(achievementsCardViewTapped))
        achievementsCardView?.addGestureRecognizer(tapGesture)
        achievementsCardView?.isUserInteractionEnabled = true
    }
    
    @objc func advancedCalmingCardViewTapped() {
        let advancedVC = AdvancedCalmingViewController()
        advancedVC.hidesBottomBarWhenPushed = true
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.pushViewController(advancedVC, animated: true)
    }
    
    private func setupAdvancedCalmingTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(advancedCalmingCardViewTapped))
        advancedCalmingCardView?.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Chevron Helper
    private func addChevron(to cardView: UIView?) {
        guard let cardView = cardView else { return }
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: config))
        chevron.tintColor = UIColor.systemGray3
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        cardView.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16)
        ])
    }
}

// MARK: - UI Logic
extension DashboardViewController {
    
    func updateGreeting() {
        let userName = DataManager.shared.getCurrentUser()?.name ?? ""
        
        // Separate greeting and username into different labels
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        switch hour {
        case 5..<12:  greeting = "Good Morning"
        case 12..<17: greeting = "Good Afternoon"
        case 17..<21: greeting = "Good Evening"
        default:      greeting = "Good Night"
        }
        greetingLabel.text = greeting
        userNameLabel.text = userName.isEmpty ? "Guest" : userName
    }
    
    func updateDailyQuote() {
        let quote = DataManager.shared.getDailyQuote()
        
        quoteLabel.text = "\"\(quote.text)\""
        authorLabel.text = "— \(quote.author)"
    }
    
    func updateStreakBadgeCount() {
        let streakDays = DataManager.shared.getStreak()
        streakCountLabel.text = "\(streakDays)"
    }
    
    func updateLifecycleStageImage() {
        let stage = DataManager.shared.getLifecycleStage()
        let totalSessions = DataManager.shared.getAnalytics().totalSessions
        
        let stageData: (name: String, image: String, desc: String)
        
        switch stage {
        case 0: stageData = ("Egg", "Image 8", "Within stillness, a new beginning quietly takes shape.")
        case 1: stageData = ("Caterpillar", "Image 6", "Every small step of the caterpillar is a quiet promise of transformation.")
        case 2: stageData = ("Pupa", "Image 9", "In silence and patience, transformation unfolds unseen.")
        case 3: stageData = ("Butterfly", "Image 12", "With open wings, change becomes freedom.")
        default: stageData = ("Egg", "Image 8", "Within stillness, a new beginning quietly takes shape.")
        }
        
        stageNameLabel.text = stageData.name
        stageDescriptionLabel.text = stageData.desc
        
        if totalSessions == 0 {
            // Shadowy/dull effect for the ENTIRE box for brand-new users
            lifecycleStageImageView.superview?.alpha = 0.45
            
            lifecycleStageImageView.image = UIImage(named: stageData.image)?.withRenderingMode(.alwaysTemplate)
            lifecycleStageImageView.tintColor = .systemGray
        } else {
            // Regular colourful appearance
            lifecycleStageImageView.superview?.alpha = 1.0
            
            lifecycleStageImageView.image = UIImage(named: stageData.image)?.withRenderingMode(.alwaysOriginal)
        }
    }
}

// MARK: - Animation
extension DashboardViewController {
    
    func setupBubbleAnimation() {
        guard let view = blueCardView else { return }
        
        // Create 8 bubbles
        for _ in 0..<8 {
            let size = CGFloat.random(in: 18...45)
            let bubble = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
            
            bubble.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            bubble.layer.cornerRadius = size / 2
            bubble.layer.shadowColor = UIColor.white.cgColor
            bubble.layer.shadowOpacity = 0.7
            bubble.layer.shadowRadius = 20
            
            let maxX = view.bounds.width - size
            let maxY = view.bounds.height - size
            bubble.frame.origin = CGPoint(x: CGFloat.random(in: 0...maxX), y: CGFloat.random(in: 0...maxY))
            
            view.addSubview(bubble)
            animateBubble(bubble, in: view)
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
