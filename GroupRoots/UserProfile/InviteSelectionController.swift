//
//  InviteSelectionController.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/28/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

// Invitation is simply a notification

class InviteSelectionController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    var groups : [Group]?
    
    var user: User?

    var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
//        navigationController?.isNavigationBarHidden = true
        view.backgroundColor = .white
        navigationItem.title = "Invite"
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(doneSelected))
        navigationItem.leftBarButtonItem?.tintColor = .black
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 80)
        self.collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - 30), collectionViewLayout: layout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        self.collectionView?.register(GroupCell.self, forCellWithReuseIdentifier: GroupCell.cellId)
        self.collectionView.backgroundColor = UIColor.white
        view.addSubview(self.collectionView)
        
        fetchAllGroups()
    }
    
    @objc private func doneSelected(){
        self.dismiss(animated: true, completion: nil)
    }
    
    private func fetchAllGroups() {
        self.collectionView?.refreshControl?.beginRefreshing()

        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().fetchAllGroups(withUID: currentLoggedInUserId, completion: { (groups) in
            self.groups = groups
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }) { (_) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.user == nil { return }
        if self.groups == nil { return }
        Database.database().createNotification(to: self.user!, notificationType: NotificationType.groupJoinInvitation, group: self.groups![indexPath.item]) { (err) in
            if err != nil {
                return
            }
            Database.database().addUserToGroupInvited(withUID: self.user!.uid, groupId: self.groups![indexPath.item].groupId) { (err) in
                if err != nil {
                    return
                }
            }
        }
        
        // send notification
        // popup saying added to group
        self.dismiss(animated: true, completion: nil)
    }

    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groups?.count ?? 0
    }

    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupCell.cellId, for: indexPath) as! GroupCell
        cell.group = groups?[indexPath.item]
        cell.user = User(uid: "", dictionary: ["":0])
        return cell
    }
    
}

extension InviteSelectionController: UICollectionViewDelegateFlowLayout {
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
    }
}

//MARK: - UITextFieldDelegate

extension InviteSelectionController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}




