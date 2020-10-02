//
//  Contacts.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 10/2/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import Contacts
import PhoneNumberKit
import FirebaseDatabase

// imports all the users contacts and store in userDefaults as an array
// if the contact is in userDefaults already then return
// add user's number to userDefaults
// if the user's number is tied to an account already
//      if not already in recommendedUsers:
//          add them to recommendedUsers
// else
//      upload the contact under firebase database entree of "importedContacts": "userId"
//      this is so that when that user signs up, it adds them as a recommended to all users under them in "importedContacts"
//          (remember to remove them from importedContacts when they sign up after doing all of this)

// cloud function stuff:
//      when user creates an account with a number tied to it:
//          for each user under the number in importedContacts:
//              if not already in said user's recommendedUsers
//                  add them to recommendedUsers with priority 1
//          remove user from importedContacts

let phoneNumberKit = PhoneNumberKit()

func importContactsToRecommended(completion: @escaping (Error?) -> ()) {
    let store = CNContactStore()
    if CNContactStore.authorizationStatus(for: .contacts) != .authorized {
        completion(nil)
        return
    }
    do {
        let sync = DispatchGroup()
        
        let keys = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactIdentifierKey as CNKeyDescriptor]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try store.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        var contacts: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            do {
                let containerResults = try store.unifiedContacts(matching: fetchPredicate, keysToFetch: keys)
                contacts.append(contentsOf: containerResults)
            } catch {
                print("Error fetching results for container")
            }
        }
        
        var updatedImportedContacts = [String]()
        if let importedContactsRetrieved = UserDefaults.standard.object(forKey: "importedContacts") as? Data {
            guard let importedContacts = try? JSONDecoder().decode([String].self, from: importedContactsRetrieved) else {
                print("Error: Couldn't decode data into Blog")
                return
            }
            updatedImportedContacts = importedContacts
        }
        
        for contact in contacts {
            if contact.phoneNumbers.count > 0 {
                let new_contact = Contact(contact: contact, selected_number: contact.phoneNumbers.first!)
                // check that contact is not in userDefaults
                if !updatedImportedContacts.contains(new_contact.contact.identifier) {
                    // add it to updatedImportedContacts
                    updatedImportedContacts.append(new_contact.contact.identifier)
                    
                    // check if number is tied to an account already
                    let phoneNumber = try? phoneNumberKit.parse(contact.phoneNumbers.first!.value.stringValue)
                    if phoneNumber != nil {
                        let numberString = phoneNumberKit.format(phoneNumber!, toType: .e164)
                        sync.enter()
                        Database.database().doesNumberExist(number: numberString, completion: { (exists) in
                            if exists {
                                Database.database().fetchUserIdFromNumber(number: numberString, completion: { (userId) in
                                    // check if not in recommendedUsers then add to recommendedUsers
                                    Database.database().isInFollowRecommendation(withUID: userId, completion: { (isRecommended) in
                                        if !isRecommended {
                                            // add to recommended users
                                            // checks to see if already follow user inside addToFollowRecommendation
                                            Database.database().addToFollowRecommendation(withUID: userId, priority: 1) { (err) in
                                                if err != nil {
                                                    return
                                                }
                                                sync.leave()
                                            }
                                        }
                                        else {
                                            sync.leave()
                                        }
                                    }) { (err) in }
                                })
                            }
                            else {
                                // upload to importedContacts: currentUserId
                                Database.database().addToImportedContacts(number: numberString, name: new_contact.given_name + " " + new_contact.family_name) { (err) in
                                    if err != nil {
                                        return
                                    }
                                    sync.leave()
                                }
                            }
                        }) { (err) in return}
                    }
                }
            }
        }
        
//            print("imported contacts updated")
//            print(updatedImportedContacts)
        
        // set updatedImportedContacts to importedContacts
        if let importedContactsEncodedData = try? JSONEncoder().encode(updatedImportedContacts) {
            UserDefaults.standard.set(importedContactsEncodedData, forKey: "importedContacts")
        }
        
        sync.notify(queue: .main) {
            completion(nil)
        }
    }
}


func fetchAllContacts(completion: @escaping ([CNContact]) -> (), withCancel cancel: ((Error) -> ())?) {
    let store = CNContactStore()
    if CNContactStore.authorizationStatus(for: .contacts) != .authorized {
        return
    }
    do {
        let keys = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactIdentifierKey as CNKeyDescriptor]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try store.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        var contacts: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            do {
                let containerResults = try store.unifiedContacts(matching: fetchPredicate, keysToFetch: keys)
                contacts.append(contentsOf: containerResults)
            } catch {
                print("Error fetching results for container")
            }
        }
        // sort by last name first, then sort by first name
        let sorted_contacts = contacts.sorted(by: { (p1, p2) -> Bool in
            return ((p1.givenName + p1.familyName).lowercased()).compare((p2.givenName + p2.familyName).lowercased()) == .orderedAscending
        })
        completion(sorted_contacts)
    }
}
