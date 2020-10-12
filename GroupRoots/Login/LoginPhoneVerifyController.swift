import UIKit
import Firebase
import GoogleSignIn
import FirebaseAuth
import FirebaseDatabase
import PhoneNumberKit

class LoginPhoneVerifyController: UIViewController, UINavigationControllerDelegate {
    
    var phone: String? {
        didSet {
            guard let phone = phone else { return }
            let attributedText = NSMutableAttributedString(string: "Enter a verification code\n\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
            attributedText.append(NSMutableAttributedString(string: "A verification code was just sent to " + phone, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
            phoneExpLabel.attributedText = attributedText
        }
    }
    
    var verificationID: String?
    
    private lazy var verificationTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Verification code"
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
        label.attributedText = NSMutableAttributedString(string: "Enter a verification code\n\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        return label
    }()
    
    private lazy var backLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        label.text = "back"
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goBack))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private let verifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Verify", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleVerify), for: .touchUpInside)
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
        
        view.addSubview(backLabel)
        backLabel.anchor(top: view.topAnchor, left: view.leftAnchor, paddingTop: 35, paddingLeft: 25)
        
        phoneExpLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: 20, width: 300, height: 300)
        self.view.insertSubview(phoneExpLabel, at: 4)
        
        setupInputFields()
    }
    
    private func setupInputFields() {
        let stackView = UIStackView(arrangedSubviews: [verificationTextField, verifyButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10
        
        view.addSubview(stackView)
        stackView.anchor(top: view.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 300, paddingLeft: 40, paddingRight: 40, height: 105)
    }
    
    private func resetInputFields() {
        verificationTextField.isUserInteractionEnabled = true
        
        verifyButton.isEnabled = false
        verifyButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
    }
    
    @objc private func handleTapOnView(_ sender: UITextField) {
        verificationTextField.resignFirstResponder()
    }
    
    @objc private func handleTextInputChange() {
        let isFormValid = verificationTextField.text?.isEmpty == false
        if isFormValid {
            verifyButton.isEnabled = true
            verifyButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        } else {
            verifyButton.isEnabled = false
            verifyButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        }
    }

    @objc private func goBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleVerify() {
        guard let verificationID = verificationID else { return }
        guard let verificationCode = verificationTextField.text else { return }
        guard let phone = phone else { return }
        
        verificationTextField.isUserInteractionEnabled = false
        
        verifyButton.isEnabled = false
        verifyButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        
        let credential = PhoneAuthProvider.provider().credential(
        withVerificationID: verificationID,
        verificationCode: verificationCode)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if error != nil {
                // error saying verification failed
                // could also fail because phone is already linked to other account
                let alert = UIAlertController(title: "Invalid Verification Code", message: "The verification code you have entered is not valid", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
                self.resetInputFields()
                self.verificationTextField.text = ""
                return
            }
            // check if number already belongs to a user in database
            // if not, then take to modified version of SignUpController, no password and no group invite code
            // add a label saying "connect phone to existing account?" -> login with email page that also connects phone number
            //      then, take to a page that does this:
            //      if number is invited to a group: You've been invited to join the group: ___. You'll be added as a member.
            //      if number isn't: You're not invited to a group yet. Do you have a group invite code?
            
            Database.database().doesNumberExist(number: phone, completion: { (exists) in
                if exists{
                    if let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController {
                        mainTabBarController.setupViewControllers()
                        mainTabBarController.selectedIndex = 0
                        self.dismiss(animated: true, completion: nil)
                    }
                }
                else {
                    let signUpAfterPhoneController = SignUpAfterPhoneController()
                    signUpAfterPhoneController.uid = Auth.auth().currentUser?.uid
                    signUpAfterPhoneController.number = phone
                    self.navigationController?.pushViewController(signUpAfterPhoneController, animated: true)
                }
            }) { (err) in return}
        }
    }
}


//MARK: - UITextFieldDelegate

extension LoginPhoneVerifyController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}



