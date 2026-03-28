import UIKit
import AVFoundation

class BreathingViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var activityNameLabel: UILabel!
    @IBOutlet weak var timerSlider: UISlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var rectangularView: UIView!
    @IBOutlet weak var exerciseDescriptionLabel: UILabel!
    
    // MARK: - Properties
    var activityName: String = "Cloud Thoughts"
    var exerciseType: String = "breathing" // breathing, calmingSounds, fingerRhythm, shoulderDrop, eyeRelaxation, meditation
    
    private var mainTimer: Timer?
    private var instructionTimer: Timer?
    private var timeRemaining: Int = 120 // 2 minutes (total)
    private var elapsedTime: Int = 0 // Time elapsed
    private var breathingPhase: Int = -1 // -1: Intro, 0-2: Cycle
    private var audioPlayer: AVAudioPlayer?
    private var isSessionRunning: Bool = false
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var hasSetupAnimations: Bool = false
    private var isLeavingConfirmed: Bool = false
    private var wasRunningBeforeBackground: Bool = false
    
    // MARK: - Breathing Animation Properties
    private var breathingAnimationView: UIView?
    private var breathingCircleLayer: CAShapeLayer?
    private var clockHandLayer: CAShapeLayer?
    private var instructionLabel: UILabel?
    private var breathingCycleTimer: Timer?
    private var currentBreathingPhase: BreathingPhase = .inhale
    private var breathingCycleElapsed: Double = 0
    private var countdownTimer: Timer?
    private var countdownValue: Int = 3
    
    // MARK: - DVD Animation Properties
    private var dvdAnimationView: UIView?
    private var dvdDiscLayers: [CAShapeLayer] = []
    private var musicSymbolLabels: [UILabel] = []
    private var dvdInstructionLabel: UILabel?
    private var dvdInstructionTimer: Timer?
    
    // MARK: - Eye Relaxation Animation Properties
    private var eyeAnimationView: UIView?
    private var eyeLidTopLayer: CAShapeLayer?
    private var eyeLidBotLayer: CAShapeLayer?
    private var eyeGlowLayer: CAShapeLayer?
    private var eyeIrisLayer: CAShapeLayer?      // LEFT eye iris
    private var eyePupilLayer: CAShapeLayer?     // LEFT eye pupil
    private var eyeHighlightLayer: CAShapeLayer? // LEFT eye highlight
    private var eyeIrisLayerR: CAShapeLayer?     // RIGHT eye iris
    private var eyePupilLayerR: CAShapeLayer?    // RIGHT eye pupil
    private var eyeHighlightLayerR: CAShapeLayer?// RIGHT eye highlight
    private var eyeLidTopLayerR: CAShapeLayer?   // RIGHT eye top lid
    private var eyeLidBotLayerR: CAShapeLayer?   // RIGHT eye bottom lid
    private var eyeBrowLayerL: CAShapeLayer?     // LEFT eyebrow
    private var eyeBrowLayerR: CAShapeLayer?     // RIGHT eyebrow
    private var eyeInstructionLabel: UILabel?
    private var eyeInstructionTimer: Timer?
    private var currentEyeInstructionIndex: Int = 0
    private let eyeInstructions = [
        "Gently close your eyes.",        // 0 → blink closed
        "Slowly roll your eyes upward.",  // 1 → iris up
        "Now roll them to the right.",    // 2 → iris right
        "Roll them downward, then left.", // 3 → iris down, then left
        "Open gently and blink softly."   // 4 → return centre + soft blink
    ]
    
    // MARK: - Meditation Animation Properties
    private var meditationAnimationView: UIView?
    private var scanBeamLayer: CAShapeLayer?
    private var meditationInstructionLabel: UILabel?
    private var meditationInstructionTimer: Timer?
    private var currentMeditationIndex: Int = 0
    private let meditationInstructions = [
        "Sit tall. Feel your body grounding down.",         // 0 Root
        "Tighten your stomach. Now slowly release.",        // 1 Sacral
        "Take a deep breath into your chest.",              // 2 Solar
        "Relax your shoulders. Let them drop.",             // 3 Heart
        "Soften your jaw. Unclench your teeth.",            // 4 Throat
        "Gently close your eyes. Breathe out.",             // 5 Third Eye
        "Feel lightness rising to your crown."              // 6 Crown
    ]
    private var currentInstructionIndex: Int = 0
    private var dvdRotationAnimation: CABasicAnimation?
    
    // MARK: - Meditation Dot Properties
    private var meditationTravelDot: CAShapeLayer?
    private var meditationChakraYPositions: [CGFloat] = []
    
    // MARK: - Triangle-Flower Breathing Animation
    private var breathingFlowerLayer: CALayer?
    private var breathingTriangleVertices: [CGPoint] = [] // [top, bottomRight, bottomLeft]
    
    // MARK: - Finger Rhythm Orb Properties
    private var fingerOrbLayer: CAShapeLayer?
    private var fingerOrbRingLayer: CAShapeLayer?
    private var fingerTipPositions: [(x: CGFloat, y: CGFloat)] = [] // [index, middle, ring, little]
    private var fingerRippleLayers: [CAShapeLayer] = []
    
    // MARK: - Shoulder Drop Animation Properties
    private var leftShoulderLayer: CAShapeLayer?
    private var rightShoulderLayer: CAShapeLayer?
    private let calmingInstructions = [
        "The sound gently fills the space.",
        "A soft rhythm settles everything down.",
        "The mind grows quieter with each moment.",
        "Thoughts fade into the background.",
        "A calm, refreshed feeling begins to rise."
    ]
    
    // MARK: - Finger Rhythm Instructions
    private let fingerRhythmInstructions = [
        "Gently touch your thumb to tip of your index finger.",
        "Now move to your middle finger.",
        "Then your ring finger.",
        "Then your little finger.",
        "Continue the same rhythm."
    ]
    private var currentFingerRhythmIndex: Int = 0
    
    // MARK: - Shoulder Drop Instructions
    private let shoulderDropInstructions = [
        "Sit upright and let your arms rest naturally.",
        "Slowly lift your shoulders toward your ears.",
        "Hold briefly at the top.",
        "Gently drop your shoulders down.",
        "Continue this rhythm."
    ]
    private var currentShoulderDropIndex: Int = 0
    
    // MARK: - Pause/Resume Tracking
    private var instructionPauseTime: Date?
    private var instructionStartTime: Date?
    private var remainingInstructionDuration: TimeInterval = 0
    
    // Breathing phases enum
    enum BreathingPhase {
        case inhale  // 4 seconds
        case hold    // 7 seconds
        case exhale  // 9 seconds
        
        var duration: Double {
            switch self {
            case .inhale: return 4.0
            case .hold: return 7.0
            case .exhale: return 9.0
            }
        }
        
        var instruction: String {
            switch self {
            case .inhale: return "INHALE"
            case .hold: return "HOLD"
            case .exhale: return "EXHALE"
            }
        }
        
        var next: BreathingPhase {
            switch self {
            case .inhale: return .hold
            case .hold: return .exhale
            case .exhale: return .inhale
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupAudio()
        setupSpeechSynthesizer()
        setupSoundPickerButton()
        
        // Prevent iPhone from going to sleep during exercises
        UIApplication.shared.isIdleTimerDisabled = true
        // Disable swipe-back gesture to prevent accidental exit
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        // Custom back button with quit confirmation
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
        navigationItem.hidesBackButton = true

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
        if isSessionRunning {
            wasRunningBeforeBackground = true
            pauseSession()
        }
    }

    @objc private func handleAppForeground() {
        // Only resume if the session was running when screen locked
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
                if self.isSessionRunning { self.pauseSession() }
            } else if type == .ended {
                // Call ended — resume automatically
                if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) && !self.isSessionRunning {
                        self.startSession()
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Make rectangular view circular (done here so it doesn't cause GPU stutter during push transition)
        if let rectView = rectangularView {
            if (exerciseType.lowercased() == "breathing" || 
                exerciseType.lowercased() == "shoulderdrop" || 
                exerciseType.lowercased() == "fingerrhythm") && rectView.frame.width > 0 {
                rectView.layer.cornerRadius = rectView.frame.width / 2
                rectView.clipsToBounds = true
                rectView.backgroundColor = .clear
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        if isLeavingConfirmed {
            stopSession()
        }
        // Re-enable sleep when leaving exercise
        UIApplication.shared.isIdleTimerDisabled = false
        // Re-enable swipe-back for other screens
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    @objc private func backButtonTapped() {
        showQuitConfirmation()
    }
    
    private func showQuitConfirmation() {
        // Pause the session while the alert is shown
        if isSessionRunning {
            pauseSession()
        }
        
        let alert = UIAlertController(
            title: "Quit Exercise?",
            message: "Are you sure you want to quit this exercise? Your progress will not be saved.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Yes, Quit", style: .destructive) { [weak self] _ in
            self?.confirmQuit()
        })
        
        alert.addAction(UIAlertAction(title: "Continue", style: .cancel) { [weak self] _ in
            // Resume the exercise automatically when user taps Continue
            self?.startSession()
        })
        
        present(alert, animated: true)
    }
    
    private func confirmQuit() {
        isLeavingConfirmed = true
        stopSession()
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Layout logic moved to viewDidAppear to prevent lag during custom push transitions
        
        // Setup animations ONLY ONCE when bounds are valid, before the transition finishes.
        // This ensures the animation is fully visible on the new screen as soon as it slides in.
        if !hasSetupAnimations, let rectView = rectangularView, rectView.frame.width > 0 {
            hasSetupAnimations = true
            
            if exerciseType.lowercased() == "breathing" || 
               exerciseType.lowercased() == "shoulderdrop" || 
               exerciseType.lowercased() == "fingerrhythm" {
                setupBreathingAnimation()
            }
            
            if exerciseType.lowercased() == "calmingsounds" {
                setupDVDAnimation()
            }
            
            if exerciseType.lowercased() == "eyerelaxation" {
                setupEyeRelaxationAnimation()
            }
            
            if exerciseType.lowercased() == "meditation" {
                setupMeditationAnimation()
            }
            
            // Advanced Calming Techniques
            if exerciseType.lowercased() == "physiologicalsigh" { setupPhysiologicalSighAnimation() }
            if exerciseType.lowercased() == "coherentbreathing" { setupCoherentBreathingAnimation() }
            if exerciseType.lowercased() == "progressivemuscle" { setupProgressiveMuscleAnimation() }
            if exerciseType.lowercased() == "grounding54321"    { setupGrounding54321Animation() }
            if exerciseType.lowercased() == "guidedimagery"     { setupGuidedImageryAnimation() }
            if exerciseType.lowercased() == "boxbreathing"      { setupBoxBreathingAnimation() }
            if exerciseType.lowercased() == "heartbreathing"    { setupHeartBreathingAnimation() }
            if exerciseType.lowercased() == "cognitivereset"    { setupCognitiveResetAnimation() }
            if exerciseType.lowercased() == "resonancehumming"  { setupResonanceHummingAnimation() }
            if exerciseType.lowercased() == "microbodyreset"    { setupMicroBodyResetAnimation() }
        }
    }
    
    // MARK: - Setup
    func setupUI() {
        activityNameLabel.text = activityName
        
        // Navigation title
        self.navigationItem.title = "Calming Activity"
        
        // Setup slider
        timerSlider.minimumValue = 0
        timerSlider.maximumValue = 120
        timerSlider.value = 0
        timerSlider.isUserInteractionEnabled = false // Slider is read-only, only updated by timer
        
        // Setup time labels
        currentTimeLabel.text = "0:00"
        totalTimeLabel.text = "2:00"
        
        // Setup exercise description
        updateExerciseDescription()
        
        // Setup exercise colors
        updateExerciseColors()
        
        // Setup play button
        updatePlayButtonIcon()
        
        // Setup sound picker button
        setupSoundPickerButton()
    }
    
    private func setupSoundPickerButton() {
        let soundButton = UIBarButtonItem(
            image: UIImage(systemName: "music.note.list"),
            style: .plain,
            target: self,
            action: #selector(showSoundPicker)
        )
        navigationItem.rightBarButtonItem = soundButton
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
            audioPlayer?.volume = 0.7
            
            // If session is running, play the new sound
            if isSessionRunning {
                audioPlayer?.play()
            }
        } catch {
        }
    }
    
    func setupAudio() {
        let selectedSound = SoundManager.shared.getSelectedSound()
        let fileName = SoundManager.shared.getFileName(for: selectedSound)
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else { 
            print("Audio file not found: \(fileName)")
            return 
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Infinite loop
            audioPlayer?.volume = 0.7
            // Do NOT play automatically - wait for user to tap play button
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    func setupSpeechSynthesizer() {
        speechSynthesizer = AVSpeechSynthesizer()
    }
    
    func speakInstruction(_ text: String) {
        // Stop any ongoing speech
        speechSynthesizer?.stopSpeaking(at: .immediate)
        
        // Create speech utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Use the best available natural voice
        if let enhancedVoice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.enhanced.en-US.Samantha") {
            utterance.voice = enhancedVoice
        } else if let compactVoice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.en-US.Samantha") {
            utterance.voice = compactVoice
        } else if let premiumVoice = AVSpeechSynthesisVoice.speechVoices()
            .first(where: { $0.language.hasPrefix("en-US") && $0.quality == .enhanced }) {
            utterance.voice = premiumVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        utterance.rate = 0.46                // Slightly slower, calm and clear
        utterance.pitchMultiplier = 0.95     // Slightly lower pitch for warmth
        utterance.volume = 0.85
        utterance.preUtteranceDelay = 0.15   // Brief pause before speaking
        utterance.postUtteranceDelay = 0.1   // Brief pause after speaking
        
        // Speak the instruction
        speechSynthesizer?.speak(utterance)
    }
    
    
    func updateExerciseDescription() {
        // Update description based on exercise type and activity name
        let description: String
        
        
        switch exerciseType.lowercased() {
        case "breathing":
            description = "Calm your mind with guided breathing"
        case "calmingsounds":
            description = "Listen to peaceful nature sounds"
        case "fingerrhythm":
            description = "Gentle self-massage for instant relief"
        case "shoulderdrop":
            description = "Release tension with shoulder exercises"
        case "eyerelaxation":
            description = "Soothe & rest your tired eyes"
        case "meditation":
            description = "Quiet your mind & find stillness"
        case "physiologicalsigh":
            description = "Double inhale + long exhale for stress reset"
        case "coherentbreathing":
            description = "Balance your nervous system with 5s breathing"
        case "progressivemuscle":
            description = "Deeply relax by tensing and releasing muscles"
        case "grounding54321":
            description = "Anchor your senses to stop spinning thoughts"
        case "guidedimagery":
            description = "Transport your mind to a peaceful place"
        case "boxbreathing":
            description = "Focus and calm with 4-4-4-4 breathing"
        case "heartbreathing":
            description = "Connect with your heart's emotional rhythm"
        case "cognitivereset":
            description = "Reframe stressful thoughts quickly"
        case "resonancehumming":
            description = "Stimulate your vagus nerve with vibration"
        case "microbodyreset":
            description = "Shake off physical tension in 2 minutes"
        default:
            description = "Relax and rejuvenate your mind and body"
        }
        
        exerciseDescriptionLabel.text = description
    }
    
    
    
    
    func updateExerciseColors() {
        // Get color based on exercise type using iOS system colors
        let color: UIColor
        
        switch exerciseType.lowercased() {
        case "breathing":
            color = .systemBlue
        case "calmingsounds":
            color = .systemPurple
        case "fingerrhythm":
            color = .systemTeal
        case "shoulderdrop":
            color = .systemGreen
        case "eyerelaxation":
            color = UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0)  // Orange
        case "meditation":
            color = UIColor(red: 0.20, green: 0.73, blue: 0.60, alpha: 1.0) // Teal-green
        case "physiologicalsigh":
            color = UIColor(red: 0.10, green: 0.38, blue: 0.82, alpha: 1.0) // Dark Blue
        case "coherentbreathing":
            color = UIColor(red: 0.08, green: 0.52, blue: 0.44, alpha: 1.0) // Deep Teal
        case "progressivemuscle":
            color = UIColor(red: 0.36, green: 0.18, blue: 0.72, alpha: 1.0) // Deep Purple
        case "grounding54321":
            color = UIColor(red: 0.82, green: 0.32, blue: 0.06, alpha: 1.0) // Burnt Orange
        case "guidedimagery":
            color = UIColor(red: 0.08, green: 0.48, blue: 0.70, alpha: 1.0) // Ocean Blue
        case "boxbreathing":
            color = UIColor(red: 0.08, green: 0.26, blue: 0.62, alpha: 1.0) // Navy
        case "heartbreathing":
            color = UIColor(red: 0.72, green: 0.10, blue: 0.30, alpha: 1.0) // Deep Red
        case "cognitivereset":
            color = UIColor(red: 0.18, green: 0.52, blue: 0.22, alpha: 1.0) // Forest Green
        case "resonancehumming":
            color = UIColor(red: 0.52, green: 0.18, blue: 0.72, alpha: 1.0) // Violet
        case "microbodyreset":
            color = UIColor(red: 0.82, green: 0.48, blue: 0.06, alpha: 1.0) // Amber
        default:
            color = .systemBlue
        }
        
        // Update activity name label color
        activityNameLabel.textColor = color
        
        // Update play button background color
        playButton.backgroundColor = color
        
        // Update slider tint colors
        timerSlider.minimumTrackTintColor = color
        
        // Update time labels color
        currentTimeLabel.textColor = color
        totalTimeLabel.textColor = color
    }
    
    // MARK: - Timer Logic
    @IBAction func playButtonTapped(_ sender: UIButton) {
        if isSessionRunning {
            pauseSession()
        } else {
            startSession()
        }
    }
    
    private func startSession() {
        isSessionRunning = true
        updatePlayButtonIcon()
        
        // For breathing exercises (including shoulder drops and finger rhythm), delay audio and timer until countdown finishes
        if exerciseType.lowercased() == "breathing" || 
           exerciseType.lowercased() == "shoulderdrop" || 
           exerciseType.lowercased() == "fingerrhythm" {
            
            if let animationView = breathingAnimationView, animationView.alpha == 1 {
                if countdownTimer != nil {
                    return
                } else if let label = instructionLabel, label.text != "START" && label.text != "" && label.text != "3" && label.text != "2" && label.text != "1" {
                    clockHandLayer?.resumeAnimation()
                    audioPlayer?.play()
                    
                    if remainingInstructionDuration > 0.1 {
                        scheduleNextPhase(after: remainingInstructionDuration)
                        remainingInstructionDuration = 0
                    } else {
                        updateBreathingPhase()
                    }
                    
                    mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                        self?.updateProgress()
                    }
                } else {
                    startBreathingAnimation()
                    // Audio and timer start AFTER countdown finishes (inside startBreathingAnimation)
                }
            }
        } else if exerciseType.lowercased() == "calmingsounds" {
            if let label = instructionLabel {
                if countdownTimer != nil {
                    return
                } else if label.text == "START" {
                    startDVDAnimation()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                        self?.audioPlayer?.play()
                        self?.mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                            self?.updateProgress()
                        }
                    }
                } else {
                    // Resume from pause - restart the instruction timer
                    dvdAnimationView?.layer.resumeAnimation()
                    audioPlayer?.play()
                    mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                        self?.updateProgress()
                    }
                    // Restart the instruction timer that was paused
                    dvdInstructionTimer = Timer.scheduledTimer(withTimeInterval: 24.0, repeats: true) { [weak self] _ in
                        self?.updateDVDInstruction()
                    }
                }
            }
        } else if exerciseType.lowercased() == "eyerelaxation" {
            if countdownTimer != nil { return }
            if let lbl = eyeInstructionLabel, lbl.text != "START" && lbl.text != "3" && lbl.text != "2" && lbl.text != "1" {
                // Resume from pause
                eyeAnimationView?.layer.resumeAnimation()
                audioPlayer?.play()
                mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.updateProgress()
                }
                eyeInstructionTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.currentEyeInstructionIndex = (self.currentEyeInstructionIndex + 1) % self.eyeInstructions.count
                    let idx = self.currentEyeInstructionIndex
                    let text = self.eyeInstructions[idx]
                    UIView.transition(with: self.eyeInstructionLabel ?? UILabel(),
                                      duration: 0.4, options: .transitionCrossDissolve) {
                        self.eyeInstructionLabel?.text = text
                    }
                    self.speakInstruction(text)
                    self.animateEyeForInstruction(idx)
                }
            } else {
                startEyeRelaxationSession()
            }
        } else if exerciseType.lowercased() == "meditation" {
            if countdownTimer != nil { return }
            if let lbl = meditationInstructionLabel, lbl.text != "START" && lbl.text != "3" && lbl.text != "2" && lbl.text != "1" {
                // Resume from pause
                meditationAnimationView?.layer.resumeAnimation()
                audioPlayer?.play()
                mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.updateProgress()
                }
                meditationInstructionTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.currentMeditationIndex = (self.currentMeditationIndex + 1) % self.meditationInstructions.count
                    let text = self.meditationInstructions[self.currentMeditationIndex]
                    UIView.transition(with: self.meditationInstructionLabel ?? UILabel(),
                                      duration: 0.4, options: .transitionCrossDissolve) {
                        self.meditationInstructionLabel?.text = text
                    }
                    self.speakInstruction(text)
                    self.moveMeditationDotToChakra(self.currentMeditationIndex)
                }
            } else {
                startMeditationSession()
            }
        } else if exerciseType.lowercased() == "physiologicalsigh" {
            startPhysiologicalSighSession()
        } else if exerciseType.lowercased() == "coherentbreathing" {
            startCoherentBreathingSession()
        } else if exerciseType.lowercased() == "progressivemuscle" {
            startProgressiveMuscleSession()
        } else if exerciseType.lowercased() == "grounding54321" {
            startGrounding54321Session()
        } else if exerciseType.lowercased() == "guidedimagery" {
            startGuidedImagerySession()
        } else if exerciseType.lowercased() == "boxbreathing" {
            startBoxBreathingSession()
        } else if exerciseType.lowercased() == "heartbreathing" {
            startHeartBreathingSession()
        } else if exerciseType.lowercased() == "cognitivereset" {
            startCognitiveResetSession()
        } else if exerciseType.lowercased() == "resonancehumming" {
            startResonanceHummingSession()
        } else if exerciseType.lowercased() == "microbodyreset" {
            startMicroBodyResetSession()
        } else {
            audioPlayer?.play()
            
            mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateProgress()
            }
        }
    }
    
    private func pauseSession() {
        isSessionRunning = false
        updatePlayButtonIcon()

        audioPlayer?.pause()
        mainTimer?.invalidate()
        mainTimer = nil

        // Stop all instruction-cycling timers (advanced techniques + standard)
        instructionTimer?.invalidate()
        instructionTimer = nil
        breathingCycleTimer?.invalidate()
        breathingCycleTimer = nil

        // Stop voice instructions
        speechSynthesizer?.stopSpeaking(at: .immediate)

        // Pause breathing animation (pause the clock hand, keep timer for resume)
        clockHandLayer?.pauseAnimation()

        // Stop instruction timer and track remaining time
        if let startTime = instructionStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            let totalDuration: TimeInterval

            // Determine total duration based on exercise type
            if exerciseType.lowercased() == "fingerrhythm" || exerciseType.lowercased() == "shoulderdrop" {
                totalDuration = 4.0
            } else {
                totalDuration = currentBreathingPhase.duration
            }

            remainingInstructionDuration = max(0, totalDuration - elapsed)
            instructionPauseTime = Date()
        }

        // Pause DVD animation (pause rotation)
        if exerciseType.lowercased() == "calmingsounds" {
            dvdAnimationView?.layer.pauseAnimation()
            // CRITICAL: Stop the instruction timer - this prevents instructions from changing while paused
            dvdInstructionTimer?.invalidate()
            dvdInstructionTimer = nil
        }

        // Pause eye / body-scan animations
        if exerciseType.lowercased() == "eyerelaxation" {
            eyeAnimationView?.layer.pauseAnimation()
            eyeInstructionTimer?.invalidate()
            eyeInstructionTimer = nil
        }
        if exerciseType.lowercased() == "meditation" {
            meditationAnimationView?.layer.pauseAnimation()
            meditationInstructionTimer?.invalidate()
            meditationInstructionTimer = nil
        }
    }
    
    private func stopSession() {
        pauseSession()
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        elapsedTime = 0
        timerSlider.value = 0
        currentTimeLabel.text = "0:00"
        
        // Stop voice instructions
        speechSynthesizer?.stopSpeaking(at: .immediate)
        
        // Stop breathing animation
        stopBreathingAnimation()
        
        // Stop DVD animation
        if exerciseType.lowercased() == "calmingsounds" {
            stopDVDAnimation()
        }
        
        // Stop eye / body-scan
        if exerciseType.lowercased() == "eyerelaxation" {
            stopEyeRelaxationAnimation()
        }
        if exerciseType.lowercased() == "meditation" {
            stopMeditationAnimation()
        }
    }
    
    private func updateProgress() {
        elapsedTime += 1 // Increment by 0.1 seconds
        let elapsedSeconds = Float(elapsedTime) / 10.0
        
        // Update slider
        timerSlider.value = elapsedSeconds
        
        // Update current time label
        let minutes = Int(elapsedSeconds) / 60
        let seconds = Int(elapsedSeconds) % 60
        currentTimeLabel.text = String(format: "%d:%02d", minutes, seconds)
        
        // Check if session completed
        if elapsedSeconds >= 120 {
            finishSession()
        }
    }
    
    private func updatePlayButtonIcon() {
        let imageName = isSessionRunning ? "pause.fill" : "play.fill"
        let config = UIImage.SymbolConfiguration(scale: .large)
        let image = UIImage(systemName: imageName, withConfiguration: config)
        playButton.setImage(image, for: .normal)
    }
    
    // MARK: - Completion Logic
    private func finishSession() {
        stopSession()
        
        let points = 5
        DataManager.shared.addPoints(points)
        DataManager.shared.incrementSessionCount()
        DataManager.shared.updateStreak()
        
        let totalSessions = DataManager.shared.getAnalytics().totalSessions
        let stageIndex = totalSessions % 4
        let grewButterfly = (stageIndex == 0)
        if grewButterfly {
            DataManager.shared.addButterfly()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("SessionCompletedNotification"), object: nil)
        

        // 2. Alert Message
        let sessionsToday = DataManager.shared.getSessionCountForDay()
        let alertStageIndex = sessionsToday % 4
        
        if grewButterfly {
            // 🦋 BUTTERFLY CELEBRATION — sparkles + special popup
            showButterflySparkles()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showButterflyCelebrationPopup(points: points)
            }
        } else {
            var message = "Great! You've completed your 2-minute breathing exercise.\n\n+\(points) Points Earned! 🏆\n\n"
            
            switch alertStageIndex {
            case 1: message += "You have completed Egg stage 🥚"
            case 2: message += "You have completed Caterpillar stage 🐛"
            case 3: message += "You have completed Pupa stage 🫘"
            default: message += "Session Complete"
            }
            
            let alert = UIAlertController(title: "Session Complete! 🎉", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigateToMoodScreen()
            })
            present(alert, animated: true)
        }
    }
    
    // MARK: - Butterfly Celebration
    private func showButterflySparkles() {
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = CGPoint(x: view.bounds.midX, y: -20)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: view.bounds.width * 1.2, height: 1)
        emitterLayer.renderMode = .additive
        
        // Sparkle cell
        let sparkleCell = CAEmitterCell()
        sparkleCell.birthRate = 25
        sparkleCell.lifetime = 5.0
        sparkleCell.velocity = 120
        sparkleCell.velocityRange = 60
        sparkleCell.emissionLongitude = .pi
        sparkleCell.emissionRange = .pi / 4
        sparkleCell.spin = 3.0
        sparkleCell.spinRange = 6.0
        sparkleCell.scale = 0.06
        sparkleCell.scaleRange = 0.04
        sparkleCell.scaleSpeed = -0.01
        sparkleCell.alphaSpeed = -0.15
        sparkleCell.contents = UIImage(systemName: "sparkle")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal).cgImage
        sparkleCell.color = UIColor.systemYellow.cgColor
        
        // Star cell
        let starCell = CAEmitterCell()
        starCell.birthRate = 15
        starCell.lifetime = 4.5
        starCell.velocity = 100
        starCell.velocityRange = 50
        starCell.emissionLongitude = .pi
        starCell.emissionRange = .pi / 3
        starCell.spin = 2.0
        starCell.spinRange = 4.0
        starCell.scale = 0.08
        starCell.scaleRange = 0.05
        starCell.scaleSpeed = -0.01
        starCell.alphaSpeed = -0.2
        starCell.contents = UIImage(systemName: "star.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal).cgImage
        starCell.color = UIColor.white.cgColor
        
        // Butterfly cell
        let butterflyCell = CAEmitterCell()
        butterflyCell.birthRate = 4
        butterflyCell.lifetime = 6.0
        butterflyCell.velocity = 80
        butterflyCell.velocityRange = 40
        butterflyCell.emissionLongitude = .pi
        butterflyCell.emissionRange = .pi / 4
        butterflyCell.spin = 1.0
        butterflyCell.spinRange = 2.0
        butterflyCell.scale = 0.12
        butterflyCell.scaleRange = 0.06
        butterflyCell.alphaSpeed = -0.12
        
        // Create a butterfly emoji image
        let butterflyRenderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
        let butterflyImg = butterflyRenderer.image { ctx in
            let str = NSAttributedString(string: "🦋", attributes: [.font: UIFont.systemFont(ofSize: 30)])
            str.draw(at: CGPoint(x: 2, y: 2))
        }
        butterflyCell.contents = butterflyImg.cgImage
        
        // Confetti cells — multiple colors
        var confettiCells: [CAEmitterCell] = []
        let confettiColors: [UIColor] = [.systemPurple, .systemPink, .systemBlue, .systemGreen, .systemOrange, .systemCyan]
        for color in confettiColors {
            let confetti = CAEmitterCell()
            confetti.birthRate = 8
            confetti.lifetime = 5.0
            confetti.velocity = 140
            confetti.velocityRange = 70
            confetti.emissionLongitude = .pi
            confetti.emissionRange = .pi / 3
            confetti.spin = 4.0
            confetti.spinRange = 8.0
            confetti.scale = 0.04
            confetti.scaleRange = 0.03
            confetti.alphaSpeed = -0.18
            confetti.contents = UIImage(systemName: "circle.fill")?.withTintColor(color, renderingMode: .alwaysOriginal).cgImage
            confetti.color = color.cgColor
            confettiCells.append(confetti)
        }
        
        emitterLayer.emitterCells = [sparkleCell, starCell, butterflyCell] + confettiCells
        view.layer.addSublayer(emitterLayer)
        
        // Stop emitting after 3 seconds, remove after particles fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            emitterLayer.birthRate = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                emitterLayer.removeFromSuperlayer()
            }
        }
    }
    
    private func showButterflyCelebrationPopup(points: Int) {
        // Add to the window so it always appears above all subviews (including rectangularView)
        guard let windowScene = view.window?.windowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
        else { return }

        let overlayView = UIView(frame: window.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0)
        overlayView.tag = 8888
        window.addSubview(overlayView)
        
        // Card container
        let cardWidth: CGFloat = min(320, view.bounds.width - 48)
        let cardHeight: CGFloat = 360
        let card = UIView(frame: CGRect(x: 0, y: 0, width: cardWidth, height: cardHeight))
        card.center = overlayView.center
        card.backgroundColor = UIColor.systemBackground
        card.layer.cornerRadius = 28
        card.clipsToBounds = true
        card.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        card.alpha = 0
        overlayView.addSubview(card)
        
        // Gradient background on card — random color from app palette each time
        let gradientPairs: [(UIColor, UIColor)] = [
            (UIColor(red: 0.56, green: 0.27, blue: 0.87, alpha: 1.0), UIColor(red: 0.30, green: 0.15, blue: 0.70, alpha: 1.0)),  // Purple
            (UIColor(red: 0.10, green: 0.38, blue: 0.82, alpha: 1.0), UIColor(red: 0.08, green: 0.26, blue: 0.62, alpha: 1.0)),  // Blue
            (UIColor(red: 0.08, green: 0.52, blue: 0.44, alpha: 1.0), UIColor(red: 0.20, green: 0.73, blue: 0.60, alpha: 1.0)),  // Teal
            (UIColor(red: 0.82, green: 0.32, blue: 0.06, alpha: 1.0), UIColor(red: 1.0,  green: 0.584, blue: 0.0, alpha: 1.0)),  // Orange
            (UIColor(red: 0.72, green: 0.10, blue: 0.30, alpha: 1.0), UIColor(red: 0.52, green: 0.18, blue: 0.72, alpha: 1.0)),  // Red-Violet
            (UIColor(red: 0.18, green: 0.52, blue: 0.22, alpha: 1.0), UIColor(red: 0.08, green: 0.52, blue: 0.44, alpha: 1.0)),  // Green-Teal
            (UIColor(red: 0.08, green: 0.48, blue: 0.70, alpha: 1.0), UIColor(red: 0.10, green: 0.38, blue: 0.82, alpha: 1.0)),  // Ocean Blue
            (UIColor(red: 0.82, green: 0.48, blue: 0.06, alpha: 1.0), UIColor(red: 0.82, green: 0.32, blue: 0.06, alpha: 1.0)),  // Amber
            (UIColor(red: 0.36, green: 0.18, blue: 0.72, alpha: 1.0), UIColor(red: 0.52, green: 0.18, blue: 0.72, alpha: 1.0)),  // Deep Purple-Violet
        ]
        let chosenPair = gradientPairs.randomElement()!
        
        let gradient = CAGradientLayer()
        gradient.colors = [chosenPair.0.cgColor, chosenPair.1.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = card.bounds
        card.layer.insertSublayer(gradient, at: 0)
        
        // Butterfly emoji
        let butterflyLabel = UILabel()
        butterflyLabel.text = "🦋"
        butterflyLabel.font = .systemFont(ofSize: 72)
        butterflyLabel.textAlignment = .center
        butterflyLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(butterflyLabel)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Butterfly Grown!"
        titleLabel.font = .systemFont(ofSize: 26, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)
        
        // Message
        let msgLabel = UILabel()
        msgLabel.text = "Congratulations! You've completed all 4 stages and grown a beautiful butterfly!\n\n+\(points) Points Earned 🏆"
        msgLabel.font = .systemFont(ofSize: 15, weight: .medium)
        msgLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        msgLabel.textAlignment = .center
        msgLabel.numberOfLines = 0
        msgLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(msgLabel)
        
        // Continue button
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
        
        // Animate in
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: []) {
            overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            card.transform = .identity
            card.alpha = 1
        }
        
        // Gentle floating animation on butterfly emoji
        UIView.animate(withDuration: 1.5, delay: 0.5, options: [.repeat, .autoreverse, .allowUserInteraction]) {
            butterflyLabel.transform = CGAffineTransform(translationX: 0, y: -10)
        }
    }
    
    @objc private func dismissButterflyPopup() {
        // Find overlay in window (where we added it)
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
    
    // MARK: - Breathing Animation Methods
    func setupBreathingAnimation() {
        guard let containerView = rectangularView else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let type = self.exerciseType.lowercased()

            // Colour per exercise
            let color: UIColor
            switch type {
            case "breathing":    color = .systemBlue
            case "shoulderdrop": color = .systemGreen
            case "fingerrhythm": color = .systemTeal
            default:             color = .systemBlue
            }

            // Shared canvas
            let animationView = UIView()
            animationView.backgroundColor = .clear
            animationView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(animationView)

            let animSize: CGFloat = (type == "fingerrhythm") ? 380 : 320
            let animYOffset: CGFloat
            switch type {
            case "fingerrhythm": animYOffset = -50
            case "shoulderdrop": animYOffset = -120
            default:             animYOffset = -80
            }

            NSLayoutConstraint.activate([
                animationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                animationView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: animYOffset),
                animationView.widthAnchor.constraint(equalToConstant: animSize),
                animationView.heightAnchor.constraint(equalToConstant: animSize)
            ])
            self.breathingAnimationView = animationView

            let cx: CGFloat = animSize / 2, cy: CGFloat = animSize / 2

            
            // DEEP BREATHING — glowing orb + concentric rings + particle field
            
            if type == "breathing" {

                // Triangle vertices (equilateral, circumradius 108, top-up)
                let R: CGFloat = 140
                let v0 = CGPoint(x: cx, y: cy - R)                            // TOP    → INHALE ends / HOLD starts
                let v1 = CGPoint(x: cx + R * sin(2 * .pi / 3),
                                 y: cy - R * cos(2 * .pi / 3))                 // BOTTOM-RIGHT → HOLD ends / EXHALE starts
                let v2 = CGPoint(x: cx + R * sin(4 * .pi / 3),
                                 y: cy - R * cos(4 * .pi / 3))                 // BOTTOM-LEFT  → EXHALE ends / INHALE starts
                self.breathingTriangleVertices = [v0, v1, v2]

                // Triangle path with soft rounded joins
                let triPath = UIBezierPath()
                triPath.move(to: v2)
                triPath.addLine(to: v0)
                triPath.addLine(to: v1)
                triPath.addLine(to: v2)
                triPath.close()

                // Outer glow copy (thick, low-alpha)
                let glowLayer = CAShapeLayer()
                glowLayer.path        = triPath.cgPath
                glowLayer.fillColor   = UIColor.clear.cgColor
                glowLayer.strokeColor = color.withAlphaComponent(0.18).cgColor
                glowLayer.lineWidth   = 14
                glowLayer.lineCap     = .round; glowLayer.lineJoin = .round
                animationView.layer.addSublayer(glowLayer)

                // Main triangle stroke (clean, crisp)
                let triLayer = CAShapeLayer()
                triLayer.path        = triPath.cgPath
                triLayer.fillColor   = color.withAlphaComponent(0.04).cgColor
                triLayer.strokeColor = color.withAlphaComponent(0.70).cgColor
                triLayer.lineWidth   = 2.8
                triLayer.lineCap     = .round; triLayer.lineJoin = .round
                animationView.layer.addSublayer(triLayer)

                // Vertex dots + phase labels
                let phaseInfo: [(pt: CGPoint, label: String, offsetX: CGFloat, offsetY: CGFloat)] = [
                    (v0, "INHALE",  0,  -22),
                    (v1, "HOLD",   28,   10),
                    (v2, "EXHALE", -36,  10)
                ]
                for info in phaseInfo {
                    // Dot
                    let dot = CAShapeLayer()
                    dot.path        = UIBezierPath(ovalIn: CGRect(x: info.pt.x-5, y: info.pt.y-5,
                                                                  width: 10, height: 10)).cgPath
                    dot.fillColor   = color.cgColor
                    dot.shadowColor = color.cgColor
                    dot.shadowRadius = 6; dot.shadowOpacity = 0.8; dot.shadowOffset = .zero
                    animationView.layer.addSublayer(dot)

                    // Label
                    let lbl = UILabel()
                    lbl.text      = info.label
                    lbl.font      = UIFont.systemFont(ofSize: 11, weight: .semibold)
                    lbl.textColor = color.withAlphaComponent(0.85)
                    lbl.sizeToFit()
                    lbl.center    = CGPoint(x: info.pt.x + info.offsetX,
                                           y: info.pt.y + info.offsetY)
                    animationView.addSubview(lbl)
                }

                // Flower: container layer holding orb + petals
                let flowerContainer = CALayer()
                flowerContainer.bounds   = CGRect(x: 0, y: 0, width: 60, height: 60)
                flowerContainer.position = v2   // starts at INHALE start vertex
                animationView.layer.addSublayer(flowerContainer)
                self.breathingFlowerLayer = flowerContainer



                // Centre orb of the flower
                let orbL = CAShapeLayer()
                orbL.path        = UIBezierPath(ovalIn: CGRect(x: 30-10, y: 30-10, width: 20, height: 20)).cgPath
                orbL.fillColor   = color.cgColor
                orbL.shadowColor = color.cgColor
                orbL.shadowRadius = 14; orbL.shadowOpacity = 1.0; orbL.shadowOffset = .zero
                flowerContainer.addSublayer(orbL)

                // Orb highlight
                let hlL = CAShapeLayer()
                hlL.path      = UIBezierPath(ovalIn: CGRect(x: 30-4, y: 30-8, width: 6, height: 6)).cgPath
                hlL.fillColor = UIColor.white.withAlphaComponent(0.70).cgColor
                flowerContainer.addSublayer(hlL)

                // Orb idle pulse
                let orbPulse = CABasicAnimation(keyPath: "transform.scale")
                orbPulse.fromValue = 0.88; orbPulse.toValue = 1.12; orbPulse.duration = 1.4
                orbPulse.repeatCount = .infinity; orbPulse.autoreverses = true
                orbPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                orbL.add(orbPulse, forKey: "pulse")

                // Invisible timing layer (keeps clockHand pause/resume intact)
                let sweepLayer = CAShapeLayer()
                sweepLayer.strokeColor = UIColor.clear.cgColor
                sweepLayer.fillColor   = UIColor.clear.cgColor
                sweepLayer.lineWidth   = 0
                sweepLayer.strokeEnd   = 0
                animationView.layer.addSublayer(sweepLayer)
                self.clockHandLayer = sweepLayer

            
            // FINGER RHYTHM — beautiful skin-tone hand with pressing index finger from above
            
            } else if type == "fingerrhythm" {

                let skin    = UIColor(red: 0.97, green: 0.87, blue: 0.76, alpha: 1.0)
                let skinDark = UIColor(red: 0.90, green: 0.78, blue: 0.66, alpha: 1.0)
                let sc      = color.withAlphaComponent(0.30)
                let lw: CGFloat = 2.2

                // Scale factor for bigger hand
                let s: CGFloat = 1.35

                // Helper: draw one organic tapered finger
                func taperFinger(fcx: CGFloat, baseY: CGFloat, tipY: CGFloat,
                                 baseHW: CGFloat, tipHW: CGFloat) -> UIBezierPath {
                    let path  = UIBezierPath()
                    let midY  = baseY + (tipY - baseY) * 0.55
                    let tipCY = tipY + tipHW

                    path.move(to: CGPoint(x: fcx - baseHW, y: baseY))
                    path.addCurve(to: CGPoint(x: fcx - tipHW, y: tipCY),
                                  controlPoint1: CGPoint(x: fcx - baseHW * 0.95, y: midY),
                                  controlPoint2: CGPoint(x: fcx - tipHW * 1.05, y: tipCY + tipHW))
                    path.addArc(withCenter: CGPoint(x: fcx, y: tipCY),
                                radius: tipHW, startAngle: .pi, endAngle: 0, clockwise: false)
                    path.addCurve(to: CGPoint(x: fcx + baseHW, y: baseY),
                                  controlPoint1: CGPoint(x: fcx + tipHW * 1.05, y: tipCY + tipHW),
                                  controlPoint2: CGPoint(x: fcx + baseHW * 0.95, y: midY))
                    path.close()
                    return path
                }

                // Canvas layout (shifted up)
                let palmBaseY: CGFloat = cy + 60 * s
                let palmTopY:  CGFloat = cy - 10 * s

                // Palm — gentle trapezoidal bezier
                let palmPath = UIBezierPath()
                palmPath.move(to: CGPoint(x: cx - 52 * s, y: palmBaseY))
                palmPath.addCurve(to: CGPoint(x: cx + 52 * s, y: palmBaseY),
                                  controlPoint1: CGPoint(x: cx - 34 * s, y: palmBaseY + 12 * s),
                                  controlPoint2: CGPoint(x: cx + 34 * s, y: palmBaseY + 12 * s))
                palmPath.addCurve(to: CGPoint(x: cx + 46 * s, y: palmTopY),
                                  controlPoint1: CGPoint(x: cx + 56 * s, y: palmBaseY - 30 * s),
                                  controlPoint2: CGPoint(x: cx + 50 * s, y: palmTopY + 20 * s))
                palmPath.addCurve(to: CGPoint(x: cx - 46 * s, y: palmTopY),
                                  controlPoint1: CGPoint(x: cx + 20 * s, y: palmTopY - 10 * s),
                                  controlPoint2: CGPoint(x: cx - 20 * s, y: palmTopY - 10 * s))
                palmPath.addCurve(to: CGPoint(x: cx - 52 * s, y: palmBaseY),
                                  controlPoint1: CGPoint(x: cx - 50 * s, y: palmTopY + 20 * s),
                                  controlPoint2: CGPoint(x: cx - 56 * s, y: palmBaseY - 30 * s))
                palmPath.close()

                let palmLayer = CAShapeLayer()
                palmLayer.path        = palmPath.cgPath
                palmLayer.fillColor   = skin.cgColor
                palmLayer.strokeColor = sc.cgColor
                palmLayer.lineWidth   = lw
                animationView.layer.addSublayer(palmLayer)

                // Wrist
                let wristPath = UIBezierPath()
                wristPath.move(to: CGPoint(x: cx - 38 * s, y: palmBaseY))
                wristPath.addCurve(to: CGPoint(x: cx + 38 * s, y: palmBaseY),
                                   controlPoint1: CGPoint(x: cx - 20 * s, y: palmBaseY + 4 * s),
                                   controlPoint2: CGPoint(x: cx + 20 * s, y: palmBaseY + 4 * s))
                wristPath.addCurve(to: CGPoint(x: cx + 34 * s, y: palmBaseY + 22 * s),
                                   controlPoint1: CGPoint(x: cx + 40 * s, y: palmBaseY + 12 * s),
                                   controlPoint2: CGPoint(x: cx + 36 * s, y: palmBaseY + 18 * s))
                wristPath.addCurve(to: CGPoint(x: cx - 34 * s, y: palmBaseY + 22 * s),
                                   controlPoint1: CGPoint(x: cx + 14 * s, y: palmBaseY + 26 * s),
                                   controlPoint2: CGPoint(x: cx - 14 * s, y: palmBaseY + 26 * s))
                wristPath.addCurve(to: CGPoint(x: cx - 38 * s, y: palmBaseY),
                                   controlPoint1: CGPoint(x: cx - 36 * s, y: palmBaseY + 18 * s),
                                   controlPoint2: CGPoint(x: cx - 40 * s, y: palmBaseY + 12 * s))
                wristPath.close()
                let wristLayer = CAShapeLayer()
                wristLayer.path        = wristPath.cgPath
                wristLayer.fillColor   = skinDark.cgColor
                wristLayer.strokeColor = sc.cgColor; wristLayer.lineWidth = lw
                animationView.layer.addSublayer(wristLayer)

                // Thumb
                let thumbPath = UIBezierPath()
                thumbPath.move(to: CGPoint(x: cx - 46 * s, y: palmTopY + 22 * s))
                thumbPath.addCurve(to: CGPoint(x: cx - 76 * s, y: palmTopY + 44 * s),
                                   controlPoint1: CGPoint(x: cx - 58 * s, y: palmTopY + 16 * s),
                                   controlPoint2: CGPoint(x: cx - 82 * s, y: palmTopY + 28 * s))
                thumbPath.addCurve(to: CGPoint(x: cx - 64 * s, y: palmTopY + 64 * s),
                                   controlPoint1: CGPoint(x: cx - 74 * s, y: palmTopY + 56 * s),
                                   controlPoint2: CGPoint(x: cx - 72 * s, y: palmTopY + 64 * s))
                thumbPath.addCurve(to: CGPoint(x: cx - 46 * s, y: palmTopY + 52 * s),
                                   controlPoint1: CGPoint(x: cx - 56 * s, y: palmTopY + 64 * s),
                                   controlPoint2: CGPoint(x: cx - 48 * s, y: palmTopY + 60 * s))
                thumbPath.addCurve(to: CGPoint(x: cx - 38 * s, y: palmTopY + 30 * s),
                                   controlPoint1: CGPoint(x: cx - 42 * s, y: palmTopY + 46 * s),
                                   controlPoint2: CGPoint(x: cx - 38 * s, y: palmTopY + 40 * s))
                thumbPath.close()
                let thumbLayer = CAShapeLayer()
                thumbLayer.path        = thumbPath.cgPath
                thumbLayer.fillColor   = skin.cgColor
                thumbLayer.strokeColor = sc.cgColor; thumbLayer.lineWidth = lw
                animationView.layer.addSublayer(thumbLayer)

                // 4 Fingers
                let fCXs:  [CGFloat] = [cx - 33 * s, cx - 11 * s, cx + 11 * s, cx + 33 * s]
                let fHs:   [CGFloat] = [100 * s, 118 * s, 112 * s, 84 * s]
                let fBHWs: [CGFloat] = [13 * s, 13 * s, 13 * s, 11 * s]
                let fTHWs: [CGFloat] = [10 * s, 10 * s, 10 * s,  8 * s]

                var tipXArr: [CGFloat] = []
                var tipYArr: [CGFloat] = []

                for fi in 0..<4 {
                    let fcx   = fCXs[fi]
                    let baseY = palmTopY + 6 * s
                    let tipY  = baseY - fHs[fi]
                    tipXArr.append(fcx)
                    tipYArr.append(tipY)

                    let fPath = taperFinger(fcx: fcx, baseY: baseY,
                                           tipY: tipY, baseHW: fBHWs[fi], tipHW: fTHWs[fi])
                    let fLayer = CAShapeLayer()
                    fLayer.path        = fPath.cgPath
                    fLayer.fillColor   = skin.cgColor
                    fLayer.strokeColor = sc.cgColor; fLayer.lineWidth = lw
                    animationView.layer.addSublayer(fLayer)

                    // Knuckle wrinkle lines
                    for offset in [CGFloat(18 * s), CGFloat(32 * s)] {
                        let wPath = UIBezierPath()
                        wPath.move(to:    CGPoint(x: fcx - fBHWs[fi] * 0.7, y: baseY - offset))
                        wPath.addCurve(to: CGPoint(x: fcx + fBHWs[fi] * 0.7, y: baseY - offset),
                                       controlPoint1: CGPoint(x: fcx - fBHWs[fi] * 0.2, y: baseY - offset - 2),
                                       controlPoint2: CGPoint(x: fcx + fBHWs[fi] * 0.2, y: baseY - offset - 2))
                        let wLine = CAShapeLayer()
                        wLine.path        = wPath.cgPath
                        wLine.strokeColor = skinDark.withAlphaComponent(0.55).cgColor
                        wLine.fillColor   = UIColor.clear.cgColor
                        wLine.lineWidth   = 1.0; wLine.lineCap = .round
                        animationView.layer.addSublayer(wLine)
                    }

                    // Fingernail
                    let tHW   = fTHWs[fi]
                    let tipCY = tipY + tHW
                    let nail  = CAShapeLayer()
                    nail.path = UIBezierPath(ovalIn: CGRect(x: fcx - tHW * 0.7,
                                                            y: tipCY - tHW * 0.55,
                                                            width: tHW * 1.4,
                                                            height: tHW * 1.1)).cgPath
                    nail.fillColor   = UIColor.white.withAlphaComponent(0.45).cgColor
                    nail.strokeColor = UIColor.white.withAlphaComponent(0.20).cgColor
                    nail.lineWidth   = 0.8
                    animationView.layer.addSublayer(nail)
                }

                // GLOWING ORB indicator (instruction-driven)
                // Store fingertip positions for instruction-driven movement
                self.fingerTipPositions = (0..<4).map { (x: tipXArr[$0], y: tipYArr[$0]) }

                let orbR: CGFloat = 16
                let orbLayer = CAShapeLayer()
                orbLayer.path = UIBezierPath(ovalIn: CGRect(x: -orbR, y: -orbR,
                                                            width: orbR*2, height: orbR*2)).cgPath
                orbLayer.fillColor    = color.withAlphaComponent(0.92).cgColor
                orbLayer.shadowColor  = color.cgColor
                orbLayer.shadowRadius = 18; orbLayer.shadowOpacity = 0.85; orbLayer.shadowOffset = .zero
                orbLayer.position     = CGPoint(x: tipXArr[0], y: tipYArr[0] - 32)
                animationView.layer.addSublayer(orbLayer)
                self.fingerOrbLayer = orbLayer

                let ringR: CGFloat = orbR + 10
                let orbRingLayer = CAShapeLayer()
                orbRingLayer.path = UIBezierPath(ovalIn: CGRect(x: -ringR, y: -ringR,
                                                                width: ringR*2, height: ringR*2)).cgPath
                orbRingLayer.fillColor   = UIColor.clear.cgColor
                orbRingLayer.strokeColor = color.withAlphaComponent(0.45).cgColor
                orbRingLayer.lineWidth   = 2.5
                orbRingLayer.position    = CGPoint(x: tipXArr[0], y: tipYArr[0] - 32)
                animationView.layer.addSublayer(orbRingLayer)
                self.fingerOrbRingLayer = orbRingLayer

                // Idle pulse on orb
                for (layer, from, to, dur) in [
                    (orbLayer,     0.88 as Float, 1.12 as Float, 1.0),
                    (orbRingLayer, 0.80 as Float, 1.24 as Float, 1.0)
                ] {
                    let p = CABasicAnimation(keyPath: "transform.scale")
                    p.fromValue = from; p.toValue = to; p.duration = dur
                    p.repeatCount = .infinity; p.autoreverses = true
                    p.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    layer.add(p, forKey: "idlePulse")
                }

                // Orb position driven by updateBreathingPhase
                // No continuous CAKeyframeAnimation — orb moves when instruction changes

                // Static ripple layers at each fingertip (triggered by moveOrbToFinger)
                var rippleLayers: [CAShapeLayer] = []
                for gi in 0..<4 {
                    let ripple = CAShapeLayer()
                    ripple.path = UIBezierPath(ovalIn: CGRect(x: tipXArr[gi]-22, y: tipYArr[gi]-22,
                                                              width: 44, height: 44)).cgPath
                    ripple.fillColor   = color.withAlphaComponent(0.20).cgColor
                    ripple.strokeColor = color.withAlphaComponent(0.55).cgColor
                    ripple.lineWidth   = 1.5; ripple.opacity = 0
                    animationView.layer.addSublayer(ripple)
                    rippleLayers.append(ripple)
                }
                self.fingerRippleLayers = rippleLayers

                // No sweep arc for finger rhythm — clockHandLayer stays nil
            } else {

                // Soft ambient circle
                let bg = CAShapeLayer()
                bg.path = UIBezierPath(ovalIn: CGRect(x: cx-118, y: cy-118, width: 236, height: 236)).cgPath
                bg.fillColor = color.withAlphaComponent(0.07).cgColor
                animationView.layer.addSublayer(bg)
                let bgP = CABasicAnimation(keyPath: "opacity")
                bgP.fromValue = 0.5; bgP.toValue = 1.0; bgP.duration = 3.0
                bgP.repeatCount = .infinity; bgP.autoreverses = true
                bg.add(bgP, forKey: "bg")

                // Body torso
                let torso = CAShapeLayer()
                torso.path = UIBezierPath(roundedRect: CGRect(x: cx-30, y: cy+20, width: 60, height: 78), cornerRadius: 20).cgPath
                torso.fillColor   = color.withAlphaComponent(0.18).cgColor
                torso.strokeColor = color.withAlphaComponent(0.55).cgColor
                torso.lineWidth   = 2.5
                animationView.layer.addSublayer(torso)

                // Head
                let head = CAShapeLayer()
                head.path = UIBezierPath(ovalIn: CGRect(x: cx-26, y: cy-50, width: 52, height: 52)).cgPath
                head.fillColor   = color.withAlphaComponent(0.18).cgColor
                head.strokeColor = color.withAlphaComponent(0.55).cgColor
                head.lineWidth   = 2.5
                animationView.layer.addSublayer(head)

                // Neck
                let neck = CAShapeLayer()
                neck.path = UIBezierPath(roundedRect: CGRect(x: cx-10, y: cy, width: 20, height: 24), cornerRadius: 6).cgPath
                neck.fillColor   = color.withAlphaComponent(0.18).cgColor
                neck.strokeColor = color.withAlphaComponent(0.45).cgColor
                neck.lineWidth   = 2.0
                animationView.layer.addSublayer(neck)

                // LEFT SHOULDER (animates up/down continuously)
                let leftShoulder = CAShapeLayer()
                leftShoulder.path = UIBezierPath(ovalIn: CGRect(x: cx-82, y: cy+8, width: 58, height: 30)).cgPath
                leftShoulder.fillColor   = color.withAlphaComponent(0.25).cgColor
                leftShoulder.strokeColor = color.withAlphaComponent(0.65).cgColor
                leftShoulder.lineWidth   = 2.5
                animationView.layer.addSublayer(leftShoulder)
                self.leftShoulderLayer = leftShoulder

                // RIGHT SHOULDER (mirror)
                let rightShoulder = CAShapeLayer()
                rightShoulder.path = UIBezierPath(ovalIn: CGRect(x: cx+24, y: cy+8, width: 58, height: 30)).cgPath
                rightShoulder.fillColor   = color.withAlphaComponent(0.25).cgColor
                rightShoulder.strokeColor = color.withAlphaComponent(0.65).cgColor
                rightShoulder.lineWidth   = 2.5
                animationView.layer.addSublayer(rightShoulder)
                self.rightShoulderLayer = rightShoulder

                // Shoulders start at rest — animation is instruction-driven via animateShoulders()

                // Left arm (hangs from shoulder)
                let leftArm = CAShapeLayer()
                let lArmPath = UIBezierPath()
                lArmPath.move(to: CGPoint(x: cx-53, y: cy+28))
                lArmPath.addCurve(to: CGPoint(x: cx-65, y: cy+110),
                                  controlPoint1: CGPoint(x: cx-72, y: cy+60),
                                  controlPoint2: CGPoint(x: cx-70, y: cy+90))
                leftArm.path = lArmPath.cgPath
                leftArm.strokeColor = color.withAlphaComponent(0.50).cgColor
                leftArm.fillColor   = UIColor.clear.cgColor
                leftArm.lineWidth   = 14; leftArm.lineCap = .round
                animationView.layer.addSublayer(leftArm)

                // Right arm
                let rightArm = CAShapeLayer()
                let rArmPath = UIBezierPath()
                rArmPath.move(to: CGPoint(x: cx+53, y: cy+28))
                rArmPath.addCurve(to: CGPoint(x: cx+65, y: cy+110),
                                  controlPoint1: CGPoint(x: cx+72, y: cy+60),
                                  controlPoint2: CGPoint(x: cx+70, y: cy+90))
                rightArm.path = rArmPath.cgPath
                rightArm.strokeColor = color.withAlphaComponent(0.50).cgColor
                rightArm.fillColor   = UIColor.clear.cgColor
                rightArm.lineWidth   = 14; rightArm.lineCap = .round
                animationView.layer.addSublayer(rightArm)

                // Floating sparkle dots
                for k in 0..<6 {
                    let ang = (CGFloat(k) / 6.0) * .pi * 2
                    let d: CGFloat = 115
                    let sp = CAShapeLayer()
                    sp.path = UIBezierPath(ovalIn: CGRect(x: cx + d*cos(ang)-5, y: cy + d*sin(ang)-5, width: 10, height: 10)).cgPath
                    sp.fillColor = color.withAlphaComponent(0.45).cgColor
                    animationView.layer.addSublayer(sp)
                    let sparkP = CABasicAnimation(keyPath: "opacity")
                    sparkP.fromValue = 0.1; sparkP.toValue = 0.8
                    sparkP.duration = Double.random(in: 1.5...2.8)
                    sparkP.beginTime = CACurrentMediaTime() + Double(k) * 0.4
                    sparkP.repeatCount = .infinity; sparkP.autoreverses = true
                    sp.add(sparkP, forKey: "sp")
                }

                // Clock-hand sweep
                let sweepLayer = CAShapeLayer()
                sweepLayer.path = UIBezierPath(arcCenter: CGPoint(x: cx, y: cy),
                                               radius: 128, startAngle: -.pi/2,
                                               endAngle: .pi*1.5, clockwise: true).cgPath
                sweepLayer.strokeColor = color.withAlphaComponent(0.55).cgColor
                sweepLayer.fillColor   = UIColor.clear.cgColor
                sweepLayer.lineWidth   = 6; sweepLayer.lineCap = .round; sweepLayer.strokeEnd = 0
                animationView.layer.addSublayer(sweepLayer)
                self.clockHandLayer = sweepLayer
            }

            // Shared: text instruction label
            let label = UILabel()
            label.text = "START"
            label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
            label.textColor = color
            label.textAlignment = .center
            label.numberOfLines = 3
            label.lineBreakMode = .byWordWrapping
            label.translatesAutoresizingMaskIntoConstraints = false

            if type == "fingerrhythm" || type == "shoulderdrop" {
                // Place instruction below the animation circle
                let labelOffset: CGFloat = (type == "fingerrhythm") ? -60 : 20
                containerView.addSubview(label)
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: labelOffset),
                    label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    label.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
                    label.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20),
                    label.widthAnchor.constraint(lessThanOrEqualToConstant: 300)
                ])
            } else {
                // Centre in the animation canvas for other exercises
                animationView.addSubview(label)
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: animationView.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: animationView.centerYAnchor),
                    label.leadingAnchor.constraint(greaterThanOrEqualTo: animationView.leadingAnchor, constant: 20),
                    label.trailingAnchor.constraint(lessThanOrEqualTo: animationView.trailingAnchor, constant: -20),
                    label.widthAnchor.constraint(lessThanOrEqualToConstant: 260)
                ])
            }
            self.instructionLabel = label

            // Start hidden — revealed by showInitialStartPrompt()
            animationView.alpha = 0
            if type == "fingerrhythm" || type == "shoulderdrop" {
                label.alpha = 0
            }
            
            // Reveal immediately after setup since transition has finished
            self.showInitialStartPrompt()
        }
    }
    
    func showInitialStartPrompt() {
        guard let animationView = breathingAnimationView,
              let label = instructionLabel else { return }

        // For finger rhythm / shoulder drop the label is below — keep empty until exercise starts
        let isLabelBelow = exerciseType.lowercased() == "fingerrhythm" || exerciseType.lowercased() == "shoulderdrop"
        label.text = isLabelBelow ? "" : "START"

        UIView.animate(withDuration: 0.3) {
            animationView.alpha = 1
            label.alpha = 1
        }
    }
    
    func startBreathingAnimation() {
        guard exerciseType.lowercased() == "breathing" ||
              exerciseType.lowercased() == "shoulderdrop" ||
              exerciseType.lowercased() == "fingerrhythm",
              let _ = breathingAnimationView,
              let label = instructionLabel else { return }

        // Start 3-second countdown
        countdownValue = 3
        label.text = "\(countdownValue)"
        label.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.countdownValue -= 1
            
            if self.countdownValue > 0 {
                UIView.transition(with: label,
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                    label.text = "\(self.countdownValue)"
                })
            } else {
                // Countdown finished — start exercise + audio + timer
                timer.invalidate()
                self.countdownTimer = nil
                
                self.elapsedTime = 0
                self.timerSlider.value = 0
                self.currentTimeLabel.text = "0:00"
                self.audioPlayer?.play()
                self.mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.updateProgress()
                }
                
                self.currentBreathingPhase = .inhale
                self.breathingCycleElapsed = 0
                self.updateBreathingPhase()
            }
        }
    }

    func stopBreathingAnimation() {
        guard let _ = breathingAnimationView,
              let label = instructionLabel else { return }
        
        // Stop all timers
        countdownTimer?.invalidate()
        countdownTimer = nil
        breathingCycleTimer?.invalidate()
        breathingCycleTimer = nil
        
        // Remove all animations
        clockHandLayer?.removeAllAnimations()
        
        // Reset to START state (keep animation visible)
        label.text = "START"
        
        // Reset phase and countdown
        currentBreathingPhase = .inhale
        breathingCycleElapsed = 0
        countdownValue = 3
        currentFingerRhythmIndex = 0 // Reset finger rhythm to first instruction
        currentShoulderDropIndex = 0 // Reset shoulder drop to first instruction
    }
    
    func updateBreathingPhase() {
        guard let label = instructionLabel else { return }
        
        // Check if this is Finger Rhythm exercise
        if exerciseType.lowercased() == "fingerrhythm" {
            // Use finger rhythm instructions (4 seconds each)
            let instruction = fingerRhythmInstructions[currentFingerRhythmIndex]
            label.text = instruction
            label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            label.numberOfLines = 2
            
            // Move orb to the correct finger
            // Index 0→index(0), 1→middle(1), 2→ring(2), 3→little(3), 4→index(0)
            let fingerIndex: Int
            switch currentFingerRhythmIndex {
            case 0: fingerIndex = 0  // index finger
            case 1: fingerIndex = 1  // middle finger
            case 2: fingerIndex = 2  // ring finger
            case 3: fingerIndex = 3  // little finger
            default: fingerIndex = 0 // "continue this rhythm" → back to index
            }
            moveOrbToFinger(fingerIndex)
            
            // Speak the instruction
            speakInstruction(instruction)
            
            // Animate clock hand rotation for 4 seconds
            animateClockHand(duration: 4.0)
            
            // Track start time for pause/resume
            instructionStartTime = Date()
            
            // Schedule next instruction
            scheduleNextPhase(after: 4.0)
        } else if exerciseType.lowercased() == "shoulderdrop" {
            // Use shoulder drop instructions (4 seconds each)
            let instruction = shoulderDropInstructions[currentShoulderDropIndex]
            label.text = instruction
            label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            label.numberOfLines = 2
            
            // Animate shoulders based on instruction
            // 0: sit upright → down, 1: lift → up, 2: hold → stay up, 3: drop → down, 4: continue → down
            switch currentShoulderDropIndex {
            case 1: animateShoulders(up: true)
            case 2: break // hold — shoulders stay lifted
            case 3: animateShoulders(up: false)
            default: break // sit upright / continue — shoulders stay down
            }
            
            // Speak the instruction
            speakInstruction(instruction)
            
            // Animate clock hand rotation for 4 seconds
            animateClockHand(duration: 4.0)
            
            // Track start time for pause/resume
            instructionStartTime = Date()
            
            // Schedule next instruction
            scheduleNextPhase(after: 4.0)
        } else {
            // Use breathing phases for breathing exercise only
            label.text = currentBreathingPhase.instruction
            label.font = UIFont.systemFont(ofSize: 32, weight: .bold) // Larger font for short text
            label.numberOfLines = 1
            
            // Speak the instruction
            speakInstruction(currentBreathingPhase.instruction)
            
            // Animate clock hand rotation for this phase duration (timing only)
            animateClockHand(duration: currentBreathingPhase.duration)
            
            // Move flower to next vertex along the triangle
            animateBreathingPhaseVisuals(phase: currentBreathingPhase)
            
            // Track start time for pause/resume
            instructionStartTime = Date()
            
            // Schedule next phase
            scheduleNextPhase(after: currentBreathingPhase.duration)
        }
    }
    
    /// Moves the flower along the triangle edge matching the current breathing phase
    private func animateBreathingPhaseVisuals(phase: BreathingPhase) {
        guard let flower = breathingFlowerLayer,
              breathingTriangleVertices.count == 3 else { return }
        
        // Map phase → (start vertex index, end vertex index)
        // Triangle: [0]=top, [1]=bottomRight, [2]=bottomLeft
        // INHALE : bottomLeft(2) → top(0)       left edge going up
        // HOLD   : top(0)       → bottomRight(1) right edge going down
        // EXHALE : bottomRight(1)→ bottomLeft(2) bottom edge going left
        let startIdx: Int
        let endIdx: Int
        switch phase {
        case .inhale:  startIdx = 2; endIdx = 0
        case .hold:    startIdx = 0; endIdx = 1
        case .exhale:  startIdx = 1; endIdx = 2
        }
        
        let start = breathingTriangleVertices[startIdx]
        let end   = breathingTriangleVertices[endIdx]
        
        // Snap position to start (model layer, no animation)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        flower.position = start
        CATransaction.commit()
        
        // Animate position to end vertex over the phase duration
        let posAnim = CABasicAnimation(keyPath: "position")
        posAnim.fromValue = NSValue(cgPoint: start)
        posAnim.toValue   = NSValue(cgPoint: end)
        posAnim.duration  = phase.duration
        
        // Easing: ease-out on inhale (slow to arrive), linear on hold, ease-in on exhale
        switch phase {
        case .inhale:  posAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        case .hold:    posAnim.timingFunction = CAMediaTimingFunction(name: .linear)
        case .exhale:  posAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        }
        posAnim.fillMode  = .forwards
        posAnim.isRemovedOnCompletion = false
        flower.add(posAnim, forKey: "move")
    }
    
    // MARK: - Finger Rhythm Orb Movement
    /// Moves the glowing orb to the specified fingertip (0=index, 1=middle, 2=ring, 3=little)
    func moveOrbToFinger(_ fingerIndex: Int) {
        guard fingerIndex < fingerTipPositions.count,
              let orbLayer = fingerOrbLayer,
              let orbRingLayer = fingerOrbRingLayer else { return }
        
        let tip = fingerTipPositions[fingerIndex]
        let targetPos = CGPoint(x: tip.x, y: tip.y - 32)
        
        // Smooth move animation
        let moveAnim = CABasicAnimation(keyPath: "position")
        moveAnim.toValue = NSValue(cgPoint: targetPos)
        moveAnim.duration = 0.35
        moveAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        moveAnim.fillMode = .forwards
        moveAnim.isRemovedOnCompletion = false
        
        orbLayer.removeAnimation(forKey: "orbMove")
        orbRingLayer.removeAnimation(forKey: "orbMove")
        
        orbLayer.add(moveAnim, forKey: "orbMove")
        orbRingLayer.add(moveAnim.copy() as! CABasicAnimation, forKey: "orbMove")
        
        // Update model position
        orbLayer.position = targetPos
        orbRingLayer.position = targetPos
        
        // Tap-down bounce effect after arriving + ripple
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            let tapDown = CAKeyframeAnimation(keyPath: "position.y")
            tapDown.values = [targetPos.y, tip.y - 8, tip.y - 20, targetPos.y]
            tapDown.keyTimes = [0, 0.3, 0.6, 1.0]
            tapDown.duration = 0.5
            tapDown.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            orbLayer.add(tapDown, forKey: "tap")
            orbRingLayer.add(tapDown.copy() as! CAKeyframeAnimation, forKey: "tap")
            
            // Trigger ripple on this finger
            if fingerIndex < (self?.fingerRippleLayers.count ?? 0),
               let ripple = self?.fingerRippleLayers[fingerIndex] {
                ripple.removeAllAnimations()
                
                let fadeIn = CABasicAnimation(keyPath: "opacity")
                fadeIn.fromValue = 0.0; fadeIn.toValue = 0.85
                fadeIn.duration = 0.2
                
                let scaleUp = CABasicAnimation(keyPath: "transform.scale")
                scaleUp.fromValue = 1.0; scaleUp.toValue = 1.6
                scaleUp.duration = 0.6
                
                let fadeOut = CABasicAnimation(keyPath: "opacity")
                fadeOut.fromValue = 0.85; fadeOut.toValue = 0.0
                fadeOut.beginTime = 0.4; fadeOut.duration = 0.3
                
                let group = CAAnimationGroup()
                group.animations = [fadeIn, scaleUp, fadeOut]
                group.duration = 0.7
                group.fillMode = .forwards
                group.isRemovedOnCompletion = false
                ripple.add(group, forKey: "ripple")
            }
        }
    }
    
    // MARK: - Shoulder Drop Animation
    /// Animates shoulders up (lift) or down (drop) based on current instruction
    func animateShoulders(up: Bool) {
        guard let left = leftShoulderLayer, let right = rightShoulderLayer else { return }
        
        let targetY: CGFloat = up ? -18 : 0
        let duration: Double = up ? 1.2 : 0.5  // Slow lift, quick drop
        
        for shLayer in [left, right] {
            shLayer.removeAnimation(forKey: "shoulderMove")
            
            let anim = CABasicAnimation(keyPath: "transform.translation.y")
            anim.toValue = targetY
            anim.duration = duration
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            anim.fillMode = .forwards
            anim.isRemovedOnCompletion = false
            shLayer.add(anim, forKey: "shoulderMove")
        }
    }
    
    // Helper function to schedule next phase transition
    func scheduleNextPhase(after duration: TimeInterval) {
        breathingCycleTimer?.invalidate()
        breathingCycleTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            // Move to next phase based on exercise type
            if self.exerciseType.lowercased() == "fingerrhythm" {
                self.currentFingerRhythmIndex = (self.currentFingerRhythmIndex + 1) % self.fingerRhythmInstructions.count
            } else if self.exerciseType.lowercased() == "shoulderdrop" {
                self.currentShoulderDropIndex = (self.currentShoulderDropIndex + 1) % self.shoulderDropInstructions.count
            } else {
                self.currentBreathingPhase = self.currentBreathingPhase.next
            }
            
            self.updateBreathingPhase()
        }
    }
    
    func animateClockHand(duration: Double) {
        guard let progressLayer = clockHandLayer else { return }
        
        // Remove existing animations
        progressLayer.removeAllAnimations()
        
        // Create the full arc path (from top to full circle)
        let circleRadius: CGFloat = 140
        let startAngle = -CGFloat.pi / 2 // Top (12 o'clock position)
        let endAngle = startAngle + (CGFloat.pi * 2) // Full circle
        
        let fullArcPath = UIBezierPath(arcCenter: CGPoint(x: 160, y: 160),
                                       radius: circleRadius,
                                       startAngle: startAngle,
                                       endAngle: endAngle,
                                       clockwise: true)
        
        // Animate the strokeEnd from 0 to 1 to create sweeping effect
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        // Set the full path and reset strokeEnd
        progressLayer.path = fullArcPath.cgPath
        progressLayer.strokeEnd = 0
        
        progressLayer.add(animation, forKey: "progressAnimation")
    }
    
    // MARK: - Navigation Helper
    private func navigateToMoodScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let moodVC = storyboard.instantiateViewController(withIdentifier: "MoodScoreViewController") as? MoodScoreViewController {
            moodVC.modalPresentationStyle = .fullScreen
            self.present(moodVC, animated: true, completion: nil)
        }
    }
    
}

// MARK: - CALayer Extension for Pause/Resume
extension CALayer {
    func pauseAnimation() {
        let pausedTime = convertTime(CACurrentMediaTime(), from: nil)
        speed = 0.0
        timeOffset = pausedTime
    }
    
    func resumeAnimation() {
        let pausedTime = timeOffset
        speed = 1.0
        timeOffset = 0.0
        beginTime = 0.0
        let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        beginTime = timeSincePause
    }
}

// MARK: - DVD Animation Methods
extension BreathingViewController {
    func setupDVDAnimation() {
        guard let containerView = rectangularView else { return }
        
        // Wait for layout to complete
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Create animation container view
            let animationView = UIView()
            animationView.backgroundColor = .clear
            animationView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(animationView)
            
            // Center the animation view (shifted up more, smaller size)
            NSLayoutConstraint.activate([
                animationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                animationView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -100),
                animationView.widthAnchor.constraint(equalToConstant: 280),
                animationView.heightAnchor.constraint(equalToConstant: 280)
            ])
            
            self.dvdAnimationView = animationView
            
            // Get the calming sounds color (purple)
            let color = UIColor.systemPurple
            
            // Create DVD disc layers to look like a real vinyl record
            let centerPoint = CGPoint(x: 140, y: 140)
            
            // Base disc (full circle with gradient-like effect)
            let baseRadius: CGFloat = 120
            let basePath = UIBezierPath(arcCenter: centerPoint,
                                        radius: baseRadius,
                                        startAngle: 0,
                                        endAngle: .pi * 2,
                                        clockwise: true)
            
            let baseLayer = CAShapeLayer()
            baseLayer.path = basePath.cgPath
            baseLayer.fillColor = color.withAlphaComponent(0.8).cgColor
            baseLayer.strokeColor = UIColor.clear.cgColor
            animationView.layer.addSublayer(baseLayer)
            self.dvdDiscLayers.append(baseLayer)
            
            // Add vinyl grooves (concentric circles to make it look realistic)
            let grooveRadii: [CGFloat] = [115, 105, 95, 85, 75, 65, 55, 45, 35]
            for radius in grooveRadii {
                let groovePath = UIBezierPath(arcCenter: centerPoint,
                                              radius: radius,
                                              startAngle: 0,
                                              endAngle: .pi * 2,
                                              clockwise: true)
                
                let grooveLayer = CAShapeLayer()
                grooveLayer.path = groovePath.cgPath
                grooveLayer.strokeColor = UIColor.black.withAlphaComponent(0.15).cgColor
                grooveLayer.fillColor = UIColor.clear.cgColor
                grooveLayer.lineWidth = 1.5
                animationView.layer.addSublayer(grooveLayer)
                self.dvdDiscLayers.append(grooveLayer)
            }
            
            // Shiny outer edge (to give depth)
            let edgeRadius: CGFloat = 120
            let edgePath = UIBezierPath(arcCenter: centerPoint,
                                        radius: edgeRadius,
                                        startAngle: 0,
                                        endAngle: .pi * 2,
                                        clockwise: true)
            
            let edgeLayer = CAShapeLayer()
            edgeLayer.path = edgePath.cgPath
            edgeLayer.strokeColor = color.withAlphaComponent(0.9).cgColor
            edgeLayer.fillColor = UIColor.clear.cgColor
            edgeLayer.lineWidth = 3
            animationView.layer.addSublayer(edgeLayer)
            self.dvdDiscLayers.append(edgeLayer)
            
            // Center label area (like a vinyl label)
            let labelRadius: CGFloat = 35
            let labelPath = UIBezierPath(arcCenter: centerPoint,
                                         radius: labelRadius,
                                         startAngle: 0,
                                         endAngle: .pi * 2,
                                         clockwise: true)
            
            let labelLayer = CAShapeLayer()
            labelLayer.path = labelPath.cgPath
            labelLayer.fillColor = UIColor.white.cgColor
            labelLayer.strokeColor = color.withAlphaComponent(0.5).cgColor
            labelLayer.lineWidth = 2
            animationView.layer.addSublayer(labelLayer)
            self.dvdDiscLayers.append(labelLayer)
            
            // Center spindle hole
            let holeRadius: CGFloat = 8
            let holePath = UIBezierPath(arcCenter: centerPoint,
                                        radius: holeRadius,
                                        startAngle: 0,
                                        endAngle: .pi * 2,
                                        clockwise: true)
            
            let holeLayer = CAShapeLayer()
            holeLayer.path = holePath.cgPath
            holeLayer.fillColor = UIColor.darkGray.cgColor
            holeLayer.strokeColor = UIColor.black.withAlphaComponent(0.3).cgColor
            holeLayer.lineWidth = 1
            animationView.layer.addSublayer(holeLayer)
            self.dvdDiscLayers.append(holeLayer)
            
            // Create music symbols around the disc (with more spacing)
            self.createMusicSymbols(in: animationView, color: color)
            
            // Add instruction label below the DVD (will show START, countdown, then instruction)
            let instructionLabel = UILabel()
            instructionLabel.text = "START"
            instructionLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
            instructionLabel.textColor = color
            instructionLabel.textAlignment = .center
            instructionLabel.numberOfLines = 2
            instructionLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(instructionLabel)
            
            NSLayoutConstraint.activate([
                instructionLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 20),
                instructionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                instructionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
            ])
            
            self.instructionLabel = instructionLabel
            self.dvdInstructionLabel = instructionLabel // Same label for both
            
            // Show the animation immediately with START text (like breathing)
            animationView.alpha = 1
        }
    }
    
    func createMusicSymbols(in containerView: UIView, color: UIColor) {
        let symbols = ["♪", "♫", "🎵", "🎶", "♪", "♫"]
        let centerPoint = CGPoint(x: 140, y: 140)
        let radius: CGFloat = 150 // Just outside the disc
        
        // Distribute symbols evenly around the entire disc
        for (index, symbol) in symbols.enumerated() {
            let angle = (CGFloat(index) / CGFloat(symbols.count)) * 2 * .pi - .pi / 2 // Start from top
            let x = centerPoint.x + radius * cos(angle)
            let y = centerPoint.y + radius * sin(angle)
            
            let label = UILabel()
            label.text = symbol
            label.font = UIFont.systemFont(ofSize: 32)
            label.textColor = color.withAlphaComponent(0.7)
            label.textAlignment = .center
            label.frame = CGRect(x: x - 20, y: y - 20, width: 40, height: 40)
            label.alpha = 0 // Start hidden
            containerView.addSubview(label)
            
            self.musicSymbolLabels.append(label)
        }
    }
    
    func startDVDAnimation() {
        guard exerciseType.lowercased() == "calmingsounds",
              let _ = dvdAnimationView,
              let label = instructionLabel else { return }
        
        // Start 3-second countdown
        countdownValue = 3
        label.text = "\(countdownValue)"
        label.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.countdownValue -= 1
            
            if self.countdownValue > 0 {
                // Update countdown number with fade animation
                UIView.transition(with: label,
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                    label.text = "\(self.countdownValue)"
                })
            } else {
                // Countdown finished, start the actual animation
                timer.invalidate()
                self.countdownTimer = nil
                
                // Show first calming instruction
                self.currentInstructionIndex = 0
                UIView.transition(with: label,
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                    label.text = self.calmingInstructions[0]
                    label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                })
                
                // Speak the first instruction
                self.speakInstruction(self.calmingInstructions[0])
                
                // Start disc rotation
                self.rotateDVD()
                
                // Animate music symbols
                self.animateMusicSymbols()
                
                // Start instruction timer (change every 24 seconds)
                self.dvdInstructionTimer = Timer.scheduledTimer(withTimeInterval: 24.0, repeats: true) { [weak self] _ in
                    self?.updateDVDInstruction()
                }
            }
        }
    }
    
    func rotateDVD() {
        guard let animationView = dvdAnimationView else { return }
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 8.0 // Smooth, visible rotation
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        animationView.layer.add(rotation, forKey: "dvdRotation")
        self.dvdRotationAnimation = rotation
    }
    
    func animateMusicSymbols() {
        for (index, label) in musicSymbolLabels.enumerated() {
            let delay = Double(index) * 0.2
            
            // Fade in
            UIView.animate(withDuration: 1.0, delay: delay, options: [.repeat, .autoreverse]) {
                label.alpha = 0.9
            }
            
            // Floating animation
            let originalY = label.frame.origin.y
            UIView.animate(withDuration: 3.0, delay: delay, options: [.repeat, .autoreverse, .curveEaseInOut]) {
                label.frame.origin.y = originalY - 15
            }
            
            // Pulsing scale
            UIView.animate(withDuration: 2.0, delay: delay, options: [.repeat, .autoreverse]) {
                label.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
        }
    }
    
    func updateDVDInstruction() {
        guard let label = instructionLabel else { return }
        
        // Move to next instruction
        currentInstructionIndex = (currentInstructionIndex + 1) % calmingInstructions.count
        let newInstruction = calmingInstructions[currentInstructionIndex]
        
        // Fade out
        UIView.animate(withDuration: 0.3, animations: {
            label.alpha = 0
        }) { _ in
            // Change text
            label.text = newInstruction
            
            // Speak the instruction
            self.speakInstruction(newInstruction)
            
            // Fade in
            UIView.animate(withDuration: 0.3) {
                label.alpha = 1
            }
        }
    }
    
    func stopDVDAnimation() {
        guard let animationView = dvdAnimationView,
              let label = instructionLabel else { return }
        
        // Stop timers
        dvdInstructionTimer?.invalidate()
        dvdInstructionTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // Remove rotation animation
        animationView.layer.removeAnimation(forKey: "dvdRotation")
        
        // Stop music symbol animations
        for symbolLabel in musicSymbolLabels {
            symbolLabel.layer.removeAllAnimations()
            symbolLabel.alpha = 0
        }
        
        // Reset label to START
        label.text = "START"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        
        // Reset
        currentInstructionIndex = 0
        countdownValue = 3
    }
    
    // MARK: - Bubble Animation
    private func addBubblesToBreathingView(_ containerView: UIView, color: UIColor) {
        // Create 8 bubbles for ambient effect
        for _ in 0..<8 {
            let size = CGFloat.random(in: 20...50)
            let bubble = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
            
            // Use the exercise color with low opacity for bubbles
            bubble.backgroundColor = color.withAlphaComponent(0.1)
            bubble.layer.cornerRadius = size / 2
            bubble.layer.shadowColor = color.cgColor
            bubble.layer.shadowOpacity = 0.5
            bubble.layer.shadowRadius = 15
            
            let maxX = containerView.bounds.width - size
            let maxY = containerView.bounds.height - size
            bubble.frame.origin = CGPoint(x: CGFloat.random(in: 0...maxX), y: CGFloat.random(in: 0...maxY))
            
            containerView.insertSubview(bubble, at: 0) // Insert behind other elements
            animateBreathingBubble(bubble, in: containerView)
        }
    }
    
    private func animateBreathingBubble(_ bubble: UIView, in parentView: UIView) {
        let size = bubble.frame.width
        let endX = CGFloat.random(in: 0...(parentView.bounds.width - size))
        let endY = CGFloat.random(in: 0...(parentView.bounds.height - size))
        
        UIView.animate(withDuration: Double.random(in: 5.0...8.0),
                       delay: 0,
                       options: [.curveEaseInOut, .allowUserInteraction],
                       animations: {
            bubble.frame.origin = CGPoint(x: endX, y: endY)
        }) { [weak self] _ in
            self?.animateBreathingBubble(bubble, in: parentView)
        }
    }
}

// MARK: - Eye Relaxation Animation
extension BreathingViewController {

    func setupEyeRelaxationAnimation() {
        guard let containerView = rectangularView else { return }
        let color = UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Canvas
            let canvas = UIView()
            canvas.backgroundColor = .clear
            canvas.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(canvas)
            NSLayoutConstraint.activate([
                canvas.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                canvas.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -120),
                canvas.widthAnchor.constraint(equalToConstant: 300),
                canvas.heightAnchor.constraint(equalToConstant: 300)
            ])
            self.eyeAnimationView = canvas

            let cx: CGFloat = 150, cy: CGFloat = 150
            _ = cx; _ = cy // suppress unused warning — kept for coordinate reference

            // CUTE FACE with two anime-style eyes

            // Face oval (warm skin tone background)
            let faceLayer = CAShapeLayer()
            faceLayer.path = UIBezierPath(roundedRect: CGRect(x: 28, y: 28, width: 244, height: 210),
                                          cornerRadius: 108).cgPath
            faceLayer.fillColor   = UIColor(red: 0.97, green: 0.90, blue: 0.82, alpha: 1.0).cgColor
            faceLayer.shadowColor = color.cgColor
            faceLayer.shadowRadius = 18; faceLayer.shadowOpacity = 0.20; faceLayer.shadowOffset = .zero
            canvas.layer.addSublayer(faceLayer)
            self.eyeGlowLayer = faceLayer
            // Gentle face glow breathe
            let fg = CABasicAnimation(keyPath: "opacity")
            fg.fromValue = 0.88; fg.toValue = 1.0; fg.duration = 3.5
            fg.repeatCount = .infinity; fg.autoreverses = true
            fg.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            faceLayer.add(fg, forKey: "faceGlow")

            // Two eyes
            let hw: CGFloat   = 40   // eye half-width
            let ir: CGFloat   = 24   // iris radius (large = cute)
            let pr: CGFloat   = 10   // pupil radius
            let eyeY: CGFloat = 142
            let eyeCentres: [(CGFloat, CGFloat)] = [(100, eyeY), (200, eyeY)]
            let lidColor = UIColor(red: 0.93, green: 0.82, blue: 0.71, alpha: 1.0)

            for (ei, (ecx, ecy)) in eyeCentres.enumerated() {

                // Curved eyebrow — stored so instructions can animate it
                let brow = UIBezierPath()
                brow.move(to:    CGPoint(x: ecx - 26, y: ecy - 50))
                brow.addCurve(to: CGPoint(x: ecx + 26, y: ecy - 50),
                              controlPoint1: CGPoint(x: ecx - 10, y: ecy - 60),
                              controlPoint2: CGPoint(x: ecx + 10, y: ecy - 60))
                let browL = CAShapeLayer()
                browL.path = brow.cgPath
                browL.strokeColor = UIColor(red: 0.68, green: 0.48, blue: 0.30, alpha: 0.9).cgColor
                browL.fillColor = UIColor.clear.cgColor
                browL.lineWidth = 3.2; browL.lineCap = .round
                canvas.layer.addSublayer(browL)
                // Store reference and add gentle idle float
                if ei == 0 { self.eyeBrowLayerL = browL } else { self.eyeBrowLayerR = browL }
                let idleFloat = CABasicAnimation(keyPath: "transform.translation.y")
                idleFloat.fromValue = 0; idleFloat.toValue = -3
                idleFloat.duration = 2.8; idleFloat.repeatCount = .infinity
                idleFloat.autoreverses = true
                idleFloat.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                browL.add(idleFloat, forKey: "browIdle")

                // Eye white (rounder almond)
                let wp = UIBezierPath()
                wp.move(to: CGPoint(x: ecx - hw, y: ecy))
                wp.addCurve(to: CGPoint(x: ecx + hw, y: ecy),
                            controlPoint1: CGPoint(x: ecx - hw*0.40, y: ecy - hw*0.80),
                            controlPoint2: CGPoint(x: ecx + hw*0.40, y: ecy - hw*0.80))
                wp.addCurve(to: CGPoint(x: ecx - hw, y: ecy),
                            controlPoint1: CGPoint(x: ecx + hw*0.40, y: ecy + hw*0.60),
                            controlPoint2: CGPoint(x: ecx - hw*0.40, y: ecy + hw*0.60))
                wp.close()
                let wl = CAShapeLayer()
                wl.path = wp.cgPath
                wl.fillColor = UIColor.white.cgColor
                wl.shadowColor = UIColor.black.withAlphaComponent(0.10).cgColor
                wl.shadowRadius = 4; wl.shadowOpacity = 1; wl.shadowOffset = .zero
                canvas.layer.addSublayer(wl)

                // Iris (fills most of eye)
                let irisL = CAShapeLayer()
                irisL.path = UIBezierPath(ovalIn: CGRect(x: ecx-ir, y: ecy-ir, width: ir*2, height: ir*2)).cgPath
                irisL.fillColor = color.cgColor
                irisL.shadowColor = color.cgColor
                irisL.shadowRadius = 6; irisL.shadowOpacity = 0.5; irisL.shadowOffset = .zero
                canvas.layer.addSublayer(irisL)
                if ei == 0 { self.eyeIrisLayer = irisL } else { self.eyeIrisLayerR = irisL }
                let ip = CABasicAnimation(keyPath: "transform.scale")
                ip.fromValue = 0.93; ip.toValue = 1.04; ip.duration = 3.5
                ip.repeatCount = .infinity; ip.autoreverses = true
                ip.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                irisL.add(ip, forKey: "irisPulse")

                // Pupil
                let pupL = CAShapeLayer()
                pupL.path = UIBezierPath(ovalIn: CGRect(x: ecx-pr, y: ecy-pr, width: pr*2, height: pr*2)).cgPath
                pupL.fillColor = UIColor(white: 0.05, alpha: 1).cgColor
                canvas.layer.addSublayer(pupL)
                if ei == 0 { self.eyePupilLayer = pupL } else { self.eyePupilLayerR = pupL }

                // Main highlight (anime style — large upper-right oval)
                let hl1 = CAShapeLayer()
                hl1.path = UIBezierPath(ovalIn: CGRect(x: ecx+4, y: ecy-ir+4, width: 14, height: 16)).cgPath
                hl1.fillColor = UIColor.white.cgColor
                canvas.layer.addSublayer(hl1)
                if ei == 0 { self.eyeHighlightLayer = hl1 } else { self.eyeHighlightLayerR = hl1 }

                // Secondary tiny highlight
                let hl2 = CAShapeLayer()
                hl2.path = UIBezierPath(ovalIn: CGRect(x: ecx-ir+4, y: ecy+6, width: 7, height: 7)).cgPath
                hl2.fillColor = UIColor.white.withAlphaComponent(0.65).cgColor
                canvas.layer.addSublayer(hl2)

                // Top eyelid — masked to eye white so fill stays inside almond
                let topL = CAShapeLayer()
                topL.path      = self.openLidPath(cx: ecx, cy: ecy, hw: hw, isTop: true)
                topL.fillColor = lidColor.cgColor
                topL.opacity   = 0
                let topMask = CAShapeLayer()
                topMask.path = wp.cgPath          // clip to eye-white almond
                topL.mask = topMask
                canvas.layer.addSublayer(topL)
                if ei == 0 { self.eyeLidTopLayer = topL } else { self.eyeLidTopLayerR = topL }

                // Bottom eyelid — masked to eye white
                let botL = CAShapeLayer()
                botL.path      = self.openLidPath(cx: ecx, cy: ecy, hw: hw, isTop: false)
                botL.fillColor = lidColor.cgColor
                botL.opacity   = 0
                let botMask = CAShapeLayer()
                botMask.path = wp.cgPath
                botL.mask = botMask
                canvas.layer.addSublayer(botL)
                if ei == 0 { self.eyeLidBotLayer = botL } else { self.eyeLidBotLayerR = botL }
            }

            // Rosy cheeks
            for (chx, chy) in [(CGFloat(56), CGFloat(175)), (CGFloat(244), CGFloat(175))] {
                let cheek = CAShapeLayer()
                cheek.path = UIBezierPath(ovalIn: CGRect(x: chx-28, y: chy-14, width: 56, height: 28)).cgPath
                cheek.fillColor = UIColor(red: 1.0, green: 0.65, blue: 0.65, alpha: 0.32).cgColor
                canvas.layer.addSublayer(cheek)
            }

            // Floating sparkle stars around face
            let sparklePositions: [CGPoint] = [
                CGPoint(x: 8, y: 65), CGPoint(x: 278, y: 58), CGPoint(x: 148, y: 8),
                CGPoint(x: 14, y: 230), CGPoint(x: 274, y: 225), CGPoint(x: 148, y: 255)
            ]
            for (i, pt) in sparklePositions.enumerated() {
                let dot = UIView(frame: CGRect(x: pt.x, y: pt.y, width: 10, height: 10))
                dot.backgroundColor = color.withAlphaComponent(0.70)
                dot.layer.cornerRadius = 5
                dot.alpha = 0.15
                canvas.addSubview(dot)
                UIView.animate(withDuration: 1.9, delay: Double(i) * 0.38,
                               options: [.repeat, .autoreverse, .curveEaseInOut]) {
                    dot.alpha = 1.0
                    dot.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
                }
            }

            // Instruction label
            let lbl = UILabel()
            lbl.text = "START"
            lbl.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lbl.textColor = color
            lbl.textAlignment = .center
            lbl.numberOfLines = 2
            lbl.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.topAnchor.constraint(equalTo: canvas.bottomAnchor, constant: 18),
                lbl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                lbl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
            ])
            self.eyeInstructionLabel = lbl
            // Iris starts centered — no movement until session begins
        }
    }

    // Open position: lid rect sits just outside the eye white boundary → masked away = invisible
    private func openLidPath(cx: CGFloat, cy: CGFloat, hw: CGFloat = 72, isTop: Bool) -> CGPath {
        if isTop {
            // rect entirely above the eye: from (cy - hw) - 50 to (cy - hw)
            return UIBezierPath(rect: CGRect(x: cx - hw - 10, y: cy - hw - 50,
                                            width: hw * 2 + 20, height: 50)).cgPath
        } else {
            // rect entirely below the eye: from (cy + hw*0.60) to (cy + hw*0.60) + 50
            return UIBezierPath(rect: CGRect(x: cx - hw - 10, y: cy + hw * 0.60,
                                            width: hw * 2 + 20, height: 50)).cgPath
        }
    }

    // Closed position: lid rect sweeps in from edge to eye centre → masked to almond = half filled
    private func closedLidPath(cx: CGFloat, cy: CGFloat, hw: CGFloat = 72, isTop: Bool) -> CGPath {
        if isTop {
            // rect from (cy - hw) - 50 down to eye centre cy → fills top half of almond
            return UIBezierPath(rect: CGRect(x: cx - hw - 10, y: cy - hw - 50,
                                            width: hw * 2 + 20, height: hw + 50 + 4)).cgPath
        } else {
            // rect from eye centre cy down past (cy + hw*0.60) + 50 → fills bottom half
            return UIBezierPath(rect: CGRect(x: cx - hw - 10, y: cy,
                                            width: hw * 2 + 20, height: hw * 0.60 + 50 + 4)).cgPath
        }
    }

    // MARK: - Instruction-synced eye movement

    /// Drives iris position + eyelid state + eyebrow to match each instruction.
    private func animateEyeForInstruction(_ index: Int) {
        switch index {
        case 0:
            // Close eyes slowly — brows relax down slightly
            moveIris(tx: 0, ty: 0, duration: 0.6)
            animateEyebrow(ty: 4, duration: 0.6)   // softly lower
            slowBlink()

        case 1:
            // Roll upward — brows rise with surprise
            moveIris(tx: 0, ty: -20, duration: 1.4)
            animateEyebrow(ty: -10, duration: 1.2)  // brows up

        case 2:
            // Roll right — brows shift very slightly (curious tilt effect)
            moveIris(tx: 20, ty: 0, duration: 1.4)
            animateEyebrow(ty: -4, duration: 1.0)

        case 3:
            // Phase 1: down — brows furrow/lower
            moveIris(tx: 0, ty: 20, duration: 1.4)
            animateEyebrow(ty: 6, duration: 1.0)    // brows down = concentration
            // Phase 2: left (after 12 s) — brows relax a little
            DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) { [weak self] in
                self?.moveIris(tx: -20, ty: 0, duration: 1.4)
                self?.animateEyebrow(ty: 2, duration: 1.0)
            }

        case 4:
            // Return to centre + gentle blink — brows settle back
            moveIris(tx: 0, ty: 0, duration: 1.0)
            animateEyebrow(ty: 0, duration: 0.9)    // back to rest
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.performBlink(slow: true)
            }

        default:
            moveIris(tx: 0, ty: 0, duration: 0.6)
            animateEyebrow(ty: 0, duration: 0.6)
        }
    }

    /// Smoothly translates both eyebrow layers by `ty` points.
    private func animateEyebrow(ty: CGFloat, duration: CFTimeInterval) {
        for browLayer in [eyeBrowLayerL, eyeBrowLayerR].compactMap({ $0 }) {
            let anim = CABasicAnimation(keyPath: "transform.translation.y")
            // Read current translated position as fromValue, animate to new ty
            let currentValue = (browLayer.presentation() ?? browLayer)
                .value(forKeyPath: "transform.translation.y") as? CGFloat ?? 0
            anim.fromValue = currentValue
            anim.toValue   = ty
            anim.duration  = duration
            anim.fillMode  = .forwards
            anim.isRemovedOnCompletion = false
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            browLayer.add(anim, forKey: "browMove")
        }
    }

    private func moveIris(tx: CGFloat, ty: CGFloat, duration: CFTimeInterval) {
        // Move all 6 layers (left + right iris, pupil, highlight) together
        let layers = [eyeIrisLayer, eyePupilLayer, eyeHighlightLayer,
                      eyeIrisLayerR, eyePupilLayerR, eyeHighlightLayerR].compactMap { $0 }
        for layer in layers {
            let anim = CABasicAnimation(keyPath: "transform.translation")
            anim.toValue    = NSValue(cgSize: CGSize(width: tx, height: ty))
            anim.duration   = duration
            anim.fillMode   = .forwards
            anim.isRemovedOnCompletion = false
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(anim, forKey: "irisMove")
        }
    }

    private func slowBlink() {
        performBlink(slow: true)
        // Blink again after 2 s for "gently close"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.performBlink(slow: true)
        }
    }

    private func performBlink(slow: Bool = false) {
        let hw: CGFloat = 40
        let closeDuration: CFTimeInterval = slow ? 0.35 : 0.12
        let totalDuration = closeDuration * 2   // close + autoReverse open

        let eyePairs: [(CAShapeLayer?, CAShapeLayer?, CGFloat, CGFloat)] = [
            (eyeLidTopLayer,  eyeLidBotLayer,  100, 142),
            (eyeLidTopLayerR, eyeLidBotLayerR, 200, 142)
        ]
        for (topLid, botLid, ecx, ecy) in eyePairs {
            guard let top = topLid, let bot = botLid else { continue }

            func animLid(_ layer: CAShapeLayer, isTop: Bool) {
                // Path: open → closed → open
                let pathAnim = CABasicAnimation(keyPath: "path")
                pathAnim.fromValue  = openLidPath(cx: ecx, cy: ecy, hw: hw, isTop: isTop)
                pathAnim.toValue    = closedLidPath(cx: ecx, cy: ecy, hw: hw, isTop: isTop)
                pathAnim.duration   = closeDuration
                pathAnim.autoreverses  = true
                pathAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

                // Opacity: 0 → 1 instantly, stay 1, → 0 at the end
                let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
                opacityAnim.values   = [0, 1, 1, 0] as [Float]
                opacityAnim.keyTimes = [0, 0.02, 0.98, 1.0]
                opacityAnim.duration = totalDuration

                let group = CAAnimationGroup()
                group.animations = [pathAnim, opacityAnim]
                group.duration   = totalDuration
                layer.add(group, forKey: "blink")
            }
            animLid(top, isTop: true)
            animLid(bot, isTop: false)
        }
    }

    func startEyeRelaxationSession() {
        eyeInstructionTimer?.invalidate()
        currentEyeInstructionIndex = 0

        // Start 3-second countdown
        countdownValue = 3
        let countLabel = eyeInstructionLabel ?? instructionLabel
        countLabel?.text = "\(countdownValue)"
        countLabel?.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.countdownValue -= 1
            
            if self.countdownValue > 0 {
                UIView.transition(with: countLabel ?? UILabel(),
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                    countLabel?.text = "\(self.countdownValue)"
                })
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                
                self.elapsedTime = 0
                self.timerSlider.value = 0
                self.currentTimeLabel.text = "0:00"
                self.audioPlayer?.play()
                
                let first = self.eyeInstructions[0]
                UIView.transition(with: self.eyeInstructionLabel ?? UILabel(),
                                  duration: 0.4, options: .transitionCrossDissolve) {
                    self.eyeInstructionLabel?.text = first
                    self.eyeInstructionLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                }
                self.speakInstruction(first)
                self.animateEyeForInstruction(0)

                self.eyeInstructionTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.currentEyeInstructionIndex = (self.currentEyeInstructionIndex + 1) % self.eyeInstructions.count
                    let idx  = self.currentEyeInstructionIndex
                    let text = self.eyeInstructions[idx]
                    UIView.transition(with: self.eyeInstructionLabel ?? UILabel(),
                                      duration: 0.4, options: .transitionCrossDissolve) {
                        self.eyeInstructionLabel?.text = text
                    }
                    self.speakInstruction(text)
                    self.animateEyeForInstruction(idx)
                }

                self.mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.updateProgress()
                }
            }
        }
    }

    func stopEyeRelaxationAnimation() {
        eyeInstructionTimer?.invalidate()
        eyeInstructionTimer = nil
        // Reset iris to centre
        moveIris(tx: 0, ty: 0, duration: 0.5)
        eyeAnimationView?.layer.removeAllAnimations()
        eyeAnimationView?.subviews.forEach { $0.layer.removeAllAnimations() }
        eyeInstructionLabel?.text = "START"
        currentEyeInstructionIndex = 0
    }
}
// MARK: - Meditation Animation
extension BreathingViewController {

    func setupMeditationAnimation() {
        guard let containerView = rectangularView else { return }
        let teal = UIColor(red: 0.20, green: 0.73, blue: 0.60, alpha: 1.0)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Canvas
            let canvas = UIView()
            canvas.backgroundColor = .clear
            canvas.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(canvas)
            NSLayoutConstraint.activate([
                canvas.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                canvas.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -120),
                canvas.widthAnchor.constraint(equalToConstant: 290),
                canvas.heightAnchor.constraint(equalToConstant: 295)
            ])
            self.meditationAnimationView = canvas

            // Canvas centre (fixed — never rotated)
            let cx: CGFloat = 145, cy: CGFloat = 148

            // Static rainbow mandala petals (background)
            // Each ring is its own layer added to a dedicated mandala container.
            // Nothing on this canvas ever rotates.
            let mandalaContainer = CALayer()
            mandalaContainer.frame = canvas.layer.bounds
            canvas.layer.addSublayer(mandalaContainer)

            struct Ring { let radius: CGFloat; let petalCount: Int; let color: UIColor }
            let rings: [Ring] = [
                Ring(radius: 128, petalCount: 16, color: UIColor(red:0.88,green:0.14,blue:0.10,alpha:0.65)),
                Ring(radius: 113, petalCount: 16, color: UIColor(red:1.00,green:0.42,blue:0.08,alpha:0.60)),
                Ring(radius:  98, petalCount: 14, color: UIColor(red:1.00,green:0.80,blue:0.08,alpha:0.55)),
                Ring(radius:  83, petalCount: 12, color: UIColor(red:0.12,green:0.76,blue:0.34,alpha:0.55)),
                Ring(radius:  68, petalCount: 12, color: UIColor(red:0.10,green:0.55,blue:0.92,alpha:0.55)),
                Ring(radius:  53, petalCount: 10, color: UIColor(red:0.28,green:0.18,blue:0.86,alpha:0.55)),
                Ring(radius:  38, petalCount:  8, color: UIColor(red:0.64,green:0.10,blue:0.88,alpha:0.50)),
            ]

            for ring in rings {
                let petalPath = UIBezierPath()
                let n          = ring.petalCount
                let angleStep  = (2.0 * CGFloat.pi) / CGFloat(n)
                let inner      = ring.radius * 0.68   // petal base radius

                for p in 0..<n {
                    let a  = CGFloat(p) * angleStep - CGFloat.pi / 2
                    // tip of petal
                    let tipX = cx + cos(a) * ring.radius
                    let tipY = cy + sin(a) * ring.radius
                    // base-left & base-right on inner ring
                    let aL = a - angleStep * 0.44
                    let aR = a + angleStep * 0.44
                    let bLx = cx + cos(aL) * inner;  let bLy = cy + sin(aL) * inner
                    let bRx = cx + cos(aR) * inner;  let bRy = cy + sin(aR) * inner
                    petalPath.move(to: CGPoint(x: bLx, y: bLy))
                    petalPath.addQuadCurve(to: CGPoint(x: bRx, y: bRy),
                                           controlPoint: CGPoint(x: tipX, y: tipY))
                }

                let rl = CAShapeLayer()
                rl.path        = petalPath.cgPath
                rl.strokeColor = ring.color.cgColor
                rl.fillColor   = ring.color.withAlphaComponent(0.07).cgColor
                rl.lineWidth   = 1.4
                mandalaContainer.addSublayer(rl)
            }

            // Outer dotted boundary ring
            let dottedRing = CAShapeLayer()
            dottedRing.path = UIBezierPath(ovalIn: CGRect(x: cx-130, y: cy-130,
                                                           width: 260, height: 260)).cgPath
            dottedRing.strokeColor = UIColor(red:0.85,green:0.10,blue:0.10,alpha:0.28).cgColor
            dottedRing.fillColor   = UIColor.clear.cgColor
            dottedRing.lineWidth   = 1.0; dottedRing.lineDashPattern = [3, 5]
            mandalaContainer.addSublayer(dottedRing)

            // Wavy positive-energy lines radiating in 8 directions
            // Each direction: a sine-wave bezier path that animates outward
            // using strokeEnd (front) / strokeStart (tail) flowing from figure
            // body to the mandala boundary, then repeats.
            let waveContainer = CALayer()
            waveContainer.frame = canvas.layer.bounds
            canvas.layer.addSublayer(waveContainer)

            // (angle in radians, chakra colour for that quadrant)
            let waveDirections: [(CGFloat, UIColor)] = [
                (-.pi/2,       UIColor(red:0.65,green:0.10,blue:0.88,alpha:1)),  // up       – violet
                (-.pi/4,       UIColor(red:0.28,green:0.20,blue:0.88,alpha:1)),  // up-right – indigo
                (0,            UIColor(red:0.14,green:0.58,blue:0.94,alpha:1)),  // right    – blue
                (.pi/4,        UIColor(red:0.14,green:0.80,blue:0.36,alpha:1)),  // down-right – green
                (.pi/2,        UIColor(red:1.00,green:0.84,blue:0.10,alpha:1)),  // down     – yellow
                (.pi*3/4,      UIColor(red:1.00,green:0.48,blue:0.10,alpha:1)),  // down-left – orange
                (.pi,          UIColor(red:0.90,green:0.12,blue:0.18,alpha:1)),  // left     – red
                (-.pi*3/4,     UIColor(red:0.72,green:0.28,blue:0.92,alpha:1)),  // up-left  – violet-pink
            ]

            let waveInner:    CGFloat = 48   // start radius (just outside figure)
            let waveOuter:    CGFloat = 162  // end radius — beyond canvas so waves exit fully
            let waveAmplitude: CGFloat = 12  // transverse oscillation (bold)
            let waveCycles    = 4            // sine half-cycles per path

            for (di, (angle, wColor)) in waveDirections.enumerated() {
                // Forward unit vector and perpendicular
                let fx = cos(angle), fy = sin(angle)
                let px = -sin(angle), py = cos(angle)

                // Build the sine-wave bezier path along the direction
                let wavePath = UIBezierPath()
                let totalLen  = waveOuter - waveInner
                let segLen    = totalLen / CGFloat(waveCycles)

                let p0 = CGPoint(x: cx + fx * waveInner, y: cy + fy * waveInner)
                wavePath.move(to: p0)

                for c in 0..<waveCycles {
                    let sign: CGFloat = (c % 2 == 0) ? 1 : -1
                    let dMid  = waveInner + (CGFloat(c) + 0.5) * segLen
                    let dEnd  = waveInner + CGFloat(c + 1)     * segLen
                    let ctrl  = CGPoint(x: cx + fx * dMid + px * waveAmplitude * sign,
                                        y: cy + fy * dMid + py * waveAmplitude * sign)
                    let endPt = CGPoint(x: cx + fx * dEnd, y: cy + fy * dEnd)
                    wavePath.addQuadCurve(to: endPt, controlPoint: ctrl)
                }

                // Two copies per direction, offset by half duration → continuous flow
                let waveDur: Double = 1.8
                for copy in 0..<2 {
                    let waveLayer = CAShapeLayer()
                    waveLayer.path        = wavePath.cgPath
                    waveLayer.fillColor   = UIColor.clear.cgColor
                    waveLayer.strokeColor = wColor.withAlphaComponent(0.85).cgColor
                    waveLayer.lineWidth   = 4.0
                    waveLayer.lineCap     = .round
                    waveLayer.lineJoin    = .round
                    waveLayer.strokeStart = 0
                    waveLayer.strokeEnd   = 0
                    waveLayer.opacity     = 0
                    waveContainer.addSublayer(waveLayer)

                    let baseDelay = Double(di) * 0.14 + Double(copy) * waveDur * 0.5

                    // strokeEnd sweeps 0 → 1 (wave front travels outward)
                    let endAnim = CABasicAnimation(keyPath: "strokeEnd")
                    endAnim.fromValue = 0.0; endAnim.toValue = 1.0
                    endAnim.duration  = waveDur
                    endAnim.beginTime = CACurrentMediaTime() + baseDelay
                    endAnim.repeatCount = .infinity
                    endAnim.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    waveLayer.add(endAnim, forKey: "waveEnd")

                    // strokeStart sweeps 0 → 1 with lag (wave tail follows)
                    let lag: Double = waveDur * 0.40
                    let startAnim = CABasicAnimation(keyPath: "strokeStart")
                    startAnim.fromValue = 0.0; startAnim.toValue = 1.0
                    startAnim.duration  = waveDur
                    startAnim.beginTime = CACurrentMediaTime() + baseDelay + lag
                    startAnim.repeatCount = .infinity
                    startAnim.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    waveLayer.add(startAnim, forKey: "waveStart")

                    // Opacity: fade in at start, fade out toward end
                    let opAnim = CAKeyframeAnimation(keyPath: "opacity")
                    opAnim.values   = [0, 1.0, 0.6, 0]
                    opAnim.keyTimes = [0, 0.12, 0.75, 1.0]
                    opAnim.duration = waveDur
                    opAnim.beginTime = CACurrentMediaTime() + baseDelay
                    opAnim.repeatCount = .infinity
                    waveLayer.add(opAnim, forKey: "waveOpacity")
                }
            }

            // Lotus-pose silhouette — matches reference image
            let figColor = UIColor(red:0.09, green:0.08, blue:0.12, alpha:0.95).cgColor
            let headCY: CGFloat = cy - 94   // head centre (also anchor for chakra spine)

            // HEAD — clean oval
            let headSL = CAShapeLayer()
            headSL.path = UIBezierPath(
                ovalIn: CGRect(x: cx-20, y: headCY-24, width: 40, height: 48)).cgPath
            headSL.fillColor = figColor
            canvas.layer.addSublayer(headSL)

            // NECK — short rectangle
            let neckSL = CAShapeLayer()
            neckSL.path = UIBezierPath(
                roundedRect: CGRect(x: cx-9, y: headCY+22, width: 18, height: 14),
                cornerRadius: 2).cgPath
            neckSL.fillColor = figColor
            canvas.layer.addSublayer(neckSL)

            // BODY + ARMS + LEGS — single continuous clockwise outline
            // Landmark Y-values (all relative to headCY):
            //   headCY +32  = shoulder line
            //   headCY +80  = upper-arm / elbow
            //   headCY +112 = forearm / hand on knee
            //   headCY +132 = outer knee (widest cross-section)
            //   headCY +178 = foot level
            //   headCY +192 = bottom of crossed legs
            let hY = headCY
            let body = UIBezierPath()

            // Start: right collarbone / neck-shoulder junction
            body.move(to: CGPoint(x: cx+14, y: hY+32))

            // Right shoulder broadening outward
            body.addCurve(to:           CGPoint(x: cx+44, y: hY+46),
                          controlPoint1: CGPoint(x: cx+26, y: hY+26),
                          controlPoint2: CGPoint(x: cx+48, y: hY+32))

            // Right upper arm sweeping out-and-down (arm widest here)
            body.addCurve(to:           CGPoint(x: cx+70, y: hY+88),
                          controlPoint1: CGPoint(x: cx+56, y: hY+56),
                          controlPoint2: CGPoint(x: cx+78, y: hY+72))

            // Right forearm — concavity as forearm rests inward on thigh
            body.addCurve(to:           CGPoint(x: cx+52, y: hY+110),
                          controlPoint1: CGPoint(x: cx+74, y: hY+100),
                          controlPoint2: CGPoint(x: cx+64, y: hY+110))

            // Right hand / mudra bump on knee
            body.addCurve(to:           CGPoint(x: cx+42, y: hY+116),
                          controlPoint1: CGPoint(x: cx+48, y: hY+112),
                          controlPoint2: CGPoint(x: cx+46, y: hY+118))

            // Outer right knee sticks out wider than hand (distinctive lotus shape)
            body.addCurve(to:           CGPoint(x: cx+90, y: hY+140),
                          controlPoint1: CGPoint(x: cx+44, y: hY+124),
                          controlPoint2: CGPoint(x: cx+94, y: hY+122))

            // Right outer leg sweeping down to right foot
            body.addCurve(to:           CGPoint(x: cx+72, y: hY+182),
                          controlPoint1: CGPoint(x: cx+96, y: hY+156),
                          controlPoint2: CGPoint(x: cx+86, y: hY+182))

            // Bottom — right foot arcs to centre
            body.addCurve(to:           CGPoint(x: cx, y: hY+194),
                          controlPoint1: CGPoint(x: cx+52, y: hY+188),
                          controlPoint2: CGPoint(x: cx+24, y: hY+194))

            // Bottom — centre arcs to left foot
            body.addCurve(to:           CGPoint(x: cx-72, y: hY+182),
                          controlPoint1: CGPoint(x: cx-24, y: hY+194),
                          controlPoint2: CGPoint(x: cx-52, y: hY+188))

            // Left outer leg sweeping up from left foot
            body.addCurve(to:           CGPoint(x: cx-90, y: hY+140),
                          controlPoint1: CGPoint(x: cx-86, y: hY+182),
                          controlPoint2: CGPoint(x: cx-96, y: hY+156))

            // Outer left knee back inward to left hand
            body.addCurve(to:           CGPoint(x: cx-42, y: hY+116),
                          controlPoint1: CGPoint(x: cx-94, y: hY+122),
                          controlPoint2: CGPoint(x: cx-44, y: hY+124))

            // Left hand / mudra bump
            body.addCurve(to:           CGPoint(x: cx-52, y: hY+110),
                          controlPoint1: CGPoint(x: cx-46, y: hY+118),
                          controlPoint2: CGPoint(x: cx-48, y: hY+112))

            // Left forearm going up — matching concavity
            body.addCurve(to:           CGPoint(x: cx-70, y: hY+88),
                          controlPoint1: CGPoint(x: cx-64, y: hY+110),
                          controlPoint2: CGPoint(x: cx-74, y: hY+100))

            // Left upper arm sweeping back up to left shoulder
            body.addCurve(to:           CGPoint(x: cx-44, y: hY+46),
                          controlPoint1: CGPoint(x: cx-78, y: hY+72),
                          controlPoint2: CGPoint(x: cx-56, y: hY+56))

            // Left shoulder to left collarbone
            body.addCurve(to:           CGPoint(x: cx-14, y: hY+32),
                          controlPoint1: CGPoint(x: cx-48, y: hY+32),
                          controlPoint2: CGPoint(x: cx-26, y: hY+26))

            // Close across neck/collarbone back to start
            body.addCurve(to:           CGPoint(x: cx+14, y: hY+32),
                          controlPoint1: CGPoint(x: cx-4, y: hY+26),
                          controlPoint2: CGPoint(x: cx+4, y: hY+26))
            body.close()

            let figureLayer = CAShapeLayer()
            figureLayer.path      = body.cgPath
            figureLayer.fillColor = figColor
            figureLayer.fillRule  = .nonZero
            canvas.layer.addSublayer(figureLayer)

            // Anchor vars for chakra spine (below)
            _ = headCY // suppress unused variable warning if headCY is needed for symmetry
            // let shoulderY removed
            let _ = 46
            let legTopY:   CGFloat = headCY + 132

            // 7 Chakra circles — vertical spine, root (bottom) → crown (top)
            // Spine runs from legTopY+52 (root) up to headCY-8 (crown).
            let spineBottom = legTopY + 52
            let spineTop    = headCY - 6
            let spineStep   = (spineBottom - spineTop) / 6.0

            let chakraData: [(CGPoint, UIColor, CGFloat)] = [
                (CGPoint(x: cx, y: spineBottom),            UIColor(red:0.90,green:0.12,blue:0.18,alpha:1), 15.0), // Root
                (CGPoint(x: cx, y: spineBottom-spineStep),  UIColor(red:1.00,green:0.48,blue:0.10,alpha:1), 14.0), // Sacral
                (CGPoint(x: cx, y: spineBottom-spineStep*2),UIColor(red:1.00,green:0.84,blue:0.10,alpha:1), 14.0), // Solar
                (CGPoint(x: cx, y: spineBottom-spineStep*3),UIColor(red:0.14,green:0.80,blue:0.36,alpha:1), 15.0), // Heart
                (CGPoint(x: cx, y: spineBottom-spineStep*4),UIColor(red:0.14,green:0.58,blue:0.94,alpha:1), 14.0), // Throat
                (CGPoint(x: cx, y: spineBottom-spineStep*5),UIColor(red:0.28,green:0.20,blue:0.88,alpha:1), 14.0), // Third Eye
                (CGPoint(x: cx, y: spineTop),               UIColor(red:0.65,green:0.10,blue:0.88,alpha:1), 13.0), // Crown
            ]

            for (i, (pt, dotColor, r)) in chakraData.enumerated() {
                let delay = Double(i) * 0.38

                // Glow halo
                let glowRing = CAShapeLayer()
                glowRing.path = UIBezierPath(ovalIn: CGRect(x: pt.x-r-5, y: pt.y-r-5,
                                                             width: (r+5)*2, height: (r+5)*2)).cgPath
                glowRing.fillColor   = dotColor.withAlphaComponent(0.22).cgColor
                glowRing.strokeColor = UIColor.clear.cgColor
                canvas.layer.addSublayer(glowRing)

                // Filled dot
                let dot = CAShapeLayer()
                dot.path = UIBezierPath(ovalIn: CGRect(x: pt.x-r, y: pt.y-r,
                                                       width: r*2, height: r*2)).cgPath
                dot.fillColor    = dotColor.cgColor
                dot.shadowColor  = dotColor.cgColor
                dot.shadowRadius = 10; dot.shadowOpacity = 0.85; dot.shadowOffset = .zero
                canvas.layer.addSublayer(dot)

                // White inner ring
                let ir: CGFloat = r * 0.56
                let innerRing = CAShapeLayer()
                innerRing.path = UIBezierPath(ovalIn: CGRect(x: pt.x-ir, y: pt.y-ir,
                                                              width: ir*2, height: ir*2)).cgPath
                innerRing.fillColor   = UIColor.clear.cgColor
                innerRing.strokeColor = UIColor.white.withAlphaComponent(0.72).cgColor
                innerRing.lineWidth   = 1.8
                canvas.layer.addSublayer(innerRing)

                // Soft pulse
                let dp = CABasicAnimation(keyPath: "opacity")
                dp.fromValue = 0.60; dp.toValue = 1.0; dp.duration = 1.8
                dp.beginTime = CACurrentMediaTime() + delay
                dp.repeatCount = .infinity; dp.autoreverses = true
                dp.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                dot.add(dp, forKey: "dotPulse")
                glowRing.add(dp, forKey: "glowPulse")
            }

            // Travelling bright light dot (instruction-driven)
            let travelDotR: CGFloat = 8
            let travelDot = CAShapeLayer()
            travelDot.path = UIBezierPath(ovalIn: CGRect(x: -travelDotR, y: -travelDotR,
                                                         width: travelDotR*2, height: travelDotR*2)).cgPath
            travelDot.fillColor    = UIColor.white.cgColor
            travelDot.shadowColor  = chakraData[0].1.cgColor
            travelDot.shadowRadius = 16; travelDot.shadowOpacity = 1.0; travelDot.shadowOffset = .zero
            travelDot.position     = CGPoint(x: cx, y: chakraData[0].0.y)
            canvas.layer.addSublayer(travelDot)
            self.meditationTravelDot = travelDot
            self.meditationChakraYPositions = chakraData.map { $0.0.y }

            let dotPulse = CABasicAnimation(keyPath: "transform.scale")
            dotPulse.fromValue = 0.88; dotPulse.toValue = 1.18; dotPulse.duration = 0.85
            dotPulse.repeatCount = .infinity; dotPulse.autoreverses = true
            dotPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            travelDot.add(dotPulse, forKey: "dotPulse")

            // Instruction label
            let lbl = UILabel()
            lbl.text = "START"
            lbl.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            lbl.textColor = teal
            lbl.textAlignment = .center
            lbl.numberOfLines = 2
            lbl.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.topAnchor.constraint(equalTo: canvas.bottomAnchor, constant: 14),
                lbl.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
                lbl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
            ])
            self.meditationInstructionLabel = lbl
        }
    }

    func startMeditationSession() {
        meditationInstructionTimer?.invalidate()
        currentMeditationIndex = 0

        // Start 3-second countdown
        countdownValue = 3
        let countLabel = meditationInstructionLabel ?? instructionLabel
        countLabel?.text = "\(countdownValue)"
        countLabel?.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.countdownValue -= 1
            
            if self.countdownValue > 0 {
                UIView.transition(with: countLabel ?? UILabel(),
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                    countLabel?.text = "\(self.countdownValue)"
                })
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                
                self.elapsedTime = 0
                self.timerSlider.value = 0
                self.currentTimeLabel.text = "0:00"
                self.audioPlayer?.play()
                
                let first = self.meditationInstructions[0]
                UIView.transition(with: self.meditationInstructionLabel ?? UILabel(),
                                  duration: 0.4, options: .transitionCrossDissolve) {
                    self.meditationInstructionLabel?.text = first
                    self.meditationInstructionLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
                }
                self.speakInstruction(first)
                self.moveMeditationDotToChakra(0)

                self.meditationInstructionTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.currentMeditationIndex = (self.currentMeditationIndex + 1) % self.meditationInstructions.count
                    let text = self.meditationInstructions[self.currentMeditationIndex]
                    UIView.transition(with: self.meditationInstructionLabel ?? UILabel(),
                                      duration: 0.4, options: .transitionCrossDissolve) {
                        self.meditationInstructionLabel?.text = text
                    }
                    self.speakInstruction(text)
                    self.moveMeditationDotToChakra(self.currentMeditationIndex)
                }

                self.mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.updateProgress()
                }
            }
        }
    }

    /// Moves the meditation travel dot to the chakra matching the current instruction index
    func moveMeditationDotToChakra(_ index: Int) {
        guard let dot = meditationTravelDot,
              index < meditationChakraYPositions.count else { return }
        
        let targetY = meditationChakraYPositions[index]
        
        let anim = CABasicAnimation(keyPath: "position.y")
        anim.toValue = targetY
        anim.duration = 0.5
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        
        dot.removeAnimation(forKey: "dotMove")
        dot.add(anim, forKey: "dotMove")
        dot.position = CGPoint(x: dot.position.x, y: targetY)
    }

    func stopMeditationAnimation() {
        meditationInstructionTimer?.invalidate()
        meditationInstructionTimer = nil
        meditationAnimationView?.layer.removeAllAnimations()
        meditationAnimationView?.subviews.forEach { $0.layer.removeAllAnimations() }
        meditationInstructionLabel?.text = "START"
        currentMeditationIndex = 0
    }
}

// MARK: - Advanced Calming Techniques (10 New Methods)
extension BreathingViewController {

    // 1. Physiological Sigh (Double inhale, long exhale)
    func setupPhysiologicalSighAnimation() {
        rectangularView.backgroundColor = .clear
        rectangularView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        rectangularView.subviews.forEach { $0.removeFromSuperview() }

        let circle = UIView()
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.backgroundColor = UIColor(red:0.10, green:0.38, blue:0.82, alpha:0.3)
        circle.layer.cornerRadius = 0 // set after layout
        circle.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        rectangularView.addSubview(circle)
        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: rectangularView.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: rectangularView.centerYAnchor),
            circle.widthAnchor.constraint(equalTo: rectangularView.widthAnchor, multiplier: 0.8),
            circle.heightAnchor.constraint(equalTo: circle.widthAnchor)
        ])
        breathingAnimationView = circle
        DispatchQueue.main.async { circle.layer.cornerRadius = circle.bounds.width / 2 }

        setupInstructionLabel(text: "Press Play to Start")
    }
    
    func startPhysiologicalSighSession() {
        audioPlayer?.play()
        let inhale1 = 1.2, inhale2 = 0.6, exhale = 4.0
        let total = inhale1 + inhale2 + exhale

        let animate = { [weak self] in
            guard let self = self, let view = self.breathingAnimationView else { return }
            UIView.animate(withDuration: inhale1, delay: 0, options: .curveEaseOut) {
                view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8); view.alpha = 0.8
                self.instructionLabel?.text = "Inhale..."
                self.speakInstruction("Inhale")
            } completion: { _ in
                UIView.animate(withDuration: inhale2, delay: 0, options: .curveEaseOut) {
                    view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0); view.alpha = 1.0
                    self.instructionLabel?.text = "Again..."
                    self.speakInstruction("Again")
                } completion: { _ in
                    UIView.animate(withDuration: exhale, delay: 0, options: .curveEaseInOut) {
                        view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5); view.alpha = 0.4
                        self.instructionLabel?.text = "Slowly Exhale..."
                        self.speakInstruction("Slowly Exhale")
                    }
                }
            }
        }
        animate()
        instructionTimer = Timer.scheduledTimer(withTimeInterval: total, repeats: true) { _ in animate() }
        mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.updateProgress() }
    }

    // 2. Coherent Breathing (5s in, 5s out)
    func setupCoherentBreathingAnimation() {
        rectangularView.backgroundColor = .clear
        rectangularView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        rectangularView.subviews.forEach { $0.removeFromSuperview() }

        let orb = UIView()
        orb.translatesAutoresizingMaskIntoConstraints = false
        orb.backgroundColor = UIColor(red:0.08, green:0.52, blue:0.44, alpha:0.4)
        orb.layer.shadowColor = UIColor(red:0.08, green:0.52, blue:0.44, alpha:1).cgColor
        orb.layer.shadowRadius = 20; orb.layer.shadowOpacity = 0.8
        orb.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        rectangularView.addSubview(orb)
        NSLayoutConstraint.activate([
            orb.centerXAnchor.constraint(equalTo: rectangularView.centerXAnchor),
            orb.centerYAnchor.constraint(equalTo: rectangularView.centerYAnchor),
            orb.widthAnchor.constraint(equalTo: rectangularView.widthAnchor, multiplier: 0.75),
            orb.heightAnchor.constraint(equalTo: orb.widthAnchor)
        ])
        breathingAnimationView = orb
        DispatchQueue.main.async { orb.layer.cornerRadius = orb.bounds.width / 2 }

        setupInstructionLabel(text: "Press Play to Start")
    }

    func startCoherentBreathingSession() {
        audioPlayer?.play()
        let duration = 5.0
        let animate = { [weak self] in
            guard let self = self, let view = self.breathingAnimationView else { return }
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0); view.alpha = 0.9
                self.instructionLabel?.text = "Inhale (5s)..."
                self.speakInstruction("Inhale for 5")
            } completion: { _ in
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
                    view.transform = CGAffineTransform(scaleX: 0.6, y: 0.6); view.alpha = 0.5
                    self.instructionLabel?.text = "Exhale (5s)..."
                    self.speakInstruction("Exhale for 5")
                }
            }
        }
        animate()
        instructionTimer = Timer.scheduledTimer(withTimeInterval: duration * 2, repeats: true) { _ in animate() }
        mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.updateProgress() }
    }

    // 3. Progressive Muscle Release
    func setupProgressiveMuscleAnimation() {
        rectangularView.backgroundColor = .clear
        rectangularView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        rectangularView.subviews.forEach { $0.removeFromSuperview() }
        
        let bodyIcon = UIImageView(image: UIImage(systemName: "figure.strengthtraining.traditional"))
        bodyIcon.tintColor = UIColor(red:0.36, green:0.18, blue:0.72, alpha:1)
        bodyIcon.contentMode = .scaleAspectFit
        bodyIcon.frame = rectangularView.bounds.insetBy(dx: 40, dy: 40)
        rectangularView.addSubview(bodyIcon)
        breathingAnimationView = bodyIcon
        
        setupInstructionLabel(text: "Get Comfortable")
    }
    
    func startProgressiveMuscleSession() {
        audioPlayer?.play()
        let steps = ["Clench Fists", "Release...", "Raise Shoulders", "Drop...",
                     "Scrunch Face", "Relax...", "Curl Toes", "Let Go..."]
        var index = 0
        instructionLabel?.text = steps[0]
        speakInstruction(steps[0])
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            index += 1
            let text = steps[index % steps.count]
            if let lbl = self.instructionLabel {
                UIView.transition(with: lbl, duration: 0.5, options: .transitionCrossDissolve) { lbl.text = text }
            }
            self.speakInstruction(text)
            if index % 2 == 0 {
                UIView.animate(withDuration: 0.5) { self.breathingAnimationView?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1); self.breathingAnimationView?.alpha = 1.0 }
            } else {
                UIView.animate(withDuration: 0.5) { self.breathingAnimationView?.transform = .identity; self.breathingAnimationView?.alpha = 0.6 }
            }
        }
        mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.updateProgress() }
    }

    // 4. Grounding 5-4-3-2-1
    func setupGrounding54321Animation() {
         rectangularView.backgroundColor = .clear
         rectangularView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
         
         let stack = UIStackView(frame: rectangularView.bounds)
         stack.axis = .vertical
         stack.distribution = .fillEqually
         stack.alignment = .center
         rectangularView.addSubview(stack)
         breathingAnimationView = stack
         
         setupInstructionLabel(text: "Look around you...")
    }
    
    func startGrounding54321Session() {
        audioPlayer?.play()
        let steps = ["Name 5 things you see",
                     "Touch 4 things you feel",
                     "Name 3 things you hear",
                     "Name 2 things you smell",
                     "Take 1 deep breath"]
        var index = 0
        instructionLabel?.text = steps[0]
        speakInstruction(steps[0])
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 24.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            index = (index + 1) % steps.count
            let text = steps[index]
            if let lbl = self.instructionLabel {
                UIView.transition(with: lbl, duration: 0.5, options: .transitionCrossDissolve) { lbl.text = text }
            }
            self.speakInstruction(text)
        }
        mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.updateProgress() }
    }

    // 5. Guided Imagery
    func setupGuidedImageryAnimation() {
        rectangularView.backgroundColor = .clear
        let bg = UIImageView(image: UIImage(systemName: "mountain.2")) // Placeholder
        bg.tintColor = UIColor(red:0.08, green:0.48, blue:0.70, alpha:0.3)
        bg.contentMode = .scaleAspectFit
        bg.frame = rectangularView.bounds.insetBy(dx: 20, dy: 20)
        rectangularView.addSubview(bg)
        breathingAnimationView = bg
        
        setupInstructionLabel(text: "Close your eyes...")
    }
    
    func startGuidedImagerySession() {
        audioPlayer?.play()
        let scenes = ["Imagine a peaceful place...",
                      "Feel a warm breeze on your skin.",
                      "Hear gentle water nearby.",
                      "Notice the colours around you.",
                      "Breathe deeply and just be here."]
        var idx = 0
        instructionLabel?.text = scenes[0]
        speakInstruction(scenes[0])
        UIView.animate(withDuration: 10.0, delay: 0, options: [.autoreverse, .repeat]) {
            self.breathingAnimationView?.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
        }
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 24.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            idx = (idx + 1) % scenes.count
            if let lbl = self.instructionLabel {
                UIView.transition(with: lbl, duration: 0.6, options: .transitionCrossDissolve) { lbl.text = scenes[idx] }
            }
            self.speakInstruction(scenes[idx])
        }
        mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.updateProgress() }
    }

    // 6. Box Breathing (4-4-4-4)
    func setupBoxBreathingAnimation() {
        rectangularView.backgroundColor = .clear
        rectangularView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let square = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        square.center = CGPoint(x: rectangularView.bounds.midX, y: rectangularView.bounds.midY)
        square.layer.borderWidth = 4
        square.layer.borderColor = UIColor(red:0.08, green:0.26,blue:0.62, alpha:1).cgColor
        square.backgroundColor = .clear
        rectangularView.addSubview(square)
        breathingAnimationView = square
        
        // Dot that travels
        let dot = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        dot.backgroundColor = .white
        dot.layer.cornerRadius = 10
        dot.center = CGPoint(x: 0, y: 0) // Top-left relative to square
        square.addSubview(dot)
        dot.tag = 999 // Tag to find it
        
        setupInstructionLabel(text: "Inhale 4s...")
    }
    
    func startBoxBreathingSession() {
        audioPlayer?.play()
        let sideDuration = 4.0
        guard let square = breathingAnimationView, let dot = square.viewWithTag(999) else { return }
        let size = square.bounds.width
        
        let animate = { [weak self] in
            guard let self = self else { return }
            
            // 1. Top edge (Inhale)
            self.instructionLabel?.text = "Inhale (4s)..."
            self.speakInstruction("Inhale")
            UIView.animate(withDuration: sideDuration, delay: 0, options: .curveLinear) {
                dot.center = CGPoint(x: size, y: 0)
            } completion: { _ in
                
                // 2. Right edge (Hold)
                self.instructionLabel?.text = "Hold (4s)..."
                self.speakInstruction("Hold")
                UIView.animate(withDuration: sideDuration, delay: 0, options: .curveLinear) {
                    dot.center = CGPoint(x: size, y: size)
                } completion: { _ in
                    
                    // 3. Bottom edge (Exhale)
                    self.instructionLabel?.text = "Exhale (4s)..."
                    self.speakInstruction("Exhale")
                    UIView.animate(withDuration: sideDuration, delay: 0, options: .curveLinear) {
                        dot.center = CGPoint(x: 0, y: size)
                    } completion: { _ in
                        
                        // 4. Left edge (Hold)
                        self.instructionLabel?.text = "Hold (4s)..."
                        self.speakInstruction("Hold")
                        UIView.animate(withDuration: sideDuration, delay: 0, options: .curveLinear) {
                            dot.center = CGPoint(x: 0, y: 0)
                        }
                    }
                }
            }
        }
        
        animate()
        instructionTimer = Timer.scheduledTimer(withTimeInterval: sideDuration * 4, repeats: true) { _ in animate() }
        mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.updateProgress() }
    }

    // 7. Heart-Focused Breathing
    func setupHeartBreathingAnimation() {
        rectangularView.backgroundColor = .clear
        let heart = UIImageView(image: UIImage(systemName: "heart.fill"))
        heart.tintColor = UIColor(red:0.72, green:0.10, blue:0.30, alpha:1) // Red
        heart.contentMode = .scaleAspectFit
        heart.frame = rectangularView.bounds.insetBy(dx: 60, dy: 60)
        rectangularView.addSubview(heart)
        breathingAnimationView = heart
        
        setupInstructionLabel(text: "Focus on your heart...")
        speakInstruction("Focus on your heart")
    }
    
    func startHeartBreathingSession() {
        audioPlayer?.play()
        let beatDur = 1.0
        
        // Gentle heartbeat
        let pulse = {
            UIView.animate(withDuration: 0.15, animations: {
                self.breathingAnimationView?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }) { _ in
                UIView.animate(withDuration: 0.25) {
                    self.breathingAnimationView?.transform = .identity
                }
            }
        }
        
        instructionTimer = Timer.scheduledTimer(withTimeInterval: beatDur, repeats: true) { _ in pulse() }
        instructionLabel?.text = "Breathe through your heart"
        speakInstruction("Breathe through your heart")
        pulse()
        mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.updateProgress() }
    }

    // 8. Cognitive Reset
    func setupCognitiveResetAnimation() {
        rectangularView.backgroundColor = .clear
        let brain = UIImageView(image: UIImage(systemName: "brain.head.profile"))
        brain.tintColor = UIColor(red:0.18, green:0.52, blue:0.22, alpha:1)
        brain.contentMode = .scaleAspectFit
        brain.frame = rectangularView.bounds.insetBy(dx: 50, dy: 50)
        rectangularView.addSubview(brain)
        breathingAnimationView = brain
        
        setupInstructionLabel(text: "Think of a stressor...")
    }
    
    func startCognitiveResetSession() {
        audioPlayer?.play()
        let prompts = [
            "Identify one stressful thought",
            "Is this 100% true?",
            "What is a calmer perspective?",
            "Take a deep breath..."
        ]
        var idx = 0
        
        instructionLabel?.text = prompts[0]
        speakInstruction(prompts[0])
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            idx = (idx + 1) % prompts.count
            let text = prompts[idx]
            if let lbl = self.instructionLabel {
                UIView.transition(with: lbl, duration: 0.6, options: .transitionFlipFromTop) { lbl.text = text }
            }
            self.speakInstruction(text)
        }
        mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.updateProgress() }
    }

    // 9. Resonance Humming
    func setupResonanceHummingAnimation() {
        rectangularView.backgroundColor = .clear
        let wave = UIImageView(image: UIImage(systemName: "waveform"))
        wave.tintColor = UIColor(red:0.52, green:0.18, blue:0.72, alpha:1)
        wave.contentMode = .scaleAspectFit
        wave.frame = rectangularView.bounds.insetBy(dx: 40, dy: 80)
        rectangularView.addSubview(wave)
        breathingAnimationView = wave
        
        setupInstructionLabel(text: "Inhale deeply...")
    }
    
    func startResonanceHummingSession() {
        audioPlayer?.play()
        
        let cycle = { [weak self] in
            guard let self = self else { return }
            
            // Inhale
            self.instructionLabel?.text = "Inhale..."
            self.speakInstruction("Inhale")
            UIView.animate(withDuration: 4.0) {
                self.breathingAnimationView?.alpha = 0.3
                self.breathingAnimationView?.transform = CGAffineTransform(scaleX: 0.8, y: 1.0)
            } completion: { _ in
                // Hum
                self.instructionLabel?.text = "Hum 'Mmmmmm'..."
                self.speakInstruction("Hum")
                // Vibrate effect
                let shake = CABasicAnimation(keyPath: "position")
                shake.duration = 0.05
                shake.repeatCount = 100 // 5 seconds
                shake.autoreverses = true
                shake.fromValue = NSValue(cgPoint: CGPoint(x: self.breathingAnimationView!.center.x - 2, y: self.breathingAnimationView!.center.y))
                shake.toValue = NSValue(cgPoint: CGPoint(x: self.breathingAnimationView!.center.x + 2, y: self.breathingAnimationView!.center.y))
                self.breathingAnimationView?.layer.add(shake, forKey: "shake")
                
                UIView.animate(withDuration: 5.0) {
                    self.breathingAnimationView?.alpha = 1.0
                    self.breathingAnimationView?.transform = .identity
                }
            }
        }
        
        cycle()
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 9.0, repeats: true) { _ in cycle() }
        mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.updateProgress() }
    }

    // 10. Micro Body Reset
    func setupMicroBodyResetAnimation() {
        rectangularView.backgroundColor = .clear
        let fig = UIImageView(image: UIImage(systemName: "figure.walk"))
        fig.tintColor = UIColor(red:0.82, green:0.48, blue:0.06, alpha:1)
        fig.contentMode = .scaleAspectFit
        fig.frame = rectangularView.bounds.insetBy(dx: 50, dy: 50)
        rectangularView.addSubview(fig)
        breathingAnimationView = fig
        
        setupInstructionLabel(text: "Stand or sit tall...")
    }
    
    func startMicroBodyResetSession() {
        audioPlayer?.play()
        let moves = [
            ("Roll Shoulders Back", "figure.roll"),
            ("Stretch Arms Up", "figure.arms.open"),
            ("Shake Hands Out", "hand.wave"),
            ("Deep Breath", "lungs")
        ]
        var idx = 0
        
        instructionLabel?.text = moves[0].0
        speakInstruction(moves[0].0)
        instructionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            idx = (idx + 1) % moves.count
            let txt = moves[idx].0
            if let lbl = self.instructionLabel {
                UIView.transition(with: lbl, duration: 0.5, options: .transitionCrossDissolve) { lbl.text = txt }
            }
            self.speakInstruction(txt)
        }
        mainTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in self?.updateProgress() }
    }
    
    // Helper
    private func setupInstructionLabel(text: String) {
        if instructionLabel == nil {
            let lbl = UILabel()
            lbl.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            lbl.textColor = activityNameLabel.textColor
            lbl.textAlignment = .center
            lbl.numberOfLines = 2
            lbl.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: rectangularView.centerXAnchor),
                lbl.topAnchor.constraint(equalTo: rectangularView.bottomAnchor, constant: 40)
            ])
            instructionLabel = lbl
        } else {
            instructionLabel?.alpha = 1.0
            instructionLabel?.isHidden = false
            instructionLabel?.textColor = activityNameLabel.textColor
        }
        instructionLabel?.text = text
    }
}
