import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import PhoneNumberKit

class LoginPhoneController: UIViewController {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    let logoContainerView: UILabel = {
        let label = UILabel()
        label.text = "GroupRoots"
        label.font = UIFont(name: "Avenir", size: 35)!
        label.textAlignment = .center
        return label
    }()
    
//    private lazy var phoneTextField: UITextField = {
//        let tf = UITextField()
//        tf.autocorrectionType = .no
//        tf.autocapitalizationType = .none
//        tf.keyboardType = .phonePad
//        tf.placeholder = "Phone number"
//        tf.backgroundColor = UIColor(white: 0, alpha: 0)
//        tf.borderStyle = .roundedRect
//        tf.font = UIFont.systemFont(ofSize: 16)
//        tf.delegate = self
//        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
//        return tf
//    }()
    
    private lazy var phoneTextField: PhoneNumberTextField = {
        let tf = PhoneNumberTextField()
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.keyboardType = .phonePad
        tf.placeholder = "Phone number"
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .none
        tf.font = UIFont.systemFont(ofSize: 27)
        
        tf.withPrefix = true
        tf.withExamplePlaceholder = true
        tf.withFlag = true
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 20
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    private let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
            ]))
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        return button
    }()
    
    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
//        let attributedTitle = NSAttributedString(string: "Login with email", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
//        ])
        let attributedTitle = NSAttributedString(string: "Use email instead", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        ])
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(handleShowEmailLogin), for: .touchUpInside)
        return button
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        navigationController?.isNavigationBarHidden = true
        view.backgroundColor = .white
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnView)))
        
        let logoImageView = UIImageView(image: #imageLiteral(resourceName: "icon_login_4"))
        view.addSubview(logoImageView)
        logoImageView.frame = CGRect(x: view.frame.width/2 - 115, y: 50, width: 230, height: 230)
        
        view.addSubview(resetButton)
        resetButton.anchor(left: view.safeAreaLayoutGuide.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingBottom: 10, height: 50)
        
//        view.addSubview(dontHaveAccountButton)
//        dontHaveAccountButton.anchor(left: view.safeAreaLayoutGuide.leftAnchor, bottom: resetButton.topAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: 50)
        
        setupInputFields()
    }
    
    private func setupInputFields() {
        let stackView = UIStackView(arrangedSubviews: [phoneTextField, nextButton])
        stackView.axis = .vertical
        stackView.spacing = 25
        stackView.distribution = .fillEqually
        view.addSubview(stackView)
        stackView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 250, paddingLeft: 40, paddingRight: 40, height: 115)
    }
    
    private func resetInputFields() {
//        emailTextField.text = ""
        phoneTextField.isUserInteractionEnabled = true
        
        nextButton.isEnabled = false
        nextButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
    }
    
    @objc private func handleLogin() {
        guard let number = phoneTextField.text else { return }
//        let groupInviteController = GroupInviteController()
//        groupInviteController.number = number
//        self.navigationController?.pushViewController(groupInviteController, animated: true)
//        return
        
        phoneTextField.isUserInteractionEnabled = false
        nextButton.isEnabled = false
        nextButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        
        let phoneNumberKit = PhoneNumberKit()
        do {
            let phoneNumber = try phoneNumberKit.parse(number)
            let numberString = phoneNumberKit.format(phoneNumber, toType: .e164)
            
            PhoneAuthProvider.provider().verifyPhoneNumber(numberString, uiDelegate: nil) { (verificationID, error) in
                if error != nil {
                    print(error!)
                    return
                }
                self.resetInputFields()
                let loginPhoneVerifyController = LoginPhoneVerifyController()
                loginPhoneVerifyController.phone = numberString
                loginPhoneVerifyController.verificationID = verificationID
                self.navigationController?.pushViewController(loginPhoneVerifyController, animated: true)
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
    
    @objc private func handleTapOnView() {
        phoneTextField.resignFirstResponder()
    }
    
    @objc private func handleTextInputChange() {
        let isFormValid = phoneTextField.text?.isEmpty == false
        if isFormValid {
            nextButton.isEnabled = true
            nextButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        } else {
            nextButton.isEnabled = false
            nextButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        }
    }
    
    @objc private func handleShowSignUp() {
        navigationController?.pushViewController(SignUpController(), animated: true)
    }
    
    @objc private func handleShowEmailLogin() {
        navigationController?.pushViewController(LoginController(), animated: true)
    }
}

//MARK: - UITextFieldDelegate

extension LoginPhoneController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}




