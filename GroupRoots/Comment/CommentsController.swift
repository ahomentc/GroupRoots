//
//  CommentsController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 8/3/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

class CommentsController: UICollectionViewController {
    
    var groupPost: GroupPost? {
        didSet {
            fetchComments()
        }
    }
    
    private var comments = [Comment]()
    
    private lazy var commentInputAccessoryView: CommentInputAccessoryView = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        let commentInputAccessoryView = CommentInputAccessoryView(frame: frame)
        commentInputAccessoryView.delegate = self
        return commentInputAccessoryView
    }()
    
    override var canBecomeFirstResponder: Bool { return true }
    
    override var inputAccessoryView: UIView? { return commentInputAccessoryView }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        navigationItem.title = "Comments"
        let textAttributes = [NSAttributedString.Key.font: UIFont(name: "Avenir", size: 22)!, NSAttributedString.Key.foregroundColor : UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        collectionView?.backgroundColor = UIColor.white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .interactive
        collectionView?.register(CommentCell.self, forCellWithReuseIdentifier: CommentCell.cellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchComments), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
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
        collectionView?.refreshControl?.beginRefreshing()
        Database.database().fetchCommentsForPost(withId: postId, completion: { (comments) in
            self.comments = comments
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }
        
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentCell.cellId, for: indexPath) as! CommentCell
        cell.comment = comments[indexPath.item]
        cell.delegate = self
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension CommentsController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dummyCell = CommentCell(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        dummyCell.comment = comments[indexPath.item]
        dummyCell.layoutIfNeeded()
        
        let targetSize = CGSize(width: view.frame.width, height: 1000)
        let estimatedSize = dummyCell.systemLayoutSizeFitting(targetSize)
        let height = max(40 + 8 + 8, estimatedSize.height)
        
        return CGSize(width: view.frame.width, height: height)
    }
}

//MARK: - CommentInputAccessoryViewDelegate

extension CommentsController: CommentInputAccessoryViewDelegate {
    func didSubmit(comment: String) {
        guard let postId = groupPost?.id else { return }
        Database.database().addCommentToPost(withId: postId, text: comment) { (err) in
            if err != nil {
                return
            }
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
}
