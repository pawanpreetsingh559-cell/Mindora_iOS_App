import UIKit

class SignInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    private let continueSpinner = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.isSecureTextEntry = true

        nameTextField.tintColor = .black
        emailTextField.tintColor = .black
        passwordTextField.tintColor = .black

        // Keyboard handling
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        nameTextField.returnKeyType = .next
        emailTextField.returnKeyType = .next
        passwordTextField.returnKeyType = .done

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.3
        // Find the active text field's bottom edge
        let activeBottom = findActiveFieldBottom()
        let overlap = activeBottom - (view.frame.height - keyboardFrame.height) + 20 // 20pt padding
        if overlap > 0 {
            UIView.animate(withDuration: duration) {
                self.view.frame.origin.y = -overlap
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.3
        UIView.animate(withDuration: duration) {
            self.view.frame.origin.y = 0
        }
    }

    private func findActiveFieldBottom() -> CGFloat {
        for field in [nameTextField, emailTextField, passwordTextField] {
            if let f = field, f.isFirstResponder {
                let frame = f.convert(f.bounds, to: view)
                return frame.maxY
            }
        }
        return view.frame.height / 2
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    @IBAction func continueButtonTapped(_ sender: UIButton) {
        registerUser()
    }

    private func registerUser() {
        let name = nameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let email = emailTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordTextField.text ?? ""

        if !isValidName(name) {
            showAlert(title: "Invalid Name", message: "Name should be 2–21 characters and contain only letters and spaces.")
            return
        }

        if !isValidEmail(email) {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address")
            return
        }

        if !isValidPassword(password) {
            showAlert(title: "Invalid Password", message: "Password must be at least 8 characters")
            return
        }

        // Guard: signing up requires a live connection to Supabase
        guard NetworkMonitor.shared.isConnected else {
            showNoInternetAlert()
            return
        }

        setContinueLoading(true)

        DataManager.shared.sendSignUpOTP(name: name, email: email, password: password) { [weak self] success, errorMessage in
            self?.setContinueLoading(false)
            
            if success {
                let otpVC = OTPVerificationViewController()
                otpVC.email = email
                otpVC.userName = name
                otpVC.password = password
                otpVC.authMode = .signUp
                
                self?.navigationController?.pushViewController(otpVC, animated: true)
            } else {
                var message = errorMessage ?? "Registration failed. Please try again."
                if message.lowercased().contains("user already registered") {
                    message = "An account with this email already exists. If you recently deleted your account, please use the Login screen to restore it."
                }
                self?.showAlert(title: "Error", message: message)
            }
        }
    }
    
    private func setContinueLoading(_ loading: Bool) {
        continueButton.isEnabled = !loading
        if loading {
            continueButton.setTitle("", for: .normal)
            continueButton.configuration?.title = ""
            continueSpinner.color = .darkGray
            continueSpinner.translatesAutoresizingMaskIntoConstraints = false
            continueButton.addSubview(continueSpinner)
            NSLayoutConstraint.activate([
                continueSpinner.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
                continueSpinner.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor)
            ])
            continueSpinner.startAnimating()
        } else {
            continueSpinner.stopAnimating()
            continueSpinner.removeFromSuperview()
            continueButton.setTitle("Continue", for: .normal)
            continueButton.configuration?.title = "Continue"
        }
    }

    // MARK: - Helper Functions

    private func navigateToDashboard() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "Dashboard")
        
        guard let window = self.view.window else { return }
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = tabBarController
        }, completion: nil)
    }
    
    private func clearFields() {
        nameTextField.text = ""
        emailTextField.text = ""
        passwordTextField.text = ""
    }

    private func isValidName(_ name: String) -> Bool {
        guard name.count >= 2, name.count <= 21 else { return false }
        let allowed = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-'"))
        return name.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)
        return predicate.evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showAlertWithAction(title: String, message: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion()
        })
        present(alert, animated: true)
    }
}
