//
//  MemeBrowserController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/23/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import YPImagePicker

class MemeBrowserController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private var _didFinishPicking: ((UIImage, Bool) -> Void)?
    public func didFinishPicking(completion: @escaping (_ items: UIImage, _ cancelled: Bool) -> Void) {
        _didFinishPicking = completion
    }
    
    var group: Group?
        
    var memes: [Meme]?
    var innerDict: NSArray?
    
    var popularMemesSelected = true
    
    private lazy var groupMemesButton: UIButton = {
        let button = UIButton()
        button.setTitle("Group Memes", for: .normal)
        button.layer.zPosition = 10
        button.backgroundColor = UIColor(white: 1, alpha: 0)
        button.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.titleLabel?.textAlignment = .left
        button.addTarget(self, action: #selector(changeToGroupMemes), for: .touchUpInside)
        return button
    }()
    
    private lazy var popularMemesButton: UIButton = {
        let button = UIButton()
        button.layer.zPosition = 4;
        button.backgroundColor = UIColor(white: 1, alpha: 0)
        button.setTitleColor(UIColor(white: 1, alpha: 1), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Popular Memes", for: .normal)
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(changeToPopularMemes), for: .touchUpInside)
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
    
    private lazy var uploadMeme: UIButton = {
        let button = UIButton()
        button.layer.zPosition = 4;
        button.backgroundColor = UIColor(white: 1, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Upload Template", for: .normal)
        button.layer.cornerRadius = 14
        button.isUserInteractionEnabled = true
        button.isHidden = true
        button.addTarget(self, action: #selector(usePicker), for: .touchUpInside)
        return button
    }()
    
    private lazy var blankMeme: UIButton = {
        let button = UIButton()
        button.layer.zPosition = 4;
        button.backgroundColor = UIColor(white: 1, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Create Template", for: .normal)
        button.layer.cornerRadius = 14
        button.isUserInteractionEnabled = true
        button.isHidden = true
        button.addTarget(self, action: #selector(selectBlank), for: .touchUpInside)
        return button
    }()
    
    // popup message saying that the template for memes you create and post to your group will be saved
    
    // [Upload Meme Template]
    // [Create blank Meme]
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search"
        sb.autocorrectionType = .no
        sb.tintColor = .white
        sb.autocapitalizationType = .none
        sb.backgroundImage = UIImage()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.init(white: 0.3, alpha: 1)
        return sb
    }()
    
    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
//        self.navigationItem.title = "Popular Memes"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelSelected))
        self.navigationItem.leftBarButtonItem?.tintColor = .white
        self.navigationController?.navigationBar.shadowImage = UIColor.black.as1ptImage()
        self.navigationController?.navigationBar.height(CGFloat(20))
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(white: 0, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 0, alpha: 1)
        
        self.loadData()
        
        self.view.insertSubview(selectGroup, at: 10)
        selectGroup.anchor(top: self.view.topAnchor, left: self.view.leftAnchor, right: self.view.rightAnchor, paddingTop: UIScreen.main.bounds.height/2, paddingLeft: 90, paddingRight: 90, height: 50)
        
        self.view.insertSubview(noGroupLabel, at: 10)
        noGroupLabel.anchor(left: self.view.leftAnchor, bottom: selectGroup.topAnchor, right: self.view.rightAnchor, paddingLeft: 50, paddingBottom: 10, paddingRight: 50, height: 40)
        
        searchBar.frame = CGRect(x: 10, y: 65, width: UIScreen.main.bounds.width - 20, height: 44)
        searchBar.layer.zPosition = 2
        self.view.insertSubview(searchBar, at: 4)
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        layout.itemSize = CGSize(width: (view.frame.width - 2) / 3, height: (view.frame.width - 2) / 3 )
        layout.minimumLineSpacing = CGFloat(0)

        collectionView = UICollectionView(frame: CGRect(x: 0, y: 130, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 170), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(MemePhotoGridCell.self, forCellWithReuseIdentifier: MemePhotoGridCell.cellId)
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = false
        collectionView?.keyboardDismissMode = .onDrag
        self.view.insertSubview(collectionView, at: 5)
        
        popularMemesButton.frame = CGRect(x: UIScreen.main.bounds.width/2 - 135, y: 5, width: 120, height: 40)
        self.view.insertSubview(popularMemesButton, at: 10)

        groupMemesButton.frame = CGRect(x: UIScreen.main.bounds.width/2 + 15, y: 5, width: 120, height: 40)
        self.view.insertSubview(groupMemesButton, at: 10)
        
        uploadMeme.frame = CGRect(x: UIScreen.main.bounds.width/2 - 170, y: 60, width: 160, height: 50)
        self.view.insertSubview(uploadMeme, at: 10)

        blankMeme.frame = CGRect(x: UIScreen.main.bounds.width/2 + 10, y: 60, width: 160, height: 50)
        self.view.insertSubview(blankMeme, at: 10)
        
        self.uploadMeme.addTarget(self, action: #selector(self.uploadMemeDown), for: .touchDown)
        self.uploadMeme.addTarget(self, action: #selector(self.uploadMemeDown), for: .touchDragInside)
        self.uploadMeme.addTarget(self, action: #selector(self.uploadMemeUp), for: .touchDragExit)
        self.uploadMeme.addTarget(self, action: #selector(self.uploadMemeUp), for: .touchCancel)
        self.uploadMeme.addTarget(self, action: #selector(self.uploadMemeUp), for: .touchUpInside)
        
        self.blankMeme.addTarget(self, action: #selector(self.blankMemeDown), for: .touchDown)
        self.blankMeme.addTarget(self, action: #selector(self.blankMemeDown), for: .touchDragInside)
        self.blankMeme.addTarget(self, action: #selector(self.blankMemeUp), for: .touchDragExit)
        self.blankMeme.addTarget(self, action: #selector(self.blankMemeUp), for: .touchCancel)
        self.blankMeme.addTarget(self, action: #selector(self.blankMemeUp), for: .touchUpInside)
    }
    
    @objc private func uploadMemeDown(){
        self.uploadMeme.animateButtonDown()
    }
    
    @objc private func uploadMemeUp(){
        self.uploadMeme.animateButtonUp()
    }
    
    @objc private func blankMemeDown(){
        self.blankMeme.animateButtonDown()
    }
    
    @objc private func blankMemeUp(){
        self.blankMeme.animateButtonUp()
    }
    
    func loadData() {
        self.memes = []
        if popularMemesSelected {
            if self.collectionView != nil {
                self.collectionView.isHidden = false
            }
            self.noGroupLabel.isHidden = true
            self.selectGroup.isHidden = true
            
            
            if let url = URL(string: "https://api.imgflip.com/get_memes") {
               URLSession.shared.dataTask(with: url) { data, response, error in
                  if let data = data {
                     if let jsonString = String(data: data, encoding: .utf8) {
                        let outerDict = self.convertToDictionary(text: jsonString)!["data"]
                        if let theJSONData = try? JSONSerialization.data(
                            withJSONObject: outerDict as Any,
                            options: []) {
                            let innerJsonDictString = String(data: theJSONData,
                                                       encoding: .ascii)
                            let innerDict = self.convertToDictionary(text: innerJsonDictString!)!["memes"] as! NSArray
                            self.innerDict = innerDict
                            var tempMemes = [Meme]()
                            for (i, _) in innerDict.enumerated() {
                                let memeItem = innerDict[i] as! NSDictionary
                                let meme = Meme(dictionary: memeItem as! [String : Any])
                                tempMemes.append(meme)
                            }
                            self.memes = tempMemes
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                        }
                     }
                   }
               }.resume()
            }
        }
        else {
            if self.group != nil {
                Database.database().fetchGroupMemeTemplates(groupId: group!.groupId, completion: { (memeTemplates) in
                    var tempMemes = [Meme]()
                    for meme in memeTemplates {
                        let values = ["url": meme.imageUrl] as [String : Any]
                        let madeMeme = Meme(dictionary: values)
                        tempMemes.append(madeMeme)
                    }
                    self.memes = tempMemes
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                    
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
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
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
    
    @objc func changeToPopularMemes() {
        self.popularMemesSelected = true
        self.popularMemesButton.setTitleColor(UIColor(white: 1, alpha: 1), for: .normal)
        self.groupMemesButton.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
        self.uploadMeme.isHidden = true
        self.blankMeme.isHidden = true
        self.searchBar.isHidden = false
        self.loadData()
    }
    
    @objc func changeToGroupMemes() {
        self.popularMemesSelected = false
        self.groupMemesButton.setTitleColor(UIColor(white: 1, alpha: 1), for: .normal)
        self.popularMemesButton.setTitleColor(UIColor(white: 0.6, alpha: 1), for: .normal)
        self.uploadMeme.isHidden = false
        self.blankMeme.isHidden = false
        self.searchBar.isHidden = true
        self.loadData()
    }
    
    @objc private func cancelSelected() {
        self.dismiss(animated: true, completion: {})
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if memes != nil {
            return memes!.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemePhotoGridCell.cellId, for: indexPath) as! MemePhotoGridCell
        cell.memeUrl = memes?[indexPath.row].url
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.dismiss(animated: true, completion: {
            let cell = self.collectionView.cellForItem(at: indexPath) as! MemePhotoGridCell
            guard let image = cell.photoImageView.image else { return }
            self._didFinishPicking?(image, false)
        })
    }
    
    @objc func selectBlank() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            self.dismiss(animated: true, completion: {
                self._didFinishPicking?(CustomImageView.imageWithColor(color: .white), true)
            })
        }
    }
    
    @objc private func usePicker() {
        var config = YPImagePickerConfiguration()
        config.library.isSquareByDefault = false
        config.shouldSaveNewPicturesToAlbum = false
        config.library.mediaType = .photoAndVideo
        config.showsPhotoFilters = false
        config.hidesStatusBar = false
        config.startOnScreen = YPPickerScreen.library
        config.targetImageSize = .cappedTo(size: 600)
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
                    Database.database().createGroupMemeTemplate(withImage: photo.image, groupId: self.group?.groupId, completion: { (memeTemplateId) in
                        self.dismiss(animated: true, completion: {
                            self.loadData()
                        })
                    })
                case .video( _):
                    return
                }
            }
        }
        present(picker, animated: true, completion: nil)
    }
}


extension MemeBrowserController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let innerDict = innerDict else { return }
        if searchText.isEmpty {
            self.memes = []
            var tempMemes = [Meme]()
            for (i, _) in innerDict.enumerated() {
                let memeItem = innerDict[i] as! NSDictionary
                let meme = Meme(dictionary: memeItem as! [String : Any])
                tempMemes.append(meme)
            }
            self.memes = tempMemes
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } else {
            print(searchText)
            self.memes = []
            var tempMemes = [Meme]()
            for (i, _) in innerDict.enumerated() {
                let memeItem = innerDict[i] as! NSDictionary
                let meme = Meme(dictionary: memeItem as! [String : Any])
                if meme.name.lowercased().contains(searchText.lowercased()) {
                    tempMemes.append(meme)
                        print("---")
                        print(searchText)
                        print(meme.name)
                        print("---")
                }
            }
            self.memes = tempMemes
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func InviteToGroupWhenCreateController(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension MemeBrowserController: UICollectionViewDelegateFlowLayout {

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
