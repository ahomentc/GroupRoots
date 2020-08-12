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

class InviteToGroupController: UICollectionViewController {
    
    var group: Group? {
        didSet {
            self.setInviteCode()
            self.collectionView.reloadData()
        }
    }
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search for user to add"
        sb.autocorrectionType = .no
        sb.autocapitalizationType = .none
        sb.barTintColor = .gray
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
        return sb
    }()
    
    private lazy var codeLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(white: 0.9, alpha: 1)
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.layer.cornerRadius = 20
        label.layer.masksToBounds = true
        label.isHidden = false
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
        label.attributedText = attributedText
        return label
    }()
    
    private lazy var shareLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(white: 0.9, alpha: 1)
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.layer.cornerRadius = 20
        label.layer.masksToBounds = true
        label.isHidden = false
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Share the download link\ngrouproots.com/app", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
        label.attributedText = attributedText
        return label
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneSelected))
        navigationItem.rightBarButtonItem?.tintColor = .black
        self.navigationController?.navigationBar.shadowImage = UIColor.white.as1ptImage()
        
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.keyboardDismissMode = .onDrag
        collectionView?.register(InviteToGroupCell.self, forCellWithReuseIdentifier: InviteToGroupCell.cellId)
        
        searchBar.delegate = self
        
        shareLabel.frame = CGRect(x: 40, y: UIScreen.main.bounds.height - 220, width: UIScreen.main.bounds.width - 80, height: 60)
        shareLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(shareDownload)))
        self.view.insertSubview(shareLabel, at: 4)
        
        codeLabel.frame = CGRect(x: 40, y: UIScreen.main.bounds.height - 140, width: UIScreen.main.bounds.width - 80, height: 60)
        codeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(shareInvite)))
        self.view.insertSubview(codeLabel, at: 4)
        
//        let arrow_1 = UIImageView(image: #imageLiteral(resourceName: "arrow_right"))
//        arrow_1.frame = CGRect(x: UIScreen.main.bounds.width - 50, y: UIScreen.main.bounds.height/2 - 90, width: 40, height: 40)
//        self.view.insertSubview(arrow_1, at: 6)
        
//        let arrow_2 = UIImageView(image: #imageLiteral(resourceName: "arrow_right"))
//        view.addSubview(arrow_2)
//        arrow_2.frame = CGRect(x: view.frame.width/2 - 115, y: 50, width: 230, height: 230)
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
    
    @objc private func shareInvite(){
        guard let group = group else { return }
        let code = String(group.groupId.suffix(6))
        let stripped_code = code.replacingOccurrences(of: "_", with: "a", options: .literal, range: nil)
        let stripped_code2 = stripped_code.replacingOccurrences(of: "-", with: "b", options: .literal, range: nil)
        let items = ["Use this code to join the group when signing up: " + stripped_code2]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
    
    @objc private func shareDownload(){
        let items = [URL(string: "https://apps.apple.com/us/app/id1525863510")!]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
    
    @objc private func setInviteCode(){
        guard let group = group else { return }
        let code = String(group.groupId.suffix(6))
        let stripped_code = code.replacingOccurrences(of: "_", with: "a", options: .literal, range: nil)
        let stripped_code2 = stripped_code.replacingOccurrences(of: "-", with: "b", options: .literal, range: nil)
        let attributedText = NSMutableAttributedString(string: "Share the group invite code\n" + stripped_code2, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
        self.codeLabel.attributedText = attributedText
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
            codeLabel.isHidden = true
            shareLabel.isHidden = true
            codeLabel.isUserInteractionEnabled = false
            shareLabel.isUserInteractionEnabled = false
            searchForUser(username: searchText)
        }
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
