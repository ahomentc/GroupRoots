//
//  MembersCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/24/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol FeedMembersCellDelegate {
    func selectedMember(selectedUser: User)
    func showMoreMembers()
    func goToFirstImage()
}

class MembersCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {

    var group: Group? {
        didSet {
            configureCell()
        }
    }
    
    var members = [User]()
    var delegate: FeedMembersCellDelegate?
    
    static var cellId = "membersCellId"
    let padding: CGFloat = 12
    
    let membersLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var showMoreLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.white
//        label.text = "show more"
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleShowMoreMembers))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
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
        showMoreLabel.text = ""
        members = [User]()
    }
    
    var tableView: UITableView!
    private func sharedInit() {
         addSubview(membersLabel)
         membersLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: padding + 150, paddingLeft:  UIScreen.main.bounds.width/2 - padding - 30, paddingRight: padding)
        membersLabel.textColor = UIColor.white
        
        let displayWidth: CGFloat = self.frame.width
//        let displayHeight: CGFloat = self.frame.height
        tableView = UITableView(frame: CGRect(x: 10, y: 180, width: displayWidth-10, height: 80*4))
        tableView.register(FeedMemberCell.self, forCellReuseIdentifier: "cellId")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.backgroundColor = UIColor.black
        addSubview(tableView)
        
        addSubview(showMoreLabel)
        showMoreLabel.anchor(top: tableView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 10, paddingLeft: padding + 10)
//        addSubview(showMoreLabel)
//         showMoreLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: padding + 150, paddingLeft:  UIScreen.main.bounds.width/2 - padding - 30, paddingRight: padding)
//        showMoreLabel.textColor = UIColor.white
    }
    
    private func configureCell() {
        let attributedText = NSMutableAttributedString(string: "Members", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)])
        self.membersLabel.attributedText = attributedText
        
        // later could make this a table instead of just text and click to go to profiles
        self.tableView.refreshControl?.beginRefreshing()
        Database.database().fetchGroupMembers(groupId: group!.groupId, completion: { (users) in
            self.members = users
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
            
            if users.count > 3 {
                let attributedText = NSMutableAttributedString(string: "Show More", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)])
                self.showMoreLabel.attributedText = attributedText
            }
        }) { (_) in }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(80)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didTapMember(selectedUser: members[indexPath.row])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if members.count > 4 {
            return 4
        }
        return members.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath as IndexPath) as! FeedMemberCell
        cell.user = members[indexPath.row]
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }
    
    func didTapMember(selectedUser: User) {
        delegate?.selectedMember(selectedUser: selectedUser)
    }
    
    @objc func handleShowMoreMembers(){
        delegate?.showMoreMembers()
    }
}











