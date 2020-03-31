//
//  InviteToGroupController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/24/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

class InviteToGroupController: UICollectionViewController {
    
    var group: Group? {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Add to group"
        sb.autocorrectionType = .no
        sb.autocapitalizationType = .none
        sb.barTintColor = .gray
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        return sb
    }()
    
//    private let InviteLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Add To Group"
//        label.font = UIFont.boldSystemFont(ofSize: 16)
//        return label
//    }()
    
    private var filteredUsers = [User]()
    
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
        collectionView?.register(InviteToGroupCell.self, forCellWithReuseIdentifier: InviteToGroupCell.cellId)
        
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
    
//    private func fetchAllUsers() {
//        collectionView?.refreshControl?.beginRefreshing()
//
//        Database.database().fetchAllUsers(includeCurrentUser: false, completion: { (users) in
//            self.users = users
//            self.filteredUsers = users
//            self.searchBar.text = ""
//            self.collectionView?.reloadData()
//            self.collectionView?.refreshControl?.endRefreshing()
//        }) { (_) in
//            self.collectionView?.refreshControl?.endRefreshing()
//        }
//    }
    
    private func searchForUser(username: String){
        collectionView?.refreshControl?.beginRefreshing()
        self.filteredUsers = []
        Database.database().searchForUser(username: username, completion: { (user) in
            self.filteredUsers.append(user)
            self.collectionView?.reloadData()
            self.collectionView?.refreshControl?.endRefreshing()
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredUsers.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InviteToGroupCell.cellId, for: indexPath) as! InviteToGroupCell
        cell.user = filteredUsers[indexPath.item]
        cell.group = group
        cell.delegate = self
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout

extension InviteToGroupController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 66)
    }
}

//MARK: - UISearchBarDelegate

extension InviteToGroupController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.filteredUsers = []
            self.collectionView?.reloadData()
        } else {
            searchForUser(username: searchText)
//            filteredUsers = users.filter { (user) -> Bool in
//                return user.username.lowercased().contains(searchText.lowercased())
//            }
        }
        self.collectionView?.reloadData()
    }
    
    func InviteToGroupController(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

//MARK: - InviteToGroupCellDelegate
extension InviteToGroupController: InviteToGroupCellDelegate {
    func inviteSentMessage(){
        let alert = UIAlertController(title: "", message: "Invite Sent", preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
          alert.dismiss(animated: true, completion: nil)
        }
    }
}
