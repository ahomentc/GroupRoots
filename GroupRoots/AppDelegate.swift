import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        let pushManager = PushNotificationManager()
        pushManager.registerForPushNotifications()
        
        window = UIWindow()
        window?.makeKeyAndVisible()
        window?.backgroundColor = .black
        window?.rootViewController = MainTabBarController()
        return true
    }

}

