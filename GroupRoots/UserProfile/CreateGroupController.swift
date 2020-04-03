//
//  CreateGroup.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

class CreateGroupController: UIViewController, UINavigationControllerDelegate {
    
    private var isPrivate: Bool = false
    
    private let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "plus_photo"), for: .normal)
        button.layer.masksToBounds = true
        button.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(handlePlusPhoto), for: .touchUpInside)
        return button
    }()
    
    private lazy var groupnameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Group Name"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self as UITextFieldDelegate
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private lazy var bioTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "bio"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self as UITextFieldDelegate
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private let createGroupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleCreateGroup), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    private let publicGroupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Public", for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor( UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        button.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        button.layer.borderWidth = 1
        button.addTarget(self, action: #selector(handleSelectedPublic), for: .touchUpInside)
        return button
    }()
    
    private let privateGroupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Private", for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.layer.borderColor = UIColor.gray.cgColor
        button.setTitleColor(UIColor.gray, for: .normal)
        button.addTarget(self, action: #selector(handleSelectedPrivate), for: .touchUpInside)
        button.layer.borderWidth = 0
        return button
    }()
    
    private var profileImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        view.backgroundColor = .white
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnView)))
        
        view.addSubview(plusPhotoButton)
        plusPhotoButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 40, width: 140, height: 140)
        plusPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        plusPhotoButton.layer.cornerRadius = 140 / 2
        
        setupInputFields()
    }
    
    private func setupInputFields() {
        
        let radioButtonsStack = UIStackView(arrangedSubviews: [publicGroupButton, privateGroupButton])
        radioButtonsStack.distribution = .fillEqually
        radioButtonsStack.axis = .horizontal
        radioButtonsStack.spacing = 10
        
        let stackView = UIStackView(arrangedSubviews: [groupnameTextField, bioTextField, radioButtonsStack, createGroupButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 25
        
        view.addSubview(stackView)
        stackView.anchor(top: plusPhotoButton.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 50, paddingLeft: 40, paddingRight: 40, height: 250)
    }
    
    private func resetInputFields() {
        groupnameTextField.text = ""
//        bioTextField.text = ""
        
        groupnameTextField.isUserInteractionEnabled = true
        bioTextField.isUserInteractionEnabled = true
        
        createGroupButton.isEnabled = false
        createGroupButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
    }
    
    @objc private func handleTapOnView(_ sender: UITextField) {
        groupnameTextField.resignFirstResponder()
        bioTextField.resignFirstResponder()
    }
    
    @objc private func handlePlusPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func handleTextInputChange() {
        let isFormValid = groupnameTextField.text?.isEmpty == false && bioTextField.text?.isEmpty == false
        if isFormValid {
            createGroupButton.isEnabled = true
            createGroupButton.backgroundColor = UIColor.mainBlue
        } else {
            createGroupButton.isEnabled = false
            createGroupButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        }
    }
    
    @objc private func handleAlreadyHaveAccount() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleCreateGroup() {
        guard let groupname = groupnameTextField.text else { return }
        let bio = bioTextField.text
        
        groupnameTextField.isUserInteractionEnabled = false
        bioTextField.isUserInteractionEnabled = false
        
        createGroupButton.isEnabled = false
        createGroupButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        
        if groupname.range(of: #"^[a-zA-Z0-9_-]*$"#, options: .regularExpression) == nil {
            let alert = UIAlertController(title: "Username invalid", message: "Please enter a groupname with no symbols or spaces (underscore is okay)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            self.resetInputFields()
            return
        }

        Database.database().createGroup(groupname: groupname, bio: bio ?? "", image: profileImage, isPrivate: isPrivate) { (err) in
            if err != nil {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                guard let error = err else { self.resetInputFields(); return }
                if error.localizedDescription == "Groupname Taken" {
                    let alert = UIAlertController(title: "Group name Taken", message: "Please select a different group name", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
                self.resetInputFields()
                return
            }
            self.dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(name: NSNotification.Name("createdGroup"), object: nil)
        }
    }
    
    @objc private func handleSelectedPublic() {
        isPrivate = false
        publicGroupButton.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        publicGroupButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        publicGroupButton.layer.borderWidth = 1
        privateGroupButton.setTitleColor(UIColor.gray, for: .normal)
        privateGroupButton.layer.borderColor = UIColor.gray.cgColor
        privateGroupButton.layer.borderWidth = 0
    }
    
    @objc private func handleSelectedPrivate() {
        isPrivate = true
        privateGroupButton.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        privateGroupButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        privateGroupButton.layer.borderWidth = 1
        publicGroupButton.setTitleColor(UIColor.gray, for: .normal)
        publicGroupButton.layer.borderColor = UIColor.gray.cgColor
        publicGroupButton.layer.borderWidth = 0
    }
}

//MARK: UIImagePickerControllerDelegate

extension CreateGroupController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            plusPhotoButton.setImage(editedImage.withRenderingMode(.alwaysOriginal), for: .normal)
            profileImage = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            plusPhotoButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
            profileImage = originalImage
        }
        plusPhotoButton.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        plusPhotoButton.layer.borderWidth = 0.5
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - UITextFieldDelegate

extension CreateGroupController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
