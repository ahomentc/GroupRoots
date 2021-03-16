//
//  FeedPostCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/23/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import Player
import AVFoundation
import SGImageCache
import NVActivityIndicatorView
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import Zoomy

protocol InnerPostCellDelegate {
    func didTapComment(groupPost: GroupPost)
    func didTapUser(user: User)
    func didTapGroup(group: Group)
    func didTapOptions(groupPost: GroupPost)
    func didView(groupPost: GroupPost)
    func didTapViewers(groupPost: GroupPost)
    func goToImage(for cell: FeedPostCell, isRight: Bool)
    func requestPlay(for cell: FeedPostCell)
    func requestZoomCapability(for cell: FeedPostCell)
    func handleGroupTap()
}

class FeedPostCell: UICollectionViewCell, UIScrollViewDelegate, MessagesControllerDelegate {
    
    var delegate: InnerPostCellDelegate?
    var timer = Timer()
    
    var commentsReference = DatabaseReference()
    
    var groupPost: GroupPost? {
        didSet {
            if groupPost != nil {
                configurePost()
            }
        }
    }

    var numComments: Int? {
        didSet {
            if numComments != nil {
                configureCommentButton(numComments: numComments!)
            }
        }
    }

    var firstComment: Comment? {
        didSet {
            if firstComment != nil {
                setupCommentCaption(comment: firstComment!)
            }
        }
    }
    
    var lastComment: Comment? {
        didSet {
            setupMessagePreview()
        }
    }

    var emptyComment: Bool? {
        didSet {
            if emptyComment != nil {
                if emptyComment! {
                    self.commentsLabel.text = ""
                }
            }
        }
    }
    
    var numViewsForPost: Int? {
        didSet {
            if numViewsForPost != nil {
                setupViewsButton(viewsCount: numViewsForPost!)
            }
        }
    }
    
    var isScrolling: Bool? {
        didSet {
//            configurePost()
        }
    }
    
    var isScrollingVertically: Bool? {
        didSet {
//            configurePost()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
            
        self.groupPost = nil
        self.numComments = nil
        self.firstComment = nil
        self.emptyComment = nil
        self.numViewsForPost = nil
        
        let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 0)])
        postedByLabel.attributedText = attributedText
        captionLabel.attributedText = attributedText
        commentsLabel.attributedText = attributedText
        locationLabel.attributedText = attributedText
        
//        self.photoImageView.image = CustomImageView.imageWithColor(color: .black)
        self.player.pause()
        self.player.url = URL(string: "")
        self.activityIndicatorView.isHidden = true
        
        for view in addedViews {
            view.removeFromSuperview()
        }
        for layer in addedLayers {
            layer.removeFromSuperlayer()
        }
        self.expandLeftButton.isHidden = true
        self.expandRightButton.isHidden = true
        self.openMessagesButton.isHidden = false
    }
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.layer.zPosition = 4;
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)])
        label.attributedText = attributedText
        label.textAlignment = .right
        return label
    }()
    
    private lazy var postedByLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.layer.zPosition = 4;
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)])
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDidTapPoster))
        label.addGestureRecognizer(gestureRecognizer)
        label.attributedText = attributedText
        label.textAlignment = .right
        return label
    }()
    
    private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.layer.zPosition = 4;
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDidTapPostGroup))
        label.addGestureRecognizer(gestureRecognizer)
        
        let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
        label.attributedText = attributedText
        
        return label
    }()
    
    var commentUser: User?
    
    private lazy var commentsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.layer.zPosition = 4;
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDidTapCommentUser))
        label.addGestureRecognizer(gestureRecognizer)
        
        let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 0)])
        label.attributedText = attributedText
        
        return label
    }()
    
    private lazy var likeCounter: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.layer.zPosition = 4;
        label.textColor = .white
        return label
    }()
    
    private lazy var viewButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "eye").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(showViewers), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.isHidden = false
        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.35
        button.layer.shadowRadius = 2.5
        return button
    }()
    
    private lazy var viewCountLabel: UILabel = {
        let label = UILabel()
        label.layer.zPosition = 4;
        label.numberOfLines = 0
        label.isHidden = false
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showViewers))
        label.addGestureRecognizer(gestureRecognizer)
        
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        label.layer.shadowOpacity = 0.35
        label.layer.shadowRadius = 2.5
        return label
    }()
    
    private lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: UIScreen.main.bounds.width/2 - 100, y: UIScreen.main.bounds.height/2 - 125, width: 200, height: 200)
        button.tintColor = UIColor.white
        button.isUserInteractionEnabled = false
        button.setImage(#imageLiteral(resourceName: "play").withRenderingMode(.alwaysOriginal), for: .normal)
        button.isHidden = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        button.layer.zPosition = 12
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.35
        button.layer.shadowRadius = 2.5
        return button
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.layer.zPosition = 4;
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var commentsButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(.white, for: .normal)
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        label.setTitle("Comments", for: .normal)
        label.layer.zPosition = 4;
        label.contentHorizontalAlignment = .left
        label.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private lazy var newCommentButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(.white, for: .normal)
        label.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        label.setTitle("", for: .normal)
        label.layer.zPosition = 4;
        label.contentHorizontalAlignment = .left
        label.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        label.isUserInteractionEnabled = true
        return label
    }()

    let padding: CGFloat = 12
    
    public let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0, alpha: 1)
        return iv
    }()
    
    public let photoImageBackgroundView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0, alpha: 1)
        return iv
    }()
            
    var player = Player()
    
    private let imageBackground: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        backgroundView.backgroundColor = .black
        return backgroundView
    }()
    
    private let coverView: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 150))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 3)
        return backgroundView
    }()
    
    private let upperCoverView: UIView = {
//        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300))
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 170))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 3)
//        backgroundView.backgroundColor = .blue
        return backgroundView
    }()
    
    private lazy var messagePreviewBackground: UIButton = {
        let backgroundView = UIButton(type: .system)
        backgroundView.backgroundColor = UIColor.init(white: 0, alpha: 0.7)
        backgroundView.layer.cornerRadius = 15
        backgroundView.layer.zPosition = 10
        backgroundView.isUserInteractionEnabled = true
        backgroundView.alpha = 0

        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        backgroundView.layer.shadowOpacity = 0.355
        backgroundView.layer.shadowRadius = 3.0
        
        backgroundView.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        return backgroundView
    }()
    
    let expandRightButton: UIButton = {
        let button = UIButton()
//        button.setImage(#imageLiteral(resourceName: "up_icon"), for: .normal)
        button.setTitle("Expand", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.backgroundColor = .clear
//        button.addTarget(self, action: #selector(toggleTempPost), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.isHidden = true
        button.isUserInteractionEnabled = false
        button.layer.zPosition = 24
        return button
    }()
    
    let expandLeftButton: UIButton = {
        let button = UIButton()
//        button.setImage(#imageLiteral(resourceName: "up_icon"), for: .normal)
        button.setTitle("Expand", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.backgroundColor = .clear
        button.isUserInteractionEnabled = false
//        button.addTarget(self, action: #selector(toggleTempPost), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.isHidden = true
        button.layer.zPosition = 24
        return button
    }()
    
    let openMessagesButton: UIButton = {
        let button = UIButton()
//        button.setImage(#imageLiteral(resourceName: "up_icon"), for: .normal)
        button.setTitle("Message", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = .clear
        button.isUserInteractionEnabled = false
//        button.addTarget(self, action: #selector(toggleTempPost), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.isHidden = false
        button.layer.zPosition = 24
        return button
    }()
    
    private lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("•••", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.layer.zPosition = 4;
        button.addTarget(self, action: #selector(handleOptionsTap), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 20, left: 15, bottom: 15, right: 15)
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.35
        button.layer.shadowRadius = 2.5
        return button
    }()
    
    let blurredEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .light)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.layer.cornerRadius = 15
        blurredEffectView.clipsToBounds = true
        blurredEffectView.isUserInteractionEnabled = true
        return blurredEffectView
    }()
    
    
    let activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width/2 - 25, y: UIScreen.main.bounds.height/2 - 50, width: 50, height: 50), type: NVActivityIndicatorType.lineScale)
    
    static var cellId = "homePostCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    var addedViews = [UIView]()
    var addedLayers = [CAShapeLayer]()
    
    func showOutgoingMessage(message: String) {
        let label =  UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        
        var text = message
        if message.count > 20 {
            text = String(message.prefix(20)) + "..."
        }
        label.text = text

        let constraintRect = CGSize(width: 0.66 * frame.width,
                                    height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: label.font],
                                            context: nil)
        label.frame.size = CGSize(width: ceil(boundingBox.width),
                                  height: ceil(boundingBox.height))

        let bubbleSize = CGSize(width: label.frame.width + 28,
                                     height: label.frame.height + 20)

        let width = bubbleSize.width
        let height = bubbleSize.height

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: width - 22, y: height))
        bezierPath.addLine(to: CGPoint(x: 17, y: height))
        bezierPath.addCurve(to: CGPoint(x: 0, y: height - 17), controlPoint1: CGPoint(x: 7.61, y: height), controlPoint2: CGPoint(x: 0, y: height - 7.61))
        bezierPath.addLine(to: CGPoint(x: 0, y: 17))
        bezierPath.addCurve(to: CGPoint(x: 17, y: 0), controlPoint1: CGPoint(x: 0, y: 7.61), controlPoint2: CGPoint(x: 7.61, y: 0))
        bezierPath.addLine(to: CGPoint(x: width - 21, y: 0))
        bezierPath.addCurve(to: CGPoint(x: width - 4, y: 17), controlPoint1: CGPoint(x: width - 11.61, y: 0), controlPoint2: CGPoint(x: width - 4, y: 7.61))
        bezierPath.addLine(to: CGPoint(x: width - 4, y: height - 11))
        bezierPath.addCurve(to: CGPoint(x: width, y: height), controlPoint1: CGPoint(x: width - 4, y: height - 1), controlPoint2: CGPoint(x: width, y: height))
        bezierPath.addLine(to: CGPoint(x: width + 0.05, y: height - 0.01))
        bezierPath.addCurve(to: CGPoint(x: width - 11.04, y: height - 4.04), controlPoint1: CGPoint(x: width - 4.07, y: height + 0.43), controlPoint2: CGPoint(x: width - 8.16, y: height - 1.06))
        bezierPath.addCurve(to: CGPoint(x: width - 22, y: height), controlPoint1: CGPoint(x: width - 16, y: height), controlPoint2: CGPoint(x: width - 19, y: height))
        bezierPath.close()
        
        let outgoingMessageLayer = CAShapeLayer()
        outgoingMessageLayer.path = bezierPath.cgPath
        outgoingMessageLayer.frame = CGRect(x: UIScreen.main.bounds.width - width - 30, y: (UIScreen.main.bounds.height - (UIScreen.main.bounds.height/7 - 35)) - 75 + 10, width: width, height: height)
        outgoingMessageLayer.fillColor = UIColor(red: 38/255, green: 118/255, blue: 255/255, alpha: 1).cgColor
        outgoingMessageLayer.zPosition = 14

        layer.insertSublayer(outgoingMessageLayer, at: 20)
        addedLayers.append(outgoingMessageLayer)
        label.layer.zPosition = 15

        label.frame = CGRect(x: UIScreen.main.bounds.width - width - 19, y: (UIScreen.main.bounds.height - (UIScreen.main.bounds.height/7 - 35)) - 75 + 10, width: width, height: height)
        insertSubview(label, at: 21)
        addedViews.append(label)
    }
    
    func showIncomingMessage(message: String) {
        let label =  UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        
        var text = message
        if message.count > 20 {
            text = String(message.prefix(20)) + "..."
        }
        label.text = text

        let constraintRect = CGSize(width: 0.66 * frame.width,
                                    height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: label.font],
                                            context: nil)
        label.frame.size = CGSize(width: ceil(boundingBox.width),
                                  height: ceil(boundingBox.height))

        let bubbleSize = CGSize(width: label.frame.width + 28,
                                     height: label.frame.height + 20)

        let width = bubbleSize.width
        let height = bubbleSize.height

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 22, y: height))
        bezierPath.addLine(to: CGPoint(x: width - 17, y: height))
        bezierPath.addCurve(to: CGPoint(x: width, y: height - 17), controlPoint1: CGPoint(x: width - 7.61, y: height), controlPoint2: CGPoint(x: width, y: height - 7.61))
        bezierPath.addLine(to: CGPoint(x: width, y: 17))
        bezierPath.addCurve(to: CGPoint(x: width - 17, y: 0), controlPoint1: CGPoint(x: width, y: 7.61), controlPoint2: CGPoint(x: width - 7.61, y: 0))
        bezierPath.addLine(to: CGPoint(x: 21, y: 0))
        bezierPath.addCurve(to: CGPoint(x: 4, y: 17), controlPoint1: CGPoint(x: 11.61, y: 0), controlPoint2: CGPoint(x: 4, y: 7.61))
        bezierPath.addLine(to: CGPoint(x: 4, y: height - 11))
        bezierPath.addCurve(to: CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: 4, y: height - 1), controlPoint2: CGPoint(x: 0, y: height))
        bezierPath.addLine(to: CGPoint(x: -0.05, y: height - 0.01))
        bezierPath.addCurve(to: CGPoint(x: 11.04, y: height - 4.04), controlPoint1: CGPoint(x: 4.07, y: height + 0.43), controlPoint2: CGPoint(x: 8.16, y: height - 1.06))
        bezierPath.addCurve(to: CGPoint(x: 22, y: height), controlPoint1: CGPoint(x: 16, y: height), controlPoint2: CGPoint(x: 19, y: height))
        bezierPath.close()

        let outgoingMessageLayer = CAShapeLayer()
        outgoingMessageLayer.path = bezierPath.cgPath
        outgoingMessageLayer.frame = CGRect(x: 35, y: (UIScreen.main.bounds.height - (UIScreen.main.bounds.height/7 - 35)) - 75 + 10, width: width, height: height)
        outgoingMessageLayer.fillColor = UIColor.init(white: 0.2, alpha: 1).cgColor
        outgoingMessageLayer.zPosition = 14

        layer.insertSublayer(outgoingMessageLayer, at: 20)
        addedLayers.append(outgoingMessageLayer)
        label.layer.zPosition = 15

        label.frame = CGRect(x: 50, y: (UIScreen.main.bounds.height - (UIScreen.main.bounds.height/7 - 35)) - 75 + 10, width: width, height: height)
        insertSubview(label, at: 21)
        addedViews.append(label)
    }

    private func sharedInit() {
        
        insertSubview(playButton, at: 11)
        
//        photoImageBackgroundView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height/3).isActive = true
//        photoImageBackgroundView.layer.cornerRadius = 15
//        photoImageBackgroundView.alpha = 0.5
//        photoImageBackgroundView.clipsToBounds = true
//        insertSubview(photoImageBackgroundView, at: 1)
//        photoImageBackgroundView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: padding + 10, paddingBottom: UIScreen.main.bounds.height/7 - 35, paddingRight: padding + 10, height: 75)
//        photoImageBackgroundView.isHidden = false

        photoImageView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        photoImageView.layer.cornerRadius = 5
        photoImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        photoImageView.center = CGPoint(x: self.frame.width  / 2, y: self.frame.height / 2)
        insertSubview(photoImageView, at: 3)
        photoImageView.isHidden = false
        
        insertSubview(player.view, at: 3) // was 0
        player.view.isHidden = true
        player.autoplay = false
        player.playbackResumesWhenBecameActive = false
        player.playbackResumesWhenEnteringForeground = false
        player.playerDelegate = self
        
        coverView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        coverView.layer.cornerRadius = 0
        coverView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 110, width: UIScreen.main.bounds.width, height: 150)
        coverView.isUserInteractionEnabled = false
        insertSubview(coverView, at: 5)
        
//        insertSubview(imageBackground, at: 1)
//        imageBackground.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
//        imageBackground.layer.cornerRadius = 0
//        imageBackground.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        insertSubview(imageBackground, at: 0)
        imageBackground.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        imageBackground.layer.cornerRadius = 0
        imageBackground.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                
        activityIndicatorView.isHidden = true
        playButton.isHidden = true
        insertSubview(activityIndicatorView, at: 20)
        activityIndicatorView.startAnimating()
        
        timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(updatePlayButton), userInfo: nil, repeats: true)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleComment))
        blurredEffectView.addGestureRecognizer(gestureRecognizer)
        insertSubview(blurredEffectView, at: 10)
        blurredEffectView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: padding + 10, paddingBottom: UIScreen.main.bounds.height/7 - 35, paddingRight: padding + 10, height: 75)
        
        insertSubview(messagePreviewBackground, at: 11)
        messagePreviewBackground.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingLeft: padding + 10, paddingBottom: UIScreen.main.bounds.height/7 - 35, paddingRight: padding + 10, height: 75)
        messagePreviewBackground.alpha = 0
        
        addSubview(expandRightButton)
        expandRightButton.anchor(bottom: messagePreviewBackground.bottomAnchor, right: messagePreviewBackground.rightAnchor, paddingBottom: 25, paddingRight: 30)
        
        addSubview(expandLeftButton)
        expandLeftButton.anchor(left: messagePreviewBackground.leftAnchor, bottom: messagePreviewBackground.bottomAnchor, paddingLeft: 30, paddingBottom: 25)
        
        addSubview(openMessagesButton)
        openMessagesButton.anchor(left: messagePreviewBackground.leftAnchor, bottom: messagePreviewBackground.bottomAnchor, right: messagePreviewBackground.rightAnchor, paddingBottom: 25)
        
        self.messagePreviewBackground.addTarget(self, action: #selector(self.messagesButtonDown), for: .touchDown)
        self.messagePreviewBackground.addTarget(self, action: #selector(self.messagesButtonDown), for: .touchDragInside)
        self.messagePreviewBackground.addTarget(self, action: #selector(self.messagesButtonUp), for: .touchDragExit)
        self.messagePreviewBackground.addTarget(self, action: #selector(self.messagesButtonUp), for: .touchCancel)
        self.messagePreviewBackground.addTarget(self, action: #selector(self.messagesButtonUp), for: .touchUpInside)
        
        insertSubview(viewButton, at: 11)
        viewButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: UIScreen.main.bounds.height/16 + 50, paddingLeft: padding)
        
        insertSubview(viewCountLabel, at: 11)
        viewCountLabel.anchor(top: topAnchor, left: viewButton.rightAnchor, paddingTop: UIScreen.main.bounds.height/16 + 65)

        insertSubview(optionsButton, at: 11)
        optionsButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: UIScreen.main.bounds.height/16, paddingLeft: padding)
    }
    
    @objc private func messagesButtonDown() {
        self.messagePreviewBackground.animateButtonDown()
    }
    
    @objc private func messagesButtonUp() {
        self.messagePreviewBackground.animateButtonUp()
    }
        
    @objc private func updatePlayButton(){
        guard let groupPost = groupPost else { return }
        if self.player.playbackState == .playing {
            self.playButton.isHidden = true
        }
        else if self.player.playbackState == .paused && groupPost.videoUrl != "" && self.activityIndicatorView.isHidden == true {
            self.playButton.isHidden = false
        }
    }
    
    private func configurePost() {
        guard let groupPost = groupPost else { return }
        
        setupGroupPoster(groupPost: groupPost)
        setupTimeLabel(groupPost: groupPost)
        setupPostLocation(groupPost: groupPost)
        
//        self.viewButton.isHidden = true
        let attributedText = NSAttributedString(string: "", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.white])
        viewCountLabel.attributedText = attributedText
        
        // need to set dimensions again in case the image is already loaded
        setImageDimensions()
        photoImageView.isHidden = true
        imageBackground.isHidden = true
        activityIndicatorView.isHidden = true
        playButton.isHidden = true
        player.view.isHidden = true
        
        var imageUrl = groupPost.imageUrl
        var videoUrl = groupPost.videoUrl
        
        let sync = DispatchGroup()
        sync.enter()
        if groupPost.imageUrl == "" {
            // need to use new folder system for this instead
            let storageRef = Storage.storage().reference()
            let imagesRef = storageRef.child("group_post_images")
            let videosRef = storageRef.child("group_post_videos")
            let groupId = groupPost.group.groupId
            let fileName = groupPost.id
            let postImageRef = imagesRef.child(groupId).child(fileName + ".jpeg")
            let postVideoRef = videosRef.child(groupId).child(fileName)
            
            // generate a download url for the image
            sync.enter()
            postImageRef.downloadURL { url, error in
                print(url!.absoluteString)
                if let error = error {
                    print(error)
                } else {
                    imageUrl = url!.absoluteString
                }
                sync.leave()
            }
            
            // generate a download url for the video
            // there is an inefficiency here
            // videoURL could be "" because there is no video, not bc its in a folder instead
            // so unneessarily trying and failing to retrieve video url a lot
            sync.enter()
            postVideoRef.downloadURL { url, error in
                if let error = error {
                    print(error)
                } else {
                    videoUrl = url!.absoluteString
                }
                sync.leave()
            }
            sync.leave()
        }
        else {
            sync.leave()
        }
        
        sync.notify(queue: .main) {
            self.delegate?.requestZoomCapability(for: self)
            if let image = SGImageCache.image(forURL: imageUrl) {
                self.photoImageView.image = image   // image loaded immediately from cache
                self.photoImageBackgroundView.image = image
                self.setImageDimensions()
                self.imageBackground.backgroundColor = UIColor(red: CGFloat(groupPost.avgRed), green: CGFloat(groupPost.avgGreen), blue: CGFloat(groupPost.avgBlue), alpha: CGFloat(groupPost.avgAlpha))
                
            } else {
                self.photoImageView.image = CustomImageView.imageWithColor(color: .black)
                SGImageCache.getImage(url: imageUrl) { [weak self] image in
                    self?.photoImageView.image = image   // image loaded async
                    self?.photoImageBackgroundView.image = image
                    self?.setImageDimensions()
                    self?.imageBackground.backgroundColor = UIColor(red: CGFloat(groupPost.avgRed), green: CGFloat(groupPost.avgGreen), blue: CGFloat(groupPost.avgBlue), alpha: CGFloat(groupPost.avgAlpha))
                }
            }
            
            if videoUrl == "" {
                self.player.url = URL(string: "")
                self.player.pause()
                self.player.muted = true
                
                self.photoImageView.isHidden = false
                self.imageBackground.isHidden = false
                self.player.view.isHidden = true
                self.activityIndicatorView.isHidden = true
                self.playButton.isHidden = true
            }
            else {
                self.player.url = URL(string: videoUrl)
                self.player.playbackLoops = true
                self.player.muted = false
                self.player.playerView.playerBackgroundColor = .black
                self.setVideoDimensions()

                self.player.view.isHidden = true
                self.activityIndicatorView.isHidden = false
                self.playButton.isHidden = true
                self.imageBackground.isHidden = true

                self.backgroundColor = UIColor.black

                do { try AVAudioSession.sharedInstance().setCategory(.playback) } catch( _) { }

                let seconds = 2.0
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    self.delegate?.requestPlay(for: self)
                }
            }
        }
        
        // this will continuously listen for refreshes in comments
        self.commentsReference = Database.database().reference().child("comments").child(groupPost.id)
        self.commentsReference.queryOrderedByKey().queryLimited(toLast: 1).observe(.value) { snapshot in
            guard let dictionaries = snapshot.value as? [String: Any] else {
                return
            }
            
            var comments = [Comment]()
                
            let sync = DispatchGroup()
            dictionaries.forEach({ (key, value) in
                guard let commentDictionary = value as? [String: Any] else { return }
                guard let uid = commentDictionary["uid"] as? String else { return }
                sync.enter()
                Database.database().userExists(withUID: uid, completion: { (exists) in
                    if exists{
                        Database.database().fetchUser(withUID: uid) { (user) in
                            let comment = Comment(user: user, dictionary: commentDictionary)
                            comments.append(comment)
                            sync.leave()
                        }
                    }
                    else{
                        sync.leave()
                    }
                })
            })
            sync.notify(queue: .main) {
                if comments.count > 0 {
                    if !(self.lastComment != nil && self.lastComment?.creationDate == comments[0].creationDate) {
                        if comments.count > 0 {
                            self.lastComment = comments[comments.count - 1]
                        }
                    }
                }
            }
        }
    }

    private func setImageDimensions(){
        let width = self.photoImageView.image?.size.width
        let height = self.photoImageView.image?.size.height
        self.photoImageView.layer.cornerRadius = 5
        if width != nil && height != nil {
            if width! >= height! {
                self.photoImageView.contentMode = .scaleToFill
                self.photoImageView.frame.size.width = self.frame.width - 20
                self.photoImageView.frame.size.height = self.photoImageView.frame.size.width * (height!/width!)
                self.photoImageView.frame.origin.y = (self.frame.height - self.photoImageView.frame.size.height) / 2
                self.photoImageView.frame.origin.x = 10
            }
            else {
                self.photoImageView.contentMode = .scaleToFill
                self.photoImageView.frame.size.width = self.frame.width - 20
                self.photoImageView.frame.size.height = self.photoImageView.frame.size.width * (height!/width!)
                
                var y_offset = UIScreen.main.bounds.height - self.photoImageView.frame.size.height - self.frame.height/9 - 100
                if y_offset < 28 {
                    y_offset = self.frame.height/9 - 50
                }
                else {
                    y_offset = y_offset - 15
                }
                self.photoImageView.frame.origin.y = y_offset
                self.photoImageView.frame.origin.x = 10
            }
        }
    }
    
    private func setVideoDimensions(){
        let width = self.photoImageView.image?.size.width
        let height = self.photoImageView.image?.size.height
        if width != nil && height != nil {
            if width! >= height! {
                print("wide")
                self.player.fillMode = .resizeAspect
            }
            else {
                print("tall")
                self.player.fillMode = .resizeAspectFill
            }
        }
    }
    

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first != nil && self.player.url?.absoluteString ?? "" != "" {
            do { try AVAudioSession.sharedInstance().setCategory(.playback) } catch( _) { }
            if self.player.playbackState == .playing {
                self.player.pause()
                self.playButton.isHidden = false
            }
            else if self.player.playbackState == .paused {
                self.player.playFromCurrentTime()
                self.playButton.isHidden = true
            }
        }
    }
    
    private func setupPostLocation(groupPost: GroupPost) {
        guard let location = groupPost.location else { return }
        var name = location.name
        if location.name == "" {
            name = location.address
        }
        let attributedText = NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.white])
        locationLabel.attributedText = attributedText
    }
    
    private func setupGroupPoster(groupPost: GroupPost) {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        let groupId = groupPost.group.groupId
        Database.database().isInGroup(groupId: groupId, completion: { (inGroup) in
            if inGroup {
                let attributedText = NSMutableAttributedString(string: "Posted by ", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)])
                attributedText.append(NSMutableAttributedString(string: groupPost.user.username, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 12)]))
                self.postedByLabel.attributedText = attributedText
            }
            else {
                // check to see if autosubscribed and if membersFollowing count > 0
                Database.database().checkIfAutoSubscribed(groupId: groupId, withUID: currentLoggedInUserId, completion: { (isAutoSubscribed) in
                    if isAutoSubscribed {
                        Database.database().fetchMembersFollowingForSubscription(groupId: groupId, withUID: currentLoggedInUserId, completion: { (members_following) in
                            if members_following.count > 0 {
                                let first_following_username = members_following[0].username
                                let attributedText = NSMutableAttributedString(string: "Because you follow " + first_following_username, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)])
                                self.postedByLabel.attributedText = attributedText
                            }
                            else {
                                let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 0)])
                                self.postedByLabel.attributedText = attributedText
                            }
                        }) { (_) in}
                    }
                    else {
                        let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 0)])
                        self.postedByLabel.attributedText = attributedText
                    }
                }) { (err) in return }
            }
        }) { (err) in
            return
        }
    }
    
    private func setupMessagePreview() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let lastComment = lastComment else { return }
        
        for view in addedViews {
            view.removeFromSuperview()
        }
        for layer in addedLayers {
            layer.removeFromSuperlayer()
        }
        
        if lastComment.user.uid == currentLoggedInUserId {
            showOutgoingMessage(message: lastComment.text)
            self.expandLeftButton.isHidden = false
            self.expandRightButton.isHidden = true
            self.openMessagesButton.isHidden = true
        }
        else {
            showIncomingMessage(message: lastComment.text)
            self.expandLeftButton.isHidden = true
            self.expandRightButton.isHidden = false
            self.openMessagesButton.isHidden = true
        }
    }

    private func setupCommentCaption(comment: Comment){
        self.commentUser = comment.user
        let attributedText = NSMutableAttributedString(string: comment.user.username, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)])
        attributedText.append(NSAttributedString(string: " " + comment.text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]))
        attributedText.append(NSAttributedString(string: "", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 4)]))
        commentsLabel.attributedText = attributedText
        commentsLabel.isHidden = false
    }
    
    private func setupViewsButton(viewsCount: Int) {
        setupViewCountLabel(viewsCount: viewsCount)
        self.viewButton.isHidden = false
    }
    
    private func configureCommentButton(numComments: Int){
        if numComments == 0 {
            self.commentsButton.setTitle("Add a comment", for: .normal)
        }
        else if numComments == 1 {
            self.commentsButton.setTitle("View 1 comment", for: .normal)
        }
        else {
            self.commentsButton.setTitle("View " + String(numComments) + " comments", for: .normal)
        }
        
        self.commentsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        self.commentsButton.setTitleColor(.white, for: .normal)
        self.newCommentButton.isUserInteractionEnabled = true
        self.newCommentButton.isHidden = false
    }
    
    private func setupTimeLabel(groupPost: GroupPost) {
        let timeAgoDisplay = groupPost.creationDate.timeAgoDisplay()
        let attributedText = NSAttributedString(string: timeAgoDisplay, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: UIColor.white])
        timeLabel.attributedText = attributedText
    }
    
    private func setupViewCountLabel(viewsCount: Int) {
        let attributedText = NSAttributedString(string: String(viewsCount), attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.white])
        viewCountLabel.attributedText = attributedText
    }
    
    @objc private func handleComment() {
        guard let groupPost = groupPost else { return }
        UIView.animate(withDuration: 0.2, animations: {
            self.blurredEffectView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.photoImageBackgroundView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        })
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { timer in
            UIView.animate(withDuration: 0.2, animations: {
                self.blurredEffectView.transform = CGAffineTransform.identity
                self.photoImageBackgroundView.transform = CGAffineTransform.identity
            })
        }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            self.delegate?.didTapComment(groupPost: groupPost)
        }
    }

    // this will never be called since LargeImageViewController sets calls MessagesController and sets
    // delegate. But okay for now. Later on pass to LargeImageViewController the commentsReference and
    // remove it there
    func didCloseMessage() {
        commentsReference.removeAllObservers()
    }
    
    @objc private func handleDidTapCommentUser() {
        guard let commentUser = commentUser else { return }
        delegate?.didTapUser(user: commentUser)
    }
    
    @objc private func handleDidTapPoster() {
        guard let groupPost = groupPost else { return }
        delegate?.didTapUser(user: groupPost.user)
    }
    
    @objc private func handleDidTapPostGroup() {
//        guard let groupPost = groupPost else { return }
//        delegate?.didTapGroup(group: groupPost.group)
        delegate?.handleGroupTap()
    }
    
    @objc private func handleOptionsTap() {
        guard let groupPost = groupPost else { return }
        delegate?.didTapOptions(groupPost: groupPost)
    }
    
    @objc private func showViewers(){
        guard let groupPost = groupPost else { return }
        delegate?.didTapViewers(groupPost: groupPost)
    }
}


extension FeedPostCell: PlayerDelegate {
    func playerReady(_ player: Player) {
        
    }
    
    func playerPlaybackStateDidChange(_ player: Player) {
        
    }
    
    func playerBufferingStateDidChange(_ player: Player) {
        self.activityIndicatorView.isHidden = true
        self.player.view.isHidden = false
        self.photoImageView.isHidden = true
    }
    
    func playerBufferTimeDidChange(_ bufferTime: Double) {
        
    }
    
    func player(_ player: Player, didFailWithError error: Error?) {
        
    }
}
