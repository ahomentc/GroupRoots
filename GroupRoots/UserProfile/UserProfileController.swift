import UIKit
import Firebase

class UserProfileController: HomePostCellViewController {
    
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
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        
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

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
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
        
        let logOutAction = UIAlertAction(title: "Log Out", style: .default) { (_) in
            do {
                try Auth.auth().signOut()
                
                // remove all local storage
                let defaults = UserDefaults.standard
                let dictionary = defaults.dictionaryRepresentation()
                dictionary.keys.forEach { key in
                    defaults.removeObject(forKey: key)
                }
                
                let loginController = LoginController()
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
        
        let deleteAccountAction = UIAlertAction(title: "Delete Account", style: .destructive, handler: nil)
        
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
                self.alertController.addAction(deleteAccountAction)
            } else {
                let toggleIncognitoAction = UIAlertAction(title: "Hide me from views", style: .default) { (_) in
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
                self.alertController.addAction(deleteAccountAction)
            }
        })
    }
    
    private func fetchAllGroups() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        collectionView?.refreshControl?.beginRefreshing()

        guard let user = user else { return }
        Database.database().fetchAllGroups(withUID: user.uid, completion: { (groups) in
            if user.uid == currentLoggedInUserId { // show all groups
                self.groups = groups
                self.fetchedGroups = true
                self.collectionView?.reloadData()
                self.collectionView?.refreshControl?.endRefreshing()
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
                    self.fetchedGroups = true
                    self.collectionView?.reloadData()
                    self.collectionView?.refreshControl?.endRefreshing()
                }
            }
        }) { (_) in
            self.collectionView?.refreshControl?.endRefreshing()
        }
    }
    
    @objc private func reloadUser(){
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().fetchUser(withUID: currentLoggedInUserId, completion: { (user) in
            self.user = user
            self.handleRefresh()
        })
    }
    
    private func configureUser() {
        guard let user = user else { return }
        
        if user.uid == Auth.auth().currentUser?.uid {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleSettings))
        }
        
        navigationItem.title = user.username
        header?.user = user
    }
    
    @objc private func handleSettings() {
        present(alertController, animated: true, completion: nil)
    }
    
    @objc private func handleRefresh() {
//        groupPosts.removeAll()
        fetchAllGroups()
        configureUser()
        configureAlertController()
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
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupCell.cellId, for: indexPath) as! GroupCell
        cell.group = groups[indexPath.item - 1]
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
        return CGSize(width: view.frame.width, height: 115)
    }

}

extension UserProfileController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if groups.count == 0 {
            let emptyStateCellHeight = (view.safeAreaLayoutGuide.layoutFrame.height - 115)
            return CGSize(width: view.frame.width, height: emptyStateCellHeight)
        }
        if indexPath.item == 0 {
            return CGSize(width: view.frame.width, height: 40)
        }
        return CGSize(width: view.frame.width, height: 80)
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
        let nacController = UINavigationController(rootViewController: createGroupController)
//        nacController.modalPresentationStyle = .fullScreen
        present(nacController, animated: true, completion: nil)
    }
    
    @objc internal func handleInviteGroup() {
        let inviteSelectionController = InviteSelectionController()
        inviteSelectionController.user = user
        let navController = UINavigationController(rootViewController: inviteSelectionController)
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc internal func didSelectFollowPage(showFollowers: Bool){
        let followPage = FollowPageController(collectionViewLayout: UICollectionViewFlowLayout())
        followPage.user = user
        followPage.isFollowerView = showFollowers
        navigationController?.pushViewController(followPage, animated: true)
    }
    
    func didSelectSubscriptionsPage() {
        let subscriptionsPage = SubscriptionsController(collectionViewLayout: UICollectionViewFlowLayout())
        subscriptionsPage.user = user
        navigationController?.pushViewController(subscriptionsPage, animated: true)
    }
}

