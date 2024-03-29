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
    func didTapPostCell(groupPostId: String)
    func didView(groupPost: GroupPost)
}

class FeedGroupPageCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    var collectionView: UICollectionView!
    static var cellId = "feedGroupPageCellId"
    var delegate: FeedGroupPageCellDelegate?
    
    // only contains four group posts
    var groupPosts: [GroupPost]? {
        didSet {
            loadCollectionView()
        }
    }
    
    var viewedPosts: [String: Bool]? {
        didSet {
            loadCollectionView()
        }
    }
    
    var lastCommentForPosts: [String: Comment]? {
        didSet {
            loadCollectionView()
        }
    }
    
    func loadCollectionView() {
        guard groupPosts != nil else { return }
        guard viewedPosts != nil else { return }
        guard lastCommentForPosts != nil else { return }
        DispatchQueue.main.async{
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
        layout.itemSize = CGSize(width: (self.frame.width - 32) / 2, height: (self.frame.width - 32) / 2)
        layout.minimumLineSpacing = CGFloat(0)

        // obviously not good cuz would be different on different screens but just for visual purposes
        collectionView = UICollectionView(frame: CGRect(x: 15, y: 0, width: self.frame.width - 30, height: self.frame.height), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(FeedGroupPostCell.self, forCellWithReuseIdentifier: FeedGroupPostCell.cellId)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
//        collectionView?.semanticContentAttribute = .forceRightToLeft
        contentView.addSubview(collectionView)        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedGroupPostCell.cellId, for: indexPath) as! FeedGroupPostCell
        
        if indexPath.row < self.groupPosts?.count ?? 0 {
            cell.tag = indexPath.row
            cell.groupPost = self.groupPosts?[indexPath.row]
            
            if cell.groupPost != nil {
                let id = cell.groupPost!.id
                if let lastComment = self.lastCommentForPosts![id] {
                    cell.lastComment = lastComment
                }
            }
            if cell.groupPost != nil {
                cell.viewedPost = self.viewedPosts?[cell.groupPost!.id]
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.cellForItem(at: indexPath) is FeedGroupPostCell {
            let cell = collectionView.cellForItem(at: indexPath) as! FeedGroupPostCell
            if cell.groupPost?.id != "" {
                delegate?.didTapPostCell(groupPostId: cell.groupPost!.id)
                delegate?.didView(groupPost: cell.groupPost!)
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
