//
//  ForgotPasswordViewController.swift
//  Mindora final
//
//  Created by pawanpreet singh on 15/12/25.
//

import UIKit

class ForgotPasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        emailTextField.returnKeyType = .done
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func continueButtonTapped(_ sender: UIButton) {
        let email = emailTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        
        guard !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address.")
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address.")
            return
        }
        
        continueButton.isEnabled = false
        
        DataManager.shared.sendPasswordResetOTP(email: email) { [weak self] success, error in
            self?.continueButton.isEnabled = true
            
            if success {
                let otpVC = OTPVerificationViewController()
                otpVC.email = email
                otpVC.authMode = .resetPassword
                self?.navigationController?.pushViewController(otpVC, animated: true)
            } else {
                self?.showAlert(title: "Error", message: error ?? "Could not send verification code. Please try again.")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
