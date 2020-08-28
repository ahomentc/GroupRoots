import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseCore
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

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
        window?.rootViewController = MainTabBarController()
        return true
    }

}

