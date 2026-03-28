import UIKit

class OnboardingViewController: UIViewController {

   
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}
