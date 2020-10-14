import UIKit
import Firebase
import UPCarouselFlowLayout
import FirebaseAuth
import FirebaseDatabase
import YPImagePicker
import Photos

class MainTabBarController: UITabBarController {
    
    var loadedFromNotif: Bool = false {
        didSet {
            if loadedFromNotif {
                self.selectedIndex = 3
            }
        }
    }
    
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
                        
                        Database.database().openedApp(completion: { _ in })
                        
//                        Database.database().groupRootsUserExists(withUID: Auth.auth().currentUser!.uid, completion: { (exists) in
//                            if exists {
//        //                        self.setupViewControllers()
//                                print("exists")
//                            }
//                            else {
//                                print("doesn't exist")
//                                do {
//                                    try Auth.auth().signOut()
//                                    let loginController = LoginPhoneController()
//                                    let navController = UINavigationController(rootViewController: loginController)
//                                    navController.modalPresentationStyle = .fullScreen
//                                    self.present(navController, animated: true, completion: nil)
//                                } catch let err {
//                                    print("Failed to sign out:", err)
//                                }
//                            }
//                        })
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
                
                // presentLoginController if GroupRoots non-auth user doesn't exist
//                Database.database().groupRootsUserExists(withUID: Auth.auth().currentUser!.uid, completion: { (exists) in
//                    if exists {
//                        print("exists")
//                    }
//                    else {
//                        print("doesn't exist")
//                        do {
//                            try Auth.auth().signOut()
//                            let loginController = LoginPhoneController()
//                            let navController = UINavigationController(rootViewController: loginController)
//                            navController.modalPresentationStyle = .fullScreen
//                            self.present(navController, animated: true, completion: nil)
//                        } catch let err {
//                            print("Failed to sign out:", err)
//                        }
//                    }
//                })
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
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(makeTabBarClear), name: NSNotification.Name(rawValue: "tabBarClear"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(makeTabBarColor), name: NSNotification.Name(rawValue: "tabBarColor"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(makeTabBarDisappear), name: NSNotification.Name(rawValue: "tabBarDisappear"), object: nil)
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
            else {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
            sync.leave()
        })


        sync.notify(queue: .main){
            self.viewControllers = [homeNavController, searchNavController, plusNavController, likeNavController, userProfileNavController]
        }
        self.viewControllers = [homeNavController, searchNavController, plusNavController, likeNavController, userProfileNavController]
        
        if loadedFromNotif {
            self.selectedIndex = 3
        }
    }
    
    private func presentLoginController() {
        DispatchQueue.main.async { // wait until MainTabBarController is inside UI
            let loginController = LoginPhoneController()
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
    
    @objc private func makeTabBarDisappear(){
        tabBar.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0)
        tabBar.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 0.5)
        tabBar.unselectedItemTintColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)
    }
    
    @objc private func makeTabBarClear(){
        tabBar.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0)
        tabBar.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        tabBar.unselectedItemTintColor = UIColor.white
    }
    
    @objc private func makeTabBarColor(){
        tabBar.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
        tabBar.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
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
        if index != 0 {
            if let topController = UIApplication.topViewController() {
                if type(of: topController) == LargeImageViewController.self {
                    NotificationCenter.default.post(name: NSNotification.Name("closeFullScreenViewController"), object: nil)
                }
            }
//            NotificationCenter.default.post(name: NSNotification.Name("closeFullScreenViewController"), object: nil)
        }
        if index == 3 {
            tabBar.items![3].image = #imageLiteral(resourceName: "bell_2")
//            tabBar.backgroundColor = UIColor.clear
//            tabBar.unselectedItemTintColor = UIColor.gray
        }
        if index == 2 {
            var config = YPImagePickerConfiguration()
            config.library.isSquareByDefault = false
            config.shouldSaveNewPicturesToAlbum = false
            config.library.mediaType = .photoAndVideo
            config.hidesStatusBar = false
            config.startOnScreen = YPPickerScreen.library
            config.targetImageSize = .cappedTo(size: 600)
            config.video.compression = AVAssetExportPresetMediumQuality
            let picker = YPImagePicker(configuration: config)
            
            var preSelectedGroup: Group?
            if let topController = UIApplication.topViewController() {
                if type(of: topController) == GroupProfileController.self {
                    let groupProfile = topController as? GroupProfileController
                    preSelectedGroup = groupProfile?.group
                }
            }
            
            picker.didFinishPicking { [unowned picker] items, cancelled in
                if cancelled {
                    print("Picker was canceled")
                    picker.dismiss(animated: true, completion: nil)
                    return
                }
                _ = items.map { print("🧀 \($0)") }
                if let firstItem = items.first {
                    switch firstItem {
                    case .photo(let photo):
                        let location = photo.asset?.location
                        // need to do self.scrollToPreSelected() too
                        let sharePhotoController = SharePhotoController()
                        sharePhotoController.preSelectedGroup = preSelectedGroup
                        sharePhotoController.selectedImage = photo.image
                        sharePhotoController.suggestedLocation = location
                        picker.pushViewController(sharePhotoController, animated: true)
                        
                    case .video(let video):
                        let location = video.asset?.location
                        let sharePhotoController = SharePhotoController()
                        sharePhotoController.preSelectedGroup = preSelectedGroup
                        sharePhotoController.selectedVideoURL = video.url
                        sharePhotoController.selectedImage = video.thumbnail
                        sharePhotoController.suggestedLocation = location
                        picker.pushViewController(sharePhotoController, animated: true)
                    }
                }
            }
            present(picker, animated: true, completion: nil)
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

//extension AppDelegate: UNUserNotificationCenterDelegate {
//  func userNotificationCenter(
//    _ center: UNUserNotificationCenter,
//    didReceive response: UNNotificationResponse,
//    withCompletionHandler completionHandler: @escaping () -> Void) {
//
////    // 1
////    let userInfo = response.notification.request.content.userInfo
////
////    // 2
////    if let aps = userInfo["aps"] as? [String: AnyObject],
////      let newsItem = NewsItem.makeNewsItem(aps) {
////
////      (window?.rootViewController as? UITabBarController)?.selectedIndex = 1
////
////      // 3
////      if response.actionIdentifier == Identifiers.viewAction,
////        let url = URL(string: newsItem.link) {
////        let safari = SFSafariViewController(url: url)
////        window?.rootViewController?.present(safari, animated: true,
////                                            completion: nil)
////      }
////    }
//
////    self.MainTabBarController.selectedIndex = 4
//    (window?.rootViewController as? UITabBarController)?.selectedIndex = 4
//
//    // 4
//    completionHandler()
//  }
//}

