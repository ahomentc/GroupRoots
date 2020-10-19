//
//  CommentsController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 8/3/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class CommentsController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var groupPost: GroupPost? {
        didSet {
            fetchComments()
        }
    }
    
    private var comments = [Comment]()
    private var atUsers = [User]()
    
    var searchCollectionView: UICollectionView!
    var commentsCollectionView: UICollectionView!
    
    private let emojiCover: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        backgroundView.backgroundColor = .white
        backgroundView.layer.zPosition = 9
        backgroundView.isUserInteractionEnabled = false
        return backgroundView
    }()
    
    private lazy var laughEmoji: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 10
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.clear
        iv.image =  #imageLiteral(resourceName: "laugh")
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(commentLaugh))
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(tapGestureRecognizer)
        return iv
    }()
    
    private lazy var heartEmoji: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 10
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.clear
        iv.image =  #imageLiteral(resourceName: "heart")
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(commentHeart))
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(tapGestureRecognizer)
        return iv
    }()
    
    private lazy var cryEmoji: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 10
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.clear
        iv.image =  #imageLiteral(resourceName: "cry")
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(commentCry))
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(tapGestureRecognizer)
        return iv
    }()
    
    private lazy var fireEmoji: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 10
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.clear
        iv.image =  #imageLiteral(resourceName: "fire")
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(commentFire))
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(tapGestureRecognizer)
        return iv
    }()
    
    private lazy var eyesEmoji: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 10
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor.clear
        iv.image =  #imageLiteral(resourceName: "eyes")
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(commentEyes))
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(tapGestureRecognizer)
        return iv
    }()
    
    private lazy var commentInputAccessoryView: CommentInputAccessoryView = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        let commentInputAccessoryView = CommentInputAccessoryView(frame: frame)
        commentInputAccessoryView.delegate = self
        return commentInputAccessoryView
    }()
    
    override var canBecomeFirstResponder: Bool { return true }
    
    override var inputAccessoryView: UIView? { return commentInputAccessoryView }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        self.view.backgroundColor = .white
        
        navigationItem.title = "Comments"
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor : UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        let layout = UICollectionViewFlowLayout()
//        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 60)
//        layout.minimumLineSpacing = CGFloat(0)
        
        let navbarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
        commentsCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 70 - navbarHeight), collectionViewLayout: layout)
        commentsCollectionView.delegate = self
        commentsCollectionView.dataSource = self
        commentsCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        commentsCollectionView.register(CommentCell.self, forCellWithReuseIdentifier: CommentCell.cellId)
        commentsCollectionView.backgroundColor = UIColor.white
        commentsCollectionView.alwaysBounceVertical = true
        commentsCollectionView.keyboardDismissMode = .interactive
        self.view.insertSubview(commentsCollectionView, at: 5)
        
        let search_layout = UICollectionViewFlowLayout()
        searchCollectionView = UICollectionView(frame: CGRect(x: 0, y: 70, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height/2), collectionViewLayout: search_layout)
        searchCollectionView.delegate = self
        searchCollectionView.dataSource = self
        searchCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        searchCollectionView.register(UserSearchCell.self, forCellWithReuseIdentifier: UserSearchCell.cellId)
        searchCollectionView.backgroundColor = UIColor.white
        searchCollectionView.isHidden = true
        searchCollectionView.alwaysBounceVertical = true
        searchCollectionView.keyboardDismissMode = .interactive
        self.view.insertSubview(searchCollectionView, at: 5)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchComments), for: .valueChanged)
        commentsCollectionView?.refreshControl = refreshControl
        
        emojiCover.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 120 - navbarHeight, width: UIScreen.main.bounds.width, height: 50)
        self.view.insertSubview(emojiCover, at: 9)
        
        laughEmoji.frame = CGRect(x: UIScreen.main.bounds.width/2-122, y: UIScreen.main.bounds.height - 110 - navbarHeight, width: 24, height: 24)
        self.view.insertSubview(laughEmoji, at: 10)
        
        heartEmoji.frame = CGRect(x: UIScreen.main.bounds.width/2-67, y: UIScreen.main.bounds.height - 110 - navbarHeight, width: 24, height: 24)
        self.view.insertSubview(heartEmoji, at: 10)
        
        fireEmoji.frame = CGRect(x: UIScreen.main.bounds.width/2-12, y: UIScreen.main.bounds.height - 110 - navbarHeight, width: 24, height: 24)
        self.view.insertSubview(fireEmoji, at: 10)
        
        cryEmoji.frame = CGRect(x: UIScreen.main.bounds.width/2+37, y: UIScreen.main.bounds.height - 110 - navbarHeight, width: 24, height: 24)
        self.view.insertSubview(cryEmoji, at: 10)
        
        eyesEmoji.frame = CGRect(x: UIScreen.main.bounds.width/2+92, y: UIScreen.main.bounds.height - 110 - navbarHeight, width: 24, height: 24)
        self.view.insertSubview(eyesEmoji, at: 10)
        
        let lineSeparatorView = UIView()
        lineSeparatorView.backgroundColor = UIColor.init(white: 0.9, alpha: 1)
        lineSeparatorView.frame = CGRect(x: 25, y: UIScreen.main.bounds.height - 120.5 - navbarHeight, width: UIScreen.main.bounds.width - 50, height: 0.5)
        self.view.insertSubview(lineSeparatorView, at: 11)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    @objc private func fetchComments() {
        guard let postId = groupPost?.id else { return }
        self.commentsCollectionView?.refreshControl?.beginRefreshing()
        Database.database().fetchCommentsForPost(withId: postId, completion: { (comments) in
            self.comments = comments
            self.commentsCollectionView.reloadData()
            self.commentsCollectionView?.refreshControl?.endRefreshing()
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
            let cell = commentsCollectionView.dequeueReusableCell(withReuseIdentifier: CommentCell.cellId, for: indexPath) as! CommentCell
            cell.comment = comments[indexPath.item]
            cell.delegate = self
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
            self.commentInputAccessoryView.replaceWithUsername(username: username)
        }
    }
    
    @objc private func commentLaugh(){
        submitEmoji(comment: "😂")
    }
    
    @objc private func commentHeart(){
        submitEmoji(comment: "❤️")
    }
    
    @objc private func commentCry(){
        submitEmoji(comment: "😢")
    }
    
    @objc private func commentFire(){
        submitEmoji(comment: "🔥")
    }
    
    @objc private func commentEyes(){
        submitEmoji(comment: "👀")
    }
    
    func submitEmoji(comment: String) {
        guard let postId = groupPost?.id else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().addCommentToPost(withId: postId, text: comment) { (err) in
            if err != nil {
                return
            }
//            NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
            
            // send the notification each each user in the group
            Database.database().fetchGroupMembers(groupId: self.groupPost!.group.groupId, completion: { (users) in
                users.forEach({ (user) in
                    if currentLoggedInUserId != user.uid {
                        Database.database().createNotification(to: user, notificationType: NotificationType.groupPostComment, group: self.groupPost!.group, groupPost: self.groupPost!) { (err) in
                            if err != nil {
                                return
                            }
                        }
                    }
                })
            }) { (_) in}
            self.commentInputAccessoryView.clearCommentTextField()
            self.fetchComments()
        }
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension CommentsController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.commentsCollectionView {
            let dummyCell = CommentCell(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
            dummyCell.comment = comments[indexPath.item]
            dummyCell.layoutIfNeeded()
            
            let targetSize = CGSize(width: view.frame.width, height: 1000)
            let estimatedSize = dummyCell.systemLayoutSizeFitting(targetSize)
            let height = max(40 + 8 + 8, estimatedSize.height)
            
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

//MARK: - CommentInputAccessoryViewDelegate

extension CommentsController: CommentInputAccessoryViewDelegate {
    
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
                    Database.database().createNotification(to: user, notificationType: NotificationType.groupPostComment, group: self.groupPost!.group, groupPost: self.groupPost!) { (err) in
                        if err != nil {
                            return
                        }
                    }
                })
            }) { (_) in}
            self.commentInputAccessoryView.clearCommentTextField()
            self.fetchComments()
        }
    }
}

//MARK: - CommentCellDelegate

extension CommentsController: CommentCellDelegate {
    func didTapUser(user: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = user
        userProfileController.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapReply(username: String) {
        commentInputAccessoryView.addAtUser(username: username)
    }
}
