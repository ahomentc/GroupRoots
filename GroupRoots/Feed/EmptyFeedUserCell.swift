import UIKit
import Firebase
import NVActivityIndicatorView

protocol EmptyFeedUserCellDelegate {
    func didTapUser(user: User)
    func didFollowUser(user: User)
    func didRemoveUser(user: User)
}

class EmptyFeedUserCell: UICollectionViewCell {
    
    let padding: CGFloat = 12
    
    var user: User? {
        didSet {
            configureCell()
        }
    }
    
    var delegate: EmptyFeedUserCellDelegate?
    
    private lazy var profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapUser))
        iv.isUserInteractionEnabled = true
        iv.addGestureRecognizer(tapGestureRecognizer)
        
        return iv
    }()
    
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapUser))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tapGestureRecognizer)
        
        return label
    }()
    
    private lazy var followButton: FollowRemoveButton = {
        let button = FollowRemoveButton(type: .system)
        button.type = .follow
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(didFollowUser), for: .touchUpInside)
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "x").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(didRemoveUser), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    static var cellId = "emptyFeedUserCellId"
    
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
        
    }

    private func sharedInit() {
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 20, paddingLeft: 40, width: 80, height: 80)
        profileImageView.layer.cornerRadius = 40
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 12)

        addSubview(followButton)
        followButton.anchor(top: usernameLabel.bottomAnchor, left: leftAnchor, paddingTop: 12, paddingLeft: 40)
        
        addSubview(cancelButton)
        cancelButton.anchor(top: topAnchor, right: rightAnchor, paddingTop: 5, paddingRight: 5, width: 44, height: 44)
        
        self.backgroundColor = .white
        
        self.contentView.layer.cornerRadius = 20.0
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true
    }
    
    private func configureCell() {
        guard let user = user else { return }
        usernameLabel.text = user.username
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        } else {
            profileImageView.image = #imageLiteral(resourceName: "user")
        }
    }
    
    @objc private func didTapUser() {
        guard let user = user else { return }
        self.delegate?.didTapUser(user: user)
    }
    
    @objc private func didFollowUser() {
        guard let user = user else { return }
        self.delegate?.didFollowUser(user: user)
    }
    
    
    @objc private func didRemoveUser() {
        guard let user = user else { return }
        self.delegate?.didRemoveUser(user: user)
    }
}

//MARK: - JoinButtonType

private enum RecommendButtonType {
    case loading, follow, remove, hide
}

//MARK: - AcceptDenyButton

private class FollowRemoveButton: UIButton {
    
    var type: RecommendButtonType = .loading {
        didSet {
            configureButton()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 20
        layer.backgroundColor = UIColor.blue.cgColor
        
        self.widthAnchor.constraint(equalToConstant: 80).isActive = true
        self.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        configureButton()
    }
    
    private func configureButton() {
        switch type {
        case .loading:
            setupLoadingStyle()
        case .follow:
            setupFollowStyle()
        case .remove:
            setupRemoveStyle()
        case .hide:
            setupHideStyle()
        }
    }
    
    private func setupLoadingStyle() {
        setTitle("Loading", for: .normal)
        setTitleColor(.black, for: .normal)
        backgroundColor = .white
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        isUserInteractionEnabled = false
    }
    
    private func setupRemoveStyle() {
        setTitle("Remove", for: .normal)
        setTitleColor(.black, for: .normal)
        layer.backgroundColor = UIColor(white: 0.9, alpha: 1).cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 0
        layer.borderColor = UIColor.gray.cgColor
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        isUserInteractionEnabled = true
    }
    
    private func setupFollowStyle() {
        setTitle("Follow", for: .normal)
        setTitleColor(UIColor.white, for: .normal)
        layer.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        layer.cornerRadius = 5
        layer.borderWidth = 0
        contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        isUserInteractionEnabled = true
    }
    
    private func setupHideStyle() {
        setTitle("", for: .normal)
        setTitleColor(.white, for: .normal)
        backgroundColor = UIColor.white
        layer.borderColor = UIColor(white: 0, alpha: 0).cgColor
        isUserInteractionEnabled = false
    }
}



