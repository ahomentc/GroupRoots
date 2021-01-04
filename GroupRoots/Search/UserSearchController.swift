import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import Contacts

class UserSearchController: UICollectionViewController, EmptySearchCellDelegate {

    func didTapUser(user: User) {
        let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = user
        userProfileController.modalPresentationCapturesStatusBarAppearance = true
        navigationController?.pushViewController(userProfileController, animated: true)
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
                    if cell is EmptySearchCell {
                        (cell as! EmptySearchCell).collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func requestImportContactsIfAuth() {
        importContactsToRecommended() { (err) in
            self.collectionView.visibleCells.forEach { cell in
                if cell is EmptySearchCell {
                    (cell as! EmptySearchCell).collectionView.reloadData()
                }
            }
        }
    }
    
    
    private var header: SearchHeader?
    private var isUsersView: Bool = true
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Enter username"
        sb.autocorrectionType = .no
        sb.autocapitalizationType = .none
        sb.barTintColor = .gray
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        return sb
    }()
    
    private var filteredUsers = [User]()
    private var filteredGroups = [Group]()
    
    //MARK: First follow popup
    private let firstFollowLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Auto Group Follow", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
        attributedText.append(NSMutableAttributedString(string: "\n\nWhen you follow someone,\nyou auto follow the public\ngroups they're members of.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
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
        
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
        
        navigationItem.titleView = searchBar
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .black
        self.navigationController?.navigationBar.shadowImage = UIColor.white.as1ptImage()
                
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(UserSearchCell.self, forCellWithReuseIdentifier: UserSearchCell.cellId)
        collectionView?.register(GroupSearchCell.self, forCellWithReuseIdentifier: GroupSearchCell.cellId)
        collectionView?.register(SearchHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SearchHeader.headerId)
        collectionView?.register(EmptySearchCell.self, forCellWithReuseIdentifier: EmptySearchCell.cellId)
        
        searchBar.delegate = self
        
        firstFollowLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height/2-80, width: UIScreen.main.bounds.width, height: 120)
        self.view.insertSubview(firstFollowLabel, at: 4)
        
        firstFollowBackground.frame = CGRect(x: UIScreen.main.bounds.width/2-140, y: UIScreen.main.bounds.height/2-120, width: 280, height: 270)
        self.view.insertSubview(firstFollowBackground, at: 3)
        
        firstFollowButton.frame = CGRect(x: UIScreen.main.bounds.width/2-50, y: UIScreen.main.bounds.height/2+60, width: 100, height: 50)
        firstFollowButton.layer.cornerRadius = 18
        self.view.insertSubview(firstFollowButton, at: 4)
        
//        fetchAllUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
        self.collectionView?.refreshControl?.endRefreshing()
    }
    
    private func searchForUser(username: String){
        let formatted_search_word = username.removeCharacters(from: "@")
        if formatted_search_word.range(of: #"^[a-zA-Z0-9_-]*$"#, options: .regularExpression) == nil || formatted_search_word == "" {
            return
        }
        collectionView?.refreshControl?.beginRefreshing()
        self.filteredUsers = []
        Database.database().searchForUsers(username: formatted_search_word, completion: { (users) in
            self.filteredUsers = users
            Database.database().searchForUsers(username: formatted_search_word.lowercased(), completion: { (lowercase_users) in
                for user in lowercase_users {
                    if !self.filteredUsers.contains(user) {
                        self.filteredUsers.append(user)
                    }
                }
                Database.database().searchForUsers(username: formatted_search_word.capitalizingFirstLetter(), completion: { (first_capitalized_users) in
                    for user in first_capitalized_users {
                        if !self.filteredUsers.contains(user) {
                            self.filteredUsers.append(user)
                        }
                    }
                    self.collectionView?.reloadData()
                    self.collectionView?.refreshControl?.endRefreshing()
                })
            })
        })
    }
    
    private func searchForGroup(search_word: String){
        let formatted_search_word = search_word.removeCharacters(from: "@")
        if formatted_search_word.range(of: #"^[a-zA-Z0-9_-]*$"#, options: .regularExpression) == nil || formatted_search_word == "" {
            return
        }
        collectionView?.refreshControl?.beginRefreshing()
        self.filteredGroups = []

        Database.database().inviteCodeExists(code: formatted_search_word, completion: { (exists) in
            if exists {
                // search by invite code
                Database.database().searchForGroupWithInviteCode(invite_code: formatted_search_word, completion: { (groups) in
                    self.filteredGroups.append(groups)
                    self.collectionView?.reloadData()
                    self.collectionView?.refreshControl?.endRefreshing()
                })
            }
            else {
                // search by group name
                Database.database().searchForGroups(groupname: formatted_search_word, completion: { (groups) in
                    self.filteredGroups = groups
                    
                    Database.database().searchForGroups(groupname: formatted_search_word.lowercased(), completion: { (lowercase_groups) in
                        for group in lowercase_groups {
                            if !self.filteredGroups.contains(group) {
                                self.filteredGroups.append(group)
                            }
                        }
                        Database.database().searchForGroups(groupname: formatted_search_word.capitalizingFirstLetter(), completion: { (first_capitalized_groups) in
                            for group in first_capitalized_groups {
                                if !self.filteredGroups.contains(group) {
                                    self.filteredGroups.append(group)
                                }
                            }
                            self.collectionView?.reloadData()
                            self.collectionView?.refreshControl?.endRefreshing()
                        })
                    })
                })
            }
        })
    }
    
//    @objc private func handleRefresh() {
//        fetchAllUsers()
//    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        searchBar.resignFirstResponder()
        if isUsersView {
            if filteredUsers.count == 0 {
                return
            }
            let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
            if indexPath.item < filteredUsers.count {
                userProfileController.user = filteredUsers[indexPath.item]
            }
            navigationController?.pushViewController(userProfileController, animated: true)
        }
        else {
            if filteredGroups.count == 0 {
                return
            }
            let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
            if indexPath.item < filteredGroups.count {
                groupProfileController.group = filteredGroups[indexPath.item]
            }
//            groupProfileController.modalPresentationCapturesStatusBarAppearance = true
            navigationController?.pushViewController(groupProfileController, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isUsersView {
            return filteredUsers.count > 0 || searchBar.text != "" ? filteredUsers.count : 1
        }
        else {
            return filteredGroups.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isUsersView {
            if filteredUsers.count == 0 && searchBar.text == "" {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptySearchCell.cellId, for: indexPath) as! EmptySearchCell
                cell.delegate = self
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserSearchCell.cellId, for: indexPath) as! UserSearchCell
                cell.user = filteredUsers[indexPath.item]
                return cell
            }
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupSearchCell.cellId, for: indexPath) as! GroupSearchCell
            cell.group = filteredGroups[indexPath.item]
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if header == nil {
            header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SearchHeader.headerId, for: indexPath) as? SearchHeader
            header?.delegate = self
        }
        return header!
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
}

//MARK: - UICollectionViewDelegateFlowLayout

extension UserSearchController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if isUsersView && filteredUsers.count == 0 {
            return CGSize(width: view.frame.width, height: view.frame.height/1.5)
        }
        return CGSize(width: view.frame.width, height: 66)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 44)
    }
}

//MARK: - UISearchBarDelegate

extension UserSearchController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.filteredUsers = []
            self.filteredGroups = []
            self.collectionView?.reloadData()
        } else {
            if isUsersView {
                searchForUser(username: searchText)
            }
            else {
                searchForGroup(search_word: searchText.replacingOccurrences(of: " ", with: "_-a-_").replacingOccurrences(of: "‘", with: "_-b-_").replacingOccurrences(of: "'", with: "_-b-_").replacingOccurrences(of: "’", with: "_-b-_"))
            }
        }
        self.collectionView?.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

//MARK: - MembersHeaderDelegate

extension UserSearchController: SearchHeaderDelegate {
    func didChangeToUsersView() {
        isUsersView = true
        self.filteredUsers = []
        self.filteredGroups = []
        collectionView?.reloadData()
        self.searchForUser(username: self.searchBar.text ?? "")
        self.searchBar.placeholder = "Enter username"
    }

    func didChangeToGroupsView() {
        isUsersView = false
        self.filteredUsers = []
        self.filteredGroups = []
        collectionView?.reloadData()
        self.searchForGroup(search_word: self.searchBar.text ?? "")
        self.searchBar.placeholder = "Enter group name or invite code"
    }
}
