//
//  OTPVerificationViewController.swift
//  Mindora
//
//  Created by pawanpreet singh on 12/03/26.
//

import UIKit

enum OTPAuthMode {
    case signUp
    case login
    case resetPassword
}

class OTPVerificationViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    var email: String = ""
    var userName: String = ""
    var password: String = ""
    var authMode: OTPAuthMode = .signUp
    
    private var resendCooldown: Int = 0
    private var cooldownTimer: Timer?
    private var otpFields: [UITextField] = []
    
    // MARK: - UI Elements
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let otpStackView = UIStackView()
    private let verifyButton = UIButton(type: .system)
    private let resendButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Colors (matching Sign-In screen)
    private let bgColor = UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1.0)
    private let accentColor = UIColor.systemBlue
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startResendCooldown()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = bgColor
        navigationItem.hidesBackButton = false
        
        // Logo
        logoImageView.image = UIImage(named: "Image")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        
        // Title
        titleLabel.text = "Verify Your Email"
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "We've sent a verification code to\n\(email)"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        
        // OTP Stack View (6 boxes)
        otpStackView.axis = .horizontal
        otpStackView.spacing = 10
        otpStackView.distribution = .fillEqually
        otpStackView.alignment = .center
        otpStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(otpStackView)
        
        for i in 0..<6 {
            let field = UITextField()
            field.font = UIFont.systemFont(ofSize: 24, weight: .bold)
            field.textAlignment = .center
            field.keyboardType = .numberPad
            field.borderStyle = .none
            field.backgroundColor = .white
            field.layer.cornerRadius = 12
            field.layer.borderWidth = 1.5
            field.layer.borderColor = UIColor.systemGray4.cgColor
            field.delegate = self
            field.tag = i
            field.translatesAutoresizingMaskIntoConstraints = false
            field.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            
            field.heightAnchor.constraint(equalToConstant: 52).isActive = true
            
            otpStackView.addArrangedSubview(field)
            otpFields.append(field)
        }
        
        // Verify Button
        var config = UIButton.Configuration.filled()
        config.title = "Verify"
        config.cornerStyle = .medium
        verifyButton.configuration = config
        verifyButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        verifyButton.layer.cornerRadius = 12
        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)
        verifyButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(verifyButton)
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        verifyButton.addSubview(activityIndicator)
        
        // Resend Button
        resendButton.setTitle("Resend Code", for: .normal)
        resendButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        resendButton.setTitleColor(.systemBlue, for: .normal)
        resendButton.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)
        resendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resendButton)
        
        // Layout
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: 140),
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            otpStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            otpStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            otpStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            verifyButton.topAnchor.constraint(equalTo: otpStackView.bottomAnchor, constant: 36),
            verifyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            verifyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            verifyButton.heightAnchor.constraint(equalToConstant: 60),
            
            activityIndicator.centerYAnchor.constraint(equalTo: verifyButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: verifyButton.trailingAnchor, constant: -16),
            
            resendButton.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: 16),
            resendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow backspace
        if string.isEmpty {
            textField.text = ""
            textField.layer.borderColor = UIColor.systemGray4.cgColor
            // Move to previous field
            let prevIndex = textField.tag - 1
            if prevIndex >= 0 {
                otpFields[prevIndex].becomeFirstResponder()
            }
            return false
        }
        
        // Only allow single digit
        guard string.count == 1, string.rangeOfCharacter(from: .decimalDigits) != nil else {
            return false
        }
        
        textField.text = string
        textField.layer.borderColor = accentColor.cgColor
        
        // Move to next field
        let nextIndex = textField.tag + 1
        if nextIndex < 6 {
            otpFields[nextIndex].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return false
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        // Handle paste of full OTP
        guard let text = textField.text, text.count > 1 else { return }
        
        let digits = text.filter { $0.isNumber }
        for (i, digit) in digits.prefix(6).enumerated() {
            otpFields[i].text = String(digit)
            otpFields[i].layer.borderColor = accentColor.cgColor
        }
        
        let lastFilledIndex = min(digits.count, 6) - 1
        if lastFilledIndex >= 0 && lastFilledIndex < 5 {
            otpFields[lastFilledIndex + 1].becomeFirstResponder()
        } else {
            otpFields.last?.resignFirstResponder()
        }
    }
    
    private func getOTPString() -> String {
        return otpFields.compactMap { $0.text }.joined()
    }
    
    // MARK: - Actions
    @objc private func verifyTapped() {
        let otp = getOTPString()
        
        guard otp.count == 6 else {
            showAlert(title: "Invalid Code", message: "Please enter the complete verification code.")
            shakeOTPFields()
            return
        }
        
        setLoading(true)
        
        switch authMode {
        case .signUp:
            DataManager.shared.verifySignUpOTP(email: email, token: otp, name: userName, password: password) { [weak self] success, error in
                self?.setLoading(false)
                if success {
                    DataManager.shared.recalculateButterflies()
                    self?.showAlertWithAction(title: "Account Created", message: "Welcome \(self?.userName ?? "")! Your account is verified and ready.") {
                        self?.navigateToDashboard()
                    }
                } else {
                    self?.showAlert(title: "Verification Failed", message: error ?? "Invalid OTP. Please try again.")
                    self?.clearOTPFields()
                }
            }
            
        case .login:
            DataManager.shared.verifyLoginOTP(email: email, token: otp) { [weak self] success, error in
                self?.setLoading(false)
                if success {
                    DataManager.shared.recalculateButterflies()
                    let name = DataManager.shared.getCurrentUser()?.name ?? "User"
                    self?.showAlertWithAction(title: "Welcome Back", message: "Welcome back, \(name)!") {
                        self?.navigateToDashboard()
                    }
                } else {
                    self?.showAlert(title: "Verification Failed", message: error ?? "Invalid OTP. Please try again.")
                    self?.clearOTPFields()
                }
            }
            
        case .resetPassword:
            DataManager.shared.verifyPasswordResetOTP(email: email, token: otp) { [weak self] success, error in
                self?.setLoading(false)
                if success {
                    let resetVC = ResetPasswordViewController()
                    resetVC.email = self?.email ?? ""
                    self?.navigationController?.pushViewController(resetVC, animated: true)
                } else {
                    self?.showAlert(title: "Verification Failed", message: error ?? "Invalid OTP. Please try again.")
                    self?.clearOTPFields()
                }
            }
        }
    }
    
    @objc private func resendTapped() {
        guard resendCooldown <= 0 else { return }
        
        resendButton.isEnabled = false
        
        switch authMode {
        case .signUp:
            DataManager.shared.resendSignUpOTP(email: email) { [weak self] success, error in
                if success {
                    self?.showAlert(title: "Code Sent", message: "A new verification code has been sent to \(self?.email ?? "your email").")
                    self?.startResendCooldown()
                    self?.clearOTPFields()
                } else {
                    self?.showAlert(title: "Error", message: error ?? "Could not resend code.")
                    self?.resendButton.isEnabled = true
                }
            }
        case .login:
            DataManager.shared.sendLoginOTP(email: email, password: password) { [weak self] success, error in
                if success {
                    self?.showAlert(title: "Code Sent", message: "A new verification code has been sent to \(self?.email ?? "your email").")
                    self?.startResendCooldown()
                    self?.clearOTPFields()
                } else {
                    self?.showAlert(title: "Error", message: error ?? "Could not resend code.")
                    self?.resendButton.isEnabled = true
                }
            }
        case .resetPassword:
            DataManager.shared.sendPasswordResetOTP(email: email) { [weak self] success, error in
                if success {
                    self?.showAlert(title: "Code Sent", message: "A new verification code has been sent to \(self?.email ?? "your email").")
                    self?.startResendCooldown()
                    self?.clearOTPFields()
                } else {
                    self?.showAlert(title: "Error", message: error ?? "Could not resend code.")
                    self?.resendButton.isEnabled = true
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func clearOTPFields() {
        for field in otpFields {
            field.text = ""
            field.layer.borderColor = UIColor.systemGray4.cgColor
        }
        otpFields.first?.becomeFirstResponder()
    }
    
    private func shakeOTPFields() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -4, 4, 0]
        otpStackView.layer.add(animation, forKey: "shake")
    }
    
    private func startResendCooldown() {
        resendCooldown = 60
        resendButton.isEnabled = false
        updateResendTitle()
        
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.resendCooldown -= 1
            self.updateResendTitle()
            if self.resendCooldown <= 0 {
                self.cooldownTimer?.invalidate()
                self.resendButton.isEnabled = true
                self.resendButton.setTitle("Resend Code", for: .normal)
            }
        }
    }
    
    private func updateResendTitle() {
        resendButton.setTitle("Resend Code (\(resendCooldown)s)", for: .normal)
    }
    
    private func setLoading(_ loading: Bool) {
        verifyButton.isEnabled = !loading
        otpFields.forEach { $0.isEnabled = !loading }
        if loading {
            activityIndicator.startAnimating()
            verifyButton.configuration?.title = "Verifying..."
        } else {
            activityIndicator.stopAnimating()
            verifyButton.configuration?.title = "Verify"
        }
    }
    
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
    
    private func showAlertWithAction(title: String, message: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion()
        })
        present(alert, animated: true)
    }
    
    deinit {
        cooldownTimer?.invalidate()
    }
}
