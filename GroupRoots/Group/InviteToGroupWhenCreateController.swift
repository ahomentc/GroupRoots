//
//  InviteToGroupWhenCreateController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 9/2/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import ContactsUI
import PhoneNumberKit

protocol InviteToGroupWhenCreateControllerDelegate {
    func shouldOpenGroup(groupId: String)
}

class InviteToGroupWhenCreateController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var group: Group? {
        didSet {
            self.addedCollectionView.reloadData()
        }
    }
    
    var delegate: InviteToGroupWhenCreateControllerDelegate?
    
    private lazy var contactsLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(white: 0.9, alpha: 1)
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.layer.cornerRadius = 20
        label.layer.masksToBounds = true
        label.isHidden = false
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Add From\nContacts", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
        label.attributedText = attributedText
        return label
    }()
    
    private lazy var searchLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(white: 0.9, alpha: 1)
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.layer.cornerRadius = 20
        label.layer.masksToBounds = true
        label.isHidden = false
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Search By\nUsername", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
        label.attributedText = attributedText
        return label
    }()
    
    private var contactsToInvite = [Contact]()
    private var users = [User]()
    
    var addedCollectionView: UICollectionView!
    var contactsCollectionView: UICollectionView!
    
    let phoneNumberKit = PhoneNumberKit()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
        
//        navigationItem.titleView = searchBar
        navigationItem.title = "Add Group Members"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelSelected))
        navigationItem.leftBarButtonItem?.tintColor = .black
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Invite", style: .plain, target: self, action: #selector(inviteButtonClicked))
        navigationItem.rightBarButtonItem?.tintColor = .black
        self.navigationController?.navigationBar.shadowImage = UIColor.white.as1ptImage()
        
        let added_layout = UICollectionViewFlowLayout()
        added_layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        added_layout.itemSize = CGSize(width: 60, height: 60)
        added_layout.minimumLineSpacing = CGFloat(20)
        addedCollectionView = UICollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height - UIScreen.main.bounds.height/9*8, width: UIScreen.main.bounds.width, height: 120), collectionViewLayout: added_layout)
        addedCollectionView.delegate = self
        addedCollectionView.dataSource = self
        addedCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        addedCollectionView?.register(AddedUserCell.self, forCellWithReuseIdentifier: AddedUserCell.cellId)
        addedCollectionView?.register(ContactCell.self, forCellWithReuseIdentifier: ContactCell.cellId)
        addedCollectionView.showsVerticalScrollIndicator = true
        addedCollectionView.isUserInteractionEnabled = true
        addedCollectionView.allowsSelection = true
        addedCollectionView.showsHorizontalScrollIndicator = false
        addedCollectionView?.backgroundColor = .white
        addedCollectionView?.alwaysBounceVertical = true
        addedCollectionView?.keyboardDismissMode = .onDrag
        self.view.insertSubview(addedCollectionView, at: 10)
        
        let contacts_layout = UICollectionViewFlowLayout()
        contacts_layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        contacts_layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        contacts_layout.minimumLineSpacing = CGFloat(0)
        
        contactsCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), collectionViewLayout: contacts_layout)
        contactsCollectionView.delegate = self
        contactsCollectionView.dataSource = self
        contactsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        contactsCollectionView?.register(AddedUserCell.self, forCellWithReuseIdentifier: AddedUserCell.cellId)
        contactsCollectionView?.register(ContactCell.self, forCellWithReuseIdentifier: ContactCell.cellId)
        contactsCollectionView.showsHorizontalScrollIndicator = false
        contactsCollectionView?.backgroundColor = .white
        contactsCollectionView?.alwaysBounceVertical = true
        contactsCollectionView?.keyboardDismissMode = .onDrag
        self.view.insertSubview(contactsCollectionView, at: 5)
        
        contactsLabel.frame = CGRect(x: 30, y: 100, width: (UIScreen.main.bounds.width - 80) / 2, height: 60)
        contactsLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleShowContacts)))
        self.view.insertSubview(contactsLabel, at: 4)
        
        searchLabel.frame = CGRect(x: 50 + ((UIScreen.main.bounds.width - 80) / 2), y: 100, width: (UIScreen.main.bounds.width - 80) / 2, height: 60)
        searchLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleShowSearch)))
        self.view.insertSubview(searchLabel, at: 4)
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
        self.dismiss(animated: true, completion: {
            self.delegate?.shouldOpenGroup(groupId: group.groupId)
        })
    }
    
    @objc private func inviteButtonClicked(){
        guard let group = group else { return }
        if contactsToInvite.count == 0 && users.count == 0 {
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
//            var alertsToPresent2 = [String: UIAlertController]()
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
                self.dismiss(animated: true, completion: {
                    self.delegate?.shouldOpenGroup(groupId: group.groupId)
                })
                NotificationCenter.default.post(name: NSNotification.Name("createdGroup"), object: nil)
                // also add a little message for when this closes saying something about invited
            }
        }
    }
    
    @objc private func handleShowContacts(){
//        let contactsInviteController = ContactsInviteController(collectionViewLayout: UICollectionViewFlowLayout())
//        userProfileController.user = selectedUser
//        navigationController?.pushViewController(contactsInviteController, animated: true)
        
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return filteredUsers.count
        return contactsToInvite.count + users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item < contactsToInvite.count {
            let contact = contactsToInvite[indexPath.item]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContactCell.cellId, for: indexPath) as! ContactCell
            cell.contact = contact
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddedUserCell.cellId, for: indexPath) as! AddedUserCell
            cell.user = users[indexPath.item - contactsToInvite.count]
            cell.group = group
//            cell.delegate = self
            return cell
        }
    }
    
//    func chooseNumber(contact: Contact, completion: (CNLabeledValue<CNPhoneNumber>?)) {
//        let alert = UIAlertController(title: "Pick a number for", message: "", preferredStyle: .alert)
//        var i = 0
//        for number in contact.phone_numbers {
//            let action = UIAlertAction(title: number?.value.stringValue, style: .default) { _ in
//                let val = contact.phone_numbers[i]
//                completion(val)
//            }
//            alert.addAction(action)
//            i += 1
//        }
//        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
//        alert.addAction(cancel)
//        self.present(alert, animated: true, completion: {
//
//        })
//    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension InviteToGroupWhenCreateController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 66)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
}

////MARK: - InviteToGroupCellDelegate
//extension InviteToGroupWhenCreateController: InviteToGroupCellDelegate {
//    func inviteSentMessage(){
//        let alert = UIAlertController(title: "", message: "Invite Sent", preferredStyle: .alert)
//        self.present(alert, animated: true, completion: nil)
//        let when = DispatchTime.now() + 2
//        DispatchQueue.main.asyncAfter(deadline: when){
//          alert.dismiss(animated: true, completion: nil)
//        }
//    }
//}

extension InviteToGroupWhenCreateController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController,
                     didSelect contacts: [CNContact]) {
        let toInvite = contacts.compactMap { Contact(contact: $0) }
        for contact in toInvite {
            if !contactsToInvite.contains(contact) {
                self.contactsToInvite.append(contact)
            }
        }
        self.addedCollectionView.reloadData()
    }
}

extension InviteToGroupWhenCreateController: SearchUserForInvitationDelegate {
    func addUser(user: User){
//        users.append(user)
        if !users.contains(user) {
            users.append(user)
        }
        self.addedCollectionView.reloadData()
    }
}


