import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

protocol loadMoreFollowersCellDelegate {
    func handleLoadMoreFollowers()
}

class LoadMoreFollowersCell: UICollectionViewCell {
    var delegate: loadMoreFollowersCellDelegate?
    
    var index: Int? {
        didSet {
            setLoadMoreVisibility()
        }
    }
    
    var user: User? {
        didSet {
            setLoadMoreVisibility()
        }
    }
    
    private lazy var loadMoreButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(.black, for: .normal)
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        label.contentHorizontalAlignment = .center
        label.isUserInteractionEnabled = true
        label.text("Load More")
        label.isHidden = true
        label.addTarget(self, action: #selector(handleLoadMore), for: .touchUpInside)
        return label
    }()
    
    static var cellId = "loadMoreFollowersCellId"
    
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
        loadMoreButton.isHidden = true
    }
    
    private func sharedInit() {
        addSubview(loadMoreButton)
        loadMoreButton.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor)
    }
    
    func setLoadMoreVisibility(){
        guard let user = user else { return }
        guard let index = index else { return }
        
//        if index < 6 {
//            loadMoreButton.isHidden = true
//            return
//        }
        
        Database.database().numberOfFollowersForUser(withUID: user.uid, completion: { (numFollowersTotal) in
            print(index)
            print(numFollowersTotal)
            if index == numFollowersTotal {
                self.loadMoreButton.isHidden = true
            }
            else {
                self.loadMoreButton.isHidden = false
            }
        })
    }
    
    @objc private func handleLoadMore(){
        self.delegate?.handleLoadMoreFollowers()
    }
}
