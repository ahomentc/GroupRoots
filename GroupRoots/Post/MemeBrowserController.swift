//
//  MemeBrowserController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/23/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit

class MemeBrowserController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private var _didFinishPicking: ((UIImage, Bool) -> Void)?
    public func didFinishPicking(completion: @escaping (_ items: UIImage, _ cancelled: Bool) -> Void) {
        _didFinishPicking = completion
    }
        
    var memes: [Meme]?
    var innerDict: NSArray?
    
    private let searchBar: UISearchBar = {
            let sb = UISearchBar()
            sb.placeholder = "Search"
            sb.autocorrectionType = .no
            sb.autocapitalizationType = .none
            sb.backgroundImage = UIImage()
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
            return sb
    }()
    
    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        self.navigationItem.title = "Popular Memes"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelSelected))
        self.navigationItem.leftBarButtonItem?.tintColor = .black
        self.navigationController?.navigationBar.shadowImage = UIColor.white.as1ptImage()
        self.navigationController?.navigationBar.height(CGFloat(20))
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(white: 1, alpha: 1)
        self.navigationController?.navigationBar.barTintColor = UIColor.init(white: 1, alpha: 1)
        
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
        
        searchBar.frame = CGRect(x: 10, y: 5, width: UIScreen.main.bounds.width - 20, height: 44)
        searchBar.layer.zPosition = 2
        self.view.insertSubview(searchBar, at: 4)
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        layout.itemSize = CGSize(width: (view.frame.width - 2) / 3, height: (view.frame.width - 2) / 3 )
        layout.minimumLineSpacing = CGFloat(0)

        collectionView = UICollectionView(frame: CGRect(x: 0, y: 60, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 100), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(MemePhotoGridCell.self, forCellWithReuseIdentifier: MemePhotoGridCell.cellId)
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = false
        collectionView?.keyboardDismissMode = .onDrag
        self.view.insertSubview(collectionView, at: 5)
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
