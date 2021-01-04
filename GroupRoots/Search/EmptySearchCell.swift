//
//  EmptySearchCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 10/27/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import NVActivityIndicatorView
import Contacts

protocol EmptySearchCellDelegate {
    func didTapUser(user: User)
    func didTapImportContacts()
    func requestImportContactsIfAuth()
    func didFollowFirstUser()
}

class EmptySearchCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, EmptyFeedUserCellDelegate, ImportContactsCellDelegate {
    
    let padding: CGFloat = 12
    
    var delegate: EmptySearchCellDelegate?
    
    var recommendedUsers: [User]?
    var collectionView: UICollectionView!
    
    let recommendedLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        let attributedText = NSMutableAttributedString(string: "Follow suggested users\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSMutableAttributedString(string: "and get auto subscribed to their public groups", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)]))
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.size(22)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    static var cellId = "emptySearchPostCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        collectionView.isHidden = true
        recommendedLabel.isHidden = true
        setRecommendedVisibility()
    }

    private func sharedInit() {
        addSubview(recommendedLabel)
        recommendedLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/10 - 40, width: 300, height: 60)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: 160, height: 200)
        layout.minimumLineSpacing = CGFloat(15)
        collectionView = UICollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height/10 + 20, width: UIScreen.main.bounds.width, height: 210), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView.register(EmptyFeedUserCell.self, forCellWithReuseIdentifier: EmptyFeedUserCell.cellId)
        collectionView.register(ImportContactsCell.self, forCellWithReuseIdentifier: ImportContactsCell.cellId)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isUserInteractionEnabled = true
        collectionView.backgroundColor = .clear
//        collectionView.allowsSelection = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isHidden = true
        insertSubview(collectionView, at: 10)
        
        fetchRecommendedUsers()
        
        // set the shadow of the view's layer
        collectionView.layer.backgroundColor = UIColor.clear.cgColor
        collectionView.layer.shadowColor = UIColor.black.cgColor
        collectionView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        collectionView.layer.shadowOpacity = 0.2
        collectionView.layer.shadowRadius = 4.0
    }
    
    func fetchRecommendedUsers(){
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().fetchFollowRecommendations(withUID: currentLoggedInUserId, completion: { (recommended_users) in
            self.recommendedUsers = recommended_users
            self.setRecommendedVisibility()
            self.collectionView?.reloadData()
            self.requestImportContacts()
            
        }) { (err) in
        }
    }
    
    func requestImportContacts(){
        self.delegate?.requestImportContactsIfAuth()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if CNContactStore.authorizationStatus(for: .contacts) != .authorized && CNContactStore.authorizationStatus(for: .contacts) != .denied {
            return (recommendedUsers?.count ?? 0) + 1
        }
        return recommendedUsers?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if CNContactStore.authorizationStatus(for: .contacts) != .authorized && CNContactStore.authorizationStatus(for: .contacts) != .denied && indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImportContactsCell.cellId, for: indexPath) as! ImportContactsCell
            cell.layer.cornerRadius = 7
            cell.layer.borderWidth = 1.0
            cell.layer.borderColor = UIColor.clear.cgColor
            cell.layer.masksToBounds = true
            cell.delegate = self
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyFeedUserCell.cellId, for: indexPath) as! EmptyFeedUserCell
            if recommendedUsers != nil && recommendedUsers!.count > 0 {
                if CNContactStore.authorizationStatus(for: .contacts) != .authorized && CNContactStore.authorizationStatus(for: .contacts) != .denied {
                    // need to do minus 1 here because first cell is taken up by the import contact cell
                    // so all are shifted right by 1
                    cell.user = recommendedUsers![indexPath.row - 1]
                }
                else {
                    cell.user = recommendedUsers![indexPath.row]
                }
            }
            cell.layer.cornerRadius = 7
            cell.layer.borderWidth = 1.0
            cell.layer.borderColor = UIColor.clear.cgColor
            cell.layer.masksToBounds = true
            cell.delegate = self
            return cell
        }
    }
    
    func setRecommendedVisibility() {
        guard let recommendedUsers = recommendedUsers else { return }
        if recommendedUsers.count == 0 && (CNContactStore.authorizationStatus(for: .contacts) == .authorized || CNContactStore.authorizationStatus(for: .contacts) == .denied) {
            collectionView.isHidden = true
            recommendedLabel.isHidden = true
        }
        else {
            collectionView.isHidden = false
            recommendedLabel.isHidden = false
        }
    }
    
    func didTapUser(user: User) {
        self.delegate?.didTapUser(user: user)
    }
    
    // Follow the user, and remove from the collectionview
    // Don't need to set 1000 as that happens in cloud function
    func didFollowUser(user: User) {
        Database.database().followUser(withUID: user.uid) { (err) in
            if err != nil {
                return
            }
            // remove from recommendedUsers and refresh the collectionview
            if self.recommendedUsers != nil && self.recommendedUsers!.count > 0 {
                self.recommendedUsers!.removeAll(where: { $0.uid == user.uid })
            }
            self.collectionView.reloadData()
            
            // check if this is the first time the user has followed someone and if so, show the popup
            Database.database().hasFollowedSomeone(completion: { (hasFollowed) in
                if !hasFollowed {
                    // add them to followed someone
                    // send notification to show popup
                    Database.database().followedSomeone() { (err) in }
                    self.delegate?.didFollowFirstUser()
                }
            })
            
            Database.database().createNotification(to: user, notificationType: NotificationType.newFollow) { (err) in
                if err != nil {
                    return
                }
            }
        }
    }
    
    func didRemoveUser(user: User) {
        // set to 1000 and remove from collectionview
        Database.database().removeFromFollowRecommendation(withUID: user.uid) { (err) in
            if err != nil {
                return
            }
            if self.recommendedUsers != nil && self.recommendedUsers!.count > 0 {
                self.recommendedUsers!.removeAll(where: { $0.uid == user.uid })
            }
            self.collectionView.reloadData()
        }
    }
    
    func didTapImportContacts() {
        self.delegate?.didTapImportContacts()
    }
    
}

extension EmptySearchCell: UICollectionViewDelegateFlowLayout {
    
    private func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlowLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 160, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
    }
}

