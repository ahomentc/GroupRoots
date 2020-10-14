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
}

class FeedPostCell: UICollectionViewCell, UIScrollViewDelegate {
    
    var delegate: InnerPostCellDelegate?
    var timer = Timer()
    
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
        button.isHidden = true
        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        return button
    }()
    
    private lazy var viewCountLabel: UILabel = {
        let label = UILabel()
        label.layer.zPosition = 4;
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showViewers))
        label.addGestureRecognizer(gestureRecognizer)
        return label
    }()
    
    private lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: UIScreen.main.bounds.width/2 - 100, y: UIScreen.main.bounds.height/2 - 100, width: 200, height: 200)
        button.tintColor = UIColor.white
        button.isUserInteractionEnabled = false
        button.setImage(#imageLiteral(resourceName: "play").withRenderingMode(.alwaysOriginal), for: .normal)
        button.isHidden = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
            
    var player = Player()
    
    private let imageBackground: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        backgroundView.backgroundColor = .black
        return backgroundView
    }()
    
    private let coverView: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 250))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 3)
        return backgroundView
    }()
    
    private let upperCoverView: UIView = {
//        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 350))
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 3)
        return backgroundView
    }()
    
    private lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("•••", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.layer.zPosition = 4;
        button.addTarget(self, action: #selector(handleOptionsTap), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 20, left: 15, bottom: 15, right: 15)
        return button
    }()
    
    let activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width/2 - 35, y: UIScreen.main.bounds.height/2 - 35, width: 70, height: 70), type: NVActivityIndicatorType.circleStrokeSpin)
    
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
        
        addSubview(postedByLabel)
        postedByLabel.anchor(bottom: bottomAnchor, right: rightAnchor, paddingLeft: padding, paddingBottom: UIScreen.main.bounds.height/9, paddingRight: padding + 6)
        
        addSubview(locationLabel)
        locationLabel.anchor(top: postedByLabel.bottomAnchor, right: rightAnchor, paddingTop: padding - 10, paddingLeft: padding, paddingRight: padding + 6)
        
        addSubview(newCommentButton)
        newCommentButton.anchor(left: leftAnchor, bottom:bottomAnchor, paddingLeft: 0, paddingBottom: UIScreen.main.bounds.height/9)
        
        addSubview(commentsButton)
        commentsButton.anchor(left: leftAnchor, bottom:bottomAnchor, paddingLeft: padding + 3, paddingBottom: UIScreen.main.bounds.height/9)
        
        addSubview(timeLabel)
        timeLabel.anchor(bottom: postedByLabel.topAnchor, right: rightAnchor, paddingBottom: padding - 10, paddingRight: padding + 6)
         
        addSubview(captionLabel)
        captionLabel.anchor(left: leftAnchor, bottom: commentsButton.topAnchor, right: rightAnchor, paddingLeft: padding + 3, paddingBottom: padding - 2, paddingRight: padding - 5)
        
        addSubview(viewButton)
        viewButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: UIScreen.main.bounds.height/16 + 50, paddingLeft: padding)
        
        addSubview(viewCountLabel)
        viewCountLabel.anchor(top: topAnchor, left: viewButton.rightAnchor, paddingTop: UIScreen.main.bounds.height/16 + 65)

        addSubview(optionsButton)
        optionsButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: UIScreen.main.bounds.height/16, paddingLeft: padding)
        
        insertSubview(playButton, at: 11)
        
        coverView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        coverView.layer.cornerRadius = 0
        coverView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 210, width: UIScreen.main.bounds.width, height: 250)
        coverView.isUserInteractionEnabled = false
        insertSubview(coverView, at: 3)
        
        // was 350
        upperCoverView.heightAnchor.constraint(equalToConstant: 300).isActive = true
        upperCoverView.layer.cornerRadius = 0
        upperCoverView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300)
        upperCoverView.isUserInteractionEnabled = false
        insertSubview(upperCoverView, at: 3)
        
        photoImageView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        photoImageView.layer.cornerRadius = 5
        photoImageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        photoImageView.center = CGPoint(x: UIScreen.main.bounds.width  / 2, y: UIScreen.main.bounds.height / 2)
        insertSubview(photoImageView, at: 2)
        photoImageView.isHidden = false
        
        insertSubview(player.view, at: 0)
        player.view.isHidden = true
        player.autoplay = false
        player.playbackResumesWhenBecameActive = false
        player.playbackResumesWhenEnteringForeground = false
        player.playerDelegate = self
        
        insertSubview(imageBackground, at: 1)
        imageBackground.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        imageBackground.layer.cornerRadius = 0
        imageBackground.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
//        insertSubview(loadingLabel, at: 19)
//        loadingLabel.isHidden = true
//        loadingLabel.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, paddingTop: padding + UIScreen.main.bounds.height/2 - 14)
        
        activityIndicatorView.isHidden = true
        playButton.isHidden = true
        insertSubview(activityIndicatorView, at: 20)
        activityIndicatorView.startAnimating()
        
        timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(updatePlayButton), userInfo: nil, repeats: true)
        
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

        setupAttributedCaption(groupPost: groupPost)
        setupGroupPoster(groupPost: groupPost)
        setupTimeLabel(groupPost: groupPost)
        setupPostLocation(groupPost: groupPost)
        
        self.viewButton.isHidden = true
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
                self.setImageDimensions()
                self.imageBackground.backgroundColor = UIColor(red: CGFloat(groupPost.avgRed), green: CGFloat(groupPost.avgGreen), blue: CGFloat(groupPost.avgBlue), alpha: CGFloat(groupPost.avgAlpha))
                
            } else {
                self.photoImageView.image = CustomImageView.imageWithColor(color: .black)
                SGImageCache.getImage(url: imageUrl) { [weak self] image in
                    self?.photoImageView.image = image   // image loaded async
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
    }

    private func setImageDimensions(){
        let width = self.photoImageView.image?.size.width
        let height = self.photoImageView.image?.size.height
        self.photoImageView.layer.cornerRadius = 5
        if width != nil && height != nil {
            if width! >= height! {
                self.photoImageView.contentMode = .scaleToFill
                self.photoImageView.frame.size.width = UIScreen.main.bounds.width - 20
                self.photoImageView.frame.size.height = self.photoImageView.frame.size.width * (height!/width!)
                self.photoImageView.frame.origin.y = (UIScreen.main.bounds.height - self.photoImageView.frame.size.height) / 2
                self.photoImageView.frame.origin.x = 10
            }
            else {
                self.photoImageView.contentMode = .scaleToFill
                self.photoImageView.frame.size.width = UIScreen.main.bounds.width - 20
                self.photoImageView.frame.size.height = self.photoImageView.frame.size.width * (height!/width!)
                
                var y_offset = UIScreen.main.bounds.height - self.photoImageView.frame.size.height - UIScreen.main.bounds.height/9 - 100
                if y_offset < 28 {
                    y_offset = UIScreen.main.bounds.height/9 - 30
                }
                else {
                    y_offset = y_offset + 15
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
                let attributedText = NSMutableAttributedString(string: "Posted by " + groupPost.user.username, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)])
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
    
    private func setupAttributedCaption(groupPost: GroupPost) {
        if groupPost.caption == "" {
            let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 1)])
            captionLabel.attributedText = attributedText
            return
        }
        var groupname = "Group"
        if groupPost.group.groupname != "" { // if groupname is not empty
            groupname =  groupPost.group.groupname.replacingOccurrences(of: "_-a-_", with: " ")
        }
        else if groupPost.caption == "" { // if groupname is empty and caption empty
            groupname = ""
        }
        let attributedText = NSMutableAttributedString(string: groupname, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
        attributedText.append(NSAttributedString(string: " \(groupPost.caption)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]))
        attributedText.append(NSAttributedString(string: "", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 4)]))
        captionLabel.attributedText = attributedText
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
        delegate?.didTapComment(groupPost: groupPost)
    }
    
    @objc private func handleDidTapCommentUser() {
        guard let commentUser = commentUser else { return }
        delegate?.didTapUser(user: commentUser)
    }
    
    @objc private func handleDidTapPostGroup() {
        guard let groupPost = groupPost else { return }
        delegate?.didTapGroup(group: groupPost.group)
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
