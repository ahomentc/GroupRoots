//
//  ProfileFeedController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 5/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import NVActivityIndicatorView
import Zoomy
import SwiftGifOrigin
import Contacts
import PhoneNumberKit
import SearchTextField
import FirebaseStorage
import YPImagePicker
import Photos

class ProfileFeedController: UICollectionViewController, UICollectionViewDelegateFlowLayout, ViewersControllerDelegate, FeedGroupCellDelegate, CreateGroupControllerDelegate, InviteToGroupWhenCreateControllerDelegate, EmptyFeedPostCellDelegate, FullGroupCellDelegate, SchoolEmptyStateCellDelegate, SchoolUsersCellDelegate, CreateGroupCellDelegate, LargeImageViewControllerDelegate {
        
    override var prefersStatusBarHidden: Bool {
      return statusBarHidden
    }
    
    var statusBarHidden = false {
      didSet(newValue) {
        setNeedsStatusBarAppearanceUpdate()
      }
    }
    
    // ---- following page data structures ----
    var groupPosts2D = [[GroupPost]]()
    var groupMembers = [String: [User]]()
    var groupPostsTotalViewersDict = [String: [String: Int]]()          // Dict inside dict. First key is the groupId. Within the value is another key with postId
    var groupPostsVisibleViewersDict = [String: [String: [User]]]()     //    same   ^
    var groupPostsFirstCommentDict = [String: [String: Comment]]()      //    same   |
    var hasViewedDict = [String: [String: Bool]]()                      //    same   |
    var groupPostsNumCommentsDict = [String: [String: Int]]()           // -- same --|
    
    var numGroupsInFeed = 5
    var usingCachedData = true
    var fetchedAllGroups = false
    var oldestRetrievedDate = 10000000000000.0
    var isFirstView = true
    
    
    // ---- school view data structures ----
    var selectedSchool = ""
    var isSchoolView = true
    private var fetchedSchoolGroups = false
    private var isInGroupFollowPendingDict = [String: Bool]()
    private var canViewGroupPostsDict = [String: Bool]()
    private var groupMembersDict = [String: [User]]()
    private var groupPosts2DDict = [String: [GroupPost]]()
    private var isInGroupDict = [String: Bool]()
    private var school_groups = [Group]()
    private var school_members = [User]()
    private var school_members_group_count = [String: Int]() // uid: number of groups
    var schoolCollectionView: UICollectionView!
    var user: User?
    var schoolPromoIsActive = false
    
    private let loadingScreenView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 10
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0, alpha: 1)
        return iv
    }()
    
    private let noInternetLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "No Internet Connection", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
        label.attributedText = attributedText
        return label
    }()
    
    private let noInternetBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        view.layer.zPosition = 3
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 10
        view.isHidden = true
        return view
    }()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.4, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Welcome to GroupRoots!\n\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        attributedText.append(NSMutableAttributedString(string: "Photos and videos of groups you\nfollow will appear here.\n\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        attributedText.append(NSMutableAttributedString(string: "When you follow friends, you automatically\nalso follow their public groups.\n\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        attributedText.append(NSMutableAttributedString(string: "When you join a group as a member,\nyou’ll be able to post to it.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        label.attributedText = attributedText
        return label
    }()
    
    private let noSubscriptionsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.4, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Welcome to GroupRoots!\n\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        attributedText.append(NSMutableAttributedString(string: "Photos and videos of groups you\nfollow will appear here.\n\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        attributedText.append(NSMutableAttributedString(string: "When you follow friends, you automatically\nalso follow their public groups.\n\n", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        attributedText.append(NSMutableAttributedString(string: "When you join a group as a member,\nyou’ll be able to post to it.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        label.attributedText = attributedText
        return label
    }()

    private lazy var reloadButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(loadFromNoInternet), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Retry", for: .normal)
        return button
    }()
    
    private lazy var newGroupButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleShowNewGroup), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Create a Group", for: .normal)
        return button
    }()
    
    private lazy var goButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleFirstGo), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Next", for: .normal)
        return button
    }()
    
    private lazy var inviteButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleShowInviteCode), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Enter a Group Invite Code", for: .normal)
        return button
    }()
    
    private lazy var createGroupIconButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleShowNewGroup), for: .touchUpInside)
        button.layer.zPosition = 10;
        button.setImage(#imageLiteral(resourceName: "group_plus").withRenderingMode(UIImage.RenderingMode.alwaysTemplate), for: .normal)
        button.tintColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        return button
    }()
    
    private lazy var followingPageButton: UIButton = {
        let button = UIButton()
        button.setTitle("Following", for: .normal)
        button.layer.zPosition = 10
        button.backgroundColor = UIColor(white: 1, alpha: 0)
        button.setTitleColor(UIColor(white: 0.35, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(changeToFollowing), for: .touchUpInside)
        return button
    }()
    
    private lazy var schoolPageButton: UIButton = {
        let button = UIButton()
        button.setTitle("My School", for: .normal)
        button.layer.zPosition = 10
        button.backgroundColor = UIColor(white: 1, alpha: 0)
        button.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(changeToMySchool), for: .touchUpInside)
        return button
    }()
    
    let logoImageView: UIImageView = {
        let img = UIImageView()
        img.image = #imageLiteral(resourceName: "icon_login_4")
        img.isHidden = true
        return img
    }()
    
    let horizontalGifView: UIImageView = {
        let img = UIImageView()
        img.isHidden = true
        return img
    }()
    
    let verticalGifView: UIImageView = {
        let img = UIImageView()
        img.isHidden = true
        return img
    }()
    
    private lazy var animationsButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(showSecondAnim), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Next", for: .normal)
        return button
    }()
    
    private lazy var animationsButton2: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(endIntro), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Got it", for: .normal)
        return button
    }()
    
    private let animationsTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.4, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Group Profile Feed", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        label.attributedText = attributedText
        return label
    }()
    
    private let animationsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.4, alpha: 1)
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "\nSwipe up to go through groups.\nGroups appear by the last time they posted.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)])
//        Swipe up to cycle through groups that friends you follow are in
        label.attributedText = attributedText
        return label
    }()
    
    var collectionViewOffset = CGPoint(x: 0, y: 0)
    var hasDisappeared = false
    
    let activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width/2 - 35, y: UIScreen.main.bounds.height/2 - 35, width: 70, height: 70), type: NVActivityIndicatorType.circleStrokeSpin)
    
    let activityIndicatorViewSchool = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width/2 - 35, y: UIScreen.main.bounds.height/2 - 35, width: 70, height: 70), type: NVActivityIndicatorType.circleStrokeSpin)
    
    //MARK: Join School UI
    private let selectASchoolLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: "Explore the Friend Groups\nin Your School", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private lazy var searchSchoolField: SearchTextField = {
        let textField = SearchTextField()
        textField.borderStyle = .none
        textField.theme.cellHeight = 60
        textField.comparisonOptions = [.caseInsensitive]
        textField.attributedPlaceholder = NSAttributedString(string: "Search for your school", attributes:[NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)])
        textField.backgroundColor = .white
        textField.startVisible = true
        textField.autocorrectionType = .no
        textField.textAlignment = .center
        textField.theme.bgColor = .white
        textField.theme.font = UIFont.systemFont(ofSize: 16)
        textField.isHidden = true
        return textField
    }()
    
    let searchSchoolBottomBorder: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    private lazy var selectSchoolButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(selectSchool), for: .touchUpInside)
        button.layer.zPosition = 1;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Join School", for: .normal)
        return button
    }()
    
    func showEmptyStateViewIfNeeded() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().numberOfSubscriptionsForUser(withUID: currentLoggedInUserId) { (followingCount) in
            Database.database().numberOfGroupsForUser(withUID: currentLoggedInUserId, completion: { (groupsCount) in
                if followingCount == 0 && groupsCount == 0 {
                    self.newGroupButton.isHidden = false
                    self.goButton.isHidden = true
                    self.inviteButton.isHidden = false
//                    self.welcomeLabel.isHidden = false
                    self.noSubscriptionsLabel.isHidden = false
                    self.logoImageView.isHidden = false
                    
//                    TableViewHelper.EmptyMessage(message: "Welcome to GroupRoots!\n\nFollow friends to see their\ngroups in your feed", viewController: self)
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                        self.collectionView?.backgroundView?.alpha = 1
                    }, completion: nil)
                    
                } else {
                    self.collectionView?.backgroundView?.alpha = 0
                }
            })
        }
    }
    
    let phoneNumberKit = PhoneNumberKit()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                (cell as! FeedGroupCell).pauseVisibleVideo()
            }
        }
        
        self.collectionView.scrollToNearestVisibleCollectionViewCell()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.configureNavBar()
        
        // check if fullscreen and set tabBar color accordingly
        for cell in collectionView.visibleCells {
            if cell is FeedGroupCell {
                let visible_cell = cell as! FeedGroupCell
                if visible_cell.isFullScreen {
                    self.createGroupIconButton.isHidden = true
                    NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
//                    self.statusBarHidden = true
                }
                else {
                    self.createGroupIconButton.isHidden = false
                    NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
//                    self.statusBarHidden = false
                }
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        if let hasOpenedAppRetrieved = UserDefaults.standard.object(forKey: "hasOpenedApp") as? Data {
            guard let hasOpenedApp = try? JSONDecoder().decode(Bool.self, from: hasOpenedAppRetrieved) else {
                print("Error: Couldn't decode data into Blog")
                return
            }
            self.isFirstView = !hasOpenedApp
        }
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
                
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor : UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
        loadingScreenView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        loadingScreenView.layer.cornerRadius = 0
        loadingScreenView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        loadingScreenView.image =  #imageLiteral(resourceName: "Splash4")
        self.view.insertSubview(loadingScreenView, at: 10)
        
        reloadButton.frame = CGRect(x: UIScreen.main.bounds.width/2-50, y: UIScreen.main.bounds.height/2, width: 100, height: 50)
        reloadButton.layer.cornerRadius = 18
        self.view.insertSubview(reloadButton, at: 4)
        
        noInternetLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height/2-50, width: UIScreen.main.bounds.width, height: 20)
        self.view.insertSubview(noInternetLabel, at: 4)
        
        noInternetBackground.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-100, width: 300, height: 200)
        self.view.insertSubview(noInternetBackground, at: 3)
        
        welcomeLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-150, width: 300, height: 300)
        self.view.insertSubview(welcomeLabel, at: 4)
        
        noSubscriptionsLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-150, width: 300, height: 300)
        self.view.insertSubview(noSubscriptionsLabel, at: 4)
        
        inviteButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 - 30, width: 300, height: 50)
        inviteButton.layer.cornerRadius = 14
        self.view.insertSubview(inviteButton, at: 4)
        
        newGroupButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 + 30, width: 300, height: 50)
        newGroupButton.layer.cornerRadius = 14
        self.view.insertSubview(newGroupButton, at: 4)
        
        goButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 + 30, width: 300, height: 50)
        goButton.layer.cornerRadius = 14
        self.view.insertSubview(goButton, at: 4)
        
        logoImageView.frame = CGRect(x: view.frame.width/2 - 100, y: 80, width: 200, height: 200)
        self.view.addSubview(logoImageView)
        
        horizontalGifView.frame = CGRect(x: view.frame.width/2 - 101.25, y: UIScreen.main.bounds.height/3 - 70, width: 202.5, height: 360)
        horizontalGifView.loadGif(name: "horiz")
        self.view.addSubview(horizontalGifView)
        
        verticalGifView.frame = CGRect(x: view.frame.width/2 - 101.25, y: UIScreen.main.bounds.height/3 - 30, width: 202.5, height: 300.15)
        verticalGifView.loadGif(name: "vert")
        self.view.addSubview(verticalGifView)
        
        animationsTitleLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/3-300, width: 300, height: 300)
        self.view.addSubview(animationsTitleLabel)
        
        animationsLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-200, y: UIScreen.main.bounds.height/3-250, width: 400, height: 300)
        self.view.addSubview(animationsLabel)
        
        animationsButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 + 30, width: 300, height: 50)
        animationsButton.layer.cornerRadius = 14
        self.view.insertSubview(animationsButton, at: 4)
        
        animationsButton2.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 + 30, width: 300, height: 50)
        animationsButton2.layer.cornerRadius = 14
        self.view.insertSubview(animationsButton2, at: 4)
        
        createGroupIconButton.frame = CGRect(x: UIScreen.main.bounds.width-50, y: UIScreen.main.bounds.height/23 + 0, width: 40, height: 40)
        createGroupIconButton.layer.cornerRadius = 14
        self.view.insertSubview(createGroupIconButton, at: 10)
        
    
        
        followingPageButton.frame = CGRect(x: UIScreen.main.bounds.width/2 - 105, y: UIScreen.main.bounds.height/23 + 0, width: 100, height: 40)
        self.view.insertSubview(followingPageButton, at: 10)
        
        schoolPageButton.frame = CGRect(x: UIScreen.main.bounds.width/2 + 5, y: UIScreen.main.bounds.height/23 + 0, width: 100, height: 40)
        self.view.insertSubview(schoolPageButton, at: 10)
        
        // create school stuff
        selectASchoolLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height/6, width: UIScreen.main.bounds.width, height: 50)
        self.view.insertSubview(selectASchoolLabel, at: 4)
        
        searchSchoolField.frame = CGRect(x: 25, y: UIScreen.main.bounds.height/3, width: UIScreen.main.bounds.width - 50, height: 40)
        self.view.insertSubview(searchSchoolField, at: 4)
        
        searchSchoolBottomBorder.backgroundColor = UIColor(white: 0, alpha: 0.2)
        self.view.addSubview(searchSchoolBottomBorder)
        searchSchoolBottomBorder.anchor(top: searchSchoolField.bottomAnchor, left: searchSchoolField.leftAnchor, right: searchSchoolField.rightAnchor, height: 0.5)
        
//        selectSchoolButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3, width: 300, height: 50)
        selectSchoolButton.layer.cornerRadius = 14
        self.view.insertSubview(selectSchoolButton, at: 4)
        selectSchoolButton.anchor(top: searchSchoolBottomBorder.bottomAnchor, right: searchSchoolField.rightAnchor, paddingTop: 25, paddingRight: 15, width: 150, height: 50)
        
        collectionView?.frame = CGRect(x: 0, y: UIScreen.main.bounds.height/9, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - UIScreen.main.bounds.height/8)
        collectionView?.register(FeedGroupCell.self, forCellWithReuseIdentifier: "cellId")
        collectionView?.register(EmptyFeedPostCell.self, forCellWithReuseIdentifier: EmptyFeedPostCell.cellId)
        collectionView?.allowsSelection = false
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.isPagingEnabled = true
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = .clear
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.minimumLineSpacing = CGFloat(0)
        
        schoolCollectionView = UICollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height/8, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - UIScreen.main.bounds.height/8), collectionViewLayout: layout)
        schoolCollectionView.delegate = self
        schoolCollectionView.dataSource = self
        schoolCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        schoolCollectionView?.register(SchoolEmptyStateCell.self, forCellWithReuseIdentifier: SchoolEmptyStateCell.cellId)
        schoolCollectionView?.register(SchoolLabelCell.self, forCellWithReuseIdentifier: SchoolLabelCell.cellId)
        schoolCollectionView?.register(InstaPromoCell.self, forCellWithReuseIdentifier: InstaPromoCell.cellId)
        schoolCollectionView?.register(GroupCell.self, forCellWithReuseIdentifier: GroupCell.cellId)
        schoolCollectionView?.register(FullGroupCell.self, forCellWithReuseIdentifier: FullGroupCell.cellId)
        schoolCollectionView?.register(SchoolUsersCell.self, forCellWithReuseIdentifier: SchoolUsersCell.cellId)
        schoolCollectionView?.register(CreateGroupCell.self, forCellWithReuseIdentifier: CreateGroupCell.cellId)
        schoolCollectionView?.register(YourGroupsCell.self, forCellWithReuseIdentifier: YourGroupsCell.cellId)
        schoolCollectionView.backgroundColor = UIColor.clear
        schoolCollectionView.showsVerticalScrollIndicator = false
//        schoolCollectionView.isPagingEnabled = true
        schoolCollectionView.isHidden = true
        self.view.insertSubview(schoolCollectionView, at: 5)
        
        self.view.backgroundColor = .white
        
        // what happens here if there's been paging... more specifically, what happens when refresh and had paging occur?
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateUserProfileFeed, object: nil)
        configureNavigationBar()
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { timer in
            self.loadingScreenView.isHidden = true
        })
        
        PushNotificationManager().updatePushTokenIfNeeded()
        
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
            self.reloadButton.isHidden = true
            self.noInternetLabel.isHidden = true
            self.noInternetBackground.isHidden = true
            
            activityIndicatorView.isHidden = false
            activityIndicatorView.color = .black
            self.view.insertSubview(activityIndicatorView, at: 20)
            activityIndicatorView.startAnimating()
            
            self.loadData()
        } else {
            print("Internet Connection not Available!")
            self.reloadButton.isHidden = false
            self.noInternetLabel.isHidden = false
            self.noInternetBackground.isHidden = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.collectionViewOffset = self.collectionView.contentOffset;
        self.hasDisappeared = true
    }
    
    override func viewDidLayoutSubviews() {
        if self.hasDisappeared {
            self.collectionView.contentOffset = self.collectionViewOffset
            self.hasDisappeared = false
        }
    }
    
    @objc func handleRefresh() {
        // stop video of visible cell
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                // TODO: write logic to stop the video before it begins scrolling
                (cell as! FeedGroupCell).pauseVisibleVideo()
            }
        }
        groupPosts2D = [[GroupPost]]()
        groupMembers = [String: [User]]()
        groupPostsTotalViewersDict = [String: [String: Int]]()
        groupPostsVisibleViewersDict = [String: [String: [User]]]()
        groupPostsFirstCommentDict = [String: [String: Comment]]()
        groupPostsNumCommentsDict = [String: [String: Int]]()
        hasViewedDict = [String: [String: Bool]]()
        oldestRetrievedDate = 10000000000000.0
        self.numGroupsInFeed = 5
        self.fetchedAllGroups = false
        
        loadData()

    }
    
    func loadData() {
        if isSchoolView {
            self.collectionView.isHidden = true
            
            self.followingPageButton.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
            self.schoolPageButton.setTitleColor(UIColor(white: 0.35, alpha: 1), for: .normal)
            
            self.createGroupIconButton.isHidden = true
            self.newGroupButton.isHidden = true
            self.goButton.isHidden = true
            self.inviteButton.isHidden = true
            self.welcomeLabel.isHidden = true
            self.noSubscriptionsLabel.isHidden = true
            self.logoImageView.isHidden = true
            self.animationsButton2.isHidden = true
            self.horizontalGifView.isHidden = true
            self.animationsTitleLabel.isHidden = true
            self.animationsButton.isHidden = true
            self.animationsLabel.isHidden = true
            self.animationsButton.isHidden = true
            self.verticalGifView.isHidden = true
            
            if let selectedSchoolRetrieved = UserDefaults.standard.object(forKey: "selectedSchool") as? Data {
                guard let selectedSchool = try? JSONDecoder().decode(String.self, from: selectedSchoolRetrieved) else {
                    print("Error: Couldn't decode data into Blog")
                    return
                }
                self.selectedSchool = selectedSchool
            }
            
            activityIndicatorView.isHidden = false
            
            
            if self.selectedSchool != "" {
                // display groups for that school and the insta thing
                self.schoolCollectionView.isHidden = false
                self.fetchAllSchoolGroups()
                searchSchoolField.isHidden = true
                selectASchoolLabel.isHidden = true
                searchSchoolBottomBorder.isHidden = true
                selectSchoolButton.isHidden = true
            }
            else {
                // display the start screen for schools
                schoolCollectionView.isHidden = true
                searchSchoolField.isHidden = false
                selectASchoolLabel.isHidden = false
                searchSchoolBottomBorder.isHidden = false
                selectSchoolButton.isHidden = false
                setupSchoolSearch()
            }
        }
        else {
            self.collectionView.isHidden = false
            self.createGroupIconButton.isHidden = false
            self.schoolCollectionView.isHidden = true
            self.searchSchoolField.isHidden = true
            self.searchSchoolField.hideResultsList()
            self.searchSchoolBottomBorder.isHidden = true
            self.selectSchoolButton.isHidden = true
            self.selectASchoolLabel.isHidden = true
            self.followingPageButton.setTitleColor(UIColor(white: 0.35, alpha: 1), for: .normal)
            self.schoolPageButton.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
            self.loadGroupPosts()
        }
    }
    
    private func configureNavigationBar() {
        self.configureNavBar()
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor : UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(white: 0.98, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.98, alpha: 1)
//        self.view.backgroundColor = UIColor.init(white: 0.98, alpha: 1)
    }
    
    func requestZoomCapability(for cell: FeedPostCell) {
        addZoombehavior(for: cell.photoImageView, settings: .instaZoomSettings)
    }
    
    private func loadGroupPosts(){
        addGroupPosts()
        if !isFirstView {
            showEmptyStateViewIfNeeded()
        }
    }
    
    private func addGroupPosts() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        collectionView?.refreshControl?.beginRefreshing()
        var group_ids = Set<String>()
        var tempGroupPosts2D = [[GroupPost]]()
        // get all the userIds of the people user is following
        let sync = DispatchGroup()
        var batch_size = 6
        batch_size = batch_size - 1

        // we don't need to show posts of groups that are member of but not following.
        // They auto follow it so they'd have to unfollow to not be in following, which means they
        // don't want to see the posts
        sync.enter()
        self.activityIndicatorView.isHidden = false
        Database.database().fetchNextGroupsFollowing(withUID: currentLoggedInUserId, endAt: oldestRetrievedDate, completion: { (groups) in
            self.reloadButton.isHidden = true
            self.newGroupButton.isHidden = true
            self.goButton.isHidden = true
            self.inviteButton.isHidden = true
            self.welcomeLabel.isHidden = true
            self.noSubscriptionsLabel.isHidden = true
            self.logoImageView.isHidden = true
            self.noInternetLabel.isHidden = true
            self.noInternetBackground.isHidden = true
            if groups.last == nil {
                self.collectionView?.refreshControl?.endRefreshing()
                sync.leave()
                return
            }
//            self.oldestRetrievedDate = groups.first!.lastPostedDate
            Database.database().fetchGroupsFollowingGroupLastPostedDate(withUID: currentLoggedInUserId, groupId: groups.first!.groupId) { (date) in
                self.oldestRetrievedDate = date
                groups.forEach({ (group) in
                    if group_ids.contains(group.groupId) == false && group.groupId != "" {
                        group_ids.insert(group.groupId)
                    }
                })
                sync.leave()
            }
        }, withCancel: { (err) in
            print("Failed to fetch posts:", err)
            self.loadingScreenView.isHidden = true
            self.collectionView?.refreshControl?.endRefreshing()
        })
        // run below when all the group ids have been collected
        sync.notify(queue: .main) {
            let lower_sync = DispatchGroup()
            group_ids.forEach({ (groupId) in
                lower_sync.enter()
                // could change this function to have only posts but maybe this could be useful in the future
                Database.database().fetchAllGroupPosts(groupId: groupId, completion: { (countAndPosts) in
                    // this section has gotten all the groupPosts within each group
                    if countAndPosts.count > 0 {
                        TableViewHelper.EmptyMessage(message: "", viewController: self)
                        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                            self.collectionView?.backgroundView?.alpha = 1
                        }, completion: nil)


                        let posts = countAndPosts[1] as! [GroupPost]
                        let sortedPosts = posts.sorted(by: { (p1, p2) -> Bool in
                            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                        })
                        if sortedPosts.count > 0 {      // don't complete if no posts (don't add it to feed)
                            let groupId = sortedPosts[0].group.groupId
                            tempGroupPosts2D.append(sortedPosts)

                            // set the members of the group
                            lower_sync.enter()
                            Database.database().fetchGroupMembers(groupId: groupId, completion: { (users) in
                                lower_sync.leave()
                                self.groupMembers[groupId] =  users
                            }) { (_) in }

                            // go through each post
                            posts.forEach({ (groupPost) in
                                // note that all these fetches are async of each other and are concurent so any of them could occur first

                                // get the first comment of the post and set the number of comments
                                lower_sync.enter()
                                Database.database().fetchFirstCommentForPost(withId: groupPost.id, completion: { (comments) in
                                    if comments.count > 0 {
                                        let existingPostsForFirstCommentInGroup = self.groupPostsFirstCommentDict[groupId]
                                        if existingPostsForFirstCommentInGroup == nil {
                                            self.groupPostsFirstCommentDict[groupId] = [groupPost.id: comments[0]]
                                        }
                                        else {
                                            self.groupPostsFirstCommentDict[groupId]![groupPost.id] = comments[0] // it is def not nil so safe to unwrap
                                        }
                                    }
                                    
                                    Database.database().numberOfCommentsForPost(postId: groupPost.id) { (commentsCount) in
                                        let existingPostsForNumCommentInGroup = self.groupPostsNumCommentsDict[groupId]
                                        if existingPostsForNumCommentInGroup == nil {
                                            self.groupPostsNumCommentsDict[groupId] = [groupPost.id: commentsCount]
                                        }
                                        else {
                                            self.groupPostsNumCommentsDict[groupId]![groupPost.id] = commentsCount // it is def not nil so safe to unwrap
                                        }
                                        lower_sync.leave()
                                    }
                                }) { (err) in }
                                
                                lower_sync.enter()
                                Database.database().hasViewedPost(postId: groupPost.id, completion: { (hasViewed) in
                                    let existingHasViewedForGroup = self.hasViewedDict[groupId]
                                    if existingHasViewedForGroup == nil {
                                        self.hasViewedDict[groupId] = [groupPost.id: hasViewed]
                                    }
                                    else {
                                        self.hasViewedDict[groupId]![groupPost.id] = hasViewed
                                    }
                                    lower_sync.leave()
                                }) { (err) in return }

                                // the following is only if the user is in a gorup
                                lower_sync.enter()
                                Database.database().isInGroup(groupId: groupPost.group.groupId, completion: { (inGroup) in
                                    lower_sync.leave()
                                    if inGroup {
                                        // get the viewers
                                        lower_sync.enter()
                                        Database.database().fetchPostVisibleViewers(postId: groupPost.id, completion: { (viewer_ids) in
                                            if viewer_ids.count > 0 {
                                                var viewers = [User]()
                                                let viewersSync = DispatchGroup()
                                                viewer_ids.forEach({ (viewer_id) in
                                                    viewersSync.enter()
                                                    Database.database().userExists(withUID: viewer_id, completion: { (exists) in
                                                        if exists{
                                                            Database.database().fetchUser(withUID: viewer_id, completion: { (user) in
                                                                viewers.append(user)
                                                                viewersSync.leave()
                                                            })
                                                        }
                                                        else {
                                                            viewersSync.leave()
                                                        }
                                                    })
                                                })
                                                viewersSync.notify(queue: .main) {
                                                    let existingPostsForVisibleViewersInGroup = self.groupPostsVisibleViewersDict[groupId]
                                                    if existingPostsForVisibleViewersInGroup == nil {
                                                        self.groupPostsVisibleViewersDict[groupId] = [groupPost.id: viewers]
                                                    }
                                                    else {
                                                        self.groupPostsVisibleViewersDict[groupId]![groupPost.id] = viewers
                                                    }
                                                    lower_sync.leave()
                                                }
                                            }
                                            else {
                                                lower_sync.leave()
                                            }
                                        }) { (err) in return}

                                        // get the post total viewers
                                        lower_sync.enter()
                                        Database.database().fetchNumPostViewers(postId: groupPost.id, completion: {(views_count) in
                                            let existingPostsForTotalViewersInGroup = self.groupPostsTotalViewersDict[groupId]
                                            if existingPostsForTotalViewersInGroup == nil {
                                                self.groupPostsTotalViewersDict[groupId] = [groupPost.id: views_count]
                                            }
                                            else {
                                                self.groupPostsTotalViewersDict[groupId]![groupPost.id] = views_count
                                            }
                                            lower_sync.leave()

                                        }) { (err) in return }
                                    }
                                }) { (err) in return }
                            })
                        }
                    }
                    else {
                        let seconds = 1.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                            if self.groupPosts2D.count == 0 {
//                                TableViewHelper.EmptyMessage(message: "No posts to show\nClick the plus to post to a group", viewController: self)
//                                self.newGroupButton.isHidden = false
//                                self.goButton.isHidden = true
//                                self.inviteButton.isHidden = false
//                                self.welcomeLabel.isHidden = false
//                                self.logoImageView.isHidden = false
                                UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
                                    self.collectionView?.backgroundView?.alpha = 1
                                }, completion: nil)
                            }
                        }
                    }
                    lower_sync.leave()
                }, withCancel: { (err) in
                    self.loadingScreenView.isHidden = true
                    self.collectionView?.refreshControl?.endRefreshing()
                })
            })
            lower_sync.notify(queue: .main) {
                tempGroupPosts2D.sort(by: { (p1, p2) -> Bool in
                    return p1[0].creationDate.compare(p2[0].creationDate) == .orderedDescending
                })

                if tempGroupPosts2D.count < batch_size {
                    self.fetchedAllGroups = true
                }
                
                self.loadingScreenView.isHidden = true
                self.activityIndicatorView.isHidden = true
                
                self.groupPosts2D += Array(tempGroupPosts2D.suffix(batch_size))
                self.usingCachedData = false

                // add refresh capability only after posts have been loaded
                let refreshControl = UIRefreshControl()
                refreshControl.addTarget(self, action: #selector(self.handleRefresh), for: .valueChanged)
                self.collectionView?.refreshControl = refreshControl
                
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    self.collectionView?.refreshControl?.endRefreshing()
                    self.collectionView.scrollToNearestVisibleCollectionViewCell()
                }
                
                if self.isSchoolView {
                    return
                }

//                if self.isFirstView && tempGroupPosts2D.count > 0 {
                if self.isFirstView {
                    self.newGroupButton.isHidden = true
                    self.inviteButton.isHidden = true
                    self.goButton.isHidden = false
                    self.welcomeLabel.isHidden = false
                    self.logoImageView.isHidden = false
                    self.collectionView.isHidden = true
                    self.createGroupIconButton.isHidden = true
                    self.noSubscriptionsLabel.isHidden = true
                }
                else if tempGroupPosts2D.count > 0 {
                    self.activityIndicatorView.isHidden = true
                    self.newGroupButton.isHidden = true
                    self.goButton.isHidden = true
                    self.inviteButton.isHidden = true
                    self.welcomeLabel.isHidden = true
                    self.noSubscriptionsLabel.isHidden = true
                    self.logoImageView.isHidden = true
                    self.collectionView.isHidden = false
                    self.createGroupIconButton.isHidden = false
                }
                else if self.groupPosts2D.count == 0 {
                    self.newGroupButton.isHidden = false
                    self.goButton.isHidden = true
                    self.inviteButton.isHidden = false
                    self.noSubscriptionsLabel.isHidden = false
                    self.welcomeLabel.isHidden = true
                    self.logoImageView.isHidden = false
                    self.collectionView.isHidden = true
                    self.createGroupIconButton.isHidden = true
                }
            }
        }
    }
    
    // ------- fetch stuff for school -------
    
    private func fetchAllSchoolGroups() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().userExists(withUID: currentLoggedInUserId, completion: { (exists) in
            if exists{
                Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
                    self.user = user
                })
            }
        })
        
        let school = self.selectedSchool.replacingOccurrences(of: " ", with: "_-a-_")
        Database.database().fetchSchoolGroups(school: school, completion: { (groups) in
            self.school_groups = groups
            self.school_groups.sort(by: { (g1, g2) -> Bool in
                return g1.lastPostedDate > g2.lastPostedDate
            })
            self.fetchedSchoolGroups = true
            self.fetchSchoolMembers(school: school)
            self.fetchSchoolGroupMembers(groups: groups)
            self.fetchSchoolGroupInfo(groups: groups)
            self.fetchSchoolPromoIsActive(school: school)
            
        }) { (_) in }
    }
    
    var schoolMembersFetched = false
    var schoolGroupInfoFetched = false
    var schoolGroupMembersFetched = false
    var schoolPromoIsActiveFetched = false
    private func reloadSchoolCollectionView(){
        if schoolMembersFetched && schoolGroupInfoFetched && schoolGroupMembersFetched && schoolPromoIsActiveFetched {
            let refreshControlSchool = UIRefreshControl()
            refreshControlSchool.addTarget(self, action: #selector(self.handleRefresh), for: .valueChanged)
            self.schoolCollectionView.refreshControl = refreshControlSchool
            
            // bring the groups you have access to, to the front
            self.school_groups.sort(by: { (g1, g2) -> Bool in
                if self.canViewGroupPostsDict[g1.groupId]! && self.canViewGroupPostsDict[g2.groupId]! {
                    return g1.lastPostedDate > g2.lastPostedDate
                }
                if self.canViewGroupPostsDict[g1.groupId]! {
                    return true
                }
                return false
            })
            
            

            self.schoolCollectionView?.reloadData()
            activityIndicatorView.isHidden = true
            self.schoolCollectionView?.refreshControl?.endRefreshing()
        }
    }
    
    private func fetchSchoolPromoIsActive(school: String) {
        Database.database().isPromoActive(school: school, completion: { (isActive) in
            print("hi")
            self.schoolPromoIsActive = isActive
            self.schoolPromoIsActiveFetched = true
            self.reloadSchoolCollectionView()
        }) { (_) in}
    }
    
    private func fetchSchoolMembers(school: String){
        Database.database().fetchSchoolMembers(school: school, completion: { (members) in
            self.school_members = members
            
            // fill a dictionary for how many groups each user is in
            let sync = DispatchGroup()
            sync.enter()
            for member in members {
                sync.enter()
                Database.database().numberOfGroupsForUser(withUID: member.uid, completion: { (groupsCount) in
                    self.school_members_group_count[member.uid] = groupsCount
                    sync.leave()
                })
            }
            sync.leave()
            sync.notify(queue: .main) {
                self.schoolMembersFetched = true
                self.reloadSchoolCollectionView()
            }
        }) { (_) in}
    }
    
    private func fetchSchoolGroupMembers(groups: [Group]){
        let sync = DispatchGroup()
        sync.enter()
        for group in groups {
            sync.enter()
            let groupId = group.groupId
            Database.database().fetchGroupMembers(groupId: groupId, completion: { (members) in
                self.groupMembersDict[groupId] = members
                sync.leave()
            }) { (_) in }
        }
        sync.leave()
        sync.notify(queue: .main) {
            self.schoolGroupMembersFetched = true
            self.reloadSchoolCollectionView()
        }
    }
    
    private func fetchSchoolGroupInfo(groups: [Group]){
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let sync = DispatchGroup()
        sync.enter()
        for group in groups {
            sync.enter()
            let groupId = group.groupId
                
            Database.database().isInGroupFollowPending(groupId: group.groupId, withUID: currentLoggedInUserId, completion: { (followPending) in
                self.isInGroupFollowPendingDict[groupId] = followPending
                
                Database.database().isInGroup(groupId: group.groupId, completion: { (inGroup) in
                    self.isInGroupDict[groupId] = inGroup
                    
                    Database.database().canViewGroupPosts(groupId: group.groupId, completion: { (canView) in
                        self.canViewGroupPostsDict[groupId] = canView
                            
                        if canView {
                            Database.database().fetchAllGroupPosts(groupId: group.groupId, completion: { (countAndPosts) in
                                if countAndPosts.count > 0 {
                                    self.groupPosts2DDict[groupId] = countAndPosts[1] as? [GroupPost]
                                    if self.groupPosts2DDict[groupId] != nil {
                                        self.groupPosts2DDict[groupId]!.sort(by: { (p1, p2) -> Bool in
                                            return p1.creationDate.compare(p2.creationDate) == .orderedDescending
                                        })
                                    }
                                    else {
                                        self.groupPosts2DDict[groupId] = []
                                    }
                                }
                                else {
                                    self.groupPosts2DDict[groupId] = []
                                }
                                sync.leave()
                            }) { (err) in
                                return
                            }
                        }
                        else {
                            self.groupPosts2DDict[groupId] = []
                            sync.leave()
                        }
                    }) { (err) in
                        return
                    }
                }) { (err) in
                   return
                }
            }) { (err) in
                return
            }
        }
        sync.leave()
        sync.notify(queue: .main) {
            self.schoolGroupInfoFetched = true
            self.reloadSchoolCollectionView()
        }
    }
    
    
    func configureNavBar() {
        self.navigationController?.navigationBar.height(CGFloat(0))
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = .clear
    }
    
    // to be used when transitioning back to ProfileFeedController
    func configureNavBarForTransition(){
        self.navigationController?.navigationBar.height(CGFloat(0))
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(white: 0, alpha: 0.5)
    }
    
    //MARK: CollectionView
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.schoolCollectionView {
            if fetchedSchoolGroups == false {
                return 0
            }
            if school_groups.count == 0 {
                return 1
            }
            if self.schoolPromoIsActive {
                return school_groups.count + 5
            }
            else {
                return school_groups.count + 4
            }
        }
        else {
            if groupPosts2D.count == 0 {
                return 0
            }
            return groupPosts2D.count + 1
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.schoolCollectionView {
            if school_groups.count == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SchoolEmptyStateCell.cellId, for: indexPath) as! SchoolEmptyStateCell
                cell.selectedSchool = self.selectedSchool
                cell.delegate = self
                return cell
            }
            
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SchoolLabelCell.cellId, for: indexPath) as! SchoolLabelCell
                cell.selectedSchool = self.selectedSchool
                return cell
            }
            if indexPath.item == 1 {
                // 120 height
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SchoolUsersCell.cellId, for: indexPath) as! SchoolUsersCell
                cell.schoolMembers = self.school_members
                cell.school_members_group_count = self.school_members_group_count
                cell.delegate = self
                return cell
            }
            
            if self.schoolPromoIsActive {
                if indexPath.item == 2 {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InstaPromoCell.cellId, for: indexPath) as! InstaPromoCell
                    cell.selectedSchool = self.selectedSchool.replacingOccurrences(of: " ", with: "_-a-_")
                    return cell
                }
                if indexPath.item == 3 {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateGroupCell.cellId, for: indexPath) as! CreateGroupCell
                    cell.selectedSchool = self.selectedSchool
                    cell.delegate = self
                    return cell
                }
                if indexPath.item == 4 {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: YourGroupsCell.cellId, for: indexPath) as! YourGroupsCell
                    return cell
                }
            }
            else {
                if indexPath.item == 2 {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateGroupCell.cellId, for: indexPath) as! CreateGroupCell
                    cell.selectedSchool = self.selectedSchool
                    cell.delegate = self
                    return cell
                }
                if indexPath.item == 3 {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: YourGroupsCell.cellId, for: indexPath) as! YourGroupsCell
                    return cell
                }
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FullGroupCell.cellId, for: indexPath) as! FullGroupCell
            cell.group = school_groups[indexPath.item - 5]
            cell.user = user
            let groupId = school_groups[indexPath.item - 5].groupId
            cell.isGroupHidden = false
            cell.isInFollowPending = isInGroupFollowPendingDict[groupId]
            cell.canView = canViewGroupPostsDict[groupId]
            cell.isInGroup = isInGroupDict[groupId]
            cell.groupMembers = groupMembersDict[groupId]
            cell.groupPosts = groupPosts2DDict[groupId]
            cell.delegate = self
            return cell
        }
        else {
            let feedCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! FeedGroupCell
            if indexPath.row == groupPosts2D.count {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyFeedPostCell.cellId, for: indexPath) as! EmptyFeedPostCell
                cell.fetchedAllGroups = fetchedAllGroups
                cell.delegate = self
                return cell
            }
            else if indexPath.row < groupPosts2D.count {
                let posts = groupPosts2D[indexPath.row]
                let groupId = posts[0].group.groupId
                feedCell.groupPosts = posts
                feedCell.usingCachedData = self.usingCachedData
                feedCell.groupMembers = groupMembers[groupId]
                feedCell.groupPostsTotalViewers = groupPostsTotalViewersDict[groupId]
                feedCell.groupPostsViewers = groupPostsVisibleViewersDict[groupId]
                feedCell.groupPostsFirstComment = groupPostsFirstCommentDict[groupId]
                feedCell.groupPostsNumComments = groupPostsNumCommentsDict[groupId]
                feedCell.hasViewedPosts = hasViewedDict[groupId]
                feedCell.delegate = self
                feedCell.tag = indexPath.row
                feedCell.maxDistanceScrolled = CGFloat(0)
                feedCell.numPicsScrolled = 1
            }
            return feedCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.schoolCollectionView {
            if school_groups.count == 0 {
                let emptyStateCellHeight = view.safeAreaLayoutGuide.layoutFrame.height
                return CGSize(width: view.frame.width, height: emptyStateCellHeight)
            }
            if indexPath.item == 0 {
                return CGSize(width: view.frame.width, height: 40)
            }
            if indexPath.item == 1 {
                return CGSize(width: view.frame.width, height: 135)
            }
            
            if self.schoolPromoIsActive {
                if indexPath.item == 2 {
                    return CGSize(width: view.frame.width, height: 80)
                }
                if indexPath.item == 3 {
                    return CGSize(width: view.frame.width, height: 60)
                }
                if indexPath.item == 4 {
                    return CGSize(width: view.frame.width, height: 40)
                }
            }
            else {
                if indexPath.item == 2 {
                    return CGSize(width: view.frame.width, height: 60)
                }
                if indexPath.item == 3 {
                    return CGSize(width: view.frame.width, height: 40)
                }
            }
            return CGSize(width: view.frame.width, height: 310)
        }
        else {
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - UIScreen.main.bounds.height/8)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == self.schoolCollectionView {
            if school_groups.count == 0  {
                return 0
            }
            else {
                return 5
            }
        }
        else {
            return 0
        }
    }
    
    //MARK: ScrollView functions
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                let visible_cell = cell as! FeedGroupCell
                visible_cell.pauseVisibleVideo()
                
                let original_pos = scrollView.contentOffset.y
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { timer in
                    let new_pos = scrollView.contentOffset.y
                    if abs(new_pos - original_pos) > 100 {
                        visible_cell.handleCloseFullscreen()
                        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
                    }
                })
            }
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let endPos = scrollView.contentOffset.y
        self.stoppedScrolling(endPos: endPos)
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let endPos = scrollView.contentOffset.y
        if !decelerate {
            self.stoppedScrolling(endPos: endPos)
        }
        if let hasScrolled = try? JSONEncoder().encode(true) {
            UserDefaults.standard.set(hasScrolled, forKey: "hasScrolled")
        }
    }
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                (cell as! FeedGroupCell).pauseVisibleVideo()
            }
        }
        return true
    }

    private var maxDistanceScrolled = CGFloat(0)
    private var numGroupsScrolled = 1
    func stoppedScrolling(endPos: CGFloat) {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
            if let indexPath = self.collectionView.indexPathsForVisibleItems.last {
                if indexPath.row == self.numGroupsInFeed {
                    self.numGroupsInFeed += 5
                    self.loadData()
                }
            }
        })
    }
    
    @objc private func loadFromNoInternet() {
        self.loadingScreenView.isHidden = false
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { timer in
            self.loadingScreenView.isHidden = true
            if Reachability.isConnectedToNetwork(){
                self.reloadButton.isHidden = true
                self.noInternetLabel.isHidden = true
                self.noInternetBackground.isHidden = true
                self.loadData()
            } else{
                self.reloadButton.isHidden = false
                self.noInternetLabel.isHidden = false
                self.noInternetBackground.isHidden = false
            }
        })
    }
    
    func didTapComment(groupPost: GroupPost) {
        let commentsController = CommentsController()
        commentsController.groupPost = groupPost
        navigationController?.pushViewController(commentsController, animated: true)
    }
    
    func didTapGroup(group: Group) {
//        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
//        groupProfileController.group = group
//        groupProfileController.modalPresentationCapturesStatusBarAppearance = true
//        navigationController?.pushViewController(groupProfileController, animated: true)
        
        let instaPromoController = InstaPromoController()
        instaPromoController.group = group
        let navController = UINavigationController(rootViewController: instaPromoController)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func didTapOptions(groupPost: GroupPost) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if let reportAction = self.reportAction(forPost: groupPost) {
            alertController.addAction(reportAction)
        }
        
        Database.database().isInGroup(groupId: groupPost.group.groupId, completion: { (inGroup) in
            if inGroup {
                if let deleteAction = self.deleteAction(forPost: groupPost) {
                    alertController.addAction(deleteAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            else{
                if let unsubscribeAction = self.unsubscribeAction(forPost: groupPost, uid: currentLoggedInUserId) {
                    alertController.addAction(unsubscribeAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }) { (err) in
            return
        }
    }
    
    private func deleteAction(forPost groupPost: GroupPost) -> UIAlertAction? {
        let action = UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
            
            let alert = UIAlertController(title: "Delete Post?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (_) in
                
                Database.database().deleteGroupPost(groupId: groupPost.group.groupId, postId: groupPost.id) { (_) in
                    NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }
    
    private func unsubscribeAction(forPost groupPost: GroupPost, uid: String) -> UIAlertAction? {
        let action = UIAlertAction(title: "Unsubscribe", style: .destructive, handler: { (_) in
            let alert = UIAlertController(title: "Unsubscribe?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Unsubscribe", style: .default, handler: { (_) in
                Database.database().removeGroupFromUserFollowing(withUID: uid, groupId: groupPost.group.groupId) { (err) in
                    NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }
    
    private func reportAction(forPost groupPost: GroupPost) -> UIAlertAction? {
        let action = UIAlertAction(title: "Report", style: .destructive, handler: { (_) in
            
            let alert = UIAlertController(title: "Report Post?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Report", style: .default, handler: { (_) in
                Database.database().reportPost(withId: groupPost.id, groupId: groupPost.group.groupId) { (err) in
                    if err != nil {
                        return
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }
    
    func didTapGroupPost(groupPost: GroupPost, index: Int) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.minimumLineSpacing = CGFloat(0)
        
        let largeImageViewController = LargeImageViewController(collectionViewLayout: layout)
        largeImageViewController.group = groupPost.group
        largeImageViewController.indexPath = IndexPath(item: index, section: 0)
        largeImageViewController.delegate = self
        let navController = UINavigationController(rootViewController: largeImageViewController)
        navController.modalPresentationStyle = .overCurrentContext
        
        self.present(navController, animated: true, completion: nil)
        
        handleDidView(groupPost: groupPost)
    }
    
    func handleDidView(groupPost: GroupPost) {
        Database.database().addToViewedPosts(postId: groupPost.id, completion: { _ in })
    }
    
    func postToGroup(group: Group) {
        var config = YPImagePickerConfiguration()
        config.library.isSquareByDefault = false
        config.shouldSaveNewPicturesToAlbum = false
        config.library.mediaType = .photoAndVideo
        config.hidesStatusBar = false
        config.startOnScreen = YPPickerScreen.library
        config.targetImageSize = .cappedTo(size: 600)
        config.video.compression = AVAssetExportPresetMediumQuality
        let picker = YPImagePicker(configuration: config)
        
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
                    sharePhotoController.preSelectedGroup = group
                    sharePhotoController.selectedImage = photo.image
                    sharePhotoController.suggestedLocation = location
                    picker.pushViewController(sharePhotoController, animated: true)
                    
                case .video(let video):
                    let location = video.asset?.location
                    let sharePhotoController = SharePhotoController()
                    sharePhotoController.preSelectedGroup = group
                    sharePhotoController.selectedVideoURL = video.url
                    sharePhotoController.selectedImage = video.thumbnail
                    sharePhotoController.suggestedLocation = location
                    picker.pushViewController(sharePhotoController, animated: true)
                }
            }
        }
        present(picker, animated: true, completion: nil)
    }
    
    
    func viewFullScreen(group: Group, indexPath: IndexPath) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.minimumLineSpacing = CGFloat(0)
        
        let largeImageViewController = LargeImageViewController(collectionViewLayout: layout)
        largeImageViewController.group = group
        largeImageViewController.indexPath = indexPath
        largeImageViewController.delegate = self
        let navController = UINavigationController(rootViewController: largeImageViewController)
        navController.modalPresentationStyle = .overCurrentContext
//        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func didSelectUser(selectedUser: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = selectedUser
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func showMoreMembers(group: Group) {
        
    }
    
    func didChangeViewType(isFullscreen: Bool) {
        if isFullscreen {
            self.createGroupIconButton.isHidden = true
        }
        else {
            self.createGroupIconButton.isHidden = false
        }
    }
    
    func didView(groupPost: GroupPost) {
        Database.database().addToViewedPosts(postId: groupPost.id, completion: { _ in })
    }
    
    func showViewers(viewers: [User], viewsCount: Int) {
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                (cell as! FeedGroupCell).pauseVisibleVideo()
            }
        }
        
        let viewersController = ViewersController()
        viewersController.viewers = viewers
        viewersController.viewsCount = viewsCount
        viewersController.delegate = self
        let navController = UINavigationController(rootViewController: viewersController)
        navController.modalPresentationStyle = .popover
        self.present(navController, animated: true, completion: nil)
    }
    
    func requestPlay(for_lower cell1: FeedPostCell, for_upper cell2: MyCell) {
        
    }

    func didTapUser(user: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = user
        userProfileController.modalPresentationCapturesStatusBarAppearance = true
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    @objc internal func handleShowNewGroup() {
        let createGroupController = CreateGroupController()
        createGroupController.delegate = self
        createGroupController.delegateForInvite = self
        let navController = UINavigationController(rootViewController: createGroupController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true, completion: nil)
    }
    
    func handleShowNewGroupForSchool(school: String) {
        let createGroupController = CreateGroupController()
        createGroupController.delegate = self
        createGroupController.delegateForInvite = self
        createGroupController.preSetSchool = school
        let navController = UINavigationController(rootViewController: createGroupController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true, completion: nil)
    }
    
    @objc internal func handleShowInviteCode() {
        let introCodeController = IntroCodeController()
        let navController = UINavigationController(rootViewController: introCodeController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true, completion: nil)
    }
    
    @objc internal func handleFirstGo() {
        // uncomment when done laying out
        self.isFirstView = false
        if let hasOpenedApp = try? JSONEncoder().encode(true) {
            UserDefaults.standard.set(hasOpenedApp, forKey: "hasOpenedApp")
        }

        self.newGroupButton.isHidden = true
        self.goButton.isHidden = true
        self.inviteButton.isHidden = true
        self.welcomeLabel.isHidden = true
        self.logoImageView.isHidden = true
        
        self.verticalGifView.isHidden = false
        self.animationsTitleLabel.isHidden = false
        self.animationsButton.isHidden = false
        self.animationsLabel.isHidden = false
    }
    
    func showBumpAnim(){
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            // check if it hasn't already scrolled down
            if let hasScrolledRetrieved = UserDefaults.standard.object(forKey: "hasScrolled") as? Data {
                guard let hasScrolled = try? JSONDecoder().decode(Bool.self, from: hasScrolledRetrieved) else {
                    print("Error: Couldn't decode data into Blog")
                    return
                }
                if !hasScrolled {
                    UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
                        self.collectionView.transform = CGAffineTransform(translationX: 0, y: -100)
                    }, completion: nil)
                    UIView.animate(withDuration: 0.5, delay: 1, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
                        self.collectionView.transform = CGAffineTransform(translationX: 0, y: 0)
                    }, completion: nil)
                    if let hasScrolled = try? JSONEncoder().encode(true) {
                        UserDefaults.standard.set(hasScrolled, forKey: "hasScrolled")
                    }
                }
            }
            else {
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
                    self.collectionView.transform = CGAffineTransform(translationX: 0, y: -100)
                }, completion: nil)
                UIView.animate(withDuration: 1, delay: 1.5, usingSpringWithDamping: 0.4, initialSpringVelocity: 1.0, options: .curveEaseOut, animations: {
                    self.collectionView.transform = CGAffineTransform(translationX: 0, y: 0)
                }, completion: nil)
                if let hasScrolled = try? JSONEncoder().encode(true) {
                    UserDefaults.standard.set(hasScrolled, forKey: "hasScrolled")
                }
            }
        }
    }
    
    @objc internal func showSecondAnim() {
        self.animationsButton.isHidden = true
        self.animationsButton2.isHidden = false
        self.horizontalGifView.isHidden = false
        self.verticalGifView.isHidden = true
        
        self.animationsLabel.attributedText = NSMutableAttributedString(string: "Swipe left to see all of a group’s posts.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)])
    }
    
    @objc internal func endIntro() {
        self.animationsButton2.isHidden = true
        self.horizontalGifView.isHidden = true
        self.animationsTitleLabel.isHidden = true
        self.animationsButton.isHidden = true
        self.animationsLabel.isHidden = true
        
        self.activityIndicatorView.isHidden = false
        self.handleRefresh()
        
        self.showBumpAnim()
    }
    
    func shouldOpenGroup(groupId: String) {
        Database.database().groupExists(groupId: groupId, completion: { (exists) in
            if exists {
                Database.database().fetchGroup(groupId: groupId, completion: { (group) in
                    self.handleRefresh()
                    
                    let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
                    groupProfileController.group = group
                    groupProfileController.modalPresentationCapturesStatusBarAppearance = true
                    self.navigationController?.pushViewController(groupProfileController, animated: true)
                })
            }
            else {
                return
            }
        })
    }
    
    func didTapImportContacts() {
        CNContactStore().requestAccess(for: .contacts) { (access, error) in
            let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            guard access else {
                if authorizationStatus == .denied {
                    return
                }
                let alert = UIAlertController(title: "GroupRoots does not have access to your contacts.\n\nEnable contacts in\nSettings > GroupRoots", message: "", preferredStyle: .alert)
                let okay_closure = { () in
                    { (action: UIAlertAction!) -> Void in
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                print("Settings opened: \(success)") // Prints true
                            })
                        }
                    }
                }
                alert.addAction(UIAlertAction(title: "Close", style: .destructive, handler: nil))
                alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: okay_closure()))
                self.present(alert, animated: true, completion: nil)
                return
            }
            importContactsToRecommended() { (err) in
                self.collectionView.visibleCells.forEach { cell in
                    if cell is EmptyFeedPostCell {
                        (cell as! EmptyFeedPostCell).collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func requestImportContactsIfAuth() {
        importContactsToRecommended() { (err) in
            self.collectionView.visibleCells.forEach { cell in
                if cell is EmptyFeedPostCell {
                    (cell as! EmptyFeedPostCell).collectionView.reloadData()
                }
            }
        }
    }
    
    @objc private func changeToFollowing() {
        self.isSchoolView = false
        self.loadData()
        self.searchSchoolField.resignFirstResponder()
    }
    
    @objc private func changeToMySchool() {
        self.isSchoolView = true
        self.loadData()
    }
    
    //MARK: Start School:
    func setupSchoolSearch(){
        let storageRef = Storage.storage().reference()
        let highSchoolsRef = storageRef.child("high_schools.json")
        highSchoolsRef.downloadURL { url, error in
            if let error = error {
                print(error)
            } else {
                let hs_url = url!.absoluteString
                if let url = URL(string: hs_url) {
                   URLSession.shared.dataTask(with: url) { data, response, error in
                      if let data = data {
                          do {
                            let json_string = String(data: data, encoding: .utf8)
                            guard let data = json_string?.data(using: String.Encoding.utf8 ),
                              let high_schools = try JSONSerialization.jsonObject(with: data, options: []) as? [String] else {
                                fatalError()
                                }
                            DispatchQueue.main.async {
                                self.searchSchoolField.filterStrings(high_schools)
                                self.activityIndicatorView.isHidden = true
                            }
                          } catch let error {
                             print(error)
                          }
                       }
                   }.resume()
                }
            }
        }
        searchSchoolField.itemSelectionHandler = { filteredResults, itemPosition in
            // Just in case you need the item position
            let item = filteredResults[itemPosition]
            print("Item at position \(itemPosition): \(item.title)")

            // Do whatever you want with the picked item
            self.searchSchoolField.text = item.title
//            self.schoolSelected = true
            self.searchSchoolField.resignFirstResponder()
            self.searchSchoolField.hideResultsList()
        }
    }
    
    @objc private func selectSchool() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        self.selectedSchool = searchSchoolField.text ?? ""
        
        let formatted_school = self.selectedSchool.replacingOccurrences(of: " ", with: "_-a-_")
        
        // save the user to the school
        // save the school to the user
        Database.database().addUserToSchool(withUID: currentLoggedInUserId, selectedSchool: formatted_school) { (err) in
            if err != nil {
               return
            }
            Database.database().addSchoolToUser(withUID: currentLoggedInUserId, selectedSchool: formatted_school) { (err) in
                if err != nil {
                   return
                }
                self.loadData()
            }
        }
    }
    
}

extension ProfileFeedController: Zoomy.Delegate {
    
    func didBeginPresentingOverlay(for imageView: Zoomable) {
        NotificationCenter.default.post(name: NSNotification.Name("tabBarDisappear"), object: nil)
        collectionView.isScrollEnabled = false
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                (cell as! FeedGroupCell).collectionView.isScrollEnabled = false
            }
        }
    }
    
    func didEndPresentingOverlay(for imageView: Zoomable) {
        NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
        collectionView.isScrollEnabled = true
        collectionView.visibleCells.forEach { cell in
            if cell is FeedGroupCell {
                (cell as! FeedGroupCell).collectionView.isScrollEnabled = true
            }
        }
    }
}
