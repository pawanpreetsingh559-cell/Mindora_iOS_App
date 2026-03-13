//
//  GardenViewController.swift
//  Mindora
//
//  Created by Agrim on 18/11/25.
//

import UIKit

class GardenViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var sunImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var butterfliesLabel: UILabel!
    @IBOutlet weak var gardenImageView: UIImageView!
    @IBOutlet weak var gardenProgressView: UIProgressView!
    
    // Track butterfly views to clean them up on refresh
    private var butterflyViews: [UIImageView] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initial setup
        navigationController?.setNavigationBarHidden(false, animated: false)
        updateGardenState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh every time we enter (in case points/time changed)
        updateGardenState()
    }
    
    // AUTOMATICALLY hides tab bar when pushed, shows it when popping back
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    // MARK: - Main Update Logic
    private func updateGardenState() {
        updateTimeOfDay()
        checkAndResetGardenIfNeeded() // Check logic before drawing
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
            sunImageView.layer.shadowOpacity = 0.6
            sunImageView.layer.shadowRadius = 20
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
        
        // 2. Garden Butterfly Progress (Bottom Bar)
        // totalButterflies is a lifetime counter — use % 10 for current garden cycle
        let totalButterflies = DataManager.shared.getButterflies()
        let currentCycleCount = totalButterflies % 10
        let gardenProgress = Float(currentCycleCount) / 10.0
        gardenProgressView.setProgress(gardenProgress, animated: true)
        gardenProgressView.progressTintColor = .systemOrange
        gardenProgressView.trackTintColor = UIColor.systemOrange.withAlphaComponent(0.2)
        
        // 3. Label — show current cycle count
        let labelText = currentCycleCount == 1 ? "Butterfly" : "Butterflies"
        butterfliesLabel.text = "\(currentCycleCount) \(labelText)"
    }
    
    private func checkAndResetGardenIfNeeded() {
        let total = DataManager.shared.getButterflies()
        
        if total >= 10 {
            // Logic handled via Alert callback in spawnButterflies
        }
    }
    
    // MARK: - Butterfly Spawning (Refined & Slowed)
    private func spawnButterflies() {
        // Clear old views
        butterflyViews.forEach { $0.removeFromSuperview() }
        butterflyViews.removeAll()
        
        // totalButterflies is lifetime — current garden shows totalButterflies % 10
        let total = DataManager.shared.getButterflies()
        let currentCycleCount = total % 10
        let countToDisplay = currentCycleCount
        
        // Check completion: a multiple of 10 means this cycle just finished
        if total > 0 && total % 10 == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showGardenCompleteAlert()
            }
        }
        
        guard countToDisplay > 0 else { return }
        
        for i in 0..<countToDisplay {
            let butterfly = UIImageView(image: UIImage(named: "Image 12"))
            butterfly.contentMode = .scaleAspectFit
            
            // Vary size slightly for depth perception
            let size: CGFloat
            if i < 4 { size = 40 }       // Bottom (Closer)
            else if i < 7 { size = 35 }  // Middle
            else { size = 30 }           // Top (Farther)
            
            butterfly.frame = CGRect(x: 0, y: 0, width: size, height: size)
            
            gardenImageView.addSubview(butterfly)
            butterflyViews.append(butterfly)
            
            // 1. Get Stratified Position
            let startPoint = getStratifiedPoint(index: i, bounds: gardenImageView.bounds)
            butterfly.center = startPoint
            
            // 2. Animate with Graceful Motion
            // Stagger start times so they don't all move in sync
            let delay = Double(i) * 0.5
            animateSmartFlight(view: butterfly, start: startPoint, index: i, delay: delay)
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
        
        alert.addAction(UIAlertAction(title: "Keep Garden", style: .cancel))
        present(alert, animated: true)
    }
    
    private func performReset() {
        // Increment garden count — butterfly count is lifetime and never resets.
        // The garden visually empties because spawnButterflies() uses totalButterflies % 10.
        DataManager.shared.incrementCompletedGardens()
        updateGardenState() // Refresh UI — garden will now show 0 butterflies (new cycle)
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
    
    // UPDATED: Slower, Smoother, More Presentable
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
