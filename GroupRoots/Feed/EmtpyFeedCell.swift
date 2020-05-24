import UIKit
import Firebase
import NVActivityIndicatorView

class EmptyFeedPostCell: UICollectionViewCell {
    
    let padding: CGFloat = 12
    
    private let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.95, alpha: 1)
        return iv
    }()
    
//    let loadingLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Loading"
//        label.textColor = UIColor.white
//        label.numberOfLines = 0
//        label.textAlignment = .center
//        return label
//    }()
    
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

    private func sharedInit() {
        
//        addSubview(loadingLabel)
//        loadingLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: padding + UIScreen.main.bounds.height/2 - 14)
        
        activityIndicatorView.isHidden = true
        activityIndicatorView.color = .black
        insertSubview(activityIndicatorView, at: 20)
        activityIndicatorView.startAnimating()
        
        addSubview(photoImageView)
        photoImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: padding + 12)
//        photoImageView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
//        photoImageView.layer.cornerRadius = 10
        photoImageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

    }
}
