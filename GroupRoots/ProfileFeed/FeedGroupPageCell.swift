//
//  FeedGroupPageCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 5/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

protocol FeedGroupPageCellDelegate {
    func didTapPostCell(for_cell cell: FeedGroupPageCell, cell_number: Int)
    func didView(groupPost: GroupPost)
}

class FeedGroupPageCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    // don't need comments, views, etc because its just the grid view of the posts
    // [have another thing like FeedCell that replaces FeedGroupPageCell when go to full view post mode]
    
    var collectionView: UICollectionView!
    static var cellId = "feedGroupPageCellId"
    
    var delegate: FeedGroupPageCellDelegate?
    
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

        // obviously not good cuz would be different on different screens but just for visual purposes
        collectionView = UICollectionView(frame: CGRect(x: 15, y: 120, width: self.frame.width - 30, height: self.frame.height), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(FeedGroupPostCell.self, forCellWithReuseIdentifier: FeedGroupPostCell.cellId)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        self.addSubview(collectionView)        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedGroupPostCell.cellId, for: indexPath) as! FeedGroupPostCell
        if indexPath.row < self.groupPosts?.count ?? 0{
            cell.groupPost = self.groupPosts?[indexPath.row]
            cell.tag = indexPath.row
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row < self.groupPosts?.count ?? 0{
            delegate?.didTapPostCell(for_cell: self, cell_number: indexPath.row)
            
            let post = groupPosts?[indexPath.row]
            if post != nil {
                delegate?.didView(groupPost: post!)
            }
        }
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
        let width = (self.frame.width - 32) / 2
        return CGSize(width: width, height: width * 1)
    }
}
