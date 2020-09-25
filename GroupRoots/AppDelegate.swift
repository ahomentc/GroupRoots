import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseCore
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
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
        
        let remoteNotif = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? NSDictionary
        if remoteNotif != nil {
            mainTabBarController.loadedFromNotif = true
        }
        else {
            print("nil")
        }
        
        window?.rootViewController = MainTabBarController()
        return true
    }

}

