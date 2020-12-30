//
//  SignUpPhoneController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 9/5/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FirebaseAuth
import FirebaseDatabase
import PhoneNumberKit

class SignUpPhoneController: UIViewController, UINavigationControllerDelegate {
    
    var phone: String?
    
    private lazy var phoneTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Phone number"
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .roundedRect
        tf.keyboardType = .phonePad
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private let phoneExpLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.2, alpha: 1)
        label.numberOfLines = 0
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Enter a phone number\n\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        attributedText.append(NSMutableAttributedString(string: "Log in faster\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        attributedText.append(NSMutableAttributedString(string: "Auto join all groups you're invited to", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        label.attributedText = attributedText
        return label
    }()
    
    private lazy var skipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        label.text = "skip"
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(skip))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        view.backgroundColor = .white
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnView)))
        
        view.addSubview(skipLabel)
        skipLabel.anchor(top: view.topAnchor, left: view.leftAnchor, paddingTop: 45, paddingLeft: 25)
        
        phoneExpLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: 20, width: 300, height: 300)
        self.view.insertSubview(phoneExpLabel, at: 4)
        
        setupInputFields()
    }
    
    private func setupInputFields() {
        let stackView = UIStackView(arrangedSubviews: [phoneTextField, doneButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10
        
        view.addSubview(stackView)
        stackView.anchor(top: view.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 300, paddingLeft: 40, paddingRight: 40, height: 105)
    }

    private func resetInputFields() {
        phoneTextField.isUserInteractionEnabled = true
        
        doneButton.isEnabled = false
        doneButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
    }

    @objc private func handleTapOnView(_ sender: UITextField) {
        phoneTextField.resignFirstResponder()
    }

    @objc private func handleTextInputChange() {
        let isFormValid = phoneTextField.text?.isEmpty == false
        if isFormValid {
            doneButton.isEnabled = true
            doneButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        } else {
            doneButton.isEnabled = false
            doneButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        }
    }

    @objc private func skip() {
        guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { return }
        mainTabBarController.setupViewControllers()
        mainTabBarController.selectedIndex = 0
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleSignUp() {
        guard let number = phoneTextField.text else { return }
        
        phoneTextField.isUserInteractionEnabled = false
        
        doneButton.isEnabled = false
        doneButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        
        let phoneNumberKit = PhoneNumberKit()
        do {
            let phoneNumber = try phoneNumberKit.parse(number)
            let numberString = phoneNumberKit.format(phoneNumber, toType: .e164)
            
            // add phone number to user's account
            PhoneAuthProvider.provider().verifyPhoneNumber(numberString, uiDelegate: nil) { (verificationID, error) in
                if error != nil {
                    print(error!)
                    return
                }
                self.resetInputFields()
                let signUpPhoneVerifyController = SignUpPhoneVerifyController()
                signUpPhoneVerifyController.phone = numberString
                signUpPhoneVerifyController.verificationID = verificationID
                self.navigationController?.pushViewController(signUpPhoneVerifyController, animated: true)
            }
        }
        catch {
            let alert = UIAlertController(title: "Invalid Phone Number", message: "The phone number you have entered is not valid", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            self.resetInputFields()
            self.phoneTextField.text = ""
            return
        }
    }
}


//MARK: - UITextFieldDelegate

extension SignUpPhoneController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}


