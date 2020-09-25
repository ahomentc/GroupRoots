import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import NVActivityIndicatorView

protocol EmptyFeedPostCellDelegate {
    func didTapUser(user: User)
    func handleShowNewGroup()
}

class EmptyFeedPostCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate, EmptyFeedUserCellDelegate {
    
    let padding: CGFloat = 12
    
    var fetchedAllGroups: Bool? {
        didSet {
            setLoadingVisibility(fetchedAllGroups: fetchedAllGroups!)
        }
    }
    
    var delegate: EmptyFeedPostCellDelegate?
    
    var recommendedUsers = [User]()
    var collectionView: UICollectionView!
    
    let endLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textColor = UIColor.black
        label.attributedText = NSMutableAttributedString(string: "You're All Caught Up!", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
        label.numberOfLines = 0
        label.size(22)
        label.textAlignment = .center
        return label
    }()
    
    let recommendedLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textColor = UIColor.black
        let attributedText = NSMutableAttributedString(string: "Follow suggested users\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSMutableAttributedString(string: "and get auto subscribed to their public groups", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)]))
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.size(22)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var newGroupButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didTapNewGroup), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Create a new Group", for: .normal)
        return button
    }()
    
    let activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width/2 - 35, y: UIScreen.main.bounds.height/2 - 35, width: 70, height: 70), type: NVActivityIndicatorType.circleStrokeSpin)
    
    var activityIndicator = UIActivityIndicatorView()
    
    static var cellId = "emptyFeedPostCellId"
    
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
        endLabel.isHidden = true
        activityIndicatorView.isHidden = false
        recommendedLabel.isHidden = true
        newGroupButton.isHidden = true
        collectionView.isHidden = true
    }

    private func sharedInit() {
        addSubview(endLabel)
        endLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: UIScreen.main.bounds.height/8)
        
        activityIndicatorView.isHidden = true
        activityIndicatorView.color = .black
        insertSubview(activityIndicatorView, at: 20)
        activityIndicatorView.startAnimating()
        
        newGroupButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 + 30, width: 300, height: 50)
        newGroupButton.layer.cornerRadius = 14
        addSubview(newGroupButton)
        
        addSubview(recommendedLabel)
        recommendedLabel.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/3 - 40, width: 300, height: 60)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.itemSize = CGSize(width: 160, height: 200)
        layout.minimumLineSpacing = CGFloat(15)
        collectionView = UICollectionView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height/3 + 20, width: UIScreen.main.bounds.width, height: 210), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CollectionViewCell")
        collectionView.register(EmptyFeedUserCell.self, forCellWithReuseIdentifier: EmptyFeedUserCell.cellId)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isUserInteractionEnabled = true
//        collectionView.allowsSelection = true
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isHidden = true
        insertSubview(collectionView, at: 10)
        
        fetchRecommendedUsers()
        
        // set the shadow of the view's layer
        collectionView.layer.backgroundColor = UIColor.clear.cgColor
        collectionView.layer.shadowColor = UIColor.black.cgColor
        collectionView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        collectionView.layer.shadowOpacity = 0.2
        collectionView.layer.shadowRadius = 4.0
    }
    
    func fetchRecommendedUsers(){
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        Database.database().fetchFollowRecommendations(withUID: currentLoggedInUserId, completion: { (recommended_users) in
            self.recommendedUsers = recommended_users
            self.collectionView?.reloadData()
        }) { (err) in
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recommendedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyFeedUserCell.cellId, for: indexPath) as! EmptyFeedUserCell
        cell.user = recommendedUsers[indexPath.row]
        cell.layer.cornerRadius = 10
        cell.layer.borderWidth = 1.0
        cell.layer.borderColor = UIColor.clear.cgColor
        cell.layer.masksToBounds = true
        cell.delegate = self
        return cell
    }
    
    func didTapUser(user: User) {
        self.delegate?.didTapUser(user: user)
    }
    
    // Follow the user, and remove from the collectionview
    // Don't need to set 1000 as that happens in cloud function
    func didFollowUser(user: User) {
        Database.database().followUser(withUID: user.uid) { (err) in
            if err != nil {
                return
            }
            // remove from recommendedUsers and refresh the collectionview
            self.recommendedUsers.removeAll(where: { $0.uid == user.uid })
            self.collectionView.reloadData()
            
            Database.database().createNotification(to: user, notificationType: NotificationType.newFollow) { (err) in
                if err != nil {
                    return
                }
            }
        }
    }
    
    func didRemoveUser(user: User) {
        // set to 1000 and remove from collectionview
        Database.database().removeFromFollowRecommendation(withUID: user.uid) { (err) in
            if err != nil {
                return
            }
            self.recommendedUsers.removeAll(where: { $0.uid == user.uid })
            self.collectionView.reloadData()
        }
    }
    
    @objc func didTapNewGroup(){
        self.delegate?.handleShowNewGroup()
    }
    
    func setLoadingVisibility(fetchedAllGroups: Bool){
        if fetchedAllGroups {
            activityIndicatorView.isHidden = true
            endLabel.isHidden = false
            newGroupButton.isHidden = false
            recommendedLabel.isHidden = false
            collectionView.isHidden = false
        }
    }
}

extension EmptyFeedPostCell: UICollectionViewDelegateFlowLayout {
    
    private func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewFlowLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 160, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
    }
}
