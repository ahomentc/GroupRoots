//
//  MessagesController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/4/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import PanModal

protocol MessagesControllerDelegate {
    func didCloseMessage()
}

class MessagesController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, PanModalPresentable {
    
    var hasLoaded = false
    
    var delegate: MessagesControllerDelegate?
    
    var panScrollable: UIScrollView? {
        return nil
    }
    
//    var shortFormHeight: PanModalHeight {
//        if hasLoaded {
//            return .contentHeight(550)
//        }
//        return .maxHeight
//    }
    

    var shortFormHeight: PanModalHeight {
//        return .maxHeight
        return .contentHeight(550)
    }

    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(100)
    }

    var anchorModalToLongForm: Bool {
        return false
    }
    
    var groupPost: GroupPost? {
        didSet {
            fetchComments()
        }
    }
    
    private var comments = [Comment]()
    private var atUsers = [User]()
    
    var searchCollectionView: UICollectionView!
    var commentsCollectionView: UICollectionView!
    
    var original_height = 0.0
    
    var commentsReference = DatabaseReference()
    
    private lazy var messageInputAccessoryView: MessageInputAccessoryView = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        let messageInputAccessoryView = MessageInputAccessoryView(frame: frame)
        messageInputAccessoryView.delegate = self
        return messageInputAccessoryView
    }()
    
    override var canBecomeFirstResponder: Bool { return true }
    
    override var inputAccessoryView: UIView? { return messageInputAccessoryView }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.black
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        hasLoaded = true
        
        self.view.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
        
        navigationItem.title = "Messages"
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor : UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.black
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        let layout = UICollectionViewFlowLayout()
        
        let navbarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
        commentsCollectionView = UICollectionView(frame: CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 550 - 70 - navbarHeight), collectionViewLayout: layout)
        commentsCollectionView.delegate = self
        commentsCollectionView.dataSource = self
        commentsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        commentsCollectionView.register(MessageCell.self, forCellWithReuseIdentifier: MessageCell.cellId)
        commentsCollectionView.backgroundColor = UIColor.clear
        commentsCollectionView.alwaysBounceVertical = true
        commentsCollectionView.keyboardDismissMode = .onDrag
        self.view.insertSubview(commentsCollectionView, at: 5)
        
        let search_layout = UICollectionViewFlowLayout()
        searchCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 70 - navbarHeight), collectionViewLayout: search_layout)
        searchCollectionView.delegate = self
        searchCollectionView.dataSource = self
        searchCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        searchCollectionView.register(UserSearchCell.self, forCellWithReuseIdentifier: UserSearchCell.cellId)
        searchCollectionView.backgroundColor = UIColor.clear
        searchCollectionView.isHidden = true
        searchCollectionView.alwaysBounceVertical = true
//        searchCollectionView.keyboardDismissMode = .interactive
        searchCollectionView.keyboardDismissMode = .onDrag
        self.view.insertSubview(searchCollectionView, at: 5)
        
//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget(self, action: #selector(fetchComments), for: .valueChanged)
//        commentsCollectionView?.refreshControl = refreshControl
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        commentsReference.removeAllObservers()
        self.delegate?.didCloseMessage()
    }
    
    @objc private func fetchComments() {
        guard let postId = groupPost?.id else { return }
        self.commentsCollectionView?.refreshControl?.beginRefreshing()
        Database.database().fetchCommentsForPost(withId: postId, completion: { (comments) in
            self.comments = comments
            self.commentsCollectionView.reloadData()
            self.commentsCollectionView.performBatchUpdates(nil, completion: {
                (result) in
                self.commentsCollectionView!.scrollToItem(at: IndexPath.init(row: comments.count - 1, section: 0), at: UICollectionView.ScrollPosition.bottom, animated: false)

                if comments.count > 5 {
                    let bottomOffset = CGPoint(x: 0, y: self.commentsCollectionView.contentSize.height - self.commentsCollectionView.bounds.height + self.commentsCollectionView.contentInset.bottom)
                    self.commentsCollectionView.setContentOffset(bottomOffset, animated: true)
                }
            })
            self.commentsCollectionView?.refreshControl?.endRefreshing()
        }) { (err) in }
        
        // this will continuously listen for refreshes in comments
        commentsReference = Database.database().reference().child("comments").child(postId)
        commentsReference.queryOrderedByKey().queryLimited(toLast: 1).observe(.value) { snapshot in
            self.commentsCollectionView?.refreshControl?.beginRefreshing()
            
            guard let dictionaries = snapshot.value as? [String: Any] else {
                return
            }
            
            var comments = [Comment]()
                
            let sync = DispatchGroup()
            dictionaries.forEach({ (key, value) in
                guard let commentDictionary = value as? [String: Any] else { return }
                guard let uid = commentDictionary["uid"] as? String else { return }
                sync.enter()
                Database.database().userExists(withUID: uid, completion: { (exists) in
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
                // check if the first comment is the same as previous one and don't put if there
                if !(self.comments.count > 0 && comments.count > 0 && self.comments[self.comments.count-1].creationDate == comments[0].creationDate) {
                    self.comments += comments
                }
                self.comments.sort(by: { (comment1, comment2) -> Bool in
                    return comment1.creationDate.compare(comment2.creationDate) == .orderedAscending
                })
                self.commentsCollectionView.reloadData()
                self.commentsCollectionView?.refreshControl?.endRefreshing()
                return
            }
        }
    }
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.commentsCollectionView {
            return comments.count
        }
        else {
            return atUsers.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.commentsCollectionView {
            let cell = commentsCollectionView.dequeueReusableCell(withReuseIdentifier: MessageCell.cellId, for: indexPath) as! MessageCell
            cell.comment = comments[indexPath.item]
            cell.delegate = self
            
            var hasPrev = false
            var hasNext = false
            if indexPath.item < comments.count {
                // hasPrev means comment before was also user's.
                
                if indexPath.item - 1 >= 0 {
                    let prevCommentUser = comments[indexPath.item - 1].user.uid
                    if prevCommentUser == cell.comment?.user.uid {
                        hasPrev = true
                    }
                }
                if indexPath.item + 1 < comments.count {
                    let nextCommentUser = comments[indexPath.item + 1].user.uid
                    if nextCommentUser == cell.comment?.user.uid {
                        hasNext = true
                    }
                }
            }
            cell.hasPrev = hasPrev
            cell.hasNext = hasNext
            
            return cell
        }
        else {
            let cell = searchCollectionView.dequeueReusableCell(withReuseIdentifier: UserSearchCell.cellId, for: indexPath) as! UserSearchCell
            cell.user = atUsers[indexPath.item]
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.searchCollectionView {
            let user = atUsers[indexPath.item]
            let username = user.username
            self.messageInputAccessoryView.replaceWithUsername(username: username)
        }
    }
    
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.comments.count > 3 {
//                self.commentsCollectionView.bounds.origin.y = 20 + keyboardSize.height
                let bottomOffset = CGPoint(x: 0, y: self.commentsCollectionView.contentSize.height - self.commentsCollectionView.bounds.height + self.commentsCollectionView.contentInset.bottom + keyboardSize.height - 20)
                self.commentsCollectionView.setContentOffset(bottomOffset, animated: true)
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.comments.count > 3 {
//            self.commentsCollectionView.bounds.origin.y = 20
        }
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension MessagesController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.commentsCollectionView {
            let comment = comments[indexPath.item]
            var hasPrev = false
            var hasNext = false
            if indexPath.item < comments.count {
                // hasPrev means comment before was also user's.
                
                if indexPath.item - 1 >= 0 {
                    let prevCommentUser = comments[indexPath.item - 1].user.uid
                    if prevCommentUser == comment.user.uid {
                        hasPrev = true
                    }
                }
                if indexPath.item + 1 < comments.count {
                    let nextCommentUser = comments[indexPath.item + 1].user.uid
                    if nextCommentUser == comment.user.uid {
                        hasNext = true
                    }
                }
            }
            
            let dummyCell = MessageCell(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
            dummyCell.comment = comment
            dummyCell.hasPrev = hasPrev
            dummyCell.hasNext = hasNext
            dummyCell.setNeedsLayout()
            dummyCell.layoutIfNeeded()
            
            let targetSize = CGSize(width: view.frame.width, height: dummyCell.bubble_height)
            var height = max(dummyCell.bubble_height + 5, 30)
            
            if !hasPrev {
                height += 30
            }

            return CGSize(width: view.frame.width, height: height)
        }
        else {
            return CGSize(width: view.frame.width, height: 60)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 50)
    }
}

//MARK: - MessageInputAccessoryViewDelegate

extension MessagesController: MessageInputAccessoryViewDelegate {
    
    func didChangeAtStatus(isInAt: Bool) {
        if isInAt {
            commentsCollectionView.isHidden = true
            searchCollectionView.isHidden = false
        }
        else {
            commentsCollectionView.isHidden = false
            searchCollectionView.isHidden = true
        }
    }
    
    func displaySearchUsers(users: [User]) {
        self.atUsers = users
        self.commentsCollectionView?.refreshControl?.beginRefreshing()
        self.searchCollectionView.reloadData()
        self.commentsCollectionView?.refreshControl?.endRefreshing()
    }
    
    func submitAtUsers(users: [User]) {
        guard let groupPost = groupPost else { return }
        for user in users {
            Database.database().createNotification(to: user, notificationType: NotificationType.mentionedInComment, group: groupPost.group, groupPost: groupPost) { (err) in
                if err != nil {
                    return
                }
            }
        }
    }
    
    func didSubmit(comment: String) {
        guard let postId = groupPost?.id else { return }
        Database.database().addCommentToPost(withId: postId, text: comment) { (err) in
            if err != nil {
                return
            }
//            NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
            
            // send the notification each each user in the group
            Database.database().fetchGroupMembers(groupId: self.groupPost!.group.groupId, completion: { (users) in
                users.forEach({ (user) in
                    Database.database().createNotification(to: user, notificationType: NotificationType.groupPostComment, group: self.groupPost!.group, groupPost: self.groupPost!, message: comment) { (err) in
                        if err != nil {
                            return
                        }
                    }
                })
            }) { (_) in}
            self.messageInputAccessoryView.clearCommentTextField()
//            self.fetchComments()
        }
    }
}

//MARK: - CommentCellDelegate

extension MessagesController: MessageCellDelegate {
    func didTapUser(user: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = user
        userProfileController.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapReply(username: String) {
        messageInputAccessoryView.addAtUser(username: username)
    }
}

