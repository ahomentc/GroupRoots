//
//  EditProfileController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 4/4/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import YPImagePicker

class EditProfileController: UIViewController, UINavigationControllerDelegate {
        
    var user: User? {
        didSet {
            setupProfileImage()
            setupInputFields()
        }
    }

    private let profileImageButton: CustomImageView = {
        let iv = CustomImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        return iv
    }()
    
    private var originalImage: UIImage?
    private var profileImage: UIImage?
    
    private let plusImage: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.image = #imageLiteral(resourceName: "plus_white")
        iv.tintColor = .white
        iv.layer.zPosition = 10;
        iv.clipsToBounds = true
        return iv
    }()
    
    private lazy var usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "username"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .none
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self
//        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private lazy var nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "name"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .none
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self
//        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private lazy var bioTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Bio"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .none
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self
        return tf
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.text = "Bio"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "Username"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Name"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(handleSave))
        
        view.addSubview(profileImageButton)
        profileImageButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 40, width: 120, height: 120)
        profileImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageButton.layer.cornerRadius = 120 / 2
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        profileImageButton.isUserInteractionEnabled = true
        profileImageButton.addGestureRecognizer(singleTap)

        view.addSubview(plusImage)
        plusImage.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 75, width: 50, height: 50)
        plusImage.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        plusImage.isUserInteractionEnabled = true
        plusImage.addGestureRecognizer(singleTap)
    }
    
    @objc func setupProfileImage() {
        guard let user = user else { return }
        if let profileImageUrl = user.profileImageUrl {
            profileImageButton.loadImage(urlString: profileImageUrl)
            originalImage = profileImageButton.image
        }
    }
    
    private func setupInputFields() {
        guard let user = user else { return }
        
        usernameTextField.text = user.username
        nameTextField.text = user.name
        bioTextField.text = user.bio
        
        let separatorViewTop = UIView()
        separatorViewTop.backgroundColor = UIColor(white: 0, alpha: 0.1)
        view.addSubview(separatorViewTop)
        separatorViewTop.anchor(top: profileImageButton.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, height: 0.5)
        
        view.addSubview(usernameLabel)
        usernameLabel.anchor(top: separatorViewTop.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, paddingTop: 15, paddingLeft: 20)
        
        view.addSubview(usernameTextField)
        usernameTextField.anchor(top: separatorViewTop.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 10, paddingLeft: 130, height: 30)
        
        let separatorViewMid = UIView()
        separatorViewMid.backgroundColor = UIColor(white: 0, alpha: 0.1)
        view.addSubview(separatorViewMid)
        separatorViewMid.anchor(top: usernameLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 15, height: 0.5)
        
        view.addSubview(bioLabel)
        bioLabel.anchor(top: separatorViewMid.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, paddingTop: 15, paddingLeft: 20)
        
        view.addSubview(bioTextField)
        bioTextField.anchor(top: separatorViewMid.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 10, paddingLeft: 130, height: 30)
        
        let separatorViewMid2 = UIView()
        separatorViewMid2.backgroundColor = UIColor(white: 0, alpha: 0.1)
        view.addSubview(separatorViewMid2)
        separatorViewMid2.anchor(top: bioLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 15, height: 0.5)
        
        view.addSubview(nameLabel)
        nameLabel.anchor(top: separatorViewMid2.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, paddingTop: 15, paddingLeft: 20)
        
        view.addSubview(nameTextField)
        nameTextField.anchor(top: separatorViewMid2.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 10, paddingLeft: 130, height: 30)
        
        let separatorViewBottom = UIView()
        separatorViewBottom.backgroundColor = UIColor(white: 0, alpha: 0.1)
        view.addSubview(separatorViewBottom)
        separatorViewBottom.anchor(top: nameLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 15, height: 0.5)
        
    }
    
    private func resetInputFields() {
        usernameTextField.text = ""
        usernameTextField.isUserInteractionEnabled = true
        nameTextField.isUserInteractionEnabled = true
        bioTextField.text = ""
        bioTextField.isUserInteractionEnabled = true
    }
    
    @objc private func selectImage() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleSave() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let username = usernameTextField.text
        let name = nameTextField.text
        let bio = bioTextField.text
    
        usernameTextField.isUserInteractionEnabled = false
        nameTextField.isUserInteractionEnabled = false
        bioTextField.isUserInteractionEnabled = false
                
//     username regex:   ^[a-zA-Z0-9_-]*$   must match
        if username != nil {
            if username!.range(of: #"^[a-zA-Z0-9_-]*$"#, options: .regularExpression) == nil {
                let alert = UIAlertController(title: "Username invalid", message: "Please enter a username with no symbols (underscore is okay)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
                self.resetInputFields()
                return
            }
        }
        
        Database.database().updateUser(withUID: currentLoggedInUserId, username: username, name: name, bio: bio, image: self.profileImage) { (err) in
            if err != nil {
                guard let error = err else { self.resetInputFields(); return }
                if error.localizedDescription == "Username Taken" {
                    let alert = UIAlertController(title: "Username Taken", message: "Please select a different username.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
            self.resetInputFields()
            self.dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(name: NSNotification.Name("updatedUser"), object: nil)
            return
        }
    }
}

extension EditProfileController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            profileImageButton.image = editedImage
            profileImage = editedImage
            plusImage.image = UIImage()
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            profileImageButton.image = originalImage
            profileImage = originalImage
            plusImage.image = UIImage()
        }
        dismiss(animated: true, completion: nil)
    }
}

extension EditProfileController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.count ?? 0
        if range.length + range.location > currentCharacterCount {
            return false
        }
        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= 120
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
