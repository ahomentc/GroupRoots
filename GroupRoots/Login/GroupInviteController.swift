//
//  GroupInviteController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 10/8/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class GroupInviteController: UIViewController, UINavigationControllerDelegate {

    var isInvited = false
    var group: Group?
    var userInvitedBy: User?
    
    var number: String? {
        didSet {
            guard let number = number else { return }
            // check if number is invited
            Database.database().isNumberInvitedToAGroup(number: number, completion: { (isInvited) in
                self.isInvited = isInvited
                if isInvited {
                    Database.database().fetchFirstGroupNumberIsInvitedTo(number: number, completion: { (group) in
                        Database.database().fetchInvitedBy(number: number, groupId: group.groupId, completion: { (invitedByUser) in
                            self.group = group
                            self.userInvitedBy = invitedByUser
                            self.setupGroupInvite()
                            Database.database().removeNumberFromInvited(number: number) { (err) in }
                        })
                    })
                }
                else {
                    self.setupGroupNoInvite()
                }
                
            }) { (err) in
                return
            }
        }
    }
    
    private lazy var skipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        label.text = "Skip"
        label.isHidden = true
        label.isUserInteractionEnabled = true
//        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goBack))
//        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private lazy var doneLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        label.text = "Skip"
        label.isHidden = true
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doneSelected))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private let notInvitedLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.4, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Have a group invite code?", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        label.attributedText = attributedText
        return label
    }()
    
    private let invitedLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.2, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Group Membership\n\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        attributedText.append(NSMutableAttributedString(string: "You've been added as a\nmember of a group.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        label.attributedText = attributedText
        return label
    }()
    
    private let tipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.2, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
//        label.isHidden = true
        label.textAlignment = .center
//        let attributedText = NSMutableAttributedString(string: "Tip\n\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
//        attributedText.append(NSMutableAttributedString(string: "If a group is public, followers of the group\nmembers will have the group appear\nin their feeds.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)]))
        let attributedText = NSMutableAttributedString(string: "Tip\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
        attributedText.append(NSMutableAttributedString(string: "Group profiles can be public or private.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)]))
        label.attributedText = attributedText
        return label
    }()
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = CustomImageView.imageWithColor(color: .white)
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 1
        iv.backgroundColor = .white
        iv.layer.zPosition = 10
        return iv
    }()
    
    private let userOneImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 1
        return iv
    }()
    
    private let userTwoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 1
        return iv
    }()
    
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
        button.setTitle("Join", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleSubmitCode), for: .touchUpInside)
        button.isEnabled = true
        return button
    }()
    
    private let noCodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Nope", for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        button.addTarget(self, action: #selector(doneSelected), for: .touchUpInside)
        button.isEnabled = true
        return button
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(doneSelected), for: .touchUpInside)
        button.isEnabled = true
        button.isHidden = true
        return button
    }()
    
    private var profileImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
//        navigationItem.title = "Group Invite Code"
//        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
//        navigationController?.navigationBar.titleTextAttributes = textAttributes
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Skip", style: .plain, target: self, action: #selector(doneSelected))
//        navigationItem.leftBarButtonItem?.tintColor = .black
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneSelected))
//        navigationItem.rightBarButtonItem?.tintColor = .black
        
        view.backgroundColor = .white
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnView)))
        
        view.addSubview(notInvitedLabel)
        notInvitedLabel.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: UIScreen.main.bounds.height/2 - 160, height: 70)
        
        view.addSubview(invitedLabel)
        invitedLabel.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: UIScreen.main.bounds.height/4, height: 110)
        
        tipLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 120, width: UIScreen.main.bounds.width, height: 100)
        self.view.insertSubview(tipLabel, at: 4)
        
        let screen_width = UIScreen.main.bounds.width
        let center = screen_width/2 - 35
        self.view.addSubview(profileImageView)
        profileImageView.anchor(top: invitedLabel.bottomAnchor, left: self.view.leftAnchor, paddingTop: 8, paddingLeft: center-5, width: 60, height: 60)
        profileImageView.layer.cornerRadius = 60/2
        profileImageView.isHidden = true
        profileImageView.image = UIImage()
        
        self.view.addSubview(userOneImageView)
        userOneImageView.anchor(top: invitedLabel.bottomAnchor, left: self.view.leftAnchor, paddingTop: 4, paddingLeft: center+10, width: 58, height: 58)
//        userOneImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userOneImageView.layer.cornerRadius = 58/2
        userOneImageView.isHidden = true
        userOneImageView.image = UIImage()
        
        self.view.addSubview(userTwoImageView)
        userTwoImageView.anchor(top: invitedLabel.bottomAnchor, left: self.view.leftAnchor, paddingTop: 8, paddingLeft: center-5, width: 60, height: 60)
//        userTwoImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userTwoImageView.layer.cornerRadius = 60/2
        userTwoImageView.isHidden = true
        userTwoImageView.image = UIImage()
        
//        view.addSubview(doneButton)
//        doneButton.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: UIScreen.main.bounds.height/4, height: 110)
        
//        doneButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 - 90, width: 300, height: 50)
//        doneButton.layer.cornerRadius = 14
//        self.view.insertSubview(doneButton, at: 4)
        
        self.view.addSubview(doneButton)
        doneButton.anchor(top: userTwoImageView.bottomAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 30, paddingLeft: (UIScreen.main.bounds.width - 300)/2, paddingRight: (UIScreen.main.bounds.width - 300)/2, width: 300, height: 50)
        doneButton.layer.cornerRadius = 14
    }
    
    @objc private func doneSelected(){
        UIView.animate(withDuration: 1) {
            self.doneButton.alpha = 0
            self.userTwoImageView.alpha = 0
            self.userOneImageView.alpha = 0
            self.profileImageView.alpha = 0
            self.tipLabel.alpha = 0
            self.skipLabel.alpha = 0
            self.invitedLabel.alpha = 0
            self.notInvitedLabel.alpha = 0
            self.doneLabel.alpha = 0
            self.codeButton.alpha = 0
            self.noCodeButton.alpha = 0
            self.inviteCodeTextField.alpha = 0
        }
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
            let introDescriptionController = IntroDescriptionController()
            introDescriptionController.isInvited = self.isInvited
            self.navigationController?.pushViewController(introDescriptionController, animated: false)
        }
    }
    
    func setupGroupInvite() {
        guard let group = group else { return }
        guard let userInvitedBy = userInvitedBy else { return }
        
        self.notInvitedLabel.isHidden = true
        self.invitedLabel.isHidden = false
        self.doneLabel.isHidden = true
        self.doneButton.isHidden = false
        if group.groupname != "" {
            let attributedText = NSMutableAttributedString(string: "Group Membership\n\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
            attributedText.append(NSMutableAttributedString(string: userInvitedBy.username + " added you as a member of\n\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
            attributedText.append(NSMutableAttributedString(string: group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘"), attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)]))
            self.invitedLabel.attributedText = attributedText
        }
        self.loadGroupMembersIcon(group: group)
        
        addUserToSchool(group: group)
    }
    
    func addUserToSchool(group: Group) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().fetchSchoolOfGroup(group: group.groupId, completion: { (school) in
            if school != "" {
                let formatted_school = school.replacingOccurrences(of: " ", with: "_-a-_")
                
                if let school_json = try? JSONEncoder().encode(formatted_school) {
                    UserDefaults.standard.set(school_json, forKey: "selectedSchool")
                }
                
                Database.database().addUserToSchool(withUID: currentLoggedInUserId, selectedSchool: formatted_school) { (err) in
                    if err != nil {
                       return
                    }
                    Database.database().addSchoolToUser(withUID: currentLoggedInUserId, selectedSchool: formatted_school) { (err) in }
                }
            }
        }) { (_) in}
    }
    
    func setupGroupNoInvite(){
        let stackView = UIStackView(arrangedSubviews: [self.inviteCodeTextField, self.codeButton, self.noCodeButton])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 10
        
        self.view.addSubview(stackView)
        stackView.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: UIScreen.main.bounds.height/2 - 70, paddingLeft: 40, paddingRight: 40, height: 165)
        
        // displays elements to add a group invite code
        self.notInvitedLabel.isHidden = false
        self.invitedLabel.isHidden = true
        self.doneLabel.isHidden = false
        self.profileImageView.isHidden = true
        self.userOneImageView.isHidden = true
        self.userTwoImageView.isHidden = true
        self.doneButton.isHidden = true
    }
    
    private func loadGroupMembersIcon(group: Group?){
        guard let group = group else { return }
        Database.database().fetchFirstNGroupMembers(groupId: group.groupId, n: 3, completion: { (first_n_users) in
            if let groupProfileImageUrl = group.groupProfileImageUrl {
                self.profileImageView.loadImage(urlString: groupProfileImageUrl)
                self.profileImageView.isHidden = false
                self.userOneImageView.isHidden = true
                self.userTwoImageView.isHidden = true
            } else {
                self.profileImageView.isHidden = true
                self.userOneImageView.isHidden = false
                self.userTwoImageView.isHidden = true
                
                if first_n_users.count > 0 {
                    if let userOneImageUrl = first_n_users[0].profileImageUrl {
                        self.userOneImageView.loadImage(urlString: userOneImageUrl)
                    } else {
                        self.userOneImageView.image = #imageLiteral(resourceName: "user")
                        self.userOneImageView.backgroundColor = .white
                    }
                }
                
                // set the second user (only if it exists)
                if first_n_users.count > 1 {
                    self.userTwoImageView.isHidden = false
                    if let userTwoImageUrl = first_n_users[1].profileImageUrl {
                        self.userTwoImageView.loadImage(urlString: userTwoImageUrl)
                        self.userTwoImageView.layer.borderWidth = 2
                    } else {
                        self.userTwoImageView.image = #imageLiteral(resourceName: "user")
                        self.userTwoImageView.backgroundColor = .white
                        self.userTwoImageView.layer.borderWidth = 2
                    }
                }
            }
        }) { (_) in }
    }
    
    private func resetInputFields() {
        inviteCodeTextField.text = ""
        inviteCodeTextField.isUserInteractionEnabled = true
        codeButton.isEnabled = true
        noCodeButton.isEnabled = true
    }
    
    @objc private func handleTapOnView(_ sender: UITextField) {
        inviteCodeTextField.resignFirstResponder()
    }
    
    @objc private func handleSubmitCode() {
        let code = inviteCodeTextField.text
        inviteCodeTextField.isUserInteractionEnabled = false
        codeButton.isEnabled = false
        noCodeButton.isEnabled = false
        
        if code == "" {
            if let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController {
                mainTabBarController.setupViewControllers()
                mainTabBarController.selectedIndex = 0
                self.dismiss(animated: true, completion: nil)
                return
            }
        }

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
                                Database.database().fetchGroupMembers(groupId: groupId, completion: { (users) in
                                    users.forEach({ (user) in
                                        Database.database().createNotification(to: user, notificationType: NotificationType.groupJoinRequest, group: group) { (err) in
                                        }
                                    })
                                }) { (_) in}
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
                            if let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController {
                                mainTabBarController.setupViewControllers()
                                mainTabBarController.selectedIndex = 0
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
            else {
                if let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController {
                    mainTabBarController.setupViewControllers()
                    mainTabBarController.selectedIndex = 0
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
}

//MARK: - UITextFieldDelegate

extension GroupInviteController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

