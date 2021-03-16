//
//  SelectGroupController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/2/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import Photos
import YPImagePicker
import FirebaseAuth
import FirebaseDatabase
import LocationPicker
import MapKit

class SelectGroupController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, SelectGroupCellDelegate {
    
    private var groups = [Group]()
    private var selectedGroupId = ""
    private var collectionView: UICollectionView!
    var last_selected_indexpath: IndexPath?
    
    var for_sticker: Bool?
    
    let separatorView: UIView = {
        let view = UIView()
        return view
    }()
    
    private var _didFinishPicking: ((Group, Bool) -> Void)?
    public func didFinishPicking(completion: @escaping (_ items: Group, _ cancelled: Bool) -> Void) {
        _didFinishPicking = completion
    }
    
    private lazy var newGroupButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleCreateGroup), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.backgroundColor = UIColor(white: 1, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Post to a new group", for: .normal)
        button.layer.cornerRadius = 14
        button.isUserInteractionEnabled = true
        return button
    }()
    
    private let creatForGroupLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.isHidden = true
        label.textColor = .white
        label.text = "Save To Group"
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        view.backgroundColor = UIColor.init(white: 0, alpha: 0.85)
        
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
//        navigationItem.leftBarButtonItem?.tintColor = .white
        
        self.navigationController?.navigationBar.height(CGFloat(50))
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(white: 0, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0, alpha: 1)
        
        if for_sticker != nil && for_sticker! == true {
            self.newGroupButton.setTitle("Create for a new group", for: .normal)
            self.navigationItem.title = "Select Group For Sticker"
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
            self.navigationController?.navigationBar.titleTextAttributes = textAttributes
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Skip", style: .plain, target: self, action: #selector(handleCancel))
            navigationItem.leftBarButtonItem?.tintColor = .white
        }
        else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
            navigationItem.leftBarButtonItem?.tintColor = .white
        }
        
        layoutViews()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleRefresh), name: NSNotification.Name.updateGroupsToPostTo, object: nil)
    }
    
    @objc private func handleCancel() {
        dismiss(animated: true, completion: {
            self._didFinishPicking?(Group(groupId: "", dictionary: Dictionary()), true)
        })
    }
    
    private func layoutViews() {
        self.view.addSubview(newGroupButton)
        newGroupButton.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 25, paddingLeft: 50, paddingRight: 50, height: 50)
        
        fetchAllGroups()
    }
    
    internal func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        self.selectedGroupId = groups[indexPath.row].groupId
        
//        if last_selected_indexpath != nil {
//            let old_cell = collectionView.cellForItem(at: last_selected_indexpath!)
//            old_cell?.layer.backgroundColor = UIColor.white.cgColor
//        }
        
//        let cell = collectionView.cellForItem(at: indexPath)
//        cell?.layer.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        
//        last_selected_indexpath = indexPath
        self.dismiss(animated: true, completion: {})
    }
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groups.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectGroupCell.cellId, for: indexPath) as! SelectGroupCell
        if indexPath.item < groups.count {
            cell.group = groups[indexPath.item]
        }
        cell.tag = indexPath.row
        cell.delegate = self
        cell.user = User(uid: "", dictionary: ["":0])
//        if last_selected_indexpath == indexPath {
//            cell.layer.backgroundColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
//        }
        return cell
    }
    
    func setCollectionView(){
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        
        self.collectionView = UICollectionView(frame: CGRect(x: 0, y: 100, width: displayWidth, height: UIScreen.main.bounds.height - barHeight - 100), collectionViewLayout: layout)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        self.collectionView?.register(SelectGroupCell.self, forCellWithReuseIdentifier: SelectGroupCell.cellId)
        self.collectionView?.register(NewGroupInPostCell.self, forCellWithReuseIdentifier: NewGroupInPostCell.cellId)
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.keyboardDismissMode = .onDrag
        self.view.addSubview(self.collectionView)
    }
    
    @objc func handleRefresh() {
        fetchAllGroups()
    }
    
    private func fetchAllGroups() {
        Database.database().fetchAllGroups(withUID: "", completion: { (groups) in
            self.groups = groups
            self.setCollectionView()
        }) { (_) in}
    }
    
    @objc private func handleCreateGroup(){
        let createGroupController = CreateGroupController()
        let navController = UINavigationController(rootViewController: createGroupController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true, completion: nil)
    }
    
    func didSelectGroup(group: Group) {
        self.dismiss(animated: true, completion: {
            self._didFinishPicking?(group, false)
        })
    }
    
    @objc private func handleShare() {
        
    }
}

extension SelectGroupController: UICollectionViewDelegateFlowLayout {
    internal func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
    }
}




