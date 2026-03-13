//
//  EditProfileViewController.swift
//  Mindora
//

import UIKit
import PhotosUI

// Delegate so ProfileViewController refreshes after save
protocol EditProfileDelegate: AnyObject {
    func didUpdateProfile()
}

class EditProfileViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var changePhotoButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var removePhotoButton: UIButton!

    // MARK: - Properties
    weak var delegate: EditProfileDelegate?
    private var selectedImage: UIImage?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentData()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1.0)

        // Avatar
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 55
        avatarImageView.layer.borderWidth = 3
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.layer.shadowColor = UIColor.black.cgColor
        avatarImageView.layer.shadowOpacity = 0.15
        avatarImageView.layer.shadowRadius = 8
        avatarImageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        avatarImageView.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        avatarImageView.image = UIImage(systemName: "person.fill")
        avatarImageView.tintColor = .white

        // Name field
        nameTextField.borderStyle = .none
        nameTextField.backgroundColor = .white
        nameTextField.layer.cornerRadius = 14
        nameTextField.layer.shadowColor = UIColor.black.cgColor
        nameTextField.layer.shadowOpacity = 0.06
        nameTextField.layer.shadowRadius = 6
        nameTextField.layer.shadowOffset = CGSize(width: 0, height: 2)
        nameTextField.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        nameTextField.textColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        nameTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        nameTextField.leftViewMode = .always
        nameTextField.returnKeyType = .done
        nameTextField.delegate = self
        nameTextField.autocorrectionType = .no

        // Email label
        emailLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        emailLabel.textColor = UIColor.systemGray

        // Save button
        saveButton.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        saveButton.layer.cornerRadius = 14
        saveButton.layer.shadowColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0).cgColor
        saveButton.layer.shadowOpacity = 0.35
        saveButton.layer.shadowRadius = 8
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 4)

        // Change photo button
        changePhotoButton.setTitle("Change Photo", for: .normal)
        changePhotoButton.setTitleColor(UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0), for: .normal)
        changePhotoButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)

        // Remove photo button
        removePhotoButton.setTitle("Remove Photo", for: .normal)
        removePhotoButton.setTitleColor(.systemRed, for: .normal)
        removePhotoButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        removePhotoButton.isHidden = true // Will show after async load if photo exists
    }

    private func loadCurrentData() {
        guard let user = DataManager.shared.getCurrentUser() else { return }
        nameTextField.text = user.name
        emailLabel.text = user.email

        // Show initials first as placeholder
        setInitialsAvatar(name: user.name)
        
        // Load photo from Supabase asynchronously
        DataManager.shared.loadProfilePhoto { [weak self] photo in
            if let photo = photo {
                self?.avatarImageView.image = photo
                self?.avatarImageView.tintColor = nil
                self?.removePhotoButton.isHidden = false
            }
        }
    }

    private func setInitialsAvatar(name: String) {
        let initials = name.components(separatedBy: " ")
            .compactMap { $0.first.map { String($0) } }
            .prefix(2)
            .joined()
            .uppercased()

        let size = CGSize(width: 110, height: 110)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        let colors = [
            UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0),
            UIColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0)
        ]
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map { $0.cgColor } as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: 0),
                               end: CGPoint(x: size.width, y: size.height),
                               options: [])
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 40, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let str = initials as NSString
        let strSize = str.size(withAttributes: attrs)
        str.draw(at: CGPoint(x: (size.width - strSize.width) / 2,
                             y: (size.height - strSize.height) / 2),
                 withAttributes: attrs)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        avatarImageView.image = img
        avatarImageView.tintColor = nil
    }

    // MARK: - Actions
    @IBAction func changePhotoTapped(_ sender: UIButton) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        sheet.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.presentCamera()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = sender
        }
        present(sheet, animated: true)
    }

    @IBAction func removePhotoTapped(_ sender: UIButton) {
        DataManager.shared.deleteProfilePhoto()
        selectedImage = nil
        removePhotoButton.isHidden = true
        if let name = nameTextField.text, !name.isEmpty {
            setInitialsAvatar(name: name)
        } else {
            avatarImageView.image = UIImage(systemName: "person.fill")
            avatarImageView.tintColor = .white
        }
    }

    @IBAction func saveTapped(_ sender: UIButton) {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespaces),
              !name.isEmpty else {
            shakeTextField()
            return
        }

        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }

        // Save name
        DataManager.shared.updateUserName(name)

        // Save photo if changed
        if let img = selectedImage {
            DataManager.shared.saveProfilePhoto(img)
        }

        delegate?.didUpdateProfile()
        dismiss(animated: true)
    }

    @IBAction func backTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    // MARK: - Photo Picker
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alert = UIAlertController(title: "Camera Unavailable",
                                          message: "Camera is not available on this device.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    private func applySelectedImage(_ image: UIImage) {
        selectedImage = image
        avatarImageView.image = image
        avatarImageView.tintColor = nil
        removePhotoButton.isHidden = false

        // Bounce animation
        avatarImageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8) {
            self.avatarImageView.transform = .identity
        }
    }

    // MARK: - Helpers
    private func shakeTextField() {
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.timingFunction = CAMediaTimingFunction(name: .linear)
        shake.duration = 0.4
        shake.values = [-10, 10, -8, 8, -5, 5, 0]
        nameTextField.layer.add(shake, forKey: "shake")
        nameTextField.layer.borderColor = UIColor.systemRed.cgColor
        nameTextField.layer.borderWidth = 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.nameTextField.layer.borderWidth = 0
        }
    }
}

// MARK: - UITextFieldDelegate
extension EditProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // Update initials preview live if no custom photo
        if selectedImage == nil {
            if let name = textField.text, !name.isEmpty {
                setInitialsAvatar(name: name)
            }
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension EditProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                if let image = object as? UIImage {
                    self?.applySelectedImage(image)
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
        if let img = image { applySelectedImage(img) }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
