import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import ContactsUI
import PhoneNumberKit

extension Auth {
    func createUser(withEmail email: String, username: String, name: String, bio: String, password: String, image: UIImage?, completion: @escaping (Error?) -> ()) {
        Database.database().usernameExists(username: username, completion: { (exists) in
            if !exists{
                Auth.auth().createUser(withEmail: email, password: password, completion: { (user, err) in
                    if let err = err {
                        print("Failed to create user:", err)
                        completion(err)
                        return
                    }
                    guard let uid = user?.user.uid else { return }
                    
                    // some sort of weird bug where username isn't added to usernames so add it here too
                    let username_values = [username: uid]
                    Database.database().reference().child("usernames").updateChildValues(username_values, withCompletionBlock: { (err, ref) in
                        if let err = err {
                            print("Failed to upload user to database:", err)
                            return
                        }
                    })
                    
                    if let image = image {
                        Storage.storage().uploadUserProfileImage(image: image, completion: { (profileImageUrl) in
                            self.uploadUser(withUID: uid, username: username, name: name, bio: bio, profileImageUrl: profileImageUrl) {
                                completion(nil)
                            }
                        })
                    } else {
                        self.uploadUser(withUID: uid, username: username, name: name, bio: bio) {
                            completion(nil)
                        }
                    }
                })
            }
            else {
                let error = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "Username Taken"])
                completion(error)
                return
            }
        })
    }
    
    func createUserFromPhone(withUID uid: String, withEmail email: String, username: String, name: String, bio: String, image: UIImage?, completion: @escaping (Error?) -> ()) {
        Database.database().usernameExists(username: username, completion: { (exists) in
            if !exists{
                
                // some sort of weird bug where username isn't added to usernames so add it here too
                let username_values = [username: uid]
                Database.database().reference().child("usernames").updateChildValues(username_values, withCompletionBlock: { (err, ref) in
                    if let err = err {
                        print("Failed to upload user to database:", err)
                        return
                    }
                })
                
                if let image = image {
                    Storage.storage().uploadUserProfileImage(image: image, completion: { (profileImageUrl) in
                        self.uploadUser(withUID: uid, username: username, name: name, bio: bio, profileImageUrl: profileImageUrl) {
                            completion(nil)
                        }
                    })
                } else {
                    self.uploadUser(withUID: uid, username: username, name: name, bio: bio) {
                        completion(nil)
                    }
                }
            }
            else {
                let error = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "Username Taken"])
                completion(error)
                return
            }
        })
    }
    
    private func uploadUser(withUID uid: String, username: String, name: String, bio: String, profileImageUrl: String? = nil, completion: @escaping (() -> ())) {
        var dictionaryValues = ["username": username, "name": name, "bio": bio]
        if profileImageUrl != nil {
            dictionaryValues["profileImageUrl"] = profileImageUrl
        }
        
        let values = [uid: dictionaryValues]
        Database.database().reference().child("users").updateChildValues(values, withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to upload user to database:", err)
                return
            }
            let values_inverted = [username: uid]
            Database.database().reference().child("usernames").updateChildValues(values_inverted, withCompletionBlock: { (err, ref) in
                if let err = err {
                    print("Failed to upload user to database:", err)
                    return
                }
                completion()
            })
        })
    }
}

extension Storage {
    
    fileprivate func uploadUserProfileImage(image: UIImage, completion: @escaping (String) -> ()) {
        guard let uploadData = image.jpegData(compressionQuality: 0.7) else { return } //changed from 0.3
        
        let storageRef = Storage.storage().reference().child("profile_images").child(NSUUID().uuidString)
        
        storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload profile image:", err)
                return
            }
            
            storageRef.downloadURL(completion: { (downloadURL, err) in
                if let err = err {
                    print("Failed to obtain download url for profile image:", err)
                    return
                }
                guard let profileImageUrl = downloadURL?.absoluteString else { return }
                completion(profileImageUrl)
            })
        })
    }
    
    fileprivate func uploadPostImage(image: UIImage, filename: String, completion: @escaping (String) -> ()) {
        guard let uploadData = image.jpegData(compressionQuality: 0.95) else { return } //changed from 0.5
        
        let storageRef = Storage.storage().reference().child("post_images").child(filename)
        storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload post image:", err)
                return
            }
            
            storageRef.downloadURL(completion: { (downloadURL, err) in
                if let err = err {
                    print("Failed to obtain download url for post image:", err)
                    return
                }
                guard let postImageUrl = downloadURL?.absoluteString else { return }
                completion(postImageUrl)
            })
        })
    }
    
    // distributes into folders
    fileprivate func uploadPostImageDistributed(image: UIImage, groupId: String, filename: String, completion: @escaping (String) -> ()) {
        guard let uploadData = image.jpegData(compressionQuality: 0.95) else { return } //changed from 0.5
        
        let storageRef = Storage.storage().reference().child("group_post_images").child(groupId).child(filename + ".jpeg")
        storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload post image:", err)
                return
            }
            
            storageRef.downloadURL(completion: { (downloadURL, err) in
                if let err = err {
                    print("Failed to obtain download url for post image:", err)
                    return
                }
                guard let postImageUrl = downloadURL?.absoluteString else { return }
                completion(postImageUrl)
            })
        })
    }
    
    func uploadPostVideo(filePath: URL, filename: String, fileExtension: String, completion: @escaping (String) -> ()) {
        // Create a reference to the file you want to upload
        let storageRef = Storage.storage().reference().child("post_videos").child("\(filename).\(fileExtension)")

        // Upload the file to the path "images/fileName.fileExtension"
        storageRef.putFile(from: filePath, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload post image:", err)
                return
            }
            
            // The upload succeeded
            storageRef.downloadURL(completion: { (downloadURL, err) in
            if let err = err {
                print("Failed to obtain download url for post image:", err)
                return
            }
            guard let postVideoUrl = downloadURL?.absoluteString else { return }
            completion(postVideoUrl)
          })
        })
    }
    
    func uploadPostVideoDistributed(filePath: URL, groupId: String, filename: String, completion: @escaping (String) -> ()) {
        // Create a reference to the file you want to upload
        let storageRef = Storage.storage().reference().child("group_post_videos").child(groupId).child("\(filename)")

        // Upload the file to the path "images/fileName.fileExtension"
        storageRef.putFile(from: filePath, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload post image:", err)
                return
            }
            
            // The upload succeeded
            storageRef.downloadURL(completion: { (downloadURL, err) in
            if let err = err {
                print("Failed to obtain download url for post image:", err)
                return
            }
            guard let postVideoUrl = downloadURL?.absoluteString else { return }
            completion(postVideoUrl)
          })
        })
    }
    
    fileprivate func uploadGroupProfileImage(image: UIImage, completion: @escaping (String) -> ()) {
        guard let uploadData = image.jpegData(compressionQuality: 0.7) else { return } //changed from 0.3
        
        let storageRef = Storage.storage().reference().child("group_profile_images").child(NSUUID().uuidString)
        
        storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload profile image:", err)
                return
            }
            print("finished uploading")
            storageRef.downloadURL(completion: { (downloadURL, err) in
                if let err = err {
                    print("Failed to obtain download url for profile image:", err)
                    return
                }
                
                guard let profileImageUrl = downloadURL?.absoluteString else { return }
                print(profileImageUrl)
                completion(profileImageUrl)
            })
        })
    }
    
    fileprivate func uploadGroupImage(image: UIImage, filename: String, completion: @escaping (String) -> ()) {
        guard let uploadData = image.jpegData(compressionQuality: 0.95) else { return } //changed from 0.5
        
        let storageRef = Storage.storage().reference().child("group_images").child(filename)
        storageRef.putData(uploadData, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload post image:", err)
                return
            }
            
            storageRef.downloadURL(completion: { (downloadURL, err) in
                if let err = err {
                    print("Failed to obtain download url for post image:", err)
                    return
                }
                guard let postImageUrl = downloadURL?.absoluteString else { return }
                completion(postImageUrl)
            })
        })
    }
}

extension Database {

//-------------------------------------------------------
//------------------------ Users ------------------------
//-------------------------------------------------------
    
    //MARK: Users
    
    func fetchUser(withUID uid: String, completion: @escaping (User) -> ()) {
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userDictionary = snapshot.value as? [String: Any] else {
                print("user not found")
                return
            }
            let user = User(uid: uid, dictionary: userDictionary)
            completion(user)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    
    // make sure to do Username exists
    func updateUser(withUID uid: String, username: String? = nil, name: String? = nil, bio: String? = nil, image: UIImage? = nil, phone: String? = nil, completion: @escaping (Error?) -> ()){
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        var profileImageUrl = ""
        
        // set the profile image url to the dictionary if there is an image
        let sync = DispatchGroup()
        sync.enter()
        if image != nil {
            Storage.storage().uploadUserProfileImage(image: image!, completion: { (userProfileImageUrl) in
                profileImageUrl = userProfileImageUrl
                sync.leave()
            })
        }
        else{
            sync.leave()
        }
        sync.notify(queue: .main){
            // get original username
            var old_username = ""
            var old_bio = ""
            Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                old_username = user.username
                old_bio = user.bio
                
                // update the user with the new values
                // can't do: Database.database().reference().child("users").updateChildValues(values)
                // because it will replace everything under user so need to do each one individually
                
                let updates_sync = DispatchGroup()
                
                // update the username if not nil
                if username != nil && username != "" {
                    print("1")
                    updates_sync.enter()
                    Database.database().usernameExists(username: username!, completion: { (exists) in
                        if !exists || username! == old_username {
                            Database.database().reference().child("users").child(currentLoggedInUserId).updateChildValues(["username": username!], withCompletionBlock: { (err, ref) in
                                if let err = err {
                                    print("Failed to update username in database:", err)
                                    return
                                }
                                // replace the username if there is a username and remove old one
                                if username != nil {
                                    let values_inverted = [username: uid]
                                    // delete the old username
                                    Database.database().reference().child("usernames").child(old_username).removeValue(completionBlock: { (err, _) in
                                        if let err = err {
                                            print("Failed to remove username:", err)
                                            return
                                        }
                                        Database.database().reference().child("usernames").updateChildValues(values_inverted, withCompletionBlock: { (err, ref) in
                                            if let err = err {
                                                print("Failed to upload user to database:", err)
                                                return
                                            }
                                            updates_sync.leave()
                                        })
                                    })
                                }
                                else {
                                    updates_sync.leave()
                                }
                            })
                        }
                        else {
                            updates_sync.leave()
                            let error = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "Username Taken"])
                            completion(error)
                            return
                        }
                    })
                }
                
                if name != nil && name != "" {
                    updates_sync.enter()
                    Database.database().reference().child("users").child(currentLoggedInUserId).updateChildValues(["name": name!], withCompletionBlock: { (err, ref) in
                        if let err = err {
                            print("Failed to update name in database:", err)
                            return
                        }
                        updates_sync.leave()
                    })
                }
                
                if bio != nil && bio != "" {
                    updates_sync.enter()
                    if bio! != old_bio {
                        Database.database().reference().child("users").child(currentLoggedInUserId).updateChildValues(["bio": bio!], withCompletionBlock: { (err, ref) in
                            if let err = err {
                                print("Failed to update bio in database:", err)
                                updates_sync.leave()
                                return
                            }
                            updates_sync.leave()
                        })
                    }
                    else {
                        updates_sync.leave()
                    }
                }
                else {
                    // username is empty, check if same as old, if not then change
                    if old_bio != "" {
                        updates_sync.enter()
                        Database.database().reference().child("users").child(currentLoggedInUserId).updateChildValues(["bio": ""], withCompletionBlock: { (err, ref) in
                            if let err = err {
                                print("Failed to update bio in database:", err)
                                updates_sync.leave()
                                return
                            }
                            updates_sync.leave()
                        })
                    }
                }
                
                if profileImageUrl != "" {
                    updates_sync.enter()
                    Database.database().reference().child("users").child(currentLoggedInUserId).updateChildValues(["profileImageUrl": profileImageUrl], withCompletionBlock: { (err, ref) in
                        if let err = err {
                            print("Failed to update name in database:", err)
                            return
                        }
                        updates_sync.leave()
                    })
                }
                
                if phone != nil && phone != "" {
                    updates_sync.enter()
                    Database.database().reference().child("users").child(currentLoggedInUserId).updateChildValues(["phoneNumber": phone!], withCompletionBlock: { (err, ref) in
                        if let err = err {
                            print("Failed to update name in database:", err)
                            return
                        }
                        updates_sync.leave()
                    })
                }
                
                updates_sync.notify(queue: .main){
                    completion(nil)
                }
            }
        }
    }

    func fetchUserFromUsername(username: String, completion: @escaping (User) -> ()) {
        Database.database().reference().child("usernames").child(username).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    return
                }
                let userId = snapshot.value as! String
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            completion(user)
                        })
                    }
                })
            }
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func inviteCodeExists(code: String, completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("inviteCodes").child(code).observeSingleEvent(of: .value, with: { (snapshot) in
            guard (snapshot.value as? [String: Any]) != nil else {
                completion(false)
                return
            }
            completion(true)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func fetchInviteCodeGroupId(code: String, completion: @escaping (String) -> ()) {
        Database.database().reference().child("inviteCodes").child(code).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion("")
                return
            }
            dictionaries.forEach({ (key, value) in
                completion(key)
                return
            })
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func userExists(withUID uid: String, completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard (snapshot.value as? [String: Any]) != nil else {
                completion(false)
                return
            }
            completion(true)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func groupRootsUserExists(withUID uid: String, completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("users").child(uid).child("username").observeSingleEvent(of: .value, with: { (snapshot) in
            guard (snapshot.value as? String) != nil else {
                completion(false)
                print("false")
                return
            }
            print("true")
            completion(true)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func usernameExists(username: String, completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("usernames").child(username).observeSingleEvent(of: .value, with: { (snapshot) in
            guard (snapshot.value as? String) != nil else {
                completion(false)
                return
            }
            completion(true)
        }) { (err) in
            print("Failed to check username in database:", err)
        }
    }
    
    func enableIncognitoMode(completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(currentLoggedInUserId)
        let values = ["incognito": 1] as [String : Any]
        ref.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to save post to database", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func disableIncognitoMode(completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(currentLoggedInUserId)
        let values = ["incognito": 0] as [String : Any]
        ref.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to save post to database", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func isInIncognitoMode(completion: @escaping (Bool) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(currentLoggedInUserId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dict = snapshot.value as? [String: Any] else { return }
            let seen = dict["incognito"] as? Int ?? 0
            if seen == 1 {
                completion(true)
            }
            else{
                completion(false)
            }
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func hasFollowedSomeone(completion: @escaping (Bool) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("hasFollowedSomeone").child(currentLoggedInUserId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func followedSomeone(completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("hasFollowedSomeone")
        let values = [currentLoggedInUserId: 1]
        ref.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to save to database", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
//    func fetchAllUsers(includeCurrentUser: Bool = true, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
//        let ref = Database.database().reference().child("users")
//        ref.observeSingleEvent(of: .value, with: { (snapshot) in
//            guard let dictionaries = snapshot.value as? [String: Any] else {
//                completion([])
//                return
//            }
//
//            var users = [User]()
//
//            dictionaries.forEach({ (key, value) in
//                if !includeCurrentUser, key == Auth.auth().currentUser?.uid {
//                    completion([])
//                    return
//                }
//                self.userExists(withUID: key, completion: { (exists) in
//                    if exists{
//                        guard let userDictionary = value as? [String: Any] else { return }
//                        let user = User(uid: key, dictionary: userDictionary)
//                        users.append(user)
//                    }
//                })
//            })
// // need to use dispatch group for this
//            users.sort(by: { (user1, user2) -> Bool in
//                return user1.username.compare(user2.username) == .orderedAscending
//            })
//            completion(users)
//
//        }) { (err) in
//            print("Failed to fetch all users from database:", (err))
//            cancel?(err)
//        }
//    }
    
    func searchForUser(username: String, completion: @escaping (User) -> ()) {
        // have dictionary in dict that is... username: uid
        Database.database().reference().child("usernames").child(username).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let uid = snapshot.value as? String else { return }
            Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
                guard let userDictionary = snapshot.value as? [String: Any] else { return }
                let user = User(uid: uid, dictionary: userDictionary)
                completion(user)
            }) { (err) in
                print("Failed to fetch user from database:", err)
            }
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func searchForUsers(username: String, completion: @escaping ([User]) -> ()) {
        Database.database().reference().child("usernames").queryOrderedByKey().queryStarting(atValue: username).queryEnding(atValue:username+"\u{f8ff}").queryLimited(toFirst: 30).observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                sync.enter()
                let userId = child.value as! String
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else{
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                users.sort(by: { (p1, p2) -> Bool in
                    return p1.username < p2.username
                })
                completion(users)
                return
            }
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }

    func setUserfcmToken(token: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(currentLoggedInUserId)
        let values = ["token": token] as [String : Any]
        ref.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to save post to database", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func fetchUserFollowers(withUID uid: String, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("followers").child(uid)
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                sync.enter()
                let userId = child.key
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else{
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                completion(users)
                return
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func fetchMoreFollowers(withUID uid: String, endAt: Double, completion: @escaping ([User],Double) -> (), withCancel cancel: ((Error) -> ())?) {
        print("endAt is: ", endAt)
        let ref = Database.database().reference().child("followers").child(uid)
        // endAt gets included in the next one but it shouldn't
        ref.queryOrderedByValue().queryEnding(atValue: endAt).queryLimited(toLast: 30).observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            var followDates = [String: Double]()

            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let userId = child.key
                followDates[userId] = child.value as? Double
                sync.enter()
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists {
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                users.sort(by: { (p1, p2) -> Bool in
                    return followDates[p1.uid] ?? 0 > followDates[p2.uid] ?? 0
                })
                
                // queryEnding keeps the oldest entree of the last batch so remove it here if not the first batch
                if endAt != 10000000000000 && users.count > 0 {
                    users.remove(at: 0)
                }
                completion(users,followDates[users.last?.uid ?? ""] ?? 10000000000000)
                return
            }
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func fetchUserFollowing(withUID uid: String, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("following").child(uid)
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in

            var users = [User]()
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                sync.enter()
                let userId = child.key
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else{
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                completion(users)
                return
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func fetchUserSubscriptions(withUID uid: String, completion: @escaping ([Group]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("groupsFollowing").child(uid)
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var groups = [Group]()
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                sync.enter()
                let groupId = child.key
                self.groupExists(groupId: groupId, completion: { (exists) in
                    if exists {
                        Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                            groups.append(group)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                completion(groups)
                return
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }

    // Modify this to get a random selection of 10 from the first 30 when sorted by value
    // Also, this may be out of order since doing an aysnc fetchUser
    func fetchFollowRecommendations(withUID uid: String, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("recommendedToFollow").child(uid)
        ref.queryOrderedByValue().queryLimited(toFirst: UInt(30)).observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            var usersToPriority = [String: Int]()
            
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                sync.enter()
                let userId = child.key
                let priority = child.value as! Int
                usersToPriority[userId] = priority
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else{
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                users.removeAll(where: { usersToPriority[$0.uid] == 1000 })
                completion(users.shuffled())
                return
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    // doesn't actually remove but sets priority to 1000
    func removeFromFollowRecommendation(withUID uid: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("recommendedToFollow").child(currentLoggedInUserId)
        let values = [uid: 1000] as [String : Any]
        ref.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to remove follow recommendation", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func addToFollowRecommendation(withUID uid: String, priority: Int, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("recommendedToFollow").child(currentLoggedInUserId)
        
        Database.database().isFollowingUser(withUID: uid, completion: { (following) in
            if following {
                completion(nil)
            } else {
                let values = [uid: priority] as [String : Any]
                ref.updateChildValues(values) { (err, ref) in
                    if let err = err {
                        print("Failed to remove follow recommendation", err)
                        completion(err)
                        return
                    }
                    completion(nil)
                }
            }
        }) { (err) in }
    }
    
    // check if user with uid is recommended for the current user
    func isInFollowRecommendation(withUID uid: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("recommendedToFollow").child(currentLoggedInUserId).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    // importedContacts holds all the numbers of contacts from grouproots users... that haven't joined yet
    // each number has children of the users who have that number in their contacts
    // when the number joins, each user who has it gets a recommendation to follow
    func addToImportedContacts(number: String, name: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("importedContacts").child(number)
        let values = [currentLoggedInUserId: 0, "name": name] as [String : Any]
        ref.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to remove follow recommendation", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func isFollowingUser(withUID uid: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("following").child(currentLoggedInUserId).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    // callback hell
    // needs to be restructured
/*   - Add user A to B's followers and B to A's following
 *   - For B's groups:
 *       - If user A is not subscribed and isn't in inUserRemoved:
 *           - If the group is public, add B to membersFollowing for the group in A's groupsFollowing
 *           - If the group is private add B to A's memberFollowing for the request to subscribe to the group, right under the autoSubscribed
 *       - If user A is subscribed:
 *           - add B to membersFollowing for the group in A's groupsFollowing
 *   - Subscribe user A to B's groups that are public if the following conditions are met:
 *       - A is not already subscribed
 *       - A isn't in the group's inUserRemoved
 *   - Add A to the groupFollowPending for B's groups that are private with info that it was B who A followed. If following conditions are met:
 *       - A is not already subscribed
 *       - A isn't in the group's inUserRemoved
 *       - A is not in already in groupFollowPending
 */
    
    func followUser(withUID uid: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        
        let values = [uid: Date().timeIntervalSince1970]
        Database.database().reference().child("following").child(currentLoggedInUserId).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            
            let values = [currentLoggedInUserId: Date().timeIntervalSince1970]
            Database.database().reference().child("followers").child(uid).updateChildValues(values) { (err, ref) in
                if let err = err {
                    completion(err)
                    return
                }
                // for each group of uid's group
                    // if group is public: check if currentLoggedInUserId is not in group.followers, not in group.removed, and groupID not in B.removed
                    // if group is private: also check if user is not in group.pendingfollowers
                Database.database().fetchAllGroups(withUID: uid, completion: { (groups) in
                    // we are given an [group] array
                    
                    let sync = DispatchGroup()
                    groups.forEach({ (groupItem) in
                        sync.enter()
                        
                        // check if the group is hidden
                        Database.database().isGroupHiddenForUser(withUID: uid, groupId: groupItem.groupId, completion: { (isHidden) in
                            if !isHidden {
                                // see if group is private
                                guard let isPrivate = groupItem.isPrivate else { completion(err); return }
                                
                                // add uid to membersFollowing of the current user's groupsFollowing for the group
                                // do this only if the group is public
                                Database.database().isFollowingGroup(groupId: groupItem.groupId, completion: { (following) in
                                    let lower_sync = DispatchGroup()
                                    let groupId = groupItem.groupId
                                    
                                    // This is the membersFollowing part:
                                    
                                    // A follows B
                                    if following { // add B to membersFollowing for the group in A's groupsFollowing
                                        let values = [uid: 1]
                                        lower_sync.enter()
                                        let ref = Database.database().reference().child("groupsFollowing").child(currentLoggedInUserId).child(groupId).child("membersFollowing")
                                        ref.updateChildValues(values) { (err, ref) in
                                            if let err = err {
                                                completion(err)
                                                return
                                            }
                                            lower_sync.leave()
                                        }
                                    }
                                    else {
                                        if isPrivate {
                                            // add B to A's memberFollowing for the request to subscribe to the group, right under the autoSubscribed
                                            let values = [uid: 1]
                                            lower_sync.enter()
                                            let ref = Database.database().reference().child("groupFollowPending").child(groupId).child(currentLoggedInUserId).child("membersFollowing")
                                            ref.updateChildValues(values) { (err, ref) in
                                                if let err = err {
                                                    completion(err)
                                                    return
                                                }
                                                lower_sync.leave()
                                            }
                                        }
                                        else { //  add B to membersFollowing for the group in A's groupsFollowing
                                            let values = [uid: 1]
                                            lower_sync.enter()
                                            let ref = Database.database().reference().child("groupsFollowing").child(currentLoggedInUserId).child(groupId).child("membersFollowing")
                                            ref.updateChildValues(values) { (err, ref) in
                                                if let err = err {
                                                    completion(err)
                                                    return
                                                }
                                                lower_sync.leave()
                                            }
                                        }
                                    }
                                    
                                    // This is the actual following part:
                                    lower_sync.notify(queue: .main){
                                        // A follows B
                                        // Subscribe user A to B's groups that are public
                                        // Add A to the groupFollowPending for B's groups that are private with info that it was B who A followed
                                        if !following {
                                            Database.database().isInGroupRemovedUsers(groupId: groupItem.groupId, withUID: currentLoggedInUserId, completion: { (inGroupRemoved) in
                                                if !inGroupRemoved {
                                                    Database.database().isInUserRemovedGroups(groupId: groupItem.groupId, withUID: currentLoggedInUserId, completion: { (inUserRemoved) in
                                                        if !inUserRemoved {
                                                            if isPrivate{
                                                                // private group
                                                                Database.database().isInGroupFollowPending(groupId: groupItem.groupId, withUID: currentLoggedInUserId, completion: { (inGroupPending) in
                                                                    if !inGroupPending {
                                                                        Database.database().addToGroupFollowPending(groupId: groupItem.groupId, withUID: currentLoggedInUserId, autoSubscribed: true) { (err) in
                                                                            if err != nil {
                                                                                completion(err);return
                                                                            }
                                                                            // sending notification (aysnc ok)
                                                                            Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
                                                                                Database.database().fetchGroupMembers(groupId: groupItem.groupId, completion: { (members) in
                                                                                    members.forEach({ (member) in
                                                                                        if user.uid != member.uid {
                                                                                            // send notification for subscription request to all members of group
                                                                                            Database.database().createNotification(to: member, notificationType: NotificationType.groupSubscribeRequest, subjectUser: user, group: groupItem) { (err) in
                                                                                                if err != nil {
                                                                                                    return
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    })
                                                                                }) { (_) in}
                                                                            })
                                                                            sync.leave()
                                                                        }
                                                                    }
                                                                    else {
                                                                        sync.leave()
                                                                    }
                                                                }) { (err) in
                                                                    completion(err);return
                                                                }
                                                            }
                                                            else {
                                                                // public group
                                                                Database.database().addToGroupFollowers(groupId: groupItem.groupId, withUID: currentLoggedInUserId) { (err) in
                                                                    if err != nil {
                                                                        completion(err);return
                                                                    }
                                                                    Database.database().addToGroupsFollowing(groupId: groupItem.groupId, withUID: currentLoggedInUserId, autoSubscribed: true) { (err) in
                                                                        if err != nil {
                                                                            completion(err);return
                                                                        }
                                                                        Database.database().removeFromGroupFollowPending(groupId: groupItem.groupId, withUID: currentLoggedInUserId, completion: { (err) in
                                                                            if err != nil {
                                                                                completion(err);return
                                                                            }
                                                                            sync.leave()
                                                                        })
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        else {
                                                            sync.leave()
                                                        }
                                                    }) { (err) in
                                                        completion(err);return
                                                    }
                                                }
                                                else {
                                                    sync.leave()
                                                }
                                            }) { (err) in
                                                completion(err);return
                                            }
                                        }
                                        else {
                                            sync.leave()
                                        }
                                    }
                                }) { (err) in
                                    completion(err);return
                                }
                            }
                            else {
                                sync.leave()
                            }
                        }) { (err) in
                            completion(err);return
                        }
                    })
                    sync.notify(queue: .main) {
                        completion(nil)
                    }
                }, withCancel: { (err) in
                    completion(err);return
                })
            }
        }
    }
    
    func unfollowUser(withUID uid: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("following").child(currentLoggedInUserId).child(uid).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove user from following:", err)
                completion(err)
                return
            }
            
            Database.database().reference().child("followers").child(uid).child(currentLoggedInUserId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to remove user from followers:", err)
                    completion(err)
                    return
                }
                completion(nil)
                // NO LONGER DO THE FOLLOWING, INSTEAD HAVE NOTIFICATION ASKING IF SHOULD UNSUBSCRIBE
//                // nonUidGroups = now need to get all groups of currentLoggedInUser's following
//                // excluding uid following (might be overlap with uid's groups is ok)
//
//                // Go through groupsfollowing(currentLoggedInUserId) and if group in there not in nonUidGroups:
//                // Remove from that groups followers and pending, remove group from currentLoggedInUserId's groupsFollowing
//
//                Database.database().reference().child("following").child(currentLoggedInUserId).observeSingleEvent(of: .value, with: { (snapshot) in
//                    let sync = DispatchGroup()
//                    var group_ids = Set<String>()
//                    let userIdsDictionary = snapshot.value as? [String: Any]
//
//                    // then fetch all the group ids of which following users are members in and put them in group_ids
//                    userIdsDictionary?.forEach({ (arg) in
//                        let (userId, _) = arg
//
//                        if userId != uid {
//                            sync.enter()
//                            Database.database().fetchAllGroupIds(withUID: userId, completion: { (groupIds) in
//                                groupIds.forEach({ (groupId) in
//                                    if group_ids.contains(groupId) == false && groupId != "" {
//                                        group_ids.insert(groupId)
//                                    }
//                                })
//                                sync.leave()
//                            }, withCancel: { (err) in
//                                print("Failed to fetch posts:", err)
//                            })
//                        }
//                    })
//                    // run below when all the group ids have been collected
//                    sync.notify(queue: .main) {
//                        Database.database().reference().child("groupsFollowing").child(currentLoggedInUserId).observeSingleEvent(of: .value, with: { (followingSnapshot) in
//                            let groupIdsDictionary = followingSnapshot.value as? [String: Any]
//                            groupIdsDictionary?.forEach({ (arg) in
//                                let (groupId, _) = arg
//                                // group following is not in group_ids
//                                if group_ids.contains(groupId) == false && groupId != "" {
//                                    Database.database().reference().child("groupFollowPending").child(groupId).child(currentLoggedInUserId).removeValue { (err, _) in
//                                        if let err = err {
//                                            completion(err)
//                                            return
//                                        }
//                                        // remove user from group followers and from user groupsfollowing
//                                        Database.database().reference().child("groupFollowers").child(groupId).child(currentLoggedInUserId).removeValue { (err, _) in
//                                            if let err = err {
//                                                print("Failed to remove user from following:", err)
//                                                completion(err)
//                                                return
//                                            }
//                                            Database.database().reference().child("groupsFollowing").child(currentLoggedInUserId).child(groupId).removeValue { (err, _) in
//                                                if let err = err {
//                                                    print("Failed to remove user from following:", err)
//                                                    completion(err)
//                                                    return
//                                                }
//                                                completion(nil)
//                                            }
//                                        }
//                                    }
//                                }
//                                else {
//                                    completion(nil)
//                                }
//                            })
//                        })
//                    }
//                }) { (err) in
//                    print("Failed to fetch posts:", err)
//                }
                
            })
        }
    }
    
    func reportUser(withUID uid: String, completion: @escaping (Error?) -> ()) {
        guard let current_uid = Auth.auth().currentUser?.uid else { return }
        
        let values = ["uid": uid, "reportDate": Date().timeIntervalSince1970, "userReported": current_uid] as [String: Any]
        
        let userReportRef = Database.database().reference().child("reportedUsers").child(uid)
        userReportRef.updateChildValues(values) { (err, _) in
            if let err = err {
                print("Failed to report post:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func blockUser(withUID uid: String, completion: @escaping (Error?) -> ()) {
        guard let current_uid = Auth.auth().currentUser?.uid else { return }
        
        let values = ["blockDate": Date().timeIntervalSince1970] as [String: Any]
        
        let userReportRef = Database.database().reference().child("blockedUsers").child(current_uid).child(uid)
        userReportRef.updateChildValues(values) { (err, _) in
            if let err = err {
                print("Failed to report post:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func isUserBlocked(withUID blockedBy: String, completion: @escaping (Bool) -> ()) {
        guard let current_uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("blockedUsers").child(blockedBy).child(current_uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard (snapshot.value as? [String: Any]) != nil else {
                completion(false)
                return
            }
            completion(true)
        }) { (err) in
            print("Failed to fetch group from database:", err)
        }
    }
    
//--------------------------------------------------------
//------------------------ Tracking ----------------------
//--------------------------------------------------------
    
    //MARK: Tracking
    
    func openedApp(completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let values = [currentLoggedInUserId: Date().timeIntervalSince1970]
        Database.database().reference().child("lastOpenedApp").updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func userPosted(completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let values = [currentLoggedInUserId: Date().timeIntervalSince1970]
        Database.database().reference().child("lastUserHasPosted").updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
//--------------------------------------------------------
//------------------------ Groups ------------------------
//--------------------------------------------------------
    
    //MARK: GroupFetch
    
    func groupExists(groupId: String, completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("groups").child(groupId).observeSingleEvent(of: .value, with: { (snapshot) in
            guard (snapshot.value as? [String: Any]) != nil else {
                completion(false)
                return
            }
            completion(true)
        }) { (err) in
            print("Failed to fetch group from database:", err)
        }
    }
    
    func updateGroup(groupId: String, changedPrivacy: Bool, groupname: String? = nil, bio: String? = nil, isPrivate: Bool? = nil, image: UIImage? = nil, completion: @escaping (Error?) -> ()){
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        var profileImageUrl = ""
        // set the profile image url to the dictionary if there is an image
        let sync = DispatchGroup()
        sync.enter()
        if image != nil {
            Storage.storage().uploadGroupProfileImage(image: image!, completion: { (groupProfileImageUrl) in
                profileImageUrl = groupProfileImageUrl
                sync.leave()
            })
        }
        else{
            sync.leave()
        }
        sync.notify(queue: .main){
            
            // get original username
            var old_groupname = ""
            var old_bio = ""
            Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                old_groupname = group.groupname
                old_bio = group.bio
                
                // update the user with the new values
                // can't do: Database.database().reference().child("users").updateChildValues(values)
                // because it will replace everything under user so need to do each one individually
                
                let updates_sync = DispatchGroup()
                
                // update the username if not nil
                if groupname != nil && groupname != "" {
                    updates_sync.enter()
                    Database.database().groupnameExists(groupname: groupname!, completion: { (exists) in
                        if groupname! != old_groupname {
                            if !exists {
                                // send notication for name change to all group members, this can be done asynchronously
                                Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
                                    Database.database().fetchGroupMembers(groupId: groupId, completion: { (members) in
                                        members.forEach({ (member) in
                                            if user.uid != member.uid {
                                                Database.database().createNotification(to: member, notificationType: NotificationType.groupProfileNameEdit, subjectUser: user, group: group) { (err) in
                                                    if err != nil {
                                                        return
                                                    }
                                                }
                                            }
                                        })
                                    }) { (_) in}
                                })
                                
                                // update the group and groupnames in database
                                Database.database().reference().child("groups").child(groupId).updateChildValues(["groupname": groupname!], withCompletionBlock: { (err, ref) in
                                    if let err = err {
                                        print("Failed to update username in database:", err)
                                        return
                                    }
                                    // replace the groupname if there is a groupname and remove old one
                                    let values_inverted = [groupname: groupId]
                                    // delete the old groupname
                                    if old_groupname != "" {
                                        Database.database().reference().child("groupnames").child(old_groupname).removeValue(completionBlock: { (err, _) in
                                            if let err = err {
                                                print("Failed to remove groupname:", err)
                                                return
                                            }
                                            Database.database().reference().child("groupnames").updateChildValues(values_inverted, withCompletionBlock: { (err, ref) in
                                                if let err = err {
                                                    print("Failed to upload user to database:", err)
                                                    return
                                                }
                                                updates_sync.leave()
                                            })
                                        })
                                    }
                                    else {
                                        Database.database().reference().child("groupnames").updateChildValues(values_inverted, withCompletionBlock: { (err, ref) in
                                            if let err = err {
                                                print("Failed to upload user to database:", err)
                                                return
                                            }
                                            updates_sync.leave()
                                        })
                                    }
                                })
                            }
                            else {
                                updates_sync.leave()
                                let error = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "Groupname Taken"])
                                completion(error)
                                return
                            }
                            
                        }
                        else {
                            updates_sync.leave()
                        }
                    })
                }
                else {
                    // username is empty, check if same as old, if not then change
                    if old_groupname != "" {
                        // send notication for name change to all group members, this can be done asynchronously
                        Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
                           Database.database().fetchGroupMembers(groupId: groupId, completion: { (members) in
                               members.forEach({ (member) in
                                   if user.uid != member.uid {
                                       Database.database().createNotification(to: member, notificationType: NotificationType.groupProfileNameEdit, subjectUser: user, group: group) { (err) in
                                           if err != nil {
                                               return
                                           }
                                       }
                                   }
                               })
                           }) { (_) in}
                        })
                        
                        updates_sync.enter()
                        Database.database().reference().child("groups").child(groupId).updateChildValues(["groupname": ""], withCompletionBlock: { (err, ref) in
                            if let err = err {
                                print("Failed to update username in database:", err)
                                return
                            }
                            // remove the old groupname
                            Database.database().reference().child("groupnames").child(old_groupname).removeValue(completionBlock: { (err, _) in
                                if let err = err {
                                    print("Failed to remove username:", err)
                                    return
                                }
                                updates_sync.leave()
                            })
                        })
                    }
                }

                if bio != nil && bio != "" {
                    updates_sync.enter()
                    if bio! != old_bio {
                        Database.database().reference().child("groups").child(groupId).updateChildValues(["bio": bio!], withCompletionBlock: { (err, ref) in
                            if let err = err {
                                print("Failed to update bio in database:", err)
                                updates_sync.leave()
                                return
                            }
                            updates_sync.leave()
                        })
                    }
                    else {
                        updates_sync.leave()
                    }
                }
                else {
                    // username is empty, check if same as old, if not then change
                    if old_bio != "" {
                        updates_sync.enter()
                        Database.database().reference().child("groups").child(groupId).updateChildValues(["bio": ""], withCompletionBlock: { (err, ref) in
                            if let err = err {
                                print("Failed to update bio in database:", err)
                                updates_sync.leave()
                                return
                            }
                            updates_sync.leave()
                        })
                    }
                }
                
                // update isPrivate
                if changedPrivacy {
                    // send notification of privacy change to all members of group
                    Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
                        Database.database().fetchGroupMembers(groupId: groupId, completion: { (members) in
                            members.forEach({ (member) in
                                if user.uid != member.uid {
                                    Database.database().createNotification(to: member, notificationType: NotificationType.groupPrivacyChange, subjectUser: user, group: group) { (err) in
                                        if err != nil {
                                            return
                                        }
                                    }
                                }
                            })
                        }) { (_) in}
                    })
                    updates_sync.enter()
                    guard let isPrivate = isPrivate else { return }
                    if isPrivate {
                        self.convertGroupToPrivate(groupId: groupId) { (err) in
                            updates_sync.leave()
                        }
                    }
                    else {
                        self.convertGroupToPublic(groupId: groupId) { (err) in
                            updates_sync.leave()
                        }
                    }
                }
                
                if profileImageUrl != "" {
                    // send notication for name change to all group members, this can be done asynchronously
                   Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
                       Database.database().fetchGroupMembers(groupId: groupId, completion: { (members) in
                           members.forEach({ (member) in
                               if user.uid != member.uid {
                                   Database.database().createNotification(to: member, notificationType: NotificationType.groupProfilePicEdit, subjectUser: user, group: group) { (err) in
                                       if err != nil {
                                           return
                                       }
                                   }
                               }
                           })
                       }) { (_) in}
                   })
                    
                    updates_sync.enter()
                    Database.database().reference().child("groups").child(groupId).updateChildValues(["groupProfileImageUrl": profileImageUrl], withCompletionBlock: { (err, ref) in
                        if let err = err {
                            print("Failed to update name in database:", err)
                            return
                        }
                        updates_sync.leave()
                    })
                }
                updates_sync.notify(queue: .main){
                    completion(nil)
                }
            })
        }
    }
    
    func convertGroupToPrivate(groupId: String, completion: @escaping (Error?) -> ()){
        // to change a group to private just need to change the isPrivate bool string in firebase
        Database.database().reference().child("groups").child(groupId).updateChildValues(["private": "true"], withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to update username in database:", err)
                return
            }
            completion(nil)
        })
    }

    func convertGroupToPublic(groupId: String, completion: @escaping (Error?) -> ()){
        Database.database().reference().child("groups").child(groupId).updateChildValues(["private": "false"], withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to update username in database:", err)
                return
            }
            // get each user from followersPending and add them as a follower of the group
            Database.database().fetchGroupFollowersPending(groupId: groupId, completion: { (group_followers_pending) in
                if group_followers_pending.count > 0 {
                    group_followers_pending.forEach({ new_follower in
                        Database.database().addToGroupFollowers(groupId: groupId, withUID: new_follower.uid) { (err) in
                            if err != nil {
                                completion(err);return
                            }
                            Database.database().addToGroupsFollowing(groupId: groupId, withUID: new_follower.uid, autoSubscribed: false) { (err) in
                                if err != nil {
                                    completion(err);return
                                }
                                Database.database().removeFromGroupFollowPending(groupId: groupId, withUID: new_follower.uid, completion: { (err) in
                                    if err != nil {
                                        completion(err);return
                                    }
                                    completion(nil)
                                })
                            }
                        }
                    })
                }
                else {
                    completion(nil)
                }
            }) { (_) in }
        })
    }
    
    func fetchGroup(groupId: String, completion: @escaping (Group) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        let ref = Database.database().reference().child("groups").child(groupId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let groupDictionary = snapshot.value as? [String: Any] else { return }
            let group = Group(groupId: groupId, dictionary: groupDictionary)
            completion(group)
        })
    }
    
    func fetchFirstNGroupMembers(groupId: String, n: Int, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("groups").child(groupId).child("members")
        ref.queryOrderedByKey().queryLimited(toFirst: UInt(n)).observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                sync.enter()
                let userId = child.key
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                users.sort(by: { (u1, u2) -> Bool in
                    return u1.uid.compare(u2.uid) == .orderedAscending
                })
                completion(users)
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func fetchGroupMembers(groupId: String, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("groups").child(groupId).child("members")
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let userId = child.key
                sync.enter()
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                users.sort(by: { (u1, u2) -> Bool in
                    return u1.uid.compare(u2.uid) == .orderedAscending
                })
                completion(users)
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func fetchAllGroups(withUID uid: String, completion: @escaping ([Group]) -> (), withCancel cancel: ((Error) -> ())?) {
        var groupUser = uid
        if groupUser == ""{
            groupUser = (Auth.auth().currentUser?.uid)!
        }
        let ref = Database.database().reference().child("users").child(groupUser).child("groups")
        
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            
            var groups = [Group]()

            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let groupId = child.key
                sync.enter()
                self.groupExists(groupId: groupId, completion: { (exists) in
                    if exists {
                        Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                            groups.append(group)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
//            })
            }
            sync.notify(queue: .main) {
                completion(groups)
            }
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func fetchFirstGroup(withUID uid: String, completion: @escaping (Group) -> (), withCancel cancel: ((Error) -> ())?) {
        var groupUser = uid
        if groupUser == ""{
            groupUser = (Auth.auth().currentUser?.uid)!
        }
        
        let ref = Database.database().reference().child("users").child(groupUser).child("groups")
        ref.queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            var groups = [Group]()

            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let groupId = child.key
                sync.enter()
                self.groupExists(groupId: groupId, completion: { (exists) in
                    if exists {
                        Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                            groups.append(group)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
//            })
            }
            sync.notify(queue: .main) {
                if groups.count > 0 {
                    completion(groups[0])
                }
                else {
                    let error = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "No groups found"])
                    cancel?(error)
                }
            }
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func fetchGroupsFollowing(withUID uid: String, completion: @escaping ([Group]) -> (), withCancel cancel: ((Error) -> ())?) {
        var groupUser = uid
        if groupUser == ""{
            groupUser = (Auth.auth().currentUser?.uid)!
        }
        let ref = Database.database().reference().child("groupsFollowing").child(groupUser)
    
        ref.queryOrderedByValue().queryLimited(toLast: 100).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var groups = [Group]()
            let sync = DispatchGroup()
            dictionaries.forEach({ (groupId, value) in
                sync.enter()
                self.groupExists(groupId: groupId, completion: { (exists) in
                    if exists {
                        Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                            groups.append(group)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            })
            sync.notify(queue: .main) {
                completion(groups)
            }
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    // toLast will keep increasing
    func fetchGroupsFollowingDynamic(withUID uid: String, toLast: Int, completion: @escaping ([Group]) -> (), withCancel cancel: ((Error) -> ())?) {
        var groupUser = uid
        if groupUser == "" {
            groupUser = (Auth.auth().currentUser?.uid)!
        }
        let ref = Database.database().reference().child("groupsFollowing").child(groupUser)
        ref.queryOrdered(byChild: "lastPostedDate").queryLimited(toLast: UInt(toLast)).observeSingleEvent(of: .value, with: { (snapshot) in
            var groups = [Group]()
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let groupId = child.key
                print(groupId)
                sync.enter()
                self.groupExists(groupId: groupId, completion: { (exists) in
                    if exists {
                        Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                            groups.append(group)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                completion(groups)
            }
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }

    func fetchNextGroupsFollowing(withUID uid: String, endAt: Double, completion: @escaping ([Group]) -> (), withCancel cancel: ((Error) -> ())?) {
        var batch_size = 6
        if endAt == 10000000000000 { // only get 3 posts if first batch because we remove the first of batch of the rest of the batches
            batch_size -= 1
        }

        var groupUser = uid
        if groupUser == "" {
            groupUser = (Auth.auth().currentUser?.uid)!
        }
        let ref = Database.database().reference().child("groupsFollowing").child(groupUser)
        ref.queryOrdered(byChild: "lastPostedDate").queryEnding(atValue: endAt).queryLimited(toLast: UInt(batch_size)).observeSingleEvent(of: .value, with: { (snapshot) in
            var groups = [Group]()
            let sync = DispatchGroup()
            sync.enter()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let groupId = child.key
                sync.enter()
                self.groupExists(groupId: groupId, completion: { (exists) in
                    if exists {
                        Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                            groups.append(group)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.leave()
            sync.notify(queue: .main) {
                // sort the groups
                groups.sort(by: { (p1, p2) -> Bool in
                    return p1.lastPostedDate < p2.lastPostedDate
                })
                
                // for debugging
//                guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
//                for group in groups{
//                    Database.database().fetchGroupsFollowingGroupLastPostedDate(withUID: currentLoggedInUserId, groupId: group.groupId) { (date) in
//                        print(group.groupId, ", ", group.groupname, ", ", date)
//                    }
//                }
                
                if endAt != 10000000000000 && groups.count > 0 {
                    groups.remove(at: groups.count-1)
                }
                completion(groups)
            }
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func fetchGroupsFollowingGroupLastPostedDate(withUID uid: String, groupId: String, completion: @escaping (Double) -> ()) {
        Database.database().reference().child("groupsFollowing").child(uid).child(groupId).child("lastPostedDate").observeSingleEvent(of: .value) { (snapshot) in
            if let val = snapshot.value as? Double {
                completion(val)
            }
            else {
                completion(0)
            }
        }
    }
     
     func fetchAllGroupIds(withUID uid: String, completion: @escaping ([String]) -> (), withCancel cancel: ((Error) -> ())?) {
         var groupUser = uid
         if groupUser == "" {
             groupUser = (Auth.auth().currentUser?.uid)!
         }
         let ref = Database.database().reference().child("users").child(groupUser).child("groups")
         
        ref.queryOrderedByKey().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            var groups = [String]()
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let groupId = child.key
                sync.enter()
                self.groupExists(groupId: groupId, completion: { (exists) in
                    if exists{
                        groups.append(groupId)
                        sync.leave()
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                completion(groups)
            }
         }) { (err) in
             print("Failed to fetch posts:", err)
             cancel?(err)
         }
     }
    
    func fetchGroupRequestUsers(groupId: String, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("groups").child(groupId).child("requestedMembers")
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let userId = child.key
                sync.enter()
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                completion(users)
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }

    func hasGroupRequestUsers(groupId: String, completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("groups").child(groupId).child("requestedMembers").queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            completion((snapshot.children.allObjects as! [DataSnapshot]).count > 0)
        }) { (err) in
            print("Failed to check if group has requesting members in database:", err)
        }
    }
    
    func groupnameExists(groupname: String, completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("groupnames").child(groupname.replacingOccurrences(of: " ", with: "_-a-_").replacingOccurrences(of: "‘", with: "_-b-_")).observeSingleEvent(of: .value, with: { (snapshot) in
            guard (snapshot.value as? String) != nil else {
                completion(false)
                return
            }
            completion(true)
        }) { (err) in
            print("Failed to check groupname in database:", err)
        }
    }
    
    func searchForGroupWithInviteCode(invite_code: String, completion: @escaping (Group) -> ()) {
        Database.database().reference().child("inviteCodes").child(invite_code).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                return
            }
            dictionaries.forEach({ (key, value) in
                let groupid = key
                Database.database().reference().child("groups").child(groupid).observeSingleEvent(of: .value, with: { (snapshot) in
                    guard let groupDictionary = snapshot.value as? [String: Any] else { return }
                    let group = Group(groupId: groupid, dictionary: groupDictionary)
                    completion(group)
                }) { (err) in
                    print("Failed to fetch group from database:", err)
                }
                return
            })
        }) { (err) in
            print("Failed to fetch invite code from database:", err)
        }
    }
    
    // Not used anymore
    func searchForGroup(groupname: String, completion: @escaping (Group) -> ()) {
        Database.database().reference().child("groupnames").child(groupname).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let groupid = snapshot.value as? String else { return }
            Database.database().reference().child("groups").child(groupid).observeSingleEvent(of: .value, with: { (snapshot) in
                guard let groupDictionary = snapshot.value as? [String: Any] else { return }
                let group = Group(groupId: groupid, dictionary: groupDictionary)
                completion(group)
            }) { (err) in
                print("Failed to fetch group from database:", err)
            }
        }) { (err) in
            print("Failed to fetch groupname from database:", err)
        }
    }
    
    func searchForGroups(groupname: String, completion: @escaping ([Group]) -> ()) {
        Database.database().reference().child("groupnames").queryOrderedByKey().queryStarting(atValue: groupname).queryEnding(atValue: groupname + "\u{f8ff}").queryLimited(toFirst: 30).observeSingleEvent(of: .value, with: { (snapshot) in
            var groups = [Group]()
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                sync.enter()
                let groupId = child.value as! String
                self.groupExists(groupId: groupId, completion: { (exists) in
                    if exists{
                        Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                            groups.append(group)
                            sync.leave()
                        })
                    }
                    else{
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                groups.sort(by: { (p1, p2) -> Bool in
                    return p1.groupname < p2.groupname
                })
                completion(groups)
                return
            }
        }) { (err) in
            print("Failed to fetch groupname from database:", err)
        }
    }
    
    //MARK: GroupMembership
    func isInGroup(groupId: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(currentLoggedInUserId).child("groups").child(groupId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let isIn = snapshot.value as? Int, isIn == 1 {
                completion(true)
            } else {
                ref.child("hidden").observeSingleEvent(of: .value, with: { (snapshot) in
                    completion(snapshot.value as? String != nil)
                }) { (err) in
                    print("Failed to check if following:", err)
                    cancel?(err)
                }
            }
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func isGroupHiddenForUser(withUID uid: String, groupId: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("users").child(uid).child("groups").child(groupId).child("hidden")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let isHidden = snapshot.value as? String, isHidden == "true" {
                completion(true)
            } else {
                completion(false)
            }
        }) { (err) in
            print("Failed to check if is visible:", err)
            cancel?(err)
        }
    }
    
    func isGroupHiddenOnProfile(groupId: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("users").child(currentLoggedInUserId).child("groups").child(groupId).child("hidden")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let isHidden = snapshot.value as? String, isHidden == "true" {
                completion(true)
            } else {
                completion(false)
            }
        }) { (err) in
            print("Failed to check if is visible:", err)
            cancel?(err)
        }
    }
    
    func setGroupVisibleOnProfile(groupId: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("users").child(currentLoggedInUserId).child("groups").child(groupId).updateChildValues(["hidden": "false"], withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to update users group in database:", err)
                return
            }
            completion(nil)
        })
    }
    
    // value of 0 means group is hidden
    // this might not be good because so other thing in database is opposite (has 1 as hidden) but I forget which one it was
    func setGroupHiddenOnProfile(groupId: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("users").child(currentLoggedInUserId).child("groups").child(groupId).updateChildValues(["hidden":
            "true"], withCompletionBlock: { (err, ref) in
            if let err = err {
                print("Failed to update users group in database:", err)
                return
            }
            completion(nil)
        })
    }
    
    func canViewGroupPosts(groupId: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        self.groupExists(groupId: groupId, completion: { (exists) in
            if exists {
                Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                    let isPrivate = group.isPrivate
                    Database.database().isFollowingGroup(groupId: groupId, completion: { (following) in
                        Database.database().isInGroup(groupId: groupId, completion: { (inGroup) in
                            if isPrivate! && !following && !inGroup {
                                completion(false)
                                return
                            }
                            else {
                                completion(true)
                                return
                            }
                        }) { (err) in
                            return
                        }
                    }) { (err) in
                        cancel?(err)
                    }
                })
            }
            else {
                completion(false)
                return
            }
        })
    }
    
    func createGroup(groupname: String?, bio: String?, image: UIImage?, isPrivate: Bool, selectedSchool: String, completion: @escaping (Error?,String) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var userGroupRef: DatabaseReference?
        let isPrivateString = isPrivate ? "true" : "false"
        
        var values = ["creationDate": Date().timeIntervalSince1970, "private": isPrivateString, "lastPostedDate": 0, "selectedSchool": selectedSchool] as [String : Any]
        let sync = DispatchGroup()
        // set the groupname if it exists
        if groupname != nil && groupname != "" {
            sync.enter()
            Database.database().groupnameExists(groupname: groupname!, completion: { (exists) in
                if !exists{
                    userGroupRef = Database.database().reference().child("groups").childByAutoId()
                    guard let groupId = userGroupRef?.key else { return }
                    
                    values["id"] = groupId
                    values["groupname"] = groupname!
                    
                    // create the entree in database for groupnames
                    let groupname_value = [groupname: groupId]
                    Database.database().reference().child("groupnames").updateChildValues(groupname_value, withCompletionBlock: { (err, ref) in
                        if let err = err {
                            print("Failed to upload user to database:", err)
                            return
                        }
                        sync.leave()
                    })
                }
                else {
                    let error = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "Groupname Taken"])
                    completion(error, "")
                    sync.leave()
                    return
                }
            })
        }
        else {
            userGroupRef = Database.database().reference().child("groups").childByAutoId()
        }
            
        if bio != nil && bio != "" {
            values["bio"] = bio!
        }
            
        sync.enter()
        if image != nil && image != UIImage() {
            Storage.storage().uploadGroupProfileImage(image: image!, completion: { (groupProfileImageUrl) in
                values["groupProfileImageUrl"] = groupProfileImageUrl
                values["imageWidth"] = image!.size.width
                values["imageHeight"] = image!.size.height
                sync.leave()
            })
        }
        else {
            sync.leave()
        }
                
        sync.notify(queue: .main) {
            guard let userGroupRef = userGroupRef else { return }
            guard let groupId = userGroupRef.key else { return }
            userGroupRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Failed to save post to database", err)
                    completion(err, "")
                    return
                }
                
                // group has now been created, do whatever with it now
                // cloud function connects to when groups/groupId is created or changed and subscribes all the user's followers
                
                // connect user to group as a member
                // add uid to group
                let values = [uid: 1]
                Database.database().reference().child("groups").child(groupId).child("members").updateChildValues(values) { (err, ref) in
                    if let err = err {
                        completion(err, "")
                        return
                    }
                    // add groupId to user
                    let values = [groupId: 1]
                    Database.database().reference().child("users").child(uid).child("groups").updateChildValues(values) { (err, ref) in
                        if let err = err {
                            completion(err, "")
                            return
                        }
                        
                        // add groupId to schools
                        if selectedSchool != "" {
                            let values = [groupId: Date().timeIntervalSince1970]
                            Database.database().reference().child("schools").child(selectedSchool).child("groups").updateChildValues(values) { (err, ref) in
                                if let err = err {
                                    completion(err, "")
                                    return
                                }
                                
                                // add groupId to schools
                                
                                // add invitation code with groupId as value
                                // increment value under groupId when user signs up with it until gets to 100 users
                                // ^^ but do this later
                                let values = [groupId: 1]
                                let code = String(groupId.suffix(6))
                                let stripped_code = code.replacingOccurrences(of: "_", with: "a", options: .literal, range: nil)
                                let stripped_code2 = stripped_code.replacingOccurrences(of: "-", with: "b", options: .literal, range: nil)
                                let invitationRef = Database.database().reference().child("inviteCodes").child(stripped_code2)
                                invitationRef.updateChildValues(values) { (err, ref) in
                                    if let err = err {
                                        completion(err, "")
                                        return
                                    }
                                    completion(nil,groupId)
                                }
                            }
                        }
                        else {
                            let values = [groupId: 1]
                            let code = String(groupId.suffix(6))
                            let stripped_code = code.replacingOccurrences(of: "_", with: "a", options: .literal, range: nil)
                            let stripped_code2 = stripped_code.replacingOccurrences(of: "-", with: "b", options: .literal, range: nil)
                            let invitationRef = Database.database().reference().child("inviteCodes").child(stripped_code2)
                            invitationRef.updateChildValues(values) { (err, ref) in
                                if let err = err {
                                    completion(err, "")
                                    return
                                }
                                completion(nil,groupId)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func joinGroup(groupId: String, completion: @escaping (Error?) -> ()) {
        // added to requested of the group
        // add group to requested of user
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let values = [uid: 1]
        Database.database().reference().child("groups").child(groupId).child("requestedMembers").updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            
            // add groupId to user
            let values = [groupId: 1]
            Database.database().reference().child("users").child(uid).child("requestedGroups").updateChildValues(values) { (err, ref) in
                if let err = err {
                    completion(err)
                    return
                }
                completion(nil)
            }
        }
    }
    
    func addUserToGroupInvited(withUID uid: String, groupId: String, completion: @escaping (Error?) -> ()) {
        let values = [groupId: 1]
        Database.database().reference().child("groupInvitationsForUsers").child(uid).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            let group_values = [uid: 1]
            Database.database().reference().child("groupInvitations").child(groupId).updateChildValues(group_values) { (err, ref) in
                if let err = err {
                    completion(err)
                    return
                }
                completion(nil)
            }
        }
    }
    
    // add contacts to invitedContactsForGroup and invitedContacts
    // invitedContactsForGroup is group: number
    // invitedContacts is number: groups invited to
    func inviteContact(contact: Contact, group: Group, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let number = contact.selected_phone_number else { return }
        
        let phoneNumberKit = PhoneNumberKit()
        do {
            let phoneNumber = try phoneNumberKit.parse(number.value.stringValue)
            let numberString = phoneNumberKit.format(phoneNumber, toType: .e164)
            
            var full_name = ""
            if contact.given_name != "" {
                full_name += contact.given_name
            }
            if contact.family_name != "" {
                full_name += " "
                full_name += contact.family_name
            }
            
            let invitedContactsForGroupValue = [numberString: full_name] as [String : Any]
            let invitedContactsValue = ["invitedBy": currentLoggedInUserId, "twilioNumber": "0"] as [String : Any]
            Database.database().doesNumberExist(number: numberString, completion: { (exists) in
                if exists {
                    Database.database().fetchUserIdFromNumber(number: numberString, completion: { (userId) in
                        self.userExists(withUID: userId, completion: { (exists) in
                            if exists{
                                Database.database().fetchUser(withUID: userId, completion: { (user) in
                                    Database.database().createNotification(to: user, notificationType: NotificationType.groupJoinInvitation, group: group) { (err) in
                                        if err != nil {
                                            completion(err)
                                            return
                                        }
                                        Database.database().addUserToGroupInvited(withUID: user.uid, groupId: group.groupId) { (err) in
                                            if err != nil {
                                                completion(err)
                                                return
                                            }
                                            completion(nil)
                                        }
                                    }
                                })
                            }
                        })
                    })
                }
                else {
                    Database.database().reference().child("invitedContactsForGroup").child(group.groupId).updateChildValues(invitedContactsForGroupValue) { (err, ref) in
                        if let err = err {
                            completion(err)
                            return
                        }
                        Database.database().reference().child("invitedContacts").child(numberString).child(group.groupId).updateChildValues(invitedContactsValue) { (err, ref) in
                            if let err = err {
                                completion(err)
                                return
                            }
                            completion(nil)
                        }
                    }
                }
            }) { (err) in return}
            
        }
        catch {
            let error = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "Phone number not valid"])
            completion(error)
            return
        }
    }
    
    func removeNumberFromInvited(number: String, completion: @escaping (Error?) -> ()) {
        // first fetch all of the groups from invitedContacts, and remove user from them
        let ref = Database.database().reference().child("invitedContacts").child(number)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let sync = DispatchGroup()
            sync.enter()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let groupId = child.key
                sync.enter()
                Database.database().removeNumberFromInvitedContactsForGroup(number: number, groupId: groupId) { (err) in
                    if err != nil {
                        return
                    }
                    sync.leave()
                }
            }
            sync.leave()
            sync.notify(queue: .main) {
                Database.database().removeNumberFromInvitedContacts(number: number) { (err) in
                    if err != nil {
                        return
                    }
                    completion(nil)
                }
            }
        })
    }
    
    func doesNumberExist(number: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        Database.database().reference().child("numbers").child(number).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func fetchUserIdFromNumber(number: String, completion: @escaping (String) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        let ref = Database.database().reference().child("numbers").child(number)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let uid = snapshot.value as? String else { return }
            completion(uid)
        })
    }
    
    //  number should already be formatted when it gets here
    func addNumberToNumbers(number: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let values = [number: currentLoggedInUserId] as [String : Any]
        Database.database().reference().child("numbers").updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func isNumberInvitedToAGroup(number: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        Database.database().reference().child("invitedContacts").child(number).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func fetchFirstGroupNumberIsInvitedTo(number: String, completion: @escaping (Group) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        let ref = Database.database().reference().child("invitedContacts").child(number)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let groupId = child.key
                Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                    completion(group)
                    return
                })
            }
        })
    }
    
    func fetchInvitedBy(number: String, groupId: String, completion: @escaping (User) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        let ref = Database.database().reference().child("invitedContacts").child(number).child(groupId).child("invitedBy")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let invited_by_id = snapshot.value as? String {
                self.userExists(withUID: invited_by_id, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: invited_by_id, completion: { (user) in
                            completion(user)
                        })
                    }
                })
            }
        })
    }

    //  number should already be formatted when it gets here
    func addNumberToGroupsInvited(number: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        // first fetch all of the groups from invitedContacts, and remove user from them
        let ref = Database.database().reference().child("invitedContacts").child(number)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let sync = DispatchGroup()
            sync.enter()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let groupId = child.key
                sync.enter()
                
                // check if user is already in group (through group invite code)
                Database.database().isInGroup(groupId: groupId, completion: { (inGroup) in
                    // check if user is a member of the group, if so then auto accept follow
                    if inGroup {
                        sync.leave()
                    }
                    else {
                        Database.database().acceptIntoGroup(withUID: currentLoggedInUserId, groupId: groupId){ (err) in
                            if err != nil {
                                return
                            }
                            sync.leave()
                            
                            // notification that member is now in group
                            Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
                                Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                                    Database.database().fetchGroupMembers(groupId: groupId, completion: { (members) in
                                        members.forEach({ (member) in
                                            if member.uid != currentLoggedInUserId {
                                                Database.database().createNotification(to: member, notificationType: NotificationType.newGroupJoin, subjectUser: user, group: group) { (err) in
                                                    if err != nil {
                                                        return
                                                    }
                                                }
                                            }
                                        })
                                    }) { (_) in}
                                })
                            })
                            
                        }
                    }
                }) { (err) in
                    return
                }
            }
            sync.leave()
            sync.notify(queue: .main) {
                completion(nil)
            }
        })
    }
    
//    let invitedContactsForGroupValue = [numberString: 1] as [String : Any]
//    let invitedContactsValue = ["invitedBy": currentLoggedInUserId, "twilioNumber": "0"] as [String : Any]
//    Database.database().reference().child("invitedContactsForGroup").child(group.groupId).updateChildValues(invitedContactsForGroupValue) { (err, ref) in
//        if let err = err {
//            completion(err)
//            return
//        }
//        Database.database().reference().child("invitedContacts").child(numberString).child(group.groupId).updateChildValues(invitedContactsValue) { (err, ref) in
//            if let err = err {
//                completion(err)
//                return
//            }
//            completion(nil)
//        }
//    }
    
    func fetchUsersInvitedToGroup(groupId: String, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("groupInvitations").child(groupId)
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let userId = child.key
                sync.enter()
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                users.sort(by: { (u1, u2) -> Bool in
                    return u1.uid.compare(u2.uid) == .orderedAscending
                })
                completion(users)
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
        
    func isUserInvitedToGroup(withUID uid: String, groupId: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("groupInvitationsForUsers").child(currentLoggedInUserId).child(groupId).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func removeFromGroupInvited(withUID uid: String, groupId: String, completion: @escaping (Error?) -> ()) {
        Database.database().reference().child("groupInvitationsForUsers").child(uid).child(groupId).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove user from following:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }

    func fetchInvitedContactsForGroup(groupId: String, completion: @escaping ([Contact]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("invitedContactsForGroup").child(groupId)
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var contacts = [Contact]()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let number = child.key
                let name = child.value as! String
                let contact = Contact(contact:CNContact(), phone_string: number, full_name: name)
                contacts.append(contact)
            }
            completion(contacts)
        }) { (err) in
            print("Failed to fetch all contacts from database:", (err))
            cancel?(err)
        }
    }
    
    func removeNumberFromInvitedContactsForGroup(number: String, groupId: String, completion: @escaping (Error?) -> ()) {
        Database.database().reference().child("invitedContactsForGroup").child(groupId).child(number).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove number from following:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func removeNumberFromInvitedContacts(number: String, completion: @escaping (Error?) -> ()) {
        Database.database().reference().child("invitedContacts").child(number).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove number from following:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func acceptIntoGroup(withUID uid: String, groupId: String, completion: @escaping (Error?) -> ()) {
        // add to members and add group to groups of user
        // remove user from requested and remove group from requested of users
        let values = [uid: 1]
        Database.database().reference().child("groups").child(groupId).child("members").updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            
            // add groupId to user
            let values = [groupId: 1]
            Database.database().reference().child("users").child(uid).child("groups").updateChildValues(values) { (err, ref) in
                if let err = err {
                    completion(err)
                    return
                }
                
                // remove user from requestedMembers of group
                Database.database().reference().child("groups").child(groupId).child("requestedMembers").child(uid).removeValue { (err, _) in
                    if let err = err {
                        print("Failed to remove user from following:", err)
                        completion(err)
                        return
                    }
                    
                    // remove group from requestedGroups of user
                    Database.database().reference().child("users").child(uid).child("requestedGroups").child(groupId).removeValue(completionBlock: { (err, _) in
                        if let err = err {
                            print("Failed to remove user from followers:", err)
                            completion(err)
                            return
                        }

                        // auto subscribe user to group
                        Database.database().addToGroupFollowers(groupId: groupId, withUID: uid) { (err) in
                            if err != nil {
                                completion(err);return
                            }
                            Database.database().addToGroupsFollowing(groupId: groupId, withUID: uid, autoSubscribed: false) { (err) in
                                if err != nil {
                                    completion(err);return
                                }
                                // moved to cloud function inside function "transferToMembersFollowingOnSubscribe"
                                Database.database().removeFromGroupFollowPending(groupId: groupId, withUID: uid, completion: { (err) in
                                    if err != nil {
                                        completion(err);return
                                    }
                                    Database.database().fetchSchoolOfGroup(group: groupId, completion: { (school) in
                                        if school != "" {
                                            let formatted_school = school.replacingOccurrences(of: " ", with: "_-a-_").replacingOccurrences(of: "_-b-_", with: "‘")
                                            Database.database().addUserToSchool(withUID: uid, selectedSchool: formatted_school) { (err) in
                                                if err != nil {
                                                   return
                                                }
                                                Database.database().addSchoolToUser(withUID: uid, selectedSchool: formatted_school) { (err) in }
                                            }
                                        }
                                    }) { (_) in}
                                    completion(nil)
                                })
                            }
                        }
                    })
                }
            }
        }
    }
    
    func denyFromGroup(withUID uid: String, groupId: String, completion: @escaping (Error?) -> ()) {
        // remove user from requested
        // remove group from requested of user
        
        // remove user from requestedMembers of group
        Database.database().reference().child("groups").child(groupId).child("requestedMembers").child(uid).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove user from following:", err)
                completion(err)
                return
            }
            
            // remove group from requestedGroups of user
            Database.database().reference().child("users").child(uid).child("requestedGroups").child(groupId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to remove user from followers:", err)
                    completion(err)
                    return
                }
                completion(nil)
            })
        }
    }
    
    func leaveGroup(groupId: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // remove user from members of group
        Database.database().reference().child("groups").child(groupId).child("members").child(uid).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove user from following:", err)
                completion(err)
                return
            }
            // remove group from groups of user
            Database.database().reference().child("users").child(uid).child("groups").child(groupId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to remove user from followers:", err)
                    completion(err)
                    return
                }
                completion(nil)
                // old and commented out:
                // When leave group G, unsubscribe all subscribers who's only tie to the group is the member leaving
                // for each follower
                //      group_ids = []
                //      for each user that the follower is following that isn't the member leaving the group
                //          get all their groups and add them to group_ids
                //      if group G not in group_ids ***** [this means that the member leaving was the only tie to the group] ******
                //          remove user from group G's follow pending, group followers, and group following
                
                // This is expensive and I don't want to automatically make the users unfollow,
                // instead a notification would be better saying that the user left the group and if you wish to unsubscribe
                // Would only send the notification if the user that left is the only tie to the group
                // For each user that is following leaving member:
                //      for each member in group:
                //          check if member is in user's folloing
                //      if user doesn't follow any other members in the group, send notification
                
                // For now just don't do anything when a member leaves a group
//                Database.database().reference().child("followers").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
//                    let upper_sync = DispatchGroup()
//                    let followersIdsDictionary = snapshot.value as? [String: Any]
//                    followersIdsDictionary?.forEach({ (arg) in
//                        upper_sync.enter()
//                        let (followerId, _) = arg
//                        self.userExists(withUID: followerId, completion: { (follower_exists) in
//                            if follower_exists{
//                                Database.database().reference().child("following").child(followerId).observeSingleEvent(of: .value, with: { (snapshot) in
//                                    let sync = DispatchGroup()
//                                    var group_ids = Set<String>()
//                                    let userIdsDictionary = snapshot.value as? [String: Any]
//
//                                    // then fetch all the group ids of which following users are members in and put them in group_ids
//                                    userIdsDictionary?.forEach({ (arg) in
//                                        sync.enter()
//                                        let (userId, _) = arg
//                                        self.userExists(withUID: followerId, completion: { (following_exists) in
//                                            if following_exists {
//                                                if userId != uid {
//                                                    Database.database().fetchAllGroupIds(withUID: userId, completion: { (groupIds) in
//                                                        groupIds.forEach({ (groupId) in
//                                                            if group_ids.contains(groupId) == false && groupId != "" {
//                                                                group_ids.insert(groupId)
//                                                            }
//                                                        })
//                                                        sync.leave()
//                                                    }, withCancel: { (err) in
//                                                        print("Failed to fetch posts:", err)
//                                                    })
//                                                }
//                                                else {
//                                                    sync.leave()
//                                                }
//                                            }
//                                            else{
//                                                sync.leave()
//                                            }
//                                        })
//                                    })
//                                    // run below when all the group ids have been collected
//                                    sync.notify(queue: .main) {
//                                        // group following is not in group_ids
//                                        if group_ids.contains(groupId) == false && groupId != "" {
//                                            Database.database().reference().child("groupFollowPending").child(groupId).child(followerId).removeValue { (err, _) in
//                                                if let err = err {
//                                                    completion(err)
//                                                    return
//                                                }
//                                                // remove user from group followers and from user groupsfollowing
//                                                Database.database().reference().child("groupFollowers").child(groupId).child(followerId).removeValue { (err, _) in
//                                                    if let err = err {
//                                                        print("Failed to remove user from following:", err)
//                                                        completion(err)
//                                                        return
//                                                    }
//                                                    Database.database().reference().child("groupsFollowing").child(followerId).child(groupId).removeValue { (err, _) in
//                                                        if let err = err {
//                                                            print("Failed to remove user from following:", err)
//                                                            completion(err)
//                                                            return
//                                                        }
//                                                    }
//                                                }
//                                            }
//                                        }
//                                        upper_sync.leave()
//                                        print("upper leave")
//                                    }
//                                }) { (err) in
//                                    print("Failed to fetch posts:", err)
//                                }
//                            }
//                            else{
//                                upper_sync.leave()
//                                print("upper leave")
//                            }
//                        })
//                    })
//                    upper_sync.notify(queue: .main) {
//                        completion(nil)
//                    }
//                }) { (err) in
//                    print("Failed to fetch posts:", err)
//                }
            })
        }
    }
    
    func removeFromGroup(withUID uid: String, groupId: String, completion: @escaping (Error?) -> ()) {
        Database.database().reference().child("groups").child(groupId).child("members").child(uid).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove user from following:", err)
                completion(err)
                return
            }
            
            // remove group from groups of user
            Database.database().reference().child("users").child(uid).child("groups").child(groupId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to remove user from followers:", err)
                    completion(err)
                    return
                }
                completion(nil)
//                Database.database().reference().child("followers").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
//                    let upper_sync = DispatchGroup()
//                    let followersIdsDictionary = snapshot.value as? [String: Any]
//                    followersIdsDictionary?.forEach({ (arg) in
//                        upper_sync.enter()
//                        let (followerId, _) = arg
//                        Database.database().reference().child("following").child(followerId).observeSingleEvent(of: .value, with: { (snapshot) in
//                            let sync = DispatchGroup()
//                            var group_ids = Set<String>()
//                            let userIdsDictionary = snapshot.value as? [String: Any]
//
//                            // then fetch all the group ids of which following users are members in and put them in group_ids
//                            userIdsDictionary?.forEach({ (arg) in
//                                let (userId, _) = arg
//
//                                if userId != uid {
//                                    sync.enter()
//                                    Database.database().fetchAllGroupIds(withUID: userId, completion: { (groupIds) in
//                                        groupIds.forEach({ (groupId) in
//                                            if group_ids.contains(groupId) == false && groupId != "" {
//                                                group_ids.insert(groupId)
//                                            }
//                                        })
//                                        sync.leave()
//                                    }, withCancel: { (err) in
//                                        print("Failed to fetch posts:", err)
//                                    })
//                                }
//                            })
//                            // run below when all the group ids have been collected
//                            sync.notify(queue: .main) {
//                                // group following is not in group_ids
//                                if group_ids.contains(groupId) == false && groupId != "" {
//                                    Database.database().reference().child("groupFollowPending").child(groupId).child(followerId).removeValue { (err, _) in
//                                        if let err = err {
//                                            completion(err)
//                                            return
//                                        }
//                                        // remove user from group followers and from user groupsfollowing
//                                        Database.database().reference().child("groupFollowers").child(groupId).child(followerId).removeValue { (err, _) in
//                                            if let err = err {
//                                                print("Failed to remove user from following:", err)
//                                                completion(err)
//                                                return
//                                            }
//                                            Database.database().reference().child("groupsFollowing").child(followerId).child(groupId).removeValue { (err, _) in
//                                                if let err = err {
//                                                    print("Failed to remove user from following:", err)
//                                                    completion(err)
//                                                    return
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                                upper_sync.leave()
//                            }
//                        }) { (err) in
//                            print("Failed to fetch posts:", err)
//                        }
//                        upper_sync.notify(queue: .main) {
//                            completion(nil)
//                        }
//                    })
//                }) { (err) in
//                    print("Failed to fetch posts:", err)
//                }
            })
        }
    }
    
    func cancelJoinRequest(groupId: String, completion: @escaping (Error?) -> ()) {
        // remove user from requested
        // remove group from requested of user
        
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        // remove user from requestedMembers of group
        Database.database().reference().child("groups").child(groupId).child("requestedMembers").child(currentLoggedInUserId).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove user from following:", err)
                completion(err)
                return
            }
            
            // remove group from requestedGroups of user
            Database.database().reference().child("users").child(currentLoggedInUserId).child("requestedGroups").child(groupId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to remove user from followers:", err)
                    completion(err)
                    return
                }
                completion(nil)
            })
        }
    }
    
    func hasRequestedGroup(groupId: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("users").child(currentLoggedInUserId).child("requestedGroups").child(groupId).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    //MARK: School
    
    func addUserToSchool(withUID uid: String, selectedSchool: String, completion: @escaping (Error?) -> ()) {
        let values = [uid: Date().timeIntervalSince1970]
        Database.database().reference().child("schools").child(selectedSchool).child("users").updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func addSchoolToUser(withUID uid: String, selectedSchool: String, completion: @escaping (Error?) -> ()) {
        let values = ["school": selectedSchool]
        Database.database().reference().child("users").child(uid).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func fetchSchoolCode(school: String, completion: @escaping (String) -> (), withCancel cancel: ((Error) -> ())?) {
        Database.database().reference().child("schools").child(school).child("schoolCode").observeSingleEvent(of: .value) { (snapshot) in
            if let val = snapshot.value as? String {
                completion(val)
            }
            else {
                completion("")
            }
        }
    }
    
    func fetchSchoolGroups(school: String, completion: @escaping ([Group]) -> (), withCancel cancel: ((Error) -> ())?) {
        
        let selectedSchool = school.replacingOccurrences(of: " ", with: "_-a-_").replacingOccurrences(of: "_-b-_", with: "‘")
        let ref = Database.database().reference().child("schools").child(selectedSchool).child("groups")
        
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var groups = [Group]()

            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let groupId = child.key
                sync.enter()
                print(groupId)
                self.groupExists(groupId: groupId, completion: { (exists) in
                    if exists {
                        Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                            groups.append(group)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                completion(groups)
            }
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func fetchSchoolMembers(school: String, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("schools").child(school).child("users")
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let userId = child.key
                sync.enter()
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                users.sort(by: { (u1, u2) -> Bool in
                    return u1.uid.compare(u2.uid) == .orderedAscending
                })
                completion(users)
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func fetchTemplateMembers(completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("template").child("users")
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let userId = child.key
                sync.enter()
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                users.sort(by: { (u1, u2) -> Bool in
                    return u1.uid.compare(u2.uid) == .orderedAscending
                })
                completion(users)
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func fetchTemplateGroups(completion: @escaping ([Group]) -> (), withCancel cancel: ((Error) -> ())?) {
        
        let ref = Database.database().reference().child("template").child("groups")
        
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var groups = [Group]()

            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let groupId = child.key
                sync.enter()
                print(groupId)
                self.groupExists(groupId: groupId, completion: { (exists) in
                    if exists {
                        Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                            groups.append(group)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                completion(groups)
            }
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func fetchSchoolOfGroup(group: String, completion: @escaping (String) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("groups").child(group).child("selectedSchool")
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            if let val = snapshot.value as? String {
                completion(val)
            }
            else {
                completion("")
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }

    func fetchSchoolOfUser(uid: String, completion: @escaping (String) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("users").child(uid).child("school")
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            if let val = snapshot.value as? String {
                completion(val)
            }
            else {
                completion("")
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func fetchSchoolPromoPayout(school: String, completion: @escaping (Int) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("promos").child(school).child("currentInstaPayout")
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            if let val = snapshot.value as? Int {
                completion(val)
            }
            else {
                completion(-1)
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func isPromoActive(school: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        Database.database().reference().child("promos").child(school).child("isActive").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(snapshot.value as! Bool)
                }
            } else {
                completion(false)
            }
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func hasUserDonePromo(school: String, username: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        Database.database().reference().child("promos").child(school).child("postedToInsta").child(username).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func isTemplateActive(school: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        Database.database().reference().child("schools").child(school).child("useTemplate").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(snapshot.value as! Bool)
                }
            } else {
                completion(false)
            }
        }) { (err) in
            print("Failed to check if template is active:", err)
            cancel?(err)
        }
    }
    
    func hideIfNoGroups(school: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        Database.database().reference().child("schools").child(school).child("hideIfNoGroups").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(snapshot.value as! Bool)
                }
            } else {
                completion(false)
            }
        }) { (err) in
            print("Failed to check if template is active:", err)
            cancel?(err)
        }
    }
    
    func blockPromoForUser(school: String, uid: String, completion: @escaping (Error?) -> ()) {
        let values = [uid: 1]
        Database.database().reference().child("blockedPromos").child(school).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func isPromoBlockedForUser(school: String, uid: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        Database.database().reference().child("blockedPromos").child(school).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func userHasSeenPromoPage(school: String, uid: String, completion: @escaping (Error?) -> ()) {
        let values = [uid: 1]
        Database.database().reference().child("seenPromoPage").child(school).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func hasUserSeenPromoPage(school: String, uid: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        Database.database().reference().child("seenPromoPage").child(school).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    //MARK: GroupFollowers
    
    func isFollowingGroup(groupId: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        // other one is called groupFollowers
        Database.database().reference().child("groupsFollowing").child(currentLoggedInUserId).child(groupId).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func isInGroupRemovedUsers(groupId: String, withUID uid: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        // groupRemoved is group that have removed followers
        Database.database().reference().child("groupRemovedUsers").child(groupId).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let isRemoved = snapshot.value as? Int, isRemoved == 1 {
                completion(true)
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if in removed:", err)
            cancel?(err)
        }
    }
    
    func isInUserRemovedGroups(groupId: String, withUID uid: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        // groupRemoved is group that have removed followers
        Database.database().reference().child("userRemovedGroups").child(uid).child(groupId).observeSingleEvent(of: .value, with: { (snapshot) in
            if let isRemoved = snapshot.value as? Int, isRemoved == 1 {
                completion(true)
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if in removed:", err)
            cancel?(err)
        }
    }
    
    func isInGroupFollowPending(groupId: String, withUID uid: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        // groupRemoved is group that have removed followers
        Database.database().reference().child("groupFollowPending").child(groupId).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if follow pending:", err)
            cancel?(err)
        }
    }
    
    func checkIfAutoSubscribed(groupId: String, withUID uid: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        Database.database().reference().child("groupsFollowing").child(uid).child(groupId).child("autoSubscribed").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    if let is_auto_subscribed = snapshot.value as? String, is_auto_subscribed == "true" {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
            
        }) { (err) in
            print("Failed to check if auto subscribed:", err)
            cancel?(err)
        }
    }
    
//    func checkIfAutoSubscribedInGroupFollowPending(groupId: String, withUID uid: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
//        Database.database().reference().child("groupFollowPending").child(groupId).child(uid).child("autoSubscribed").observeSingleEvent(of: .value, with: { (snapshot) in
//            if snapshot.value != nil {
//                if snapshot.value! is NSNull {
//                    print("false 1")
//                    completion(false)
//                }
//                else {
//                    if let is_auto_subscribed = snapshot.value as? String, is_auto_subscribed == "true" {
//                        completion(true)
//                    } else {
//                        completion(false)
//                    }
//                }
//            } else {
//                completion(false)
//                print("false 3")
//            }
//
//        }) { (err) in
//            print("Failed to check if auto subscribed:", err)
//            cancel?(err)
//        }
//    }
    
    func fetchMembersFollowingForSubscription(groupId: String, withUID uid: String, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("groupsFollowing").child(uid).child(groupId).child("membersFollowing")
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
                        
            var users = [User]()
            
            let sync = DispatchGroup()
            dictionaries.forEach({ (arg) in
                sync.enter()
                let (userId, _) = arg
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else{
                        sync.leave()
                    }
                })
            })
            sync.notify(queue: .main) {
                completion(users)
                return
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    // this is for a private group when the user is acceped to follow
    // removing form groupFollowPending inside a cloud function
    func acceptSubscriptionToPrivateGroup(withUID uid: String, groupId: String, completion: @escaping (Error?) -> ()) {
        Database.database().addToGroupFollowers(groupId: groupId, withUID: uid) { (err) in
            if err != nil {
                return
            }
            // autoSubscribed okay as false because set correctly in cloud function, just need placeholder here
            Database.database().addToGroupsFollowing(groupId: groupId, withUID: uid, autoSubscribed: false) { (err) in
                if err != nil {
                    return
                }
                // notification to refresh
                completion(nil)
            }
        }
    }
    
    // this is called when the user presses a button to subscribe, more like a request to subscribe to group
    func subscribeToGroup(groupId: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        self.groupExists(groupId: groupId, completion: { (exists) in
            if exists {
                Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                    let isPrivate = group.isPrivate
                    if isPrivate == nil { return }
                    Database.database().isFollowingGroup(groupId: groupId, completion: { (following) in
                        if !following {
                            Database.database().isInGroupRemovedUsers(groupId: groupId, withUID: currentLoggedInUserId, completion: { (inGroupRemoved) in
                                if !inGroupRemoved {
                                    Database.database().removeGroupFromUserRemovedGroups(withUID: currentLoggedInUserId, groupId: groupId) { (err) in
                                        if err != nil {
                                            completion(err);return
                                        }
                                        if isPrivate!{
                                            // private group
                                            Database.database().isInGroup(groupId: groupId, completion: { (inGroup) in
                                                // check if user is a member of the group, if so then auto accept follow
                                                if inGroup {
                                                    Database.database().addToGroupFollowers(groupId: groupId, withUID: currentLoggedInUserId) { (err) in
                                                        if err != nil {
                                                            completion(err);return
                                                        }
                                                        Database.database().addToGroupsFollowing(groupId: groupId, withUID: currentLoggedInUserId, autoSubscribed: false) { (err) in
                                                            if err != nil {
                                                                completion(err);return
                                                            }
                                                            Database.database().removeFromGroupFollowPending(groupId: groupId, withUID: currentLoggedInUserId, completion: { (err) in
                                                                if err != nil {
                                                                    completion(err);return
                                                                }
                                                                completion(nil)
                                                            })
                                                        }
                                                    }
                                                }
                                                else {
                                                    Database.database().isInGroupFollowPending(groupId: groupId, withUID: currentLoggedInUserId, completion: { (inGroupPending) in
                                                        if !inGroupPending {
                                                            Database.database().addToGroupFollowPending(groupId: groupId, withUID: currentLoggedInUserId, autoSubscribed: false) { (err) in
                                                                if err != nil {
                                                                    completion(err);return
                                                                }
                                                                completion(nil)
                                                                print("pending sent")
                                                            }
                                                        }
                                                    }) { (err) in
                                                        completion(err);return
                                                    }
                                                }
                                            }) { (err) in
                                                return
                                            }
                                        }
                                        else {
                                            // public group
                                            Database.database().addToGroupFollowers(groupId: groupId, withUID: currentLoggedInUserId) { (err) in
                                                if err != nil {
                                                    completion(err);return
                                                }
                                                Database.database().addToGroupsFollowing(groupId: groupId, withUID: currentLoggedInUserId, autoSubscribed: false) { (err) in
                                                    if err != nil {
                                                        completion(err);return
                                                    }
                                                    
                                                    // this is actually useless since there is no group follow pending for public groups
                                                    Database.database().removeFromGroupFollowPending(groupId: groupId, withUID: currentLoggedInUserId, completion: { (err) in
                                                        if err != nil {
                                                            completion(err);return
                                                        }
                                                        completion(nil)
                                                    })
                                                }
                                            }
                                        }
                                    }
                                }
                                else {
                                    completion(nil)
                                }
                            }) { (err) in
                                completion(err);return
                            }
                        }
                        else {
                            completion(nil)
                        }
                    }) { (err) in
                        completion(err);return
                    }
                })
            }
            else {
                return
            }
        })
    }
    
    func addToGroupFollowPending(groupId: String, withUID uid: String, autoSubscribed: Bool, completion: @escaping (Error?) -> ()) {
        let values = ["autoSubscribed": autoSubscribed]  as [String : Any]
        Database.database().reference().child("groupFollowPending").child(groupId).child(uid).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func removeFromGroupFollowPending(groupId: String, withUID uid: String, completion: @escaping (Error?) -> ()) {
        Database.database().reference().child("groupFollowPending").child(groupId).child(uid).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove user from following:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func addToGroupRemovedUsers(groupId: String, withUID uid: String, completion: @escaping (Error?) -> ()) {
        let values = [uid: 1]
        Database.database().reference().child("groupRemovedUsers").child(groupId).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func addToUserRemovedGroups(groupId: String, withUID uid: String, completion: @escaping (Error?) -> ()) {
        let values = [groupId: 1]
        Database.database().reference().child("userRemovedGroups").child(uid).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func addToGroupFollowers(groupId: String, withUID uid: String, completion: @escaping (Error?) -> ()) {
        let values = [uid: Date().timeIntervalSince1970]
        Database.database().reference().child("groupFollowers").child(groupId).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func addToGroupsFollowing(groupId: String, withUID uid: String, autoSubscribed: Bool, completion: @escaping (Error?) -> ()) {
        // get group
        self.groupExists(groupId: groupId, completion: { (exists) in
            if exists {
                Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                    let lastPostedDate = Int(group.lastPostedDate)
                    let values = ["lastPostedDate": lastPostedDate, "autoSubscribed": autoSubscribed] as [String : Any]
                    Database.database().reference().child("groupsFollowing").child(uid).child(groupId).updateChildValues(values) { (err, ref) in
                        if let err = err {
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                })
            }
        })
    }

    func fetchGroupFollowers(groupId: String, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("groupFollowers").child(groupId)
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            
            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                sync.enter()
                let userId = child.key
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists {
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                completion(users)
                return
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func fetchMoreGroupFollowers(groupId: String, endAt: Double, completion: @escaping ([User],Double) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("groupFollowers").child(groupId)
        // endAt gets included in the next one but it shouldn't
        ref.queryOrderedByValue().queryEnding(atValue: endAt).queryLimited(toLast: 30).observeSingleEvent(of: .value, with: { (snapshot) in
            var users = [User]()
            var followDates = [String: Double]()

            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let userId = child.key
                followDates[userId] = child.value as? Double
                sync.enter()
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists {
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                users.sort(by: { (p1, p2) -> Bool in
                    return followDates[p1.uid] ?? 0 > followDates[p2.uid] ?? 0
                })
                
                // queryEnding keeps the oldest entree of the last batch so remove it here if not the first batch
                if endAt != 10000000000000 && users.count > 0 {
                    users.remove(at: 0)
                }
                completion(users,followDates[users.last?.uid ?? ""] ?? 10000000000000)
                return
            }
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func fetchGroupFollowersPending(groupId: String, completion: @escaping ([User]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("groupFollowPending").child(groupId)
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
                        
            var users = [User]()
            
            let sync = DispatchGroup()
            dictionaries.forEach({ (arg) in
                sync.enter()
                let (userId, _) = arg
                self.userExists(withUID: userId, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: userId, completion: { (user) in
                            users.append(user)
                            sync.leave()
                        })
                    }
                    else{
                        sync.leave()
                    }
                })
            })
            sync.notify(queue: .main) {
                completion(users)
                return
            }
        }) { (err) in
            print("Failed to fetch all users from database:", (err))
            cancel?(err)
        }
    }
    
    func hasGroupSubscriptionRequestUsers(groupId: String, completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("groupFollowPending").child(groupId).queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            completion((snapshot.children.allObjects as! [DataSnapshot]).count > 0)
        }) { (err) in
            print("Failed to check if group has requesting members in database:", err)
        }
    }
    
    func removeGroupFromUserRemovedGroups(withUID uid: String, groupId: String, completion: @escaping (Error?) -> ()) {
        Database.database().reference().child("userRemovedGroups").child(uid).child(groupId).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove user from following:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func removeUserFromGroupFollowers(withUID uid: String, groupId: String, completion: @escaping (Error?) -> ()) {
        // add to group.removed
        // remove user from groups following
        let values = [uid: 1]
        Database.database().reference().child("groupRemovedUsers").child(groupId).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            // remove user from group followers and from user groupsfollowing
            Database.database().reference().child("groupFollowers").child(groupId).child(uid).removeValue { (err, _) in
                if let err = err {
                    print("Failed to remove user from following:", err)
                    completion(err)
                    return
                }
                Database.database().reference().child("groupsFollowing").child(uid).child(groupId).removeValue { (err, _) in
                    if let err = err {
                        print("Failed to remove user from following:", err)
                        completion(err)
                        return
                    }
                    completion(nil)
                }
            }
        }
    }
    
    func removeGroupFromUserFollowing(withUID uid: String, groupId: String, completion: @escaping (Error?) -> ()) {
        // add to user.removed
        // remove user from groups following
        let values = [groupId: 1]
        Database.database().reference().child("userRemovedGroups").child(uid).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            // remove user from group followers and from user groupsfollowing
            Database.database().reference().child("groupFollowers").child(groupId).child(uid).removeValue { (err, _) in
                if let err = err {
                    print("Failed to remove user from following:", err)
                    completion(err)
                    return
                }
                Database.database().reference().child("groupsFollowing").child(uid).child(groupId).removeValue { (err, _) in
                    if let err = err {
                        print("Failed to remove user from following:", err)
                        completion(err)
                        return
                    }
                    completion(nil)
                }
            }
        }
    }
    
    func removeUserFromGroupPending(withUID uid: String, groupId: String, completion: @escaping (Error?) -> ()) {
        Database.database().reference().child("groupFollowPending").child(groupId).child(uid).removeValue { (err, _) in
            if let err = err {
                print("Failed to remove user from following:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func addUserToGroupRemovedUsers(withUID uid: String, groupId: String, completion: @escaping (Error?) -> ()) {
        let values = [uid: 1]
        Database.database().reference().child("groupRemovedUsers").child(groupId).updateChildValues(values) { (err, ref) in
            if let err = err {
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
//-------------------------------------------------------
//------------------------ Posts ------------------------
//-------------------------------------------------------
    
    //MARK: Posts
    
    func createPost(withImage image: UIImage, caption: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let userPostRef = Database.database().reference().child("posts").child(uid).childByAutoId()
        
        guard let postId = userPostRef.key else { return }
        
        Storage.storage().uploadPostImage(image: image, filename: postId) { (postImageUrl) in
            let values = ["imageUrl": postImageUrl, "caption": caption, "imageWidth": image.size.width, "imageHeight": image.size.height, "creationDate": Int(Date().timeIntervalSince1970), "id": postId] as [String : Any]
            
            userPostRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Failed to save post to database", err)
                    completion(err)
                    return
                }
                completion(nil)
            }
        }
    }

//    func createGroupPost(withImage image: UIImage?, withVideo video_url: URL?, caption: String, groupId: String, completion: @escaping (String) -> (), withCancel cancel: ((Error) -> ())? = nil) {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//
//        let groupPostRef = Database.database().reference().child("posts").child(groupId).childByAutoId()
//
//        guard let postId = groupPostRef.key else { return }
//
//        // if video_url is empty then its a picture
//        if video_url == nil {
//            guard let image = image else { return }
//            Storage.storage().uploadPostImage(image: image, filename: postId) { (postImageUrl) in
//
//                // get the average color of the image
//                guard let inputImage = CIImage(image: image) else { return }
//                let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
//                guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return }
//                guard let outputImage = filter.outputImage else { return }
//                var bitmap = [UInt8](repeating: 0, count: 4)
//                let context = CIContext(options: [.workingColorSpace: kCFNull])
//                context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
//                let avgRed = CGFloat(bitmap[0]) / 255
//                let avgGreen = CGFloat(bitmap[1]) / 255
//                let avgBlue = CGFloat(bitmap[2]) / 255
//                let avgAlpha = CGFloat(bitmap[3]) / 255
//
//                let values = ["imageUrl": postImageUrl, "caption": caption, "imageWidth": image.size.width, "imageHeight": image.size.height, "avgRed": avgRed, "avgGreen": avgGreen, "avgBlue": avgBlue, "avgAlpha": avgAlpha, "creationDate": Date().timeIntervalSince1970, "id": postId, "userUploaded": uid] as [String : Any]
//                groupPostRef.updateChildValues(values) { (err, ref) in
//                    if let err = err {
//                        print("Failed to save post to database", err)
//                        completion("")
//                    }
//                    // update lastPostedDate for group
//                    // if wanted to skip the date and just do ordering but in reverse, could do 10000000000000 - Date().timeIntervalSince1970
//                    let lastPostedValue = ["lastPostedDate": Int(Date().timeIntervalSince1970)] as [String : Int]
//                    Database.database().reference().child("groups").child(groupId).updateChildValues(lastPostedValue) { (err, ref) in
//                        if let err = err {
//                            print("Failed to save post to database", err)
//                            completion("")
//                        }
//                        // also update lastPostedDate for groupsFollowing for the user uploading since it takes time for cloud function
//                        // also check if following group though
//                        Database.database().isFollowingGroup(groupId: groupId, completion: { (following) in
//                            if following {
//                                Database.database().reference().child("groupsFollowing").child(uid).child(groupId).updateChildValues(lastPostedValue) { (err, ref) in
//                                    if let err = err {
//                                        print("Failed to save post to database", err)
//                                        completion("")
//                                    }
//                                    completion(postId)
//                                }
//                            }
//                            else {
//                                completion(postId)
//                            }
//                        }){ (err) in }
//                    }
//                }
//            }
//        }
//        else {
//            guard let video_url = video_url else { return }
//            guard let video_thumbnail = image else { return }
//            Storage.storage().uploadPostImage(image: video_thumbnail, filename: postId) { (postImageUrl) in
//                Storage.storage().uploadPostVideo(filePath: video_url, filename: String(postId), fileExtension: "mp4") { (postVideoUrl) in
//                    let values = ["imageUrl": postImageUrl, "videoUrl": postVideoUrl, "caption": caption, "videoWidth": video_thumbnail.size.width, "videoHeight": video_thumbnail.size.height, "creationDate": Date().timeIntervalSince1970, "id": postId, "userUploaded": uid] as [String : Any]
//                    groupPostRef.updateChildValues(values) { (err, ref) in
//                        if let err = err {
//                            print("Failed to save post to database", err)
//                            completion("")
//                        }
//                        let lastPostedValue = ["lastPostedDate": Int(Date().timeIntervalSince1970)] as [String : Int]
//                        Database.database().reference().child("groups").child(groupId).updateChildValues(lastPostedValue) { (err, ref) in
//                            if let err = err {
//                                print("Failed to save post to database", err)
//                                completion("")
//                            }
//                            completion(postId)
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    func createGroupPost(withImage image: UIImage?, withVideo video_url: URL?, caption: String, groupId: String, location: String, isTempPost: Bool, completion: @escaping (String) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let groupPostRef = Database.database().reference().child("posts").child(groupId).childByAutoId()
        
        guard let postId = groupPostRef.key else { return }
        
        let sync = DispatchGroup()
        sync.enter()
        if caption != "" {
            Database.database().addCommentToPost(withId: postId, text: caption) { (err) in
                if err != nil {
                    return
                }
                sync.leave()
            }
        }
        else {
            sync.leave()
        }
        
        sync.notify(queue: .main) {
            // if video_url is empty then its a picture
            if video_url == nil {
                guard let image = image else { return }
                Storage.storage().uploadPostImageDistributed(image: image, groupId: groupId, filename: postId) { (postImageUrl) in
                    
                    // get the average color of the image
                    guard let inputImage = CIImage(image: image) else { return }
                    let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
                    guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return }
                    guard let outputImage = filter.outputImage else { return }
                    var bitmap = [UInt8](repeating: 0, count: 4)
                    let context = CIContext(options: [.workingColorSpace: kCFNull])
                    context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
                    let avgRed = CGFloat(bitmap[0]) / 255
                    let avgGreen = CGFloat(bitmap[1]) / 255
                    let avgBlue = CGFloat(bitmap[2]) / 255
                    let avgAlpha = CGFloat(bitmap[3]) / 255
                    
                    let values = ["imageUrl": postImageUrl, "caption": caption, "imageWidth": image.size.width, "imageHeight": image.size.height, "avgRed": avgRed, "avgGreen": avgGreen, "avgBlue": avgBlue, "avgAlpha": avgAlpha, "creationDate": Date().timeIntervalSince1970, "id": postId, "userUploaded": uid, "location": location, "isTempPost": isTempPost] as [String : Any]
                    groupPostRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to save post to database", err)
                            completion("")
                        }
                        // update lastPostedDate for group
                        // if wanted to skip the date and just do ordering but in reverse, could do 10000000000000 - Date().timeIntervalSince1970
                        let lastPostedValue = ["lastPostedDate": Int(Date().timeIntervalSince1970)] as [String : Int]
                        Database.database().reference().child("groups").child(groupId).updateChildValues(lastPostedValue) { (err, ref) in
                            if let err = err {
                                print("Failed to save post to database", err)
                                completion("")
                            }
                            // also update lastPostedDate for groupsFollowing for the user uploading since it takes time for cloud function
                            // also check if following group though
                            Database.database().isFollowingGroup(groupId: groupId, completion: { (following) in
                                if following {
                                    Database.database().reference().child("groupsFollowing").child(uid).child(groupId).updateChildValues(lastPostedValue) { (err, ref) in
                                        if let err = err {
                                            print("Failed to save post to database", err)
                                            completion("")
                                        }
                                        completion(postId)
                                    }
                                }
                                else {
                                    completion(postId)
                                }
                            }){ (err) in }
                        }
                    }
                }
            }
            else {
                guard let video_url = video_url else { return }
                guard let video_thumbnail = image else { return }
                Storage.storage().uploadPostImageDistributed(image: video_thumbnail, groupId: groupId, filename: postId) { (postImageUrl) in
                    Storage.storage().uploadPostVideoDistributed(filePath: video_url, groupId: groupId, filename: String(postId)) { (postVideoUrl) in
                        let values = ["imageUrl": postImageUrl, "videoUrl": postVideoUrl, "caption": caption, "videoWidth": video_thumbnail.size.width, "videoHeight": video_thumbnail.size.height, "creationDate": Date().timeIntervalSince1970, "id": postId, "userUploaded": uid, "location": location, "isTempPost": isTempPost] as [String : Any]
                        groupPostRef.updateChildValues(values) { (err, ref) in
                            if let err = err {
                                print("Failed to save post to database", err)
                                completion("")
                            }
                            let lastPostedValue = ["lastPostedDate": Int(Date().timeIntervalSince1970)] as [String : Int]
                            Database.database().reference().child("groups").child(groupId).updateChildValues(lastPostedValue) { (err, ref) in
                                if let err = err {
                                    print("Failed to save post to database", err)
                                    completion("")
                                }
                                completion(postId)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func fetchPost(withUID uid: String, postId: String, completion: @escaping (Post) -> (), withCancel cancel: ((Error) -> ())? = nil) {
//        guard let currentLoggedInUser = Auth.auth().currentUser?.uid else { return }
//
//        let ref = Database.database().reference().child("posts").child(uid).child(postId)
//
//        ref.observeSingleEvent(of: .value, with: { (snapshot) in
//
//            guard let postDictionary = snapshot.value as? [String: Any] else { return }
//
//            Database.database().fetchUser(withUID: uid, completion: { (user) in
//                var post = Post(user: user, dictionary: postDictionary)
//                post.id = postId
//
//                //check likes
//                Database.database().reference().child("likes").child(postId).child(currentLoggedInUser).observeSingleEvent(of: .value, with: { (snapshot) in
//                    if let value = snapshot.value as? Int, value == 1 {
//                        post.likedByCurrentUser = true
//                    } else {
//                        post.likedByCurrentUser = false
//                    }
//                    completion(post)
//                }, withCancel: { (err) in
//                    print("Failed to fetch like info for post:", err)
//                    cancel?(err)
//                })
//            })
//        })
    }
    
    func groupPostExists(groupId: String, postId: String, completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("posts").child(groupId).child(postId).observeSingleEvent(of: .value, with: { (snapshot) in
            guard (snapshot.value as? [String: Any]) != nil else {
                completion(false)
                return
            }
            completion(true)
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func fetchGroupPost(groupId: String, postId: String, completion: @escaping (GroupPost) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        let ref = Database.database().reference().child("posts").child(groupId).child(postId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let postDictionary = snapshot.value as? [String: Any] else { return }
            self.groupExists(groupId: groupId, completion: { (exists) in
                if exists {
                    Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                        let user_id = postDictionary["userUploaded"] as? String ?? ""
                        if user_id == ""{
                            var post = GroupPost(group: group, user: nil, dictionary: postDictionary)
                            post.id = postId
                            completion(post)
                        }
                        else {
                            self.userExists(withUID: user_id, completion: { (exists) in
                                if exists{
                                    Database.database().fetchUser(withUID: user_id) { (user) in
                                        var post = GroupPost(group: group, user: user, dictionary: postDictionary)
                                        post.id = postId
                                        completion(post)
                                    }
                                }
                                else {
                                    let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "USER NOT FOUND"])
                                    print("Failed to fetch user", err)
                                    cancel?(err)
                                }
                            })
                        }
                    })
                }
                else {
                    let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "GROUP NOT FOUND"])
                    print("Failed to fetch user", err)
                    cancel?(err)
                }
            })
        })
    }
    
    // DO NOT USE THIS. USE fetchAllGroupPosts
    func fetchAllPosts(withUID uid: String, completion: @escaping ([Post]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("posts").child(uid)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }

            var posts = [Post]()

            dictionaries.forEach({ (postId, value) in
                Database.database().fetchPost(withUID: uid, postId: postId, completion: { (post) in
                    posts.append(post)
                    
                    if posts.count == dictionaries.count {
                        completion(posts)
                    }
                })
            })
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func fetchAllGroupPosts(groupId: String, completion: @escaping ([Any]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("posts").child(groupId)
        // this returns it backwards
        // so we'll continuously do limit last, with the limit increasing the 3, there will be a counter
        // we don't know how many posts there are in a group, we should figure this out for each group
        // and then cache it. This way, we can do "queryStartingAtValue" and "queryEndingAtValue"
        
        ref.queryOrdered(byChild: "creationDate").observeSingleEvent(of: .value, with: { snapshot in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var posts = [GroupPost]()
            
            let sync = DispatchGroup()
            dictionaries.forEach({ (postId, value) in
                sync.enter()
                self.groupPostExists(groupId: groupId, postId: postId, completion: { (exists) in
                    if exists {
                        Database.database().fetchGroupPost(groupId: groupId, postId: postId, completion: { (post) in
                            posts.append(post)
                            sync.leave()
                        })
                    }
                    else{
                        sync.leave()
                    }
                })
            })
            sync.notify(queue: .main) {
                // sort the posts, then cut off
                posts.sort(by: { (p1, p2) -> Bool in
                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                })
                completion([posts.count,posts])
                return
            }
            
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func fetchMoreGroupPosts(groupId: String, num_posts_loaded: Int, completion: @escaping ([Any]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("posts").child(groupId)
    
        // this returns it backwards
        // so we'll continuously do limit last, with the limit increasing the 3, there will be a counter
        // we don't know how many posts there are in a group, we should figure this out for each group
        // and then cache it. This way, we can do "queryStartingAtValue" and "queryEndingAtValue"

        ref.queryOrdered(byChild: "creationDate").observeSingleEvent(of: .value, with: { snapshot in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var posts = [GroupPost]()
            
            let sync = DispatchGroup()
            dictionaries.forEach({ (postId, value) in
                sync.enter()
                self.groupPostExists(groupId: groupId, postId: postId, completion: { (exists) in
                    if exists{
                        Database.database().fetchGroupPost(groupId: groupId, postId: postId, completion: { (post) in
                            posts.append(post)
                            sync.leave()
                        })
                    }
                    else{
                        sync.leave()
                    }
                })
            })
            sync.notify(queue: .main) {
                // sort the posts, then cut off
                posts.sort(by: { (p1, p2) -> Bool in
                    return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                })
                var stopCounter = 3
                var skipCounter = num_posts_loaded
                var posts_to_send = [GroupPost]()
                posts.forEach({ post in
                    if skipCounter == 0 {
                        if stopCounter == 0 {
                            return
                        }
                        stopCounter -= 1
                        posts_to_send.append(post)
                    }
                    else {
                        skipCounter -= 1
                    }
                })
                print("----")
                print(posts_to_send)
                completion([posts.count,posts_to_send])
                return
            }
            
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func deleteGroup(groupId: String, groupname: String, school: String? = nil, completion: ((Error?) -> ())? = nil) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("groups").child(groupId).removeValue { (err, _) in
            if let err = err {
                print("Failed to delete post:", err)
                completion?(err)
                return
            }
            
            Database.database().reference().child("users").child(currentLoggedInUserId).child("groups").child(groupId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to delete comments on post:", err)
                    completion?(err)
                    return
                }
                
                if groupname != "" {
                    Database.database().reference().child("groupnames").child(groupname).removeValue(completionBlock: { (err, _) in
                        if let err = err {
                            print("Failed to delete likes on post:", err)
                            completion?(err)
                            return
                        }
                        if school != nil && school != "" {
                            Database.database().reference().child("schools").child(school!).child("groups").child(groupId).removeValue(completionBlock: { (err, _) in
                                if let err = err {
                                    print("Failed to delete likes on post:", err)
                                    completion?(err)
                                    return
                                }
                                completion?(nil)
                            })
                        }
                        else {
                            completion?(nil)
                        }
                    })
                }
                else {
                    if school != nil && school != "" {
                        Database.database().reference().child("schools").child(school!).child("groups").child(groupId).removeValue(completionBlock: { (err, _) in
                            if let err = err {
                                print("Failed to delete likes on post:", err)
                                completion?(err)
                                return
                            }
                            completion?(nil)
                        })
                    }
                    else {
                        completion?(nil)
                    }
                }
            })
        }
    }
    
    func deletePost(withUID uid: String, postId: String, completion: ((Error?) -> ())? = nil) {
        Database.database().reference().child("posts").child(uid).child(postId).removeValue { (err, _) in
            if let err = err {
                print("Failed to delete post:", err)
                completion?(err)
                return
            }
            
            Database.database().reference().child("comments").child(postId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to delete comments on post:", err)
                    completion?(err)
                    return
                }
                
                Database.database().reference().child("likes").child(postId).removeValue(completionBlock: { (err, _) in
                    if let err = err {
                        print("Failed to delete likes on post:", err)
                        completion?(err)
                        return
                    }
                    
                    Storage.storage().reference().child("post_images").child(postId).delete(completion: { (err) in
                        if let err = err {
                            print("Failed to delete post image from storage:", err)
                            completion?(err)
                            return
                        }
                    })
                    
                    completion?(nil)
                })
            })
        }
    }
    
    func deleteGroupPost(groupId: String, postId: String, completion: ((Error?) -> ())? = nil) {
        Database.database().reference().child("posts").child(groupId).child(postId).removeValue { (err, _) in
            if let err = err {
                print("Failed to delete post:", err)
                completion?(err)
                return
            }
            
            Database.database().reference().child("comments").child(postId).removeValue(completionBlock: { (err, _) in
                if let err = err {
                    print("Failed to delete comments on post:", err)
                    completion?(err)
                    return
                }
                
                Database.database().reference().child("likes").child(postId).removeValue(completionBlock: { (err, _) in
                    if let err = err {
                        print("Failed to delete likes on post:", err)
                        completion?(err)
                        return
                    }
                    
                    Storage.storage().reference().child("post_images").child(postId).delete(completion: { (err) in
                        if let err = err {
                            print("Failed to delete post image from storage:", err)
                            completion?(err)
                            return
                        }
                    })
                    completion?(nil)
                })
            })
        }
    }
    
    func reportPost(withId postId: String, groupId: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let values = ["groupId": groupId, "reportDate": Date().timeIntervalSince1970, "userReported": uid] as [String: Any]
        
        let postReportRef = Database.database().reference().child("reportedPosts").child(postId)
        postReportRef.updateChildValues(values) { (err, _) in
            if let err = err {
                print("Failed to report post:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func addCommentToPost(withId postId: String, text: String, completion: @escaping (Error?) -> ()) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let values = ["text": text, "creationDate": Date().timeIntervalSince1970, "uid": uid] as [String: Any]
        
        let commentsRef = Database.database().reference().child("comments").child(postId).childByAutoId()
        commentsRef.updateChildValues(values) { (err, _) in
            if let err = err {
                print("Failed to add comment:", err)
                completion(err)
                return
            }
            completion(nil)
        }
    }
    
    func fetchCommentsForPost(withId postId: String, completion: @escaping ([Comment]) -> (), withCancel cancel: ((Error) -> ())?) {
        let commentsReference = Database.database().reference().child("comments").child(postId)
        
        commentsReference.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var comments = [Comment]()
                
            let sync = DispatchGroup()
            dictionaries.forEach({ (key, value) in
                guard let commentDictionary = value as? [String: Any] else { return }
                guard let uid = commentDictionary["uid"] as? String else { return }
                sync.enter()
                self.userExists(withUID: uid, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: uid) { (user) in
                            let comment = Comment(user: user, dictionary: commentDictionary)
                            comments.append(comment)
                            sync.leave()
                        }
                    }
                    else{
                        sync.leave()
                    }
                })
            })
            sync.notify(queue: .main) {
                comments.sort(by: { (comment1, comment2) -> Bool in
                    return comment1.creationDate.compare(comment2.creationDate) == .orderedAscending
                })
                completion(comments)
                return
            }
            
        }) { (err) in
            print("Failed to fetch comments:", err)
            cancel?(err)
        }
    }

    func fetchFirstCommentForPost(withId postId: String, completion: @escaping ([Comment]) -> (), withCancel cancel: ((Error) -> ())?) {
        let commentsReference = Database.database().reference().child("comments").child(postId)
        commentsReference.queryOrderedByKey().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
                    
            var comments = [Comment]()
            
            // this for loop only has 2 iterations
            // just used it to get value since dictionaries are unorganized
            // could also use loop to find the newest, most relevent, etc comment and return it
            // or return 2 comments potentially so returning an array
            let sync = DispatchGroup()
            for (_, value) in dictionaries {
                guard let commentDictionary = value as? [String: Any] else { return }
                guard let uid = commentDictionary["uid"] as? String else { return }
                sync.enter()
                
                self.userExists(withUID: uid, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: uid) { (user) in
                            let comment = Comment(user: user, dictionary: commentDictionary)
                            comments.append(comment)
                            sync.leave()
                        }
                    }
                    else{
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                comments.sort(by: { (comment1, comment2) -> Bool in
                    return comment1.creationDate.compare(comment2.creationDate) == .orderedAscending
                })
                if comments.count >= 2 {
                    completion(Array(comments[0 ..< 2]))
                } else {
                    completion(comments)
                }
                return
            }
        }) { (err) in
            print("Failed to fetch comments:", err)
            cancel?(err)
        }
    }
    
    func fetchLastCommentForPost(withId postId: String, completion: @escaping ([Comment]) -> (), withCancel cancel: ((Error) -> ())?) {
        let commentsReference = Database.database().reference().child("comments").child(postId)
        commentsReference.queryOrderedByKey().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
                    
            var comments = [Comment]()
            
            // this for loop only has 2 iterations
            // just used it to get value since dictionaries are unorganized
            // could also use loop to find the newest, most relevent, etc comment and return it
            // or return 2 comments potentially so returning an array
            let sync = DispatchGroup()
            for (_, value) in dictionaries {
                guard let commentDictionary = value as? [String: Any] else { return }
                guard let uid = commentDictionary["uid"] as? String else { return }
                sync.enter()
                
                self.userExists(withUID: uid, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: uid) { (user) in
                            let comment = Comment(user: user, dictionary: commentDictionary)
                            comments.append(comment)
                            sync.leave()
                        }
                    }
                    else{
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                if comments.count >= 2 {
                    completion(Array(comments[0 ..< 2]))
                } else {
                    completion(comments)
                }
                return
            }
        }) { (err) in
            print("Failed to fetch comments:", err)
            cancel?(err)
        }
    }
    
    func addToViewedPosts(postId: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().isInIncognitoMode(completion: { (isIncognito) in
            var value = 0
            // value == 1 means the view is an incognito view (hidden)
            // value == 0 means the view is not hidden
            if isIncognito { value = 1 }
            let values = [postId: value]
            Database.database().reference().child("usersViewed").child(currentLoggedInUserId).updateChildValues(values) { (err, ref) in
                if let err = err {
                    completion(err)
                    return
                }
                
                let values = [currentLoggedInUserId: value]
                Database.database().reference().child("postViews").child(postId).updateChildValues(values) { (err, ref) in
                    if let err = err {
                        completion(err)
                        return
                    }
                    // save to userDefaults of viewedPosts
                    // first fetch those already viewed, then add to it, then save it
                    var viewedPosts = [String: Bool]()
                    if let viewedPostsRetrieved = UserDefaults.standard.object(forKey: "viewedPosts") as? Data {
                        guard let allViewedPosts = try? JSONDecoder().decode([String: Bool].self, from: viewedPostsRetrieved) else {
                            print("Error: Couldn't decode data into Blog")
                            return
                        }
                        viewedPosts = allViewedPosts
                    }
                    viewedPosts[postId] = true
                    if let viewedPostsEncodedData = try? JSONEncoder().encode(viewedPosts) {
                        UserDefaults.standard.set(viewedPostsEncodedData, forKey: "viewedPosts")
                    }
                    
                    completion(nil)
                }
            }
        })
    }
    
    func hasViewedPost(postId: String, completion: @escaping (Bool) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        Database.database().reference().child("usersViewed").child(currentLoggedInUserId).child(postId).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.value != nil {
                if snapshot.value! is NSNull {
                    completion(false)
                }
                else {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func fetchPostVisibleViewers(postId: String, completion: @escaping ([String]) -> (), withCancel cancel: ((Error) -> ())?) {
        let ref = Database.database().reference().child("postViews").child(postId)
        ref.queryOrderedByKey().observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            var viewers = [String]()
            dictionaries.forEach({ (viewerId, value) in
                if value as! Int == 0 {
                    viewers.append(viewerId)
                }
            })
            completion(viewers)
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
//    func fetchNumPostViewers(postId: String, completion: @escaping (Int) -> (), withCancel cancel: ((Error) -> ())?) {
//        let ref = Database.database().reference().child("postViews").child(postId)
//        ref.observeSingleEvent(of: .value, with: { (snapshot) in
//            guard let dictionaries = snapshot.value as? [String: Any] else {
//                completion(0)
//                return
//            }
//            completion(dictionaries.count)
//        }) { (err) in
//            print("Failed to fetch posts:", err)
//            cancel?(err)
//        }
//    }
    func fetchNumPostViewers(postId: String, completion: @escaping (Int) -> (), withCancel cancel: ((Error) -> ())?) {
        Database.database().reference().child("postViewsCount").child(postId).observeSingleEvent(of: .value) { (snapshot) in
            if let val = snapshot.value as? Int {
                completion(val)
            }
            else {
                completion(0)
            }
        }
    }
    
//---------------------------------------------------------------
//------------------------ Notifications ------------------------
//---------------------------------------------------------------
    
    //MARK: Notifications
    
    func fetchMyFcnToken(completion: @escaping (String) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("users").child(currentLoggedInUserId).child("token").observeSingleEvent(of: .value, with: { (snapshot) in
            let token = snapshot.value as? String
            completion(token ?? "")
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func fetchUserFcnToken(withUID uid: String, completion: @escaping (String) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        Database.database().reference().child("users").child(uid).child("token").observeSingleEvent(of: .value, with: { (snapshot) in
            let token = snapshot.value as? String
            completion(token ?? "")
            
        }) { (err) in
            print("Failed to check if following:", err)
            cancel?(err)
        }
    }
    
    func createNotification(to: User, notificationType: NotificationType, subjectUser: User? = nil, group: Group? = nil, groupPost: GroupPost? = nil, message: String? = nil, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let toId = to.uid
        
        // don't allow notifications from user to himself, but also don't err
        if toId == currentLoggedInUserId{
            completion(nil)
            return
        }
        
        self.userExists(withUID: toId, completion: { (exists) in
            if !exists{
                return
            }
        })
        
        let notificationRef = Database.database().reference().child("notifications").child(toId).childByAutoId()
        guard let notificationId = notificationRef.key else { return }
        Database.database().fetchUserFcnToken(withUID: to.uid, completion: { (token) in
            switch notificationType {
            case .newFollow:
                Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                    let pushMessage = user.username + " followed you"
                    PushNotificationSender().sendPushNotification(to: token, title: "New Follower", body: pushMessage)
                    
                    // Save the notification
                    let values = ["id": notificationId, "from_id": currentLoggedInUserId, "type": "newFollow", "creationDate": Date().timeIntervalSince1970] as [String : Any]
                    notificationRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to save post to database", err)
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                }
            case .groupJoinRequest:
                Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                    let pushMessage = user.username + " requested to join your group " + group!.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
                    PushNotificationSender().sendPushNotification(to: token, title: "Group Join Request", body: pushMessage)
                    
                    // Save the notification
                    let values = ["id": notificationId, "from_id": currentLoggedInUserId, "group_id": group!.groupId, "type": "groupJoinRequest", "creationDate": Date().timeIntervalSince1970] as [String : Any]
                    notificationRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to save post to database", err)
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                }
            case .newGroupJoin:
                // someone in the group is accepting a user, so that user can't create the notification themselves
                // subjectUser is the user that is being accepted
                self.userExists(withUID: subjectUser!.uid, completion: { (exists) in
                    if !exists{
                        completion(nil)
                        return
                    }
                })
                
                guard let group = group else { return }
                Database.database().fetchUser(withUID: subjectUser!.uid) { (user) in
                    let pushMessage = user.username + " joined your group " + group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
                    PushNotificationSender().sendPushNotification(to: token, title: "Group Join", body: pushMessage)
                    
                    // Save the notification
                    let values = ["id": notificationId, "from_id": user.uid, "group_id": group.groupId, "type": "newGroupJoin", "creationDate": Date().timeIntervalSince1970] as [String : Any]
                    notificationRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to save post to database", err)
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                }
            case .newGroupSubscribe:
                guard let group = group else { return }
                Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                    let pushMessage = user.username + " followed your group " + group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
                    PushNotificationSender().sendPushNotification(to: token, title: "New Subscription", body: pushMessage)
                    
                    // Save the notification
                    let values = ["id": notificationId, "from_id": currentLoggedInUserId, "group_id": group.groupId, "type": "newGroupSubscribe", "creationDate": Date().timeIntervalSince1970] as [String : Any]
                    notificationRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to send notification", err)
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                }
            case .groupSubscribeRequest:
                guard let group = group else { return }
                Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                    let pushMessage = user.username + " requested to follow your group " + group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
                    PushNotificationSender().sendPushNotification(to: token, title: "New Subscription Request", body: pushMessage)
                    
                    // Save the notification
                    let values = ["id": notificationId, "from_id": currentLoggedInUserId, "group_id": group.groupId, "type": "groupSubscribeRequest", "creationDate": Date().timeIntervalSince1970] as [String : Any]
                    notificationRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to send notification", err)
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                }
            case .groupProfileNameEdit:
                guard let group = group else { return }
                Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                    let groupname = group.groupname
                    var pushMessage = ""
                    if groupname == "" {
                        pushMessage = user.username + " removed your group's name"
                    }
                    else {
                        pushMessage = user.username + " changed group name to " + groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
                    }
                    
                    PushNotificationSender().sendPushNotification(to: token, title: "Group Name Edit", body: pushMessage)
                    
                    // Save the notification
                    let values = ["id": notificationId, "from_id": currentLoggedInUserId, "group_id": group.groupId, "type": "groupProfileNameEdit", "creationDate": Date().timeIntervalSince1970] as [String : Any]
                    notificationRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to send notification", err)
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                }
            case .groupPrivacyChange:
                guard let group = group else { return }
                guard let isPrivate = group.isPrivate else { return }
                Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                    var groupname = group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
                    if groupname == "" { groupname = "your group" }
                    var pushMessage = ""
                    if isPrivate {
                        pushMessage = user.username + " made " + groupname + " private"
                    }
                    else {
                        pushMessage = user.username + " made " + groupname + " public"
                    }
                    
                    PushNotificationSender().sendPushNotification(to: token, title: "Group Privacy Change", body: pushMessage)
                    
                    // Save the notification
                    let values = ["id": notificationId, "from_id": currentLoggedInUserId, "group_id": group.groupId, "type": "groupPrivacyChange", "creationDate": Date().timeIntervalSince1970] as [String : Any]
                    notificationRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to send notification", err)
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                }
            case .groupProfilePicEdit:
                guard let group = group else { return }
                Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                    var groupname = group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
                    if groupname == "" { groupname = "your group" }
                    let pushMessage = user.username + " edited " + groupname + "'s profile picture"
                    PushNotificationSender().sendPushNotification(to: token, title: "Group Profile Picture Edit", body: pushMessage)
                    
                    // Save the notification
                    let values = ["id": notificationId, "from_id": currentLoggedInUserId, "group_id": group.groupId, "type": "groupProfilePicEdit", "creationDate": Date().timeIntervalSince1970] as [String : Any]
                    notificationRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to send notification", err)
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                }
            case .groupPostComment:
                guard let group = group else { return }
                guard let message = message else { return }
                guard let groupPost = groupPost else { return }
                Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                    
                    // could add a check to see if the currentLoggedInUser is following the user in the group.
                    // if not following, then could not send a notification for them.
                    // could add this here, before this function is called, + have default and change from settings
                    
//                    var groupname = group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
//                    if groupname == "" { groupname = "your group" }
//                    let pushMessage = user.username + " commented on " + groupname + "'s post"
//                    PushNotificationSender().sendPushNotification(to: token, title: "Comment", body: pushMessage)
                    
                    var short_message = message
                    if message.count > 40 {
                        short_message = String(message.prefix(40)) + "..."
                    }
                    
                    var groupname = group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
                    if groupname == "" { groupname = "Group Message" }
                    let pushMessage = user.username + ": " + short_message
                    PushNotificationSender().sendPushNotification(to: token, title: groupname, body: pushMessage, click_action: "open_post_" + groupPost.id + "*" + group.groupId)
                    
                    completion(nil)
                    
                    // Don't save the notification for a message actually
                    
                    // Save the notification:
//                    let values = ["id": notificationId, "from_id": currentLoggedInUserId, "group_id": group.groupId, "group_post_id": groupPost!.id, "type": "groupPostComment", "creationDate": Date().timeIntervalSince1970] as [String : Any]
//                    notificationRef.updateChildValues(values) { (err, ref) in
//                        if let err = err {
//                            print("Failed to save post to database", err)
//                            completion(err)
//                            return
//                        }
//                        completion(nil)
//                    }
                }
            case .newGroupPost:
                guard let group = group else { return }
                Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                    
                    // could add a check to see if the currentLoggedInUser is following the user in the group.
                    // if not following, then could not send a notification for them.
                    // could add this here, before this function is called, + have default and change from settings
                    
                    var groupname = group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
                    if groupname == "" { groupname = "your group" }
                    let pushMessage = user.username + " posted in " + groupname
                    PushNotificationSender().sendPushNotification(to: token, title: "Group Post", body: pushMessage)
                    
                    // Save the notification
                    let values = ["id": notificationId, "from_id": currentLoggedInUserId, "group_id": group.groupId, "group_post_id": groupPost!.id, "type": "newGroupPost", "creationDate": Date().timeIntervalSince1970] as [String : Any]
                    notificationRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to save post to database", err)
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                }
            case .mentionedInComment:
                Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                    guard let group = group else { return }
                    // could add a check to see if the currentLoggedInUser is following the user in the group.
                    // if not following, then could not send a notification for them.
                    // could add this here, before this function is called, + have default and change from settings

                    let pushMessage = user.username + " mentioned you in a comment"
                    PushNotificationSender().sendPushNotification(to: token, title: "Group Post", body: pushMessage)
                    
                    // Save the notification
                    let values = ["id": notificationId, "from_id": currentLoggedInUserId, "group_id": group.groupId, "group_post_id": groupPost!.id, "type": "mentionedInComment", "creationDate": Date().timeIntervalSince1970] as [String : Any]
                    notificationRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to save post to database", err)
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                }
            case .unsubscribeRequest:
                // no notification for unsubscribe request
                completion(nil)
            case .groupJoinInvitation:
                guard let group = group else { return }
                // someone in the group is inviting a user
                Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in                    
                    var groupname = group.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
                    if groupname == "" { groupname = "a group" }
                    let pushMessage = user.username + " invited you to join " + groupname
                    PushNotificationSender().sendPushNotification(to: token, title: "Group Invitation", body: pushMessage)
                    
                    // Save the notification
                    let values = ["id": notificationId, "from_id": currentLoggedInUserId, "group_id": group.groupId, "type": "groupJoinInvitation", "creationDate": Date().timeIntervalSince1970] as [String : Any]
                    notificationRef.updateChildValues(values) { (err, ref) in
                        if let err = err {
                            print("Failed to save post to database", err)
                            completion(err)
                            return
                        }
                        completion(nil)
                    }
                }
            }
        })
    }
    
    func notificationIsValid(notificationId: String, completion: @escaping (Bool) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("notifications").child(currentLoggedInUserId).child(notificationId)

        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let notificationDictionary = snapshot.value as? [String: Any] else { return }
            let from_id = notificationDictionary["from_id"] as? String ?? ""
            let type_string = notificationDictionary["type"] as? String ?? ""
            let group_id = notificationDictionary["group_id"] as? String ?? ""
            let group_post_id = notificationDictionary["group_post_id"] as? String ?? ""
            
            // Will need to check that all the above still exist, not just user
            self.userExists(withUID: from_id, completion: { (exists) in
                if !exists{
                    completion(false)
                    return
                }
                else{
                    switch type_string{
                        case "newFollow":
                            completion(true)
                            return
                        case "groupJoinRequest":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                completion(exists)
                                return
                            })
                        case "newGroupJoin":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                completion(exists)
                                return
                            })
                        case "newGroupSubscribe":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                completion(exists)
                                return
                            })
                        case "groupSubscribeRequest":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                completion(exists)
                                return
                            })
                        case "groupProfileNameEdit":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                completion(exists)
                                return
                            })
                        case "groupPrivacyChange":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                completion(exists)
                                return
                            })
                        case "groupProfilePicEdit":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                completion(exists)
                                return
                            })
                        case "groupPostComment":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                if exists {
                                    self.groupPostExists(groupId: group_id, postId: group_post_id, completion: { (post_exists) in
                                        completion(post_exists)
                                        return
                                    })
                                }
                                else{
                                    completion(false)
                                    return
                                }
                            })
                        case "newGroupPost":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                if exists {
                                    self.groupPostExists(groupId: group_id, postId: group_post_id, completion: { (post_exists) in
                                        completion(post_exists)
                                        return
                                    })
                                }
                                else{
                                    completion(false)
                                    return
                                }
                            })
                        case "mentionedInComment":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                if exists {
                                    self.groupPostExists(groupId: group_id, postId: group_post_id, completion: { (post_exists) in
                                        completion(post_exists)
                                        return
                                    })
                                }
                                else{
                                    completion(false)
                                    return
                                }
                            })
                        case "groupJoinInvitation":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                completion(exists)
                                return
                            })
                        case "unsubscribeRequest":
                            self.groupExists(groupId: group_id, completion: { (exists) in
                                completion(exists)
                                return
                            })
                        default:
                            completion(false)
                            return
                    }
                }
            })
        })
    }
    
    // inspire this from fetchGroupPost
    // this will be passed in the notification id
    // with that, you will do a bunch of snapshot value things to get the values from firebase
    // will construct the notification struct from those value and return it
    func fetchNotification(notificationId: String, completion: @escaping (Notification) -> (), withCancel cancel: ((Error) -> ())? = nil) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("notifications").child(currentLoggedInUserId).child(notificationId)

        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let notificationDictionary = snapshot.value as? [String: Any] else { return }
            let from_id = notificationDictionary["from_id"] as? String ?? ""
            let type_string = notificationDictionary["type"] as? String ?? ""
            let group_id = notificationDictionary["group_id"] as? String ?? ""
            let group_post_id = notificationDictionary["group_post_id"] as? String ?? ""
            
            // to = current_logged_in_user
            // we already have to and type
            Database.database().fetchUser(withUID: currentLoggedInUserId) { (toUser) in
                self.userExists(withUID: from_id, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: from_id) { (fromUser) in
                            switch type_string{
                            case "newFollow":
                                // need from
                                var notification = Notification(from: fromUser, to: toUser, type: NotificationType.newFollow, dictionary: notificationDictionary)
                                notification.id = notificationId
                                completion(notification)
                            case "groupJoinRequest":
                                // need from, group
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            var notification = Notification(group: group, from: fromUser, to: toUser, type: NotificationType.groupJoinRequest, dictionary: notificationDictionary)
                                            notification.id = notificationId
                                            completion(notification)
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "group existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            case "newGroupJoin":
                                // need from, group
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            var notification = Notification(group: group, from: fromUser, to: toUser, type: NotificationType.newGroupJoin, dictionary: notificationDictionary)
                                            notification.id = notificationId
                                            completion(notification)
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "group existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            case "newGroupSubscribe":
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            var notification = Notification(group: group, from: fromUser, to: toUser, type: NotificationType.newGroupSubscribe, dictionary: notificationDictionary)
                                            notification.id = notificationId
                                            completion(notification)
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "group existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            case "groupSubscribeRequest":
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            var notification = Notification(group: group, from: fromUser, to: toUser, type: NotificationType.groupSubscribeRequest, dictionary: notificationDictionary)
                                            notification.id = notificationId
                                            completion(notification)
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "group existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            case "unsubscribeRequest":
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            var notification = Notification(group: group, from: fromUser, to: toUser, type: NotificationType.unsubscribeRequest, dictionary: notificationDictionary)
                                            notification.id = notificationId
                                            completion(notification)
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "group existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            case "groupProfileNameEdit":
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            var notification = Notification(group: group, from: fromUser, to: toUser, type: NotificationType.groupProfileNameEdit, dictionary: notificationDictionary)
                                            notification.id = notificationId
                                            completion(notification)
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "group existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            case "groupPrivacyChange":
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            var notification = Notification(group: group, from: fromUser, to: toUser, type: NotificationType.groupPrivacyChange, dictionary: notificationDictionary)
                                            notification.id = notificationId
                                            completion(notification)
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "group existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            case "groupProfilePicEdit":
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            var notification = Notification(group: group, from: fromUser, to: toUser, type: NotificationType.groupProfilePicEdit, dictionary: notificationDictionary)
                                            notification.id = notificationId
                                            completion(notification)
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "group existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            case "groupPostComment":
                                // need from, group, post
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            self.groupPostExists(groupId: group_id, postId: group_post_id, completion: { (post_exists) in
                                                if post_exists{
                                                    Database.database().fetchGroupPost(groupId: group_id, postId: group_post_id, completion: { (post) in
                                                        var notification = Notification(group: group, groupPost: post, from: fromUser, to: toUser, type: NotificationType.groupPostComment, dictionary: notificationDictionary)
                                                        notification.id = notificationId
                                                        completion(notification)
                                                    })
                                                }
                                                else{
                                                    let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "groupPost existance"])
                                                    cancel?(err)
                                                    return
                                                }
                                            })
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "group existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            case "newGroupPost":
                                // need from, group, post
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            self.groupPostExists(groupId: group_id, postId: group_post_id, completion: { (post_exists) in
                                                if post_exists{
                                                    Database.database().fetchGroupPost(groupId: group_id, postId: group_post_id, completion: { (post) in
                                                        var notification = Notification(group: group, groupPost: post, from: fromUser, to: toUser, type: NotificationType.newGroupPost, dictionary: notificationDictionary)
                                                        notification.id = notificationId
                                                        completion(notification)

                                                    })
                                                }
                                                else{
                                                    let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "groupPost existance"])
                                                    cancel?(err)
                                                    return
                                                }
                                            })
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "group existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            case "mentionedInComment":
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            self.groupPostExists(groupId: group_id, postId: group_post_id, completion: { (post_exists) in
                                                if post_exists{
                                                    Database.database().fetchGroupPost(groupId: group_id, postId: group_post_id, completion: { (post) in
                                                        var notification = Notification(group: group, groupPost: post, from: fromUser, to: toUser, type: NotificationType.mentionedInComment, dictionary: notificationDictionary)
                                                        notification.id = notificationId
                                                        completion(notification)
                                                    })
                                                }
                                                else{
                                                    let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "groupPost existance"])
                                                    cancel?(err)
                                                    return
                                                }
                                            })
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "group existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            case "groupJoinInvitation":
                                // need from, group
                                self.groupExists(groupId: group_id, completion: { (exists) in
                                    if exists {
                                        Database.database().fetchGroup(groupId: group_id, completion: { (group) in
                                            var notification = Notification(group: group, from: fromUser, to: toUser, type: NotificationType.groupJoinInvitation, dictionary: notificationDictionary)
                                            notification.id = notificationId
                                            completion(notification)
                                        })
                                    }
                                    else {
                                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "groupPost existance"])
                                        cancel?(err)
                                        return
                                    }
                                })
                            default:
                                return
                            }
                        }
                    }
                    else {
                        let err = NSError(domain:"", code:401, userInfo:[ NSLocalizedDescriptionKey: "user existance"])
                        cancel?(err)
                        return
                    }
                })
            }
        })
    }

    // this creates an array of notification structs
    // it doesn't have to deal with any values of notification, just the id
    func fetchAllNotifications(completion: @escaping ([Notification]) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("notifications").child(currentLoggedInUserId)

        ref.queryOrdered(byChild: "creationDate").observeSingleEvent(of: .value, with: { (snapshot) in
            var notifications = [Notification]()

            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let notificationId = child.key
                sync.enter()
                self.notificationIsValid(notificationId: notificationId, completion: { (valid) in
                    if valid{
                        Database.database().fetchNotification(notificationId: notificationId, completion: { (notification) in
                            notifications.append(notification)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                notifications.sort(by: { (not1, not2) -> Bool in
                    return not1.creationDate.compare(not2.creationDate) == .orderedDescending
                })
                completion(notifications)
                return
            }
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
        
    // toSkip skips the notifications that already have been retrieved (the latest ones)
    func fetchMoreNotifications(endAt: Double, completion: @escaping ([Notification]) -> (), withCancel cancel: ((Error) -> ())?) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let ref = Database.database().reference().child("notifications").child(currentLoggedInUserId)
        // endAt gets included in the next one but it shouldn't
        print("end at is: ", endAt)
        ref.queryOrdered(byChild: "creationDate").queryEnding(atValue: endAt).queryLimited(toLast: 15).observeSingleEvent(of: .value, with: { (snapshot) in
            var notifications = [Notification]()

            let sync = DispatchGroup()
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let notificationId = child.key
                sync.enter()
                self.notificationIsValid(notificationId: notificationId, completion: { (valid) in
                    if valid {
                        Database.database().fetchNotification(notificationId: notificationId, completion: { (notification) in
                            notifications.append(notification)
                            sync.leave()
                        })
                    }
                    else {
                        sync.leave()
                    }
                })
            }
            sync.notify(queue: .main) {
                notifications.sort(by: { (not1, not2) -> Bool in
                    return not1.creationDate.compare(not2.creationDate) == .orderedDescending
                })
                print(notifications.count)
                for notification in notifications {
                    print(notification.id)
                }
                print("-----")
                // queryEnding keeps the oldest entree of the last batch so remove it here if not the first batch
                if endAt != 10000000000000.0 && notifications.count > 0 {
                    notifications.remove(at: 0)
                }
                completion(notifications)
                return
            }
        }) { (err) in
            print("Failed to fetch posts:", err)
            cancel?(err)
        }
    }
    
    func interactWithNotification(notificationId: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let notificationRef = Database.database().reference().child("notifications").child(currentLoggedInUserId).child(notificationId)
        let values = ["interacted": 1] as [String : Any]
        notificationRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to save post to database", err)
                return
            }
            completion(nil)
        }
    }
    
    func hasNotificationBeenInteractedWith(notificationId: String, completion: @escaping (Bool) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let notificationRef = Database.database().reference().child("notifications").child(currentLoggedInUserId).child(notificationId)
        notificationRef.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let notificationDictionary = snapshot.value as? [String: Any] else { return }
            let interacted = notificationDictionary["interacted"] as? Int ?? 0
            if interacted == 1 {
                completion(true)
            }
            else{
                completion(false)
            }
        }) { (err) in
            print("Failed to fetch user from database:", err)
        }
    }
    
    func viewNotification(notificationId: String, completion: @escaping (Error?) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let notificationRef = Database.database().reference().child("notifications").child(currentLoggedInUserId).child(notificationId)
        let values = ["seen": 1] as [String : Any]
        notificationRef.updateChildValues(values) { (err, ref) in
            if let err = err {
                print("Failed to save post to database", err)
                return
            }
            completion(nil)
        }
    }
    
    func hasLatestNotificationBeenSeen(completion: @escaping (Bool) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let notificationsRef = Database.database().reference().child("notifications").child(currentLoggedInUserId)
        notificationsRef.queryOrderedByKey().queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion(true)
                return
            }
            dictionaries.forEach({ (arg) in
                let (_, value) = arg
                guard let dict_values = value as? [String: Any] else { return }
                let seen = dict_values["seen"] as? Int ?? 0
                if seen == 1 {
                    completion(true)
                }
                else{
                    completion(false)
                }
            })
        }) { (err) in
            print("Failed to fetch notification from database:", err)
        }
    }
    
    func isForceCreateGroupEnabled(completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("forceCreateGroupEnabled").observeSingleEvent(of: .value, with: { (snapshot) in
            if let isEnabled = snapshot.value as? Bool {
                print("isEnabled: ", isEnabled)
                completion(isEnabled)
            }
            else {
                // on by default
                completion(true)
            }
        }) { (err) in
            print("Failed to fetch notification from database:", err)
        }
    }
    
    // gets the last 20 notifications and checks to see how many user has not seen
    // only get the last 20 since those are really the only relevent notifications and don't
    // want to retrieve too much
    func numberOfUnseenNotificationInLast20(completion: @escaping (Int) -> ()) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let notificationsRef = Database.database().reference().child("notifications").child(currentLoggedInUserId)
        notificationsRef.queryOrderedByKey().queryLimited(toLast: 20).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                completion(0)
                return
            }
            var count = 0
            dictionaries.forEach({ (arg) in
                let (_, value) = arg
                guard let dict_values = value as? [String: Any] else { return }
                let seen = dict_values["seen"] as? Int ?? 0
                if seen != 1 {
                    count += 1
                }
            })
            completion(count)
        }) { (err) in
            print("Failed to fetch notification from database:", err)
        }
    }
    
//    func hasNotificationBeenSeen(notificationId: String, completion: @escaping (Bool) -> ()) {
//        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
//        let notificationRef = Database.database().reference().child("notifications").child(currentLoggedInUserId).child(notificationId)
//        notificationRef.observeSingleEvent(of: .value, with: { (snapshot) in
//            guard let notificationDictionary = snapshot.value as? [String: Any] else { return }
//            let seen = notificationDictionary["seen"] as? Int ?? 0
//            if seen == 1 {
//                completion(true)
//            }
//            else{
//                completion(false)
//            }
//        }) { (err) in
//            print("Failed to fetch user from database:", err)
//        }
//    }
    
    //MARK: Utilities
    
    func numberOfPostsForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("posts").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
    
    func numberOfPostsForGroup(groupId: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("posts").child(groupId).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
    
    func numberOfSubscriptionsForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("userSubscriptionsCount").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let val = snapshot.value as? Int {
                completion(val)
            }
            else {
                completion(0)
            }
        }
    }
    
    // modified to be total followers of members of group since groups can no longer be followed
//    func numberOfFollowersForGroup(groupId: String, completion: @escaping (Int) -> ()) {
//        Database.database().numberOfMembersForGroup(groupId: groupId) { (membersCount) in
//            var count = 0
//            var iter = 0
//            // get the members of the group
//            Database.database().fetchGroupMembers(groupId: groupId, completion: { (users) in
//                users.forEach({ (user) in
//                    // get the number of followers of the user
//                    Database.database().numberOfFollowersForUser(withUID: user.uid) { (followersCount) in
//                        count += followersCount
//                        iter += 1
//                        if iter == membersCount{
//                            completion(count)
//                        }
//                    }
//                })
//            }) { (_) in
//                completion(0)
//            }
//        }
//    }
    
    func numberOfMembersForGroup(groupId: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("groupMembersCount").child(groupId).observeSingleEvent(of: .value) { (snapshot) in
            if let val = snapshot.value as? Int {
                completion(val)
            }
            else {
                completion(0)
            }
        }
    }
    
    func numberOfSubscribersForGroup(groupId: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("groupFollowersCount").child(groupId).observeSingleEvent(of: .value) { (snapshot) in
            if let val = snapshot.value as? Int {
                completion(val)
            }
            else {
                completion(0)
            }
        }
    }
    
    func numberOfGroupsForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("usersGroupsCount").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let val = snapshot.value as? Int {
                completion(val)
            }
            else {
                completion(0)
            }
        }
    }
    
    func numberOfGroupsForUserGettingsAllGroups(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().fetchAllGroups(withUID: uid, completion: { (groups) in
            completion(groups.count)
        }, withCancel: { (err) in
            completion(0)
        })
    }
    
    func numberOfFollowersForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("userFollowersCount").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let val = snapshot.value as? Int {
                completion(val)
            }
            else {
                completion(0)
            }
        }
    }
    
    func numberOfUsersFollowingForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("userFollowingCount").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let val = snapshot.value as? Int {
                completion(val)
            }
            else {
                completion(0)
            }
        }
    }
    
    func numberOfNotificationsForUser(withUID uid: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("usersNotificationsCount").child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if let val = snapshot.value as? Int {
                completion(val)
            }
            else {
                completion(0)
            }
        }
    }
    
    // MAKE THIS BE LIKE THE OTHERS
    func numberOfCommentsForPost(postId: String, completion: @escaping (Int) -> ()) {
        Database.database().reference().child("comments").child(postId).observeSingleEvent(of: .value) { (snapshot) in
            if let dictionaries = snapshot.value as? [String: Any] {
                completion(dictionaries.count)
            } else {
                completion(0)
            }
        }
    }
    
    func currentVersionIsValid(completion: @escaping (Bool) -> ()) {
        Database.database().reference().child("min_app_version").observeSingleEvent(of: .value) { (snapshot) in
            if let min_app_version = snapshot.value as? Double {
                if let current_app_version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    if let current = Double(current_app_version) {
                        completion(current >= min_app_version)
                    }
                    completion(true)
                }
                completion(true)
            }
            completion(true)
        }
    }
    
    func fetch_link_to_app(completion: @escaping (String) -> ()) {
        Database.database().reference().child("link_to_app").observeSingleEvent(of: .value) { (snapshot) in
            if let link_to_app = snapshot.value as? String {
                completion(link_to_app)
            }
        }
    }
    
    func fetch_link_to_terms(completion: @escaping (String) -> ()) {
        Database.database().reference().child("link_to_terms").observeSingleEvent(of: .value) { (snapshot) in
            if let link_to_terms = snapshot.value as? String {
                completion(link_to_terms)
            }
        }
    }
    
    func fetch_link_to_policy(completion: @escaping (String) -> ()) {
        Database.database().reference().child("link_to_policy").observeSingleEvent(of: .value) { (snapshot) in
            if let link_to_policy = snapshot.value as? String {
                completion(link_to_policy)
            }
        }
    }
}
