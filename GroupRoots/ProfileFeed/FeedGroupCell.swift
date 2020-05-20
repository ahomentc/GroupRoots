//
//  FeedGroupCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 5/17/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

protocol FeedGroupCellDelegate {
    func didTapComment(groupPost: GroupPost)
    func didTapGroup(group: Group)
    func didTapUser(user: User)
    func didTapOptions(groupPost: GroupPost)
    func didSelectUser(selectedUser: User)
    func showMoreMembers(group: Group)
    func didView(groupPost: GroupPost)
    func showViewers(viewers: [User], viewsCount: Int)
    func requestPlay(for_lower cell1: FeedPostCell, for_upper cell2: MyCell)
}

class FeedGroupCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    var firstCommentForPosts = [String: Comment]()
    var viewersForPosts = [String: [User]]()
    var numViewsForPost = [String: Int]()
    var numCommentsForPosts = [String: Int]()
    
    var groupPosts: [GroupPost]? {
        didSet {
            configureHeader()
            self.reloadGroupData()
        }
    }
    
    var groupMembers: [User]? {
        didSet {
            configureHeader()
        }
    }
    
    var usingCachedData: Bool?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        groupMembers = nil
        groupPosts = nil
        groupPostsTotalViewers = nil
        checkedIfCommentExists = false
        groupPostsFirstComment = nil
        groupPostsNumComments = nil
    }
    
    // this might be bad but to clarify. FeedController sets groupPostsViewers for this cell. That in turn sets viewersForPosts
    var groupPostsViewers: [String: [User]]? { // key is the postId
        didSet{
            guard let groupPostsViewers = groupPostsViewers else { return }
            viewersForPosts = groupPostsViewers
        }
    }
    
    var groupPostsTotalViewers: [String: Int]? { // key is the postId
        didSet {
            guard let groupPostsTotalViewers = groupPostsTotalViewers else { return }
            numViewsForPost = groupPostsTotalViewers
            self.reloadGroupData()
        }
    }
    
    var checkedIfCommentExists = false
    var groupPostsFirstComment: [String: Comment]? { // key is the postId
        didSet {
            self.reloadGroupData()
        }
    }
    
    var groupPostsNumComments: [String: Int]? { // key is the postId
        didSet {
            self.reloadGroupData()
        }
    }
        
    var maxDistanceScrolled = CGFloat(0)
    var numPicsScrolled = 1

    var collectionView: UICollectionView!
    
    let header = FeedPostCellHeader()
    var delegate: FeedGroupCellDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    func reloadGroupData(){
        guard let groupPosts = groupPosts else { return }
        guard groupPostsNumComments != nil else { return }
                
        self.collectionView.reloadData(); // this is causing or uncovering some problems where video is playing over itself
        self.collectionView.layoutIfNeeded()
        
        if groupPosts.count > 0 { // need to check if in group, else viewers will be nil and always return
            Database.database().isInGroup(groupId: groupPosts[0].group.groupId, completion: { (inGroup) in
                if inGroup{
                    DispatchQueue.main.async{
                        self.collectionView.reloadData()
                        self.collectionView.layoutIfNeeded()
                    }
                }
                else {
                    DispatchQueue.main.async{
                        self.collectionView.reloadData();
                        self.collectionView.layoutIfNeeded()
                    }
                }
            }) { (err) in return }
        }
        else {
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
        }
    }
    
    func setupViews() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        layout.minimumLineSpacing = CGFloat(0)
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView?.register(FeedPostCell.self, forCellWithReuseIdentifier: FeedPostCell.cellId)
        collectionView?.register(FeedGroupPageCell.self, forCellWithReuseIdentifier: FeedGroupPageCell.cellId)
        collectionView?.register(EmptyFeedPostCell.self, forCellWithReuseIdentifier: EmptyFeedPostCell.cellId)
        collectionView?.register(MembersCell.self, forCellWithReuseIdentifier: MembersCell.cellId)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        self.addSubview(collectionView)

        addSubview(header)
        header.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 25, paddingLeft: 5, paddingRight: UIScreen.main.bounds.width/2)
        header.delegate = self
    }
    
    func configureHeader() {
        header.groupMembers = []
        header.group = nil
        if groupPosts?.count == 0 { return }
        guard let groupPost = groupPosts?[0] else { return }
        header.group = groupPost.group
        guard let groupMembers = groupMembers else { return }
        if groupMembers.count == 0 { return }
        header.groupMembers = groupMembers
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if groupPosts?.count ?? 0 > 0 {
            return Int(ceil(Double(groupPosts?.count ?? 0)/4))
        }
        else {
            return 0
        }
    }
    
    // when click on a picture box, take to LargeImageViewController?
    // Thing is that it'd be nice to just scroll down to get to next post instead of clicking back and then scrolling down
    // so maybe just have an X instead to exit full screen view and don't use LargeImageViewController
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // only show 4 pictures in page
        let startPos = indexPath.row * 4
        var endPos = indexPath.row * 4 + 4
        
        let groupPostsCount = (groupPosts ?? []).count
        if endPos > groupPostsCount {
            endPos = groupPostsCount
        }
        let slicedArr = (groupPosts ?? [])[startPos..<endPos]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedGroupPageCell.cellId, for: indexPath) as! FeedGroupPageCell
        cell.groupPosts = Array(slicedArr)
        return cell
    }
    
    //MARK: - InnerPostCellDelegate
    func didTapComment(groupPost: GroupPost) {
        delegate?.didTapComment(groupPost: groupPost)
    }
    
    func didTapUser(user: User) {
        delegate?.didTapUser(user: user)
    }
    
    func didTapGroup(group: Group) {
        delegate?.didTapGroup(group: group)
    }
    
    func didTapOptions(groupPost: GroupPost) {
        delegate?.didTapOptions(groupPost: groupPost)
    }
    
    func didView(groupPost: GroupPost) {
        delegate?.didView(groupPost: groupPost)
    }
    
    func didTapViewers(groupPost: GroupPost){
        guard let viewers = viewersForPosts[groupPost.id] else { return }
        guard let numViews = numViewsForPost[groupPost.id] else { return }
        delegate?.showViewers(viewers: viewers, viewsCount: numViews)
    }
    
    //MARK: - FeedMembersCellDelegate
    func selectedMember(selectedUser: User) {
        delegate?.didSelectUser(selectedUser: selectedUser)
    }
    
    func showMoreMembers() {
        guard let group = groupPosts?[0].group else { return }
        delegate?.showMoreMembers(group: group)
    }
    
}

extension FeedGroupCell: UICollectionViewDelegateFlowLayout {
    private func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlowLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}

//MARK: - HomePostCellHeaderDelegate

extension FeedGroupCell: FeedPostCellHeaderDelegate {
    
    func didTapGroup() {
        guard let group = groupPosts?[0].group else { return }
        delegate?.didTapGroup(group: group)
    }
    
    func didTapOptions() {
        guard let groupPost = groupPosts?[0] else { return }
        delegate?.didTapOptions(groupPost: groupPost)
    }
    
    func goToFirstImage() {
        collectionView.scrollToItem(at: IndexPath(item: 1, section: 0), at: .centeredHorizontally, animated: true)
    }
}

