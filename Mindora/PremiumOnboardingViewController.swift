import UIKit

// MARK: - Feature Chip Data
private struct FeatureChip {
    let icon: String   // SF Symbol
    let text: String
}

// MARK: - Page Model
private struct OnboardingPage {
    let bg1: UIColor
    let bg2: UIColor
    let radialColor: UIColor    // central radial glow colour
    let accent: UIColor
    let sfSymbol: String?
    let emoji: String?
    let symbolSize: CGFloat
    let tag: String
    let headline: String
    let body: String
    let chips: [FeatureChip]
    let nextLabel: String
    let stages: [(emoji: String, name: String)?]
}

// MARK: - Main Controller

class PremiumOnboardingViewController: UIViewController {

    var onFinish: (() -> Void)?

    // MARK: - Pages
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            bg1: UIColor(red: 0.35, green: 0.25, blue: 0.55, alpha: 1),
            bg2: UIColor(red: 0.22, green: 0.13, blue: 0.40, alpha: 1),
            radialColor: UIColor(red: 0.55, green: 0.35, blue: 1.00, alpha: 1),
            accent: UIColor(red: 0.72, green: 0.55, blue: 1.00, alpha: 1),
            sfSymbol: "sparkles",
            emoji: nil,
            symbolSize: 100,
            tag: "WELCOME",
            headline: "Welcome to\nMindora.",
            body: "Your daily mental wellness companion — breathing exercises, calming activities, streaks, and a garden that grows as you do.",
            chips: [
                FeatureChip(icon: "lungs.fill", text: "Breathing"),
                FeatureChip(icon: "flame.fill", text: "Streaks"),
                FeatureChip(icon: "chart.bar.fill", text: "Insights"),
            ],
            nextLabel: "Let's go",
            stages: []
        ),
        OnboardingPage(
            bg1: UIColor(red: 0.25, green: 0.45, blue: 0.65, alpha: 1),
            bg2: UIColor(red: 0.12, green: 0.30, blue: 0.55, alpha: 1),
            radialColor: UIColor(red: 0.20, green: 0.60, blue: 1.00, alpha: 1),
            accent: UIColor(red: 0.40, green: 0.78, blue: 1.00, alpha: 1),
            sfSymbol: "wind",
            emoji: nil,
            symbolSize: 90,
            tag: "ACTIVITIES",
            headline: "Calm Yourself\nin 2 Minutes.",
            body: "6 quick 2-minute resets — Deep Breathing, Calming Sounds, Finger Rhythm, Shoulder Drop, Eye Relaxation, Meditation. Plus 7 Advanced Calm techniques at your own pace.",
            chips: [
                FeatureChip(icon: "timer", text: "2-Min Reset"),
                FeatureChip(icon: "waveform.path.ecg", text: "Advanced Calm"),
                FeatureChip(icon: "brain.head.profile", text: "Science-Backed"),
            ],
            nextLabel: "Next",
            stages: []
        ),
        OnboardingPage(
            bg1: UIColor(red: 0.25, green: 0.55, blue: 0.35, alpha: 1),
            bg2: UIColor(red: 0.13, green: 0.40, blue: 0.22, alpha: 1),
            radialColor: UIColor(red: 0.25, green: 0.85, blue: 0.48, alpha: 1),
            accent: UIColor(red: 0.40, green: 0.92, blue: 0.60, alpha: 1),
            sfSymbol: nil,
            emoji: "🦋",
            symbolSize: 100,
            tag: "BUTTERFLY",
            headline: "Every Session\nUnlocks a Stage.",
            body: "Complete 4 activities to grow your butterfly from Egg → Caterpillar → Pupa → Butterfly. Your streak keeps the momentum going.",
            chips: [],
            nextLabel: "Next",
            stages: [
                (emoji: "🥚", name: "Egg"),
                (emoji: "🐛", name: "Caterpillar"),
                (emoji: "🫛", name: "Pupa"),
                (emoji: "🦋", name: "Butterfly"),
            ]
        ),
        OnboardingPage(
            bg1: UIColor(red: 0.70, green: 0.45, blue: 0.25, alpha: 1),
            bg2: UIColor(red: 0.55, green: 0.32, blue: 0.14, alpha: 1),
            radialColor: UIColor(red: 1.00, green: 0.65, blue: 0.18, alpha: 1),
            accent: UIColor(red: 1.00, green: 0.76, blue: 0.32, alpha: 1),
            sfSymbol: nil,
            emoji: "🌸",
            symbolSize: 100,
            tag: "GARDEN",
            headline: "Watch Your\nGarden Bloom.",
            body: "Collect 10 butterflies to complete your personal garden. It comes alive with butterflies in flight — even changing between day and night. Plus, experience your garden in AR right in your real world.",
            chips: [
                FeatureChip(icon: "sun.max.fill", text: "Day & Night"),
                FeatureChip(icon: "butterfly.fill", text: "10 Butterflies"),
            ],
            nextLabel: "Get Started  →",
            stages: []
        ),
    ]

    private var currentIndex = 0

    // MARK: - Background layers
    private let bgGradient = CAGradientLayer()
    private let radialGlow1 = UIView()   // large radial bloom top
    private let radialGlow2 = UIView()   // smaller glow bottom-right

    // Floating orbs (ambient particles)
    private var orbs: [UIView] = []

    // MARK: - Central illustration
    private let symbolLabel = UILabel()     // emoji
    private let symbolImage = UIImageView() // SF Symbol
    private let glowHalo = UIView()         // outer halo ring
    private let glowMid = UIView()          // mid ring
    private var emitterLayer: CAEmitterLayer?

    // MARK: - Blur sheet at bottom
    private let blurSheet = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let tagLabel = UILabel()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let chipsStack = UIStackView()
    private let stagesRow = UIStackView()
    private let dotsRow = UIStackView()
    private var dots: [UIView] = []
    private let ctaButton = UIButton(type: .custom)
    private let skipButton = UIButton(type: .system)

    // Bottom sheet drag handle
    private let sheetHandle = UIView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        loadPage(0, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgGradient.frame = view.bounds
        layoutRadialGlows()
        setupEmitter()
        layoutOrbs()
        applyButtonStyle(accent: pages[currentIndex].accent)
    }

    // MARK: - Build UI

    private func buildUI() {
        // ── Background ──
        bgGradient.startPoint = CGPoint(x: 0.3, y: 0)
        bgGradient.endPoint   = CGPoint(x: 0.7, y: 1)
        view.layer.insertSublayer(bgGradient, at: 0)

        // ── Radial glows ──
        radialGlow1.translatesAutoresizingMaskIntoConstraints = false
        radialGlow2.translatesAutoresizingMaskIntoConstraints = false
        [radialGlow1, radialGlow2].forEach {
            $0.isUserInteractionEnabled = false
            view.addSubview($0)
        }

        // ── Floating orbs ──
        for _ in 0..<6 {
            let orb = UIView()
            orb.translatesAutoresizingMaskIntoConstraints = false
            orb.isUserInteractionEnabled = false
            orb.layer.cornerRadius = 6
            view.addSubview(orb)
            orbs.append(orb)
        }

        // ── Central icon (no card, no border — just glow + symbol) ──
        glowHalo.translatesAutoresizingMaskIntoConstraints = false
        glowHalo.isUserInteractionEnabled = false
        view.addSubview(glowHalo)

        glowMid.translatesAutoresizingMaskIntoConstraints = false
        glowMid.isUserInteractionEnabled = false
        view.addSubview(glowMid)

        symbolLabel.translatesAutoresizingMaskIntoConstraints = false
        symbolLabel.textAlignment = .center
        view.addSubview(symbolLabel)

        symbolImage.translatesAutoresizingMaskIntoConstraints = false
        symbolImage.contentMode = .scaleAspectFit
        view.addSubview(symbolImage)

        // ── Skip (top right) ──
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle("Skip", for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        skipButton.setTitleColor(UIColor.label.withAlphaComponent(0.40), for: .normal)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        view.addSubview(skipButton)

        // ── Blur bottom sheet ──
        blurSheet.translatesAutoresizingMaskIntoConstraints = false
        blurSheet.layer.cornerRadius = 36
        blurSheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        blurSheet.clipsToBounds = true
        blurSheet.layer.borderWidth = 0.5
        blurSheet.layer.borderColor = UIColor.label.withAlphaComponent(0.10).cgColor
        view.addSubview(blurSheet)

        // Thin handle bar at top of sheet
        sheetHandle.translatesAutoresizingMaskIntoConstraints = false
        sheetHandle.backgroundColor = UIColor.label.withAlphaComponent(0.20)
        sheetHandle.layer.cornerRadius = 2.5
        sheetHandle.isHidden = true
        blurSheet.contentView.addSubview(sheetHandle)

        // Tag badge
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.font = UIFont.systemFont(ofSize: 10, weight: .heavy)
        tagLabel.layer.cornerRadius = 7
        tagLabel.clipsToBounds = true
        tagLabel.textAlignment = .center
        blurSheet.contentView.addSubview(tagLabel)

        // Headline
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.numberOfLines = 3
        headlineLabel.textAlignment = .left
        headlineLabel.textColor = .label
        blurSheet.contentView.addSubview(headlineLabel)

        // Body
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .left
        blurSheet.contentView.addSubview(bodyLabel)

        // Feature chips row
        chipsStack.translatesAutoresizingMaskIntoConstraints = false
        chipsStack.axis = .horizontal
        chipsStack.spacing = 8
        chipsStack.alignment = .center
        blurSheet.contentView.addSubview(chipsStack)

        // Stages row
        stagesRow.translatesAutoresizingMaskIntoConstraints = false
        stagesRow.axis = .horizontal
        stagesRow.spacing = 10
        stagesRow.distribution = .fillEqually
        stagesRow.isHidden = true
        blurSheet.contentView.addSubview(stagesRow)

        // Page dots
        dotsRow.translatesAutoresizingMaskIntoConstraints = false
        dotsRow.axis = .horizontal
        dotsRow.spacing = 6
        dotsRow.alignment = .center
        blurSheet.contentView.addSubview(dotsRow)
        buildDots()

        // CTA Button
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.layer.cornerRadius = 26
        ctaButton.clipsToBounds = true
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        blurSheet.contentView.addSubview(ctaButton)

        // ── Constraints ──
        let sheetHeight: CGFloat = UIScreen.main.bounds.height > 800 ? 455 : 420

        NSLayoutConstraint.activate([
            // Radial glows (sized in layoutRadialGlows)
            radialGlow1.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            radialGlow1.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),

            radialGlow2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 60),
            radialGlow2.bottomAnchor.constraint(equalTo: view.centerYAnchor),

            // Halo rings centred on screen, above sheet
            glowHalo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            glowHalo.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -90),
            glowHalo.widthAnchor.constraint(equalToConstant: 230),
            glowHalo.heightAnchor.constraint(equalToConstant: 230),

            glowMid.centerXAnchor.constraint(equalTo: glowHalo.centerXAnchor),
            glowMid.centerYAnchor.constraint(equalTo: glowHalo.centerYAnchor),
            glowMid.widthAnchor.constraint(equalToConstant: 170),
            glowMid.heightAnchor.constraint(equalToConstant: 170),

            // Symbol
            symbolLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            symbolLabel.centerYAnchor.constraint(equalTo: glowHalo.centerYAnchor),

            symbolImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            symbolImage.centerYAnchor.constraint(equalTo: glowHalo.centerYAnchor),
            symbolImage.widthAnchor.constraint(equalToConstant: 90),
            symbolImage.heightAnchor.constraint(equalToConstant: 90),

            // Skip
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Blur sheet
            blurSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurSheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurSheet.heightAnchor.constraint(equalToConstant: sheetHeight),

            // Handle
            sheetHandle.topAnchor.constraint(equalTo: blurSheet.contentView.topAnchor, constant: 12),
            sheetHandle.centerXAnchor.constraint(equalTo: blurSheet.contentView.centerXAnchor),
            sheetHandle.widthAnchor.constraint(equalToConstant: 36),
            sheetHandle.heightAnchor.constraint(equalToConstant: 5),

            // Tag
            tagLabel.topAnchor.constraint(equalTo: sheetHandle.bottomAnchor, constant: 14),
            tagLabel.leadingAnchor.constraint(equalTo: blurSheet.contentView.leadingAnchor, constant: 24),
            tagLabel.heightAnchor.constraint(equalToConstant: 24),

            // Headline
            headlineLabel.topAnchor.constraint(equalTo: tagLabel.bottomAnchor, constant: 8),
            headlineLabel.leadingAnchor.constraint(equalTo: blurSheet.contentView.leadingAnchor, constant: 24),
            headlineLabel.trailingAnchor.constraint(equalTo: blurSheet.contentView.trailingAnchor, constant: -24),

            // Body
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: blurSheet.contentView.leadingAnchor, constant: 24),
            bodyLabel.trailingAnchor.constraint(equalTo: blurSheet.contentView.trailingAnchor, constant: -24),

            // Chips
            chipsStack.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 10),
            chipsStack.leadingAnchor.constraint(equalTo: blurSheet.contentView.leadingAnchor, constant: 24),

            // Stages
            stagesRow.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 10),
            stagesRow.leadingAnchor.constraint(equalTo: blurSheet.contentView.leadingAnchor, constant: 24),
            stagesRow.trailingAnchor.constraint(equalTo: blurSheet.contentView.trailingAnchor, constant: -24),
            stagesRow.heightAnchor.constraint(equalToConstant: 68),

            // Dots
            dotsRow.leadingAnchor.constraint(equalTo: blurSheet.contentView.leadingAnchor, constant: 24),
            dotsRow.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -14),

            // CTA
            ctaButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            ctaButton.leadingAnchor.constraint(equalTo: blurSheet.contentView.leadingAnchor, constant: 20),
            ctaButton.trailingAnchor.constraint(equalTo: blurSheet.contentView.trailingAnchor, constant: -20),
            ctaButton.heightAnchor.constraint(equalToConstant: 54),
        ])

        startAmbientAnimations()
    }

    // MARK: - Radial glows layout

    private func layoutRadialGlows() {
        let s1: CGFloat = 420
        radialGlow1.bounds = CGRect(x: 0, y: 0, width: s1, height: s1)
        radialGlow1.layer.cornerRadius = s1 / 2
        let s2: CGFloat = 260
        radialGlow2.bounds = CGRect(x: 0, y: 0, width: s2, height: s2)
        radialGlow2.layer.cornerRadius = s2 / 2
    }

    private func layoutOrbs() {
        guard orbs.allSatisfy({ $0.frame.size == .zero }) else { return }
        let sizes: [CGFloat] = [10, 7, 5, 8, 6, 9]
        let xs: [CGFloat] = [0.15, 0.80, 0.65, 0.25, 0.90, 0.42]
        let ys: [CGFloat] = [0.18, 0.12, 0.38, 0.32, 0.28, 0.22]
        for (i, orb) in orbs.enumerated() {
            let s = sizes[i]
            orb.frame = CGRect(x: view.bounds.width * xs[i] - s/2,
                               y: view.bounds.height * ys[i] - s/2,
                               width: s, height: s)
            orb.layer.cornerRadius = s / 2
        }
    }

    // MARK: - Ambient animations (idle)

    private func startAmbientAnimations() {
        // Halo pulse
        UIView.animate(withDuration: 3.5, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.glowHalo.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }
        UIView.animate(withDuration: 2.8, delay: 0.6, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.glowMid.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
        }
        // Orb drift
        for (i, orb) in orbs.enumerated() {
            animateOrb(orb, delay: Double(i) * 0.7)
        }
    }

    private func animateOrb(_ orb: UIView, delay: Double) {
        let dx = CGFloat.random(in: -28...28)
        let dy = CGFloat.random(in: -22...22)
        UIView.animate(
            withDuration: Double.random(in: 5...9),
            delay: delay,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: {
                orb.transform = CGAffineTransform(translationX: dx, y: dy)
                orb.alpha = CGFloat.random(in: 0.3...0.8)
            },
            completion: { [weak self] _ in self?.animateOrb(orb, delay: 0) }
        )
    }

    // MARK: - Particle emitter

    private func setupEmitter() {
        guard emitterLayer == nil else { return }
        let e = CAEmitterLayer()
        e.emitterPosition = CGPoint(x: view.bounds.midX, y: view.bounds.height * 0.36)
        e.emitterSize = CGSize(width: 140, height: 140)
        e.emitterShape = .sphere
        e.renderMode = .additive

        let cell = CAEmitterCell()
        cell.birthRate = 4
        cell.lifetime = 6.0
        cell.velocity = 18
        cell.velocityRange = 10
        cell.emissionRange = .pi * 2
        cell.scale = 0.035
        cell.scaleRange = 0.018
        cell.scaleSpeed = -0.004
        cell.alphaSpeed = -0.09

        let sz: CGFloat = 10
        UIGraphicsBeginImageContextWithOptions(CGSize(width: sz, height: sz), false, 0)
        UIColor.white.setFill()
        UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: sz, height: sz)).fill()
        cell.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()

        e.emitterCells = [cell]
        view.layer.insertSublayer(e, below: blurSheet.layer)
        emitterLayer = e
    }

    private func updateEmitter(color: UIColor) {
        guard let e = emitterLayer, var cell = e.emitterCells?.first else { return }
        cell.color = color.withAlphaComponent(0.5).cgColor
        e.emitterCells = [cell]
    }

    // MARK: - Page Loading

    private func loadPage(_ idx: Int, animated: Bool) {
        let p = pages[idx]

        // BG gradient
        let newColors = [p.bg1.cgColor, p.bg2.cgColor]
        if animated {
            let anim = CABasicAnimation(keyPath: "colors")
            anim.fromValue = bgGradient.colors
            anim.toValue = newColors
            anim.duration = 0.6
            bgGradient.add(anim, forKey: "bg")
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bgGradient.colors = newColors
        CATransaction.commit()

        // Radial glows
        radialGlow1.backgroundColor = p.radialColor.withAlphaComponent(0.18)
        radialGlow2.backgroundColor = p.radialColor.withAlphaComponent(0.10)

        // Orbs
        for orb in orbs {
            orb.backgroundColor = p.accent.withAlphaComponent(0.55)
        }

        // Halo rings
        glowHalo.backgroundColor = p.accent.withAlphaComponent(0.08)
        glowHalo.layer.borderWidth = 1
        glowHalo.layer.borderColor = p.accent.withAlphaComponent(0.25).cgColor
        glowHalo.layer.cornerRadius = 115

        glowMid.backgroundColor = p.accent.withAlphaComponent(0.14)
        glowMid.layer.borderWidth = 1
        glowMid.layer.borderColor = p.accent.withAlphaComponent(0.35).cgColor
        glowMid.layer.cornerRadius = 85

        // Shadow glow on halo
        glowHalo.layer.shadowColor = p.accent.cgColor
        glowHalo.layer.shadowRadius = 40
        glowHalo.layer.shadowOpacity = 0.5
        glowHalo.layer.shadowOffset = .zero

        // Symbol
        if let sym = p.sfSymbol {
            let cfg = UIImage.SymbolConfiguration(pointSize: p.symbolSize, weight: .ultraLight)
            symbolImage.image = UIImage(systemName: sym, withConfiguration: cfg)
            symbolImage.tintColor = p.accent
            symbolImage.isHidden = false
            // Glow on icon
            symbolImage.layer.shadowColor = p.accent.cgColor
            symbolImage.layer.shadowRadius = 28
            symbolImage.layer.shadowOpacity = 0.8
            symbolImage.layer.shadowOffset = .zero
            symbolLabel.isHidden = true
        } else {
            symbolLabel.font = UIFont.systemFont(ofSize: p.symbolSize)
            symbolLabel.text = p.emoji
            symbolLabel.isHidden = false
            symbolImage.isHidden = true
        }

        // Tag
        let tagStr = "  \(p.tag)  "
        tagLabel.attributedText = NSAttributedString(string: tagStr, attributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .heavy),
            .foregroundColor: p.bg1,
            .kern: 1.8,
        ])
        tagLabel.backgroundColor = p.accent
        tagLabel.layer.cornerRadius = 7

        // Headline
        headlineLabel.attributedText = NSAttributedString(string: p.headline, attributes: [
            .font: UIFont.systemFont(ofSize: 34, weight: .heavy),
            .foregroundColor: UIColor.label,
            .kern: -0.6,
        ])

        // Body
        let para = NSMutableParagraphStyle(); para.lineSpacing = 4
        bodyLabel.attributedText = NSAttributedString(string: p.body, attributes: [
            .font: UIFont.systemFont(ofSize: 14.5, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel,
            .paragraphStyle: para,
        ])

        // Chips
        chipsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if p.chips.isEmpty {
            chipsStack.isHidden = true
        } else {
            chipsStack.isHidden = false
            for chip in p.chips {
                chipsStack.addArrangedSubview(makeChip(chip, accent: p.accent))
            }
        }

        // Stages
        stagesRow.isHidden = p.stages.isEmpty
        stagesRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for s in p.stages {
            guard let s = s else { continue }
            stagesRow.addArrangedSubview(makeStageCard(s, accent: p.accent))
        }

        // Button
        ctaButton.setTitle(p.nextLabel, for: .normal)
        applyButtonStyle(accent: p.accent)

        // Skip
        skipButton.isHidden = (idx == pages.count - 1)

        // Dots
        updateDots(idx, accent: p.accent)

        // Emitter
        updateEmitter(color: p.accent)

        // Transition animations
        if animated {
            symbolLabel.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            symbolImage.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            symbolLabel.alpha = 0; symbolImage.alpha = 0
            [tagLabel, headlineLabel, bodyLabel, chipsStack, stagesRow].forEach { $0.alpha = 0 }

            UIView.animate(withDuration: 0.55, delay: 0.05,
                           usingSpringWithDamping: 0.58, initialSpringVelocity: 0.5) {
                self.symbolLabel.transform = .identity
                self.symbolImage.transform = .identity
                self.symbolLabel.alpha = 1
                self.symbolImage.alpha = 1
            }
            UIView.animate(withDuration: 0.4, delay: 0.18) {
                self.tagLabel.alpha = 1
                self.headlineLabel.alpha = 1
            }
            UIView.animate(withDuration: 0.4, delay: 0.28) {
                self.bodyLabel.alpha = 1
                self.chipsStack.alpha = 1
                self.stagesRow.alpha = 1
            }
        }
    }

    // MARK: - Chip factory

    private func makeChip(_ chip: FeatureChip, accent: UIColor) -> UIView {
        let pill = UIView()
        pill.backgroundColor = accent.withAlphaComponent(0.22)
        pill.layer.cornerRadius = 12
        pill.layer.borderWidth = 0.8
        pill.layer.borderColor = accent.withAlphaComponent(0.45).cgColor

        let img = UIImageView()
        img.image = UIImage(systemName: chip.icon)
        img.tintColor = UIColor.label.withAlphaComponent(0.70)
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = chip.text
        lbl.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = UIColor.label.withAlphaComponent(0.85)
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [img, lbl])
        row.axis = .horizontal
        row.spacing = 4
        row.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(row)

        NSLayoutConstraint.activate([
            img.widthAnchor.constraint(equalToConstant: 12),
            img.heightAnchor.constraint(equalToConstant: 12),
            row.topAnchor.constraint(equalTo: pill.topAnchor, constant: 6),
            row.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -6),
            row.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 8),
            row.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -8),
        ])
        return pill
    }

    // MARK: - Stage card factory

    private func makeStageCard(_ stage: (emoji: String, name: String), accent: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 0.5
        card.layer.borderColor = accent.withAlphaComponent(0.25).cgColor

        let e = UILabel(); e.text = stage.emoji
        e.font = UIFont.systemFont(ofSize: 26); e.textAlignment = .center
        let n = UILabel(); n.text = stage.name
        n.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        n.textColor = UIColor.label.withAlphaComponent(0.60); n.textAlignment = .center

        let v = UIStackView(arrangedSubviews: [e, n])
        v.axis = .vertical; v.spacing = 4
        v.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(v)
        NSLayoutConstraint.activate([
            v.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            v.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])
        return card
    }

    // MARK: - Dots

    private func buildDots() {
        dotsRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        dots.removeAll()
        for _ in pages {
            let d = UIView()
            d.translatesAutoresizingMaskIntoConstraints = false
            d.layer.cornerRadius = 3
            d.widthAnchor.constraint(equalToConstant: 6).isActive = true
            d.heightAnchor.constraint(equalToConstant: 6).isActive = true
            d.backgroundColor = UIColor.label.withAlphaComponent(0.25)
            dotsRow.addArrangedSubview(d)
            dots.append(d)
        }
    }

    private func updateDots(_ idx: Int, accent: UIColor) {
        for (i, d) in dots.enumerated() {
            UIView.animate(withDuration: 0.35, delay: 0,
                           usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3) {
                d.backgroundColor = i == idx ? accent : UIColor.label.withAlphaComponent(0.22)
                d.transform = i == idx
                    ? CGAffineTransform(scaleX: 2.4, y: 1)
                    : .identity
            }
        }
    }

    // MARK: - Button gradient

    private func applyButtonStyle(accent: UIColor) {
        ctaButton.layer.sublayers?.filter { $0.name == "btnGrad" }.forEach { $0.removeFromSuperlayer() }

        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        accent.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let c1 = UIColor(hue: h, saturation: max(0, s - 0.10), brightness: min(1, b + 0.15), alpha: 1)
        let c2 = UIColor(hue: h, saturation: min(1, s + 0.06), brightness: max(0, b - 0.10), alpha: 1)

        let g = CAGradientLayer()
        g.name = "btnGrad"
        g.colors = [c1.cgColor, c2.cgColor]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint   = CGPoint(x: 1, y: 0.5)
        g.frame = CGRect(x: 0, y: 0,
                         width: UIScreen.main.bounds.width - 40,
                         height: 54)
        g.cornerRadius = 26
        ctaButton.layer.insertSublayer(g, at: 0)
        ctaButton.layer.shadowColor = accent.cgColor
        ctaButton.layer.shadowOpacity = 0.55
        ctaButton.layer.shadowRadius = 16
        ctaButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        ctaButton.layer.masksToBounds = false
    }

    // MARK: - Actions

    @objc private func nextTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Button pulse
        UIView.animate(withDuration: 0.1, animations: {
            self.ctaButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.ctaButton.transform = .identity
            }
        }

        if currentIndex < pages.count - 1 {
            currentIndex += 1
            crossFadeTransition()
        } else {
            finish()
        }
    }

    @objc private func skipTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        finish()
    }

    private func crossFadeTransition() {
        let snapshot = view.snapshotView(afterScreenUpdates: false)
        if let snap = snapshot { view.addSubview(snap) }

        loadPage(currentIndex, animated: true)

        UIView.animate(withDuration: 0.35, delay: 0.05) {
            snapshot?.alpha = 0
        } completion: { _ in
            snapshot?.removeFromSuperview()
        }
    }

    // MARK: - Finish

    private func finish() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        guard let window = view.window else { onFinish?(); return }

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.view.alpha = 0
            self.view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let dash = sb.instantiateViewController(withIdentifier: "Dashboard")
            UIView.transition(with: window, duration: 0.40, options: .transitionCrossDissolve) {
                window.rootViewController = dash
            }
        }
    }
}
