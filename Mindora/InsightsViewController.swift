import UIKit

class InsightsViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var totalPointsLabel: UILabel!
    @IBOutlet weak var totalSessionsLabel: UILabel!
    @IBOutlet weak var totalButterfliesLabel: UILabel!
    @IBOutlet weak var currentStreakLabel: UILabel!
   
    
    // MARK: - Daily Goal Outlets
    @IBOutlet weak var dailyGoalPercentageLabel: UILabel!
    @IBOutlet weak var dailyGoalSessionsLabel: UILabel!
    @IBOutlet weak var congratulationsLabel: UILabel!
    
    // MARK: - Card View Outlets
    @IBOutlet weak var totalSessionsCardView: UIView!
    @IBOutlet weak var currentStreakCardView: UIView!
    @IBOutlet weak var butterfliesCardView: UIView!
    @IBOutlet weak var totalPointsCardView: UIView!
    
    // MARK: - Graph Outlet
    @IBOutlet weak var graphContainerView: UIView!
    var graphSegmentControl: UISegmentedControl?
    var graphScrollView: UIScrollView?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFixedHeader()
        setupUI()
        setupBubbleAnimations()
        
        // Listen for session completion to update UI immediately
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionCompletedHandler),
            name: NSNotification.Name("SessionCompletedNotification"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
    }
    
    @objc func sessionCompletedHandler() {
        setupUI()
    }
    
    // MARK: - Setup
    func setupUI() {
        updateMetricsDisplay()
        updateDailyGoalDisplay()
        
        drawGraph()
    }
    
    private func setupFixedHeader() {
        // Find the scroll view and its content view
        guard let scrollView = self.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView,
              let contentView = scrollView.subviews.first else { return }
        
        var originalTitle: UILabel?
        var originalSubtitle: UILabel?
        
        // Locate the original labels based on their text and hide them
        for view in contentView.subviews {
            if let label = view as? UILabel {
                if label.text == "Insights" {
                    originalTitle = label
                    label.alpha = 0
                } else if label.text == "Track your wellness journey and progress" {
                    originalSubtitle = label
                    label.alpha = 0
                }
            }
        }
        
        guard let oTitle = originalTitle, let oSubtitle = originalSubtitle else { return }
        
        // Create the sticky header container
        let headerView = UIView()
        headerView.backgroundColor = UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1.0)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(headerView)
        
        // Add duplicate title
        let pinnedTitle = UILabel()
        pinnedTitle.text = oTitle.text
        pinnedTitle.font = oTitle.font
        pinnedTitle.textColor = oTitle.textColor
        pinnedTitle.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(pinnedTitle)
        
        // Add duplicate subtitle
        let pinnedSubtitle = UILabel()
        pinnedSubtitle.text = oSubtitle.text
        pinnedSubtitle.font = oSubtitle.font
        pinnedSubtitle.textColor = oSubtitle.textColor
        pinnedSubtitle.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(pinnedSubtitle)
        
        // Setup constraints to lock the header to the top of the screen
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: self.view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: pinnedSubtitle.bottomAnchor, constant: 16),
            
            // Push title down to match original safe area constraints plus margin
            pinnedTitle.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            pinnedTitle.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            pinnedSubtitle.topAnchor.constraint(equalTo: pinnedTitle.bottomAnchor, constant: 8),
            pinnedSubtitle.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20)
        ])
        
        // Pull the scroll view content up slightly to reduce the physical gap
        // between the invisible labels in the scroll view and the Daily Goal card
        scrollView.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)
    }
}

// MARK: - UI Update Logic
extension InsightsViewController {
    
    func updateMetricsDisplay() {
        // Fetch fresh data
        let analytics = DataManager.shared.getAnalytics()
        let streak = DataManager.shared.getStreak()
        let points = DataManager.shared.getPoints()
        let butterflies = DataManager.shared.getButterflies()
        
        // Update Labels
        totalPointsLabel?.text = "\(points)"
        totalSessionsLabel?.text = "\(analytics.totalSessions)"
        totalButterfliesLabel?.text = "\(butterflies)"
        currentStreakLabel?.text = "\(streak)"
    }
    
    func updateDailyGoalDisplay() {
        let todaysSessions = DataManager.shared.getSessionCountForDay()
        let maxSessions = 4

        // Cap calculations at 4 sessions / 100%
        let displaySessions = min(todaysSessions, maxSessions)
        let percentage = (displaySessions * 100) / maxSessions

        dailyGoalPercentageLabel?.text = "\(percentage)%"
        dailyGoalSessionsLabel?.text = "\(displaySessions) of \(maxSessions) sessions"

        // Always hide the in-card label — we show a floating banner instead
        congratulationsLabel?.isHidden = true

        if todaysSessions >= maxSessions {
            showGoalCompletedBanner()
        }
    }

    // MARK: - Floating congratulations banner
    private func showGoalCompletedBanner() {
        // Avoid stacking multiple banners
        view.subviews.first(where: { $0.tag == 9901 })?.removeFromSuperview()

        let banner = UIView()
        banner.tag = 9901
        banner.layer.cornerRadius = 18
        banner.layer.masksToBounds = false
        banner.layer.shadowColor  = UIColor(red: 0.0, green: 0.6, blue: 0.55, alpha: 1).cgColor
        banner.layer.shadowOpacity = 0.30
        banner.layer.shadowRadius  = 12
        banner.layer.shadowOffset  = CGSize(width: 0, height: 4)

        // Teal gradient background
        let grad = CAGradientLayer()
        grad.colors = [
            UIColor(red: 0.0, green: 0.72, blue: 0.65, alpha: 1).cgColor,
            UIColor(red: 0.0, green: 0.56, blue: 0.52, alpha: 1).cgColor
        ]
        grad.startPoint = CGPoint(x: 0, y: 0); grad.endPoint = CGPoint(x: 1, y: 1)
        grad.cornerRadius = 18
        banner.layer.insertSublayer(grad, at: 0)

        // Star icon
        let icon = UILabel()
        icon.text = "🌟"; icon.font = UIFont.systemFont(ofSize: 28)
        icon.translatesAutoresizingMaskIntoConstraints = false

        // Message
        let msg = UILabel()
        msg.text = "Daily goal complete!"
        msg.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        msg.textColor = .white

        let sub = UILabel()
        sub.text = "You've done all 4 sessions today"
        sub.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        sub.textColor = UIColor.white.withAlphaComponent(0.85)

        let textStack = UIStackView(arrangedSubviews: [msg, sub])
        textStack.axis = .vertical; textStack.spacing = 2

        let hStack = UIStackView(arrangedSubviews: [icon, textStack])
        hStack.axis = .horizontal; hStack.spacing = 12; hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false

        banner.addSubview(hStack)
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)

        // Tab bar height for safe positioning
        let tabH = tabBarController?.tabBar.frame.height ?? 83

        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            banner.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(tabH + 14)),
            banner.heightAnchor.constraint(equalToConstant: 72),
            hStack.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 18),
            hStack.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -18),
            hStack.centerYAnchor.constraint(equalTo: banner.centerYAnchor)
        ])

        // Layout now so gradient fills correctly
        view.layoutIfNeeded()
        grad.frame = banner.bounds

        // Slide in from below
        banner.transform = CGAffineTransform(translationX: 0, y: 120)
        banner.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0,
                       usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5) {
            banner.transform = .identity; banner.alpha = 1
        }

        // Auto-dismiss after 4 s
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak banner] in
            UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseIn) {
                banner?.transform = CGAffineTransform(translationX: 0, y: 120)
                banner?.alpha = 0
            } completion: { _ in banner?.removeFromSuperview() }
        }
    }
    
   
}

// MARK: - Graph Logic
extension InsightsViewController {
    
    @objc func graphSegmentChanged(_ sender: UISegmentedControl) {
        guard let scrollView = graphScrollView else { return }
        let xOffset = CGFloat(sender.selectedSegmentIndex) * scrollView.frame.width
        scrollView.setContentOffset(CGPoint(x: xOffset, y: 0), animated: true)
    }

    func drawGraph() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let container = self.graphContainerView else { return }
            guard container.bounds.width > 0 else { return }
            
            container.subviews.forEach { $0.removeFromSuperview() }
            container.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            
            container.layer.cornerRadius = 12
            container.backgroundColor = UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1.0)
            
            // Add segmented control at the top
            let segmentHeight: CGFloat = 30
            let segmentPadding: CGFloat = 10
            let segmentedControl = UISegmentedControl(items: ["Weekly", "Monthly"])
            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.backgroundColor = .white
            segmentedControl.selectedSegmentTintColor = UIColor(red:0.0, green:0.580, blue:1.0, alpha:1) // #0094FF
            let selectedAttr: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
            ]
            segmentedControl.setTitleTextAttributes(selectedAttr, for: .selected)
            segmentedControl.addTarget(self, action: #selector(self.graphSegmentChanged(_:)), for: .valueChanged)
            segmentedControl.frame = CGRect(x: 20, y: segmentPadding, width: container.bounds.width - 40, height: segmentHeight)
            container.addSubview(segmentedControl)
            self.graphSegmentControl = segmentedControl
            
            let scrollY = segmentPadding + segmentHeight + segmentPadding
            let scrollHeight = container.bounds.height - scrollY
            
            let scrollView = UIScrollView(frame: CGRect(x: 0, y: scrollY, width: container.bounds.width, height: scrollHeight))
            scrollView.isPagingEnabled = true
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.delegate = self
            container.addSubview(scrollView)
            self.graphScrollView = scrollView
            
            let width = scrollView.bounds.width
            let height = scrollView.bounds.height
            scrollView.contentSize = CGSize(width: width * 2, height: height)
            
            let weeklyContainer = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            let monthlyContainer = UIView(frame: CGRect(x: width, y: 0, width: width, height: height))
            
            scrollView.addSubview(weeklyContainer)
            scrollView.addSubview(monthlyContainer)
            
            self.drawWeeklyGraph(in: weeklyContainer)
            self.drawMonthlyGraph(in: monthlyContainer)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = round(scrollView.contentOffset.x / scrollView.frame.width)
        if let segment = graphSegmentControl, segment.selectedSegmentIndex != Int(page) {
            segment.selectedSegmentIndex = Int(page)
        }
    }

    private func drawWeeklyGraph(in container: UIView) {
            let whiteContainer = UIView(frame: container.bounds.insetBy(dx: 10, dy: 10))
            whiteContainer.backgroundColor = .white
            whiteContainer.layer.cornerRadius = 12
            whiteContainer.layer.shadowColor = UIColor.black.cgColor
            whiteContainer.layer.shadowOpacity = 0.1
            whiteContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
            whiteContainer.layer.shadowRadius = 8
            container.addSubview(whiteContainer)
            
            // Add title
            let titleLabel = UILabel(frame: CGRect(x: 20, y: 15, width: whiteContainer.bounds.width - 40, height: 25))
            titleLabel.text = "Average Weekly Mood Score"
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            titleLabel.textColor = .darkGray
            whiteContainer.addSubview(titleLabel)
            
            // Add date label (top right)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            let dateLabel = UILabel(frame: CGRect(x: whiteContainer.bounds.width - 110, y: 15, width: 90, height: 25))
            dateLabel.text = dateFormatter.string(from: Date())
            dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            dateLabel.textColor = .lightGray
            dateLabel.textAlignment = .right
            whiteContainer.addSubview(dateLabel)
            
            // Get Fixed Week Data
            let data = DataManager.shared.getFixedWeekComparison()
            let currentScores = data.current.map { $0 ?? 0.0 }
            let previousScores = data.previous
            let labels = data.labels
            
            // Check if there is any data to display
            let hasData = currentScores.contains(where: { ($0 ?? 0) > 0 })
                || previousScores.contains(where: { $0 > 0 })
            
            // If no data, show placeholder
            if !hasData {
                self.showPlaceholder(in: whiteContainer)
                return
            }
            
            // Layout Constants (adjusted for white container)
            let margin: CGFloat = 30
            let topOffset: CGFloat = 60 // Space for title (increased for more gap)
            let bottomOffset: CGFloat = 60 // Space for labels and legend
            let graphWidth = whiteContainer.bounds.width - (margin * 2)
            let graphHeight = whiteContainer.bounds.height - topOffset - bottomOffset
            let maxValue: CGFloat = 5.0
            
            // Bar settings
            let barWidth: CGFloat = 15
            let groupSpacing = graphWidth / CGFloat(labels.count)
            let barSpacing: CGFloat = 4
            
            // ==========================================
            // Draw Grid & Y-Axis
            // ==========================================
            for i in 0...5 {
                let value = CGFloat(i)
                let y = topOffset + graphHeight * (1 - (value / maxValue))
                
                // Grid Line
                let gridPath = UIBezierPath()
                gridPath.move(to: CGPoint(x: margin, y: y))
                gridPath.addLine(to: CGPoint(x: whiteContainer.bounds.width - margin, y: y))
                
                let gridLayer = CAShapeLayer()
                gridLayer.path = gridPath.cgPath
                gridLayer.strokeColor = UIColor.systemGray6.cgColor
                gridLayer.lineWidth = 1.0
                if i > 0 { gridLayer.lineDashPattern = [4, 4] }
                whiteContainer.layer.addSublayer(gridLayer)
                
                // Y-Axis Labels (Darker)
                let label = UILabel(frame: CGRect(x: 5, y: y - 10, width: margin - 10, height: 20))
                label.text = "\(i)"
                label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
                label.textColor = .darkGray
                label.textAlignment = .right
                whiteContainer.addSubview(label)
            }
            
            // ==========================================
            // Draw Double Bars
            // ==========================================
            for (index, day) in labels.enumerated() {
                let centerX = margin + (CGFloat(index) * groupSpacing) + (groupSpacing / 2)
                
                // Previous week bar (Green) - Left
                let prevScore = previousScores[index]
                let prevHeight = (CGFloat(prevScore) / maxValue) * graphHeight
                let prevX = centerX - barWidth - (barSpacing / 2)
                let prevY = topOffset + graphHeight - prevHeight
                
                let prevBar = UIView(frame: CGRect(x: prevX, y: prevY, width: barWidth, height: prevHeight))
                
                // Add gradient to previous week bar
                let prevGradient = CAGradientLayer()
                prevGradient.frame = prevBar.bounds
                prevGradient.colors = [
                    UIColor.systemGreen.cgColor,
                    UIColor.systemGreen.withAlphaComponent(0.7).cgColor
                ]
                prevGradient.startPoint = CGPoint(x: 0.5, y: 0)
                prevGradient.endPoint = CGPoint(x: 0.5, y: 1)
                prevGradient.cornerRadius = 4
                prevBar.layer.insertSublayer(prevGradient, at: 0)
                
                // Add shadow for depth
                prevBar.layer.cornerRadius = 4
                prevBar.layer.shadowColor = UIColor.black.cgColor
                prevBar.layer.shadowOpacity = 0.2
                prevBar.layer.shadowOffset = CGSize(width: 0, height: 2)
                prevBar.layer.shadowRadius = 3
                prevBar.transform = CGAffineTransform(scaleX: 1.0, y: 0.01)
                whiteContainer.addSubview(prevBar)
                
                // Animate previous week bar
                UIView.animate(withDuration: 0.6, delay: Double(index) * 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                    prevBar.transform = .identity
                    prevGradient.frame = prevBar.bounds
                }
                
                // Current week bar (Blue) - Right
                let currScore = currentScores[index]
                let currHeight = (CGFloat(currScore) / maxValue) * graphHeight
                let currX = centerX + (barSpacing / 2)
                let currY = topOffset + graphHeight - currHeight
                
                let currBar = UIView(frame: CGRect(x: currX, y: currY, width: barWidth, height: currHeight))
                
                // Add gradient to current week bar
                let currGradient = CAGradientLayer()
                currGradient.frame = currBar.bounds
                currGradient.colors = [
                    UIColor.systemBlue.cgColor,
                    UIColor.systemBlue.withAlphaComponent(0.8).cgColor
                ]
                currGradient.startPoint = CGPoint(x: 0.5, y: 0)
                currGradient.endPoint = CGPoint(x: 0.5, y: 1)
                currGradient.cornerRadius = 4
                currBar.layer.insertSublayer(currGradient, at: 0)
                
                // Add shadow for depth
                currBar.layer.cornerRadius = 4
                currBar.layer.shadowColor = UIColor.black.cgColor
                currBar.layer.shadowOpacity = 0.25
                currBar.layer.shadowOffset = CGSize(width: 0, height: 2)
                currBar.layer.shadowRadius = 3
                currBar.transform = CGAffineTransform(scaleX: 1.0, y: 0.01)
                whiteContainer.addSubview(currBar)
                
                // Animate current week bar
                UIView.animate(withDuration: 0.6, delay: Double(index) * 0.1 + 0.05, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                    currBar.transform = .identity
                    currGradient.frame = currBar.bounds
                }
                
                // Day label
                self.drawLabel(text: day, x: centerX, y: whiteContainer.bounds.height - 35, in: whiteContainer)
            }
            
            // Legend at bottom
            self.addLegend(in: whiteContainer)
    }
    
    private func drawMonthlyGraph(in container: UIView) {
        let whiteContainer = UIView(frame: container.bounds.insetBy(dx: 10, dy: 10))
        whiteContainer.backgroundColor = .white
        whiteContainer.layer.cornerRadius = 12
        whiteContainer.layer.shadowColor = UIColor.black.cgColor
        whiteContainer.layer.shadowOpacity = 0.1
        whiteContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        whiteContainer.layer.shadowRadius = 8
        container.addSubview(whiteContainer)
        
        let titleLabel = UILabel(frame: CGRect(x: 20, y: 15, width: whiteContainer.bounds.width - 40, height: 25))
        titleLabel.text = "Monthly Mood Score"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .darkGray
        whiteContainer.addSubview(titleLabel)
        
        let data = DataManager.shared.getMonthlyComparison()
        
        let dateLabel = UILabel(frame: CGRect(x: whiteContainer.bounds.width - 110, y: 15, width: 90, height: 25))
        dateLabel.text = data.currentMonthName
        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .lightGray
        dateLabel.textAlignment = .right
        whiteContainer.addSubview(dateLabel)
        
        let currentScores = data.current.map { $0 ?? 0.0 }
        let hasData = !currentScores.isEmpty && currentScores.contains(where: { $0 > 0 })
            || data.previous.contains(where: { $0 > 0 })
        
        if !hasData {
            self.showPlaceholder(in: whiteContainer)
            return
        }
        
        let margin: CGFloat = 30
        let topOffset: CGFloat = 60
        let bottomOffset: CGFloat = 60
        let graphWidth = whiteContainer.bounds.width - (margin * 2)
        let graphHeight = whiteContainer.bounds.height - topOffset - bottomOffset
        let maxValue: CGFloat = 5.0
        let totalDays = data.labels.count
        
        // Y-axis grid
        for i in 0...5 {
            let value = CGFloat(i)
            let y = topOffset + graphHeight * (1 - (value / maxValue))
            let gridPath = UIBezierPath()
            gridPath.move(to: CGPoint(x: margin, y: y))
            gridPath.addLine(to: CGPoint(x: whiteContainer.bounds.width - margin, y: y))
            let gridLayer = CAShapeLayer()
            gridLayer.path = gridPath.cgPath
            gridLayer.strokeColor = UIColor.systemGray6.cgColor
            gridLayer.lineWidth = 1.0
            if i > 0 { gridLayer.lineDashPattern = [4, 4] }
            whiteContainer.layer.addSublayer(gridLayer)
            let label = UILabel(frame: CGRect(x: 5, y: y - 10, width: margin - 10, height: 20))
            label.text = "\(i)"
            label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
            label.textColor = .darkGray
            label.textAlignment = .right
            whiteContainer.addSubview(label)
        }
        
        let pointSpacing = graphWidth / CGFloat(max(1, totalDays - 1))
        
        // --- Green line (previous month) ---
        let prevPath = UIBezierPath()
        var prevFirstPoint = true
        for (index, score) in data.previous.enumerated() {
            guard index < totalDays else { break }
            let x = margin + CGFloat(index) * pointSpacing
            let clampedScore = min(max(CGFloat(score), 0), maxValue)
            let y = topOffset + graphHeight * (1 - (clampedScore / maxValue))
            if prevFirstPoint {
                prevPath.move(to: CGPoint(x: x, y: y))
                prevFirstPoint = false
            } else {
                prevPath.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        let prevLayer = CAShapeLayer()
        prevLayer.path = prevPath.cgPath
        prevLayer.strokeColor = UIColor.systemGreen.cgColor
        prevLayer.lineWidth = 2.5
        prevLayer.fillColor = UIColor.clear.cgColor
        prevLayer.lineCap = .round
        prevLayer.lineJoin = .round
        whiteContainer.layer.addSublayer(prevLayer)
        
        let prevAnim = CABasicAnimation(keyPath: "strokeEnd")
        prevAnim.fromValue = 0; prevAnim.toValue = 1
        prevAnim.duration = 1.0
        prevAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        prevLayer.add(prevAnim, forKey: "prevLine")
        
        // --- Blue line (current month) ---
        let currPath = UIBezierPath()
        var currFirstPoint = true
        for (index, scoreRaw) in data.current.enumerated() {
            guard index < totalDays else { break }
            guard let score = scoreRaw else { continue }
            let x = margin + CGFloat(index) * pointSpacing
            let clampedScore = min(max(CGFloat(score), 0), maxValue)
            let y = topOffset + graphHeight * (1 - (clampedScore / maxValue))
            if currFirstPoint {
                currPath.move(to: CGPoint(x: x, y: y))
                currFirstPoint = false
            } else {
                currPath.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        let currLayer = CAShapeLayer()
        currLayer.path = currPath.cgPath
        currLayer.strokeColor = UIColor(red:0.0, green:0.580, blue:1.0, alpha:1).cgColor
        currLayer.lineWidth = 3.0
        currLayer.fillColor = UIColor.clear.cgColor
        currLayer.lineCap = .round
        currLayer.lineJoin = .round
        whiteContainer.layer.addSublayer(currLayer)
        
        let currAnim = CABasicAnimation(keyPath: "strokeEnd")
        currAnim.fromValue = 0; currAnim.toValue = 1
        currAnim.duration = 1.0
        currAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        currLayer.add(currAnim, forKey: "currLine")
        
        // X-axis labels (every 5th day + first + last to avoid clutter)
        for (index, dayLabel) in data.labels.enumerated() {
            if index == 0 || index == totalDays - 1 || (index + 1) % 3 == 0 {
                let x = margin + CGFloat(index) * pointSpacing
                self.drawLabel(text: dayLabel, x: x, y: whiteContainer.bounds.height - 35, in: whiteContainer)
            }
        }
        
        // Legend
        self.addMonthlyLegend(in: whiteContainer, prevName: data.previousMonthName, currName: data.currentMonthName)
    }
    
    private func addMonthlyLegend(in container: UIView, prevName: String, currName: String) {
        let legendStack = UIStackView()
        legendStack.axis = .horizontal
        legendStack.spacing = 25
        legendStack.alignment = .center
        legendStack.distribution = .equalSpacing
        
        // Green (previous month)
        let greenStack = UIStackView()
        greenStack.axis = .horizontal; greenStack.spacing = 5; greenStack.alignment = .center
        let greenDot = UIView()
        greenDot.backgroundColor = .systemGreen
        greenDot.layer.cornerRadius = 5
        greenDot.translatesAutoresizingMaskIntoConstraints = false
        greenDot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        greenDot.heightAnchor.constraint(equalToConstant: 10).isActive = true
        let greenLabel = UILabel()
        greenLabel.text = prevName
        greenLabel.textColor = .darkGray
        greenLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        greenStack.addArrangedSubview(greenDot)
        greenStack.addArrangedSubview(greenLabel)
        
        // Blue (current month)
        let blueStack = UIStackView()
        blueStack.axis = .horizontal; blueStack.spacing = 5; blueStack.alignment = .center
        let blueDot = UIView()
        blueDot.backgroundColor = UIColor(red:0.0, green:0.580, blue:1.0, alpha:1)
        blueDot.layer.cornerRadius = 5
        blueDot.translatesAutoresizingMaskIntoConstraints = false
        blueDot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        blueDot.heightAnchor.constraint(equalToConstant: 10).isActive = true
        let blueLabel = UILabel()
        blueLabel.text = currName
        blueLabel.textColor = .darkGray
        blueLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        blueStack.addArrangedSubview(blueDot)
        blueStack.addArrangedSubview(blueLabel)
        
        legendStack.addArrangedSubview(greenStack)
        legendStack.addArrangedSubview(blueStack)
        
        container.addSubview(legendStack)
        legendStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            legendStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            legendStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])
    }
    
    // MARK: - Graph Helpers
    
    private func drawLabel(text: String, x: CGFloat, y: CGFloat, in container: UIView) {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        label.center = CGPoint(x: x, y: y)
        label.text = text
        label.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        container.addSubview(label)
    }
    
    private func addLegend(in container: UIView) {
        // Create horizontal stack for legend items
        let legendStack = UIStackView()
        legendStack.axis = .horizontal
        legendStack.spacing = 25
        legendStack.alignment = .center
        legendStack.distribution = .equalSpacing
        
        // Green indicator (Past Week)
        let greenStack = UIStackView()
        greenStack.axis = .horizontal
        greenStack.spacing = 5
        greenStack.alignment = .center
        
        let greenDot = UIView()
        greenDot.backgroundColor = .systemGreen
        greenDot.layer.cornerRadius = 5
        greenDot.translatesAutoresizingMaskIntoConstraints = false
        greenDot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        greenDot.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        let greenLabel = UILabel()
        greenLabel.text = "Past Week"
        greenLabel.textColor = .darkGray
        greenLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        
        greenStack.addArrangedSubview(greenDot)
        greenStack.addArrangedSubview(greenLabel)
        
        // Blue indicator (Current Week)
        let blueStack = UIStackView()
        blueStack.axis = .horizontal
        blueStack.spacing = 5
        blueStack.alignment = .center
        
        let blueDot = UIView()
        blueDot.backgroundColor = .systemBlue
        blueDot.layer.cornerRadius = 5
        blueDot.translatesAutoresizingMaskIntoConstraints = false
        blueDot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        blueDot.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        let blueLabel = UILabel()
        blueLabel.text = "Current Week"
        blueLabel.textColor = .darkGray
        blueLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        
        blueStack.addArrangedSubview(blueDot)
        blueStack.addArrangedSubview(blueLabel)
        
        // Add both to main legend stack
        legendStack.addArrangedSubview(greenStack)
        legendStack.addArrangedSubview(blueStack)
        
        // Add to container and position at bottom center
        container.addSubview(legendStack)
        legendStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            legendStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            legendStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])
    }
    
    private func showPlaceholder(in container: UIView) {
        // Create a centered placeholder view
        let placeholderStack = UIStackView()
        placeholderStack.axis = .vertical
        placeholderStack.spacing = 16
        placeholderStack.alignment = .center
        placeholderStack.distribution = .equalSpacing
        
        // Placeholder icon (chart line uptrend SF Symbol)
        let iconImageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
        iconImageView.image = UIImage(systemName: "chart.line.uptrend.xyaxis", withConfiguration: config)
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        placeholderStack.addArrangedSubview(iconImageView)
        
        // Main message
        let titleLabel = UILabel()
        titleLabel.text = "No Mood Data Yet"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .darkGray
        titleLabel.textAlignment = .center
        placeholderStack.addArrangedSubview(titleLabel)
        
        // Description text
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Complete calming sessions to see your mood score progression"
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .systemGray
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        let descriptionConstraint = descriptionLabel.widthAnchor.constraint(equalToConstant: container.bounds.width - 60)
        descriptionConstraint.isActive = true
        placeholderStack.addArrangedSubview(descriptionLabel)
        
        // Add placeholder to container
        container.addSubview(placeholderStack)
        placeholderStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            placeholderStack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }
}

// MARK: - Bubble Animation
extension InsightsViewController {
    
    func setupBubbleAnimations() {
        let cards: [UIView?] = [totalSessionsCardView, currentStreakCardView, butterfliesCardView, totalPointsCardView]
        for card in cards {
            if let card = card {
                addBubblesToCard(card, bubbleCount: 4)
            }
        }
    }
    
    private func addBubblesToCard(_ cardView: UIView, bubbleCount: Int) {
        for _ in 0..<bubbleCount {
            let size = CGFloat.random(in: 8...20)
            let bubble = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
            
            bubble.backgroundColor = UIColor.white.withAlphaComponent(0.25)
            bubble.layer.cornerRadius = size / 2
            bubble.layer.shadowColor = UIColor.white.cgColor
            bubble.layer.shadowOpacity = 0.7
            bubble.layer.shadowRadius = 10
            
            let maxX = max(cardView.bounds.width - size, 0)
            let maxY = max(cardView.bounds.height - size, 0)
            bubble.frame.origin = CGPoint(x: CGFloat.random(in: 0...maxX), y: CGFloat.random(in: 0...maxY))
            
            cardView.insertSubview(bubble, at: 0)
            animateBubble(bubble, in: cardView)
        }
    }
    
    private func animateBubble(_ bubble: UIView, in parentView: UIView) {
        let size = bubble.frame.width
        let endX = CGFloat.random(in: 0...max(parentView.bounds.width - size, 0))
        let endY = CGFloat.random(in: 0...max(parentView.bounds.height - size, 0))
        
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
