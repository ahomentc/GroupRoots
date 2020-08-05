import UIKit
import Firebase

protocol ProfileFeedCellHeaderDelegate {
    func didTapGroup()
    func didTapOptions()
    func didTapUser(user: User)
}

class ProfileFeedCellHeader: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var group: Group? {
        didSet {
            configureGroup()
        }
    }
    
    var groupMembers: [User]? {
        didSet {
            configureGroup()
        }
    }
    
    var memberRequestors: Int? {
        didSet {
        }
    }
    
    var followers: Int? {
        didSet {
        }
    }
    
    var pendingFollowers: Int? {
        didSet {
        }
    }
    
    // this collection view holds the members
    var collectionView: UICollectionView!
    
    static var headerId = "profileFeedCellHeaderId"
    var delegate: ProfileFeedCellHeaderDelegate?
    private var users = [User]()
    
    private var padding: CGFloat = 8
    
    private lazy var usernameButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(.black, for: .normal)
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        label.contentHorizontalAlignment = .center
        label.isUserInteractionEnabled = true
        label.addTarget(self, action: #selector(handleGroupTap), for: .touchUpInside)
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

    private func sharedInit() {
        addSubview(usernameButton)
        usernameButton.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: padding + 20)
        usernameButton.backgroundColor = .clear
        usernameButton.isUserInteractionEnabled = true
        usernameButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGroupTap)))

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumLineSpacing = CGFloat(0)

        collectionView = UICollectionView(frame: CGRect(x: 0, y: 80, width: UIScreen.main.bounds.width, height: 90), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView.register(GroupProfileHeaderCell.self, forCellWithReuseIdentifier: GroupProfileHeaderCell.cellId)
        collectionView.register(MemberHeaderCell.self, forCellWithReuseIdentifier: MemberHeaderCell.cellId)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isUserInteractionEnabled = true
        collectionView.allowsSelection = true
        self.addSubview(collectionView)
    }
    
    private func configureGroup() {
        guard let group = group else { return }
        guard let groupMembers = groupMembers else { return }
        if groupMembers.count == 0 { return }
        
        // set groupname
        usernameButton.setTitle(group.groupname.replacingOccurrences(of: "_-a-_", with: " "), for: .normal)
        usernameButton.setTitleColor(.black, for: .normal)
        
        Database.database().fetchGroupMembers(groupId: group.groupId, completion: { (users) in
            self.users = users
            self.collectionView.reloadData()
        }) { (_) in
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // if there is a group profile image
        if group?.groupProfileImageUrl != nil && group?.groupProfileImageUrl != ""{
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupProfileHeaderCell.cellId, for: indexPath) as! GroupProfileHeaderCell
                cell.profileImageUrl = group?.groupProfileImageUrl
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemberHeaderCell.cellId, for: indexPath) as! MemberHeaderCell
                cell.user = users[indexPath.item-1]
                cell.group_has_profile_image = true
                return cell
            }
        }
        else {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupProfileHeaderCell.cellId, for: indexPath) as! GroupProfileHeaderCell
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemberHeaderCell.cellId, for: indexPath) as! MemberHeaderCell
                cell.user = users[indexPath.item-1]
                cell.group_has_profile_image = false
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item > 0 {
            let user = users[indexPath.item-1]
            delegate?.didTapUser(user: user)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    @objc private func handleGroupTap() {
        delegate?.didTapGroup()
    }
    
    @objc private func handleOptionsTap() {
        delegate?.didTapOptions()
    }
}

extension ProfileFeedCellHeader: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if users.count == 1 && (group?.groupProfileImageUrl == nil || group?.groupProfileImageUrl == "") {
            let totalCellWidth = 80 * collectionView.numberOfItems(inSection: 0)
            let totalSpacingWidth = 10 * (collectionView.numberOfItems(inSection: 0) - 1)

            let leftInset = (collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
            let rightInset = leftInset

            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        }
        else if users.count == 2 && (group?.groupProfileImageUrl == nil || group?.groupProfileImageUrl == "") {
            let totalCellWidth = 80 * collectionView.numberOfItems(inSection: 0)
            let totalSpacingWidth = 20 * (collectionView.numberOfItems(inSection: 0) - 1)

            let leftInset = (collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
            let rightInset = leftInset

            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        }
        else {
            return UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 0)
        }
    }
}
