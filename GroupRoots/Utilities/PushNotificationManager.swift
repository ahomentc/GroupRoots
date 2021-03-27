//
//  PushNotificationManager.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/25/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import Firebase
import FirebaseMessaging
import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseDatabase
import NotificationBannerSwift

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {

    
//    let userID: String
//    init(userID: String) {
//        self.userID = userID
//        super.init()
//    }
    
    func registerForPushNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }

        UIApplication.shared.registerForRemoteNotifications()
        updatePushTokenIfNeeded()
    }

    func updatePushTokenIfNeeded() {
        if let token = Messaging.messaging().fcmToken {
            Database.database().setUserfcmToken(token:token) { (err) in
                if err != nil {
                    return
                }
            }
        }
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        updatePushTokenIfNeeded()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // this will handle what happens when the app is open in background when the notification is recieved
        print("notification recieved when app in background")
        
        if response.notification.request.content.categoryIdentifier.contains("open_post") {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            layout.minimumLineSpacing = CGFloat(0)

            let postIdAndGroupId = response.notification.request.content.categoryIdentifier.replacingOccurrences(of: "open_post_", with: "")
            let postIdAndGroupIdArr = postIdAndGroupId.split(separator: "*")
            let postId = String(postIdAndGroupIdArr[0])
            let groupId = String(postIdAndGroupIdArr[1])

            Database.database().fetchGroupPost(groupId: groupId, postId: postId, completion: { (post) in
                let largeImageViewController = LargeImageViewController(collectionViewLayout: layout)
                largeImageViewController.group = post.group
                largeImageViewController.postToScrollToId = post.id
                if let topController = UIApplication.topViewController() {
                    if type(of: topController) == ProfileFeedController.self {
                        let profileFeedController = topController as? ProfileFeedController
                        largeImageViewController.delegate = profileFeedController
                    }
                }
                
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                
                let navController = UINavigationController(rootViewController: largeImageViewController)
                navController.modalPresentationStyle = .overCurrentContext
                
                let viewController = UIApplication.shared.keyWindow!.rootViewController as! MainTabBarController
                viewController.present(navController, animated: true, completion: nil)
                
            })
        }
        else if response.notification.request.content.categoryIdentifier.contains("open_message") {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            layout.minimumLineSpacing = CGFloat(0)

            let postIdAndGroupId = response.notification.request.content.categoryIdentifier.replacingOccurrences(of: "open_message_", with: "")
            let postIdAndGroupIdArr = postIdAndGroupId.split(separator: "*")
            let postId = String(postIdAndGroupIdArr[0])
            let groupId = String(postIdAndGroupIdArr[1])

            Database.database().fetchGroupPost(groupId: groupId, postId: postId, completion: { (post) in
                let largeImageViewController = LargeImageViewController(collectionViewLayout: layout)
                largeImageViewController.group = post.group
                largeImageViewController.postToScrollToId = post.id
                largeImageViewController.shouldOpenMessage = true
                if let topController = UIApplication.topViewController() {
                    if type(of: topController) == ProfileFeedController.self {
                        let profileFeedController = topController as? ProfileFeedController
                        largeImageViewController.delegate = profileFeedController
                    }
                }
                
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                
                let navController = UINavigationController(rootViewController: largeImageViewController)
                navController.modalPresentationStyle = .overCurrentContext
                
                let viewController = UIApplication.shared.keyWindow!.rootViewController as! MainTabBarController
                viewController.present(navController, animated: true, completion: nil)
                
            })
        }
    }


    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // this will handle what happens when the app is opened already when the notification is recieved
        print("notification recieved when app already opened")
        
        if notification.request.content.categoryIdentifier.contains("open_post") {
            UIApplication.shared.applicationIconBadgeNumber = 0
            
            
            let postIdAndGroupId = notification.request.content.categoryIdentifier.replacingOccurrences(of: "open_post_", with: "")
            let postIdAndGroupIdArr = postIdAndGroupId.split(separator: "*")
            let postId = String(postIdAndGroupIdArr[0])
            let groupId = String(postIdAndGroupIdArr[1])
            
            if let topController = UIApplication.topViewController() {
                if type(of: topController) == MessagesController.self {
                    let messagesController = topController as? MessagesController
                    let post_id = messagesController?.groupPost?.id
                    if post_id == postId {
                        return
                    }
                }
            }

            Database.database().fetchGroupPost(groupId: groupId, postId: postId, completion: { (post) in

                let banner = FloatingNotificationBanner(title: notification.request.content.title, subtitle: notification.request.content.body, style: .success)
                banner.backgroundColor = UIColor.init(white: 0.97, alpha: 1)
                banner.titleLabel?.textColor = .black
//                banner.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                banner.subtitleLabel?.textColor = .black
                banner.layer.cornerRadius = 10
                banner.clipsToBounds = true
                
                banner.layer.borderWidth = 1
                banner.layer.borderColor = UIColor.init(white: 0.8, alpha: 1).cgColor
                banner.onTap = {
                    if let topController = UIApplication.topViewController() {
                        if type(of: topController) == LargeImageViewController.self {
                            let largeImageViewController = topController as? LargeImageViewController
                            largeImageViewController?.handleCloseFullscreen()
                        }
                        else if type(of: topController) == MessagesController.self {
                            let messagesController = topController as? MessagesController
                            messagesController?.dismiss(animated: false, completion: {
                                
                                if let topController = UIApplication.topViewController() {
                                    if type(of: topController) == LargeImageViewController.self {
                                        let largeImageViewController = topController as? LargeImageViewController
                                        largeImageViewController?.handleCloseFullscreen()
                                    }
                                }
                                
                            })
                        }
                    }
                    
                    Timer.scheduledTimer(withTimeInterval: 1 , repeats: false) { timer in
                        let layout = UICollectionViewFlowLayout()
                        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
                        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        layout.minimumLineSpacing = CGFloat(0)
                        
                        let largeImageViewController = LargeImageViewController(collectionViewLayout: layout)
                        largeImageViewController.group = post.group
                        largeImageViewController.postToScrollToId = post.id
                        
                        if let topController = UIApplication.topViewController() {
                            if type(of: topController) == ProfileFeedController.self {
                                let profileFeedController = topController as? ProfileFeedController
                                largeImageViewController.delegate = profileFeedController
                            }
                        }
                        let navController = UINavigationController(rootViewController: largeImageViewController)
                        navController.modalPresentationStyle = .overCurrentContext
                        
                        let viewController = UIApplication.shared.keyWindow!.rootViewController as! MainTabBarController
                        viewController.present(navController, animated: true, completion: nil)
                    }
                
                }
                banner.show()
            })
        }
        else if notification.request.content.categoryIdentifier.contains("open_message") {
            UIApplication.shared.applicationIconBadgeNumber = 0
            
            let postIdAndGroupId = notification.request.content.categoryIdentifier.replacingOccurrences(of: "open_message_", with: "")
            let postIdAndGroupIdArr = postIdAndGroupId.split(separator: "*")
            let postId = String(postIdAndGroupIdArr[0])
            let groupId = String(postIdAndGroupIdArr[1])
            
            if let topController = UIApplication.topViewController() {
                if type(of: topController) == MessagesController.self {
                    let messagesController = topController as? MessagesController
                    let post_id = messagesController?.groupPost?.id
                    if post_id == postId {
                        return
                    }
                }
            }

            Database.database().fetchGroupPost(groupId: groupId, postId: postId, completion: { (post) in

                let banner = FloatingNotificationBanner(title: notification.request.content.title, subtitle: notification.request.content.body, style: .success)
                banner.backgroundColor = UIColor.init(white: 0.97, alpha: 1)
                banner.titleLabel?.textColor = .black
//                banner.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                banner.subtitleLabel?.textColor = .black
                banner.layer.cornerRadius = 10
                banner.clipsToBounds = true
                
                banner.layer.borderWidth = 1
                banner.layer.borderColor = UIColor.init(white: 0.8, alpha: 1).cgColor
                banner.onTap = {
                    if let topController = UIApplication.topViewController() {
                        if type(of: topController) == LargeImageViewController.self {
                            let largeImageViewController = topController as? LargeImageViewController
                            largeImageViewController?.handleCloseFullscreen()
                        }
                        else if type(of: topController) == MessagesController.self {
                            let messagesController = topController as? MessagesController
                            messagesController?.dismiss(animated: false, completion: {
                                
                                if let topController = UIApplication.topViewController() {
                                    if type(of: topController) == LargeImageViewController.self {
                                        let largeImageViewController = topController as? LargeImageViewController
                                        largeImageViewController?.handleCloseFullscreen()
                                    }
                                }
                                
                            })
                        }
                    }
                    
                    Timer.scheduledTimer(withTimeInterval: 1 , repeats: false) { timer in
                        let layout = UICollectionViewFlowLayout()
                        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
                        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        layout.minimumLineSpacing = CGFloat(0)
                        
                        let largeImageViewController = LargeImageViewController(collectionViewLayout: layout)
                        largeImageViewController.group = post.group
                        largeImageViewController.postToScrollToId = post.id
                        largeImageViewController.shouldOpenMessage = true
                        
                        if let topController = UIApplication.topViewController() {
                            if type(of: topController) == ProfileFeedController.self {
                                let profileFeedController = topController as? ProfileFeedController
                                largeImageViewController.delegate = profileFeedController
                            }
                        }
                        let navController = UINavigationController(rootViewController: largeImageViewController)
                        navController.modalPresentationStyle = .overCurrentContext
                        
                        let viewController = UIApplication.shared.keyWindow!.rootViewController as! MainTabBarController
                        viewController.present(navController, animated: true, completion: nil)
                    }
                
                }
                banner.show()
            })
        }
//        completionHandler(UNNotificationPresentationOptions.sound) // play sound
    }
}
