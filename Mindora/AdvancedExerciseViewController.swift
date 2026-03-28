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
    private var wasRunningBeforeBackground = false  // tracks screen-lock auto-pause
    private var speechSynth: AVSpeechSynthesizer?
    private var audioPlayer: AVAudioPlayer?

    /// Realistic session durations in tenths-of-seconds per exercise
    private var sessionTenths: Int {
        switch exercise?.exerciseType {
        case "physiologicalSigh":   return 1800  // 3 min
        case "coherentBreathing":   return 1800  // 3 min
        case "progressiveMuscle":   return 6000  // 10 min
        case "grounding54321":      return 1800  // 3 min
        case "guidedImagery":       return 1800  // 3 min
        case "boxBreathing":        return 3000  // 5 min
        case "heartBreathing":      return 3000  // 5 min
        default:                    return 1800  // 3 min default
        }
    }

    // MARK: — Animation state
    private var animationPhaseIndex: Int = 0
    private var currentInstructionIndex: Int = 0
    private var instructionItems: [String] = []
    private var guidedStepIndex: Int = 0       // tracks current step across pause/resume
    private var boxPhase: Int = 0              // tracks box breathing dot phase
    private var boxDotLayer: CAShapeLayer?     // CAShapeLayer dot for box breathing
    private var boxSquareSide: CGFloat = 200   // side length of the box square
    private var stepStartTime: Date?           // when current instruction started
    private var currentStepDuration: TimeInterval = 0  // full duration of current step
    private var remainingStepDuration: TimeInterval = 0 // remaining time on pause
    private var resumeShowStep: (() -> Void)?  // stored closure to resume current showStep chain
    private var animationViews: [UIView] = []

    // MARK: — UI
    private let gradientLayer = CAGradientLayer()

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
        navigationController?.setNavigationBarHidden(false, animated: false)
        // Disable swipe-back gesture to prevent accidental exit
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        // Custom back button with quit confirmation (same as BreathingViewController)
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(closeTapped))
        navigationItem.leftBarButtonItem = backButton
        navigationItem.hidesBackButton = true
        
        setupGradient()
        buildLayout()
        configureForExercise()
        setupAudio()
        setupSpeech()
        setupSoundPickerButton()

        // Pause when screen locks (power button), resume when unlocked
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        // Pause exercise automatically when a phone call interrupts
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleAppBackground() {
        if isRunning {
            wasRunningBeforeBackground = true
            pauseSession()
        }
    }

    @objc private func handleAppForeground() {
        if wasRunningBeforeBackground {
            wasRunningBeforeBackground = false
            startSession()
        }
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if type == .began {
                // Phone call started — pause the exercise
                if self.isRunning { self.pauseSession() }
            } else if type == .ended {
                // Call ended — resume automatically
                if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) && !self.isRunning {
                        self.startSession()
                    }
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAll()
        navigationController?.setNavigationBarHidden(false, animated: false)
        // Re-enable swipe-back for other screens
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
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(canvasView)
        view.addSubview(instructionCard)
        instructionCard.addSubview(instructionLabel)
        view.addSubview(timerSlider)
        view.addSubview(currentTimeLabel)
        view.addSubview(totalTimeLabel)
        view.addSubview(playButton)

        // Two equal spacers — one above canvas, one below — so it's always perfectly centred
        // between the subtitle and the instruction card on every screen size.
        let topSpacer    = UILayoutGuide()
        let bottomSpacer = UILayoutGuide()
        view.addLayoutGuide(topSpacer)
        view.addLayoutGuide(bottomSpacer)

        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Play button — pinned to bottom safe area
            playButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 70),
            playButton.heightAnchor.constraint(equalToConstant: 70),

            // Timeline slider — just above play button
            timerSlider.bottomAnchor.constraint(equalTo: playButton.topAnchor, constant: -24),
            timerSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            timerSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Time labels — below slider
            currentTimeLabel.topAnchor.constraint(equalTo: timerSlider.bottomAnchor, constant: 4),
            currentTimeLabel.leadingAnchor.constraint(equalTo: timerSlider.leadingAnchor),
            totalTimeLabel.topAnchor.constraint(equalTo: timerSlider.bottomAnchor, constant: 4),
            totalTimeLabel.trailingAnchor.constraint(equalTo: timerSlider.trailingAnchor),

            // Instruction card — pinned ABOVE the slider so it can never overlap
            instructionCard.bottomAnchor.constraint(equalTo: timerSlider.topAnchor, constant: -16),
            instructionCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            instructionCard.heightAnchor.constraint(equalToConstant: 80),

            instructionLabel.topAnchor.constraint(equalTo: instructionCard.topAnchor, constant: 12),
            instructionLabel.bottomAnchor.constraint(equalTo: instructionCard.bottomAnchor, constant: -12),
            instructionLabel.leadingAnchor.constraint(equalTo: instructionCard.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: instructionCard.trailingAnchor, constant: -16),

            // Equal spacers above and below the canvas → canvas is exactly centred
            topSpacer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor),
            topSpacer.bottomAnchor.constraint(equalTo: canvasView.topAnchor),

            bottomSpacer.topAnchor.constraint(equalTo: canvasView.bottomAnchor),
            bottomSpacer.bottomAnchor.constraint(equalTo: instructionCard.topAnchor),

            topSpacer.heightAnchor.constraint(equalTo: bottomSpacer.heightAnchor),

            // Safety: never let canvas top get closer than 40pt to subtitle (HOLD label clearance)
            canvasView.topAnchor.constraint(greaterThanOrEqualTo: subtitleLabel.bottomAnchor, constant: 40),

            // Canvas: square, max 260pt, min 160pt
            canvasView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            canvasView.widthAnchor.constraint(equalTo: canvasView.heightAnchor),
            canvasView.widthAnchor.constraint(lessThanOrEqualToConstant: 260),
            canvasView.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
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
        let selectedSound = SoundManager.shared.getSelectedSound()
        let fileName = SoundManager.shared.getFileName(for: selectedSound)
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else { 
            print("Audio file not found: \(fileName)")
            return 
        }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.numberOfLoops = -1
        audioPlayer?.volume = 0.5
        // Do NOT play automatically - wait for user to tap play button
    }

    private func setupSpeech() {
        speechSynth = AVSpeechSynthesizer()
    }
    
    private func setupSoundPickerButton() {
        let soundButton = UIBarButtonItem(
            image: UIImage(systemName: "music.note.list"),
            style: .plain,
            target: self,
            action: #selector(showSoundPicker)
        )
        navigationItem.rightBarButtonItem = soundButton
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @objc private func showSoundPicker() {
        let alertController = UIAlertController(
            title: "Select Background Sound",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let allSounds = SoundManager.shared.getAllSounds()
        let selectedSound = SoundManager.shared.getSelectedSound()
        
        for sound in allSounds {
            let action = UIAlertAction(title: sound.rawValue, style: .default) { [weak self] _ in
                self?.changeBGSound(to: sound)
            }
            
            if sound == selectedSound {
                action.setValue(UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysOriginal).withTintColor(.systemBlue), forKey: "image")
            }
            
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alertController, animated: true)
    }
    
    private func changeBGSound(to sound: SoundManager.CalmingSound) {
        // Save preference
        SoundManager.shared.setSelectedSound(sound)
        
        // Get the file name
        let fileName = SoundManager.shared.getFileName(for: sound)
        
        // Stop current audio
        audioPlayer?.stop()
        
        // Load new audio
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.5
            
            // If session is running, play the new sound
            if isRunning {
                audioPlayer?.play()
            }
        } catch {
        }
    }

    private func speak(_ text: String) {
        // Stop speaking asynchronously to avoid blocking
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.speechSynth?.stopSpeaking(at: .immediate)
        }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "en-US")
        u.rate = 0.45
        u.pitchMultiplier = 1.0
        u.volume = 0.8
        DispatchQueue.main.async { [weak self] in
            self?.speechSynth?.speak(u)
        }
    }

    // MARK: — Controls
    @objc private func closeTapped() {
        if hasStartedOnce {
            // Stop everything immediately before showing alert
            stopAll()
            
            let alert = UIAlertController(
                title: "Quit Exercise?",
                message: "Are you sure you want to quit this exercise? Your progress will not be saved.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Yes, Quit", style: .destructive) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            alert.addAction(UIAlertAction(title: "Continue", style: .cancel) { [weak self] _ in
                // Resume the exercise when user taps Continue
                self?.startSession()
            })
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
            UIApplication.shared.isIdleTimerDisabled = true
            updatePlayIcon()
            audioPlayer?.play()

            // Resume CALayer animations on canvas
            for v in animationViews {
                v.layer.resumeAnimation()
                v.subviews.forEach { $0.layer.resumeAnimation() }
            }

            // Resume the current step with remaining time
            if remainingStepDuration > 0.1, let showStep = resumeShowStep {
                instructionTimer?.invalidate()
                instructionTimer = Timer.scheduledTimer(withTimeInterval: remainingStepDuration, repeats: false) { [weak self] _ in
                    guard let self = self, self.isRunning else { return }
                    showStep()
                }
                stepStartTime = Date()
                currentStepDuration = remainingStepDuration
                remainingStepDuration = 0
            } else if let showStep = resumeShowStep {
                showStep()
            } else {
                startExerciseSession()
            }

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
                self.guidedStepIndex = 0
                self.boxPhase = 0
                self.isRunning = true
                self.updatePlayIcon()
                UIApplication.shared.isIdleTimerDisabled = true
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
        UIApplication.shared.isIdleTimerDisabled = false
        updatePlayIcon()
        audioPlayer?.pause()
        mainTimer?.invalidate()
        mainTimer = nil

        // Calculate remaining duration for current step
        if let start = stepStartTime {
            let elapsed = Date().timeIntervalSince(start)
            remainingStepDuration = max(0, currentStepDuration - elapsed)
        }

        instructionTimer?.invalidate()
        instructionTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        // Stop speaking without blocking - use background thread
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.speechSynth?.stopSpeaking(at: .immediate)
        }

        // Pause CALayer animations so dot/orb stays in place
        for v in animationViews {
            v.layer.pauseAnimation()
            v.subviews.forEach { $0.layer.pauseAnimation() }
        }
    }

    private func stopAll() {
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
        mainTimer?.invalidate()
        mainTimer = nil
        instructionTimer?.invalidate()
        instructionTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        audioPlayer?.stop()
        // Don't call stopSpeaking synchronously as it can block the main thread
        // Just let it finish naturally or set a flag
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

        // 1. Data Logic
        let points = 5
        DataManager.shared.addPoints(points)
        DataManager.shared.incrementSessionCount()
        DataManager.shared.updateStreak()

        // Always use lifetime total for stage and butterfly
        let totalSessions = DataManager.shared.getAnalytics().totalSessions
        let stageIndex = totalSessions % 4

        if stageIndex == 0 {
            DataManager.shared.addButterfly()
        }

        // Notify dashboard to refresh
        NotificationCenter.default.post(name: NSNotification.Name("SessionCompletedNotification"), object: nil)

        // 2. Show butterfly popup or simple stage alert
        if stageIndex == 0 {
            showButterflyCelebrationPopup(points: points)
        } else {
            var message = "Great! You've completed your \(exercise.title) exercise.\n\n+\(points) Points Earned! 🏆\n\n"
            switch stageIndex {
            case 1: message += "You have completed Egg stage 🥚"
            case 2: message += "You have completed Caterpillar stage 🐛"
            case 3: message += "You have completed Pupa stage 🫘"
            default: break
            }
            let alert = UIAlertController(title: "Session Complete! 🎉", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigateToMoodScreen()
            })
            present(alert, animated: true)
        }
    }

    // MARK: - Butterfly Celebration Popup (same design as BreathingViewController)
    private func showButterflyCelebrationPopup(points: Int) {
        // Add to the window so it always appears above the gradient canvas
        guard let windowScene = view.window?.windowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
        else { return }

        let overlayView = UIView(frame: window.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0)
        overlayView.tag = 8888
        window.addSubview(overlayView)

        let cardWidth: CGFloat = min(320, view.bounds.width - 48)
        let cardHeight: CGFloat = 360
        let card = UIView(frame: CGRect(x: 0, y: 0, width: cardWidth, height: cardHeight))
        card.center = overlayView.center
        card.layer.cornerRadius = 28
        card.clipsToBounds = true
        card.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        card.alpha = 0
        overlayView.addSubview(card)

        let gradientPairs: [(UIColor, UIColor)] = [
            (UIColor(red: 0.56, green: 0.27, blue: 0.87, alpha: 1.0), UIColor(red: 0.30, green: 0.15, blue: 0.70, alpha: 1.0)),
            (UIColor(red: 0.10, green: 0.38, blue: 0.82, alpha: 1.0), UIColor(red: 0.08, green: 0.26, blue: 0.62, alpha: 1.0)),
            (UIColor(red: 0.08, green: 0.52, blue: 0.44, alpha: 1.0), UIColor(red: 0.20, green: 0.73, blue: 0.60, alpha: 1.0)),
            (UIColor(red: 0.82, green: 0.32, blue: 0.06, alpha: 1.0), UIColor(red: 1.0,  green: 0.584, blue: 0.0, alpha: 1.0)),
            (UIColor(red: 0.72, green: 0.10, blue: 0.30, alpha: 1.0), UIColor(red: 0.52, green: 0.18, blue: 0.72, alpha: 1.0)),
        ]
        let chosenPair = gradientPairs.randomElement()!
        let gradient = CAGradientLayer()
        gradient.colors = [chosenPair.0.cgColor, chosenPair.1.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = card.bounds
        card.layer.insertSublayer(gradient, at: 0)

        let butterflyLabel = UILabel()
        butterflyLabel.text = "🦋"
        butterflyLabel.font = .systemFont(ofSize: 72)
        butterflyLabel.textAlignment = .center
        butterflyLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(butterflyLabel)

        let titleLabel = UILabel()
        titleLabel.text = "Butterfly Grown!"
        titleLabel.font = .systemFont(ofSize: 26, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        let msgLabel = UILabel()
        msgLabel.text = "Congratulations! You've completed all 4 stages and grown a beautiful butterfly!\n\n+\(points) Points Earned 🏆"
        msgLabel.font = .systemFont(ofSize: 15, weight: .medium)
        msgLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        msgLabel.textAlignment = .center
        msgLabel.numberOfLines = 0
        msgLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(msgLabel)

        let continueBtn = UIButton(type: .system)
        continueBtn.setTitle("Continue", for: .normal)
        continueBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        continueBtn.setTitleColor(chosenPair.0, for: .normal)
        continueBtn.backgroundColor = .white
        continueBtn.layer.cornerRadius = 16
        continueBtn.translatesAutoresizingMaskIntoConstraints = false
        continueBtn.addTarget(self, action: #selector(dismissButterflyPopup), for: .touchUpInside)
        card.addSubview(continueBtn)

        NSLayoutConstraint.activate([
            butterflyLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            butterflyLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: butterflyLabel.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            msgLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            msgLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            msgLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            continueBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
            continueBtn.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            continueBtn.widthAnchor.constraint(equalToConstant: 200),
            continueBtn.heightAnchor.constraint(equalToConstant: 50),
        ])

        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8) {
            overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            card.transform = .identity
            card.alpha = 1
        }
        UIView.animate(withDuration: 1.5, delay: 0.5, options: [.repeat, .autoreverse, .allowUserInteraction]) {
            butterflyLabel.transform = CGAffineTransform(translationX: 0, y: -10)
        }
    }

    @objc private func dismissButterflyPopup() {
        let window = view.window ?? UIApplication.shared.windows.first
        guard let overlay = window?.viewWithTag(8888) else {
            navigateToMoodScreen()
            return
        }
        UIView.animate(withDuration: 0.3, animations: {
            overlay.alpha = 0
            overlay.subviews.first?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { [weak self] _ in
            overlay.removeFromSuperview()
            self?.navigateToMoodScreen()
        }
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
        
        // Remove any existing background image from previous exercises
        view.subviews.filter { $0.tag == 9999 }.forEach { $0.removeFromSuperview() }

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

    // 1. Physiological Sigh large breathing orb
    private func buildBreathCircleCanvas(color: UIColor) {
        // Create beautiful expanding waves for Physiological Sigh (double inhale + long exhale)
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        canvasView.addSubview(container)
        pinCenter(container, to: canvasView)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 320),
            container.heightAnchor.constraint(equalToConstant: 320),
        ])
        
        var rings: [UIView] = []
        
        // Create 6 concentric expanding rings with darker, richer colors
        let ringDiameters: [CGFloat] = [60, 100, 140, 180, 220, 260]
        let alphas: [CGFloat] = [1.0, 0.95, 0.85, 0.7, 0.5, 0.3]
        
        // Darken the color for more sophisticated look
        let darkerColor = UIColor(
            red: max(0, (color.cgColor.components?[0] ?? 0) * 0.75),
            green: max(0, (color.cgColor.components?[1] ?? 0) * 0.75),
            blue: max(0, (color.cgColor.components?[2] ?? 0) * 0.75),
            alpha: 1.0
        )
        
        for (index, diameter) in ringDiameters.enumerated() {
            let ring = UIView()
            ring.translatesAutoresizingMaskIntoConstraints = false
            ring.backgroundColor = .clear
            ring.layer.borderWidth = 2.5
            ring.layer.borderColor = darkerColor.withAlphaComponent(alphas[index]).cgColor
            ring.layer.cornerRadius = diameter / 2
            container.addSubview(ring)
            
            NSLayoutConstraint.activate([
                ring.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                ring.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                ring.widthAnchor.constraint(equalToConstant: diameter),
                ring.heightAnchor.constraint(equalToConstant: diameter),
            ])
            
            rings.append(ring)
        }
        
        // Create central core sphere with darker color
        let coreSphere = UIView()
        coreSphere.translatesAutoresizingMaskIntoConstraints = false
        coreSphere.backgroundColor = darkerColor.withAlphaComponent(0.85)
        coreSphere.layer.cornerRadius = 20
        container.addSubview(coreSphere)
        NSLayoutConstraint.activate([
            coreSphere.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            coreSphere.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            coreSphere.widthAnchor.constraint(equalToConstant: 40),
            coreSphere.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        animationViews = rings + [coreSphere]
    }

    // 2. Coherent Breathing glowing orb
    private func buildPulseOrbCanvas(color: UIColor) {
        // Create beautiful flower petal pattern (like the image you showed)
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        canvasView.addSubview(container)
        pinCenter(container, to: canvasView)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 280),
            container.heightAnchor.constraint(equalToConstant: 280),
        ])
        
        var petalLayers: [UIView] = []
        
        // Create 6 flower petals arranged in a circle
        let petalDiameter: CGFloat = 80
        let petalRadius: CGFloat = 70  // Distance from center to petal center
        
        // Darker, more saturated colors for better contrast
        let darkerColor = UIColor(
            red: max(0, color.cgColor.components?[0] ?? 0 - 0.2),
            green: max(0, color.cgColor.components?[1] ?? 0 - 0.2),
            blue: max(0, color.cgColor.components?[2] ?? 0 - 0.2),
            alpha: 0.85
        )
        
        for i in 0..<6 {
            let angle = CGFloat(i) * (2 * .pi / 6)  // 60 degrees apart
            let xOffset = petalRadius * cos(angle)
            let yOffset = petalRadius * sin(angle)
            
            let petal = UIView()
            petal.translatesAutoresizingMaskIntoConstraints = false
            petal.backgroundColor = darkerColor
            petal.layer.cornerRadius = petalDiameter / 2
            petal.layer.shadowColor = darkerColor.cgColor
            petal.layer.shadowRadius = 20
            petal.layer.shadowOpacity = 0.7
            petal.tag = 2000 + i
            container.addSubview(petal)
            
            NSLayoutConstraint.activate([
                petal.centerXAnchor.constraint(equalTo: container.centerXAnchor, constant: xOffset),
                petal.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: yOffset),
                petal.widthAnchor.constraint(equalToConstant: petalDiameter),
                petal.heightAnchor.constraint(equalToConstant: petalDiameter),
            ])
            
            petalLayers.append(petal)
        }
        
        // Create central bright core that glows
        let core = UIView()
        core.translatesAutoresizingMaskIntoConstraints = false
        core.backgroundColor = darkerColor
        core.layer.cornerRadius = 25
        core.layer.shadowColor = darkerColor.cgColor
        core.layer.shadowRadius = 30
        core.layer.shadowOpacity = 0.9
        container.addSubview(core)
        NSLayoutConstraint.activate([
            core.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            core.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            core.widthAnchor.constraint(equalToConstant: 50),
            core.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        // animationViews: [6 petals + core]
        animationViews = petalLayers + [core]
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

    // 4. Body Scan Relaxation — glowing orb
    private func buildGroundingCanvas() {
        // Create animated body figure for body scan
        let bodyContainer = UIView()
        bodyContainer.translatesAutoresizingMaskIntoConstraints = false
        canvasView.addSubview(bodyContainer)
        pinCenter(bodyContainer, to: canvasView)
        NSLayoutConstraint.activate([
            bodyContainer.widthAnchor.constraint(equalToConstant: 280),
            bodyContainer.heightAnchor.constraint(equalToConstant: 350),
        ])
        
        // Head (top)
        let head = UIView()
        head.translatesAutoresizingMaskIntoConstraints = false
        head.backgroundColor = UIColor(red:0.98,green:0.92,blue:0.85,alpha:1)
        head.layer.cornerRadius = 20
        bodyContainer.addSubview(head)
        NSLayoutConstraint.activate([
            head.topAnchor.constraint(equalTo: bodyContainer.topAnchor, constant: 10),
            head.centerXAnchor.constraint(equalTo: bodyContainer.centerXAnchor),
            head.widthAnchor.constraint(equalToConstant: 50),
            head.heightAnchor.constraint(equalToConstant: 55),
        ])
        
        // Neck
        let neck = UIView()
        neck.translatesAutoresizingMaskIntoConstraints = false
        neck.backgroundColor = UIColor(red:0.98,green:0.92,blue:0.85,alpha:1)
        bodyContainer.addSubview(neck)
        NSLayoutConstraint.activate([
            neck.topAnchor.constraint(equalTo: head.bottomAnchor),
            neck.centerXAnchor.constraint(equalTo: bodyContainer.centerXAnchor),
            neck.widthAnchor.constraint(equalToConstant: 16),
            neck.heightAnchor.constraint(equalToConstant: 12),
        ])
        
        // Shoulders and Chest
        let chest = UIView()
        chest.translatesAutoresizingMaskIntoConstraints = false
        chest.backgroundColor = UIColor(red:0.98,green:0.92,blue:0.85,alpha:0.9)
        chest.layer.cornerRadius = 8
        bodyContainer.addSubview(chest)
        NSLayoutConstraint.activate([
            chest.topAnchor.constraint(equalTo: neck.bottomAnchor),
            chest.centerXAnchor.constraint(equalTo: bodyContainer.centerXAnchor),
            chest.widthAnchor.constraint(equalToConstant: 80),
            chest.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        // Left Arm
        let leftArm = UIView()
        leftArm.translatesAutoresizingMaskIntoConstraints = false
        leftArm.backgroundColor = UIColor(red:0.98,green:0.92,blue:0.85,alpha:0.85)
        leftArm.layer.cornerRadius = 8
        bodyContainer.addSubview(leftArm)
        NSLayoutConstraint.activate([
            leftArm.centerYAnchor.constraint(equalTo: chest.centerYAnchor),
            leftArm.trailingAnchor.constraint(equalTo: chest.leadingAnchor, constant: -5),
            leftArm.widthAnchor.constraint(equalToConstant: 18),
            leftArm.heightAnchor.constraint(equalToConstant: 55),
        ])
        
        // Right Arm
        let rightArm = UIView()
        rightArm.translatesAutoresizingMaskIntoConstraints = false
        rightArm.backgroundColor = UIColor(red:0.98,green:0.92,blue:0.85,alpha:0.85)
        rightArm.layer.cornerRadius = 8
        bodyContainer.addSubview(rightArm)
        NSLayoutConstraint.activate([
            rightArm.centerYAnchor.constraint(equalTo: chest.centerYAnchor),
            rightArm.leadingAnchor.constraint(equalTo: chest.trailingAnchor, constant: 5),
            rightArm.widthAnchor.constraint(equalToConstant: 18),
            rightArm.heightAnchor.constraint(equalToConstant: 55),
        ])
        
        // Stomach
        let stomach = UIView()
        stomach.translatesAutoresizingMaskIntoConstraints = false
        stomach.backgroundColor = UIColor(red:0.98,green:0.92,blue:0.85,alpha:0.85)
        stomach.layer.cornerRadius = 8
        bodyContainer.addSubview(stomach)
        NSLayoutConstraint.activate([
            stomach.topAnchor.constraint(equalTo: chest.bottomAnchor, constant: 5),
            stomach.centerXAnchor.constraint(equalTo: bodyContainer.centerXAnchor),
            stomach.widthAnchor.constraint(equalToConstant: 60),
            stomach.heightAnchor.constraint(equalToConstant: 45),
        ])
        
        // Left Leg
        let leftLeg = UIView()
        leftLeg.translatesAutoresizingMaskIntoConstraints = false
        leftLeg.backgroundColor = UIColor(red:0.98,green:0.92,blue:0.85,alpha:0.8)
        leftLeg.layer.cornerRadius = 8
        bodyContainer.addSubview(leftLeg)
        NSLayoutConstraint.activate([
            leftLeg.topAnchor.constraint(equalTo: stomach.bottomAnchor, constant: 8),
            leftLeg.trailingAnchor.constraint(equalTo: bodyContainer.centerXAnchor, constant: -8),
            leftLeg.widthAnchor.constraint(equalToConstant: 16),
            leftLeg.heightAnchor.constraint(equalToConstant: 70),
        ])
        
        // Right Leg
        let rightLeg = UIView()
        rightLeg.translatesAutoresizingMaskIntoConstraints = false
        rightLeg.backgroundColor = UIColor(red:0.98,green:0.92,blue:0.85,alpha:0.8)
        rightLeg.layer.cornerRadius = 8
        bodyContainer.addSubview(rightLeg)
        NSLayoutConstraint.activate([
            rightLeg.topAnchor.constraint(equalTo: stomach.bottomAnchor, constant: 8),
            rightLeg.leadingAnchor.constraint(equalTo: bodyContainer.centerXAnchor, constant: 8),
            rightLeg.widthAnchor.constraint(equalToConstant: 16),
            rightLeg.heightAnchor.constraint(equalToConstant: 70),
        ])
        
        // Left Foot
        let leftFoot = UIView()
        leftFoot.translatesAutoresizingMaskIntoConstraints = false
        leftFoot.backgroundColor = UIColor(red:0.98,green:0.92,blue:0.85,alpha:0.8)
        leftFoot.layer.cornerRadius = 6
        bodyContainer.addSubview(leftFoot)
        NSLayoutConstraint.activate([
            leftFoot.topAnchor.constraint(equalTo: leftLeg.bottomAnchor, constant: 3),
            leftFoot.centerXAnchor.constraint(equalTo: leftLeg.centerXAnchor),
            leftFoot.widthAnchor.constraint(equalToConstant: 22),
            leftFoot.heightAnchor.constraint(equalToConstant: 12),
        ])
        
        // Right Foot
        let rightFoot = UIView()
        rightFoot.translatesAutoresizingMaskIntoConstraints = false
        rightFoot.backgroundColor = UIColor(red:0.98,green:0.92,blue:0.85,alpha:0.8)
        rightFoot.layer.cornerRadius = 6
        bodyContainer.addSubview(rightFoot)
        NSLayoutConstraint.activate([
            rightFoot.topAnchor.constraint(equalTo: rightLeg.bottomAnchor, constant: 3),
            rightFoot.centerXAnchor.constraint(equalTo: rightLeg.centerXAnchor),
            rightFoot.widthAnchor.constraint(equalToConstant: 22),
            rightFoot.heightAnchor.constraint(equalToConstant: 12),
        ])
        
        // animationViews: [head, neck, chest, leftArm, rightArm, stomach, leftLeg, rightLeg, leftFoot, rightFoot]
        animationViews = [head, neck, chest, leftArm, rightArm, stomach, leftLeg, rightLeg, leftFoot, rightFoot]
    }

    // 5. Guided Imagery mountain + sun
    private func buildImageryCanvas() {
        // Add nature image as full-screen background behind everything
        let backgroundImage = UIImageView()
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.image = UIImage(named: "nature")
        backgroundImage.contentMode = .scaleAspectFill
        backgroundImage.clipsToBounds = true
        backgroundImage.tag = 9999  // Tag to identify and remove later
        view.insertSubview(backgroundImage, belowSubview: titleLabel)
        
        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        // Subtle overlay for better text readability
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        overlay.tag = 9999  // Same tag for cleanup
        view.insertSubview(overlay, belowSubview: titleLabel)
        
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        // Make canvas view transparent
        canvasView.backgroundColor = .clear
        
        // animationViews: [backgroundImage, overlay]
        animationViews = [backgroundImage, overlay]
    }

    // 6. Box Breathing animated square with traveling dot
    private func buildBoxCanvas() {
        let side: CGFloat = 200
        let square = UIView()
        square.translatesAutoresizingMaskIntoConstraints = false
        square.layer.borderWidth = 3
        square.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        square.layer.cornerRadius = 4
        square.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        canvasView.addSubview(square)
        NSLayoutConstraint.activate([
            square.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor),
            square.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor),
            square.widthAnchor.constraint(equalToConstant: side),
            square.heightAnchor.constraint(equalToConstant: side),
        ])

        // Labels around the square
        // Left: INHALE
        let inhaleLabel = UILabel()
        inhaleLabel.translatesAutoresizingMaskIntoConstraints = false
        inhaleLabel.text = "INHALE"
        inhaleLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        inhaleLabel.textColor = .white
        canvasView.addSubview(inhaleLabel)
        NSLayoutConstraint.activate([
            inhaleLabel.centerYAnchor.constraint(equalTo: square.centerYAnchor),
            inhaleLabel.trailingAnchor.constraint(equalTo: square.leadingAnchor, constant: -12),
        ])

        // Top: HOLD
        let holdTopLabel = UILabel()
        holdTopLabel.translatesAutoresizingMaskIntoConstraints = false
        holdTopLabel.text = "HOLD"
        holdTopLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        holdTopLabel.textColor = .white
        canvasView.addSubview(holdTopLabel)
        NSLayoutConstraint.activate([
            holdTopLabel.centerXAnchor.constraint(equalTo: square.centerXAnchor),
            holdTopLabel.bottomAnchor.constraint(equalTo: square.topAnchor, constant: -10),
        ])

        // Right: EXHALE
        let exhaleLabel = UILabel()
        exhaleLabel.translatesAutoresizingMaskIntoConstraints = false
        exhaleLabel.text = "EXHALE"
        exhaleLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        exhaleLabel.textColor = .white
        canvasView.addSubview(exhaleLabel)
        NSLayoutConstraint.activate([
            exhaleLabel.centerYAnchor.constraint(equalTo: square.centerYAnchor),
            exhaleLabel.leadingAnchor.constraint(equalTo: square.trailingAnchor, constant: 12),
        ])

        // Bottom: HOLD
        let holdBottomLabel = UILabel()
        holdBottomLabel.translatesAutoresizingMaskIntoConstraints = false
        holdBottomLabel.text = "HOLD"
        holdBottomLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        holdBottomLabel.textColor = .white
        canvasView.addSubview(holdBottomLabel)
        NSLayoutConstraint.activate([
            holdBottomLabel.centerXAnchor.constraint(equalTo: square.centerXAnchor),
            holdBottomLabel.topAnchor.constraint(equalTo: square.bottomAnchor, constant: 10),
        ])

        // Lungs icon in the center
        let lungs = UIImageView()
        lungs.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 60, weight: .regular)
        lungs.image = UIImage(systemName: "lungs.fill", withConfiguration: cfg)
        lungs.tintColor = UIColor.white.withAlphaComponent(0.6)
        lungs.contentMode = .scaleAspectFit
        canvasView.addSubview(lungs)
        NSLayoutConstraint.activate([
            lungs.centerXAnchor.constraint(equalTo: square.centerXAnchor),
            lungs.centerYAnchor.constraint(equalTo: square.centerYAnchor),
        ])

        // CAShapeLayer dot for traveling — added to square's layer
        let dotRadius: CGFloat = 10
        let dotLayer = CAShapeLayer()
        dotLayer.path = UIBezierPath(ovalIn: CGRect(x: -dotRadius, y: -dotRadius,
                                                     width: dotRadius * 2, height: dotRadius * 2)).cgPath
        dotLayer.fillColor = UIColor.white.cgColor
        dotLayer.shadowColor = UIColor.white.cgColor
        dotLayer.shadowRadius = 8
        dotLayer.shadowOpacity = 1
        dotLayer.shadowOffset = .zero
        dotLayer.position = CGPoint(x: 0, y: side)  // start at bottom-left
        square.layer.addSublayer(dotLayer)
        boxDotLayer = dotLayer

        animationViews = [square]
    }

    // 7. Heart Breathing pulsing heart - Optimized for Performance
    private func buildHeartCanvas() {
        // Vibrant deep red for maximum visibility
        let deepRed = UIColor(red: 0.9, green: 0.1, blue: 0.2, alpha: 1)
        let brightRed = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1)
        let lightGlow = UIColor(red: 1.0, green: 0.5, blue: 0.6, alpha: 1)

        // --- Particle emitter: warm glowing particles radiating from the heart ---
        let emitterContainer = UIView()
        emitterContainer.translatesAutoresizingMaskIntoConstraints = false
        emitterContainer.isUserInteractionEnabled = false
        canvasView.addSubview(emitterContainer)
        NSLayoutConstraint.activate([
            emitterContainer.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor),
            emitterContainer.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor, constant: -20),
            emitterContainer.widthAnchor.constraint(equalToConstant: 300),
            emitterContainer.heightAnchor.constraint(equalToConstant: 300),
        ])

        // Create emitter after layout - on background thread
        DispatchQueue.main.async {
            let emitter = CAEmitterLayer()
            emitter.emitterPosition = CGPoint(x: 150, y: 150)
            emitter.emitterSize = CGSize(width: 40, height: 40)
            emitter.emitterShape = .circle
            emitter.renderMode = .additive

            let cell = CAEmitterCell()
            cell.birthRate = 8
            cell.lifetime = 4.0
            cell.velocity = 30
            cell.velocityRange = 18
            cell.emissionRange = .pi * 2
            cell.scale = 0.08
            cell.scaleRange = 0.04
            cell.scaleSpeed = -0.01
            cell.alphaSpeed = -0.22
            cell.color = brightRed.withAlphaComponent(0.9).cgColor

            // Larger, more visible particles
            let size: CGFloat = 16
            UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
            brightRed.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()
            cell.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
            UIGraphicsEndImageContext()

            emitter.emitterCells = [cell]
            emitterContainer.layer.addSublayer(emitter)
        }

        // --- Three concentric bold rings - SIMPLIFIED for performance ---
        let ringData: [(CGFloat, CGFloat, CGFloat)] = [
            (280, 0.4, 2.5),   // outer ring
            (240, 0.55, 2.0),  // middle ring
            (195, 0.7, 1.5)    // inner ring
        ]
        var ringViews: [UIView] = []
        for (i, (diameter, alpha, borderWidth)) in ringData.enumerated() {
            let ring = UIView()
            ring.translatesAutoresizingMaskIntoConstraints = false
            ring.backgroundColor = .clear
            ring.layer.cornerRadius = diameter / 2
            ring.layer.borderWidth = borderWidth
            ring.layer.borderColor = brightRed.withAlphaComponent(alpha).cgColor
            ring.layer.shouldRasterize = false  // Don't rasterize to keep animations smooth
            
            canvasView.addSubview(ring)
            NSLayoutConstraint.activate([
                ring.widthAnchor.constraint(equalToConstant: diameter),
                ring.heightAnchor.constraint(equalToConstant: diameter),
                ring.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor),
                ring.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor, constant: -20),
            ])
            ringViews.append(ring)

            // Continuous pulse animation on each ring (staggered)
            UIView.animate(withDuration: 2.5, delay: Double(i) * 0.4,
                           options: [.repeat, .autoreverse, .curveEaseInOut]) {
                ring.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
        }

        // --- Bright radial glow - SIMPLIFIED ---
        let glowOuter = UIView()
        glowOuter.translatesAutoresizingMaskIntoConstraints = false
        glowOuter.backgroundColor = lightGlow.withAlphaComponent(0.35)
        glowOuter.layer.cornerRadius = 85
        glowOuter.layer.shouldRasterize = false
        
        canvasView.addSubview(glowOuter)
        NSLayoutConstraint.activate([
            glowOuter.widthAnchor.constraint(equalToConstant: 170),
            glowOuter.heightAnchor.constraint(equalToConstant: 170),
            glowOuter.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor),
            glowOuter.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor, constant: -20),
        ])

        let glowInner = UIView()
        glowInner.translatesAutoresizingMaskIntoConstraints = false
        glowInner.backgroundColor = lightGlow.withAlphaComponent(0.6)
        glowInner.layer.cornerRadius = 60
        glowInner.layer.shouldRasterize = false
        
        canvasView.addSubview(glowInner)
        NSLayoutConstraint.activate([
            glowInner.widthAnchor.constraint(equalToConstant: 120),
            glowInner.heightAnchor.constraint(equalToConstant: 120),
            glowInner.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor),
            glowInner.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor, constant: -20),
        ])

        // Continuous glow breathing
        UIView.animate(withDuration: 3.0, delay: 0,
                       options: [.repeat, .autoreverse, .curveEaseInOut]) {
            glowOuter.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            glowOuter.alpha = 0.5
            glowInner.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            glowInner.alpha = 0.7
        }

        // --- Heart icon - SIMPLIFIED (no heavy shadows) ---
        let heartView = UIImageView()
        heartView.translatesAutoresizingMaskIntoConstraints = false
        let cfg = UIImage.SymbolConfiguration(pointSize: 100, weight: .semibold)
        heartView.image = UIImage(systemName: "heart.fill", withConfiguration: cfg)
        heartView.tintColor = brightRed
        heartView.contentMode = .scaleAspectFit
        
        canvasView.addSubview(heartView)
        NSLayoutConstraint.activate([
            heartView.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor),
            heartView.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor, constant: -20),
        ])

        // animationViews: [ring0, ring1, ring2, glowOuter, glowInner, emitterContainer, heartView]
        animationViews = ringViews + [glowOuter, glowInner, emitterContainer, heartView]
    }
}

// MARK: - Exercise Session Logic
extension AdvancedExerciseViewController {

    private func startExerciseSession() {       switch exercise.exerciseType {
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
        // Store items for potential resume
        instructionItems = items
        currentInstructionIndex = 0
        
        if immediate {
            setInstruction(items[0], animate: false)
            speak(items[0])
            currentInstructionIndex = 1
        }
        
        instructionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let text = items[self.currentInstructionIndex % items.count]
            self.setInstruction(text, animate: true)
            self.speak(text)
            self.currentInstructionIndex += 1
        }
    }

    // 1. Physiological Sigh — Guided Flow (3 min)
    private func sessionPhysiologicalSigh() {
        guard animationViews.count >= 7 else { return }  // 6 rings + 1 core
        
        // Reset all rings to starting position
        for view in animationViews {
            view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }

        // (text, duration, phase: "rest", "inhale", "topup", "exhale")
        let steps: [(String, TimeInterval, String)] = [
            ("Find a quiet spot — sit upright or lie down comfortably", 5.0, "rest"),
            ("Let your jaw unclench and your shoulders drop", 3.0, "rest"),
            ("Take a slow breath in", 4.0, "inhale"),
            ("And exhale gently", 6.0, "exhale"),
            ("Now begin", 2.0, "rest"),
            ("Inhale slowly through your nose", 4.0, "inhale"),
            ("Take a second gentle sip of air in", 2.0, "topup"),
            ("Exhale slowly through your mouth", 6.0, "exhale"),
            ("Inhale", 4.0, "inhale"),
            ("Second gentle inhale", 2.0, "topup"),
            ("Exhale slowly", 6.0, "exhale"),
            ("Continue this calming rhythm", 3.0, "rest"),
            ("Inhale", 4.0, "inhale"),
            ("Second gentle inhale", 2.0, "topup"),
            ("Exhale slowly", 6.0, "exhale"),
            ("Inhale", 4.0, "inhale"),
            ("Second gentle inhale", 2.0, "topup"),
            ("Exhale slowly", 6.0, "exhale"),
            ("Let your shoulders drop as you exhale", 5.0, "rest"),
            ("Inhale", 4.0, "inhale"),
            ("Second gentle inhale", 2.0, "topup"),
            ("Exhale slowly", 6.0, "exhale"),
            ("Inhale", 4.0, "inhale"),
            ("Second gentle inhale", 2.0, "topup"),
            ("Exhale slowly", 6.0, "exhale"),
            ("Stay with this steady rhythm", 3.0, "rest"),
            ("Inhale", 4.0, "inhale"),
            ("Second gentle inhale", 2.0, "topup"),
            ("Exhale slowly", 6.0, "exhale"),
            ("Inhale", 4.0, "inhale"),
            ("Second gentle inhale", 2.0, "topup"),
            ("Exhale slowly", 6.0, "exhale"),
            ("Feel your body relaxing more with each breath", 5.0, "rest"),
            ("Inhale", 4.0, "inhale"),
            ("Second gentle inhale", 2.0, "topup"),
            ("Exhale slowly", 6.0, "exhale"),
            ("Inhale", 4.0, "inhale"),
            ("Second gentle inhale", 2.0, "topup"),
            ("Exhale slowly", 6.0, "exhale"),
            ("Continue at your own pace", 5.0, "rest"),
            ("Inhale", 4.0, "inhale"),
            ("Second gentle inhale", 2.0, "topup"),
            ("Exhale slowly", 6.0, "exhale"),
            ("Take one final deep breath in", 4.0, "inhale"),
            ("Second gentle inhale", 2.0, "topup"),
            ("Exhale slowly and completely", 6.0, "exhale"),
            ("Notice your body feeling calm and relaxed", 6.0, "rest"),
            ("Slowly bring your awareness back", 4.0, "rest"),
            ("Gently open your eyes", 3.0, "rest"),
        ]

        func showStep() {
            guard self.isRunning else { return }
            let (text, duration, phase) = steps[self.guidedStepIndex % steps.count]
            self.setInstruction(text, animate: self.guidedStepIndex > 0)
            self.speak(text)

            // Animate rings based on breathing phase
            let animDuration = min(duration, 2.0)
            
            if phase == "inhale" {
                // Rings expand to 1.25x during first inhale (4s)
                UIView.animate(withDuration: animDuration, delay: 0, options: .curveEaseInOut, animations: {
                    for (idx, view) in self.animationViews.enumerated() {
                        if idx < 6 {  // Rings (all 6)
                            view.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                        } else {  // Core sphere
                            view.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
                        }
                    }
                })
            } else if phase == "topup" {
                // Rings expand to maximum 1.38x for top-up inhale (1s sharp)
                UIView.animate(withDuration: min(duration, 1.2), delay: 0, options: .curveEaseOut, animations: {
                    for (idx, view) in self.animationViews.enumerated() {
                        if idx < 6 {  // Rings (all 6)
                            view.transform = CGAffineTransform(scaleX: 1.38, y: 1.38)
                        } else {  // Core sphere
                            view.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
                        }
                    }
                })
            } else if phase == "exhale" {
                // Rings contract smoothly back to 1.0x during exhale (6s)
                UIView.animate(withDuration: animDuration, delay: 0, options: .curveEaseInOut, animations: {
                    for (idx, view) in self.animationViews.enumerated() {
                        if idx < 6 {  // Rings (all 6)
                            view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                        } else {  // Core sphere
                            view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                        }
                    }
                })
            } else {
                // Rest phase - neutral position
                UIView.animate(withDuration: animDuration, delay: 0, options: .curveEaseOut, animations: {
                    for view in self.animationViews {
                        view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
                })
            }

            self.stepStartTime = Date()
            self.currentStepDuration = duration
            self.resumeShowStep = showStep
            self.guidedStepIndex += 1

            self.instructionTimer?.invalidate()
            self.instructionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                showStep()
            }
        }

        showStep()
    }

    // 2. Coherent Breathing — Guided Flow (3 min)
    private func sessionCoherentBreathing() {
        guard animationViews.count >= 7 else { return }
        
        let petals = Array(animationViews[0..<6])  // 6 flower petals
        let core = animationViews[6]  // Central core

        // Set initial state - all petals contracted
        for petal in petals {
            petal.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }
        core.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)

        // (text, duration in seconds, inhale?)
        let steps: [(String, TimeInterval, Bool)] = [
            ("Sit in a relaxed position with your spine gently tall", 5.0, false),
            ("Rest your hands on your knees, palms facing up", 3.0, false),
            ("Take a slow breath in", 5.0, true),
            ("And exhale gently", 5.0, false),
            ("Now begin a steady rhythm", 3.0, false),
            ("Inhale slowly through your nose", 5.0, true),
            ("Exhale slowly through your mouth", 5.0, false),
            ("Inhale", 5.0, true),
            ("Exhale", 5.0, false),
            ("Continue this smooth rhythm", 3.0, false),
            ("Inhale", 5.0, true),
            ("Exhale", 5.0, false),
            ("Inhale", 5.0, true),
            ("Exhale", 5.0, false),
            ("Let your breathing stay calm and even", 5.0, false),
            ("Inhale", 5.0, true),
            ("Exhale", 5.0, false),
            ("Inhale", 5.0, true),
            ("Exhale", 5.0, false),
            ("Stay with this steady flow", 3.0, false),
            ("Inhale", 5.0, true),
            ("Exhale", 5.0, false),
            ("Inhale", 5.0, true),
            ("Exhale", 5.0, false),
            ("Feel your body relaxing with each breath", 5.0, false),
            ("Inhale", 5.0, true),
            ("Exhale", 5.0, false),
            ("Inhale", 5.0, true),
            ("Exhale", 5.0, false),
            ("Continue at your own pace", 5.0, false),
            ("Inhale", 5.0, true),
            ("Exhale", 5.0, false),
            ("Take one final deep breath in", 5.0, true),
            ("And exhale slowly", 5.0, false),
            ("Notice your body feeling calm and steady", 6.0, false),
            ("Slowly bring your awareness back", 4.0, false),
            ("Gently open your eyes", 3.0, false),
        ]

        func showStep() {
            guard self.isRunning else { return }
            let (text, duration, isInhale) = steps[self.guidedStepIndex % steps.count]
            self.setInstruction(text, animate: self.guidedStepIndex > 0)
            self.speak(text)

            if isInhale {
                // INHALE - All petals expand outward like a blooming flower
                for (index, petal) in petals.enumerated() {
                    UIView.animate(withDuration: duration, delay: Double(index) * 0.08, options: .curveEaseInOut) {
                        petal.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
                }
                
                // Core expands and glows brighter
                UIView.animate(withDuration: duration, delay: 0.2, options: .curveEaseInOut) {
                    core.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                }
                
            } else {
                // EXHALE - All petals contract inward, like closing petals
                for (index, petal) in petals.enumerated() {
                    UIView.animate(withDuration: duration, delay: Double(index) * 0.08, options: .curveEaseInOut) {
                        petal.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    }
                }
                
                // Core contracts gently
                UIView.animate(withDuration: duration, delay: 0.2, options: .curveEaseInOut) {
                    core.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                }
            }

            self.stepStartTime = Date()
            self.currentStepDuration = duration
            self.resumeShowStep = showStep
            self.guidedStepIndex += 1

            self.instructionTimer?.invalidate()
            self.instructionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                showStep()
            }
        }

        showStep()
    }

    // 3. Progressive Muscle Release — Complete Guided Flow (10 min)
    private func sessionProgressiveMuscle() {
        // (text, duration in seconds, tense animation?)
        let steps: [(String, TimeInterval, Bool)] = [
            ("Lie down on a comfortable surface — bed or floor", 8.0, false),
            ("Uncross your arms and legs, let them rest naturally", 5.0, false),
            ("Take a slow deep breath in", 4.0, false),
            ("And exhale gently", 6.0, false),
            ("Allow your body to begin relaxing", 6.0, false),
            // Feet
            ("Tense your feet and curl your toes", 5.0, true),
            ("Hold the tension, feel it", 5.0, true),
            ("Release and relax completely", 10.0, false),
            // Calves
            ("Continue the same rhythm for your calves", 3.0, false),
            ("Tense your calves", 5.0, true),
            ("Hold the tension", 5.0, true),
            ("Release and relax completely", 10.0, false),
            // Thighs
            ("Continue the same rhythm for your thighs", 3.0, false),
            ("Tense your thighs", 5.0, true),
            ("Hold the tension", 5.0, true),
            ("Release and relax completely", 10.0, false),
            // Hips & Glutes
            ("Continue the same rhythm for your hips and glutes", 3.0, false),
            ("Tense your hips and glutes", 5.0, true),
            ("Hold the tension", 5.0, true),
            ("Release and relax completely", 10.0, false),
            // Stomach
            ("Continue the same rhythm for your stomach", 3.0, false),
            ("Tighten your stomach muscles", 5.0, true),
            ("Hold the tension", 5.0, true),
            ("Release and relax completely", 10.0, false),
            // Chest
            ("Continue the same rhythm for your chest", 3.0, false),
            ("Take a deep breath and hold tension in your chest", 5.0, true),
            ("Hold", 5.0, true),
            ("Relax completely", 10.0, false),
            // Hands
            ("Continue the same rhythm for your hands", 3.0, false),
            ("Make fists and tense your hands", 5.0, true),
            ("Hold the tension", 5.0, true),
            ("Release and relax completely", 10.0, false),
            // Arms
            ("Continue the same rhythm for your arms", 3.0, false),
            ("Tense your arms", 5.0, true),
            ("Hold the tension", 5.0, true),
            ("Release and relax completely", 10.0, false),
            // Shoulders
            ("Continue the same rhythm for your shoulders", 3.0, false),
            ("Raise your shoulders towards your ears", 5.0, true),
            ("Hold the tension", 5.0, true),
            ("Release and relax completely", 10.0, false),
            // Neck
            ("Continue the same rhythm for your neck", 3.0, false),
            ("Gently tense your neck", 5.0, true),
            ("Hold the tension", 5.0, true),
            ("Release and relax completely", 10.0, false),
            // Face
            ("Continue the same rhythm for your face", 3.0, false),
            ("Scrunch your eyes and jaw", 5.0, true),
            ("Hold the tension", 5.0, true),
            ("Release and relax completely", 10.0, false),
            // Cool-down
            ("Now take a slow deep breath in", 4.0, false),
            ("And exhale gently", 6.0, false),
            ("Feel your whole body deeply relaxed", 15.0, false),
            ("Let go of any remaining tension", 15.0, false),
            ("Stay in this calm and peaceful state", 20.0, false),
            ("Slowly bring your awareness back to your surroundings", 8.0, false),
            ("Gently move your fingers and toes", 8.0, false),
            ("And when you're ready, slowly open your eyes", 5.0, false),
        ]

        func showStep() {
            guard self.isRunning else { return }
            let (text, duration, tense) = steps[self.guidedStepIndex % steps.count]
            self.setInstruction(text, animate: self.guidedStepIndex > 0)
            self.speak(text)
            self.pulseAnimViews(tense: tense)
            self.stepStartTime = Date()
            self.currentStepDuration = duration
            self.resumeShowStep = showStep
            self.guidedStepIndex += 1

            self.instructionTimer?.invalidate()
            self.instructionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                showStep()
            }
        }

        showStep()
    }

    private func pulseAnimViews(tense: Bool) {
        if tense {
            UIView.animate(withDuration: 0.4) { self.animationViews.forEach { $0.transform = CGAffineTransform(scaleX: 1.15, y: 1.15) } }
        } else {
            UIView.animate(withDuration: 0.7) { self.animationViews.forEach { $0.transform = .identity } }
        }
    }

    // 4. Body Scan Relaxation — Guided Flow (3 min)
    private func sessionGrounding() {
        guard animationViews.count >= 10 else { return }
        let head = animationViews[0]
        let neck = animationViews[1]
        let chest = animationViews[2]
        let leftArm = animationViews[3]
        let rightArm = animationViews[4]
        let stomach = animationViews[5]
        let leftLeg = animationViews[6]
        let rightLeg = animationViews[7]
        let leftFoot = animationViews[8]
        let rightFoot = animationViews[9]
        
        // Reset all body parts to normal state
        func resetAllParts() {
            [head, neck, chest, leftArm, rightArm, stomach, leftLeg, rightLeg, leftFoot, rightFoot].forEach {
                $0.backgroundColor = UIColor(red:0.98,green:0.92,blue:0.85,alpha:$0 == head ? 1.0 : ($0 == leftArm || $0 == rightArm ? 0.85 : ($0 == leftLeg || $0 == rightLeg || $0 == leftFoot || $0 == rightFoot ? 0.8 : 0.9)))
                $0.layer.borderWidth = 0
                $0.transform = .identity
            }
        }
        
        // Highlight a body part with glow and subtle animation
        func highlightPart(_ part: UIView, with color: UIColor) {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                part.backgroundColor = color
                part.layer.borderWidth = 2
                part.layer.borderColor = color.cgColor
                part.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            }
        }
        
        // Golden yellow highlight color
        let highlightColor = UIColor(red:0.98,green:0.84,blue:0.30,alpha:0.8)

        let steps: [(String, TimeInterval, [UIView]?)] = [
            ("Lie down flat, arms resting gently at your sides", 5.0, nil),
            ("Feel the surface beneath you supporting your whole body", 3.0, nil),
            ("Take a slow deep breath in", 4.0, nil),
            ("And exhale gently", 6.0, nil),
            ("Now begin", 2.0, nil),
            ("Bring your attention to your feet, notice any sensations", 8.0, [leftFoot, rightFoot]),
            ("Slowly move your awareness to your calves, let them relax", 8.0, [leftLeg, rightLeg]),
            ("Now bring your attention to your thighs, feel them soften", 8.0, [leftLeg, rightLeg]),
            ("Bring your awareness to your hips and lower body, release any tension", 8.0, [leftLeg, rightLeg]),
            ("Now focus on your stomach and chest, notice your breathing", 8.0, [stomach, chest]),
            ("Bring attention to your hands and arms, let them feel heavy and relaxed", 8.0, [leftArm, rightArm]),
            ("Now notice your shoulders, gently let them drop", 8.0, [neck]),
            ("Bring your awareness to your neck, release any tightness", 8.0, [neck]),
            ("Now focus on your face, relax your eyes, jaw, and forehead", 8.0, [head]),
            ("Feel your whole body relaxed and at ease", 10.0, [head, neck, chest, leftArm, rightArm, stomach, leftLeg, rightLeg, leftFoot, rightFoot]),
            ("Take a slow deep breath in", 4.0, nil),
            ("And exhale gently", 6.0, nil),
            ("Stay in this calm and relaxed state", 10.0, nil),
            ("Slowly bring your awareness back", 4.0, nil),
            ("Gently open your eyes", 3.0, nil),
        ]

        func showStep() {
            guard self.isRunning else { return }
            let (text, duration, bodyParts) = steps[self.guidedStepIndex % steps.count]
            self.setInstruction(text, animate: self.guidedStepIndex > 0)
            self.speak(text)

            // Reset all parts first
            resetAllParts()
            
            // Highlight specific body parts
            if let parts = bodyParts {
                for part in parts {
                    highlightPart(part, with: highlightColor)
                }
            }

            self.stepStartTime = Date()
            self.currentStepDuration = duration
            self.resumeShowStep = showStep
            self.guidedStepIndex += 1

            self.instructionTimer?.invalidate()
            self.instructionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                showStep()
            }
        }

        showStep()
    }

    // 5. Guided Imagery — Guided Flow (3 min)
    private func sessionGuidedImagery() {
        guard animationViews.count >= 2 else { return }
        let backgroundImage = animationViews[0]
        let overlay = animationViews[1]

        let steps: [(String, TimeInterval, String)] = [
            ("Choose a comfortable position — seated or lying down", 5.0, "relax"),
            ("Soften your gaze, then let your eyelids gently close", 3.0, "relax"),
            ("Take a slow deep breath in", 4.0, "breathe"),
            ("And exhale gently", 6.0, "breathe"),
            ("Now begin", 2.0, "relax"),
            ("Imagine yourself in a peaceful place", 6.0, "calm"),
            ("It could be a beach, mountains, or a quiet garden", 6.0, "calm"),
            ("Look around in this place, notice the colors and light", 8.0, "light"),
            ("Gently bring your attention to the sounds around you", 8.0, "sounds"),
            ("Maybe waves, wind, or birds", 8.0, "sounds"),
            ("Now notice how your body feels in this place", 8.0, "feel"),
            ("Calm, safe, and relaxed", 8.0, "calm"),
            ("Take a slow deep breath in", 4.0, "breathe"),
            ("And exhale gently", 6.0, "breathe"),
            ("Feel the calmness spreading through your body", 10.0, "calm"),
            ("Stay here for a few moments", 15.0, "calm"),
            ("Notice small details around you", 10.0, "sight"),
            ("The air, the space, the stillness", 10.0, "calm"),
            ("Take another slow deep breath in", 4.0, "breathe"),
            ("And exhale slowly", 6.0, "breathe"),
            ("Let this peaceful feeling deepen", 10.0, "calm"),
            ("Slowly begin to bring your awareness back", 6.0, "return"),
            ("Gently return to the present moment", 5.0, "return"),
            ("And when you're ready, slowly open your eyes", 4.0, "open"),
        ]

        func showStep() {
            guard self.isRunning else { return }
            let (text, duration, type) = steps[self.guidedStepIndex % steps.count]
            self.setInstruction(text, animate: self.guidedStepIndex > 0)
            self.speak(text)

            switch type {
            case "breathe":
                // Subtle overlay pulsing effect
                UIView.animate(withDuration: duration * 0.5, delay: 0, options: .curveEaseInOut) {
                    overlay.alpha = 0.05
                } completion: { _ in
                    UIView.animate(withDuration: duration * 0.5) {
                        overlay.alpha = 0.15
                    }
                }
                
            case "sight":
                // Lighten overlay to enhance visual focus
                UIView.animate(withDuration: duration * 0.7, delay: 0, options: .curveEaseInOut) {
                    overlay.alpha = 0.08
                }
                
            case "light":
                // Brighten image for light focus
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                    overlay.alpha = 0.05
                    backgroundImage.alpha = 1.0
                }
                
            case "sounds":
                // Gentle dimming for inner focus
                UIView.animate(withDuration: duration * 0.5, delay: 0, options: .curveEaseOut) {
                    overlay.alpha = 0.2
                } completion: { _ in
                    UIView.animate(withDuration: duration * 0.3) {
                        overlay.alpha = 0.12
                    }
                }
                
            case "feel":
                // Subtle effect
                UIView.animate(withDuration: duration * 0.6, delay: 0, options: .curveEaseInOut) {
                    overlay.alpha = 0.1
                }
                
            case "calm":
                // Peaceful overlay state
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                    overlay.alpha = 0.12
                }
                
            case "return":
                // Return to normal
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                    overlay.alpha = 0.15
                    backgroundImage.alpha = 1.0
                }
                
            case "open":
                // Brighten as eyes open
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                    overlay.alpha = 0.08
                }
                
            default:
                break
            }

            self.stepStartTime = Date()
            self.currentStepDuration = duration
            self.resumeShowStep = showStep
            self.guidedStepIndex += 1

            self.instructionTimer?.invalidate()
            self.instructionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                showStep()
            }
        }

        showStep()
    }

    // 6. Box Breathing — Guided Flow (5 min) with dot animation
    private func sessionBoxBreathing() {
        guard let dotLayer = boxDotLayer else { return }

        let side = boxSquareSide

        // Corner positions in the square's coordinate system
        let bottomLeft  = CGPoint(x: 0, y: side)
        let topLeft     = CGPoint(x: 0, y: 0)
        let topRight    = CGPoint(x: side, y: 0)
        let bottomRight = CGPoint(x: side, y: side)

        // Only reset dot position on first start (not resume)
        if self.guidedStepIndex == 0 {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            dotLayer.position = bottomLeft
            CATransaction.commit()
        }

        // Helper: animate dot from current position to destination using Core Animation
        func animateDot(to destination: CGPoint, duration: TimeInterval) {
            let anim = CABasicAnimation(keyPath: "position")
            anim.fromValue = dotLayer.presentation()?.position ?? dotLayer.position
            anim.toValue = destination
            anim.duration = duration
            anim.timingFunction = CAMediaTimingFunction(name: .linear)
            anim.fillMode = .forwards
            anim.isRemovedOnCompletion = false
            // Update model layer so pause/resume works correctly
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            dotLayer.position = destination
            CATransaction.commit()
            dotLayer.add(anim, forKey: "dotMove")
        }

        // (text, duration, type: "inhale"/"hold"/"exhale"/"other")
        let steps: [(String, TimeInterval, String)] = [
            ("Sit tall in your chair or on the floor — spine straight", 5.0, "other"),
            ("Place your hands on your thighs and relax your face", 3.0, "other"),
            ("Now begin", 2.0, "other"),
            ("Inhale slowly through your nose", 4.0, "inhale"),
            ("Hold", 4.0, "hold"),
            ("Exhale slowly through your mouth", 4.0, "exhale"),
            ("Hold", 4.0, "hold"),
            ("Inhale", 4.0, "inhale"),
            ("Hold", 4.0, "hold"),
            ("Exhale", 4.0, "exhale"),
            ("Hold", 4.0, "hold"),
            ("Continue this steady rhythm", 6.0, "other"),
            ("Inhale", 4.0, "inhale"),
            ("Hold", 4.0, "hold"),
            ("Exhale", 4.0, "exhale"),
            ("Hold", 4.0, "hold"),
            ("Inhale", 4.0, "inhale"),
            ("Hold", 4.0, "hold"),
            ("Exhale", 4.0, "exhale"),
            ("Hold", 4.0, "hold"),
            ("Stay with this smooth pattern", 7.0, "other"),
            ("Inhale", 4.0, "inhale"),
            ("Hold", 4.0, "hold"),
            ("Exhale", 4.0, "exhale"),
            ("Hold", 4.0, "hold"),
            ("Inhale", 4.0, "inhale"),
            ("Hold", 4.0, "hold"),
            ("Exhale", 4.0, "exhale"),
            ("Hold", 4.0, "hold"),
            ("Keep your breathing slow and controlled", 8.0, "other"),
            ("Inhale", 4.0, "inhale"),
            ("Hold", 4.0, "hold"),
            ("Exhale", 4.0, "exhale"),
            ("Hold", 4.0, "hold"),
            ("Inhale", 4.0, "inhale"),
            ("Hold", 4.0, "hold"),
            ("Exhale", 4.0, "exhale"),
            ("Hold", 4.0, "hold"),
            ("Notice your body feeling calm and steady", 13.0, "other"),
            ("Slowly bring your awareness back", 5.0, "other"),
            ("Gently open your eyes", 3.0, "other"),
        ]

        func showStep() {
            guard self.isRunning else { return }
            let (text, duration, type) = steps[self.guidedStepIndex % steps.count]
            self.setInstruction(text, animate: self.guidedStepIndex > 0)
            self.speak(text)

            // Animate dot along the square edges using Core Animation
            switch type {
            case "inhale":
                // Bottom-left -> Top-left (up left side)
                animateDot(to: topLeft, duration: duration)
                self.boxPhase = 1
            case "hold":
                if self.boxPhase == 1 {
                    // Top-left -> Top-right (across top)
                    animateDot(to: topRight, duration: duration)
                    self.boxPhase = 2
                } else {
                    // Bottom-right -> Bottom-left (across bottom)
                    animateDot(to: bottomLeft, duration: duration)
                    self.boxPhase = 0
                }
            case "exhale":
                // Top-right -> Bottom-right (down right side)
                animateDot(to: bottomRight, duration: duration)
                self.boxPhase = 3
            default:
                // Non-breathing step: no dot movement, just stay in place
                break
            }

            self.stepStartTime = Date()
            self.currentStepDuration = duration
            self.resumeShowStep = showStep
            self.guidedStepIndex += 1

            self.instructionTimer?.invalidate()
            self.instructionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                showStep()
            }
        }

        showStep()
    }

    // 7. Heart Focused Breathing — Guided Flow (5 min) - Enhanced Animation
    private func sessionHeartBreathing() {
        guard animationViews.count >= 7 else { return }
        let ring0     = animationViews[0]  // outer ring
        let ring1     = animationViews[1]  // middle ring
        let ring2     = animationViews[2]  // inner ring
        let glowOuter = animationViews[3]  // outer glow
        let glowInner = animationViews[4]  // inner glow
        let emitterC  = animationViews[5]  // emitter container
        let heart     = animationViews[6]  // heart icon

        // Helper to adjust particle birth rate
        func setParticles(_ rate: Float) {
            if let emitter = emitterC.layer.sublayers?.compactMap({ $0 as? CAEmitterLayer }).first {
                emitter.birthRate = rate
            }
        }

        // (text, duration, type: "inhale"/"exhale"/"warmth"/"other")
        let steps: [(String, TimeInterval, String)] = [
            ("Sit or lie in a position that feels warm and safe", 5.0, "other"),
            ("Gently close your eyes and take a soft, easy breath", 3.0, "other"),
            ("Place your hand on your heart", 4.0, "warmth"),
            ("Take a slow deep breath in through your nose", 5.0, "inhale"),
            ("And exhale slowly through your mouth", 5.0, "exhale"),
            ("Now begin", 2.0, "other"),
            ("Breathe slowly and evenly", 3.0, "other"),
            ("Imagine your breath flowing in and out of your heart", 6.0, "warmth"),
            ("Inhale", 5.0, "inhale"),
            ("Exhale", 5.0, "exhale"),
            ("With each breath, feel a sense of calm and warmth in your chest", 6.0, "warmth"),
            ("Inhale", 5.0, "inhale"),
            ("Exhale", 5.0, "exhale"),
            ("Gently bring to mind a feeling of gratitude or care", 8.0, "warmth"),
            ("Inhale", 5.0, "inhale"),
            ("Exhale", 5.0, "exhale"),
            ("Let this feeling grow with each breath", 8.0, "warmth"),
            ("Inhale", 5.0, "inhale"),
            ("Exhale", 5.0, "exhale"),
            ("Stay with this calm and steady rhythm", 8.0, "warmth"),
            ("Inhale", 5.0, "inhale"),
            ("Exhale", 5.0, "exhale"),
            ("Feel your body becoming more relaxed and centered", 8.0, "warmth"),
            ("Inhale", 5.0, "inhale"),
            ("Exhale", 5.0, "exhale"),
            ("Continue at your own gentle pace", 8.0, "warmth"),
            ("Take one final deep breath in", 5.0, "inhale"),
            ("And exhale slowly", 5.0, "exhale"),
            ("Notice how calm and balanced you feel", 10.0, "warmth"),
            ("Slowly bring your awareness back", 5.0, "other"),
            ("Gently open your eyes", 3.0, "other"),
        ]

        func showStep() {
            guard self.isRunning else { return }
            let (text, duration, type) = steps[self.guidedStepIndex % steps.count]
            self.setInstruction(text, animate: self.guidedStepIndex > 0)
            self.speak(text)

            switch type {
            case "inhale":
                // Spring expansion with particles
                setParticles(20)
                
                // Heart expands with spring bounce
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.3, options: .curveEaseInOut, animations: {
                    heart.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                })
                
                // Glow expands with smooth curve
                UIView.animate(withDuration: duration * 0.8, delay: 0, options: .curveEaseInOut) {
                    glowOuter.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
                    glowOuter.alpha = 0.9
                    glowInner.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
                    glowInner.alpha = 0.85
                }
                
                // Cascading ring expansion
                UIView.animate(withDuration: duration * 0.6, delay: 0.1, options: .curveEaseOut) {
                    ring2.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
                    ring2.alpha = 0.9
                }
                UIView.animate(withDuration: duration * 0.6, delay: 0.2, options: .curveEaseOut) {
                    ring1.transform = CGAffineTransform(scaleX: 1.09, y: 1.09)
                    ring1.alpha = 0.85
                }
                UIView.animate(withDuration: duration * 0.6, delay: 0.3, options: .curveEaseOut) {
                    ring0.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
                    ring0.alpha = 0.8
                }

            case "exhale":
                // Smooth contraction
                setParticles(3)
                
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                    heart.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    glowOuter.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                    glowOuter.alpha = 0.2
                    glowInner.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    glowInner.alpha = 0.25
                }
                
                // Rings reset smoothly
                UIView.animate(withDuration: duration * 0.7, delay: 0.1, options: .curveEaseInOut) {
                    ring2.transform = .identity
                    ring2.alpha = 1.0
                }
                UIView.animate(withDuration: duration * 0.7, delay: 0.2, options: .curveEaseInOut) {
                    ring1.transform = .identity
                    ring1.alpha = 1.0
                }
                UIView.animate(withDuration: duration * 0.7, delay: 0.3, options: .curveEaseInOut) {
                    ring0.transform = .identity
                    ring0.alpha = 1.0
                }

            case "warmth":
                // Energetic particle burst
                setParticles(40)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { setParticles(15) }

                let rippleDur = min(duration * 0.35, 1.8)
                
                // Ripple outward on all rings
                UIView.animate(withDuration: rippleDur, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: .curveEaseOut, animations: {
                    ring2.transform = CGAffineTransform(scaleX: 1.18, y: 1.18)
                    ring2.alpha = 0.9
                }) { _ in
                    UIView.animate(withDuration: rippleDur * 0.8) {
                        ring2.transform = .identity
                        ring2.alpha = 1.0
                    }
                }
                
                UIView.animate(withDuration: rippleDur, delay: 0.25, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
                    ring1.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                    ring1.alpha = 0.9
                }) { _ in
                    UIView.animate(withDuration: rippleDur * 0.8) {
                        ring1.transform = .identity
                        ring1.alpha = 1.0
                    }
                }
                
                UIView.animate(withDuration: rippleDur, delay: 0.5, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
                    ring0.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
                    ring0.alpha = 0.9
                }) { _ in
                    UIView.animate(withDuration: rippleDur * 0.8) {
                        ring0.transform = .identity
                        ring0.alpha = 1.0
                    }
                }
                
                // Dramatic glow flare
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                    glowOuter.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
                    glowOuter.alpha = 0.9
                    glowInner.transform = CGAffineTransform(scaleX: 1.28, y: 1.28)
                    glowInner.alpha = 0.85
                }) { _ in
                    UIView.animate(withDuration: 1.2, delay: 0.1, options: .curveEaseInOut, animations: {
                        glowOuter.transform = .identity
                        glowOuter.alpha = 0.4
                        glowInner.transform = .identity
                        glowInner.alpha = 0.4
                    })
                }
                
                // Triple heartbeat for warmth emotion
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
                    heart.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                }) { _ in
                    UIView.animate(withDuration: 0.2, delay: 0.15, options: .curveEaseInOut, animations: {
                        heart.transform = .identity
                    }) { _ in
                        UIView.animate(withDuration: 0.2, delay: 0.08, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.9, options: .curveEaseOut, animations: {
                            heart.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                        }) { _ in
                            UIView.animate(withDuration: 0.2) {
                                heart.transform = .identity
                            }
                        }
                    }
                }

            default:
                // Gentle single heartbeat with soft animation
                setParticles(10)
                UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.6, options: .curveEaseOut, animations: {
                    heart.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                }) { _ in
                    UIView.animate(withDuration: 0.4) {
                        heart.transform = .identity
                    }
                }
            }

            self.stepStartTime = Date()
            self.currentStepDuration = duration
            self.resumeShowStep = showStep
            self.guidedStepIndex += 1

            self.instructionTimer?.invalidate()
            self.instructionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                showStep()
            }
        }

        showStep()
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
