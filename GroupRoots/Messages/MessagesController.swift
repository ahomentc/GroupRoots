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
import NVActivityIndicatorView

protocol MessagesControllerDelegate {
    func didCloseMessage()
    func didTapUser(user: User)
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
            
            // new message was sent so update the lastestViewedMessage
            print("setting latest viewed message")
            if groupPost != nil && groupPost!.id != "" {
                Database.database().setLatestViewPostMessage(postId: groupPost!.id, completion: { _ in })
            }
        }
    }
    
    let activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width/2 - 35, y: UIScreen.main.bounds.height/2 - 35, width: 70, height: 70), type: NVActivityIndicatorType.circleStrokeSpin)
    
    private var comments = [Comment]()
    private var atUsers = [User]()
    
    var searchCollectionView: UICollectionView!
    var commentsCollectionView: UICollectionView!
    
    var original_height = 0.0
    
    var fetched_initial_comments = false
    
    var commentsReference = DatabaseReference()
        
    private lazy var messageInputAccessoryView: MessageInputAccessoryView = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        let messageInputAccessoryView = MessageInputAccessoryView(frame: frame)
        messageInputAccessoryView.delegate = self
        return messageInputAccessoryView
    }()
    
    override var canBecomeFirstResponder: Bool { return true }
    
    override var inputAccessoryView: MessageInputAccessoryView? { return messageInputAccessoryView }
    
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
        commentsCollectionView.alpha = 0
        self.view.insertSubview(commentsCollectionView, at: 5)
        
        activityIndicatorView.frame = CGRect(x: UIScreen.main.bounds.width/2 - 35, y: (550 - 70 - navbarHeight)/2 - 35, width: 70, height: 70)
        self.view.insertSubview(activityIndicatorView, at: 20)
        activityIndicatorView.isHidden = false
        activityIndicatorView.color = .white
        activityIndicatorView.startAnimating()
        
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
        
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
        commentsReference.removeAllObservers()
        self.delegate?.didCloseMessage()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
    }
    
    @objc private func fetchComments() {
        guard let postId = groupPost?.id else { return }
        Database.database().fetchCommentsForPost(withId: postId, completion: { (comments) in
            self.comments = comments
            
            if comments.count == 0 {
                UIView.animate(withDuration: 0.3) {
                    self.commentsCollectionView.alpha = 1
                    self.activityIndicatorView.alpha = 0
                }
                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in
                    self.activityIndicatorView.isHidden = true
                }
            }
            
            if self.commentsCollectionView != nil {
                self.commentsCollectionView.reloadData()
            }
            else {
                return
            }
            
            self.fetched_initial_comments = true
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                self.commentsCollectionView!.scrollToItem(at: IndexPath.init(row: self.comments.count - 1, section: 0), at: UICollectionView.ScrollPosition.bottom, animated: true)
            }
            
            self.commentsCollectionView.performBatchUpdates(nil, completion: {
                (result) in
                if self.comments.count > 5 {
//                    let bottomOffset = CGPoint(x: 0, y: self.commentsCollectionView.contentSize.height - self.commentsCollectionView.bounds.height + self.commentsCollectionView.contentInset.bottom + 100)
//                    self.commentsCollectionView.setContentOffset(bottomOffset, animated: true)
                    self.commentsCollectionView!.scrollToItem(at: IndexPath.init(row: self.comments.count - 1, section: 0), at: UICollectionView.ScrollPosition.bottom, animated: false)
                    let navbarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
                    self.commentsCollectionView.frame = CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 550 - 70 - navbarHeight - 50)
                }
                // this will continuously listen for refreshes in comments
                self.commentsReference = Database.database().reference().child("comments").child(postId)
                self.commentsReference.queryOrderedByKey().queryLimited(toLast: 1).observe(.value) { snapshot in
                    guard let dictionaries = snapshot.value as? [String: Any] else {
                        return
                    }
                    
                    var comments = [Comment]()
                        
                    let sync = DispatchGroup()
                    dictionaries.forEach({ (key, value) in
                        guard let commentDictionary = value as? [String: Any] else { return }
                        guard let uid = commentDictionary["uid"] as? String else { return }
                        
                        print(commentDictionary)
                        
                        if uid == "bot" {
                            let botUserValues = ["username": "Groupbot", "name": "Bot", "bio": "", "profileImageUrl": ""]
                            let comment = Comment(user: User(uid: "bot", dictionary: botUserValues), dictionary: commentDictionary)
                            comments.append(comment)
                        }
                        else {
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
                        }
                    })
                    sync.notify(queue: .main) {
                        // check if the first comment is the same as previous one and don't put if there
                        if !(self.comments.count > 0 && comments.count > 0 && self.comments[self.comments.count-1].creationDate == comments[0].creationDate) {
                            if self.fetched_initial_comments {
                                self.comments += comments
                            }
                        }
                        
                        // new message was sent so update the lastestViewedMessage
                        if self.groupPost != nil && self.groupPost!.id != "" {
                            Database.database().setLatestViewPostMessage(postId: self.groupPost!.id, completion: { _ in })
                        }
                        
                        self.comments.sort(by: { (comment1, comment2) -> Bool in
                            return comment1.creationDate.compare(comment2.creationDate) == .orderedAscending
                        })
                        if self.commentsCollectionView != nil {
                            self.commentsCollectionView.reloadData()
                        }

                        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                            self.commentsCollectionView!.scrollToItem(at: IndexPath.init(row: self.comments.count - 1, section: 0), at: UICollectionView.ScrollPosition.bottom, animated: true)
                            UIView.animate(withDuration: 0.3) {
                                self.commentsCollectionView.alpha = 1
                                self.activityIndicatorView.alpha = 0
                            }
                            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in
                                self.activityIndicatorView.isHidden = true
                            }
                        }
                    }
                }
            })
        }) { (err) in }
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
//                let bottomOffset = CGPoint(x: 0, y: self.commentsCollectionView.contentSize.height - self.commentsCollectionView.bounds.height + self.commentsCollectionView.contentInset.bottom + keyboardSize.height - 20)
//                self.commentsCollectionView.setContentOffset(bottomOffset, animated: false)
                
                let navbarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
                commentsCollectionView.frame = CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 550 - 70 - navbarHeight - keyboardSize.height)
                self.commentsCollectionView!.scrollToItem(at: IndexPath.init(row: self.comments.count - 1, section: 0), at: UICollectionView.ScrollPosition.bottom, animated: true)

            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.comments.count > 3 {
//            self.commentsCollectionView.bounds.origin.y = 20
            
            let navbarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
            commentsCollectionView.frame = CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height: 550 - 70 - navbarHeight)
            self.commentsCollectionView!.scrollToItem(at: IndexPath.init(row: self.comments.count - 1, section: 0), at: UICollectionView.ScrollPosition.bottom, animated: true)
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
            Database.database().numberOfMembersForGroup(groupId: self.groupPost!.group.groupId) { (membersCount) in
                if membersCount < 50 {
                    Database.database().fetchGroupMembers(groupId: self.groupPost!.group.groupId, completion: { (users) in
                        users.forEach({ (user) in
                            Database.database().createNotification(to: user, notificationType: NotificationType.groupPostComment, group: self.groupPost!.group, groupPost: self.groupPost!, message: comment) { (err) in
                                if err != nil {
                                    return
                                }
                            }
                        })
                    }) { (_) in}
                }
            }
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
        
        self.dismiss(animated: true, completion: {
            self.delegate?.didTapUser(user: user)
        })
    }
    
    func didTapReply(username: String) {
        messageInputAccessoryView.addAtUser(username: username)
    }
}


extension MessagesController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        self.inputAccessoryView?.commentTextView.resignFirstResponder()
    }
}
