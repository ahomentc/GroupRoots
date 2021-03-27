import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseCore
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        print("hi there")
        
        
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
//        Database.database().isPersistenceEnabled = true
        let pushManager = PushNotificationManager()
        pushManager.registerForPushNotifications()
        
        UNUserNotificationCenter.current().requestAuthorization(options: .badge) { (granted, error) in
            if error != nil {
                // success!
            }
        }
        
        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.backgroundColor = .black
        let mainTabBarController = MainTabBarController()
        let remoteNotif = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [String: Any]
        if remoteNotif != nil {
            let aps = remoteNotif!["aps"] as? [String:Any]
            if aps != nil {
                let category = aps!["category"] as? String
                mainTabBarController.messageFromAppDelegate = category ?? ""
                if category == nil {
                    // default action when no category is to go to notifications page
                    mainTabBarController.loadedFromNotif = true
                }
                else {
                    // do custom action based on category
                    if category!.contains("new_post") {
                        // takes you to the new post page
                        mainTabBarController.newPost = true
                    }
                    else if category!.contains("open_post") {
                        print("open post selected")
                        // for viewed by notification
                        // add a thing to open viewers directly too
                        
                        // opens a specific post
                        // format of open_post_<post_id>_<group_id>
                        let postIdAndGroupId = category!.replacingOccurrences(of: "open_post_", with: "")
                        mainTabBarController.postAndGroupToOpen = postIdAndGroupId
//                        mainTabBarController.messageFromAppDelegate = postIdAndGroupId
                    }
                    else if category!.contains("open_message") {
                        print("open post selected")
                        // for viewed by notification
                        // add a thing to open viewers directly too
                        
                        // opens a specific post
                        // format of open_post_<post_id>_<group_id>
                        let postIdAndGroupId = category!.replacingOccurrences(of: "open_message_", with: "")
                        mainTabBarController.postAndGroupToOpenWithMessage = postIdAndGroupId
                        
//                        mainTabBarController.messageFromAppDelegate = postIdAndGroupId
                    }
                    else if category!.contains("open_group_member_requestors") {
                        // format of open_group_member_requestors_<group_id>
                        let group_id = category!.replacingOccurrences(of: "open_group_member_requestors_", with: "")
                        mainTabBarController.groupMemberRequestorsToOpenFor = group_id
                    }
                    else if category!.contains("open_group_subscribe_requestors") {
                        // format of open_group_subscribe_requestors_<group_id>
                        let group_id = category!.replacingOccurrences(of: "open_group_subscribe_requestors_", with: "")
                        mainTabBarController.groupSubscribeRequestorsToOpenFor = group_id
                    }
                    else if category!.contains("open_group") {
                        // probably to click "join" button on group profile
                        // format of open_group_<group_id>
                        let group_id = category!.replacingOccurrences(of: "open_group_", with: "")
                        mainTabBarController.groupToOpen = group_id
                    }
                }
            }
        }
        window?.rootViewController = mainTabBarController
        return true
    }

}

