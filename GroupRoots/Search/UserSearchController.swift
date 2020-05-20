import UIKit
import Firebase

class UserSearchController: UICollectionViewController {
    
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
        
//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
//        collectionView?.refreshControl = refreshControl
        
        searchBar.delegate = self
        
//        fetchAllUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
        self.collectionView?.refreshControl?.endRefreshing()
    }
    
    private func searchForUser(username: String){
        if username.range(of: #"^[a-zA-Z0-9_-]*$"#, options: .regularExpression) == nil || username == "" {
            return
        }
        collectionView?.refreshControl?.beginRefreshing()
        self.filteredUsers = []
        Database.database().searchForUser(username: username, completion: { (user) in
            self.filteredUsers.append(user)
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        })
    }
    
    private func searchForGroup(groupname: String){
        if groupname.range(of: #"^[a-zA-Z0-9_-]*$"#, options: .regularExpression) == nil || groupname == "" {
            return
        }
        collectionView?.refreshControl?.beginRefreshing()
        self.filteredGroups = []
        Database.database().searchForGroup(groupname: groupname, completion: { (group) in
            self.filteredGroups.append(group)
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        })
    }
    
//    @objc private func handleRefresh() {
//        fetchAllUsers()
//    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        searchBar.resignFirstResponder()
        if isUsersView {
            let userProfileController = UserProfileController(collectionViewLayout: UICollectionViewFlowLayout())
            userProfileController.user = filteredUsers[indexPath.item]
            navigationController?.pushViewController(userProfileController, animated: true)
        }
        else {
            let groupProfileController = GroupProfileController(collectionViewLayout: UICollectionViewFlowLayout())
            groupProfileController.group = filteredGroups[indexPath.item]
//            groupProfileController.modalPresentationCapturesStatusBarAppearance = true
            navigationController?.pushViewController(groupProfileController, animated: true)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isUsersView {
            return filteredUsers.count
        }
        else {
            return filteredGroups.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isUsersView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserSearchCell.cellId, for: indexPath) as! UserSearchCell
            cell.user = filteredUsers[indexPath.item]
            return cell
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
}

//MARK: - UICollectionViewDelegateFlowLayout

extension UserSearchController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
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
                searchForGroup(groupname: searchText)
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
        collectionView?.reloadData()
        self.searchForUser(username: self.searchBar.text ?? "")
    }

    func didChangeToGroupsView() {
        isUsersView = false
        self.filteredUsers = []
        collectionView?.reloadData()
        self.searchForGroup(groupname: self.searchBar.text ?? "")
    }
}
