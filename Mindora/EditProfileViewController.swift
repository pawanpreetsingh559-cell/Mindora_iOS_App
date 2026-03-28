import UIKit
import PhotosUI

// Delegate so ProfileViewController refreshes after save
protocol EditProfileDelegate: AnyObject {
    func didUpdateProfile(photoRemoved: Bool)
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
    private var photoShouldBeDeleted = false  // set when Remove Photo is tapped, executed on Save

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentData()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.973, green: 0.961, blue: 0.933, alpha: 1.0)

        // Avatar — tapping it opens the same sheet as the button
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
        avatarImageView.isUserInteractionEnabled = true
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(showPhotoOptions))
        avatarImageView.addGestureRecognizer(avatarTap)

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
        nameTextField.tintColor = .black
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
            guard let self = self else { return }
            // Don't overwrite if user already removed or replaced the photo
            guard !self.photoShouldBeDeleted, self.selectedImage == nil else { return }
            if let photo = photo {
                self.avatarImageView.image = photo
                self.avatarImageView.tintColor = nil
                self.removePhotoButton.isHidden = false
            }
        }
    }

    private func setInitialsAvatar(name: String) {
        let size = CGSize(width: 110, height: 110)
        avatarImageView.image = DataManager.shared.generateInitialsImage(name: name, size: size)
        avatarImageView.tintColor = nil
    }

    // MARK: - Actions
    @IBAction func changePhotoTapped(_ sender: UIButton) {
        showPhotoOptions()
    }

    @objc private func showPhotoOptions() {
        let sheet = UIAlertController(title: "Profile Avatar", message: "Customize your avatar style", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.presentPhotoPicker()
        })
        sheet.addAction(UIAlertAction(title: "Customize Initial", style: .default) { [weak self] _ in
            self?.showCustomizeInitialSheet()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = avatarImageView
        }
        present(sheet, animated: true)
    }
    
    private func showCustomizeInitialSheet() {
        let currentName = nameTextField.text?.trimmingCharacters(in: .whitespaces)
        let name = (currentName?.isEmpty == false) ? currentName! : "Guest"
        let vc = CustomizeInitialViewController(name: name)
        vc.onApply = { [weak self] themeIndex in
            DataManager.shared.setAvatarTheme(themeIndex)
            self?.removePhotoAndShowInitials()
        }
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(vc, animated: true)
    }
    
    private func removePhotoAndShowInitials() {
        photoShouldBeDeleted = true
        selectedImage = nil
        removePhotoButton.isHidden = true
        if let name = nameTextField.text, !name.isEmpty {
            setInitialsAvatar(name: name)
        } else {
            setInitialsAvatar(name: "Guest")
        }
    }

    // Called from both the Remove Photo button and the action sheet option
    private func removePhoto() {
        photoShouldBeDeleted = true
        selectedImage = nil
        removePhotoButton.isHidden = true
        if let name = nameTextField.text, !name.isEmpty {
            setInitialsAvatar(name: name)
        } else {
            avatarImageView.image = UIImage(systemName: "person.fill")
            avatarImageView.tintColor = .white
        }
        // Stay on screen — user must press Save Changes to commit
    }

    @IBAction func removePhotoTapped(_ sender: UIButton) {
        removePhoto()
    }

    @IBAction func saveTapped(_ sender: UIButton) {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespaces),
              !name.isEmpty else {
            shakeTextField()
            return
        }

        DataManager.shared.updateUserName(name)
        sender.isEnabled = false
        sender.setTitle("", for: .normal)

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        sender.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: sender.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: sender.centerYAnchor),
        ])
        spinner.startAnimating()

        let finish = { [weak self] (success: Bool, photoWasRemoved: Bool) in
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            sender.isEnabled = true
            sender.setTitle("Save Changes", for: .normal)
            if success {
                self?.delegate?.didUpdateProfile(photoRemoved: photoWasRemoved)
                self?.dismiss(animated: true)
            } else {
                sender.setTitle("Failed — try again", for: .normal)
                sender.backgroundColor = UIColor.systemRed
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    sender.setTitle("Save Changes", for: .normal)
                    sender.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
                }
            }
        }

        if let img = selectedImage {
            DataManager.shared.saveProfilePhoto(img) { success in finish(success, false) }
        } else if photoShouldBeDeleted {
            DataManager.shared.deleteProfilePhoto { finish(true, true) }
        } else {
            finish(true, false)
        }
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
