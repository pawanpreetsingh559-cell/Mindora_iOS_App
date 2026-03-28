import UIKit

class LogInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    private let loginSpinner = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.isSecureTextEntry = true

        emailTextField.tintColor = .black
        passwordTextField.tintColor = .black

        // Keyboard handling
        emailTextField.delegate = self
        passwordTextField.delegate = self
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
        let activeBottom = findActiveFieldBottom()
        let overlap = activeBottom - (view.frame.height - keyboardFrame.height) + 20
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
        for field in [emailTextField, passwordTextField] {
            if let f = field, f.isFirstResponder {
                let frame = f.convert(f.bounds, to: view)
                return frame.maxY
            }
        }
        return view.frame.height / 2
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    @IBAction func logInButtonTapped(_ sender: UIButton) {
        loginUser()
    }

    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let forgotVC = storyboard.instantiateViewController(withIdentifier: "ForgotPasswordVC")
        navigationController?.pushViewController(forgotVC, animated: true)
    }

    private func loginUser() {
        let email = emailTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordTextField.text ?? ""

        if email.isEmpty {
            showAlert(title: "Error", message: "Please enter your email")
            return
        }

        if !isValidEmail(email) {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address format.")
            return
        }

        if password.isEmpty {
            showAlert(title: "Error", message: "Please enter your password")
            return
        }

        // Guard: logging in requires a live connection to Supabase
        guard NetworkMonitor.shared.isConnected else {
            showNoInternetAlert()
            return
        }

        setLoginLoading(true)

        DataManager.shared.sendLoginOTP(email: email, password: password) { [weak self] success, errorMessage in
            self?.setLoginLoading(false)
            
            if success {
                let otpVC = OTPVerificationViewController()
                otpVC.email = email
                otpVC.password = password
                otpVC.authMode = .login
                
                self?.navigationController?.pushViewController(otpVC, animated: true)
            } else {
                var message = errorMessage ?? "Login failed. Please check your credentials."
                if message.lowercased().contains("invalid login credentials") {
                    message = "No matching account was found with these details, or the password was incorrect."
                }
                self?.showAlert(title: "Login Failed", message: message)
            }
        }
    }
    
    private func setLoginLoading(_ loading: Bool) {
        logInButton.isEnabled = !loading
        if loading {
            logInButton.setTitle("", for: .normal)
            logInButton.configuration?.title = ""
            loginSpinner.color = .darkGray
            loginSpinner.translatesAutoresizingMaskIntoConstraints = false
            logInButton.addSubview(loginSpinner)
            NSLayoutConstraint.activate([
                loginSpinner.centerXAnchor.constraint(equalTo: logInButton.centerXAnchor),
                loginSpinner.centerYAnchor.constraint(equalTo: logInButton.centerYAnchor)
            ])
            loginSpinner.startAnimating()
        } else {
            loginSpinner.stopAnimating()
            loginSpinner.removeFromSuperview()
            logInButton.setTitle("Continue", for: .normal)
            logInButton.configuration?.title = "Continue"
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

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)
        return predicate.evaluate(with: email)
    }

    private func showAlertWithAction(title: String, message: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion()
        })
        present(alert, animated: true)
    }
}
