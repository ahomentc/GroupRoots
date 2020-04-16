import UIKit

protocol HomePostCellDelegate {
    func didTapComment(groupPost: GroupPost)
    func didTapGroup(group: Group)
    func didTapOptions(groupPost: GroupPost)
}

class HomePostCell: UICollectionViewCell {
    
    var delegate: HomePostCellDelegate?
    
    var groupPost: GroupPost? {
        didSet {
            configurePost()
        }
    }
    
    let header = HomePostCellHeader()
    
    let captionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    let padding: CGFloat = 12
    
    private let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.95, alpha: 1)
        return iv
    }()

    private lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "comment").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return button
    }()
    
    private let sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "send2").withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()
    
    private let bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "ribbon").withRenderingMode(.alwaysOriginal), for: .normal)
        return button
    }()
    
    private let likeCounter: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
        return label
    }()
    
    static var cellId = "homePostCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(header)
        header.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor)
        header.delegate = self
        
        addSubview(photoImageView)
        photoImageView.anchor(top: header.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingLeft: 20, paddingRight: 20)
        photoImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
        photoImageView.layer.cornerRadius = 10
        
        setupActionButtons()
        
        addSubview(captionLabel)
        captionLabel.anchor(top: likeCounter.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: padding - 6, paddingLeft: padding, paddingRight: padding)
    }
    
    private func setupActionButtons() {
        let stackView = UIStackView(arrangedSubviews: [commentButton])
        stackView.distribution = .fillEqually
        stackView.alignment = .top
        stackView.spacing = 16
        addSubview(stackView)
        stackView.anchor(top: photoImageView.bottomAnchor, left: leftAnchor, paddingTop: padding, paddingLeft: padding)
        
//        addSubview(bookmarkButton)
//        bookmarkButton.anchor(top: photoImageView.bottomAnchor, right: rightAnchor, paddingTop: padding, paddingRight: padding)
    }
    
    private func configurePost() {
        guard let groupPost = groupPost else { return }
        header.group = groupPost.group
        photoImageView.loadImage(urlString: groupPost.imageUrl)
        setupAttributedCaption()
    }
    
    private func setupAttributedCaption() {
        guard let post = self.groupPost else { return }
        
        let attributedText = NSMutableAttributedString(string: post.group.groupname, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
        attributedText.append(NSAttributedString(string: " \(post.caption)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]))
        attributedText.append(NSAttributedString(string: "\n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 4)]))
        
        let timeAgoDisplay = post.creationDate.timeAgoDisplay()
        attributedText.append(NSAttributedString(string: timeAgoDisplay, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray]))
        captionLabel.attributedText = attributedText
    }
    
    @objc private func handleComment() {
        guard let groupPost = groupPost else { return }
        delegate?.didTapComment(groupPost: groupPost)
    }
}

//MARK: - HomePostCellHeaderDelegate

extension HomePostCell: HomePostCellHeaderDelegate {
    
    func didTapGroup() {
        guard let group = groupPost?.group else { return }
        delegate?.didTapGroup(group: group)
    }
    
    func didTapOptions() {
        guard let groupPost = groupPost else { return }
        delegate?.didTapOptions(groupPost: groupPost)
    }
}

