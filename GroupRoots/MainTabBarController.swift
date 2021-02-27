import UIKit
import Firebase
import UPCarouselFlowLayout
import FirebaseAuth
import FirebaseDatabase
import YPImagePicker
import Photos

class MainTabBarController: UITabBarController, LargeImageViewControllerDelegate {
    
    var loadedFromNotif: Bool = false {
        didSet {
            if loadedFromNotif {
                self.selectedIndex = 3
            }
        }
    }
    
    var newPost: Bool = false
    var groupToOpen: String = ""
    var groupMemberRequestorsToOpenFor: String = ""
    var groupSubscribeRequestorsToOpenFor: String = ""
    var postAndGroupToOpen: String = ""
    
    private let loadingScreenView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 9
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
        self.view.insertSubview(loadingScreenView, at: 9)
        
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
                        Database.database().groupRootsUserExists(withUID: Auth.auth().currentUser!.uid, completion: { (exists) in
                            if exists {
        //                        self.setupViewControllers()
                            }
                            else {
                                do {
                                    try Auth.auth().signOut()
                                    let loginController = LoginPhoneController()
                                    let navController = UINavigationController(rootViewController: loginController)
                                    navController.modalPresentationStyle = .fullScreen
                                    self.present(navController, animated: true, completion: nil)
                                } catch let err {
                                    print("Failed to sign out:", err)
                                }
                            }
                        })
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
                Database.database().groupRootsUserExists(withUID: Auth.auth().currentUser!.uid, completion: { (exists) in
                    if exists {
                    }
                    else {
                        do {
                            try Auth.auth().signOut()
                            let loginController = LoginPhoneController()
                            let navController = UINavigationController(rootViewController: loginController)
                            navController.modalPresentationStyle = .fullScreen
                            self.present(navController, animated: true, completion: nil)
                        } catch let err {
                            print("Failed to sign out:", err)
                        }
                    }
                })
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
        
        
//        let alert = UIAlertController(title: "test", message: "", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//        self.present(alert, animated: true)
        
        if self.loadedFromNotif {
            self.selectedIndex = 3
        }
        else if self.newPost {
//            self.createNewPost()
            self.goToPostPageForTemp()
        }
        else if self.groupToOpen != "" {
            Database.database().groupExists(groupId: self.groupToOpen, completion: { (exists) in
                if exists {
                    Database.database().fetchGroup(groupId: self.groupToOpen, completion: { (group) in
                        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
                        groupProfileController.group = group
                        groupProfileController.modalPresentationCapturesStatusBarAppearance = true
                        groupProfileController.isModallyPresented = true
                        let navController = UINavigationController(rootViewController: groupProfileController)
                        navController.modalPresentationStyle = .popover
                        self.present(navController, animated: true, completion: nil)
                    })
                }
                else {
                    return
                }
            })
        }
        else if self.groupMemberRequestorsToOpenFor != "" {
            Database.database().groupExists(groupId: self.groupMemberRequestorsToOpenFor, completion: { (exists) in
                if exists {
                    Database.database().fetchGroup(groupId: self.groupMemberRequestorsToOpenFor, completion: { (group) in
                        Database.database().isInGroup(groupId: group.groupId, completion: { (inGroup) in
                            let membersController = MembersController(collectionViewLayout: UICollectionViewFlowLayout())
                            membersController.group = group
                            membersController.isInGroup = inGroup
                            membersController.isMembersView = false
                            membersController.isModallyPresented = true
                            let navController = UINavigationController(rootViewController: membersController)
                            navController.modalPresentationStyle = .popover
                            self.present(navController, animated: true, completion: nil)
                        }) { (err) in
                            return
                        }
                    })
                }
                else {
                    return
                }
            })
        }
        else if self.groupSubscribeRequestorsToOpenFor != "" {
            Database.database().groupExists(groupId: self.groupSubscribeRequestorsToOpenFor, completion: { (exists) in
                if exists {
                    Database.database().fetchGroup(groupId: self.groupSubscribeRequestorsToOpenFor, completion: { (group) in
                        Database.database().isInGroup(groupId: group.groupId, completion: { (inGroup) in
                            let groupFollowersController = GroupFollowersController(collectionViewLayout: UICollectionViewFlowLayout())
                            groupFollowersController.group = group
                            groupFollowersController.isInGroup = inGroup
                            groupFollowersController.isPrivate = group.isPrivate
                            groupFollowersController.isModallyPresented = true
                            if group.isPrivate ?? false {
                                // if group is private enable go to the requestors page
                                groupFollowersController.isFollowersView = false
                            }
                            let navController = UINavigationController(rootViewController: groupFollowersController)
                            navController.modalPresentationStyle = .popover
                            self.present(navController, animated: true, completion: nil)
                        }) { (err) in
                            return
                        }
                    })
                }
                else {
                    return
                }
            })
        }
        else if self.postAndGroupToOpen != "" {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            layout.minimumLineSpacing = CGFloat(0)
            
            let postIdAndGroupIdArr = self.postAndGroupToOpen.split(separator: "_")
            let postId = String(postIdAndGroupIdArr[0])
            let groupId = String(postIdAndGroupIdArr[1])
            
            Database.database().fetchGroupPost(groupId: groupId, postId: postId, completion: { (post) in
                let largeImageViewController = LargeImageViewController(collectionViewLayout: layout)
                largeImageViewController.group = post.group
                largeImageViewController.postToScrollToId = post.id
                largeImageViewController.delegate = self
                let navController = UINavigationController(rootViewController: largeImageViewController)
                navController.modalPresentationStyle = .overCurrentContext
                self.present(navController, animated: true, completion: nil)
            })
        }
    }
    
    func didTapGroup(group: Group) {
        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        groupProfileController.group = group
        groupProfileController.modalPresentationCapturesStatusBarAppearance = true
        navigationController?.pushViewController(groupProfileController, animated: true)
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
//        tabBar.unselectedItemTintColor = UIColor.gray
        tabBar.unselectedItemTintColor = UIColor.darkGray
        
    }
    
    @objc private func makeNotificationIconRead(){
//        self.setupViewControllers()
    }
    
    // --------- Timer Posts ----------
    
//    let timerBackgroundLeft: UIButton = {
//        let view = UIButton(type: .system)
//        view.backgroundColor = UIColor(white: 1, alpha: 1)
//        view.layer.zPosition = 11
//        view.layer.cornerRadius = 10
//        view.layer.shadowOpacity = 0.84
//        view.layer.shadowOffset = .zero
//        view.layer.shadowRadius = 20
//        view.isUserInteractionEnabled = true
//        return view
//    }()
//
//    let timerBackgroundRight: UIButton = {
//        let view = UIButton(type: .system)
//        view.backgroundColor = UIColor(white: 1, alpha: 1)
//        view.layer.zPosition = 11
//        view.layer.cornerRadius = 10
//        view.layer.shadowOpacity = 0.84
//        view.layer.shadowOffset = .zero
//        view.layer.shadowRadius = 20
//        view.isUserInteractionEnabled = true
//        view.addTarget(self, action: #selector(goToPostPageForTemp), for: .touchUpInside)
//        return view
//    }()
//
//    let galleryButton: UIButton = {
//        let label = UIButton(type: .system)
//        label.setTitleColor(UIColor.init(white: 0.1, alpha: 1), for: .normal)
//        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
//        label.contentHorizontalAlignment = .center
//        label.isUserInteractionEnabled = false
//        label.layer.zPosition = 12
//        label.setImage(#imageLiteral(resourceName: "gallery"), for: .normal)
//        label.tintColor = UIColor.init(white: 0.1, alpha: 1)
//        return label
//    }()
//
//    let cameraButton: UIButton = {
//        let label = UIButton(type: .system)
//        label.setTitleColor(UIColor.init(white: 0.1, alpha: 1), for: .normal)
//        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
//        label.contentHorizontalAlignment = .center
//        label.isUserInteractionEnabled = false
//        label.layer.zPosition = 12
////        label.setImage(#imageLiteral(resourceName: "camera_2"), for: .normal)
//        label.setImage(#imageLiteral(resourceName: "hourglass"), for: .normal)
//        label.tintColor = UIColor.init(white: 0.1, alpha: 1)
//        return label
//    }()
//
//    let foreverButton: UIButton = {
//        let label = UIButton(type: .system)
//        label.setTitleColor(UIColor.init(white: 0.1, alpha: 1), for: .normal)
//        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
//        label.contentHorizontalAlignment = .center
//        label.isUserInteractionEnabled = false
//        label.layer.zPosition = 12
//        label.tintColor = UIColor.init(white: 0.1, alpha: 1)
//        label.setTitle("Forever", for: .normal)
//        label.addTarget(self, action: #selector(goToPostPage), for: .touchUpInside)
//        return label
//    }()
//
//    let oneDayButton: UIButton = {
//        let label = UIButton(type: .system)
//        label.setTitleColor(UIColor.init(white: 0.1, alpha: 1), for: .normal)
//        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
//        label.contentHorizontalAlignment = .center
//        label.isUserInteractionEnabled = false
//        label.layer.zPosition = 12
//        label.setTitle("24 Hours", for: .normal)
//        label.addTarget(self, action: #selector(goToPostPageForTemp), for: .touchUpInside)
//        return label
//    }()
//
//    @objc func closeTimerPopup(){
//        UIView.animate(withDuration: 0.5) {
//            self.timerBackgroundLeft.alpha = 0
//            self.timerBackgroundRight.alpha = 0
//            self.foreverButton.alpha = 0
//            self.oneDayButton.alpha = 0
//            self.galleryButton.alpha = 0
//            self.cameraButton.alpha = 0
//        }
//        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
//            self.timerBackgroundLeft.removeFromSuperview()
//            self.timerBackgroundRight.removeFromSuperview()
//            self.foreverButton.removeFromSuperview()
//            self.oneDayButton.removeFromSuperview()
//            self.galleryButton.removeFromSuperview()
//            self.cameraButton.removeFromSuperview()
//        })
//    }
//
//    func createNewPost() {
//        timerBackgroundLeft.alpha = 0
//        timerBackgroundRight.alpha = 0
//        foreverButton.alpha = 0
//        oneDayButton.alpha = 0
//        galleryButton.alpha = 0
//        cameraButton.alpha = 0
//
//        UIView.animate(withDuration: 0.5) {
//            self.timerBackgroundLeft.alpha = 1
//            self.timerBackgroundRight.alpha = 1
//            self.foreverButton.alpha = 1
//            self.oneDayButton.alpha = 1
//            self.galleryButton.alpha = 1
//            self.cameraButton.alpha = 1
//        }
//
//        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
//            self.timerBackgroundLeft.addTarget(self, action: #selector(self.goToPostPage), for: .touchUpInside)
//            self.timerBackgroundLeft.addTarget(self, action: #selector(self.animateLeftBackgroundButtonDown), for: .touchDown)
//            self.timerBackgroundLeft.addTarget(self, action: #selector(self.animateLeftBackgroundButtonDown), for: .touchDragInside)
//            self.timerBackgroundLeft.addTarget(self, action: #selector(self.animateLeftBackgroundButtonUp), for: .touchDragExit)
//            self.timerBackgroundLeft.addTarget(self, action: #selector(self.animateLeftBackgroundButtonUp), for: .touchCancel)
//            self.timerBackgroundLeft.addTarget(self, action: #selector(self.animateLeftBackgroundButtonUp), for: .touchUpInside)
//
//            self.timerBackgroundRight.addTarget(self, action: #selector(self.goToPostPage), for: .touchUpInside)
//            self.timerBackgroundRight.addTarget(self, action: #selector(self.animateRightBackgroundButtonDown), for: .touchDown)
//            self.timerBackgroundRight.addTarget(self, action: #selector(self.animateRightBackgroundButtonDown), for: .touchDragInside)
//            self.timerBackgroundRight.addTarget(self, action: #selector(self.animateRightBackgroundButtonUp), for: .touchDragExit)
//            self.timerBackgroundRight.addTarget(self, action: #selector(self.animateRightBackgroundButtonUp), for: .touchCancel)
//            self.timerBackgroundRight.addTarget(self, action: #selector(self.animateRightBackgroundButtonUp), for: .touchUpInside)
//        })
//
//        timerBackgroundLeft.frame = CGRect(x: 40, y: UIScreen.main.bounds.height/2-75, width: UIScreen.main.bounds.width/2-50, height: 150)
//        self.view.insertSubview(timerBackgroundLeft, at: 11)
//
//        timerBackgroundRight.frame = CGRect(x: 60 + UIScreen.main.bounds.width/2-50 , y: UIScreen.main.bounds.height/2-75, width: UIScreen.main.bounds.width/2-50, height: 150)
//        self.view.insertSubview(timerBackgroundRight, at: 11)
//
//        galleryButton.frame = CGRect(x: 40 + (UIScreen.main.bounds.width/2-50)/2 - 15, y: UIScreen.main.bounds.height/2-40, width: 30, height: 30)
//        self.view.insertSubview(galleryButton, at: 12)
//
////        cameraButton.frame = CGRect(x: 60 + UIScreen.main.bounds.width/2-50 + (UIScreen.main.bounds.width/2-50)/2 - 15, y: UIScreen.main.bounds.height/2-40, width: 30, height: 30)
//        cameraButton.frame = CGRect(x: 60 + UIScreen.main.bounds.width/2-50 + (UIScreen.main.bounds.width/2-50)/2 - 20, y: UIScreen.main.bounds.height/2-45, width: 40, height: 40)
//        self.view.insertSubview(cameraButton, at: 12)
//
//        foreverButton.frame = CGRect(x: 40 + (UIScreen.main.bounds.width/2-50)/2 - 40, y: UIScreen.main.bounds.height/2-0, width: 80, height: 50)
//        self.view.insertSubview(foreverButton, at: 12)
//
//        oneDayButton.frame = CGRect(x: 60 + UIScreen.main.bounds.width/2-50 + (UIScreen.main.bounds.width/2-50)/2 - 40, y: UIScreen.main.bounds.height/2-0, width: 80, height: 50)
//        self.view.insertSubview(oneDayButton, at: 12)
//
//    }
//
//    @objc private func animateLeftBackgroundButtonDown(){
//        self.timerBackgroundLeft.animateButtonDown()
//    }
//
//    @objc private func animateLeftBackgroundButtonUp(){
//        self.timerBackgroundLeft.animateButtonUp()
//    }
//
//    @objc private func animateRightBackgroundButtonDown(){
//        self.timerBackgroundRight.animateButtonDown()
//    }
//
//    @objc private func animateRightBackgroundButtonUp(){
//        self.timerBackgroundRight.animateButtonUp()
//    }
//
    // ---- end timer posts ----
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
//            self.createNewPost()
            self.goToPostPageForTemp()
            return false
        }
        return true
    }
    
    @objc func goToPostPage(){
//        self.closeTimerPopup()
        
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
                    sharePhotoController.isTempPost = false
                    picker.pushViewController(sharePhotoController, animated: true)
                    
                case .video(let video):
                    let location = video.asset?.location
                    let sharePhotoController = SharePhotoController()
                    sharePhotoController.preSelectedGroup = preSelectedGroup
                    sharePhotoController.selectedVideoURL = video.url
                    sharePhotoController.selectedImage = video.thumbnail
                    sharePhotoController.suggestedLocation = location
                    sharePhotoController.isTempPost = false
                    picker.pushViewController(sharePhotoController, animated: true)
                }
            }
        }
        present(picker, animated: true, completion: nil)
    }
    
    @objc func goToPostPageForTemp(){
//        self.closeTimerPopup()
        
        let tempPostCameraController = TempPostCameraController()
        let navController = UINavigationController(rootViewController: tempPostCameraController)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
        
        return
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
                    sharePhotoController.isTempPost = true
                    picker.pushViewController(sharePhotoController, animated: true)
                    
                case .video(let video):
                    let location = video.asset?.location
                    let sharePhotoController = SharePhotoController()
                    sharePhotoController.preSelectedGroup = preSelectedGroup
                    sharePhotoController.selectedVideoURL = video.url
                    sharePhotoController.selectedImage = video.thumbnail
                    sharePhotoController.suggestedLocation = location
                    sharePhotoController.isTempPost = true
                    picker.pushViewController(sharePhotoController, animated: true)
                }
            }
        }
        present(picker, animated: true, completion: nil)
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

extension UIButton {
    @objc func animateButtonDown() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: nil)
    }
    @objc func animateButtonUp() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseOut], animations: {
            self.transform = CGAffineTransform.identity
        }, completion: nil)
    }
}
