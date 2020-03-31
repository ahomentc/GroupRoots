//
//  HomeCellViewController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 8/15/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

class HomePostCellViewController: UICollectionViewController, HomePostCellDelegate {
  
    var groupPosts = [GroupPost]()
    var members = [User]()
    var memberRequestors = [User]()
    var followers = [User]()
    var pendingFollowers = [User]()
    
    // key is groupId
    // value is an array of GroupPosts of that group
    var groupPostsDict: [String:[GroupPost]] = [:]
    
    // 2d representation of the dict, same as dict but with no values
    // later, just use the dict but convert it to this after all data is loaded in
    var groupPosts2D = [[GroupPost]]()
    
    func showEmptyStateViewIfNeeded() {}
    
    //MARK: - HomePostCellDelegate
    
    func didTapComment(groupPost: GroupPost) {
        let commentsController = CommentsController(collectionViewLayout: UICollectionViewFlowLayout())
        commentsController.groupPost = groupPost
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func didTapUser(user: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = user
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func didTapGroup(group: Group) {
        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        groupProfileController.group = group
        navigationController?.pushViewController(groupProfileController, animated: true)
    }
    
    func didTapOptions(groupPost: GroupPost) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        Database.database().isInGroup(groupId: groupPost.group.groupId, completion: { (inGroup) in
            if inGroup {
                if let deleteAction = self.deleteAction(forPost: groupPost) {
                    alertController.addAction(deleteAction)
                }
            }
            self.present(alertController, animated: true, completion: nil)
        }) { (err) in
            return
        }
        
    }
    
    private func deleteAction(forPost groupPost: GroupPost) -> UIAlertAction? {
        let action = UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
            
            let alert = UIAlertController(title: "Delete Post?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (_) in
                
                Database.database().deleteGroupPost(groupId: groupPost.group.groupId, postId: groupPost.id) { (_) in
                    if let postIndex = self.groupPosts.index(where: {$0.id == groupPost.id}) {
                        self.groupPosts.remove(at: postIndex)
                        self.collectionView?.reloadData()
                        self.showEmptyStateViewIfNeeded()
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }
    
    func didLike(for cell: HomePostCell) {
        guard let indexPath = collectionView?.indexPath(for: cell) else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        var groupPost = groupPosts[indexPath.item]
        
        if groupPost.likedByCurrentUser {
            Database.database().reference().child("likes").child(groupPost.id).child(uid).removeValue { (err, _) in
                if let err = err {
                    print("Failed to unlike post:", err)
                    return
                }
                groupPost.likedByCurrentUser = false
                groupPost.likes = groupPost.likes - 1
                self.groupPosts[indexPath.item] = groupPost
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadItems(at: [indexPath])
                }
            }
        } else {
            let values = [uid : 1]
            Database.database().reference().child("likes").child(groupPost.id).updateChildValues(values) { (err, _) in
                if let err = err {
                    print("Failed to like post:", err)
                    return
                }
                // send the notification each each user in the group
                Database.database().fetchGroupMembers(groupId: groupPost.group.groupId, completion: { (users) in
                    users.forEach({ (user) in
                        if user.uid != currentLoggedInUserId{
                            Database.database().createNotification(to: user, notificationType: NotificationType.groupPostLiked, group: groupPost.group, groupPost: groupPost) { (err) in
                                if err != nil {
                                    return
                                }
                            }
                        }
                    })
                }) { (_) in}
                
                groupPost.likedByCurrentUser = true
                groupPost.likes = groupPost.likes + 1
                self.groupPosts[indexPath.item] = groupPost
                UIView.performWithoutAnimation {
                    self.collectionView?.reloadItems(at: [indexPath])
                }
            }
        }
    }
}
