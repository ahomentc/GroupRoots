import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class ForceUpdateController: UIViewController {
    
    private let logoView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.zPosition = 10
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0, alpha: 1)
        return iv
    }()
    
    private let updateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 4
        label.numberOfLines = 0
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Please Update GroupRoots", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
        label.attributedText = attributedText
        return label
    }()
    
    private let updateBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 1)
        view.layer.zPosition = 3
        view.isUserInteractionEnabled = false
        view.layer.cornerRadius = 10
        return view
    }()
    
    private lazy var updateButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(sent_to_update), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.backgroundColor = UIColor.black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.setTitle("Update Now", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        self.navigationController?.isNavigationBarHidden = true
        
//        logoView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        logoView.layer.cornerRadius = 0
        logoView.frame = CGRect(x: UIScreen.main.bounds.width/2-20, y: UIScreen.main.bounds.height/2-80, width: 40, height: 40)
        logoView.image =  #imageLiteral(resourceName: "Small_White_Logo")
        self.view.insertSubview(logoView, at: 10)
        
        updateButton.frame = CGRect(x: UIScreen.main.bounds.width/2-70, y: UIScreen.main.bounds.height/2 + 25, width: 140, height: 50)
        updateButton.layer.cornerRadius = 18
        self.view.insertSubview(updateButton, at: 4)
        
        updateLabel.frame = CGRect(x: 0, y: UIScreen.main.bounds.height/2-20, width: UIScreen.main.bounds.width, height: 20)
        self.view.insertSubview(updateLabel, at: 4)
         
        updateBackground.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-100, width: 300, height: 200)
        self.view.insertSubview(updateBackground, at: 3)
        
        view.backgroundColor = UIColor(white: 0.15, alpha: 1)
    }
    
    @objc func sent_to_update() {
        Database.database().fetch_link_to_app(completion: { (link_to_app) in
            guard let url = URL(string: link_to_app) else { return }
            UIApplication.shared.open(url)
        })
    }
}
