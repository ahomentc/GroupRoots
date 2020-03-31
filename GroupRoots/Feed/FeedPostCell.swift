//
//  FeedPostCell.swift
//  InstagramClone
//
//  Created by Andrei Homentcovschi on 1/23/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase

protocol InnerPostCellDelegate {
    func didTapComment(groupPost: GroupPost)
    func didTapUser(user: User)
    func didTapGroup(group: Group)
    func didTapOptions(groupPost: GroupPost)
    func didView(groupPost: GroupPost)
    func didTapViewers(groupPost: GroupPost)
    func goToImage(for cell: FeedPostCell, isRight: Bool)
}

class FeedPostCell: UICollectionViewCell {
    
    var delegate: InnerPostCellDelegate?
    
    var groupPost: GroupPost? {
        didSet {
            configurePost()
        }
    }

    var numComments: Int? {
        didSet {
            configureCommentButton(numComments: numComments!)
        }
    }

    var firstComment: Comment? {
        didSet {
            setupCommentCaption(comment: firstComment!)
        }
    }
    
    var numViewsForPost: Int? {
        didSet {
            setupViewsButton(viewsCount: numViewsForPost!)
        }
    }
    
    private lazy var postedByLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.layer.zPosition = 4;
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
//        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDidTapPostGroup))
//        label.addGestureRecognizer(gestureRecognizer)
        
        let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)])
        label.attributedText = attributedText
        
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
        
        let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
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
        button.isHidden = true
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
        label.setTitle("Show More", for: .normal)
        label.contentHorizontalAlignment = .left
        label.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private lazy var newCommentButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(.white, for: .normal)
        label.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        label.setTitle("Comment", for: .normal)
        label.contentHorizontalAlignment = .left
        label.addTarget(self, action: #selector(handleComment), for: .touchUpInside)
        label.isUserInteractionEnabled = true
        return label
    }()

    let padding: CGFloat = 12
    
    private let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0, alpha: 1)
        return iv
    }()
    
    private let coverView: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 250))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 0)
        return backgroundView
    }()
    
    private let upperCoverView: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 350))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 0)
        return backgroundView
    }()
    
    private lazy var optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("•••", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleOptionsTap), for: .touchUpInside)
        return button
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
        addSubview(optionsButton)
        optionsButton.anchor(top: topAnchor, right: rightAnchor, paddingTop: padding + 6 + padding + 110, paddingRight: padding)
        
        addSubview(viewCountLabel)
        viewCountLabel.anchor(top: topAnchor, right: rightAnchor, paddingTop: padding + 6 + padding + 80, paddingRight: padding)
        
        addSubview(viewButton)
        viewButton.anchor(top: topAnchor, right: viewCountLabel.leftAnchor, paddingTop: padding + 5 + padding + 80, paddingRight: padding)
        
        addSubview(timeLabel)
        timeLabel.anchor(bottom:bottomAnchor, right: rightAnchor, paddingBottom: padding + 50, paddingRight: padding)
        
        addSubview(commentsButton)
        commentsButton.anchor(left: leftAnchor, bottom:bottomAnchor, paddingLeft: padding, paddingBottom: padding + 50, paddingRight: padding)
        
        addSubview(newCommentButton)
        newCommentButton.anchor(left: leftAnchor, bottom:bottomAnchor, paddingLeft: padding + 100, paddingBottom: padding + 50, paddingRight: padding)
        
        addSubview(postedByLabel)
        postedByLabel.anchor(bottom: commentsButton.topAnchor, right: rightAnchor, paddingLeft: padding, paddingBottom: padding - 12, paddingRight: padding - 8)
        
        addSubview(commentsLabel)
        commentsLabel.anchor(left: leftAnchor, bottom:postedByLabel.topAnchor, right: rightAnchor, paddingLeft: padding, paddingBottom: padding - 5, paddingRight: padding)
         
        addSubview(captionLabel)
        captionLabel.anchor(left: leftAnchor, bottom: commentsLabel.topAnchor, right: rightAnchor, paddingLeft: padding, paddingBottom: padding - 5, paddingRight: padding - 8)
        
        coverView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        coverView.layer.cornerRadius = 0
        coverView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 210, width: UIScreen.main.bounds.width, height: 250)
        insertSubview(coverView, at: 0)
        
        upperCoverView.heightAnchor.constraint(equalToConstant: 350).isActive = true
        upperCoverView.layer.cornerRadius = 0
        upperCoverView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 350)
        insertSubview(upperCoverView, at: 0)
        
        photoImageView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        photoImageView.layer.cornerRadius = 5
        photoImageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        photoImageView.center = CGPoint(x: UIScreen.main.bounds.width  / 2, y: UIScreen.main.bounds.height / 2)
        insertSubview(photoImageView, at: 0)
        configurePost()
    }
    
    private func configurePost() {
        guard let groupPost = groupPost else { return }
        setupAttributedCaption(groupPost: groupPost)
        setupGroupPoster(groupPost: groupPost)
        setupTimeLabel(groupPost: groupPost)
        photoImageView.loadImageWithCompletion(urlString: groupPost.imageUrl, completion: { () in
            self.setImageDimensions()
        })
        
        self.viewButton.isHidden = true
        let attributedText = NSAttributedString(string: "", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.white])
        viewCountLabel.attributedText = attributedText
        
        // need to set dimensions again in case the image is already loaded
        setImageDimensions()
        delegate?.didView(groupPost: groupPost)
    }
    
    private func setImageDimensions(){
        let width = self.photoImageView.image?.size.width
        let height = self.photoImageView.image?.size.height
        if width != nil && height != nil {
            if width! >= height! {
                self.photoImageView.contentMode = .scaleToFill
                self.photoImageView.frame.size.width = UIScreen.main.bounds.width - 20
                self.photoImageView.frame.size.height = self.photoImageView.frame.size.width * (height!/width!)
                self.photoImageView.frame.origin.y = (UIScreen.main.bounds.height - self.photoImageView.frame.size.height) / 2
                self.photoImageView.frame.origin.x = 10
            }
            else {
                self.photoImageView.contentMode = .scaleAspectFill
                self.photoImageView.frame.size.height = UIScreen.main.bounds.height
                self.photoImageView.frame.origin.y = 0
                self.photoImageView.frame.size.width = UIScreen.main.bounds.width
                self.photoImageView.frame.origin.x = 0
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            // could also use touches for going to user profile maybe
            let position = touch.location(in: self.photoImageView)
            if position.y > 0 {
                if position.x > self.photoImageView.frame.size.width / 2 {
                    delegate?.goToImage(for: self, isRight: true)
                }
                else {
                    delegate?.goToImage(for: self, isRight: false)
                }
            }
        }
    }
    
    private func setupGroupPoster(groupPost: GroupPost) {
        Database.database().isInGroup(groupId: groupPost.group.groupId, completion: { (inGroup) in
            if inGroup {
                let attributedText = NSMutableAttributedString(string: "Posted by " + groupPost.user.username, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)])
                self.postedByLabel.attributedText = attributedText
            }
            else{
                let attributedText = NSMutableAttributedString(string: "", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 0)])
                self.postedByLabel.attributedText = attributedText
            }
        }) { (err) in
            return
        }
    }
    
    private func setupAttributedCaption(groupPost: GroupPost) {
        let attributedText = NSMutableAttributedString(string: groupPost.group.groupname, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16)])
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
    }
    
    private func setupViewsButton(viewsCount: Int) {
        setupViewCountLabel(viewsCount: viewsCount)
        self.viewButton.isHidden = false
    }
    
    private func configureCommentButton(numComments: Int){
        if numComments < 1{
            self.commentsButton.setTitle("Comment", for: .normal)
            self.commentsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
            self.commentsButton.setTitleColor(.white, for: .normal)
            self.newCommentButton.isUserInteractionEnabled = false
            self.newCommentButton.isHidden = true
        }
        else if numComments == 1{
            self.commentsButton.setTitle("Comment", for: .normal)
            self.commentsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
            self.commentsButton.setTitleColor(.white, for: .normal)
            self.newCommentButton.isUserInteractionEnabled = false
            self.newCommentButton.isHidden = true
        }
        else if numComments > 1{
            self.commentsButton.setTitle("Show More", for: .normal)
            self.commentsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            self.commentsButton.setTitleColor(.white, for: .normal)
            self.newCommentButton.isUserInteractionEnabled = true
            self.newCommentButton.isHidden = false
        }
    }
    
    private func setupTimeLabel(groupPost: GroupPost) {
        let timeAgoDisplay = groupPost.creationDate.timeAgoDisplay()
        let attributedText = NSAttributedString(string: timeAgoDisplay, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.white])
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
