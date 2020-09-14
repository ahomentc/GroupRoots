import UIKit
import Firebase
import NVActivityIndicatorView

class EmptyFeedPostCell: UICollectionViewCell {
    
    let padding: CGFloat = 12
    
    var fetchedAllGroups: Bool? {
        didSet {
            setLoadingVisibility(fetchedAllGroups: fetchedAllGroups!)
        }
    }
    
    let endLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textColor = UIColor.black
        label.attributedText = NSMutableAttributedString(string: "You're All Caught Up!", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
        label.numberOfLines = 0
        label.size(22)
        label.textAlignment = .center
        return label
    }()
    
    let recommendedLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textColor = UIColor.black
        let attributedText = NSMutableAttributedString(string: "Follow Friends\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
        attributedText.append(NSMutableAttributedString(string: "to get auto subscribed to their public groups", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)]))
        label.attributedText = attributedText
        label.numberOfLines = 0
        label.size(22)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var newGroupButton: UIButton = {
        let button = UIButton()
//        button.addTarget(self, action: #selector(handleShowNewGroup), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = true
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Create a Group", for: .normal)
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
    }

    private func sharedInit() {
        addSubview(endLabel)
        endLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: UIScreen.main.bounds.height/8)
        
        addSubview(recommendedLabel)
        recommendedLabel.anchor(top: endLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 50, height: 60)
        
        activityIndicatorView.isHidden = true
        activityIndicatorView.color = .black
        insertSubview(activityIndicatorView, at: 20)
        activityIndicatorView.startAnimating()
        
        newGroupButton.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/4 * 3 + 30, width: 300, height: 50)
        newGroupButton.layer.cornerRadius = 14
        addSubview(newGroupButton)
    }
    
    func setLoadingVisibility(fetchedAllGroups: Bool){
        if fetchedAllGroups {
            activityIndicatorView.isHidden = true
            endLabel.isHidden = false
            newGroupButton.isHidden = false
            recommendedLabel.isHidden = false
        }
    }
}
