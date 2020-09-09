//
//  ViewController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 3/16/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FirebaseAuth
import FirebaseDatabase

class SignUpController: UIViewController, UINavigationControllerDelegate {

    private let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "plus_photo"), for: .normal)
        button.layer.masksToBounds = true
        button.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(handlePlusPhoto), for: .touchUpInside)
        return button
    }()
    
    private lazy var emailTextField: UITextField = {
        let tf = UITextField()
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.keyboardType = .emailAddress
        tf.placeholder = "Email"
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private lazy var usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private lazy var nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Name"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private lazy var bioTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Bio (optional)"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    private let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Already have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        attributedTitle.append(NSAttributedString(string: "Sign In", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
            ]))
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(handleAlreadyHaveAccount), for: .touchUpInside)
        return button
    }()
    
    private lazy var TermsOfUseLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "By continuing, you agree to GroupRoot's ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11)])
        attributedText.append(NSAttributedString(string: "Terms of Use", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 11), NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]))
        attributedText.append(NSMutableAttributedString(string: ",", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11)]))
        label.attributedText = attributedText
        
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(send_to_terms))
        label.addGestureRecognizer(gestureRecognizer)
        
        return label
    }()
    
    private lazy var PrivacyPolicyLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "confirm that you have read GroupRoot's ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11)])
        attributedText.append(NSAttributedString(string: "Privacy Policy", attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 11), NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]))
        attributedText.append(NSMutableAttributedString(string: ",", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11)]))
        label.attributedText = attributedText
        
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(send_to_policy))
        label.addGestureRecognizer(gestureRecognizer)

        return label
    }()
    
    private let Over16Label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "and are 16 years or older.", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11)])
        label.attributedText = attributedText
        return label
    }()
    
    private var profileImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        view.backgroundColor = .white
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnView)))
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.anchor(left: view.safeAreaLayoutGuide.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: 50)
        
        view.addSubview(Over16Label)
        Over16Label.anchor(left: view.safeAreaLayoutGuide.leftAnchor, bottom: alreadyHaveAccountButton.topAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: 16)
        
        view.addSubview(PrivacyPolicyLabel)
        PrivacyPolicyLabel.anchor(left: view.safeAreaLayoutGuide.leftAnchor, bottom: Over16Label.topAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: 16)
        
        view.addSubview(TermsOfUseLabel)
        TermsOfUseLabel.anchor(left: view.safeAreaLayoutGuide.leftAnchor, bottom: PrivacyPolicyLabel.topAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: 16)
        
        view.addSubview(plusPhotoButton)
        plusPhotoButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 60, width: 140, height: 140)
        plusPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        plusPhotoButton.layer.cornerRadius = 140 / 2
        
        setupInputFields()
    }
    
    private func setupInputFields() {
//        let stackView = UIStackView(arrangedSubviews: [emailTextField, usernameTextField, nameTextField, passwordTextField, invitationTextField, signUpButton])
        let stackView = UIStackView(arrangedSubviews: [emailTextField, usernameTextField, nameTextField, bioTextField, nextButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10
        
        view.addSubview(stackView)
        stackView.anchor(top: plusPhotoButton.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 40, paddingLeft: 40, paddingRight: 40, height: 262)
    }
    
    private func resetInputFields() {
//        emailTextField.text = ""
//        usernameTextField.text = ""
//        nameTextField.text = ""
        
        emailTextField.isUserInteractionEnabled = true
        usernameTextField.isUserInteractionEnabled = true
        nameTextField.isUserInteractionEnabled = true
        bioTextField.isUserInteractionEnabled = true
        
        nextButton.isEnabled = false
        nextButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
    }
    
    @objc private func handleTapOnView(_ sender: UITextField) {
        usernameTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        bioTextField.resignFirstResponder()
    }
    
    @objc private func handlePlusPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func handleTextInputChange() {
        let isFormValid = emailTextField.text?.isEmpty == false && usernameTextField.text?.isEmpty == false && nameTextField.text?.isEmpty == false
        if isFormValid {
            nextButton.isEnabled = true
            nextButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        } else {
            nextButton.isEnabled = false
            nextButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        }
    }
    
    @objc private func handleAlreadyHaveAccount() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleNext() {
        guard let email = emailTextField.text else { return }
        guard let username = usernameTextField.text else { return }
        guard let name = nameTextField.text else { return }
        guard let bio = bioTextField.text else { return }
        
//     username regex:   ^[a-zA-Z0-9_-]*$   must match
        if username.range(of: #"^[a-zA-Z0-9_-]*$"#, options: .regularExpression) == nil {
            let alert = UIAlertController(title: "Username invalid", message: "Please enter a username with no symbols (underscore is okay)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            usernameTextField.text = ""
            self.resetInputFields()
            return
        }
        
        Database.database().usernameExists(username: username, completion: { (exists) in
            if exists{
                let alert = UIAlertController(title: "Username Taken", message: "Please select a different username.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
                self.usernameTextField.text = ""
                self.resetInputFields()
                return
            }
            else {
                // check if email already exists
                Auth.auth().fetchSignInMethods(forEmail: email, completion: {
                    (providers, error) in
                    if error != nil || providers == nil {
                        // push SignUpTwoController
                        let signUpTwoController = SignUpTwoController()
                        signUpTwoController.email = email
                        signUpTwoController.username = username
                        signUpTwoController.name = name
                        signUpTwoController.profileImage = self.profileImage
                        signUpTwoController.bio = bio
                        self.navigationController?.pushViewController(signUpTwoController, animated: true)
//                        let signUpPhoneController = SignUpPhoneController()
//                        self.navigationController?.pushViewController(signUpPhoneController, animated: true)
                    }
                    else {
                        // email already exists, send to login
                        let alert = UIAlertController(title: "", message: "Email already exists. Please log in", preferredStyle: .alert)
                        self.present(alert, animated: true, completion: nil)
                        let when = DispatchTime.now() + 3
                        DispatchQueue.main.asyncAfter(deadline: when){
                            alert.dismiss(animated: true, completion: nil)
                            self.handleAlreadyHaveAccount()
                        }
                    }
                })
            }
        })
    }
    
    @objc func send_to_terms() {
        Database.database().fetch_link_to_terms(completion: { (link_to_terms) in
            guard let url = URL(string: link_to_terms) else { return }
            UIApplication.shared.open(url)
        })
    }
    
    @objc func send_to_policy() {
        Database.database().fetch_link_to_policy(completion: { (link_to_policy) in
            guard let url = URL(string: link_to_policy) else { return }
            UIApplication.shared.open(url)
        })
    }
}

//MARK: UIImagePickerControllerDelegate

extension SignUpController: UIImagePickerControllerDelegate {
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

extension SignUpController: UITextFieldDelegate {
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
