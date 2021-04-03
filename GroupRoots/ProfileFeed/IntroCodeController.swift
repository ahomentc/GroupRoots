import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class IntroCodeController: UIViewController, UINavigationControllerDelegate {

    private lazy var inviteCodeTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Group Invite Code"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.delegate = self as UITextFieldDelegate
//        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private let codeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Submit", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleSubmitCode), for: .touchUpInside)
        button.isEnabled = true
        return button
    }()
    
    private var profileImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        navigationItem.title = "Group Invite Code"
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(doneSelected))
        navigationItem.leftBarButtonItem?.tintColor = .black
        
        view.backgroundColor = .white
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnView)))
        
        setupInputFields()
    }
    
    @objc private func doneSelected(){
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setupInputFields() {
        let stackView = UIStackView(arrangedSubviews: [inviteCodeTextField, codeButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 25
        
        view.addSubview(stackView)
        stackView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 50, paddingLeft: 40, paddingRight: 40, height: 110)
    }
    
    private func resetInputFields() {
        inviteCodeTextField.text = ""
        inviteCodeTextField.isUserInteractionEnabled = true
        codeButton.isEnabled = true
    }
    
    @objc private func handleTapOnView(_ sender: UITextField) {
        inviteCodeTextField.resignFirstResponder()
    }
    
    @objc private func handleSubmitCode() {
        let code = inviteCodeTextField.text
        inviteCodeTextField.isUserInteractionEnabled = false
        codeButton.isEnabled = false

        var groupId = ""
        let sync = DispatchGroup()
        sync.enter()
        if code != "" {
            Database.database().fetchInviteCodeGroupId(code: code ?? "", completion: { (group_id) in
                groupId = group_id
                sync.leave()
            })
        }
        else {
            sync.leave()
        }
        
        sync.notify(queue: .main) {
            if code != "" && groupId == "" {
                let alert = UIAlertController(title: "Invalid Invitation", message: "The invitation code is no longer valid", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
                self.resetInputFields()
                self.inviteCodeTextField.text = ""
                return
            }
            if groupId != "" {
                Database.database().joinGroup(groupId: groupId) { (err) in
                    // send the notification each each user in the group
                    Database.database().groupExists(groupId: groupId, completion: { (exists) in
                        if exists {
                            Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                                Database.database().numberOfMembersForGroup(groupId: groupId) { (membersCount) in
                                    if membersCount < 20 {
                                        Database.database().fetchGroupMembers(groupId: groupId, completion: { (users) in
                                            users.forEach({ (user) in
                                                Database.database().createNotification(to: user, notificationType: NotificationType.groupJoinRequest, group: group) { (err) in
                                                }
                                            })
                                        }) { (_) in}
                                    }
                                }
                            })
                        }
                    })
                    
                    Database.database().subscribeToGroup(groupId: groupId) { (err) in
                        NotificationCenter.default.post(name: NSNotification.Name("updateFollowers"), object: nil)
                        NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                        NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                        
                        let alert = UIAlertController(title: "Membership Requested", message: "Someone in the group needs to approve your membership", preferredStyle: .alert)
                        self.present(alert, animated: true, completion: nil)
                        let when = DispatchTime.now() + 5
                        DispatchQueue.main.asyncAfter(deadline: when){
                            alert.dismiss(animated: true, completion: nil)
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
            else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
}

//MARK: - UITextFieldDelegate

extension IntroCodeController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
