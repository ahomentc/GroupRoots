//
//  SharePhotoController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/27/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase
import Photos
import YPImagePicker
import FirebaseAuth
import FirebaseDatabase

class SharePhotoController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var selectedImage: UIImage? {
        didSet {
            imageView.image = selectedImage
        }
    }
    
    var preSelectedGroup: Group?

    var selectedVideoURL: URL?
    
    private var groups = [Group]()
    private var selectedGroupId = ""
    private var collectionView: UICollectionView!
    var last_selected_indexpath: IndexPath?
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let textView: PlaceholderTextView = {
        let tv = PlaceholderTextView()
        tv.placeholderLabel.text = "Add caption"
        tv.placeholderLabel.font = UIFont.systemFont(ofSize: 14)
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.autocorrectionType = .no
        return tv
    }()
    
    let selectGroupLabel: UILabel = {
        let label = UILabel()
        label.text = "Select a Group"
        label.textAlignment = .center
        label.backgroundColor = UIColor.white
        label.font = UIFont(name: "Avenir", size: 22)!
        label.isHidden = true
        return label
    }()
    
    private let selectedGroupLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Posting to ", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        label.attributedText = attributedText
        return label
    }()
    
    private let selectedGroupnameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        label.attributedText = attributedText
        return label
    }()
    
    private let groupImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        return iv
    }()
    
    private let userOneImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 0
        return iv
    }()
    
    private let userTwoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 0
        return iv
    }()
    
    private let groupnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        return label
    }()
    
    private lazy var selectOtherGroupButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(postToDiffGroup), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Post to a different group", for: .normal)
        return button
    }()
    
//    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        view.backgroundColor = UIColor.white
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(handleShare))
        
        layoutViews()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateGroupsToPostTo, object: nil)
    }

    @objc private func selectImage(){
        var config = YPImagePickerConfiguration()
        config.library.isSquareByDefault = false
        config.shouldSaveNewPicturesToAlbum = false
        config.library.mediaType = .photoAndVideo
        config.hidesStatusBar = false
        config.startOnScreen = YPPickerScreen.library
        config.targetImageSize = .cappedTo(size: 600)
        config.video.compression = AVAssetExportPresetMediumQuality
        let picker = YPImagePicker(configuration: config)
        
        picker.didFinishPicking { [unowned picker] items, cancelled in
            self.scrollToPreSelected()
            if cancelled {
                print("Picker was canceled")
                picker.dismiss(animated: true, completion: nil)
                return
            }
            _ = items.map { print("🧀 \($0)") }
            if let firstItem = items.first {
                switch firstItem {
                case .photo(let photo):
                    self.selectedImage = photo.image
                    picker.dismiss(animated: true, completion: nil)
                case .video(let video):
                    self.selectedVideoURL = video.url
                    self.selectedImage = video.thumbnail
                    picker.dismiss(animated: true, completion: nil)
                }
            }
        }
        present(picker, animated: true, completion: nil)
    }
    
    @objc private func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    private func scrollToPreSelected(){
        // check to see if preSelectedGroup has a value, if so then select and scroll to it
        guard let preSelected = self.preSelectedGroup else { return }
        
        // loop through groups to find index of preSelected
        var index = 0
        for group in self.groups {
            if group.groupId == preSelected.groupId {
                break
            }
            index += 1
        }
        let newIndexPath = IndexPath(row: index, section: 0)
        if index > 2 {
            // scroll to the cell that is before the preselected one
            let previousOfNewIndexPath = IndexPath(row: index-1, section: 0)
            self.collectionView.scrollToItem(at: previousOfNewIndexPath, at: .top, animated: false)
        }
        self.selectedGroupId = preSelected.groupId
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
            let cell = self.collectionView.cellForItem(at: newIndexPath)
            cell?.layer.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
            self.last_selected_indexpath = newIndexPath
        })
    }
    
    private func layoutViews() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        view.addSubview(containerView)
        containerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.safeAreaLayoutGuide.leftAnchor, right: view.safeAreaLayoutGuide.rightAnchor, height: 122)
                
        containerView.addSubview(imageView)
        imageView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, paddingTop: 15, paddingLeft: 15, paddingBottom: 8, width: 100)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(singleTap)
        imageView.layer.cornerRadius = 10
        
        
        containerView.addSubview(textView)
        textView.anchor(top: containerView.topAnchor, left: imageView.rightAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 10, paddingLeft: 10)
        
        containerView.addSubview(selectGroupLabel)
        selectGroupLabel.anchor(top: textView.bottomAnchor, left: containerView.leftAnchor, right: containerView.rightAnchor, paddingTop: UIScreen.main.bounds.height/50)
        
        self.view.addSubview(selectedGroupLabel)
        selectedGroupLabel.anchor(top: containerView.bottomAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: UIScreen.main.bounds.height/12)
        
        self.selectedGroupLabel.attributedText = NSMutableAttributedString(string: "Posting to", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        
        self.view.addSubview(groupImageView)
        groupImageView.anchor(top: selectedGroupLabel.bottomAnchor, left: self.view.leftAnchor, paddingTop: 15, paddingLeft: UIScreen.main.bounds.width/2 - 40, width: 80, height: 80)
//        groupImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        groupImageView.layer.cornerRadius = 80 / 2
        groupImageView.isHidden = true
        
        self.view.addSubview(userOneImageView)
        userOneImageView.anchor(top: selectedGroupLabel.bottomAnchor, left: self.view.leftAnchor, paddingTop: 20, paddingLeft: UIScreen.main.bounds.width/2 - 50, width: 70, height: 70)
//        userOneImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        userOneImageView.layer.cornerRadius = 70/2
        userOneImageView.isHidden = true
        userOneImageView.image = UIImage()
        
        self.view.addSubview(userTwoImageView)
        userTwoImageView.anchor(top: selectedGroupLabel.bottomAnchor, left: self.view.leftAnchor, paddingTop: 17, paddingLeft: UIScreen.main.bounds.width/2 - 20, width: 75, height: 75)
//        userTwoImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        userTwoImageView.layer.cornerRadius = 75/2
        userTwoImageView.isHidden = true
        userTwoImageView.image = UIImage()
        
        selectOtherGroupButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 + 30, width: 300, height: 50)
        selectOtherGroupButton.layer.cornerRadius = 14
        self.view.insertSubview(selectOtherGroupButton, at: 4)
        
        self.view.addSubview(selectedGroupnameLabel)
        selectedGroupnameLabel.anchor(top: groupImageView.bottomAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 10)
        
        fetchAllGroups()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        textView.endEditing(true)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        textView.endEditing(true)
        
        if preSelectedGroup != nil {
            self.selectedGroupId = groups[indexPath.row].groupId
            
            if last_selected_indexpath != nil {
                let old_cell = collectionView.cellForItem(at: last_selected_indexpath!)
                old_cell?.layer.backgroundColor = UIColor.white.cgColor
            }
            
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        }
        else {
            if indexPath.row == 0 {
                let createGroupController = CreateGroupController()
                let navController = UINavigationController(rootViewController: createGroupController)
                navController.modalPresentationStyle = .fullScreen
                present(navController, animated: true, completion: nil)
            }
            else {
                self.selectedGroupId = groups[indexPath.row - 1].groupId
                
                if last_selected_indexpath != nil {
                    let old_cell = collectionView.cellForItem(at: last_selected_indexpath!)
                    old_cell?.layer.backgroundColor = UIColor.white.cgColor
                }
                
                let cell = collectionView.cellForItem(at: indexPath)
                cell?.layer.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
                
                last_selected_indexpath = indexPath
            }
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if preSelectedGroup != nil {
            return groups.count
        }
        else {
            return groups.count + 1
        }
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if preSelectedGroup != nil { // preSelected group means that "post to new group" doesn't appear
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupCell.cellId, for: indexPath) as! GroupCell
            if indexPath.item < groups.count {
                cell.group = groups[indexPath.item]
            }
            cell.user = User(uid: "", dictionary: ["":0])
            if last_selected_indexpath == indexPath {
                cell.layer.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
            }
            return cell
        }
        else {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewGroupInPostCell.cellId, for: indexPath) as! NewGroupInPostCell
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupCell.cellId, for: indexPath) as! GroupCell
                if indexPath.item - 1 < groups.count {
                    cell.group = groups[indexPath.item - 1]
                }
                cell.user = User(uid: "", dictionary: ["":0])
                if last_selected_indexpath == indexPath {
                    cell.layer.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
                }
                return cell
            }
        }
        
    }
    
    @objc func handleRefresh() {
        fetchAllGroups()
    }
    
    private func fetchAllGroups() {
        Database.database().fetchAllGroups(withUID: "", completion: { (groups) in
            self.groups = groups
            
            if self.preSelectedGroup == nil {
                self.selectGroupLabel.isHidden = false
                self.selectedGroupLabel.isHidden = true
                self.selectedGroupnameLabel.isHidden = true
                self.selectOtherGroupButton.isHidden = true
                
                let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
                let displayWidth: CGFloat = self.view.frame.width
                let displayHeight: CGFloat = self.view.frame.height
                
                let layout = UICollectionViewFlowLayout()
                layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                
                self.collectionView = UICollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height/4, width: displayWidth, height: displayHeight - barHeight - UIScreen.main.bounds.height/4 + 10), collectionViewLayout: layout)
                self.collectionView.delegate = self
                self.collectionView.dataSource = self
                self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
                self.collectionView?.register(GroupCell.self, forCellWithReuseIdentifier: GroupCell.cellId)
                self.collectionView?.register(NewGroupInPostCell.self, forCellWithReuseIdentifier: NewGroupInPostCell.cellId)
                self.collectionView.backgroundColor = UIColor.white
                self.view.addSubview(self.collectionView)
            }
            else {
                Database.database().isInGroup(groupId: self.preSelectedGroup!.groupId, completion: { (inGroup) in
                    if inGroup {
                        // in group so show preselected group
                        self.selectGroupLabel.isHidden = true // set up groupname if there is none
                        self.selectedGroupLabel.isHidden = false
                        self.selectedGroupnameLabel.isHidden = false
                        self.selectOtherGroupButton.isHidden = false
                        Database.database().fetchFirstNGroupMembers(groupId: self.preSelectedGroup!.groupId, n: 3, completion: { (first_n_users) in
                            self.loadGroupMembersIcon(group: self.preSelectedGroup!, first_n_users: first_n_users)
                            if self.preSelectedGroup!.groupname == "" {
                                var usernames = ""
                                if first_n_users.count > 2 {
                                    usernames = first_n_users[0].username + " & " + first_n_users[1].username + " & " + first_n_users[2].username
                                    if usernames.count > 21 {
                                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                                        usernames = usernames + "..."
                                    }
                                }
                                else if first_n_users.count == 2 {
                                    usernames = first_n_users[0].username + " & " + first_n_users[1].username
                                    if usernames.count > 21 {
                                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                                        usernames = usernames + "..."
                                    }
                                }
                                else if first_n_users.count == 1 {
                                    usernames = first_n_users[0].username
                                    if usernames.count > 21 {
                                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                                        usernames = usernames + "..."
                                    }
                                }
                                self.selectedGroupnameLabel.attributedText = NSMutableAttributedString(string: usernames, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20)])
                            }
                            else {
                                self.selectedGroupnameLabel.attributedText = NSMutableAttributedString(string: self.preSelectedGroup!.groupname.replacingOccurrences(of: "_-a-_", with: " "), attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20)])
                            }
                        }) { (_) in }
                    }
                    else {
                        // not in group so show group selection instead
                        self.selectGroupLabel.isHidden = false
                        self.selectedGroupLabel.isHidden = true
                        self.selectedGroupnameLabel.isHidden = true
                        self.selectOtherGroupButton.isHidden = true
                        
                        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
                        let displayWidth: CGFloat = self.view.frame.width
                        let displayHeight: CGFloat = self.view.frame.height
                        
                        let layout = UICollectionViewFlowLayout()
                        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                        
                        self.collectionView = UICollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height/4, width: displayWidth, height: displayHeight - barHeight - UIScreen.main.bounds.height/4 + 10), collectionViewLayout: layout)
                        self.collectionView.delegate = self
                        self.collectionView.dataSource = self
                        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
                        self.collectionView?.register(GroupCell.self, forCellWithReuseIdentifier: GroupCell.cellId)
                        self.collectionView.backgroundColor = UIColor.white
                        self.view.addSubview(self.collectionView)
                    }
                }) { (err) in
                    return
                }
            }
        }) { (_) in}
    }
    
    @objc private func postToDiffGroup(){
        self.selectGroupLabel.isHidden = false
        self.selectedGroupLabel.isHidden = true
        self.selectedGroupnameLabel.isHidden = true
        self.selectOtherGroupButton.isHidden = true
        
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        
        self.collectionView = UICollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height/4, width: displayWidth, height: displayHeight - barHeight - UIScreen.main.bounds.height/4 + 10), collectionViewLayout: layout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        self.collectionView?.register(GroupCell.self, forCellWithReuseIdentifier: GroupCell.cellId)
        self.collectionView.backgroundColor = UIColor.white
        self.view.addSubview(self.collectionView)
        
        self.collectionView.layoutIfNeeded()
        self.scrollToPreSelected()
    }
    
    
    // NEEDS WORK.
    // Should work. Still to be tested.
    // Clean it up make it better, make error detection too since its currently commented out
    @objc private func handleShare() {
        guard let postImage = selectedImage else { return }
        let caption = textView.text
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        if selectedGroupId == "" && preSelectedGroup == nil { return }

        if selectedGroupId == "" && preSelectedGroup != nil {
            selectedGroupId = preSelectedGroup!.groupId
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        textView.isUserInteractionEnabled = false
        
        Database.database().createGroupPost(withImage: postImage, withVideo: self.selectedVideoURL, caption: caption ?? "", groupId: self.selectedGroupId, completion: { (postId) in
            if postId == "" {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.textView.isUserInteractionEnabled = true
                
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                self.dismiss(animated: true, completion: nil)
                return
            }
            Database.database().groupExists(groupId: self.selectedGroupId, completion: { (exists) in
                if exists {
                    Database.database().fetchGroup(groupId: self.selectedGroupId, completion: { (group) in
                        Database.database().fetchGroupPost(groupId: group.groupId, postId: postId, completion: { (post) in
                            // send the notification each each user in the group
                            Database.database().fetchGroupMembers(groupId: group.groupId, completion: { (members) in
                                members.forEach({ (member) in
                                    if member.uid != currentLoggedInUserId{
                                        Database.database().createNotification(to: member, notificationType: NotificationType.newGroupPost, group: group, groupPost: post) { (err) in
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
                else {
                    return
                }
            })
            NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
            NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("updatedUser"), object: nil)
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    private func loadGroupMembersIcon(group: Group?, first_n_users: [User]){
        guard let group = group else { return }
        Database.database().fetchFirstNGroupMembers(groupId: group.groupId, n: 3, completion: { (first_n_users) in
            if let groupProfileImageUrl = group.groupProfileImageUrl {
                self.groupImageView.loadImage(urlString: groupProfileImageUrl)
                self.groupImageView.isHidden = false
                self.userOneImageView.isHidden = true
                self.userTwoImageView.isHidden = true
            } else {
                self.groupImageView.isHidden = true
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
    
}

extension SharePhotoController: UICollectionViewDelegateFlowLayout {
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
    }
}




