import UIKit

class TwoMinuteResetViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var activity1View: UIView!
    @IBOutlet weak var activity2View: UIView!
    @IBOutlet weak var activity3View: UIView!
    @IBOutlet weak var activity4View: UIView!
    @IBOutlet weak var activity5View: UIView!
    @IBOutlet weak var activity6View: UIView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    // MARK: - Setup
    private func setupGestures() {
        addTap(to: activity1View, action: #selector(handleDeepBreathing))
        addTap(to: activity2View, action: #selector(handleCalmingSounds))
        addTap(to: activity3View, action: #selector(handleFingerRhythm))
        addTap(to: activity4View, action: #selector(handleShoulderDrop))
        addTap(to: activity5View, action: #selector(handleEyeRelaxation))
        addTap(to: activity6View, action: #selector(handleMeditation))
    }
    
    private func addTap(to view: UIView, action: Selector) {
        let tap = UITapGestureRecognizer(target: self, action: action)
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
    }
    
    // MARK: - Actions
    @objc private func handleDeepBreathing() {
        navigateToBreathing(name: "Deep Breathing", type: "breathing")
    }
    
    @objc private func handleCalmingSounds() {
        navigateToBreathing(name: "Calming Sounds", type: "calmingSounds")
    }
    
    @objc private func handleFingerRhythm() {
        navigateToBreathing(name: "Finger Rhythm", type: "fingerRhythm")
    }
    
    @objc private func handleShoulderDrop() {
        navigateToBreathing(name: "Shoulder Drop", type: "shoulderDrop")
    }
    
    @objc private func handleEyeRelaxation() {
        navigateToBreathing(name: "Eye Relaxation", type: "eyeRelaxation")
    }
    
    @objc private func handleMeditation() {
        navigateToBreathing(name: "Meditation", type: "meditation")
    }
    
    // MARK: - Navigation
    private func navigateToBreathing(name: String, type: String) {
        // Guard: sessions require Supabase to save progress — block if offline
        guard NetworkMonitor.shared.isConnected else {
            showNoInternetAlert()
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let breathingVC = storyboard.instantiateViewController(withIdentifier: "breathingVC") as? BreathingViewController {
            breathingVC.activityName = name
            breathingVC.exerciseType = type
            
            if let navigationController = self.navigationController {
                // Set this controller as delegate to handle custom transitions
                navigationController.delegate = self
                // Push without default animation - custom animation will handle it
                navigationController.pushViewController(breathingVC, animated: true)
            } else {
                breathingVC.modalPresentationStyle = .fullScreen
                self.present(breathingVC, animated: true)
            }
        }
    }
}

// MARK: - UINavigationControllerDelegate for smooth transition
extension TwoMinuteResetViewController: UINavigationControllerDelegate {
    
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        
        // Only apply custom animation when pushing to BreathingViewController
        if operation == .push && toVC is BreathingViewController {
            return SmoothPushTransition()
        }
        
        return nil
    }
}

// MARK: - Custom Transition Animator
class SmoothPushTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration: TimeInterval = 0.3
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let container = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toViewController)
        
        // Start from off-screen (right side)
        toViewController.view.frame = CGRect(
            x: container.bounds.width,
            y: 0,
            width: container.bounds.width,
            height: container.bounds.height
        )
        
        container.addSubview(toViewController.view)
        
        // Animate with spring for snappy natural feel
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                toViewController.view.frame = finalFrame
            },
            completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}

