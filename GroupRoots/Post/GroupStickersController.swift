//
//  GroupStickersController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/12/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import PanModal

// should have two collection views
// view 1 is My Stickers
// view 2 is Group Stickers
// there can be overlap as in my stickers can have stickers that are in groupstickers too

class GroupStickersController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, PanModalPresentable {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var group: Group?
    var backgroundImage: UIImage?
    
    var isGroupStickers = true
    
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var shortFormHeight: PanModalHeight {
//        return .maxHeight
        return .contentHeight(550)
    }

    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(100)
    }
    
    private lazy var groupStickersButton: UIButton = {
        let button = UIButton()
        button.setTitle("Group Stickers", for: .normal)
        button.layer.zPosition = 10
        button.backgroundColor = UIColor(white: 1, alpha: 0)
        button.setTitleColor(UIColor(white: 1, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.titleLabel?.textAlignment = .right
        button.addTarget(self, action: #selector(changeToGroupStickers), for: .touchUpInside)
        return button
    }()
    
    let noGroupLabel: UILabel = {
        let label = UILabel()
        label.text = "No group selected"
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.isHidden = true
        label.layer.zPosition = 22
        return label
    }()

    private lazy var selectGroup: UIButton = {
        let button = UIButton()
        button.layer.zPosition = 4;
        button.backgroundColor = UIColor(white: 1, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Select Group", for: .normal)
        button.layer.cornerRadius = 14
        button.isUserInteractionEnabled = true
        button.isHidden = true
        button.addTarget(self, action: #selector(selectAGroup), for: .touchUpInside)
        return button
    }()
    
    private lazy var myStickersButton: UIButton = {
        let button = UIButton()
        button.setTitle("My Stickers", for: .normal)
        button.layer.zPosition = 10
        button.backgroundColor = UIColor(white: 1, alpha: 0)
        button.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.titleLabel?.textAlignment = .left
        button.addTarget(self, action: #selector(changeToMyStickers), for: .touchUpInside)
        return button
    }()
    
    private lazy var createStickerButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(createSticker), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.backgroundColor = UIColor(white: 1, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Create Sticker", for: .normal)
        button.layer.cornerRadius = 14
        button.isUserInteractionEnabled = true
        return button
    }()
    
    private var _didFinishPicking: ((Sticker, Bool) -> Void)?
    public func didFinishPicking(completion: @escaping (_ items: Sticker, _ cancelled: Bool) -> Void) {
        _didFinishPicking = completion
    }
        
    var stickers: [Sticker]?
    
    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.init(white: 0, alpha: 0.85)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelSelected))
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        self.navigationController?.navigationBar.height(CGFloat(50))
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(white: 0, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0, alpha: 1)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        layout.itemSize = CGSize(width: (view.frame.width - 2) / 3, height: (view.frame.width - 2) / 3 )
        layout.minimumLineSpacing = CGFloat(0)

        let navbarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 145, width: UIScreen.main.bounds.width, height: (550 - 20 - navbarHeight) - 145), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(StickerPhotoGridCell.self, forCellWithReuseIdentifier: StickerPhotoGridCell.cellId)
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = false
        collectionView?.keyboardDismissMode = .onDrag
        self.view.insertSubview(collectionView, at: 5)
        
        groupStickersButton.frame = CGRect(x: UIScreen.main.bounds.width/2 - 125, y: 10, width: 120, height: 40)
        self.view.insertSubview(groupStickersButton, at: 10)

        myStickersButton.frame = CGRect(x: UIScreen.main.bounds.width/2 + 5, y: 10, width: 120, height: 40)
        self.view.insertSubview(myStickersButton, at: 10)
        
        self.view.addSubview(createStickerButton)
        createStickerButton.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: 65, paddingLeft: 50, paddingRight: 50, height: 50)

        self.view.insertSubview(selectGroup, at: 10)
        selectGroup.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: UIScreen.main.bounds.height/2, paddingLeft: 90, paddingRight: 90, height: 50)
        
        self.view.insertSubview(noGroupLabel, at: 10)
        noGroupLabel.anchor(left: self.view.leftAnchor, bottom: selectGroup.topAnchor, right: self.view.rightAnchor, paddingLeft: 50, paddingBottom: 10, paddingRight: 50, height: 40)
        
        self.loadData()
        
        self.createStickerButton.addTarget(self, action: #selector(self.createStickerButtonDown), for: .touchDown)
        self.createStickerButton.addTarget(self, action: #selector(self.createStickerButtonDown), for: .touchDragInside)
        self.createStickerButton.addTarget(self, action: #selector(self.createStickerButtonUp), for: .touchDragExit)
        self.createStickerButton.addTarget(self, action: #selector(self.createStickerButtonUp), for: .touchCancel)
        self.createStickerButton.addTarget(self, action: #selector(self.createStickerButtonUp), for: .touchUpInside)
        
        self.selectGroup.addTarget(self, action: #selector(self.selectGroupDown), for: .touchDown)
        self.selectGroup.addTarget(self, action: #selector(self.selectGroupDown), for: .touchDragInside)
        self.selectGroup.addTarget(self, action: #selector(self.selectGroupUp), for: .touchDragExit)
        self.selectGroup.addTarget(self, action: #selector(self.selectGroupUp), for: .touchCancel)
        self.selectGroup.addTarget(self, action: #selector(self.selectGroupUp), for: .touchUpInside)
    }
    
    func loadData() {
        // retrieve the stickers
        self.stickers = []
        if self.isGroupStickers {
            if self.group != nil {
                Database.database().fetchGroupStickers(groupId: group!.groupId, completion: { (stickers) in
                    self.stickers = stickers
                    self.noGroupLabel.isHidden = true
                    self.selectGroup.isHidden = true
                    self.collectionView.isHidden = false
                    self.collectionView?.reloadData()
                }) { (_) in }
            }
            else {
                noGroupLabel.isHidden = false
                selectGroup.isHidden = false
                self.collectionView.isHidden = true
            }
        }
        else {
            Database.database().fetchUserStickers( completion: { (stickers) in
                self.stickers = stickers
                self.noGroupLabel.isHidden = true
                self.selectGroup.isHidden = true
                self.collectionView.isHidden = false
                self.collectionView?.reloadData()
            }) { (_) in }
        }
    }
    
    @objc private func createSticker() {
        if group == nil {
            let selectGroupController = SelectGroupController()
            selectGroupController.didFinishPicking { [unowned selectGroupController] group, cancelled in
                if !cancelled {
                    self.group = group
                }
                self.goToCreateSticker()
            }
            selectGroupController.for_sticker = true
            let navController = UINavigationController(rootViewController: selectGroupController)
            navController.modalPresentationStyle = .overFullScreen
            self.present(navController, animated: true, completion: nil)
        }
        else {
            self.goToCreateSticker()
        }
    }
    
    func goToCreateSticker() {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
            self.myStickersButton.alpha = 0
            self.groupStickersButton.alpha = 0
            self.createStickerButton.alpha = 0
            self.collectionView.alpha = 0
            self.navigationItem.leftBarButtonItem = nil
        }, completion: nil)
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { timer in
            let createStickerController = CreateStickerController()
            createStickerController.backgroundImage = self.backgroundImage
            createStickerController.group = self.group
            createStickerController.didFinishPicking { [unowned createStickerController] sticker, cancelled in
                if cancelled {
                    self.dismiss(animated: true, completion: {})
                }
                else {
                    self.dismiss(animated: true, completion: {
                        self._didFinishPicking?(sticker, false)
                    })
                }
            }
            let navController = UINavigationController(rootViewController: createStickerController)
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated: false, completion: nil)
        }
    }
    
    @objc private func cancelSelected() {
        self.dismiss(animated: true, completion: {})
    }
    
    @objc private func selectAGroup() {
        let selectGroupController = SelectGroupController()
        selectGroupController.didFinishPicking { [unowned selectGroupController] group, cancelled in
            if !cancelled {
                self.group = group
                self.loadData()
            }
        }
        selectGroupController.for_sticker = true
        let navController = UINavigationController(rootViewController: selectGroupController)
        navController.modalPresentationStyle = .overFullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if stickers != nil {
            return stickers!.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerPhotoGridCell.cellId, for: indexPath) as! StickerPhotoGridCell
        cell.sticker = stickers?[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.dismiss(animated: true, completion: {
            let cell = self.collectionView.cellForItem(at: indexPath) as! StickerPhotoGridCell
            guard let sticker = cell.sticker else { return }
            self._didFinishPicking?(sticker, false)
        })
    }
    
    @objc private func changeToGroupStickers() {
        self.isGroupStickers = true
        self.groupStickersButton.setTitleColor(UIColor(white: 1, alpha: 1), for: .normal)
        self.myStickersButton.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
        self.loadData()
    }
    
    @objc private func changeToMyStickers() {
        self.isGroupStickers = false
        self.groupStickersButton.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
        self.myStickersButton.setTitleColor(UIColor(white: 1, alpha: 1), for: .normal)
        self.loadData()
    }
    
    @objc private func createStickerButtonDown(){
        self.createStickerButton.animateButtonDown()
    }
    
    @objc private func createStickerButtonUp(){
        self.createStickerButton.animateButtonUp()
    }
    
    @objc private func selectGroupDown(){
        self.selectGroup.animateButtonDown()
    }
    
    @objc private func selectGroupUp(){
        self.selectGroup.animateButtonUp()
    }
    
    
}

extension GroupStickersController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
}
