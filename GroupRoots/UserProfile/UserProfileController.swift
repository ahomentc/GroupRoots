import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import YPImagePicker
import Photos

class UserProfileController: HomePostCellViewController, CreateGroupControllerDelegate, FullGroupCellDelegate, LargeImageViewControllerDelegate {

    var user: User? {
        didSet {
            configureUser()
        }
    }
    
    private var header: UserProfileHeader?
    
    private var alertController: UIAlertController = {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        return ac
    }()
    
    private var groups = [Group]()
    private var fetchedGroups = false
    
    private var isGridView: Bool = true
    
    private var isBlockedByThisUser = false
    
    private var isGroupHiddenDict = [String: Bool]()
    private var isInGroupFollowPendingDict = [String: Bool]()
    private var canViewGroupPostsDict = [String: Bool]()
    private var groupMembersDict = [String: [User]]()
    private var groupPosts2DDict = [String: [GroupPost]]()
    private var isInGroupDict = [String: Bool]()
    
    //MARK: First follow popup
    private let firstFollowLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Auto Group Follow", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
        attributedText.append(NSMutableAttributedString(string: "\n\nWhen you follow someone\nposts from their public groups\nwill appear in the following feed.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        label.attributedText = attributedText
        return label
    }()
    
    private lazy var firstFollowButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(closeFirstFollowPopup), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Got it", for: .normal)
        return button
    }()
    
    private let firstFollowBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 1)
//        view.layer.borderWidth = 1
//        view.layer.borderColor = UIColor.darkGray.cgColor
        view.layer.zPosition = 3
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 10
        view.isHidden = true
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 150
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(white: 0.98, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.98, alpha: 1)
        self.view.backgroundColor = UIColor.init(white: 0.98, alpha: 1)

        
//        let textAttributes = [NSAttributedString.Key.font: UIFont(name: "Avenir", size: 18)!, NSAttributedString.Key.foregroundColor : UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)]
//        navigationController?.navigationBar.titleTextAttributes = textAttributes
        let textAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18), NSAttributedString.Key.foregroundColor : UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateUserProfileFeed, object: nil)
        
        collectionView?.backgroundColor = .white
        collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UserProfileHeader.headerId)
        collectionView?.register(UserProfilePhotoGridCell.self, forCellWithReuseIdentifier: UserProfilePhotoGridCell.cellId)
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: HomePostCell.cellId)
        collectionView?.register(UserProfileEmptyStateCell.self, forCellWithReuseIdentifier: UserProfileEmptyStateCell.cellId)
        collectionView?.register(MembershipLabelCell.self, forCellWithReuseIdentifier: MembershipLabelCell.cellId)
        collectionView?.register(GroupCell.self, forCellWithReuseIdentifier: GroupCell.cellId)
        collectionView?.register(FullGroupCell.self, forCellWithReuseIdentifier: FullGroupCell.cellId)
        collectionView?.showsVerticalScrollIndicator = false

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        refreshControl.backgroundColor = UIColor.init(white: 0.98, alpha: 1)
        collectionView?.refreshControl = refreshControl

        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name(rawValue: "createdGroup"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadUser), name: NSNotification.Name(rawValue: "updatedUser"), object: nil)

        configureAlertController()
        fetchAllGroups()
        
        if user == nil {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            Database.database().fetchUser(withUID: uid) { (current_user) in
                if self.user == nil { // if user is still nil after the fetch
                    self.user = current_user
                    self.configureUser()
                    self.configureAlertController()
                    self.fetchAllGroups()
                }
            }
        }
        
        firstFollowLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height/3-80, width: UIScreen.main.bounds.width, height: 120)
        self.view.insertSubview(firstFollowLabel, at: 4)
        
        firstFollowBackground.frame = CGRect(x: UIScreen.main.bounds.width/2-140, y: UIScreen.main.bounds.height/3-120, width: 280, height: 270)
        self.view.insertSubview(firstFollowBackground, at: 3)
        
        firstFollowButton.frame = CGRect(x: UIScreen.main.bounds.width/2-50, y: UIScreen.main.bounds.height/3+60, width: 100, height: 50)
        firstFollowButton.layer.cornerRadius = 18
        self.view.insertSubview(firstFollowButton, at: 4)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
//        self.navigationController?.navigationBar.backgroundColor = UIColor.white
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.collectionView?.refreshControl?.endRefreshing()
//        header = nil
    }
    
    private func configureAlertController() {
        guard let user = user else { return }
        
        alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if user.uid == Auth.auth().currentUser?.uid {
            let logOutAction = UIAlertAction(title: "Log Out", style: .default) { (_) in
                do {
                    try Auth.auth().signOut()
                    
                    // remove all local storage
                    let defaults = UserDefaults.standard
                    let dictionary = defaults.dictionaryRepresentation()
                    dictionary.keys.forEach { key in
                        defaults.removeObject(forKey: key)
                    }
                    
                    let loginController = LoginPhoneController()
                    let navController = UINavigationController(rootViewController: loginController)
                    navController.modalPresentationStyle = .fullScreen
                    self.present(navController, animated: true, completion: nil)
                } catch let err {
                    print("Failed to sign out:", err)
                }
            }
            
            let edit_profile = UIAlertAction(title: "Edit Profile", style: .default) { (_) in
                do {
                    let editProfileController = EditProfileController()
                    editProfileController.user = user
                    let navController = UINavigationController(rootViewController: editProfileController)
                    navController.modalPresentationStyle = .fullScreen
                    self.present(navController, animated: true, completion: nil)
                }
            }
            
    //        let deleteAccountAction = UIAlertAction(title: "Delete Account", style: .destructive, handler: nil)
            
            // if want to add more database fetches use DispatchGroup... this is okay for now
            Database.database().isInIncognitoMode(completion: { (isIncognito) in
                if isIncognito {
                    let toggleIncognitoAction = UIAlertAction(title: "Show me in views", style: .default) { (_) in
                        do {
                            Database.database().disableIncognitoMode() { (err) in
                                if err != nil {
                                    return
                                }
                                self.configureAlertController()
                            }
                        }
                    }
                    self.alertController.addAction(edit_profile)
                    self.alertController.addAction(toggleIncognitoAction)
                    self.alertController.addAction(logOutAction)
    //                self.alertController.addAction(deleteAccountAction)
                } else {
                    let toggleIncognitoAction = UIAlertAction(title: "Hide me from views (Incognito)", style: .default) { (_) in
                        do {
                            Database.database().enableIncognitoMode() { (err) in
                                if err != nil {
                                    return
                                }
                                self.configureAlertController()
                            }
                        }
                    }
                    self.alertController.addAction(edit_profile)
                    self.alertController.addAction(toggleIncognitoAction)
                    self.alertController.addAction(logOutAction)
    //                self.alertController.addAction(deleteAccountAction)
                }
            })
        }
        else {
            if let reportAction = self.reportAction(forUser: user) {
                alertController.addAction(reportAction)
            }
            
            if let blockAction = self.blockAction(forUser: user) {
                alertController.addAction(blockAction)
            }
        }
    }
    
    private func reportAction(forUser user: User) -> UIAlertAction? {
        let action = UIAlertAction(title: "Report", style: .destructive, handler: { (_) in
            
            let alert = UIAlertController(title: "Report User?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Report", style: .default, handler: { (_) in
                Database.database().reportUser(withUID: user.uid) { (err) in
                    if err != nil {
                        return
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }
    
    private func blockAction(forUser user: User) -> UIAlertAction? {
        let action = UIAlertAction(title: "Block", style: .destructive, handler: { (_) in
            
            let alert = UIAlertController(title: "Block User?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Block", style: .default, handler: { (_) in
                Database.database().blockUser(withUID: user.uid) { (err) in
                    if err != nil {
                        return
                    }
                }
            }))
            self.present(alert, animated: true, completion: nil)
        })
        return action
    }
    
    private func fetchAllGroups() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        collectionView?.refreshControl?.beginRefreshing()
        
        guard let user = user else { return }
        
        Database.database().isUserBlocked(withUID: user.uid, completion: { (isBlocked) in
            self.isBlockedByThisUser = isBlocked
            if !isBlocked{
                Database.database().fetchAllGroups(withUID: user.uid, completion: { (groups) in
                    if user.uid == currentLoggedInUserId { // show all groups
                        self.groups = groups
                        self.groups.sort(by: { (g1, g2) -> Bool in
                            return g1.lastPostedDate > g2.lastPostedDate
                        })
                        self.fetchedGroups = true
                        self.fetchGroupMembers(groups: groups)
                        self.fetchGroupInfo(groups: groups)
//                        self.collectionView?.reloadData()
//                        self.collectionView?.refreshControl?.endRefreshing()
                    }
                    else {
                        var visibleGroups = [Group]()
                        let sync = DispatchGroup()
                        groups.forEach { group in  // check if cell is still visible
                            sync.enter()
                            Database.database().isGroupHiddenForUser(withUID: user.uid, groupId: group.groupId, completion: { (isHidden) in
                                // only allow this if is in group
                                if !isHidden {
                                    visibleGroups.append(group)
                                }
                                sync.leave()
                            }) { (err) in
                                return
                            }
                        }
                        sync.notify(queue: .main) {
                            self.groups = visibleGroups
                            self.groups.sort(by: { (g1, g2) -> Bool in
                                return g1.lastPostedDate > g2.lastPostedDate
                            })
                            self.fetchedGroups = true
                            self.fetchGroupMembers(groups: groups)
                            self.fetchGroupInfo(groups: groups)
//                            self.collectionView?.reloadData()
//                            self.collectionView?.refreshControl?.endRefreshing()
                        }
                    }
                }) { (_) in
                    self.collectionView?.refreshControl?.endRefreshing()
                }
            }
            else {
                self.collectionView?.refreshControl?.endRefreshing()
            }
        })
    }
    
    private func fetchGroupMembers(groups: [Group]){
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
            self.collectionView?.reloadData()
        }
    }
    
    private func fetchGroupInfo(groups: [Group]){
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        let sync = DispatchGroup()
        sync.enter()
        for group in groups {
            sync.enter()
            let groupId = group.groupId
            Database.database().isGroupHiddenOnProfile(groupId: group.groupId, completion: { (isHidden) in
                self.isGroupHiddenDict[groupId] = isHidden
                
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
            }) { (err) in
                return
            }
        }
        sync.leave()
        sync.notify(queue: .main) {
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }
    
    @objc private func reloadUser(){
        self.handleRefresh()
    }
    
    private func configureUser() {
        guard let user = user else { return }
        
        if user.uid == Auth.auth().currentUser?.uid {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleSettings))
        }
        else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "•••", style: .plain, target: self, action: #selector(handleSettings))
            navigationItem.rightBarButtonItem?.tintColor = .black
        }
        
        navigationItem.title = user.username
        header?.user = user
        header?.reloadData()
        
        Database.database().isUserBlocked(withUID: user.uid, completion: { (isBlocked) in
            self.header?.isBlocked = isBlocked
        })
    }
    
    @objc private func handleSettings() {
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func handleRefresh() {
        fetchAllGroups()
//        configureUser()
//        configureAlertController()
        
        guard let existing_user = user else { return }
        Database.database().fetchUser(withUID: existing_user.uid, completion: { (updated_user) in
            self.user = updated_user
            self.configureAlertController()
        })
    }
    
    // when an item is selected, go to that view controller
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if groups.count == 0 || indexPath.item == 0 {
            return
        }
        let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        groupProfileController.group = groups[indexPath.item-1]
        navigationController?.pushViewController(groupProfileController, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if fetchedGroups == false {
            return 0
        }
        if groups.count == 0 {
            return 1
        }
        return groups.count + 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if groups.count == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserProfileEmptyStateCell.cellId, for: indexPath) as! UserProfileEmptyStateCell
            return cell
        }
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MembershipLabelCell.cellId, for: indexPath) as! MembershipLabelCell
            cell.numberOfGroups = groups.count
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FullGroupCell.cellId, for: indexPath) as! FullGroupCell
        cell.group = groups[indexPath.item - 1]
        cell.user = user
        let groupId = groups[indexPath.item - 1].groupId
        cell.isGroupHidden = isGroupHiddenDict[groupId]
        cell.isInFollowPending = isInGroupFollowPendingDict[groupId]
        cell.canView = canViewGroupPostsDict[groupId]
        cell.isInGroup = isInGroupDict[groupId]
        cell.groupMembers = groupMembersDict[groupId]
        cell.groupPosts = groupPosts2DDict[groupId]
        cell.delegate = self
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if header == nil {
            header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UserProfileHeader.headerId, for: indexPath) as? UserProfileHeader
            header?.delegate = self
            header?.user = user
        }
        return header!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        guard let user = user else { return CGSize(width: view.frame.width, height: 115) }
        guard let user = user else { return CGSize(width: view.frame.width, height: 235) }
        let bio = user.bio
        if bio == "" {
            return CGSize(width: view.frame.width, height: 165)
        }
        else {
            if bio.count < 40 {
                return CGSize(width: view.frame.width, height: 195)
            }
            else if bio.count < 80 {
                return CGSize(width: view.frame.width, height: 215)
            }
            else {
                return CGSize(width: view.frame.width, height: 235)
            }
        }
    }
    
    func shouldOpenGroup(groupId: String) {
        Database.database().groupExists(groupId: groupId, completion: { (exists) in
            if exists {
                Database.database().fetchGroup(groupId: groupId, completion: { (group) in
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
    
    func didTapGroupPost(groupPost: GroupPost, index: Int) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.minimumLineSpacing = CGFloat(0)
        
        let largeImageViewController = LargeImageViewController(collectionViewLayout: layout)
        largeImageViewController.group = groupPost.group
        largeImageViewController.delegate = self
        largeImageViewController.indexPath = IndexPath(item: index, section: 0)
        let navController = UINavigationController(rootViewController: largeImageViewController)
        navController.modalPresentationStyle = .overCurrentContext
        
        self.present(navController, animated: true, completion: nil)
        
        handleDidView(groupPost: groupPost)
    }
    
    func didExitLargeImageView() {
    }
    
    func didFollowFirstUser() {
        self.showFirstFollowPopup()
    }
    
    @objc func showFirstFollowPopup() {
        self.firstFollowLabel.isHidden = false
        self.firstFollowBackground.isHidden = false
        self.firstFollowButton.isHidden = false
        
        self.firstFollowLabel.alpha = 0
        self.firstFollowBackground.alpha = 0
        self.firstFollowButton.alpha = 0
        
        UIView.animate(withDuration: 0.5) {
            self.collectionView.alpha = 0
            self.firstFollowLabel.alpha = 1
            self.firstFollowBackground.alpha = 1
            self.firstFollowButton.alpha = 1
        }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            self.collectionView.isHidden = true
        }
        
    }
    
    @objc func closeFirstFollowPopup() {
        self.firstFollowLabel.alpha = 1
        self.firstFollowBackground.alpha = 1
        self.firstFollowButton.alpha = 1
        
        self.collectionView.isHidden = false
        self.collectionView.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.collectionView.alpha = 1
            self.firstFollowLabel.alpha = 0
            self.firstFollowBackground.alpha = 0
            self.firstFollowButton.alpha = 0
        }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            self.firstFollowLabel.isHidden = true
            self.firstFollowBackground.isHidden = true
            self.firstFollowButton.isHidden = true
        }
    }
    
    func handleDidView(groupPost: GroupPost) {
        Database.database().addToViewedPosts(postId: groupPost.id, completion: { _ in })
    }
    
    func postToGroup(group: Group) {
        let tempPostCameraController = TempPostCameraController()
        tempPostCameraController.preSelectedGroup = group
        let navController = UINavigationController(rootViewController: tempPostCameraController)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true, completion: nil)
    }
}

extension UserProfileController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if groups.count == 0 {
            let emptyStateCellHeight = (view.safeAreaLayoutGuide.layoutFrame.height - 115)
            return CGSize(width: view.frame.width, height: emptyStateCellHeight)
        }
        if indexPath.item == 0 {
            return CGSize(width: view.frame.width, height: 60)
        }
        return CGSize(width: view.frame.width, height: 310)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if groups.count == 0  {
            return 0
        }
        else {
            return 20
        }
    }
}

//MARK: - UserProfileHeaderDelegate

extension UserProfileController: UserProfileHeaderDelegate {

    func didChangeToGridView() {
        isGridView = true
        collectionView?.reloadData()
    }

    func didChangeToListView() {
        isGridView = false
        collectionView?.reloadData()
    }

    @objc internal func handleShowNewGroup() {
        let createGroupController = CreateGroupController()
        createGroupController.delegate = self
        let navController = UINavigationController(rootViewController: createGroupController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true, completion: nil)
    }
    
    @objc internal func handleInviteGroup() {
        guard let user = user else { return }
        let inviteSelectionController = InviteSelectionController()
        inviteSelectionController.user = user
        let navController = UINavigationController(rootViewController: inviteSelectionController)
        if !isBlockedByThisUser{
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    @objc internal func didSelectFollowPage(showFollowers: Bool){
        guard let user = user else { return }
        let followPage = FollowPageController(collectionViewLayout: UICollectionViewFlowLayout())
        followPage.user = user
        followPage.isFollowerView = showFollowers
        if !isBlockedByThisUser{
            self.navigationController?.pushViewController(followPage, animated: true)
        }
    }
    
    func didSelectSubscriptionsPage() {
        guard let user = user else { return }
        let subscriptionsPage = SubscriptionsController(collectionViewLayout: UICollectionViewFlowLayout())
        subscriptionsPage.user = user
        if !isBlockedByThisUser{
            self.navigationController?.pushViewController(subscriptionsPage, animated: true)
        }
    }
}

