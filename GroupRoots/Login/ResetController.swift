import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class ResetController: UIViewController {
    
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
    
    private lazy var backLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        label.text = "Back"
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goBack))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleReset), for: .touchUpInside)
        button.isEnabled = false
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
        
        view.addSubview(backLabel)
        backLabel.anchor(top: view.topAnchor, left: view.leftAnchor, paddingTop: 35, paddingLeft: 25)
        
        setupInputFields()
    }
    
    private func setupInputFields() {
        let stackView = UIStackView(arrangedSubviews: [emailTextField, resetButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        view.addSubview(stackView)
        stackView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 250, paddingLeft: 40, paddingRight: 40, height: 100)
    }
    
    private func resetInputFields() {
        emailTextField.isUserInteractionEnabled = true
        
        resetButton.isEnabled = false
        resetButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
    }
    
    @objc private func handleReset() {
        guard let email = emailTextField.text else { return }
        
        emailTextField.isUserInteractionEnabled = false
        
        resetButton.isEnabled = false
        resetButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        
        Auth.auth().sendPasswordReset(withEmail: email) { err in
            if let err = err {
                print("Failed to reset with email:", err)
                let alert = UIAlertController(title: "", message: "Email not found", preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                let when = DispatchTime.now() + 2
                DispatchQueue.main.asyncAfter(deadline: when){
                    alert.dismiss(animated: true, completion: nil)
                    self.resetInputFields()
                }
                return
            }
            let alert = UIAlertController(title: "", message: "Check your email to reset your password", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            let when = DispatchTime.now() + 3
            DispatchQueue.main.asyncAfter(deadline: when){
                alert.dismiss(animated: true, completion: nil)
                self.navigationController?.popViewController(animated: true)
            }
            
        }
    }
    
    @objc private func goBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleTapOnView() {
        emailTextField.resignFirstResponder()
    }
    
    @objc private func handleTextInputChange() {
        let isFormValid = emailTextField.text?.isEmpty == false
        if isFormValid {
            resetButton.isEnabled = true
            resetButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        } else {
            resetButton.isEnabled = false
            resetButton.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.7)
        }
    }
}

//MARK: - UITextFieldDelegate

extension ResetController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}




