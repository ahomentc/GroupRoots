//
//  MainTabBarController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 3/19/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase
import UPCarouselFlowLayout

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        tabBar.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        tabBar.isTranslucent = true
        tabBar.barTintColor = UIColor.clear
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.unselectedItemTintColor = UIColor.white
        tabBar.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.1)
        delegate = self
        
        if Auth.auth().currentUser == nil {
            presentLoginController()
        } else {
            setupViewControllers()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(makeTabBarClear), name: NSNotification.Name(rawValue: "tabBarClear"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(makeTabBarColor), name: NSNotification.Name(rawValue: "tabBarColor"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(makeNotificationIconRead), name: NSNotification.Name(rawValue: "notification_icon_read"), object: nil)
    }
    
    func setupViewControllers() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
//        let homeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_selected"), rootViewController: HomeController(collectionViewLayout: UICollectionViewFlowLayout()))
        
//        let homeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_selected"), rootViewController: HomeFeedController())
        
        
        let layout = UPCarouselFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.spacingMode = UPCarouselFlowLayoutSpacingMode.fixed(spacing: 20)
        let homeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "home_5"), selectedImage: #imageLiteral(resourceName: "home_5"), rootViewController: FeedController(collectionViewLayout: layout))
        
        let searchNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "search_2"), selectedImage: #imageLiteral(resourceName: "search_2"), rootViewController: UserSearchController(collectionViewLayout: UICollectionViewFlowLayout()))
        let plusNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "plus"), selectedImage: #imageLiteral(resourceName: "plus"))
        
        var likeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "bell_2"), selectedImage: #imageLiteral(resourceName: "bell_2"), rootViewController: NotificationsController(collectionViewLayout: UICollectionViewFlowLayout()))
        
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        let userProfileNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "group"), selectedImage: #imageLiteral(resourceName: "group"), rootViewController: userProfileController)
        
        let sync = DispatchGroup()
        sync.enter()
        Database.database().hasLatestNotificationBeenSeen(completion: { (seen) in
            if !seen {
                likeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "bell_2_unread"), selectedImage: #imageLiteral(resourceName: "bell_2"), rootViewController: NotificationsController(collectionViewLayout: UICollectionViewFlowLayout()))
                
            }
            sync.leave()
        })
        
        sync.enter()
        Database.database().fetchUser(withUID: uid) { (user) in
            userProfileController.user = user
            sync.leave()
        }
        
        sync.notify(queue: .main){
            self.viewControllers = [homeNavController, searchNavController, plusNavController, likeNavController, userProfileNavController]
        }
    }
    
    private func presentLoginController() {
        DispatchQueue.main.async { // wait until MainTabBarController is inside UI
            let loginController = LoginController()
            let navController = UINavigationController(rootViewController: loginController)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    private func templateNavController(unselectedImage: UIImage, selectedImage: UIImage, rootViewController: UIViewController = UIViewController()) -> UINavigationController {
        let viewController = rootViewController
        let navController = UINavigationController(rootViewController: viewController)
        navController.tabBarItem.image = unselectedImage
        navController.tabBarItem.selectedImage = selectedImage
        navController.tabBarItem.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: -4, right: 0)
        return navController
    }
    
    @objc private func makeTabBarClear(){
        tabBar.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.1)
        tabBar.unselectedItemTintColor = UIColor.white
    }
    
    @objc private func makeTabBarColor(){
        tabBar.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
        tabBar.unselectedItemTintColor = UIColor.gray
    }
    
    @objc private func makeNotificationIconRead(){
//        self.setupViewControllers()
    }
}

//MARK: - UITabBarControllerDelegate

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let index = viewControllers?.index(of: viewController)
        if index == 3 {
            tabBar.items![3].image = #imageLiteral(resourceName: "bell_2")
            tabBar.backgroundColor = UIColor.clear
            tabBar.unselectedItemTintColor = UIColor.gray
        }
        else if index != 0 {
            tabBar.selectionIndicatorImage = UIImage()
            tabBar.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
            tabBar.unselectedItemTintColor = UIColor.gray
        }
        else{
            tabBar.selectionIndicatorImage = UIImage()
            tabBar.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.1)
            tabBar.unselectedItemTintColor = UIColor.white
        }
        if index == 2 {
//            let layout = UICollectionViewFlowLayout()
//            let photoSelectorController = PhotoSelectorController(collectionViewLayout: layout)
//            let nacController = UINavigationController(rootViewController: photoSelectorController)
            let sharePhotoController = SharePhotoController()
            let nacController = UINavigationController(rootViewController: sharePhotoController)
            nacController.modalPresentationStyle = .fullScreen
            present(nacController, animated: true, completion: nil)
            return false
        }
        return true
    }
}

