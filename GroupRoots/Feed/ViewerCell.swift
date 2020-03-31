import UIKit

class ViewerCell: UICollectionViewCell {
    
    var user: User? {
        didSet {
            configureCell()
        }
    }
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        return iv
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    static var cellId = "viewerCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(profileImageView)
        profileImageView.anchor(left: leftAnchor, paddingLeft: 8, width: 50, height: 50)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 50 / 2
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 8)
        
    }
    
    private func configureCell() {
        usernameLabel.text = user?.username
        if let profileImageUrl = user?.profileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        } else {
            profileImageView.image = #imageLiteral(resourceName: "user")
        }
    }
}

class NumHiddenCell: UICollectionViewCell {
    
    var num_total: Int? {
        didSet {
            configureCell()
        }
    }
    
    var num_visible: Int? {
        didSet {
            configureCell()
        }
    }
    
    private let hiddenIcon: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "hide_eye").withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()
        
    private let numHiddenLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    static var cellId = "numHiddenCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(hiddenIcon)
        hiddenIcon.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, paddingLeft: 16)
        
        addSubview(numHiddenLabel)
        numHiddenLabel.anchor(top: topAnchor, left: hiddenIcon.rightAnchor, bottom: bottomAnchor,  paddingLeft: 12)
    }
    
    private func configureCell() {
        guard let num_total = num_total else { return }
        guard let num_visible = num_visible else { return }
        let num_hidden = num_total - num_visible
        if num_hidden == 1 {
            numHiddenLabel.text = String(num_hidden) + " Hidden Viewer"
        }
        else if num_hidden > 1 {
            numHiddenLabel.text = String(num_hidden) + " Hidden Viewers"
        }
    }
}
