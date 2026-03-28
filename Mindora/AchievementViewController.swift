import UIKit

class AchievementViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var topSummaryContainer: UIView!
    @IBOutlet weak var totalPointsLabel: UILabel!
    @IBOutlet weak var growthStageLabel: UILabel!
    @IBOutlet weak var progressRingView: CircularProgressView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Properties
    private let manager = AchievementManager.shared
    private var dataSource: UICollectionViewDiffableDataSource<AchievementCategory, String>!
    
    // Programmatic circle badge label (unlocked count)
    private var circleUnlockLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        DataManager.shared.syncAchievementsNow()
        
        // Hide navigation bar entirely
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Re-enable swipe-back gesture even with hidden nav bar
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        // Push content down from the very top of the screen
        additionalSafeAreaInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        
        setupCollectionView()
        configureDataSource()
        setupHeaderCard()
        setupScrollableHeader()
        updateUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUnlock(_:)), name: .achievementUnlocked, object: nil)
    }
    
    private func setupScrollableHeader() {
        // Collect views to sweep into collection view header space
        let titleLabel = view.subviews.first(where: { $0 is UILabel && ($0 as? UILabel)?.text == "Achievements" })
        let subLabel = view.subviews.first(where: { $0 is UILabel && ($0 as? UILabel)?.text == "Your milestones & badges" })
        
        guard let titleLbl = titleLabel, let subLbl = subLabel, let summaryView = topSummaryContainer else { return }
        
        // Find the back button (the only button in the view that isn't deep inside a cell)
        let backBtn = view.subviews.first(where: { $0 is UIButton })
        
        // 1. Remove them from main view, clear their constraints
        titleLbl.removeFromSuperview()
        subLbl.removeFromSuperview()
        summaryView.removeFromSuperview()
        
        titleLbl.translatesAutoresizingMaskIntoConstraints = true
        subLbl.translatesAutoresizingMaskIntoConstraints = true
        summaryView.translatesAutoresizingMaskIntoConstraints = true
        
        // 2. Put them in a container that lives inside the collection view bounds
        let headerHeight: CGFloat = 240
        let headerView = UIView(frame: CGRect(x: 0, y: -headerHeight, width: UIScreen.main.bounds.width, height: headerHeight))
        
        headerView.addSubview(titleLbl)
        headerView.addSubview(subLbl)
        headerView.addSubview(summaryView)
        
        // Top to bottom layout
        titleLbl.frame = CGRect(x: 16, y: 0, width: UIScreen.main.bounds.width - 32, height: 40)
        subLbl.frame = CGRect(x: 16, y: 44, width: UIScreen.main.bounds.width - 32, height: 22)
        summaryView.frame = CGRect(x: 16, y: 82, width: UIScreen.main.bounds.width - 32, height: 120)
        
        collectionView.addSubview(headerView)
        
        // Give the collection view top spacing to show this container
        collectionView.contentInset = UIEdgeInsets(top: headerHeight, left: 0, bottom: 30, right: 0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: headerHeight, left: 0, bottom: 0, right: 0)
        
        // 3. Expand the collection view upwards so it scrolls under the back button
        collectionView.removeFromSuperview()
        view.addSubview(collectionView)
        view.sendSubviewToBack(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60), 
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Snapshot which achievements were already seen BEFORE the sync runs,
        // so that only achievements unlocked in this sync appear as "new".
        let userDefaults = UserDefaults.standard
        let previousUnlockedIds = Set(userDefaults.array(forKey: "seenUnlockedAchievements") as? [String] ?? [])
        
        DataManager.shared.syncAchievementsNow()
        updateUI()
        
        // Check for newly unlocked achievements (using the pre-sync snapshot)
        checkAndShowNewlyUnlockedAchievements(previouslySeenIds: previousUnlockedIds)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore nav bar for other screens
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupHeaderCard() {
        guard let card = topSummaryContainer else { return }
        

        // Card styling
        card.layer.cornerRadius = 20
        card.clipsToBounds = true
        card.backgroundColor = UIColor(red: 0.0, green: 0.580, blue: 1.0, alpha: 1.0) // #0094FF

        
        // Subtle depth circles
        for (x, y, size, a) in [(CGFloat(240), CGFloat(10), CGFloat(90), CGFloat(0.08)),
                                  (CGFloat(10),  CGFloat(70), CGFloat(55), CGFloat(0.06))] {
            let c = UIView(frame: CGRect(x: x, y: y, width: size, height: size))
            c.backgroundColor = UIColor.white.withAlphaComponent(a)
            c.layer.cornerRadius = size / 2
            card.addSubview(c)
        }
        
        totalPointsLabel.superview?.isHidden = true
        progressRingView.isHidden = true
        progressRingView.superview?.isHidden = true
        badgeLabel.textColor = UIColor.white.withAlphaComponent(0.70)
        badgeLabel.font      = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        let progressStack = UIStackView()
        progressStack.axis = .vertical
        progressStack.spacing = 6
        progressStack.alignment = .fill
        progressStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(progressStack)
        
        // Top Row: Unlocked (Left) ... Count (Right)
        let textStack = UIStackView()
        textStack.axis = .horizontal
        textStack.distribution = .equalSpacing
        textStack.alignment = .lastBaseline
        progressStack.addArrangedSubview(textStack)
        
        let titleLabel = UILabel()
        titleLabel.text = "Unlocked"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .left
        textStack.addArrangedSubview(titleLabel)
        
        let countLabel = UILabel()
        countLabel.textColor = .white
        countLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        countLabel.textAlignment = .right
        self.circleUnlockLabel = countLabel 
        textStack.addArrangedSubview(countLabel)
        
        // Bottom Row: Progress Bar
        let trackView = UIView()
        trackView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        trackView.layer.cornerRadius = 6
        trackView.clipsToBounds = true
        trackView.translatesAutoresizingMaskIntoConstraints = false
        progressStack.addArrangedSubview(trackView)
        
        let fillView = UIView()
        fillView.backgroundColor = UIColor.white
        fillView.layer.cornerRadius = 6
        fillView.translatesAutoresizingMaskIntoConstraints = false
        trackView.addSubview(fillView)
        fillView.tag = 999 
        
        NSLayoutConstraint.activate([
            progressStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            progressStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            progressStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            
            trackView.heightAnchor.constraint(equalToConstant: 12),
            
            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            fillView.widthAnchor.constraint(equalTo: trackView.widthAnchor, multiplier: 0) // initial 0
        ])
    }
    
    private func setupCollectionView() {
        collectionView.collectionViewLayout = createLayout()
        collectionView.delegate = self
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                  heightDimension: .absolute(240))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(240))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .estimated(44))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                      elementKind: UICollectionView.elementKindSectionHeader,
                                                                      alignment: .top)
            section.boundarySupplementaryItems = [header]
            
            return section
        }
        return layout
    }
    
    // MARK: - Data Source
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<AchievementCategory, String>(collectionView: collectionView) { [weak self] (collectionView, indexPath, id) -> UICollectionViewCell? in
            guard let self = self,
                  let achievement = self.manager.achievements.first(where: { $0.id == id }),
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AchievementCell", for: indexPath) as? AchievementCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: achievement)
            return cell
        }
        
        dataSource.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) in
            guard let self = self else { return nil }
             let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as? SectionHeaderView
            
            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            header?.titleLabel.text = section.rawValue
            return header
        }
    }
    
    private func updateUI() {
        let unlockedCount = manager.achievements.filter { $0.isUnlocked }.count
        let totalCount = manager.achievements.count

        // Derive growth stage from unlocked growth achievements
        let growthStage: String

        if manager.achievements.first(where: { $0.id == "growth_butterfly" })?.isUnlocked == true {
            growthStage = "Butterfly"
        } else if manager.achievements.first(where: { $0.id == "growth_cocoon" })?.isUnlocked == true {
            growthStage = "Cocoon"
        } else if manager.achievements.first(where: { $0.id == "growth_caterpillar" })?.isUnlocked == true {
            growthStage = "Caterpillar"
        } else {
            growthStage = "Egg"
        }

        totalPointsLabel.text = "\(unlockedCount * 10) pts"
        growthStageLabel.text = growthStage
        badgeLabel.isHidden = true


        // Update linear progress: count / total
        if let countLabel = circleUnlockLabel {
            countLabel.text = "\(unlockedCount)/\(totalCount)"
        }
        
        // Update the fill view width
        if let fillView = topSummaryContainer?.viewWithTag(999) {
            
            if let superview = fillView.superview {
                // Remove old width constraints
                fillView.constraints.forEach { c in
                    if c.firstAttribute == .width && (c.secondItem === superview || c.secondItem == nil) {
                         fillView.removeConstraint(c)
                    }
                }
                superview.constraints.forEach { c in
                    if c.firstItem === fillView && c.firstAttribute == .width {
                        superview.removeConstraint(c)
                    }
                }
                
                let newMultiplier = (totalCount > 0) ? CGFloat(unlockedCount) / CGFloat(totalCount) : 0
                let finalMult = max(0.001, min(newMultiplier, 1.0))
                
                let wConst = fillView.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: finalMult)
                wConst.isActive = true
                
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                }
            }
        }

        
        var snapshot = NSDiffableDataSourceSnapshot<AchievementCategory, String>()
        let categories = AchievementCategory.allCases
        snapshot.appendSections(categories)
        
        for category in categories {
            let items = manager.achievements
                .filter { $0.category == category }
                .sorted {
                    // Growth always shows in fixed lifecycle order: Egg → Caterpillar → Cocoon → Butterfly
                    if category == .growth {
                        return $0.requiredValue < $1.requiredValue
                    }
                    // All other categories: unlocked first, then by progress, then by required value
                    if $0.isUnlocked != $1.isUnlocked { return $0.isUnlocked }
                    if $0.currentValue != $1.currentValue { return $0.currentValue > $1.currentValue }
                    return $0.requiredValue < $1.requiredValue
                }
                .map { $0.id }
                
            snapshot.appendItems(items, toSection: category)
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Newly Unlocked Achievements
    private func checkAndShowNewlyUnlockedAchievements(previouslySeenIds: Set<String>) {
        // Get all currently unlocked achievement IDs (post-sync)
        let currentUnlockedIds = Set(manager.achievements.filter { $0.isUnlocked }.map { $0.id })
        
        // Find only the achievements newly unlocked since the last time this screen was shown
        let newlyUnlockedIds = currentUnlockedIds.subtracting(previouslySeenIds)
        
        // Update the seen set so next visit won't re-report these
        UserDefaults.standard.set(Array(currentUnlockedIds), forKey: "seenUnlockedAchievements")
        
        // Show popup only if there are genuinely new achievements this visit
        if !newlyUnlockedIds.isEmpty {
            showCongratulationsPopup(count: newlyUnlockedIds.count)
        }
    }
    
    private func showCongratulationsPopup(count: Int) {
        let title = "🎉 Congratulations!"
        let message = "You have unlocked \(count) achievement\(count == 1 ? "" : "s")!\n\nGo to achievement description to see your progress"
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Customize appearance
        alertController.view.tintColor = UIColor(red: 0.0, green: 0.580, blue: 1.0, alpha: 1.0) // #0094FF
        
        // Add action button
        let okAction = UIAlertAction(title: "Continue", style: .default) { _ in
            // Optional: Dismiss after user taps
        }
        alertController.addAction(okAction)
        
        // Present with haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Small delay to ensure view is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.present(alertController, animated: true)
        }
    }
    
    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: Any) {
        // If presented modally
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            // If in nav stack
            navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func showSummaryAlert(_ sender: Any) {
        let alert = UIAlertController(title: "Your Journey", message: "Keep going to unlock the Butterfly!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func handleUnlock(_ notification: Notification) {
        guard let achievement = notification.object as? Achievement else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let alert = UIAlertController(title: "Unlocked!", message: "You've earned: \(achievement.title)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Awesome!", style: .default))
        present(alert, animated: true)
        
        showConfetti()
        updateUI()
    }
    
    private func showConfetti() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.center.x, y: -50)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.frame.size.width, height: 1)
        
        let cell = CAEmitterCell()
        cell.birthRate = 5
        cell.lifetime = 10.0
        cell.velocity = 100
        cell.velocityRange = 50
        cell.emissionLongitude = .pi
        cell.spinRange = 4
        cell.scale = 0.1
        cell.scaleRange = 0.25
        cell.contents = UIImage(systemName: "star.fill")?.cgImage
        cell.color = UIColor.systemYellow.cgColor
        
        emitter.emitterCells = [cell]
        view.layer.addSublayer(emitter)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            emitter.birthRate = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                emitter.removeFromSuperlayer()
            }
        }
    }
}

class SectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "SectionHeader"
    
    // MARK: - IBOutlet
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

// MARK: - Collection View Delegate
extension AchievementViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       options: [.curveEaseOut, .allowUserInteraction],
                       animations: {
            cell.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.15,
                           delay: 0,
                           options: [.curveEaseOut, .allowUserInteraction],
                           animations: {
                cell.transform = .identity
            })
        }
        
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        
        guard let achievementId = dataSource.itemIdentifier(for: indexPath),
              let achievement = manager.achievements.first(where: { $0.id == achievementId }) else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailVC = storyboard.instantiateViewController(withIdentifier: "AchievementDetailViewController") as! AchievementDetailViewController
        detailVC.achievement = achievement
        if UIDevice.current.userInterfaceIdiom == .pad {
            detailVC.modalPresentationStyle = .formSheet
        } else {
            detailVC.modalPresentationStyle = .pageSheet
        }
        present(detailVC, animated: true)
    }
}
