import UIKit

// MARK: - CustomizeInitialViewController
// Presented as a .pageSheet to let the user pick a font style and background
// for their initials avatar. Calls onApply(themeIndex) on confirm.

class CustomizeInitialViewController: UIViewController {

    // MARK: - Public API
    var onApply: ((Int) -> Void)?

    // MARK: - State
    private let userName: String
    private var selectedFontIndex: Int = 0   // 0-based index into fontOptions
    private var selectedColorIndex: Int = 0  // 0-based index into colorOptions

    // Map selectedFontIndex → DataManager theme index
    //   0 Default (Vibrant Modern)   → theme 0
    //   1 Rounded                    → theme 0 (rounded variant – same gradient, rounded font)
    //   2 Serif / Elegant            → theme 1
    //   3 Pastel                     → theme 2
    //   4 Monospace                  → theme 3
    //   5 Minimal                    → theme 4
    //   6 Bold (same as Default)     → theme 0
    private let fontToTheme = [0, 0, 1, 2, 3, 4, 0]

    // MARK: - Font Options
    private let fontOptions: [(label: String, font: UIFont)] = {
        let base: CGFloat = 36
        let boldFont      = UIFont.systemFont(ofSize: base, weight: .bold)
        var roundedFont   = boldFont
        if let rd = boldFont.fontDescriptor.withDesign(.rounded) {
            roundedFont = UIFont(descriptor: rd, size: base)
        }
        let serifFont      = UIFont(name: "Palatino-Bold",            size: base) ?? boldFont
        let pastelFont     = UIFont(name: "MarkerFelt-Wide",          size: base) ?? boldFont
        let monoFont       = UIFont(name: "Menlo-Bold",               size: base) ?? boldFont
        let minimalFont    = UIFont(name: "HelveticaNeue-UltraLight", size: base) ?? boldFont
        let scriptFont     = UIFont(name: "Noteworthy-Bold",          size: base) ?? boldFont

        return [
            ("Bold",        boldFont),
            ("Rounded",     roundedFont),
            ("Serif",       serifFont),
            ("Pastel",      pastelFont),
            ("Mono",        monoFont),
            ("Minimal",     minimalFont),
            ("Script",      scriptFont)
        ]
    }()

    // MARK: - Color / Gradient Options (pairs matching Mindora palette)
    private let colorOptions: [(UIColor, UIColor)] = [
        // Mindora Blue (#0094FF)
        (UIColor(red:0.0, green:0.580, blue:1.0, alpha:1), UIColor(red:0.0, green:0.45, blue:0.85, alpha:1)),
        // Teal–Cyan -> Light Pastel Teal
        (UIColor(red:0.50, green:0.92, blue:0.94, alpha:1), UIColor(red:0.30, green:0.72, blue:0.80, alpha:1)),
        // Emerald Green -> Light Pastel Green
        (UIColor(red:0.45, green:0.95, blue:0.70, alpha:1), UIColor(red:0.25, green:0.75, blue:0.50, alpha:1)),
        // Sage–Moss -> Light Pastel Sage
        (UIColor(red:0.70, green:0.90, blue:0.68, alpha:1), UIColor(red:0.50, green:0.75, blue:0.50, alpha:1)),
        // Soft Purple -> Light Pastel Purple
        (UIColor(red:0.80, green:0.65, blue:0.98, alpha:1), UIColor(red:0.65, green:0.45, blue:0.85, alpha:1)),
        // Rose Pink -> Light Pastel Pink
        (UIColor(red:1.00, green:0.62, blue:0.75, alpha:1), UIColor(red:0.90, green:0.40, blue:0.55, alpha:1)),
        // Warm Amber -> Light Pastel Amber
        (UIColor(red:1.00, green:0.85, blue:0.45, alpha:1), UIColor(red:0.95, green:0.65, blue:0.25, alpha:1)),
    ]

    // MARK: - UI References
    private let previewContainer = UIView()
    private let previewLabel     = UILabel()
    private var fontPills:  [UIButton] = []
    private var colorDots:  [UIButton] = []
    private let applyButton = UIButton(type: .system)

    // MARK: - Init
    init(name: String) {
        self.userName = name
        super.init(nibName: nil, bundle: nil)
        // Restore previous selections from UserDefaults
        let savedFont  = UserDefaults.standard.integer(forKey: "AvatarFontIndex")
        let savedColor = UserDefaults.standard.integer(forKey: "AvatarColorIndex")
        selectedFontIndex  = min(savedFont,  6)   // clamp to valid range
        selectedColorIndex = min(savedColor, 6)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
        refreshPreview()
    }

    // MARK: - Build UI
    private func buildUI() {
        // ── Title
        let titleLabel = UILabel()
        titleLabel.text = "Customize Initial"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(red:0.08, green:0.08, blue:0.12, alpha:1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // ── Preview Circle
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.layer.cornerRadius = 55
        previewContainer.clipsToBounds = true
        view.addSubview(previewContainer)

        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.textAlignment = .center
        previewLabel.textColor = .white
        previewContainer.addSubview(previewLabel)

        // ── Section: Font Style
        let fontSectionLabel = makeSectionLabel("FONT STYLE")
        fontSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fontSectionLabel)

        // Font pills in two rows (4 + 3)
        let fontRow1 = makeHStack(spacing: 10)
        let fontRow2 = makeHStack(spacing: 10)
        fontRow1.translatesAutoresizingMaskIntoConstraints = false
        fontRow2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fontRow1)
        view.addSubview(fontRow2)

        for (i, opt) in fontOptions.enumerated() {
            let pill = makeFontPill(title: opt.label, tag: i)
            fontPills.append(pill)
            if i < 4 { fontRow1.addArrangedSubview(pill) }
            else      { fontRow2.addArrangedSubview(pill) }
        }

        // ── Section: Background
        let colorSectionLabel = makeSectionLabel("BACKGROUND")
        colorSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(colorSectionLabel)

        let colorScroll = UIScrollView()
        colorScroll.translatesAutoresizingMaskIntoConstraints = false
        colorScroll.showsHorizontalScrollIndicator = false
        colorScroll.alwaysBounceHorizontal = true
        view.addSubview(colorScroll)

        let colorStack = makeHStack(spacing: 12)
        colorStack.translatesAutoresizingMaskIntoConstraints = false
        colorScroll.addSubview(colorStack)

        for (i, _) in colorOptions.enumerated() {
            let dot = makeColorDot(index: i)
            colorDots.append(dot)
            colorStack.addArrangedSubview(dot)
        }

        // ── Apply Button
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.setTitle("Apply", for: .normal)
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        applyButton.backgroundColor = UIColor(red:0.20, green:0.60, blue:1.0, alpha:1)
        applyButton.layer.cornerRadius = 14
        applyButton.layer.shadowColor  = UIColor(red:0.20, green:0.60, blue:1.0, alpha:1).cgColor
        applyButton.layer.shadowOpacity = 0.35
        applyButton.layer.shadowRadius  = 8
        applyButton.layer.shadowOffset  = CGSize(width:0, height:4)
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        view.addSubview(applyButton)

        // ── Constraints
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Preview
            previewContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 22),
            previewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewContainer.widthAnchor.constraint(equalToConstant: 110),
            previewContainer.heightAnchor.constraint(equalToConstant: 110),

            previewLabel.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            previewLabel.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),

            // Font section label
            fontSectionLabel.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 26),
            fontSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),

            // Font row 1
            fontRow1.topAnchor.constraint(equalTo: fontSectionLabel.bottomAnchor, constant: 10),
            fontRow1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fontRow1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Font row 2
            fontRow2.topAnchor.constraint(equalTo: fontRow1.bottomAnchor, constant: 10),
            fontRow2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            // Color section label
            colorSectionLabel.topAnchor.constraint(equalTo: fontRow2.bottomAnchor, constant: 22),
            colorSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),

            // Color scroll
            colorScroll.topAnchor.constraint(equalTo: colorSectionLabel.bottomAnchor, constant: 12),
            colorScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            colorScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            colorScroll.heightAnchor.constraint(equalToConstant: 62),

            colorStack.topAnchor.constraint(equalTo: colorScroll.topAnchor),
            colorStack.bottomAnchor.constraint(equalTo: colorScroll.bottomAnchor),
            colorStack.leadingAnchor.constraint(equalTo: colorScroll.leadingAnchor),
            colorStack.trailingAnchor.constraint(equalTo: colorScroll.trailingAnchor),
            colorStack.heightAnchor.constraint(equalTo: colorScroll.heightAnchor),

            // Apply button
            applyButton.topAnchor.constraint(equalTo: colorScroll.bottomAnchor, constant: 28),
            applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            applyButton.heightAnchor.constraint(equalToConstant: 52),
        ])

        updateFontPillSelection()
        updateColorDotSelection()
    }

    // MARK: - Factory helpers
    private func makeSectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        l.textColor = UIColor(red:0.55, green:0.55, blue:0.60, alpha:1)
        l.letterSpacing(1.2)
        return l
    }

    private func makeHStack(spacing: CGFloat) -> UIStackView {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = spacing
        sv.alignment = .center
        sv.distribution = .fillProportionally
        return sv
    }

    private func makeFontPill(title: String, tag: Int) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.tag = tag
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        btn.layer.cornerRadius = 16
        btn.layer.borderWidth = 1.5
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        btn.addTarget(self, action: #selector(fontPillTapped(_:)), for: .touchUpInside)
        return btn
    }

    private func makeColorDot(index: Int) -> UIButton {
        let btn = UIButton()
        btn.tag = index
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 48).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        btn.layer.cornerRadius = 14
        btn.clipsToBounds = false

        // Gradient fill
        let (c1, c2) = colorOptions[index]
        let grad = CAGradientLayer()
        grad.colors  = [c1.cgColor, c2.cgColor]
        grad.startPoint = CGPoint(x:0, y:0)
        grad.endPoint   = CGPoint(x:1, y:1)
        grad.frame = CGRect(x:0, y:0, width:48, height:48)
        grad.cornerRadius = 14
        btn.layer.insertSublayer(grad, at: 0)

        btn.addTarget(self, action: #selector(colorDotTapped(_:)), for: .touchUpInside)
        return btn
    }

    // MARK: - Selection Styling
    private func updateFontPillSelection() {
        let selectedColor = UIColor(red:0.20, green:0.60, blue:1.0, alpha:1)
        for (i, pill) in fontPills.enumerated() {
            if i == selectedFontIndex {
                pill.backgroundColor = selectedColor.withAlphaComponent(0.12)
                pill.setTitleColor(selectedColor, for: .normal)
                pill.layer.borderColor = selectedColor.cgColor
            } else {
                pill.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.97, alpha:1)
                pill.setTitleColor(UIColor(red:0.30, green:0.30, blue:0.35, alpha:1), for: .normal)
                pill.layer.borderColor = UIColor(red:0.85, green:0.85, blue:0.88, alpha:1).cgColor
            }
        }
    }

    private func updateColorDotSelection() {
        for (i, dot) in colorDots.enumerated() {
            if i == selectedColorIndex {
                dot.layer.borderColor = UIColor.label.cgColor
                dot.layer.borderWidth = 3
                dot.layer.shadowColor  = colorOptions[i].0.cgColor
                dot.layer.shadowOpacity = 0.55
                dot.layer.shadowRadius  = 6
                dot.layer.shadowOffset  = .zero
            } else {
                dot.layer.borderWidth  = 0
                dot.layer.shadowOpacity = 0
            }
        }
    }

    // MARK: - Preview Refresh
    private func refreshPreview() {
        // Remove old gradient sublayer
        previewContainer.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }

        let (c1, c2) = colorOptions[selectedColorIndex]
        let grad = CAGradientLayer()
        grad.colors = [c1.cgColor, c2.cgColor]
        grad.startPoint = CGPoint(x:0, y:0)
        grad.endPoint   = CGPoint(x:1, y:1)
        grad.frame = CGRect(x:0, y:0, width:110, height:110)
        previewContainer.layer.insertSublayer(grad, at: 0)

        // Initials text
        let initials = userName
            .components(separatedBy: " ")
            .compactMap { $0.first.map { String($0) } }
            .prefix(2).joined().uppercased()
        let display = initials.isEmpty ? "G" : initials

        let selectedFont = fontOptions[selectedFontIndex].font
        previewLabel.text = display
        previewLabel.font = selectedFont

        // Bounce
        previewContainer.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        UIView.animate(withDuration: 0.35, delay: 0,
                       usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            self.previewContainer.transform = .identity
        }
    }

    // MARK: - Actions
    @objc private func fontPillTapped(_ sender: UIButton) {
        selectedFontIndex = sender.tag
        updateFontPillSelection()
        refreshPreview()
    }

    @objc private func colorDotTapped(_ sender: UIButton) {
        selectedColorIndex = sender.tag
        updateColorDotSelection()
        refreshPreview()
    }

    @objc private func applyTapped() {
        // Map font selection → DataManager theme index
        let themeIndex = fontToTheme[selectedFontIndex]

        // Persist both selections so the sheet reopens in the same state.
        UserDefaults.standard.set(selectedFontIndex,  forKey: "AvatarFontIndex")
        UserDefaults.standard.set(selectedColorIndex, forKey: "AvatarColorIndex")
        UserDefaults.standard.set(true,               forKey: "AvatarColorIndexSet")

        // Bounce the button
        UIView.animate(withDuration: 0.12, animations: {
            self.applyButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.12) { self.applyButton.transform = .identity }
        }

        onApply?(themeIndex)
        dismiss(animated: true)
    }
}

// MARK: - UILabel spacing helper
private extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        if let text = self.text {
            let attrStr = NSMutableAttributedString(string: text)
            attrStr.addAttribute(.kern, value: spacing, range: NSRange(location: 0, length: text.count))
            self.attributedText = attrStr
        }
    }
}
