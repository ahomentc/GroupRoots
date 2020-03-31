import UIKit
import Firebase

//MARK: - FollowPageHeaderDelegate

protocol FollowPageHeaderDelegate {
    func didChangeToFollowingView()
    func didChangeToFollowersView()
}

//MARK: - FollowPageHeader

class FollowPageHeader: UICollectionViewCell {
    
    var isFollowerView: Bool? {
        didSet {
            if isFollowerView!{
                followersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
            }
            else {
                followingButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
            }
        }
    }

    var delegate: FollowPageHeaderDelegate?
    
    private lazy var followersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Followers", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor(white: 0, alpha: 0.6).cgColor
        button.addTarget(self, action: #selector(handleChangeToFollowersView), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()

    private lazy var followingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Following", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.borderColor = UIColor(white: 0, alpha: 0.6).cgColor
        button.addTarget(self, action: #selector(handleChangeToFollowingView), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()

    private let padding: CGFloat = 12

    static var headerId = "followPageHeaderId"

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    private func sharedInit() {
        layoutToolbar()
    }

    private func layoutToolbar() {
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor(white: 0, alpha: 0.2)

        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor(white: 0, alpha: 0.2)

        let stackView = UIStackView(arrangedSubviews: [followingButton, followersButton])
        stackView.distribution = .fillEqually

        addSubview(stackView)
        addSubview(topDividerView)
        addSubview(bottomDividerView)

        topDividerView.anchor(top: stackView.topAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
        bottomDividerView.anchor(top: stackView.bottomAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
        stackView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, height: 44)
    }

    @objc private func handleChangeToFollowersView() {
        followersButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        followingButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
        delegate?.didChangeToFollowersView()
    }

    @objc private func handleChangeToFollowingView() {
        followingButton.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        followersButton.setTitleColor(UIColor(white: 0, alpha: 0.2), for: .normal)
        delegate?.didChangeToFollowingView()
    }
}
