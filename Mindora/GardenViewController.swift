import UIKit
import CoreHaptics

class GardenViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var sunImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var butterfliesLabel: UILabel!
    @IBOutlet weak var gardenImageView: UIImageView!
    @IBOutlet weak var gardenProgressView: UIProgressView!
    
    // Track butterfly views to clean them up on refresh
    private var butterflyViews: [UIImageView] = []
    private var hapticEngine: CHHapticEngine?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupGardenImageView()
        updateGardenState()
        addARButton()
        setupHaptics()
    }

    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        hapticEngine = try? CHHapticEngine()
        try? hapticEngine?.start()
        hapticEngine?.resetHandler = { [weak self] in
            try? self?.hapticEngine?.start()
        }
    }

    private func playDisturbHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else {
            // Fallback for devices without Core Haptics
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            return
        }
        let sharp = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ],
            relativeTime: 0
        )
        let soft = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ],
            relativeTime: 0.12
        )
        if let pattern = try? CHHapticPattern(events: [sharp, soft], parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: CHHapticTimeImmediate)
        }
    }

    private func setupGardenImageView() {
        // Remove any storyboard border that causes the visible boundary
        gardenImageView.layer.borderWidth = 0
        gardenImageView.layer.borderColor = UIColor.clear.cgColor
        gardenImageView.clipsToBounds = true
        // Match corner radius to parent card if it has one
        if let parent = gardenImageView.superview {
            gardenImageView.layer.cornerRadius = parent.layer.cornerRadius > 0
                ? parent.layer.cornerRadius : gardenImageView.layer.cornerRadius
        }
        // Remove shadow from imageView itself (shadow should be on the parent card, not the image)
        gardenImageView.layer.shadowOpacity = 0
    }

    private func addARButton() {
        let arButton = UIButton(type: .system)
        arButton.setTitle("AR Mode", for: .normal)
        arButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        arButton.setTitleColor(.white, for: .normal)
        arButton.backgroundColor = UIColor(red: 0.10, green: 0.50, blue: 0.22, alpha: 1.0)
        arButton.layer.cornerRadius = 14
        arButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        arButton.layer.shadowColor = UIColor(red: 0.10, green: 0.50, blue: 0.22, alpha: 1.0).cgColor
        arButton.layer.shadowOpacity = 0.35
        arButton.layer.shadowRadius = 4
        arButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        arButton.translatesAutoresizingMaskIntoConstraints = false
        arButton.addTarget(self, action: #selector(arButtonTapped), for: .touchUpInside)
        view.addSubview(arButton)

        NSLayoutConstraint.activate([
            arButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // Align with "My Garden" heading — sits ~60pt below safe area top
            arButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
        ])
    }

    @objc private func arButtonTapped() {
        let arVC = ARGardenViewController()
        arVC.modalPresentationStyle = .fullScreen
        present(arVC, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Enable swipe-back to dashboard
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        // Refresh every time we enter (in case points/time changed)
        updateGardenState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore default delegate so other screens aren't affected
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }

    // AUTOMATICALLY hides tab bar when pushed, shows it when popping back
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    // MARK: - Main Update Logic
    private func updateGardenState() {
        updateTimeOfDay()
        updateProgressBars()
        spawnButterflies()
    }
    
    // MARK: - Time of Day (Sun/Moon/Background)
    private func updateTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: Date())
        let isNight = hour >= 18 || hour < 5
        
        // 1. Background
        gardenImageView.image = UIImage(named: isNight ? "Night garden" : "Day garden")
        
        // 2. Celestial Body (Sun/Moon)
        if isNight {
            sunImageView.image = UIImage(named: "Moon")
            sunImageView.layer.shadowColor = UIColor.systemBlue.cgColor
            sunImageView.layer.shadowOpacity = 0.2   // was 0.6 — much softer
            sunImageView.layer.shadowRadius = 35     // was 20 — wider spread = no hard ring
            sunImageView.layer.shadowOffset = .zero
            animateMoonEffects(view: sunImageView)
        } else {
            sunImageView.image = UIImage(named: "sun")
            sunImageView.layer.shadowColor = UIColor.systemYellow.cgColor
            sunImageView.layer.shadowOpacity = 0.7
            sunImageView.layer.shadowRadius = 15
            animateSunEffects(view: sunImageView)
        }
    }
    
    // MARK: - Progress & Data
    private func updateProgressBars() {
        // 1. Lifecycle Progress (Top Bar)
        let stage = DataManager.shared.getLifecycleStage()
        let lifecycleProgress = Float(stage + 1) / 4.0
        progressView.setProgress(lifecycleProgress, animated: true)
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = UIColor.systemBlue.withAlphaComponent(0.2)
        
        // Garden butterfly progress bar
        // If the garden is full and user kept it, show 10/10 instead of 0/10
        let totalButterflies = DataManager.shared.getButterflies()
        let analytics = DataManager.shared.getAnalytics()
        let gardenIsFull = totalButterflies > 0 && totalButterflies % 10 == 0
        let displayCount = gardenIsFull && analytics.lastGardenAlertedAt == totalButterflies
            ? 10 : totalButterflies % 10
        let gardenProgress = Float(displayCount) / 10.0
        gardenProgressView.setProgress(gardenProgress, animated: true)
        gardenProgressView.progressTintColor = .systemOrange
        gardenProgressView.trackTintColor = UIColor.systemOrange.withAlphaComponent(0.2)
        
        let labelText = displayCount == 1 ? "Butterfly" : "Butterflies"
        butterfliesLabel.text = "\(displayCount) \(labelText)"
    }
    

    private func spawnButterflies() {
        // Clear old views
        butterflyViews.forEach { $0.removeFromSuperview() }
        butterflyViews.removeAll()
        
        // totalButterflies is lifetime — current garden shows totalButterflies % 10
        let total = DataManager.shared.getButterflies()
        let currentCycleCount = total % 10
        
        let analytics = DataManager.shared.getAnalytics()
        let gardenIsFull = total > 0 && total % 10 == 0
        
        // Show the alert only once per milestone
        if gardenIsFull && analytics.lastGardenAlertedAt != total {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showGardenCompleteAlert()
            }
        }
        
        // If the garden is full and user chose Keep Garden, display all 10 butterflies
        // instead of 0 (which is what % 10 gives for a full garden).
        let countToDisplay = gardenIsFull && analytics.lastGardenAlertedAt == total ? 10 : currentCycleCount
        
        guard countToDisplay > 0 else { return }
        
        for i in 0..<countToDisplay {
            let butterfly = UIImageView(image: UIImage(named: "Image 12"))
            butterfly.contentMode = .scaleAspectFit
            butterfly.isUserInteractionEnabled = true

            // Vary size slightly for depth perception
            let size: CGFloat
            if i < 4 { size = 40 }       // Bottom (Closer)
            else if i < 7 { size = 35 }  // Middle
            else { size = 30 }           // Top (Farther)

            butterfly.frame = CGRect(x: 0, y: 0, width: size, height: size)

            gardenImageView.addSubview(butterfly)
            butterflyViews.append(butterfly)

            // Tap to disturb
            let tap = UITapGestureRecognizer(target: self, action: #selector(butterflyTapped(_:)))
            butterfly.addGestureRecognizer(tap)

            // 1. Get Stratified Position
            let startPoint = getStratifiedPoint(index: i, bounds: gardenImageView.bounds)
            butterfly.center = startPoint

            // 2. Animate with Graceful Motion
            let delay = Double(i) * 0.5
            animateSmartFlight(view: butterfly, start: startPoint, index: i, delay: delay)
        }
    }
    
    // MARK: - Butterfly Tap (Disturb)
    @objc private func butterflyTapped(_ gesture: UITapGestureRecognizer) {
        guard let butterfly = gesture.view as? UIImageView else { return }
        playDisturbHaptic()

        butterfly.layer.removeAllAnimations()
        butterfly.isUserInteractionEnabled = false

        // Phase 1: Startled jitter — rapid shake in place (0.25s)
        let jitter = CAKeyframeAnimation(keyPath: "transform.translation.x")
        jitter.timingFunction = CAMediaTimingFunction(name: .linear)
        jitter.duration = 0.25
        jitter.values = [-6, 6, -5, 5, -4, 4, -2, 2, 0]
        butterfly.layer.add(jitter, forKey: "jitter")

        let jitterY = CAKeyframeAnimation(keyPath: "transform.translation.y")
        jitterY.timingFunction = CAMediaTimingFunction(name: .linear)
        jitterY.duration = 0.25
        jitterY.values = [-4, 4, -5, 5, -3, 3, -2, 2, 0]
        butterfly.layer.add(jitterY, forKey: "jitterY")

        // Phase 2: Erratic zig-zag escape after jitter
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            // Pick a random escape direction
            let escapeX = CGFloat.random(in: -120...120)
            let escapeY = CGFloat.random(in: -200 ... -80)

            // Zig-zag waypoints: dart left/right while flying away
            let mid1 = CGAffineTransform(translationX: escapeX * 0.3 + CGFloat.random(in: -60...60),
                                          y: escapeY * 0.4)
            let mid2 = CGAffineTransform(translationX: escapeX * 0.6 + CGFloat.random(in: -80...80),
                                          y: escapeY * 0.7)
            let final = CGAffineTransform(translationX: escapeX, y: escapeY).scaledBy(x: 0.3, y: 0.3)

            UIView.animateKeyframes(withDuration: 0.7, delay: 0, options: []) {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
                    butterfly.transform = mid1
                    butterfly.alpha = 0.9
                }
                UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.35) {
                    butterfly.transform = mid2
                    butterfly.alpha = 0.5
                }
                UIView.addKeyframe(withRelativeStartTime: 0.65, relativeDuration: 0.35) {
                    butterfly.transform = final
                    butterfly.alpha = 0
                }
            } completion: { _ in
                butterfly.removeFromSuperview()
                if let idx = self.butterflyViews.firstIndex(of: butterfly) {
                    self.butterflyViews.remove(at: idx)
                }
                // Respawn after a short pause
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                    guard let self = self else { return }
                    let i = self.butterflyViews.count
                    let newButterfly = UIImageView(image: UIImage(named: "Image 12"))
                    newButterfly.contentMode = .scaleAspectFit
                    newButterfly.isUserInteractionEnabled = true
                    let sz: CGFloat = i < 4 ? 40 : (i < 7 ? 35 : 30)
                    newButterfly.frame = CGRect(x: 0, y: 0, width: sz, height: sz)
                    newButterfly.alpha = 0
                    self.gardenImageView.addSubview(newButterfly)
                    self.butterflyViews.append(newButterfly)
                    let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.butterflyTapped(_:)))
                    newButterfly.addGestureRecognizer(tap2)
                    let startPt = self.getStratifiedPoint(index: i, bounds: self.gardenImageView.bounds)
                    newButterfly.center = startPt
                    UIView.animate(withDuration: 0.4) { newButterfly.alpha = 1 }
                    self.animateSmartFlight(view: newButterfly, start: startPt, index: i, delay: 0)
                }
            }
        }
    }


    // MARK: - Alerts
    private func showGardenCompleteAlert() {
        let alert = UIAlertController(
            title: "Garden Complete! 🦋🌸",
            message: "You've collected 10 butterflies! Would you like to reset your garden to start a new journey?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Reset Garden", style: .default) { [weak self] _ in
            self?.performReset()
        })
        
        alert.addAction(UIAlertAction(title: "Keep Garden", style: .cancel) { _ in
            // Mark alert as shown so it doesn't re-fire next time the screen opens
            DataManager.shared.markGardenAlertShown()
        })
        present(alert, animated: true)
    }
    
    private func performReset() {
        // Record that we've shown the alert for this butterfly count so it won't repeat.
        DataManager.shared.markGardenAlertShown()
        // Increment garden count — butterfly count is lifetime and never resets.
        // The garden visually empties because spawnButterflies() uses totalButterflies % 10.
        DataManager.shared.incrementCompletedGardens()
        updateGardenState()
    }
}

// MARK: - Animation & Path Logic
extension GardenViewController {
    
    // Divide screen into 3 layers (Flowers, Air, Sky)
    private func getStratifiedPoint(index: Int, bounds: CGRect) -> CGPoint {
        let w = bounds.width
        let h = bounds.height
        
        var yRange: ClosedRange<CGFloat>
        var xRange: ClosedRange<CGFloat>
        
        // Horizontal spread
        let xSection = w / 3
        let xOffset = CGFloat(index % 3) * xSection
        xRange = (xOffset + 20)...(xOffset + xSection - 20)

        // Vertical Layering
        if index < 4 {
            // LAYER 1: BOTTOM (Flowers)
            yRange = (h * 0.65)...(h * 0.90)
        } else if index < 7 {
            // LAYER 2: MIDDLE (Air)
            yRange = (h * 0.35)...(h * 0.60)
        } else {
            // LAYER 3: TOP (Sky)
            yRange = (h * 0.10)...(h * 0.30)
        }
        
        return CGPoint(
            x: CGFloat.random(in: xRange),
            y: CGFloat.random(in: yRange)
        )
    }
    

    func animateSmartFlight(view: UIView, start: CGPoint, index: Int, delay: Double) {
        let animation = CAKeyframeAnimation(keyPath: "position")
        let path = UIBezierPath()
        path.move(to: start)
        
        // 1. Settings for Flight Style
        let flightRadius: CGFloat
        let speedDuration: Double
        
        if index < 4 {
            // Bottom: Very slow, small gentle movements near flowers
            flightRadius = 25
            speedDuration = Double.random(in: 18...25) // Much Slower
        } else if index < 7 {
            // Middle: Peaceful drifting
            flightRadius = 50
            speedDuration = Double.random(in: 25...35) // Much Slower
        } else {
            // Top: Slow, wide soaring
            flightRadius = 80
            speedDuration = Double.random(in: 35...45) // Very Slow
        }
        
        // 2. Generate Smoother Path Points
        var currentPoint = start
        for _ in 0...4 { // Fewer points = smoother curves
            let nextPoint = CGPoint(
                x: start.x + CGFloat.random(in: -flightRadius...flightRadius),
                y: start.y + CGFloat.random(in: -flightRadius...flightRadius)
            )
            
            // Widen the control points for gentler curves
            let control1 = CGPoint(
                x: currentPoint.x + CGFloat.random(in: -40...40),
                y: currentPoint.y + CGFloat.random(in: -40...40)
            )
            let control2 = CGPoint(
                x: nextPoint.x + CGFloat.random(in: -40...40),
                y: nextPoint.y + CGFloat.random(in: -40...40)
            )
            
            path.addCurve(to: nextPoint, controlPoint1: control1, controlPoint2: control2)
            currentPoint = nextPoint
        }
        
        path.close()
        
        animation.path = path.cgPath
        animation.duration = speedDuration
        animation.repeatCount = .infinity
        animation.beginTime = CACurrentMediaTime() + delay
        animation.fillMode = .forwards
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(animation, forKey: "flight")
        
        // 3. UPDATED: Gentle Wing Flap
        let flap = CABasicAnimation(keyPath: "transform.scale.x")
        flap.fromValue = 1.0
        flap.toValue = 0.85 // Less drastic squeeze
        
        // Slower flapping for a more relaxed look
        let flapSpeed = (index >= 7) ? 0.4 : 0.6
        flap.duration = flapSpeed
        flap.repeatCount = .infinity
        flap.autoreverses = true
        view.layer.add(flap, forKey: "flap")
    }
    
    // Celestial Animations (Unchanged)
    func animateSunEffects(view: UIView) {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 20
        rotation.repeatCount = .infinity
        view.layer.add(rotation, forKey: "sunRot")
        
        let glow = CABasicAnimation(keyPath: "transform.scale")
        glow.fromValue = 1.0
        glow.toValue = 1.12
        glow.duration = 3
        glow.autoreverses = true
        glow.repeatCount = .infinity
        view.layer.add(glow, forKey: "sunGlow")
    }
    
    func animateMoonEffects(view: UIView) {
        // Slow rotation — full 360° every 60s for a calm dreamy feel
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 20
        rotation.repeatCount = .infinity
        view.layer.add(rotation, forKey: "moonRotation")

        let glow = CABasicAnimation(keyPath: "transform.scale")
        glow.toValue = 1.08
        glow.duration = 4
        glow.autoreverses = true
        glow.repeatCount = .infinity
        view.layer.add(glow, forKey: "moonGlow")

        let twinkle = CABasicAnimation(keyPath: "opacity")
        twinkle.fromValue = 0.85
        twinkle.toValue = 1.0
        twinkle.duration = 3
        twinkle.autoreverses = true
        twinkle.repeatCount = .infinity
        view.layer.add(twinkle, forKey: "moonTwinkle")
    }
}

// MARK: - Swipe-back gesture support
extension GardenViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow swipe-back only when there is a previous screen to pop to
        return (navigationController?.viewControllers.count ?? 0) > 1
    }
}
