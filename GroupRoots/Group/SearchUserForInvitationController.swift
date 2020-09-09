//
//  SearchUserForInvitationController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 8/29/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

//
//  InviteToGroupController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/24/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol SearchUserForInvitationDelegate {
    func addUser(user: User)
}

class SearchUserForInvitationController: UICollectionViewController {
    
    var group: Group? {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    var delegate: SearchUserForInvitationDelegate?
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Username"
        sb.autocorrectionType = .no
        sb.autocapitalizationType = .none
        sb.barTintColor = .gray
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        return sb
    }()
    
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
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneSelected))
//        navigationItem.rightBarButtonItem?.tintColor = .black
        self.navigationController?.navigationBar.shadowImage = UIColor.white.as1ptImage()
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(InviteToGroupCell.self, forCellWithReuseIdentifier: InviteToGroupCell.cellId)
        
        searchBar.delegate = self
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
    
    @objc private func doneSelected(){
        self.dismiss(animated: true, completion: nil)
    }
    
    private func searchForUser(username: String){
        if username.range(of: #"^[a-zA-Z0-9_-]*$"#, options: .regularExpression) == nil || username == "" {
            return
        }
        collectionView?.refreshControl?.beginRefreshing()
        self.filteredUsers = []
        Database.database().searchForUsers(username: username, completion: { (users) in
            self.filteredUsers = users
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

extension SearchUserForInvitationController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 66)
    }
}

//MARK: - UISearchBarDelegate

extension SearchUserForInvitationController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.filteredUsers = []
            self.collectionView?.reloadData()
        } else {
            searchForUser(username: searchText)
        }
    }
    
    func InviteToGroupController(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

//MARK: - InviteToGroupCellDelegate
extension SearchUserForInvitationController: InviteToGroupCellDelegate {
    func inviteSentMessage(){
        let alert = UIAlertController(title: "", message: "Invite Sent", preferredStyle: .alert)
        self.present(alert, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){
          alert.dismiss(animated: true, completion: nil)
        }
    }
    
    func addUser(user: User){
        self.delegate?.addUser(user: user)
        self.navigationController?.popViewController(animated: true)
    }
}

