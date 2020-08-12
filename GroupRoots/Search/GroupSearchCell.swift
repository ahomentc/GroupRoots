import UIKit
import Firebase
import FirebaseDatabase

class GroupSearchCell: UICollectionViewCell {
    
    var group: Group? {
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
    
    private let userOneImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 0
        return iv
    }()
    
    private let userTwoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 0
        return iv
    }()
    
    private let groupnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    static var cellId = "groupSearchCellId"
    
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
        profileImageView.anchor(left: leftAnchor, paddingLeft: 15, width: 50, height: 50)
        profileImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        profileImageView.layer.cornerRadius = 50 / 2
        
        addSubview(userOneImageView)
        userOneImageView.anchor(left: leftAnchor, paddingTop: 10, paddingLeft: 28, width: 40, height: 40)
        userOneImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userOneImageView.layer.cornerRadius = 40/2
        userOneImageView.isHidden = true
        userOneImageView.image = UIImage()
        
        addSubview(userTwoImageView)
        userTwoImageView.anchor(left: leftAnchor, paddingTop: 0, paddingLeft: 8, width: 44, height: 44)
        userTwoImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        userTwoImageView.layer.cornerRadius = 44/2
        userTwoImageView.isHidden = true
        userTwoImageView.image = UIImage()
        
        addSubview(groupnameLabel)
        groupnameLabel.anchor(top: topAnchor, left: userOneImageView.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: 8)
        
    }
    
    private func configureCell() {
        guard let group = group else { return }
        
        groupnameLabel.text = group.groupname.replacingOccurrences(of: "_-a-_", with: " ")
        if let profileImageUrl = group.groupProfileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        } else {
            profileImageView.image = #imageLiteral(resourceName: "user")
        }
        
        Database.database().fetchFirstNGroupMembers(groupId: group.groupId, n: 3, completion: { (first_n_users) in
            if group.groupname != "" {
                self.groupnameLabel.text = group.groupname.replacingOccurrences(of: "_-a-_", with: " ")
            }
            else {
                if first_n_users.count > 2 {
                    var usernames = first_n_users[0].username + " & " + first_n_users[1].username + " & " + first_n_users[2].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                    self.groupnameLabel.text = usernames
                }
                else if first_n_users.count == 2 {
                    var usernames = first_n_users[0].username + " & " + first_n_users[1].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                    self.groupnameLabel.text = usernames
                }
                else if first_n_users.count == 1 {
                    var usernames = first_n_users[0].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                    self.groupnameLabel.text = usernames
                }
            }

            if let groupProfileImageUrl = group.groupProfileImageUrl {
                self.profileImageView.loadImage(urlString: groupProfileImageUrl)
                self.profileImageView.isHidden = false
                self.userOneImageView.isHidden = true
                self.userTwoImageView.isHidden = true
            } else {
                self.profileImageView.isHidden = true
                self.userOneImageView.isHidden = false
                self.userTwoImageView.isHidden = true
                
                if first_n_users.count > 0 {
                    if let userOneImageUrl = first_n_users[0].profileImageUrl {
                        self.userOneImageView.loadImage(urlString: userOneImageUrl)
                    } else {
                        self.userOneImageView.image = #imageLiteral(resourceName: "user")
                        self.userOneImageView.backgroundColor = .white
                    }
                }
                else {
                    self.userOneImageView.image = #imageLiteral(resourceName: "user")
                    self.userOneImageView.backgroundColor = .white
                }
                
                // set the second user (only if it exists)
                if first_n_users.count > 1 {
                    self.userTwoImageView.isHidden = false
                    if let userTwoImageUrl = first_n_users[1].profileImageUrl {
                        self.userTwoImageView.loadImage(urlString: userTwoImageUrl)
                        self.userTwoImageView.layer.borderWidth = 2
                    } else {
                        self.userTwoImageView.image = #imageLiteral(resourceName: "user")
                        self.userTwoImageView.backgroundColor = .white
                        self.userTwoImageView.layer.borderWidth = 2
                    }
                }
            }
        }) { (_) in }
    }
}
