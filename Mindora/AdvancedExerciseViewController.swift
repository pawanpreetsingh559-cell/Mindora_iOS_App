// AdvancedExerciseViewController.swift
// Mindora — Dedicated full-screen player for Advanced Calming exercises.

import UIKit
import AVFoundation

// MARK: - Entry Model
struct AdvancedExercise {
    let title: String
    let subtitle: String
    let iconName: String
    let exerciseType: String
    let color1: UIColor
    let color2: UIColor
}

// MARK: - ViewController
class AdvancedExerciseViewController: UIViewController {

    // MARK: — Public
    var exercise: AdvancedExercise!

    // MARK: — Timer / State
    private var mainTimer: Timer?
    private var instructionTimer: Timer?
    private var countdownTimer: Timer?
    private var countdownValue: Int = 3
    private var elapsedTenths: Int = 0   // counts 0.1s ticks
    private var isRunning = false
    private var hasStartedOnce = false   // tracks if exercise was ever started
    private var speechSynth: AVSpeechSynthesizer?
    private var audioPlayer: AVAudioPlayer?

    /// Realistic session durations in tenths-of-seconds per exercise
    private var sessionTenths: Int {
        switch exercise?.exerciseType {
        case "physiologicalSigh":   return 1800  // 3 min
        case "coherentBreathing":   return 3000  // 5 min
        case "progressiveMuscle":   return 3000  // 5 min
        case "grounding54321":      return 1800  // 3 min
        case "guidedImagery":       return 3000  // 5 min
        case "boxBreathing":        return 2400  // 4 min
        case "heartBreathing":      return 3000  // 5 min
        default:                    return 1800  // 3 min default
        }
    }

    // MARK: — Animation state
    private var animationPhaseIndex: Int = 0
    private var animationViews: [UIView] = []

    // MARK: — UI
    private let gradientLayer = CAGradientLayer()

    private lazy var closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        lbl.textColor = .white
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = UIColor.white.withAlphaComponent(0.75)
        lbl.textAlignment = .center
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Central animation canvas — exercises draw into here
    private lazy var canvasView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = false
        return v
    }()

    private lazy var instructionCard: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        v.layer.cornerRadius = 20
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        return v
    }()

    private lazy var instructionLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        lbl.textColor = .white
        lbl.textAlignment = .center
        lbl.numberOfLines = 3
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // Timeline slider + time labels (like BreathingViewController)
    private lazy var timerSlider: UISlider = {
        let s = UISlider()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.minimumValue = 0
        s.maximumValue = 120
        s.value = 0
        s.isUserInteractionEnabled = false
        s.minimumTrackTintColor = .white
        s.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        s.thumbTintColor = .white
        return s
    }()

    private lazy var currentTimeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        lbl.textColor = UIColor.white.withAlphaComponent(0.8)
        lbl.text = "0:00"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var totalTimeLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        lbl.textColor = UIColor.white.withAlphaComponent(0.8)
        lbl.textAlignment = .right
        lbl.text = "2:00"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var playButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        btn.layer.cornerRadius = 35
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        let cfg = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        btn.setImage(UIImage(systemName: "play.fill", withConfiguration: cfg), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: — Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        setupGradient()
        buildLayout()
        configureForExercise()
        setupAudio()
        setupSpeech()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: — Gradient Background
    private func setupGradient() {
        gradientLayer.colors = [exercise.color1.cgColor, exercise.color2.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    // MARK: — Layout
    private func buildLayout() {
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(canvasView)
        view.addSubview(instructionCard)
        instructionCard.addSubview(instructionLabel)
        view.addSubview(timerSlider)
        view.addSubview(currentTimeLabel)
        view.addSubview(totalTimeLabel)
        view.addSubview(playButton)

        NSLayoutConstraint.activate([
            // Back button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            // Title — shifted down
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Canvas — pushed further down
            canvasView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 36),
            canvasView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            canvasView.widthAnchor.constraint(equalToConstant: 280),
            canvasView.heightAnchor.constraint(equalToConstant: 280),

            // Instruction card — below canvas
            instructionCard.topAnchor.constraint(equalTo: canvasView.bottomAnchor, constant: 20),
            instructionCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            instructionLabel.topAnchor.constraint(equalTo: instructionCard.topAnchor, constant: 16),
            instructionLabel.bottomAnchor.constraint(equalTo: instructionCard.bottomAnchor, constant: -16),
            instructionLabel.leadingAnchor.constraint(equalTo: instructionCard.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: instructionCard.trailingAnchor, constant: -16),

            // Play button — pinned to bottom
            playButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 70),
            playButton.heightAnchor.constraint(equalToConstant: 70),

            // Timeline slider — just above play button
            timerSlider.bottomAnchor.constraint(equalTo: playButton.topAnchor, constant: -24),
            timerSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            timerSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Current time (left of slider)
            currentTimeLabel.topAnchor.constraint(equalTo: timerSlider.bottomAnchor, constant: 4),
            currentTimeLabel.leadingAnchor.constraint(equalTo: timerSlider.leadingAnchor),

            // Total time (right of slider)
            totalTimeLabel.topAnchor.constraint(equalTo: timerSlider.bottomAnchor, constant: 4),
            totalTimeLabel.trailingAnchor.constraint(equalTo: timerSlider.trailingAnchor),
        ])
    }

    // MARK: — Configure per exercise
    private func configureForExercise() {
        titleLabel.text    = exercise.title
        subtitleLabel.text = exercise.subtitle
        setInstruction("Tap play to begin")
        buildExerciseAnimation()
        
        // Set slider max and total time label
        let totalSecs = Float(sessionTenths) / 10.0
        timerSlider.maximumValue = totalSecs
        timerSlider.value = 0
        let totalMins = Int(totalSecs) / 60
        let totalRemSecs = Int(totalSecs) % 60
        totalTimeLabel.text = String(format: "%d:%02d", totalMins, totalRemSecs)
        currentTimeLabel.text = "0:00"
    }

    // MARK: — Audio / Speech
    private func setupAudio() {
        guard let url = Bundle.main.url(forResource: "deep-calm-texture-short-450960", withExtension: "mp3") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.numberOfLoops = -1
        audioPlayer?.volume = 0.5
    }

    private func setupSpeech() {
        speechSynth = AVSpeechSynthesizer()
    }

    private func speak(_ text: String) {
        speechSynth?.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        u.rate = 0.45
        u.pitchMultiplier = 1.0
        u.volume = 0.8
        speechSynth?.speak(u)
    }

    // MARK: — Controls
    @objc private func closeTapped() {
        if hasStartedOnce && isRunning {
            pauseSession()
            let alert = UIAlertController(
                title: "Quit Exercise?",
                message: "Are you sure you want to quit this exercise? Your progress will not be saved.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Yes, Quit", style: .destructive) { [weak self] _ in
                self?.stopAll()
                self?.navigationController?.popViewController(animated: true)
            })
            alert.addAction(UIAlertAction(title: "Continue", style: .cancel, handler: nil))
            present(alert, animated: true)
        } else {
            stopAll()
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func playTapped() {
        isRunning ? pauseSession() : startSession()
    }

    private func startSession() {
        if hasStartedOnce {
            // Resume — skip countdown
            isRunning = true
            updatePlayIcon()
            audioPlayer?.play()
            startExerciseSession()
            mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.tick()
            }
            return
        }

        // First time — show 3-2-1 countdown
        countdownValue = 3
        setInstruction("\(countdownValue)")
        instructionLabel.font = UIFont.systemFont(ofSize: 48, weight: .bold)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.countdownValue -= 1

            if self.countdownValue > 0 {
                UIView.transition(with: self.instructionLabel, duration: 0.3,
                                  options: .transitionCrossDissolve) {
                    self.instructionLabel.text = "\(self.countdownValue)"
                }
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                self.instructionLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)

                self.hasStartedOnce = true
                self.isRunning = true
                self.updatePlayIcon()
                self.audioPlayer?.play()
                self.startExerciseSession()
                self.mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.tick()
                }
            }
        }
    }

    private func pauseSession() {
        isRunning = false
        updatePlayIcon()
        audioPlayer?.pause()
        mainTimer?.invalidate()
        instructionTimer?.invalidate()
        countdownTimer?.invalidate()
        countdownTimer = nil
        speechSynth?.stopSpeaking(at: .immediate)
    }

    private func stopAll() {
        isRunning = false
        mainTimer?.invalidate()
        instructionTimer?.invalidate()
        countdownTimer?.invalidate()
        countdownTimer = nil
        audioPlayer?.stop()
        speechSynth?.stopSpeaking(at: .immediate)
        canvasView.layer.removeAllAnimations()
        canvasView.subviews.forEach { $0.layer.removeAllAnimations() }
    }

    private func updatePlayIcon() {
        let name = isRunning ? "pause.fill" : "play.fill"
        let cfg = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        playButton.setImage(UIImage(systemName: name, withConfiguration: cfg), for: .normal)
    }

    // MARK: — Progress tick
    private func tick() {
        elapsedTenths += 1
        let elapsed = Float(elapsedTenths) / 10.0

        // Update slider
        timerSlider.value = elapsed

        // Update time labels
        let mins = Int(elapsed) / 60
        let secs = Int(elapsed) % 60
        currentTimeLabel.text = String(format: "%d:%02d", mins, secs)

        if elapsedTenths >= sessionTenths { finishSession() }
    }

    private func finishSession() {
        stopAll()

        // 1. Data Logic — match BreathingViewController
        let points = 5
        DataManager.shared.addPoints(points)
        DataManager.shared.incrementSessionCount()

        let totalSessions = DataManager.shared.getAnalytics().totalSessions
        if totalSessions % 4 == 0 {
            DataManager.shared.addButterfly()
        }

        DataManager.shared.updateStreak()

        // Notify dashboard to refresh
        NotificationCenter.default.post(name: NSNotification.Name("SessionCompletedNotification"), object: nil)

        // 2. Completion Alert with lifecycle stage
        let sessionsToday = DataManager.shared.getSessionCountForDay()
        let stageIndex = sessionsToday % 4

        var message = "Great! You've completed your \(exercise.title) exercise.\n\n+\(points) Points Earned! \u{1F3C6}\n\n"

        switch stageIndex {
        case 1: message += "You have completed Egg stage"
        case 2: message += "You have completed Caterpillar stage"
        case 3: message += "You have completed Pupa stage"
        case 0: message += "You have grown a Butterfly!"
        default: message += "Session Complete"
        }

        let alert = UIAlertController(title: "Session Complete! \u{1F389}", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigateToMoodScreen()
        })
        present(alert, animated: true)
    }

    private func navigateToMoodScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let moodVC = storyboard.instantiateViewController(withIdentifier: "MoodScoreViewController") as? MoodScoreViewController {
            moodVC.modalPresentationStyle = .fullScreen
            self.present(moodVC, animated: true, completion: nil)
        }
    }

    // MARK: — Instruction helper
    private func setInstruction(_ text: String, animate: Bool = false) {
        if animate {
            UIView.transition(with: instructionLabel, duration: 0.5, options: .transitionCrossDissolve) {
                self.instructionLabel.text = text
            }
        } else {
            instructionLabel.text = text
        }
    }
}

// MARK: - Exercise Animation Builder
extension AdvancedExerciseViewController {

    private func buildExerciseAnimation() {
        canvasView.subviews.forEach { $0.removeFromSuperview() }
        canvasView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        switch exercise.exerciseType {
        case "physiologicalSigh":   buildBreathCircleCanvas(color: exercise.color1)
        case "coherentBreathing":   buildPulseOrbCanvas(color: exercise.color1)
        case "progressiveMuscle":   buildProgressiveMuscleCanvas()
        case "grounding54321":      buildGroundingCanvas()
        case "guidedImagery":       buildImageryCanvas()
        case "boxBreathing":        buildBoxCanvas()
        case "heartBreathing":      buildHeartCanvas()
        default: break
        }
    }

    // Shared helpers
    private func iconView(_ sfName: String, color: UIColor, size: CGFloat = 100) -> UIImageView {
        let cfg  = UIImage.SymbolConfiguration(pointSize: size, weight: .medium)
        let img  = UIImageView(image: UIImage(systemName: sfName, withConfiguration: cfg))
        img.tintColor = color
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }

    private func circle(diameter: CGFloat, color: UIColor, alpha: CGFloat = 0.35) -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = color.withAlphaComponent(alpha)
        v.layer.cornerRadius = diameter / 2
        NSLayoutConstraint.activate([
            v.widthAnchor.constraint(equalToConstant: diameter),
            v.heightAnchor.constraint(equalToConstant: diameter)
        ])
        return v
    }

    private func pinCenter(_ child: UIView, to parent: UIView) {
        NSLayoutConstraint.activate([
            child.centerXAnchor.constraint(equalTo: parent.centerXAnchor),
            child.centerYAnchor.constraint(equalTo: parent.centerYAnchor)
        ])
    }

    // 1. Physiological Sigh — Apple Breathe-style flower petal animation
    private func buildBreathCircleCanvas(color: UIColor) {
        let petalCount = 6
        let petalDiameter: CGFloat = 100
        let offset: CGFloat = 30  // how far each petal is from center (collapsed)

        // Create a container for all petals so we can rotate the whole flower
        let flowerContainer = UIView()
        flowerContainer.translatesAutoresizingMaskIntoConstraints = false
        flowerContainer.clipsToBounds = false
        canvasView.addSubview(flowerContainer)
        NSLayoutConstraint.activate([
            flowerContainer.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor),
            flowerContainer.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor),
            flowerContainer.widthAnchor.constraint(equalToConstant: 280),
            flowerContainer.heightAnchor.constraint(equalToConstant: 280),
        ])

        // Lighter + darker shades for alternating petals
        let color1 = color
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let color2 = UIColor(
            red: min(r + 0.15, 1.0),
            green: min(g + 0.15, 1.0),
            blue: min(b + 0.05, 1.0),
            alpha: 1.0
        )

        var petals: [UIView] = []
        for i in 0..<petalCount {
            let angle = CGFloat(i) * (2.0 * .pi / CGFloat(petalCount))
            let petal = UIView()
            petal.translatesAutoresizingMaskIntoConstraints = false
            petal.backgroundColor = (i % 2 == 0 ? color1 : color2).withAlphaComponent(0.45)
            petal.layer.cornerRadius = petalDiameter / 2
            flowerContainer.addSubview(petal)

            let dx = cos(angle) * offset
            let dy = sin(angle) * offset

            NSLayoutConstraint.activate([
                petal.widthAnchor.constraint(equalToConstant: petalDiameter),
                petal.heightAnchor.constraint(equalToConstant: petalDiameter),
                petal.centerXAnchor.constraint(equalTo: flowerContainer.centerXAnchor, constant: dx),
                petal.centerYAnchor.constraint(equalTo: flowerContainer.centerYAnchor, constant: dy),
            ])
            petals.append(petal)
        }

        // Central glow dot
        let centerDot = UIView()
        centerDot.translatesAutoresizingMaskIntoConstraints = false
        centerDot.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        centerDot.layer.cornerRadius = 8
        flowerContainer.addSubview(centerDot)
        NSLayoutConstraint.activate([
            centerDot.widthAnchor.constraint(equalToConstant: 16),
            centerDot.heightAnchor.constraint(equalToConstant: 16),
            centerDot.centerXAnchor.constraint(equalTo: flowerContainer.centerXAnchor),
            centerDot.centerYAnchor.constraint(equalTo: flowerContainer.centerYAnchor),
        ])

        // animationViews: [flowerContainer, centerDot, petals...]
        animationViews = [flowerContainer, centerDot] + petals
    }

    // 2. Coherent Breathing glowing orb
    private func buildPulseOrbCanvas(color: UIColor) {
        let orb = circle(diameter: 200, color: color, alpha: 0.6)
        orb.layer.shadowColor = color.cgColor
        orb.layer.shadowRadius = 40; orb.layer.shadowOpacity = 0.9
        canvasView.addSubview(orb)
        pinCenter(orb, to: canvasView)
        animationViews = [orb]
    }

    // 3. Progressive Muscle Release body groups
    private func buildProgressiveMuscleCanvas() {
        // Concentric colored rings representing body zones
        let colors: [(UIColor, CGFloat)] = [
            (UIColor(red:0.56,green:0.36,blue:0.96,alpha:1), 220),
            (UIColor(red:0.56,green:0.36,blue:0.96,alpha:1), 170),
            (UIColor(red:0.56,green:0.36,blue:0.96,alpha:1), 120),
            (UIColor(red:0.56,green:0.36,blue:0.96,alpha:1), 70),
        ]
        var rings: [UIView] = []
        for (idx, (col, diam)) in colors.enumerated() {
            let r = circle(diameter: diam, color: col, alpha: 0.15 + CGFloat(idx) * 0.12)
            canvasView.addSubview(r)
            pinCenter(r, to: canvasView)
            rings.append(r)
        }
        let iv = iconView("figure.mind.and.body", color: .white, size: 60)
        canvasView.addSubview(iv)
        pinCenter(iv, to: canvasView)
        animationViews = rings + [iv]
    }

    // 4. Grounding 5-4-3-2-1 numbered dots
    private func buildGroundingCanvas() {
        let numbers = ["5", "4", "3", "2", "1"]
        let senses  = ["👁", "✋", "👂", "👃", "💨"]
        let positions: [(CGFloat, CGFloat)] = [
            (0, -100), (90, -30), (55, 80), (-55, 80), (-90, -30)
        ]
        for (i, (dx, dy)) in positions.enumerated() {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            dot.layer.cornerRadius = 32
            dot.layer.borderWidth = 2
            dot.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
            dot.tag = i

            let numLbl = UILabel()
            numLbl.translatesAutoresizingMaskIntoConstraints = false
            numLbl.text = senses[i] + "\n" + numbers[i]
            numLbl.font = UIFont.systemFont(ofSize: 14, weight: .bold)
            numLbl.textColor = .white
            numLbl.textAlignment = .center
            numLbl.numberOfLines = 2

            canvasView.addSubview(dot)
            dot.addSubview(numLbl)
            NSLayoutConstraint.activate([
                dot.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor, constant: dx),
                dot.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor, constant: dy),
                dot.widthAnchor.constraint(equalToConstant: 64),
                dot.heightAnchor.constraint(equalToConstant: 64),
                numLbl.centerXAnchor.constraint(equalTo: dot.centerXAnchor),
                numLbl.centerYAnchor.constraint(equalTo: dot.centerYAnchor),
            ])
            animationViews.append(dot)
        }
    }

    // 5. Guided Imagery mountain + sun
    private func buildImageryCanvas() {
        // Gradient sky circle
        let sky = circle(diameter: 240, color: exercise.color1, alpha: 0.4)
        canvasView.addSubview(sky)
        pinCenter(sky, to: canvasView)

        let iv = iconView("sun.horizon.fill", color: UIColor(red:0.98,green:0.84,blue:0.30,alpha:1), size: 90)
        canvasView.addSubview(iv)
        pinCenter(iv, to: canvasView)
        animationViews = [sky, iv]
    }

    // 6. Box Breathing animated square with traveling dot
    private func buildBoxCanvas() {
        let side: CGFloat = 200
        let square = UIView()
        square.translatesAutoresizingMaskIntoConstraints = false
        square.layer.borderWidth = 3
        square.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        square.layer.cornerRadius = 16
        square.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        canvasView.addSubview(square)
        NSLayoutConstraint.activate([
            square.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor),
            square.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor),
            square.widthAnchor.constraint(equalToConstant: side),
            square.heightAnchor.constraint(equalToConstant: side),
        ])

        let dot = UIView()
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.backgroundColor = .white
        dot.layer.cornerRadius = 10
        dot.layer.shadowColor = UIColor.white.cgColor
        dot.layer.shadowRadius = 8; dot.layer.shadowOpacity = 1
        square.addSubview(dot)
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 20),
            dot.heightAnchor.constraint(equalToConstant: 20),
            dot.centerXAnchor.constraint(equalTo: square.leadingAnchor),
            dot.centerYAnchor.constraint(equalTo: square.topAnchor),
        ])
        animationViews = [square, dot]
    }

    // 7. Heart Breathing pulsing heart
    private func buildHeartCanvas() {
        let bg = circle(diameter: 220, color: UIColor(red:0.96,green:0.28,blue:0.46,alpha:1), alpha: 0.2)
        canvasView.addSubview(bg)
        pinCenter(bg, to: canvasView)

        let iv = iconView("heart.fill", color: UIColor(red:0.96,green:0.28,blue:0.46,alpha:1), size: 100)
        iv.layer.shadowColor = UIColor(red:0.96,green:0.28,blue:0.46,alpha:1).cgColor
        iv.layer.shadowRadius = 20; iv.layer.shadowOpacity = 0.9
        canvasView.addSubview(iv)
        pinCenter(iv, to: canvasView)
        animationViews = [bg, iv]
    }
}

// MARK: - Exercise Session Logic
extension AdvancedExerciseViewController {

    private func startExerciseSession() {
        switch exercise.exerciseType {
        case "physiologicalSigh":  sessionPhysiologicalSigh()
        case "coherentBreathing":  sessionCoherentBreathing()
        case "progressiveMuscle":  sessionProgressiveMuscle()
        case "grounding54321":     sessionGrounding()
        case "guidedImagery":      sessionGuidedImagery()
        case "boxBreathing":       sessionBoxBreathing()
        case "heartBreathing":     sessionHeartBreathing()
        default: break
        }
    }

    // Helpers
    private func scheduleInstructions(_ items: [String], interval: TimeInterval, immediate: Bool = true) {
        var idx = 0
        if immediate {
            setInstruction(items[0], animate: false)
            speak(items[0])
            idx = 1
        }
        instructionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let text = items[idx % items.count]
            self.setInstruction(text, animate: true)
            self.speak(text)
            idx += 1
        }
    }

    // 1. Physiological Sigh — Apple Breathe-style flower bloom
    private func sessionPhysiologicalSigh() {
        guard animationViews.count >= 2 else { return }
        let flower   = animationViews[0]  // flowerContainer
        let center   = animationViews[1]  // centerDot
        let petals   = Array(animationViews.dropFirst(2))

        // Start collapsed
        flower.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        center.alpha = 0.4

        // 4s inhale + 2s top-up + 6s exhale = 12s total
        let total = 12.0
        let run = { [weak self] in
            guard let self = self, self.isRunning else { return }

            // Phase 1 — Inhale (4s): bloom open + rotate
            self.setInstruction("Inhale slowly through your nose", animate: true)
            self.speak("Inhale slowly through your nose")
            UIView.animate(withDuration: 4.0, delay: 0, options: .curveEaseInOut) {
                flower.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    .rotated(by: .pi / 6)
                center.alpha = 0.7
                petals.forEach { $0.alpha = 0.55 }
            } completion: { _ in
                guard self.isRunning else { return }

                // Phase 2 — Second short inhale (2s): expand to full + extra rotation
                self.setInstruction("Take a second short inhale", animate: true)
                self.speak("Take a second short inhale")
                UIView.animate(withDuration: 2.0, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.9) {
                    flower.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                        .rotated(by: .pi / 3)
                    center.alpha = 1.0
                    center.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                    petals.forEach { $0.alpha = 0.65 }
                } completion: { _ in
                    guard self.isRunning else { return }

                    // Phase 3 — Exhale (6s): contract + rotate back
                    self.setInstruction("Exhale slowly through your mouth", animate: true)
                    self.speak("Exhale slowly through your mouth")
                    UIView.animate(withDuration: 6.0, delay: 0, options: .curveEaseInOut) {
                        flower.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
                            .rotated(by: 0)
                        center.alpha = 0.4
                        center.transform = .identity
                        petals.forEach { $0.alpha = 0.45 }
                    }
                }
            }
        }
        run()
        instructionTimer = Timer.scheduledTimer(withTimeInterval: total, repeats: true) { _ in run() }
    }

    // 2. Coherent Breathing
    private func sessionCoherentBreathing() {
        guard let orb = animationViews.first else { return }
        orb.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

        let dur = 5.0
        let run = { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: dur, delay: 0, options: .curveEaseInOut) {
                orb.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.setInstruction("Inhale for 5... 🌬", animate: true)
            } completion: { _ in
                UIView.animate(withDuration: dur, delay: 0, options: .curveEaseInOut) {
                    orb.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    self.setInstruction("Exhale for 5... 😮‍💨", animate: true)
                }
            }
        }
        run()
        instructionTimer = Timer.scheduledTimer(withTimeInterval: dur * 2, repeats: true) { _ in run() }
    }

    // 3. Progressive Muscle Release
    private func sessionProgressiveMuscle() {
        let steps = [
            ("Clench your fists tight... 💪", true),
            ("Release... let it go completely 🌿", false),
            ("Lift your shoulders to your ears 🤷", true),
            ("Drop them down, release all tension 🌊", false),
            ("Scrunch your face muscles... 😬", true),
            ("Soften your face, breathe out 😌", false),
            ("Curl your toes tightly... 🦶", true),
            ("Let them go, feel the release ✨", false),
        ]
        var idx = 0
        setInstruction(steps[0].0, animate: false)
        speak(steps[0].0)
        pulseAnimViews(tense: steps[0].1)
        idx = 1
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let (text, tense) = steps[idx % steps.count]
            self.setInstruction(text, animate: true)
            self.speak(text)
            self.pulseAnimViews(tense: tense)
            idx += 1
        }
    }

    private func pulseAnimViews(tense: Bool) {
        if tense {
            UIView.animate(withDuration: 0.4) { self.animationViews.forEach { $0.transform = CGAffineTransform(scaleX: 1.15, y: 1.15) } }
        } else {
            UIView.animate(withDuration: 0.7) { self.animationViews.forEach { $0.transform = .identity } }
        }
    }

    // 4. Grounding 5-4-3-2-1
    private func sessionGrounding() {
        let steps = [
            "Name 5 things you can see 👁",
            "Touch 4 things around you ✋",
            "Name 3 things you can hear 👂",
            "Name 2 things you can smell 👃",
            "Take 1 slow, deep breath 💨",
        ]
        setInstruction(steps[0], animate: false)
        speak(steps[0])
        highlightGroundingDot(0)
        var idx = 1
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 24.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let i = idx % steps.count
            self.setInstruction(steps[i], animate: true)
            self.speak(steps[i])
            self.highlightGroundingDot(i)
            idx += 1
        }
    }

    private func highlightGroundingDot(_ active: Int) {
        for (i, dot) in animationViews.enumerated() {
            UIView.animate(withDuration: 0.4) {
                dot.backgroundColor = i == active
                    ? UIColor.white.withAlphaComponent(0.55)
                    : UIColor.white.withAlphaComponent(0.2)
                dot.transform = i == active ? CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
            }
        }
    }

    private func sessionGuidedImagery() {
        let scenes = [
            ("Imagine a quiet, peaceful place 🌿", UIColor(red:0.20,green:0.72,blue:0.90,alpha:0.5)),
            ("Feel a gentle warm breeze on your skin ☀️", UIColor(red:0.98,green:0.84,blue:0.30,alpha:0.5)),
            ("Hear soft water flowing nearby 💧", UIColor(red:0.30,green:0.60,blue:0.95,alpha:0.5)),
            ("Notice the colours and beauty around you 🌈", UIColor(red:0.80,green:0.50,blue:0.90,alpha:0.5)),
            ("Breathe slowly and just be present here 🍃", UIColor(red:0.30,green:0.82,blue:0.60,alpha:0.5)),
            ("Feel the ground beneath you, solid and safe 🌍", UIColor(red:0.60,green:0.45,blue:0.30,alpha:0.5)),
            ("Let all tension melt away like warm sunlight ✨", UIColor(red:0.98,green:0.78,blue:0.20,alpha:0.5)),
            ("You are calm, you are safe, you are here 🕊", UIColor(red:0.85,green:0.85,blue:0.95,alpha:0.5)),
        ]
        setInstruction(scenes[0].0, animate: false)
        speak(scenes[0].0)

        // Gentle breathing scale on sun icon
        if let sun = animationViews.last {
            UIView.animate(withDuration: 4.0, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction]) {
                sun.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            }
        }

        // Color-shift the background circle with each scene
        if let sky = animationViews.first {
            sky.backgroundColor = scenes[0].1
        }

        var idx = 1
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let scene = scenes[idx % scenes.count]
            self.setInstruction(scene.0, animate: true)
            self.speak(scene.0)
            // Smooth color transition
            UIView.animate(withDuration: 1.5) {
                self.animationViews.first?.backgroundColor = scene.1
            }
            idx += 1
        }
    }

    // 6. Box Breathing
    private func sessionBoxBreathing() {
        guard animationViews.count >= 2,
              let square = animationViews.first,
              let dot = animationViews[1].subviews.first else { return }

        let side: CGFloat = square.bounds.width > 0 ? square.bounds.width : 200

        let run = { [weak self] in
            guard let self = self else { return }
            // Top → Right  (Inhale 4s)
            self.setInstruction("Inhale 4 seconds 🌬", animate: true)
            self.speak("Inhale for 4")
            UIView.animate(withDuration: 4, delay: 0, options: .curveLinear) {
                dot.center = CGPoint(x: side, y: 0)
            } completion: { _ in
                // Right → Bottom (Hold 4s)
                self.setInstruction("Hold for 4 seconds 🛑", animate: true)
                self.speak("Hold for 4")
                UIView.animate(withDuration: 4, delay: 0, options: .curveLinear) {
                    dot.center = CGPoint(x: side, y: side)
                } completion: { _ in
                    // Bottom → Left (Exhale 4s)
                    self.setInstruction("Exhale for 4 seconds 😮‍💨", animate: true)
                    self.speak("Exhale for 4")
                    UIView.animate(withDuration: 4, delay: 0, options: .curveLinear) {
                        dot.center = CGPoint(x: 0, y: side)
                    } completion: { _ in
                        // Left → Top (Hold 4s)
                        self.setInstruction("Hold for 4 seconds 🛑", animate: true)
                        self.speak("Hold for 4")
                        UIView.animate(withDuration: 4, delay: 0, options: .curveLinear) {
                            dot.center = CGPoint(x: 0, y: 0)
                        }
                    }
                }
            }
        }
        run()
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 16, repeats: true) { _ in run() }
    }

    // 7. Heart Breathing
    private func sessionHeartBreathing() {
        guard animationViews.count >= 2 else { return }
        let heart = animationViews[1]

        let breaths = [
            "Breathe in — feel warmth in your chest 💛",
            "Breathe out — send love outward ❤️",
            "Inhale calm into your heart centre 🌿",
            "Exhale any tension you're holding 😮‍💨",
        ]
        setInstruction(breaths[0], animate: false)
        speak(breaths[0])

        // Start continuous double-heartbeat loop
        animateContinuousHeartbeat(heart)

        // Rotate breath prompts every 10s
        var idx = 1
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.setInstruction(breaths[idx % breaths.count], animate: true)
            self.speak(breaths[idx % breaths.count])
            idx += 1
        }
    }

    private func animateContinuousHeartbeat(_ v: UIView) {
        func beat() {
            guard isRunning else { return }
            UIView.animate(withDuration: 0.18) { v.transform = CGAffineTransform(scaleX: 1.2, y: 1.2) } completion: { _ in
                UIView.animate(withDuration: 0.18) { v.transform = .identity } completion: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.64) { beat() }
                }
            }
        }
        beat()
    }

    // 8. Cognitive Reset
    private func sessionCognitiveReset() {
        guard let brain = animationViews.last, let bg = animationViews.first else { return }
        let prompts: [(String, UIColor)] = [
            ("Identify one stressful thought 🤔", UIColor(red:0.90,green:0.30,blue:0.30,alpha:0.35)),
            ("Is this thought 100% true? 🔍", UIColor(red:0.80,green:0.60,blue:0.20,alpha:0.35)),
            ("What evidence supports it? 🧩", UIColor(red:0.60,green:0.60,blue:0.40,alpha:0.35)),
            ("What's a calmer perspective? 🌱", UIColor(red:0.30,green:0.72,blue:0.40,alpha:0.35)),
            ("Take a slow, deep breath now 🌬", UIColor(red:0.30,green:0.60,blue:0.80,alpha:0.35)),
            ("You are safe. This too shall pass ✨", UIColor(red:0.50,green:0.40,blue:0.80,alpha:0.35)),
        ]
        setInstruction(prompts[0].0, animate: false)
        speak(prompts[0].0)
        bg.backgroundColor = prompts[0].1

        // Gentle brain breathing pulse
        UIView.animate(withDuration: 3.0, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction]) {
            brain.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
        }

        var idx = 1
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let prompt = prompts[idx % prompts.count]
            self.setInstruction(prompt.0, animate: true)
            self.speak(prompt.0)

            // Shift background glow color
            UIView.animate(withDuration: 1.0) {
                bg.backgroundColor = prompt.1
            }
            // Small brain rotation jolt for interactivity
            UIView.animate(withDuration: 0.3, animations: {
                brain.transform = CGAffineTransform(rotationAngle: 0.1).scaledBy(x: 1.15, y: 1.15)
            }) { _ in
                UIView.animate(withDuration: 0.4) {
                    brain.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }
            }
            idx += 1
        }
    }

    // 9. Resonance Humming
    private func sessionResonanceHumming() {
        let rings = Array(animationViews.dropLast())
        let run = { [weak self] in
            guard let self = self else { return }
            // Inhale
            self.setInstruction("Inhale slowly through your nose 🌬", animate: true)
            UIView.animate(withDuration: 4.0) {
                rings.forEach { $0.alpha = 0.15 }
            } completion: { _ in
                // Hum
                self.setInstruction("Hum 'Mmmmmmm'... feel the vibration 🎵", animate: true)
                self.speak("Hum Mmm")
                // Ripple rings outward
                for (i, ring) in rings.enumerated() {
                    UIView.animate(withDuration: 0.8, delay: Double(i) * 0.2, options: [.autoreverse, .repeat]) {
                        ring.alpha = 0.6 - CGFloat(i) * 0.1
                        ring.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    guard let self = self else { return }
                    self.animationViews.forEach { $0.layer.removeAllAnimations(); $0.transform = .identity }
                }
            }
        }
        run()
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 9.0, repeats: true) { _ in run() }
    }

    // 10. Micro Body Reset
    private func sessionMicroBodyReset() {
        guard let fig = animationViews.last, let bg = animationViews.first else { return }
        let moves: [(text: String, icon: String, scale: CGFloat)] = [
            ("Roll your shoulders back slowly 🔄", "arrow.triangle.2.circlepath", 1.0),
            ("Slow, deep breath as you roll 🌬", "wind", 0.9),
            ("Stretch both arms up high 🙌", "arrow.up.left.and.arrow.down.right", 1.15),
            ("Feel the stretch through your spine ✨", "figure.arms.open", 1.1),
            ("Shake out your hands and wrists 👐", "hand.wave", 1.0),
            ("Release all the tension you're holding 🌊", "drop.fill", 0.85),
            ("Take a big deep breath in 💨", "lungs.fill", 1.15),
            ("Exhale with a long sigh — aahhh 😮‍💨", "wind", 0.8),
        ]
        var idx = 0
        setInstruction(moves[0].text, animate: false)
        speak(moves[0].text)

        // Update icon per move
        let updateIcon = { [weak self] (move: (text: String, icon: String, scale: CGFloat)) in
            guard let self = self, let figIV = fig as? UIImageView else { return }
            let cfg = UIImage.SymbolConfiguration(pointSize: 80, weight: .medium)
            UIView.transition(with: figIV, duration: 0.4, options: .transitionCrossDissolve) {
                figIV.image = UIImage(systemName: move.icon, withConfiguration: cfg)
            }
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
                fig.transform = CGAffineTransform(scaleX: move.scale, y: move.scale)
                bg.transform = CGAffineTransform(scaleX: move.scale, y: move.scale)
            }
        }
        updateIcon(moves[0])

        instructionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            idx += 1
            let move = moves[idx % moves.count]
            self.setInstruction(move.text, animate: true)
            self.speak(move.text)
            updateIcon(move)
        }
    }
}
