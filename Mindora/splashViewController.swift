import UIKit

class splashViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Delay for splash animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkSessionAndNavigate()
        }
    }
    
    private func checkSessionAndNavigate() {
        Task {
            let isActive = await DataManager.shared.restoreSession()
            
            await MainActor.run {
                if isActive {
                    self.goToDashboard()
                } else {
                    self.performSegue(withIdentifier: "goToOnboarding", sender: nil)
                }
            }
        }
    }

    private func goToDashboard() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "Dashboard")
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
        }
    }
}
