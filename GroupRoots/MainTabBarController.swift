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
    }
    
    func setupViewControllers() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
//        let homeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_selected"), rootViewController: HomeController(collectionViewLayout: UICollectionViewFlowLayout()))
        
//        let homeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_selected"), rootViewController: HomeFeedController())
        
        
        let layout = UPCarouselFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.spacingMode = UPCarouselFlowLayoutSpacingMode.fixed(spacing: 20)
        let homeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_unselected"), rootViewController: FeedController(collectionViewLayout: layout))
        
        let searchNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "search_unselected"), selectedImage: #imageLiteral(resourceName: "search_selected"), rootViewController: UserSearchController(collectionViewLayout: UICollectionViewFlowLayout()))
        let plusNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "plus"), selectedImage: #imageLiteral(resourceName: "plus"))
        let likeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "notification_unselected"), selectedImage: #imageLiteral(resourceName: "notification_unselected"), rootViewController: NotificationsController(collectionViewLayout: UICollectionViewFlowLayout()))

        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        let userProfileNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "profile_unselected"), selectedImage: #imageLiteral(resourceName: "profile_unselected"), rootViewController: userProfileController)
        
        Database.database().fetchUser(withUID: uid) { (user) in
            userProfileController.user = user
        }
        
        viewControllers = [homeNavController, searchNavController, plusNavController, likeNavController, userProfileNavController]
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
}

//MARK: - UITabBarControllerDelegate

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let index = viewControllers?.index(of: viewController)
        if index != 0 {
            tabBar.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
            tabBar.unselectedItemTintColor = UIColor.gray
        }
        else{
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

