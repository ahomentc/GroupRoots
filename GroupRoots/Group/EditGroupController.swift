//
//  EditGroupController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 4/5/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import YPImagePicker

class EditGroupController: UIViewController, UINavigationControllerDelegate {
    
    private var isPrivate: Bool = false
    private var originalIsPrivate: Bool = false
    
    var group: Group? {
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
    
    private lazy var groupnameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Group Name"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .none
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self
//        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private let groupnameLabel: UILabel = {
        let label = UILabel()
        label.text = "Group Name"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
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
        guard let group = group else { return }
        if let profileImageUrl = group.groupProfileImageUrl {
            profileImageButton.loadImage(urlString: profileImageUrl)
            originalImage = profileImageButton.image
        }
    }
    
    private func setupInputFields() {
        guard let group = group else { return }
        groupnameTextField.text = group.groupname
        
        if group.isPrivate! {
            originalIsPrivate = true
            self.handleSelectedPrivate()
        }
        else {
            originalIsPrivate = false
            self.handleSelectedPublic()
        }
        
        let separatorViewTop = UIView()
        separatorViewTop.backgroundColor = UIColor(white: 0, alpha: 0.1)
        view.addSubview(separatorViewTop)
        separatorViewTop.anchor(top: profileImageButton.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, height: 0.5)
        
        view.addSubview(groupnameLabel)
        groupnameLabel.anchor(top: separatorViewTop.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, paddingTop: 15, paddingLeft: 20)
        
        view.addSubview(groupnameTextField)
        groupnameTextField.anchor(top: separatorViewTop.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 10, paddingLeft: 130, height: 30)
        
        let separatorViewMid = UIView()
        separatorViewMid.backgroundColor = UIColor(white: 0, alpha: 0.1)
        view.addSubview(separatorViewMid)
        separatorViewMid.anchor(top: groupnameLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 15, height: 0.5)
        
        let radioButtonsStack = UIStackView(arrangedSubviews: [publicGroupButton, privateGroupButton])
        radioButtonsStack.distribution = .fillEqually
        radioButtonsStack.axis = .horizontal
        radioButtonsStack.spacing = 10
        view.addSubview(radioButtonsStack)
        radioButtonsStack.anchor(top: separatorViewMid.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 25, paddingLeft: 40, paddingRight: 40, height: 50)
    }
    
    private func resetInputFields() {
        groupnameTextField.text = ""
        groupnameTextField.isUserInteractionEnabled = true
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
        guard let group = group else { return }
        let groupname = groupnameTextField.text
        groupnameTextField.isUserInteractionEnabled = false
        let changedPrivacy = isPrivate != originalIsPrivate
                
//     username regex:   ^[a-zA-Z0-9_-]*$   must match
        if groupname != nil && groupname != "" {
            if groupname!.range(of: #"^[a-zA-Z0-9_-]*$"#, options: .regularExpression) == nil {
                let alert = UIAlertController(title: "Group Name invalid", message: "Please enter a group name with no symbols (underscore is okay)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
                self.resetInputFields()
                return
            }
        }
        
        // notifications sent from updateGroup too
        Database.database().updateGroup(groupId: group.groupId, changedPrivacy: changedPrivacy, groupname: groupname, isPrivate: isPrivate, image: self.profileImage) { (err) in
            if err != nil {
                guard let error = err else { self.resetInputFields(); return }
                if error.localizedDescription == "Groupname Taken" {
                    let alert = UIAlertController(title: "Group Name Taken", message: "Please select a different Group name.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            }
            self.resetInputFields()
            self.dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(name: NSNotification.Name("updatedGroup"), object: nil)
        }
    }
}

extension EditGroupController: UIImagePickerControllerDelegate {
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

extension EditGroupController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

