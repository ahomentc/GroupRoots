//
//  HomeController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/28/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class HomeController: HomePostCellViewController {
   
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        configureNavigationBar()
        
        collectionView?.backgroundColor = .white
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: HomePostCell.cellId)
        collectionView?.backgroundView = HomeEmptyStateView()
        collectionView?.backgroundView?.alpha = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateHomeFeed, object: nil)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshControl
        
        fetchAllPosts()
    }
    
    private func configureNavigationBar() {
        navigationItem.title = "DayOnes"
        let textAttributes = [NSAttributedString.Key.font: UIFont(name: "Gill Sans", size: 18)!]
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "inbox").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: nil)
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
    }

    private func fetchAllPosts() {
        showEmptyStateViewIfNeeded()
//        fetchFollowingUserPosts()
        fetchFollowingUserGroupPosts()
    }

    private func fetchFollowingUserPosts() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        collectionView?.refreshControl?.beginRefreshing()
        
        Database.database().reference().child("following").child(currentLoggedInUserId).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userIdsDictionary = snapshot.value as? [String: Any] else { return }
            
            userIdsDictionary.forEach({ (groupId, value) in
                
                Database.database().fetchAllGroupPosts(groupId: groupId, completion: { (countAndPosts) in
                    
                    let posts = countAndPosts[1] as! [GroupPost]
                    self.groupPosts.append(contentsOf: posts)
                    
                    self.groupPosts.sort(by: { (p1, p2) -> Bool in
                        return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                    })
                    
                    self.collectionView?.reloadData()
                    self.collectionView?.refreshControl?.endRefreshing()
                    
                }, withCancel: { (err) in
                    self.collectionView?.refreshControl?.endRefreshing()
                })
            })
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }
    
    // For now, only public groups
    // When have private groups, add a check to see if have access
    // For now, fetch all posts of all groups of all following
    // In the future, will only show some of the posts, the ones from groups that have
    //  the highest score. Score will be determined by how many of the people you're following
    //  are in the group, and how many people you're in a group with are in the group.
    private func fetchFollowingUserGroupPosts() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        collectionView?.refreshControl?.beginRefreshing()
        
        // get the list of users you follow
        // for each user:
        //      get the list of groups they're a member of
        //          for each group:
        //              get the posts of the group
        Database.database().reference().child("following").child(currentLoggedInUserId).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let userIdsDictionary = snapshot.value as? [String: Any] else { return }
            userIdsDictionary.forEach({ (arg) in
                let (uid, _) = arg
                Database.database().fetchAllGroups(withUID: uid, completion: { (groups) in
                    // we are given an [group] array
                    groups.forEach({ (groupItem) in
                        Database.database().fetchAllGroupPosts(groupId: groupItem.groupId, completion: { (countAndPosts) in
                            let posts = countAndPosts[1] as! [GroupPost]
                            self.groupPosts.append(contentsOf: posts)
                            
                            // sort the groupPosts
                            // this should not be here, since it is inside the loop
                            // should be outside and only run once all group posts are collected
                            // for now keep here since I don't know how to get past the async call inside the loop problem
                            // will fix soon
                            self.groupPosts.sort(by: { (p1, p2) -> Bool in
                                return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                            })
                            self.collectionView?.reloadData()
                            self.collectionView?.refreshControl?.endRefreshing()
                        }, withCancel: { (err) in
                            self.collectionView?.refreshControl?.endRefreshing()
                        })
                    })
                }, withCancel: { (err) in
                    self.collectionView?.refreshControl?.endRefreshing()
                })
            })
        }) { (err) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }
    
    override func showEmptyStateViewIfNeeded() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
//        Database.database().numberOfFollowingForUser(withUID: currentLoggedInUserId) { (followingCount) in
//            Database.database().numberOfPostsForUser(withUID: currentLoggedInUserId, completion: { (postCount) in
//                
//                if followingCount == 0 && postCount == 0 {
//                    UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
//                        self.collectionView?.backgroundView?.alpha = 1
//                    }, completion: nil)
//                    
//                } else {
//                    self.collectionView?.backgroundView?.alpha = 0
//                }
//            })
//        }
    }
    
    @objc private func handleRefresh() {
        groupPosts.removeAll()
        fetchAllPosts()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groupPosts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePostCell.cellId, for: indexPath) as! HomePostCell
        if indexPath.item < groupPosts.count {
            cell.groupPost = groupPosts[indexPath.item]
        }
        cell.delegate = self
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension HomeController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dummyCell = HomePostCell(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 1000))
        dummyCell.groupPost = groupPosts[indexPath.item]
        dummyCell.layoutIfNeeded()
        
        var height: CGFloat = dummyCell.header.bounds.height
        height += view.frame.width
        height += 24 + 2 * dummyCell.padding //bookmark button + padding
        height += dummyCell.captionLabel.intrinsicContentSize.height + 8
        return CGSize(width: view.frame.width, height: height)
    }
}
