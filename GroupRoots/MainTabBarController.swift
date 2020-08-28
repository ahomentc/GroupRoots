import UIKit
import Firebase
import UPCarouselFlowLayout
import FirebaseAuth
import FirebaseDatabase

class MainTabBarController: UITabBarController {
    
    private let loadingScreenView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 10
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0, alpha: 1)
        return iv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        loadingScreenView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        loadingScreenView.layer.cornerRadius = 0
        loadingScreenView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        loadingScreenView.image =  #imageLiteral(resourceName: "Splash4")
        self.view.insertSubview(loadingScreenView, at: 10)
        
        self.view.backgroundColor = UIColor.white
        
        tabBar.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        tabBar.isTranslucent = true
        tabBar.barTintColor = UIColor.clear
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.unselectedItemTintColor = UIColor.white
        tabBar.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0)
        
        delegate = self
        
        // check if the current version of the app is valid or needs to be updated
        // only run this if there is internet
        if Reachability.isConnectedToNetwork(){
            Database.database().currentVersionIsValid(completion: { (is_valid) in
                if is_valid {
                    self.loadingScreenView.isHidden = true
                    if Auth.auth().currentUser == nil {
                        self.presentLoginController()
                    } else {
                        self.setupViewControllers()
                    }
                }
                else {
                    // present force update screen
                    self.loadingScreenView.isHidden = true
                    self.presentForceUpdateController()
                }
            })
        } else {
            self.loadingScreenView.isHidden = true
            if Auth.auth().currentUser == nil {
                self.presentLoginController()
            } else {
                self.setupViewControllers()
            }
        }
        
        // this will continuously listen for refreshes in notifications and then refresh the notifications button
        if let current_user = Auth.auth().currentUser {
            // update when receive update notifications
            let uid = current_user.uid
            let notification_ref = Database.database().reference().child("notifications").child(uid)
            notification_ref.observe(.value) { snapshot in
                Database.database().hasLatestNotificationBeenSeen(completion: { (seen) in
                    if !seen {
                        let likeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "bell_2_unread"), selectedImage: #imageLiteral(resourceName: "bell_2"), rootViewController: NotificationsController(collectionViewLayout: UICollectionViewFlowLayout()))
                        if self.viewControllers != nil && self.viewControllers!.count > 3 {
                            self.viewControllers![3] = likeNavController
                        }
                        Database.database().numberOfUnseenNotificationInLast20(completion: { (numUnseen) in
                            UIApplication.shared.applicationIconBadgeNumber = numUnseen
                        })
                    }
                })
            }
            
//            // update when recieve addition for membership
//            let membership_ref_add = Database.database().reference().child("users").child(uid).child("groups")
//            membership_ref_add.observe(.childAdded, with: { (snapshot) -> Void in
//                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
//                NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
//            })
//
//            // update when recieve addition for subscription
//            let subscription_ref_add = Database.database().reference().child("groupsFollowing").child(uid)
//            subscription_ref_add.observe(.childAdded, with: { (snapshot) -> Void in
//                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
//                NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
//            })
//
//            // update when recieve removal for membership
//            let membership_ref_remove = Database.database().reference().child("users").child(uid).child("groups")
//            membership_ref_remove.observe(.childRemoved, with: { (snapshot) -> Void in
//                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
//                NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
//            })
//
//            // update when recieve removal for subscription
//            let subscription_ref_remove = Database.database().reference().child("groupsFollowing").child(uid)
//            subscription_ref_remove.observe(.childRemoved, with: { (snapshot) -> Void in
//                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
//                NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
//            })
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(makeTabBarClear), name: NSNotification.Name(rawValue: "tabBarClear"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(makeTabBarColor), name: NSNotification.Name(rawValue: "tabBarColor"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(makeNotificationIconRead), name: NSNotification.Name(rawValue: "notification_icon_read"), object: nil)
    }
    
    func setupViewControllers() {
        guard (Auth.auth().currentUser?.uid) != nil else { return }

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.minimumLineSpacing = CGFloat(0)
        
        let homeNavController = self.templateNavController(unselectedImage: #imageLiteral(resourceName: "home_5"), selectedImage: #imageLiteral(resourceName: "home_5"), rootViewController: ProfileFeedController(collectionViewLayout: layout))
        
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


        sync.notify(queue: .main){
            self.viewControllers = [homeNavController, searchNavController, plusNavController, likeNavController, userProfileNavController]
        }
        self.viewControllers = [homeNavController, searchNavController, plusNavController, likeNavController, userProfileNavController]
    }
    
    private func presentLoginController() {
        DispatchQueue.main.async { // wait until MainTabBarController is inside UI
            let loginController = LoginController()
            let navController = UINavigationController(rootViewController: loginController)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    private func presentForceUpdateController() {
        DispatchQueue.main.async { // wait until MainTabBarController is inside UI
            let forceUpdateController = ForceUpdateController()
            let navController = UINavigationController(rootViewController: forceUpdateController)
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
//        tabBar.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.1)
        tabBar.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0)
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
        if index == 2 {
            let sharePhotoController = SharePhotoController()
            if let topController = UIApplication.topViewController() {
                if type(of: topController) == GroupProfileController.self {
                    let groupProfile = topController as? GroupProfileController
                    sharePhotoController.preSelectedGroup = groupProfile?.group
                }
            }
            
            let nacController = UINavigationController(rootViewController: sharePhotoController)
            nacController.modalPresentationStyle = .fullScreen
            present(nacController, animated: true, completion: nil)
            return false
        }
        return true
    }
}


extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
