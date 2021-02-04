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
    func didTapFirstFollow()
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
    
    var hideIfNoGroups: Bool? {
        didSet {
            configureGroupHeader()
        }
    }
    
    var schoolTemplateIsActive: Bool? {
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
        headerCollectionView?.register(UnlockSchoolUserCell.self, forCellWithReuseIdentifier: UnlockSchoolUserCell.cellId)
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
        guard self.schoolMembers != nil else { return }
        guard school_members_group_count != nil else { return }
        guard is_following_groups_in_school != nil else { return }
        guard hideIfNoGroups != nil else { return }
        guard schoolTemplateIsActive != nil else { return }
        
        self.orderedSchoolMembers = self.schoolMembers!
        
        self.finishedLoading = true
        self.headerCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !finishedLoading {
            return 0
        }
        
        let currentLoggedInUserId = Auth.auth().currentUser?.uid
        if currentLoggedInUserId != nil && self.school_members_group_count != nil && self.hideIfNoGroups != nil && self.schoolTemplateIsActive != nil
        {
            let num_groups_for_user = self.school_members_group_count![currentLoggedInUserId!]
            if (num_groups_for_user == 0 || num_groups_for_user == nil) && self.hideIfNoGroups! && self.schoolTemplateIsActive!{
                return 11
            }
            else if (num_groups_for_user == 0 || num_groups_for_user == nil) && self.hideIfNoGroups! && orderedSchoolMembers.count > 11 {
                return 11
            }
        }
        return orderedSchoolMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let currentLoggedInUserId = Auth.auth().currentUser?.uid
        if currentLoggedInUserId != nil && self.school_members_group_count != nil && self.hideIfNoGroups != nil {
            let num_groups_for_user = self.school_members_group_count![currentLoggedInUserId!]
            if (num_groups_for_user == 0 || num_groups_for_user == nil) && self.hideIfNoGroups! && indexPath.item == 10 {
                let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: UnlockSchoolUserCell.cellId, for: indexPath) as! UnlockSchoolUserCell
                cell.layer.backgroundColor = UIColor.clear.cgColor
//                cell.layer.borderWidth = 1
//                cell.layer.cornerRadius = 5
//                cell.layer.borderColor = UIColor.init(white: 0.9, alpha: 1).cgColor
                return cell
            }
        }
        
        let cell = headerCollectionView.dequeueReusableCell(withReuseIdentifier: SchoolUserCell.cellId, for: indexPath) as! SchoolUserCell
        if indexPath.item < orderedSchoolMembers.count {
            cell.user = orderedSchoolMembers[indexPath.item]
            cell.num_groups = school_members_group_count?[cell.user?.uid ?? ""]
            cell.is_following = is_following_groups_in_school?[cell.user?.uid ?? ""]
        }
        cell.group_has_profile_image = true
        cell.layer.backgroundColor = UIColor.clear.cgColor
        
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 5
        cell.layer.borderColor = UIColor.init(white: 0.9, alpha: 1).cgColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentLoggedInUserId = Auth.auth().currentUser?.uid
        if currentLoggedInUserId != nil && self.school_members_group_count != nil && self.hideIfNoGroups != nil {
            let num_groups_for_user = self.school_members_group_count![currentLoggedInUserId!]
            if (num_groups_for_user == 0 || num_groups_for_user == nil) && self.hideIfNoGroups! && indexPath.item == 10 {
                delegate?.didTapFirstFollow()
                return
            }
        }
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

