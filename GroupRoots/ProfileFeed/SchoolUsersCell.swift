//
//  SchoolUsersCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 12/24/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol SchoolUsersCellDelegate {
    func didTapUser(user: User)
}

class SchoolUsersCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var schoolMembers: [User]? {
        didSet {
            configureGroupHeader()
        }
    }
    
    var orderedSchoolMembers = [User]()
    
    // uid to number of groups
    var school_members_group_count: [String: Int]? {
        didSet {
            configureGroupHeader()
        }
    }
    
    // group_id to is_following
    var is_following_groups_in_school: [String: Bool]? {
        didSet {
            configureGroupHeader()
        }
    }
    
    var delegate: SchoolUsersCellDelegate?
    
    var finishedLoading = false
    
    var headerCollectionView: UICollectionView!
    
    private let schoolMembersLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.textColor = .darkGray
        label.text = "People in your school"
        return label
    }()
    
    static var cellId = "schoolGroupCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.backgroundColor = UIColor(white: 0, alpha: 0)
        self.schoolMembers = nil
    }
    
    private func sharedInit() {
        self.backgroundColor = UIColor(white: 0, alpha: 0)
        
        let header_layout = UICollectionViewFlowLayout()
        header_layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        
        addSubview(schoolMembersLabel)
        schoolMembersLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 5, paddingLeft: 20)

        headerCollectionView = UICollectionView(frame: CGRect(x: 0, y: 30, width: UIScreen.main.bounds.width, height: 155), collectionViewLayout: header_layout)
        headerCollectionView.delegate = self
        headerCollectionView.dataSource = self
        headerCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        headerCollectionView.register(GroupProfileHeaderCell.self, forCellWithReuseIdentifier: GroupProfileHeaderCell.cellId)
        headerCollectionView.register(SchoolUserCell.self, forCellWithReuseIdentifier: SchoolUserCell.cellId)
        headerCollectionView.showsHorizontalScrollIndicator = false
        headerCollectionView.isUserInteractionEnabled = true
        headerCollectionView.allowsSelection = true
        headerCollectionView.backgroundColor = UIColor.clear
        headerCollectionView.showsHorizontalScrollIndicator = false
        insertSubview(headerCollectionView, at: 5)
        
//        let separatorViewBottom = UIView()
//        separatorViewBottom.backgroundColor = UIColor(white: 0, alpha: 0.2)
//        addSubview(separatorViewBottom)
//        separatorViewBottom.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 10, paddingRight: 10, height: 0.5)
    }
    
    public func configureGroupHeader(){
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard var schoolMembers = self.schoolMembers else { return }
        guard let school_members_group_count = school_members_group_count else { return }
        guard let is_following_groups_in_school = is_following_groups_in_school else { return }
        
        self.orderedSchoolMembers = self.schoolMembers!
        
        // order the members by number of groups
        // randomize the first 10
        // make the user be in position 1 of array if array length is > 1
        // else make user be in position 0
//
//        schoolMembers.sort(by: { (u1, u2) -> Bool in
//            return school_members_group_count[u1.uid]! > school_members_group_count[u2.uid]!
//        })
//
//        // get array with just the first 10
//        var firstAfterSort = schoolMembers.prefix(6)
//
//        firstAfterSort.shuffle()
//
//        self.orderedSchoolMembers = firstAfterSort + Array(schoolMembers.dropFirst(6))
//
//        // put current user to top of the list
//        var indexToSwap = -1
//        for (i,user) in self.orderedSchoolMembers.enumerated() {
//            if user.uid == currentLoggedInUserId {
//                indexToSwap = i
//                break
//            }
//        }
//        if indexToSwap > -1 && self.orderedSchoolMembers.count > 1 {
//            self.orderedSchoolMembers.swapAt(1, indexToSwap)
//        }
//
        
        self.finishedLoading = true
        self.headerCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !finishedLoading {
            return 0
        }
        return orderedSchoolMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: SchoolUserCell.cellId, for: indexPath) as! SchoolUserCell
        if indexPath.item < orderedSchoolMembers.count {
            cell.user = orderedSchoolMembers[indexPath.item]
            cell.num_groups = school_members_group_count?[cell.user?.uid ?? ""]
            cell.is_following = is_following_groups_in_school?[cell.user?.uid ?? ""]
        }
        cell.group_has_profile_image = true
        cell.layer.backgroundColor = UIColor.clear.cgColor
        
//        cell.layer.shadowColor = UIColor.black.cgColor
//        cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
//        cell.layer.shadowOpacity = 0.2
//        cell.layer.shadowRadius = 2.0
        
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 5
        cell.layer.borderColor = UIColor.init(white: 0.9, alpha: 1).cgColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didTapUser(user: orderedSchoolMembers[indexPath.row])
    }
}

extension SchoolUsersCell: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 7
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 145)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
    }
}

