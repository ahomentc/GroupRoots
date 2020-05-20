import UIKit
import Firebase

class FeedMemberCell: UITableViewCell {
        
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
    
    static var cellId = "feedMemberCellId"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func sharedInit() {
        addSubview(profileImageView)
        profileImageView.anchor(left: leftAnchor, paddingLeft: 8, width: 50, height: 50)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 50/2
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 15)
        usernameLabel.textColor = UIColor.white
        
        backgroundColor = UIColor.clear
//        let separatorView = UIView()
//        separatorView.backgroundColor = UIColor(white: 0, alpha: 0.1)
//        addSubview(separatorView)
//        separatorView.anchor(left: usernameLabel.leftAnchor, bottom: bottomAnchor, right: rightAnchor, height: 0.5)
        
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
