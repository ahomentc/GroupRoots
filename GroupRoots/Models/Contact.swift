//
//  Contact.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 8/29/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import ContactsUI

struct Contact: Equatable {
    
    let contact: CNContact
    let given_name: String
    let family_name: String
//    let phone: CNLabeledValue<CNPhoneNumber>?
    let phone_numbers: [CNLabeledValue<CNPhoneNumber>?]
    let identifier: String
    let selected_phone_number: CNLabeledValue<CNPhoneNumber>?
    
    init(contact: CNContact, selected_number: CNLabeledValue<CNPhoneNumber>? = nil) {
        self.contact = contact
        self.given_name = contact.givenName
        self.family_name = contact.familyName
        self.phone_numbers = contact.phoneNumbers
        self.identifier = contact.identifier
        self.selected_phone_number = selected_number
    }
    
    static func ==(lhs: Contact, rhs: Contact) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
