import UIKit
import Firebase

class LoginController: UIViewController {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    let logoContainerView: UILabel = {
        let label = UILabel()
        label.text = "GroupRoots"
        label.font = UIFont(name: "Avenir", size: 35)!
        label.textAlignment = .center
        return label
    }()
    
    private lazy var emailTextField: UITextField = {
        let tf = UITextField()
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.keyboardType = .emailAddress
        tf.placeholder = "Email"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
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
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
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
        let attributedTitle = NSAttributedString(string: "Forgot Password?", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        ])
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(handleShowReset), for: .touchUpInside)
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
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.anchor(left: view.safeAreaLayoutGuide.leftAnchor, bottom: resetButton.topAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: 50)
        
        setupInputFields()
    }
    
    private func setupInputFields() {
        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, loginButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        view.addSubview(stackView)
        stackView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 250, paddingLeft: 40, paddingRight: 40, height: 150)
    }
    
    private func resetInputFields() {
//        emailTextField.text = ""
        passwordTextField.text = ""
        emailTextField.isUserInteractionEnabled = true
        passwordTextField.isUserInteractionEnabled = true
        
        loginButton.isEnabled = false
        loginButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
    }
    
    @objc private func handleLogin() {
        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
        
        emailTextField.isUserInteractionEnabled = false
        passwordTextField.isUserInteractionEnabled = false
        
        loginButton.isEnabled = false
        loginButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, err) in
            if let err = err {
                print("Failed to sign in with email:", err)
                self.resetInputFields()
                return
            }
            
            if let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController {
                mainTabBarController.setupViewControllers()
                mainTabBarController.selectedIndex = 0
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    @objc private func handleTapOnView() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    @objc private func handleTextInputChange() {
        let isFormValid = emailTextField.text?.isEmpty == false && passwordTextField.text?.isEmpty == false
        if isFormValid {
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        } else {
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        }
    }
    
    @objc private func handleShowSignUp() {
        navigationController?.pushViewController(SignUpController(), animated: true)
    }
    
    @objc private func handleShowReset() {
        navigationController?.pushViewController(ResetController(), animated: true)
    }
}

//MARK: - UITextFieldDelegate

extension LoginController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}




