//
//  FeedGroupPageCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 5/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

class FeedGroupPageCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    // don't need comments, views, etc because its just the grid view of the posts
    // [have another thing like FeedCell that replaces FeedGroupPageCell when go to full view post mode]
    
    var collectionView: UICollectionView!
    static var cellId = "feedGroupPageCellId"
    
    // only contains four group posts
    var groupPosts: [GroupPost]? {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        groupPosts = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    func setupViews() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.minimumLineSpacing = CGFloat(0)

        collectionView = UICollectionView(frame: CGRect(x: 0, y: 180, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 180), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(FeedGroupPostCell.self, forCellWithReuseIdentifier: FeedGroupPostCell.cellId)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        self.addSubview(collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.groupPosts?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedGroupPostCell.cellId, for: indexPath) as! FeedGroupPostCell
        cell.groupPost = self.groupPosts?[indexPath.row]
        return cell
    }
    
}

extension FeedGroupPageCell: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.frame.width - 2) / 2
        return CGSize(width: width, height: width)
    }
}
