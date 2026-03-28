import UIKit

class MoodScoreViewController: UIViewController {

    // MARK: - Outlets (Kept as UIView)
    @IBOutlet weak var score1Button: UIView!
    @IBOutlet weak var score2Button: UIView!
    @IBOutlet weak var score3Button: UIView!
    @IBOutlet weak var score4Button: UIView!
    @IBOutlet weak var score5Button: UIView!
    
    @IBOutlet weak var continueButton: UIButton!
    
    var selectedScore: Int? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }
    
    func setupUI() {
        continueButton.isEnabled = false
        continueButton.alpha = 0.5
        
        let allViews = [score1Button, score2Button, score3Button, score4Button, score5Button]
        allViews.forEach {
            $0?.layer.cornerRadius = 10
            $0?.layer.borderWidth = 1
            $0?.layer.borderColor = UIColor.systemGray5.cgColor
            $0?.backgroundColor = .white
        }
    }
    
    // MARK: - Gesture Setup
    func setupGestures() {
        let allViews = [score1Button, score2Button, score3Button, score4Button, score5Button]
        
        for view in allViews {
            // Create a tap gesture for each view
            let tap = UITapGestureRecognizer(target: self, action: #selector(scoreViewTapped(_:)))
            view?.addGestureRecognizer(tap)
            view?.isUserInteractionEnabled = true
        }
    }

    // MARK: - Action (Sender changed to UITapGestureRecognizer)
    @objc func scoreViewTapped(_ sender: UITapGestureRecognizer) {
        guard let tappedView = sender.view else { return }
        
        // 1. Reset all styles
        resetButtonStyles()
        
        // 2. Highlight selected view
        tappedView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        tappedView.layer.borderColor = UIColor.systemBlue.cgColor
        
        // 3. Determine score by checking which view was tapped
        if tappedView == score1Button { selectedScore = 1 }
        else if tappedView == score2Button { selectedScore = 2 }
        else if tappedView == score3Button { selectedScore = 3 }
        else if tappedView == score4Button { selectedScore = 4 }
        else if tappedView == score5Button { selectedScore = 5 }
        
        // 4. Enable Continue
        continueButton.isEnabled = true
        continueButton.alpha = 1.0
    }

    @IBAction func continueButtonTapped(_ sender: UIButton) {
        guard let score = selectedScore else { return }
        DataManager.shared.logMood(score: score)
        
        let message = score <= 3 ? "Attend more sessions in order to be calm & relaxed." : "Be consistent in order to be calm & relaxed."
        let alert = UIAlertController(title: "Your Journey", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { [weak self] _ in
            self?.navigateToDashboard()
        })
        
        present(alert, animated: true)
    }
    
    // Navigate to Dashboard (Tab Bar Controller)
    private func navigateToDashboard() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let dashboardTabBar = storyboard.instantiateViewController(withIdentifier: "Dashboard") as? UITabBarController {
            dashboardTabBar.modalPresentationStyle = .fullScreen
            dashboardTabBar.selectedIndex = 0 // Select the first tab (Dashboard)
            
            // Get the root view controller and present the dashboard
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = dashboardTabBar
                window.makeKeyAndVisible()
            }
        }
    }
    
    private func resetButtonStyles() {
        let allViews = [score1Button, score2Button, score3Button, score4Button, score5Button]
        for view in allViews {
            view?.backgroundColor = .white
            view?.layer.borderColor = UIColor.systemGray5.cgColor
        }
    }
}
