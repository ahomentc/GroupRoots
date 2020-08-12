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
        return label
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
        
        selectImage()
        
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
        
        fetchAllGroups()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        textView.endEditing(true)
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        textView.endEditing(true)
        self.selectedGroupId = groups[indexPath.row].groupId
        
        if last_selected_indexpath != nil {
            let old_cell = collectionView.cellForItem(at: last_selected_indexpath!)
            old_cell?.layer.backgroundColor = UIColor.white.cgColor
        }
        
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        
        last_selected_indexpath = indexPath
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groups.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupCell.cellId, for: indexPath) as! GroupCell
        cell.group = groups[indexPath.item]
        if last_selected_indexpath == indexPath {
            cell.layer.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        }
        return cell
    }
    
    private func fetchAllGroups() {
        Database.database().fetchAllGroups(withUID: "", completion: { (groups) in
            self.groups = groups
            
            let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
            let displayWidth: CGFloat = self.view.frame.width
            let displayHeight: CGFloat = self.view.frame.height
            
            let layout = UICollectionViewFlowLayout()
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
            
            self.collectionView = UICollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height/3 + 10, width: displayWidth, height: displayHeight - barHeight - UIScreen.main.bounds.height/3), collectionViewLayout: layout)
            self.collectionView.delegate = self
            self.collectionView.dataSource = self
            self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
            self.collectionView?.register(GroupCell.self, forCellWithReuseIdentifier: GroupCell.cellId)
            self.collectionView.backgroundColor = UIColor.white
            self.view.addSubview(self.collectionView)
            
        }) { (_) in
        }
    }
    
    
    // NEEDS WORK.
    // Should work. Still to be tested.
    // Clean it up make it better, make error detection too since its currently commented out
    @objc private func handleShare() {
        guard let postImage = selectedImage else { return }
        let caption = textView.text
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        if selectedGroupId == "" { return }
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        textView.isUserInteractionEnabled = false
        
        Database.database().createGroupPost(withImage: postImage, withVideo: self.selectedVideoURL, caption: caption ?? "", groupId: self.selectedGroupId, completion: { (postId) in
            if postId == "" {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                self.textView.isUserInteractionEnabled = true
                
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
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
            self.dismiss(animated: true, completion: nil)
        })
    }
}

extension SharePhotoController: UICollectionViewDelegateFlowLayout {
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
    }
}




