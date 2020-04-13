//
//  SignUpTwoController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 4/10/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SignUpTwoController: UIViewController, UINavigationControllerDelegate {
    
    var email: String?
    var username: String?
    var name: String?
    
    private lazy var backLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        label.text = "Back"
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goBack))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private lazy var passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private lazy var passwordMatchTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Confirm Password"
        tf.isSecureTextEntry = true
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private let invitationTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Group Invite Code"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
//        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
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
    
    private var profileImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        view.backgroundColor = .white
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnView)))
        
        view.addSubview(backLabel)
        backLabel.anchor(top: view.topAnchor, left: view.leftAnchor, paddingTop: 35, paddingLeft: 25)
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.anchor(left: view.safeAreaLayoutGuide.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: 50)
        
        setupInputFields()
    }
    
    private func setupInputFields() {
        let stackView = UIStackView(arrangedSubviews: [passwordTextField, passwordMatchTextField, invitationTextField, signUpButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10
        
        view.addSubview(stackView)
        stackView.anchor(top: view.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 200, paddingLeft: 40, paddingRight: 40, height: 210)
    }
    
    private func resetInputFields() {
//        passwordTextField.text = ""
//        passwordMatchTextField.text = ""
//        invitationTextField.text = ""
        
        passwordTextField.isUserInteractionEnabled = true
        invitationTextField.isUserInteractionEnabled = true
        
        signUpButton.isEnabled = false
        signUpButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
    }
    
    @objc private func handleTapOnView(_ sender: UITextField) {
        passwordTextField.resignFirstResponder()
        passwordMatchTextField.resignFirstResponder()
        invitationTextField.resignFirstResponder()
    }
    
    @objc private func handleTextInputChange() {
        let isFormValid = passwordTextField.text?.isEmpty == false && passwordMatchTextField.text?.isEmpty == false && invitationTextField.text?.isEmpty == false
        if isFormValid {
            signUpButton.isEnabled = true
            signUpButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        } else {
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        }
    }
    
    @objc private func handleAlreadyHaveAccount() {
        self.navigationController?.pushViewController(LoginController(), animated: true)
    }
    
    @objc private func goBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleSignUp() {
        guard let password = passwordTextField.text else { return }
        guard let passwordMatch = passwordMatchTextField.text else { return }
        guard let code = invitationTextField.text else { return }
        guard let email = email else { return }
        guard let username = username else { return }
        guard let name = name else { return }
        
        if password != passwordMatch {
            self.passwordTextField.text = ""
            self.passwordMatchTextField.text = ""
            let alert = UIAlertController(title: "", message: "Passwords don't match", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when){
                alert.dismiss(animated: true, completion: nil)
            }
            return
        }
        
        passwordTextField.isUserInteractionEnabled = false
        invitationTextField.isUserInteractionEnabled = false
        
        signUpButton.isEnabled = false
        signUpButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        
        Database.database().fetchInviteCodeGroupId(code: code, completion: { (groupId) in
            if groupId != "" || code == "qwerty123" {
                Auth.auth().createUser(withEmail: email, username: username, name: name, password: password, image: self.profileImage) { (err) in
                    if err != nil {
                        
                    }
                    
                    if code == "qwerty123"{
                        guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }
                        mainTabBarController.setupViewControllers()
                        mainTabBarController.selectedIndex = 0
                        self.dismiss(animated: true, completion: nil)
                        return
                    }
                    
                    // get the groupId that the code belongs to
                    // send a request to join the group
                    // auto follow/subscribe to the group so it appears in the feed
                    Database.database().joinGroup(groupId: groupId) { (err) in
                        if err != nil {
                            return
                        }
                        // send the notification each each user in the group
                        Database.database().groupExists(groupId: groupId, completion: { (exists) in
                            if exists {
                                Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                                    Database.database().fetchGroupMembers(groupId: groupId, completion: { (users) in
                                        users.forEach({ (user) in
                                            Database.database().createNotification(to: user, notificationType: NotificationType.groupJoinRequest, group: group) { (err) in
                                                if err != nil {
                                                    return
                                                }
                                            }
                                        })
                                    }) { (_) in}
                                })
                            }
                            else {
                                return
                            }
                        })
                        
                        Database.database().subscribeToGroup(groupId: groupId) { (err) in
                            if err != nil {
                                return
                            }
                            print("subscribed")
                            NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
                            
                            guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }
                            mainTabBarController.setupViewControllers()
                            mainTabBarController.selectedIndex = 0
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
            else {
                let alert = UIAlertController(title: "Invalid Invitation", message: "Your invitation code is no longer valid", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
                self.resetInputFields()
                self.invitationTextField.text = ""
            }
            
        })
    }
}


//MARK: - UITextFieldDelegate

extension SignUpTwoController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
