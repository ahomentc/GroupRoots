//
//  InviteToGroupFromIntroController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/19/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.


import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import ContactsUI
import PhoneNumberKit
import DGCollectionViewLeftAlignFlowLayout
import NVActivityIndicatorView


class InviteToGroupFromIntroController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, ContactCellDelegate, AddedUserCellDelegate {
    
    var group: Group?
    
    var groupname: String?
    var bio: String?
    var image: UIImage?
    var isPrivate: Bool?
    var selectedSchool: String?
    
    var isPromoActive = false
    var school = ""
        
    private lazy var contactsLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(white: 0.9, alpha: 1)
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.isHidden = false
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Select Contacts", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
        label.attributedText = attributedText
        return label
    }()
    
    private lazy var explainSelectContactLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        let attributedText = NSMutableAttributedString(string: "Add contacts without giving access\n\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
        attributedText.append(NSMutableAttributedString(string: "Only add contacts you select with\n\"Select Contacts\"\n\nGroupRoots will not have access to\nall of your contacts", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        label.attributedText = attributedText
        return label
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 5
        let attributedText = NSMutableAttributedString(string: "Add Group Members", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.textAlignment = .center
//        label.backgroundColor = .blue
        return label
    }()
    
//    private lazy var addLabel: UILabel = {
//        let label = UILabel()
//        label.textColor = UIColor.black
//        label.layer.zPosition = 5
//        let attributedText = NSMutableAttributedString(string: "Done", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)])
//        label.attributedText = attributedText
//        label.numberOfLines = 0
//        label.textAlignment = .center
//
//        label.isUserInteractionEnabled = true
//        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(inviteButtonClicked))
//        label.addGestureRecognizer(gestureRecognizer)
//
//        return label
//    }()
    
    private lazy var addLabel: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(UIColor.init(white: 0.1, alpha: 1), for: .normal)
        label.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        label.contentHorizontalAlignment = .center
        label.isUserInteractionEnabled = true
        label.setTitle("Done", for: .normal)
        label.addTarget(self, action: #selector(inviteButtonClicked), for: .touchUpInside)
        return label
    }()
    
//    private lazy var backLabel: UILabel = {
//        let label = UILabel()
//        label.textColor = UIColor.black
//        label.layer.zPosition = 5
//        let attributedText = NSMutableAttributedString(string: "Back", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 18)])
//        label.attributedText = attributedText
//        label.numberOfLines = 0
//        label.textAlignment = .center
//
//        label.isUserInteractionEnabled = true
//        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goBack))
//        label.addGestureRecognizer(gestureRecognizer)
//
//        return label
//    }()
    
    private lazy var backLabel: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(UIColor.init(white: 0.1, alpha: 1), for: .normal)
        label.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        label.contentHorizontalAlignment = .center
        label.isUserInteractionEnabled = true
        label.setTitle("Back", for: .normal)
        label.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        return label
    }()
    
    private let searchBar: UISearchBar = {
            let sb = UISearchBar()
            sb.placeholder = "Contact or Username"
            sb.autocorrectionType = .no
            sb.autocapitalizationType = .none
    //        sb.barTintColor = .gray
            sb.backgroundImage = UIImage()
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
            return sb
    }()
    
    let activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width/2 - 35, y: UIScreen.main.bounds.height/2 - 35, width: 70, height: 70), type: NVActivityIndicatorType.circleStrokeSpin)
    
    private var filteredUsers = [User]()
    private var filteredContacts = [Contact]()
    
    private var contactsToInvite = [Contact]()
    private var users = [User]()
    var allContacts = [Contact]()
    
    var addedCollectionView: UICollectionView!
    var searchCollectionView: UICollectionView!
    
    let phoneNumberKit = PhoneNumberKit()
    
    var hasClickedSelectContacts = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        self.view.backgroundColor = .white
        
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
        
        if let hasSelectedContactsRetrieved = UserDefaults.standard.object(forKey: "hasSelectedContacts") as? Data {
            guard let hasSelectedContacts = try? JSONDecoder().decode(Bool.self, from: hasSelectedContactsRetrieved) else {
                return
            }
            self.hasClickedSelectContacts = hasSelectedContacts
        }
        
        self.view.insertSubview(titleLabel, at: 5)
        titleLabel.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 44, paddingLeft: 70, paddingRight: 70)
        
        self.view.insertSubview(addLabel, at: 5)
        addLabel.anchor(top: view.topAnchor, right: view.rightAnchor, paddingTop: 37, paddingRight: 25)
        
//        self.view.insertSubview(backLabel, at: 5)
//        backLabel.anchor(top: view.topAnchor, left: view.leftAnchor, paddingTop: 37, paddingLeft: 25)

        let added_layout = DGCollectionViewLeftAlignFlowLayout()
        added_layout.scrollDirection = UICollectionView.ScrollDirection.vertical
//        added_layout.minimumLineSpacing = CGFloat(20)
        addedCollectionView = UICollectionView(frame: CGRect(x: 0, y: 90, width: UIScreen.main.bounds.width, height: 140), collectionViewLayout: added_layout)
        addedCollectionView.delegate = self
        addedCollectionView.dataSource = self
        addedCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        addedCollectionView.register(MiniAddedUserCell.self, forCellWithReuseIdentifier: MiniAddedUserCell.cellId)
        addedCollectionView.register(MiniContactCell.self, forCellWithReuseIdentifier: MiniContactCell.cellId)
        addedCollectionView.showsVerticalScrollIndicator = true
        addedCollectionView.isUserInteractionEnabled = true
        addedCollectionView.allowsSelection = true
        addedCollectionView.backgroundColor = .white
        addedCollectionView.alwaysBounceVertical = true
        addedCollectionView.keyboardDismissMode = .onDrag
        addedCollectionView.layer.borderColor = UIColor.init(white: 0.9, alpha: 1).cgColor
        addedCollectionView.layer.borderWidth = 1
        addedCollectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.view.insertSubview(addedCollectionView, at: 10)
        
        let contacts_layout = UICollectionViewFlowLayout()
        contacts_layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        contacts_layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 70)
        contacts_layout.minimumLineSpacing = CGFloat(0)
        
        searchCollectionView = UICollectionView(frame: CGRect(x: 0, y: 300, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height-300), collectionViewLayout: contacts_layout)
        searchCollectionView.delegate = self
        searchCollectionView.dataSource = self
        searchCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        searchCollectionView?.register(AddedUserCell.self, forCellWithReuseIdentifier: AddedUserCell.cellId)
        searchCollectionView?.register(ContactCell.self, forCellWithReuseIdentifier: ContactCell.cellId)
        searchCollectionView?.backgroundColor = .white
        searchCollectionView?.alwaysBounceVertical = true
        searchCollectionView?.keyboardDismissMode = .onDrag
        self.view.insertSubview(searchCollectionView, at: 5)
                
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            searchBar.frame = CGRect(x: 10, y: 243, width: UIScreen.main.bounds.width - 20, height: 44)
            self.view.insertSubview(searchBar, at: 4)
            searchBar.delegate = self
            searchBar.placeholder = "Username or Contact Name"
        }
        else {
            contactsLabel.frame = CGRect(x: 20 + (UIScreen.main.bounds.width - 40) / 2, y: 247, width: (UIScreen.main.bounds.width - 40) / 2, height: 37)
            contactsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleShowContacts)))
            self.view.insertSubview(contactsLabel, at: 4)

            searchBar.frame = CGRect(x: 10, y: 243, width: (UIScreen.main.bounds.width - 40) / 2, height: 44)
            self.view.insertSubview(searchBar, at: 4)
            searchBar.delegate = self
            searchBar.placeholder = "Username"
            
            explainSelectContactLabel.frame = CGRect(x: 20, y: 300, width: UIScreen.main.bounds.width - 40, height: 300)
            self.view.insertSubview(explainSelectContactLabel, at: 4)
        }
        
        self.importAllContacts()
        
        self.view.insertSubview(activityIndicatorView, at: 20)
        activityIndicatorView.color = .black
        activityIndicatorView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
    }
    
    
    @objc private func cancelSelected(){
        guard let group = group else { self.dismiss(animated: true, completion: nil); return }
        
        self.activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
        Database.database().deleteGroup(groupId: group.groupId, groupname: group.groupname, school: self.school) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func goBack() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc private func inviteButtonClicked(){
        guard let group = group else { return }
        if false && contactsToInvite.count == 0 && users.count == 0 { // skipping this for now
            let alert = UIAlertController(title: "", message: "Please add at least one member", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when){
              alert.dismiss(animated: true, completion: nil)
            }
        }
        else {
            let sync = DispatchGroup()
            var alertsToPresent: [UIAlertController] = []
            var skippedAddingFirstAlertToList = false
            
            for user in users {
                sync.enter()
                Database.database().createNotification(to: user, notificationType: NotificationType.groupJoinInvitation, group: group) { (err) in
                    if err != nil {
                        return
                    }
                    Database.database().addUserToGroupInvited(withUID: user.uid, groupId: group.groupId) { (err) in
                        if err != nil {
                            return
                        }
                        sync.leave()
                    }
                }
            }
            
            for contact in contactsToInvite {
                sync.enter()
                var new_contact = contact
                if contact.phone_numbers.count == 1 {
                    // create a new contact with the selected one
                    new_contact = Contact(contact: contact.contact, selected_number: contact.phone_numbers.first!)
                    Database.database().inviteContact(contact: new_contact, group: group) { (err) in
                        if err != nil {
                            return
                        }
                        sync.leave()
                    }
                }
                else {
                    let alert = UIAlertController(title: "Pick a number for " + contact.given_name + " " + contact.family_name, message: "", preferredStyle: .alert)
                    
                    let closure = { (index: Int) in
                        { (action: UIAlertAction!) -> Void in
                            let selected_phone = contact.phone_numbers[index]
                            new_contact = Contact(contact: contact.contact, selected_number: selected_phone)
                            Database.database().inviteContact(contact: new_contact, group: group) { (err) in
                                if err != nil {
                                    // should probably check this in some other way than comparing the description
                                    if err?.localizedDescription == "Phone number not valid" {
                                        let err_alert = UIAlertController(title: "Phone number not valid", message: "Please select a valid number for " + contact.given_name + " " + contact.family_name, preferredStyle: .alert)
                                        self.present(err_alert, animated: true, completion: nil)
                                        let when = DispatchTime.now() + 3
                                        DispatchQueue.main.asyncAfter(deadline: when){
                                            err_alert.dismiss(animated: true, completion: nil)
                                            return
                                        }
                                    }
                                }
                                else {
                                    if alertsToPresent.count > 0 {
                                        self.present(alertsToPresent[0], animated: true)
                                        alertsToPresent.removeFirst()
                                    }
                                    sync.leave()
                                }
                            }
                        }
                    }
                    
                    let cancel_closure = { () in
                       { (action: UIAlertAction!) -> Void in
                            self.present(alertsToPresent[0], animated: true)
                            alertsToPresent.removeFirst()
                            sync.leave()
                       }
                    }
                    
                    for (i, number) in contact.phone_numbers.enumerated() {
                        let action = UIAlertAction(title: number?.value.stringValue, style: .default, handler: closure(i))
                        alert.addAction(action)
                    }
                    
                    let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: cancel_closure())
                    alert.addAction(cancel)
                    if skippedAddingFirstAlertToList {
                        alertsToPresent.append(alert)
                    }
                    else {
                        skippedAddingFirstAlertToList = true
                    }
                    self.present(alert, animated: true)
                }
            }
            
            sync.notify(queue: .main) {
                if let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController {
                    mainTabBarController.setupViewControllers()
                    mainTabBarController.selectedIndex = 0
                    self.dismiss(animated: true, completion: nil)
                }
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("createdGroup"), object: nil)
                // also add a little message for when this closes saying something about invited
            }
        }
    }
    
    @objc private func handleShowContacts(){
        if hasClickedSelectContacts == false {
            if let hasSelectedContacts = try? JSONEncoder().encode(true) {
                UserDefaults.standard.set(hasSelectedContacts, forKey: "hasSelectedContacts")
            }
            self.hasClickedSelectContacts = true
            self.explainSelectContactLabel.isHidden = true
        }
        
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        contactPicker.predicateForEnablingContact = NSPredicate(
          format: "phoneNumbers.@count > 0")
        contactPicker.modalPresentationStyle = .fullScreen
        present(contactPicker, animated: true, completion: nil)
    }
    
    @objc private func handleShowSearch(){
        let searchUserForInvitationController = SearchUserForInvitationController(collectionViewLayout: UICollectionViewFlowLayout())
        searchUserForInvitationController.group = self.group
        searchUserForInvitationController.delegate = self
//        searchUserForInvitationController.modalPresentationStyle = .fullScreen
//        present(searchUserForInvitationController, animated: true, completion: nil)
        navigationController?.pushViewController(searchUserForInvitationController, animated: true)
    }
    
    func remove_contact(contact: Contact){
        contactsToInvite.removeAll(where: { $0.identifier == contact.identifier })
        self.addedCollectionView.collectionViewLayout.invalidateLayout()
        self.addedCollectionView.reloadData()
        self.addedCollectionView.layoutIfNeeded()
    }
    
    func remove_added_user(user: User) {
        users.removeAll(where: { $0.uid == user.uid })
        self.addedCollectionView.collectionViewLayout.invalidateLayout()
        self.addedCollectionView.reloadData()
        self.addedCollectionView.layoutIfNeeded()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.searchCollectionView {
            if indexPath.item < filteredContacts.count {
                let contact = filteredContacts[indexPath.item]
                if !contactsToInvite.contains(contact) {
                    self.contactsToInvite.append(contact)
                    self.addedCollectionView.collectionViewLayout.invalidateLayout()
                    self.addedCollectionView.reloadData()
                    self.addedCollectionView.layoutIfNeeded()
                    self.addedCollectionView.scrollToItem(at: IndexPath(item: self.contactsToInvite.count + self.users.count - 1, section: 0), at: [.centeredVertically, .centeredHorizontally], animated: false)
                }
            }
            else if indexPath.item < filteredContacts.count + filteredUsers.count { // filteredUsers
                let user = filteredUsers[indexPath.item - filteredContacts.count]
                if !users.contains(user) {
                    users.append(user)
                }
                self.addedCollectionView.collectionViewLayout.invalidateLayout()
                self.addedCollectionView.reloadData()
                self.addedCollectionView.layoutIfNeeded()
                self.addedCollectionView.scrollToItem(at: IndexPath(item: self.contactsToInvite.count + self.users.count - 1, section: 0), at: [.centeredVertically, .centeredHorizontally], animated: false)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.addedCollectionView {
            return contactsToInvite.count + users.count
        }
        else { // searchCollectionView
            return filteredContacts.count + filteredUsers.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.addedCollectionView {
            if indexPath.item < contactsToInvite.count {
                let contact = contactsToInvite[indexPath.item]
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MiniContactCell.cellId, for: indexPath) as! MiniContactCell
                cell.contact = contact
                cell.layer.cornerRadius = 10
                cell.delegate = self
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MiniAddedUserCell.cellId, for: indexPath) as! MiniAddedUserCell
                cell.user = users[indexPath.item - contactsToInvite.count]
                cell.group = group
                cell.layer.cornerRadius = 10
                cell.delegate = self
                return cell
            }
        }
        else {
            if indexPath.item < filteredContacts.count {
                let contact = filteredContacts[indexPath.item]
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContactCell.cellId, for: indexPath) as! ContactCell
                cell.contact = contact
                return cell
            }
            else { // filteredUsers
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddedUserCell.cellId, for: indexPath) as! AddedUserCell
                cell.user = filteredUsers[indexPath.item - filteredContacts.count]
                cell.group = group
                return cell
            }
        }
    }
    
    func importAllContacts() {
        CNContactStore().requestAccess(for: .contacts) { (access, error) in
            let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            guard access else {
                if authorizationStatus == .denied {
                    DispatchQueue.main.async {
                        if !self.hasClickedSelectContacts {
                            self.explainSelectContactLabel.isHidden = false
                        }
                    }
                    return
                }
                let alert = UIAlertController(title: "GroupRoots does not have access to your contacts.\n\nEnable contacts in\nSettings > GroupRoots", message: "", preferredStyle: .alert)
                let cancel_closure = { () in
                    { (action: UIAlertAction!) -> Void in
//                         let alert = UIAlertController(title: "Add contacts without giving access", message: "Only add contacts you select with \"Add Selected Contacts\". GroupRoots will not access to all of your contacts", preferredStyle: .alert)
//                         alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                         self.present(alert, animated: true, completion: nil)
                        if !self.hasClickedSelectContacts {
                            self.explainSelectContactLabel.isHidden = false
                        }
                    }
                }
                
                let okay_closure = { () in
                    { (action: UIAlertAction!) -> Void in
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                print("Settings opened: \(success)") // Prints true
                            })
                        }
                    }
                }
                 
                alert.addAction(UIAlertAction(title: "Close", style: .destructive, handler: cancel_closure()))
                alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: okay_closure()))
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            importContactsToRecommended() { (err) in }
            fetchAllContacts(completion: { (contacts) in
                for contact in contacts {
                    if contact.phoneNumbers.count > 0 {
                        let new_contact = Contact(contact: contact)
                        self.allContacts.append(new_contact)
                    }
                }
                self.filteredContacts = self.allContacts
                DispatchQueue.main.async {
                    self.searchCollectionView.reloadData()
                    self.contactsLabel.isHidden = true
                    self.searchBar.frame = CGRect(x: 10, y: 243, width: UIScreen.main.bounds.width - 20, height: 44)
                    self.searchBar.placeholder = "Username or Contact Name"
                }
            }) { (err) in return }
        }
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension InviteToGroupFromIntroController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.addedCollectionView {
             if indexPath.row < contactsToInvite.count {
                 let contact = contactsToInvite[indexPath.row]
                 let name = contact.given_name + " " + contact.family_name
                 return CGSize(width: 75 + 9 * name.count, height: 40)
             }
             else {
                 let user = users[indexPath.item - contactsToInvite.count]
                 let name = user.username
                 return CGSize(width: 75 + 9 * name.count, height: 40)
             }
        }
        else {
            return CGSize(width: UIScreen.main.bounds.width, height: 70)
        }
    }
    
}

extension InviteToGroupFromIntroController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController,
                     didSelect contacts: [CNContact]) {
        let toInvite = contacts.compactMap { Contact(contact: $0) }
        for contact in toInvite {
            if !contactsToInvite.contains(contact) {
                self.contactsToInvite.append(contact)
            }
        }
        self.addedCollectionView.collectionViewLayout.invalidateLayout()
        self.addedCollectionView.reloadData()
        self.addedCollectionView.layoutIfNeeded()
        self.addedCollectionView.scrollToItem(at: IndexPath(item: self.contactsToInvite.count + self.users.count - 1, section: 0), at: [.centeredVertically, .centeredHorizontally], animated: false)
    }
}

extension InviteToGroupFromIntroController: SearchUserForInvitationDelegate {
    func addUser(user: User){
        if !users.contains(user) {
            users.append(user)
        }
        self.addedCollectionView.collectionViewLayout.invalidateLayout()
        self.addedCollectionView.reloadData()
        self.addedCollectionView.layoutIfNeeded()
        self.addedCollectionView.scrollToItem(at: IndexPath(item: self.contactsToInvite.count + self.users.count - 1, section: 0), at: [.centeredVertically, .centeredHorizontally], animated: false)
    }
}


extension InviteToGroupFromIntroController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.filteredUsers = []
            self.filteredContacts = allContacts
            self.searchCollectionView.reloadData()
            
            if CNContactStore.authorizationStatus(for: .contacts) != .authorized {
                if !self.hasClickedSelectContacts {
                    self.explainSelectContactLabel.isHidden = false
                }
            }
        } else {
            self.filteredUsers = []
            if self.explainSelectContactLabel.isHidden == false {
                self.explainSelectContactLabel.isHidden = true
            }
            let formatted_search_word = searchText.removeCharacters(from: "@")
            Database.database().searchForUsers(username: formatted_search_word, completion: { (users) in
                self.filteredUsers = users
//                self.searchCollectionView.reloadData()
                Database.database().searchForUsers(username: formatted_search_word.lowercased(), completion: { (lowercase_users) in
                    for user in lowercase_users {
                        if !self.filteredUsers.contains(user) {
                            self.filteredUsers.append(user)
                        }
                    }
                    Database.database().searchForUsers(username: formatted_search_word.capitalizingFirstLetter(), completion: { (first_capitalized_users) in
                        for user in first_capitalized_users {
                            if !self.filteredUsers.contains(user) {
                                self.filteredUsers.append(user)
                            }
                        }
                        self.filteredContacts = self.allContacts.filter { (contact: Contact) -> Bool in
                            return (contact.given_name + contact.family_name).lowercased().contains(searchText.lowercased())
                        }
                        self.searchCollectionView.reloadData()
                    })
                })
            })
        }
    }
    
    func InviteToGroupFromIntroController(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

