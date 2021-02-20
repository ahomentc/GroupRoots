//
//  IntroGroupStepController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/17/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

// instead of saying create a group, say "create your group's profile"

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import SearchTextField
import FirebaseStorage
import NVActivityIndicatorView


class IntroGroupStepController: UIViewController, UINavigationControllerDelegate {
    
    var delegateForInvite: InviteToGroupWhenCreateControllerDelegate?
    
    private var isPrivate: Bool = false
    private var schoolSelected: Bool = false
    
    var preSetSchool: String? {
        didSet {
            guard let presetSchool = preSetSchool else { return }
            self.linkSchools.text = presetSchool.replacingOccurrences(of: "_-a-_", with: " ")
            self.schoolSelected = true
        }
    }
    
    private let schoolLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: "Link to a school (optional)", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)])
        label.textColor = .gray
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    let searchSchoolBottomBorder: UIView = {
        let view = UIView()
        return view
    }()
    
    private let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "plus_photo"), for: .normal)
        button.layer.masksToBounds = true
        button.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.imageView?.contentMode = .scaleAspectFill
        button.addTarget(self, action: #selector(handlePlusPhoto), for: .touchUpInside)
        return button
    }()
    
    private lazy var groupnameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Group Name (optional)"
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.backgroundColor = UIColor(white: 0, alpha: 0)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.delegate = self as UITextFieldDelegate
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
        tf.delegate = self as UITextFieldDelegate
        tf.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return tf
    }()
    
    private let createGroupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleCreateGroup), for: .touchUpInside)
        button.isEnabled = true
        return button
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
    
    let groupProfileTitle: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 5
        let attributedText = NSMutableAttributedString(string: "Create a group profile", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    var linkSchools = SearchTextField()
    
    private var profileImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        navigationItem.title = "Create Group"
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(doneSelected))
        navigationItem.leftBarButtonItem?.tintColor = .black
        
        view.backgroundColor = .white
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnView)))
        
        self.view.insertSubview(groupProfileTitle, at: 5)
        groupProfileTitle.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 45, paddingLeft: 20, paddingRight: 20)
        
        view.addSubview(plusPhotoButton)
        plusPhotoButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 80, width: 140, height: 140)
        plusPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        plusPhotoButton.layer.cornerRadius = 140 / 2
        
        setupInputFields()
    }
    
    @objc private func doneSelected(){
        self.dismiss(animated: true, completion: nil)
    }
    
    struct Response: Codable { // or Decodable
      let foo: String
    }
    
    private func setupInputFields() {
        
        let storageRef = Storage.storage().reference()
        let highSchoolsRef = storageRef.child("high_schools.json")
        highSchoolsRef.downloadURL { url, error in
            if let error = error {
                print(error)
            } else {
                let hs_url = url!.absoluteString
                if let url = URL(string: hs_url) {
                   URLSession.shared.dataTask(with: url) { data, response, error in
                      if let data = data {
                          do {
                            let json_string = String(data: data, encoding: .utf8)
                            guard let data = json_string?.data(using: String.Encoding.utf8 ),
                              let high_schools = try JSONSerialization.jsonObject(with: data, options: []) as? [String] else {
                                fatalError()
                                }
                            DispatchQueue.main.async {
                                self.linkSchools.filterStrings(high_schools)
                            }
                          } catch let error {
                             print(error)
                          }
                       }
                   }.resume()
                }
            }
        }
    
        linkSchools.borderStyle = .none
        linkSchools.theme.cellHeight = 50
        linkSchools.comparisonOptions = [.caseInsensitive]
        linkSchools.placeholder = "Search"
        linkSchools.backgroundColor = .clear
        linkSchools.startVisible = true
        linkSchools.autocorrectionType = .no
        linkSchools.textAlignment = .left
        linkSchools.theme.bgColor = .white
        linkSchools.theme.font = UIFont.systemFont(ofSize: 14)
        linkSchools.itemSelectionHandler = { filteredResults, itemPosition in
            // Just in case you need the item position
            let item = filteredResults[itemPosition]
            print("Item at position \(itemPosition): \(item.title)")

            // Do whatever you want with the picked item
            self.linkSchools.text = item.title
            self.schoolSelected = true
            self.linkSchools.resignFirstResponder()
        }
        
        view.addSubview(schoolLabel)
        schoolLabel.anchor(top: plusPhotoButton.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, paddingTop: 40, paddingLeft: 40)
        
        view.addSubview(linkSchools)
        linkSchools.anchor(top: schoolLabel.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: -5, paddingLeft: 40, paddingRight: 40, height: 50)
        
        searchSchoolBottomBorder.backgroundColor = UIColor(white: 0, alpha: 0.2)
        self.view.addSubview(searchSchoolBottomBorder)
        searchSchoolBottomBorder.anchor(top: linkSchools.bottomAnchor, left: linkSchools.leftAnchor, right: linkSchools.rightAnchor, height: 0.5)
        
        let radioButtonsStack = UIStackView(arrangedSubviews: [publicGroupButton, privateGroupButton])
        radioButtonsStack.distribution = .fillEqually
        radioButtonsStack.axis = .horizontal
        radioButtonsStack.spacing = 10
        
        let stackViewSchool = UIStackView(arrangedSubviews: [groupnameTextField, bioTextField, radioButtonsStack, createGroupButton])
        stackViewSchool.distribution = .fillEqually
        stackViewSchool.axis = .vertical
        stackViewSchool.spacing = 15
        stackViewSchool.isHidden = false
        
        view.addSubview(stackViewSchool)
        stackViewSchool.anchor(top: linkSchools.bottomAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, paddingTop: 25, paddingLeft: 40, paddingRight: 40, height: 230)
        
        radioButtonsStack.alpha = 0
        stackViewSchool.alpha = 0
        searchSchoolBottomBorder.alpha = 0
        linkSchools.alpha = 0
        schoolLabel.alpha = 0
        plusPhotoButton.alpha = 0
        groupProfileTitle.alpha = 0
        UIView.animate(withDuration: 0.5) {
            radioButtonsStack.alpha = 1
            stackViewSchool.alpha = 1
            self.searchSchoolBottomBorder.alpha = 1
            self.linkSchools.alpha = 1
            self.schoolLabel.alpha = 1
            self.plusPhotoButton.alpha = 1
            self.groupProfileTitle.alpha = 1
        }
    }
    
    private func resetInputFields() {
        groupnameTextField.text = ""
//        bioTextField.text = ""
        
        groupnameTextField.isUserInteractionEnabled = true
        bioTextField.isUserInteractionEnabled = true
        
        createGroupButton.isEnabled = true
//        createGroupButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
    }
    
    @objc private func handleTapOnView(_ sender: UITextField) {
        groupnameTextField.resignFirstResponder()
        bioTextField.resignFirstResponder()
        linkSchools.resignFirstResponder()
        
        if !schoolSelected {
            linkSchools.text = ""
        }
    }
    
    @objc private func handlePlusPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func handleTextInputChange() {
//        let isFormValid = groupnameTextField.text?.isEmpty == false && bioTextField.text?.isEmpty == false
//        if isFormValid {
//            createGroupButton.isEnabled = true
//            createGroupButton.backgroundColor = UIColor.mainBlue
//        } else {
//            createGroupButton.isEnabled = false
//            createGroupButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
//        }
    }
    
    @objc private func handleAlreadyHaveAccount() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleCreateGroup() {
        let groupname = groupnameTextField.text
        let bio = bioTextField.text
        var formatedGroupname = ""
        
        groupnameTextField.isUserInteractionEnabled = false
        bioTextField.isUserInteractionEnabled = false
        
        createGroupButton.isEnabled = false
//        createGroupButton.backgroundColor = UIColor.rgb(red: 149, green: 204, blue: 244)
        
        
        if groupname != nil && groupname != "" {
            formatedGroupname = groupname!.replacingOccurrences(of: " ", with: "_-a-_").replacingOccurrences(of: "‘", with: "_-b-_").replacingOccurrences(of: "'", with: "_-b-_").replacingOccurrences(of: "’", with: "_-b-_")
            if formatedGroupname.range(of: #"^[a-zA-Z0-9‘_ -]*$"#, options: .regularExpression) == nil {
                let alert = UIAlertController(title: "Group name invalid", message: "Please enter a Group name with no symbols", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
                self.resetInputFields()
                return
            }
        }

        let selectedSchool = linkSchools.text?.replacingOccurrences(of: " ", with: "_-a-_") ?? ""
        if groupname != nil && groupname != "" {
            Database.database().groupnameExists(groupname: groupname!, completion: { (exists) in
                if exists {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    let alert = UIAlertController(title: "Group name Taken", message: "Please select a different Group name", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                    self.resetInputFields()
                    return
                }
                else {
                    self.groupnameTextField.isUserInteractionEnabled = true
                    self.bioTextField.isUserInteractionEnabled = true
                    self.createGroupButton.isEnabled = true
                    
                    let inviteToGroupController = InviteToGroupFromIntroController()
                    inviteToGroupController.groupname = formatedGroupname
                    inviteToGroupController.bio = bio ?? ""
                    inviteToGroupController.image = self.profileImage
                    inviteToGroupController.isPrivate = self.isPrivate
                    inviteToGroupController.selectedSchool = selectedSchool
                    self.navigationController?.pushViewController(inviteToGroupController, animated: true)
                }
            })
        }
        else {
            self.groupnameTextField.isUserInteractionEnabled = true
            self.bioTextField.isUserInteractionEnabled = true
            self.createGroupButton.isEnabled = true
            
            let inviteToGroupController = InviteToGroupFromIntroController()
            inviteToGroupController.groupname = formatedGroupname
            inviteToGroupController.bio = bio ?? ""
            inviteToGroupController.image = self.profileImage
            inviteToGroupController.isPrivate = self.isPrivate
            inviteToGroupController.selectedSchool = selectedSchool
            self.navigationController?.pushViewController(inviteToGroupController, animated: true)
        }
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
}

//MARK: UIImagePickerControllerDelegate

extension IntroGroupStepController: UIImagePickerControllerDelegate {
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

extension IntroGroupStepController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}


