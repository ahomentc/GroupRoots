//
//  ContactsInviteController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 8/29/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import ContactsUI

class ContactsInviteController: UICollectionViewController {
    
    private var contactsToInvite = [Contact]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        self.collectionView.backgroundColor = .white
        
        collectionView?.register(ContactCell.self, forCellWithReuseIdentifier: ContactCell.cellId)
        collectionView?.alwaysBounceVertical = true
        
        // open the contacts picker automatically
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        contactPicker.predicateForEnablingContact = NSPredicate(
          format: "phoneNumbers.@count > 0")
        present(contactPicker, animated: true, completion: nil)
    }
    
    // add a collectionview that shows all of the contacts you've added,
    // then when user clicks "next", it'll send the invitation to all of them
    // they can add and remove from the list with the edit and add buttons in the corner
    // but the contact picker screen will open auto first before this table is added
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contactsToInvite.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContactCell.cellId, for: indexPath) as! ContactCell
        cell.contact = contactsToInvite[indexPath.item]
//        cell.delegate = self
        return cell
    }
}

extension ContactsInviteController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 66)
    }
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        if isInGroup ?? false {
//            return CGSize(width: view.frame.width, height: 44)
//        }
//        return CGSize(width: view.frame.width, height: 5)
//    }
}

extension ContactsInviteController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController,
                     didSelect contacts: [CNContact]) {
        let toInvite = contacts.compactMap { Contact(contact: $0) }
        for contact in toInvite {
            if !contactsToInvite.contains(contact) {
              contactsToInvite.append(contact)
            }
        }
        print(contactsToInvite)
        self.collectionView.reloadData()
    }
}
