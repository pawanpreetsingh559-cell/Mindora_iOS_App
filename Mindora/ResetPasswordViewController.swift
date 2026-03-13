//
//  ResetPasswordViewController.swift
//  Mindora
//
//  Created by pawanpreet singh on 13/03/26.
//

import UIKit

class ResetPasswordViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    var email: String = ""
    
    // MARK: - Colors
    private let bgColor = UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1.0)
    
    // MARK: - UI Elements
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let newPasswordLabel = UILabel()
    private let newPasswordTextField = UITextField()
    private let confirmPasswordLabel = UILabel()
    private let confirmPasswordTextField = UITextField()
    private let resetButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        newPasswordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        newPasswordTextField.returnKeyType = .next
        confirmPasswordTextField.returnKeyType = .done
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == newPasswordTextField {
            confirmPasswordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = bgColor
        navigationItem.hidesBackButton = true
        
        // Logo
        logoImageView.image = UIImage(named: "Image")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        
        // Title
        titleLabel.text = "Reset Password"
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Enter your new password"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        
        // New Password Label
        newPasswordLabel.text = "New Password"
        newPasswordLabel.font = UIFont.systemFont(ofSize: 17)
        newPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newPasswordLabel)
        
        // New Password Text Field
        newPasswordTextField.placeholder = "Enter new password"
        newPasswordTextField.font = UIFont.systemFont(ofSize: 14)
        newPasswordTextField.borderStyle = .roundedRect
        newPasswordTextField.isSecureTextEntry = true
        newPasswordTextField.layer.cornerRadius = 25
        newPasswordTextField.clipsToBounds = true
        newPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newPasswordTextField)
        
        // Confirm Password Label
        confirmPasswordLabel.text = "Confirm Password"
        confirmPasswordLabel.font = UIFont.systemFont(ofSize: 17)
        confirmPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(confirmPasswordLabel)
        
        // Confirm Password Text Field
        confirmPasswordTextField.placeholder = "Re-enter new password"
        confirmPasswordTextField.font = UIFont.systemFont(ofSize: 14)
        confirmPasswordTextField.borderStyle = .roundedRect
        confirmPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.layer.cornerRadius = 25
        confirmPasswordTextField.clipsToBounds = true
        confirmPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(confirmPasswordTextField)
        
        // Reset Button
        var config = UIButton.Configuration.filled()
        config.title = "Reset Password"
        config.cornerStyle = .medium
        resetButton.configuration = config
        resetButton.layer.cornerRadius = 12
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resetButton)
        
        // Activity Indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addSubview(activityIndicator)
        
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
            
            newPasswordLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            newPasswordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            
            newPasswordTextField.topAnchor.constraint(equalTo: newPasswordLabel.bottomAnchor, constant: 10),
            newPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            newPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            newPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            confirmPasswordLabel.topAnchor.constraint(equalTo: newPasswordTextField.bottomAnchor, constant: 16),
            confirmPasswordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            
            confirmPasswordTextField.topAnchor.constraint(equalTo: confirmPasswordLabel.bottomAnchor, constant: 10),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            resetButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 36),
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            resetButton.heightAnchor.constraint(equalToConstant: 60),
            
            activityIndicator.centerYAnchor.constraint(equalTo: resetButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: resetButton.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Actions
    @objc private func resetTapped() {
        let newPassword = newPasswordTextField.text ?? ""
        let confirmPassword = confirmPasswordTextField.text ?? ""
        
        guard !newPassword.isEmpty else {
            showAlert(title: "Error", message: "Please enter a new password.")
            return
        }
        
        guard newPassword.count >= 8 else {
            showAlert(title: "Error", message: "Password must be at least 8 characters.")
            return
        }
        
        guard newPassword == confirmPassword else {
            showAlert(title: "Error", message: "Passwords do not match.")
            return
        }
        
        setLoading(true)
        
        DataManager.shared.updatePassword(newPassword: newPassword) { [weak self] success, error in
            self?.setLoading(false)
            if success {
                self?.showAlertWithAction(title: "Password Reset", message: "Your password has been updated successfully. Please log in with your new password.") {
                    self?.navigateToLogin()
                }
            } else {
                self?.showAlert(title: "Error", message: error ?? "Could not update password. Please try again.")
            }
        }
    }
    
    private func setLoading(_ loading: Bool) {
        resetButton.isEnabled = !loading
        newPasswordTextField.isEnabled = !loading
        confirmPasswordTextField.isEnabled = !loading
        if loading {
            activityIndicator.startAnimating()
            resetButton.configuration?.title = "Updating..."
        } else {
            activityIndicator.stopAnimating()
            resetButton.configuration?.title = "Reset Password"
        }
    }
    
    private func navigateToLogin() {
        if let navController = navigationController {
            for vc in navController.viewControllers {
                if vc is LogInViewController {
                    navController.popToViewController(vc, animated: true)
                    return
                }
            }
            navController.popToRootViewController(animated: true)
        }
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
