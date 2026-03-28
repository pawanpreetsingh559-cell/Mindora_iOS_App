import UIKit
import ARKit
import SceneKit
import CoreHaptics

class ARGardenViewController: UIViewController {

    // MARK: - Properties
    private var arView: ARSCNView!
    private var statusLabel: UILabel!
    private var closeButton: UIButton!
    private var placeButton: UIButton!

    private var wrapperNode: SCNNode?
    private var gardenNode: SCNNode?
    private var gardenPlaced = false
    private var butterflyNodes: [SCNNode] = []
    private var hapticEngine: CHHapticEngine?

    private let minScale: Float = 0.3
    private let maxScale: Float = 3.0

    private var butterflyCount: Int {
        let total = DataManager.shared.getButterflies()
        return total == 0 ? 0 : ((total - 1) % 10) + 1
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupUI()
        addTapGesture()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.run(config)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }

    // MARK: - Setup
    private func setupARView() {
        arView = ARSCNView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.delegate = self
        arView.scene = SCNScene()
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        view.addSubview(arView)
    }

    private func setupUI() {
        // Status label at the top
        statusLabel = UILabel()
        statusLabel.text = "Point at a flat surface and tap to place your garden 🌿"
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        statusLabel.layer.cornerRadius = 14
        statusLabel.clipsToBounds = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Close button (top-left)
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        // Place button (bottom center) - shows before garden is placed
        placeButton = UIButton(type: .system)
        placeButton.setTitle("🌿  Place Garden Here", for: .normal)
        placeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        placeButton.setTitleColor(.white, for: .normal)
        placeButton.backgroundColor = UIColor(red: 0.13, green: 0.55, blue: 0.25, alpha: 0.92)
        placeButton.layer.cornerRadius = 26
        placeButton.translatesAutoresizingMaskIntoConstraints = false
        placeButton.addTarget(self, action: #selector(placeGardenTapped), for: .touchUpInside)
        view.addSubview(placeButton)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            placeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            placeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeButton.widthAnchor.constraint(equalToConstant: 240),
            placeButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tap)

        // Pinch to zoom garden
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        arView.addGestureRecognizer(pinch)

        // Two-finger rotate garden
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        arView.addGestureRecognizer(rotate)

        // Allow pinch + rotate simultaneously
        pinch.delegate = self
        rotate.delegate = self
    }

    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func placeGardenTapped() {
        // Place at center of screen
        let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        placeGarden(at: center)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: arView)

        // 1. Check if a butterfly was tapped first
        let hits = arView.hitTest(location, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
        if let hit = hits.first(where: { butterflyNodes.contains($0.node) }) {
            disturbARButterfly(hit.node)
            return
        }

        // 2. Otherwise, try to place the garden
        guard !gardenPlaced else { return }
        placeGarden(at: location)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gardenPlaced, let wrapper = wrapperNode else { return }

        if gesture.state == .changed {
            let pinchScale = Float(gesture.scale)
            let currentScale = wrapper.scale.x
            
            var newScale = currentScale * pinchScale
            if newScale < minScale { newScale = minScale }
            if newScale > maxScale { newScale = maxScale }
            
            wrapper.scale = SCNVector3(newScale, newScale, newScale)
            gesture.scale = 1.0 // Reset for incremental tracking
        }
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard gardenPlaced, let wrapper = wrapperNode else { return }

        if gesture.state == .changed {
            // Rotate the entire wrapper symmetrically
            wrapper.eulerAngles.y -= Float(gesture.rotation)
            gesture.rotation = 0  
        }
    }

    private func disturbARButterfly(_ node: SCNNode) {
        guard butterflyNodes.contains(node) else { return }
        playDisturbHaptic()

        // Stop regular flight
        node.removeAllActions()

        // Phase 1: Rapid panic wing flaps (4 fast beats)
        let panicFlapIn = SCNAction.customAction(duration: 0.07) { node, elapsed in
            let t = Float(elapsed / 0.07)
            node.scale = SCNVector3(max(0.1, 1.0 - 0.9 * t), 1.0, 1.0)
        }
        let panicFlapOut = SCNAction.customAction(duration: 0.07) { node, elapsed in
            let t = Float(elapsed / 0.07)
            node.scale = SCNVector3(min(1.0, 0.1 + 0.9 * t), 1.0, 1.0)
        }
        let panicFlap = SCNAction.repeat(SCNAction.sequence([panicFlapIn, panicFlapOut]), count: 4)

        // Phase 2: Erratic zig-zag scramble to a new nearby position
        let escapeAngle = Float.random(in: 0...(.pi * 2))
        let escapeDist = Float.random(in: 0.25...0.5)
        let side1 = Float.random(in: -0.12...0.12)
        let side2 = Float.random(in: -0.12...0.12)

        let dart1 = SCNAction.moveBy(
            x: CGFloat(cos(escapeAngle) * escapeDist * 0.35 + side1),
            y: CGFloat(Float.random(in: 0.03...0.12)),
            z: CGFloat(sin(escapeAngle) * escapeDist * 0.35 + side1),
            duration: 0.14
        )
        let dart2 = SCNAction.moveBy(
            x: CGFloat(cos(escapeAngle) * escapeDist * 0.35 + side2),
            y: CGFloat(Float.random(in: -0.05...0.1)),
            z: CGFloat(sin(escapeAngle) * escapeDist * 0.35 + side2),
            duration: 0.14
        )
        let dart3 = SCNAction.moveBy(
            x: CGFloat(cos(escapeAngle) * escapeDist * 0.3),
            y: CGFloat(Float.random(in: 0.02...0.1)),
            z: CGFloat(sin(escapeAngle) * escapeDist * 0.3),
            duration: 0.12
        )

        let zigzag = SCNAction.sequence([dart1, dart2, dart3])

        // Phase 3: After scramble, resume normal calm flight from new position
        let fullSequence = SCNAction.sequence([panicFlap, zigzag])
        node.runAction(fullSequence) { [weak self] in
            guard let self = self else { return }
            // Resume normal gentle flight and wing flap from wherever the butterfly landed
            let idx = self.butterflyNodes.firstIndex(of: node) ?? 0
            self.addFlightAnimation(to: node)
            self.addWingFlapAnimation(to: node, index: idx)
        }
    }



    // MARK: - Garden Placement
    private func placeGarden(at screenPoint: CGPoint) {
        guard !gardenPlaced else { return }

        // Try raycast on detected horizontal plane
        if let query = arView.raycastQuery(from: screenPoint,
                                            allowing: .estimatedPlane,
                                            alignment: .horizontal),
           let result = arView.session.raycast(query).first {
            placeGardenAt(transform: result.worldTransform)
            return
        }

        // Fallback: place 1.2m in front of camera
        guard let camera = arView.session.currentFrame?.camera else { return }
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -1.2
        let transform = simd_mul(camera.transform, translation)
        placeGardenAt(transform: transform)
    }

    private func placeGardenAt(transform: simd_float4x4) {
        gardenPlaced = true
        placeButton.isHidden = true

        // Load Garden.usdz
        guard let gardenURL = Bundle.main.url(forResource: "Fantasy_Landscape", withExtension: "usdz"),
              let gardenScene = try? SCNScene(url: gardenURL, options: nil) else {
            showLoadError()
            return
        }

        let wrapper = SCNNode()
        wrapper.position = SCNVector3(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )
        arView.scene.rootNode.addChildNode(wrapper)
        wrapperNode = wrapper

        let node = SCNNode()
        for child in gardenScene.rootNode.childNodes {
            node.addChildNode(child)
        }
        node.scale = SCNVector3(0.003, 0.003, 0.003)
        // Position relative to wrapper is 0,0,0
        node.position = SCNVector3(0, 0, 0)
        wrapper.addChildNode(node)

        let anchor = ARAnchor(transform: transform)
        arView.session.add(anchor: anchor)

        node.opacity = 0
        gardenNode = node

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        node.opacity = 1
        SCNTransaction.commit()

        // Spawn butterflies inside the wrapper
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.spawnButterflies()
        }

        // Update status
        DispatchQueue.main.async {
            self.statusLabel.text = "🦋 Your garden is alive! \(self.butterflyCount) butterfly\(self.butterflyCount == 1 ? "" : "s") are flying"
        }
    }

    private func showLoadError() {
        statusLabel.text = "⚠️ Could not load garden model"
        gardenPlaced = false
        placeButton.isHidden = false
    }

    // MARK: - Butterfly Spawning
    private func spawnButterflies() {
        guard let wrapper = wrapperNode else { return }
        
        for i in 0..<butterflyCount {
            let butterfly = createButterflyNode(index: i)

            // Random local position inside wrapper
            let angle = Float(i) * (Float.pi * 2 / Float(butterflyCount))
            let radius = Float.random(in: 0.15...0.4)
            let height = Float.random(in: 0.08...0.35)

            butterfly.position = SCNVector3(
                radius * cos(angle),
                height,
                radius * sin(angle)
            )

            wrapper.addChildNode(butterfly)
            butterflyNodes.append(butterfly)

            // Start flight animation
            let delay = Double(i) * 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.addFlightAnimation(to: butterfly)
                self.addWingFlapAnimation(to: butterfly, index: i)
            }
        }
    }

    private func createButterflyNode(index: Int) -> SCNNode {
        // Plane geometry with butterfly image texture
        let size: CGFloat = index < 3 ? 0.06 : (index < 6 ? 0.05 : 0.04)
        let plane = SCNPlane(width: size, height: size)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "Image 12")
        material.isDoubleSided = true
        material.lightingModel = .constant // Unlit — looks good in AR
        plane.materials = [material]

        let node = SCNNode(geometry: plane)

        // Always face the camera (billboard)
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = [.X, .Y]
        node.constraints = [billboard]

        return node
    }

    private func addFlightAnimation(to node: SCNNode) {
        // Local animation around (0,0,0) of the wrapper wrapperNode
        let baseX = node.position.x
        let baseY = node.position.y
        let baseZ = node.position.z

        var actions: [SCNAction] = []
        for _ in 0..<6 {
            let nextX = Float.random(in: -0.4...0.4)
            let nextY = Float.random(in: 0.05...0.45)
            let nextZ = Float.random(in: -0.4...0.4)
            let duration = Double.random(in: 2.5...5.0)
            let move = SCNAction.move(to: SCNVector3(nextX, nextY, nextZ), duration: duration)
            move.timingMode = .easeInEaseOut
            actions.append(move)
        }
        // Return to original position to close the loop
        let returnAction = SCNAction.move(to: SCNVector3(baseX, baseY, baseZ), duration: 3.0)
        returnAction.timingMode = .easeInEaseOut
        actions.append(returnAction)

        let sequence = SCNAction.sequence(actions)
        node.runAction(SCNAction.repeatForever(sequence))
    }

    private func addWingFlapAnimation(to node: SCNNode, index: Int) {
        let flapSpeed = index >= 6 ? 0.35 : 0.5

        // Fold wings in (scale X: 1.0 → 0.25)
        let flapIn = SCNAction.customAction(duration: flapSpeed) { node, elapsedTime in
            let t = Float(elapsedTime / flapSpeed)
            node.scale = SCNVector3(max(0.25, 1.0 - 0.75 * t), 1.0, 1.0)
        }
        // Open wings out (scale X: 0.25 → 1.0)
        let flapOut = SCNAction.customAction(duration: flapSpeed) { node, elapsedTime in
            let t = Float(elapsedTime / flapSpeed)
            node.scale = SCNVector3(min(1.0, 0.25 + 0.75 * t), 1.0, 1.0)
        }
        let flap = SCNAction.repeatForever(SCNAction.sequence([flapIn, flapOut]))
        node.runAction(flap, forKey: "wingFlap")
    }
}

// MARK: - ARSCNViewDelegate
extension ARGardenViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor, !gardenPlaced else { return }
        DispatchQueue.main.async {
            self.statusLabel.text = "✅ Surface detected! Tap or press the button to place your garden"
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ARGardenViewController: UIGestureRecognizerDelegate {
    // Allow pinch and rotation to work at the same time
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
