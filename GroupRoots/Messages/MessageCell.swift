//
//  MessageCell.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/4/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

protocol MessageCellDelegate {
    func didTapUser(user: User)
    func didTapReply(username: String)
}

class MessageCell: UICollectionViewCell, UITextViewDelegate {
    
    var comment: Comment? {
        didSet {
            configureComment()
        }
    }
    
    var hasPrev: Bool? {
        didSet {
            configureComment()
        }
    }
    
    var hasNext: Bool? {
        didSet {
            configureComment()
        }
    }
    
    var bubble_height = CGFloat(0)
    
    var delegate: MessageCellDelegate?
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.layer.zPosition = 16
        return textView
    }()
    
    private let incomingProfileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.isUserInteractionEnabled = true
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        iv.layer.zPosition = 16
        iv.image = #imageLiteral(resourceName: "user")
        iv.isHidden = true
        return iv
    }()
    
//    private let outgoingProfileImageView: CustomImageView = {
//        let iv = CustomImageView()
//        iv.clipsToBounds = true
//        iv.contentMode = .scaleAspectFill
//        iv.isUserInteractionEnabled = true
//        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
//        iv.layer.borderWidth = 0.5
//        iv.layer.zPosition = 16
//        iv.image = #imageLiteral(resourceName: "user")
//        iv.isHidden = true
//        return iv
//    }()
    
    private lazy var incomingUsernameButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(.white, for: .normal)
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        label.setTitle("", for: .normal)
        label.layer.zPosition = 4;
        label.contentHorizontalAlignment = .left
        label.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        label.isUserInteractionEnabled = true
        label.isHidden = true
        return label
    }()
    
    private lazy var incomingTimeButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(UIColor.init(white: 0.6, alpha: 1), for: .normal)
        label.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        label.setTitle("", for: .normal)
        label.layer.zPosition = 4;
        label.isUserInteractionEnabled = false
        label.contentHorizontalAlignment = .left
        label.isHidden = true
        return label
    }()
    
    private lazy var usernameButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(.white, for: .normal)
        label.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        label.setTitle("", for: .normal)
        label.layer.zPosition = 4;
        label.contentHorizontalAlignment = .left
        label.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        label.isUserInteractionEnabled = true
        label.isHidden = true
        return label
    }()
    
    private lazy var outgoingTimeButton: UIButton = {
        let label = UIButton(type: .system)
        label.setTitleColor(UIColor.init(white: 0.6, alpha: 1), for: .normal)
        label.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        label.setTitle("", for: .normal)
        label.layer.zPosition = 4;
        label.isUserInteractionEnabled = false
        label.contentHorizontalAlignment = .left
        label.isHidden = true
        return label
    }()
    
    static var cellId = "commentCellId"
    
    var addedViews = [UIView]()
    var addedLayers = [CAShapeLayer]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
//        self.backgroundColor = .random
//        self.layer.backgroundColor = UIColor.random.cgColor
        
//        self.insertSubview(outgoingProfileImageView, at: 21)
//        outgoingProfileImageView.anchor(bottom: bottomAnchor, right: rightAnchor, paddingBottom: 0, paddingRight: 8, width: 40, height: 40)
//        outgoingProfileImageView.layer.cornerRadius = 40 / 2
//        outgoingProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        self.insertSubview(incomingProfileImageView, at: 21)
        incomingProfileImageView.anchor(left: leftAnchor, bottom: bottomAnchor, paddingLeft: 8, paddingBottom: 0, width: 40, height: 40)
        incomingProfileImageView.layer.cornerRadius = 40 / 2
        incomingProfileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        
        self.insertSubview(incomingUsernameButton, at: 21)
        incomingUsernameButton.anchor(top: topAnchor, left: leftAnchor, paddingTop: 10, paddingLeft: 65, height: 30)
        
        self.insertSubview(incomingTimeButton, at: 21)
        incomingTimeButton.anchor(top: topAnchor, left: incomingUsernameButton.rightAnchor, paddingTop: 10, paddingLeft: 10, height: 30)
        
        self.insertSubview(outgoingTimeButton, at: 21)
        outgoingTimeButton.anchor(top: topAnchor, right: rightAnchor, paddingTop: 10, paddingRight: 20, height: 30)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        comment = nil
        hasPrev = nil
        hasNext = nil
        incomingProfileImageView.isHidden = true
//        outgoingProfileImageView.isHidden = true
        incomingUsernameButton.isHidden = true
        incomingTimeButton.isHidden = true
        outgoingTimeButton.isHidden = true
        clearMessage()
    }
    
    func clearMessage() {
        for view in addedViews {
            view.removeFromSuperview()
        }
        for layer in addedLayers {
            layer.removeFromSuperlayer()
        }
    }
    
    func showIncomingMessage(text: String) {
        guard let hasPrev = hasPrev else { return }
        guard let hasNext = hasNext else { return }
        
        let label =  UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
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

        let bubble_width = bubbleSize.width
        let bubble_height = bubbleSize.height
        self.bubble_height = bubble_height
        
        let bezierPath = UIBezierPath()
        if hasNext {
            bezierPath.move(to: CGPoint(x: 21, y: bubble_height))
            bezierPath.addLine(to: CGPoint(x: bubble_width - 17, y: bubble_height))
            bezierPath.addCurve(to: CGPoint(x: bubble_width, y: bubble_height - 17), controlPoint1: CGPoint(x: bubble_width - 7.61, y: bubble_height), controlPoint2: CGPoint(x: bubble_width, y: bubble_height - 7.61))
            bezierPath.addLine(to: CGPoint(x: bubble_width, y: 17))
            bezierPath.addCurve(to: CGPoint(x: bubble_width - 17, y: 0), controlPoint1: CGPoint(x: bubble_width, y: 7.61), controlPoint2: CGPoint(x: bubble_width - 7.61, y: 0))
            bezierPath.addLine(to: CGPoint(x: 21, y: 0))
            bezierPath.addCurve(to: CGPoint(x: 4, y: 17), controlPoint1: CGPoint(x: 11.61, y: 0), controlPoint2: CGPoint(x: 4, y: 7.61))
            bezierPath.addLine(to: CGPoint(x: 4, y: bubble_height - 17))
            bezierPath.addCurve(to: CGPoint(x: 21, y: bubble_height), controlPoint1: CGPoint(x: 4, y: bubble_height - 7.61), controlPoint2: CGPoint(x: 11.61, y: bubble_height))
            bezierPath.close()
        }
        else {
            bezierPath.move(to: CGPoint(x: 22, y: bubble_height))
            bezierPath.addLine(to: CGPoint(x: bubble_width - 17, y: bubble_height))
            bezierPath.addCurve(to: CGPoint(x: bubble_width, y: bubble_height - 17), controlPoint1: CGPoint(x: bubble_width - 7.61, y: bubble_height), controlPoint2: CGPoint(x: bubble_width, y: bubble_height - 7.61))
            bezierPath.addLine(to: CGPoint(x: bubble_width, y: 17))
            bezierPath.addCurve(to: CGPoint(x: bubble_width - 17, y: 0), controlPoint1: CGPoint(x: bubble_width, y: 7.61), controlPoint2: CGPoint(x: bubble_width - 7.61, y: 0))
            bezierPath.addLine(to: CGPoint(x: 21, y: 0))
            bezierPath.addCurve(to: CGPoint(x: 4, y: 17), controlPoint1: CGPoint(x: 11.61, y: 0), controlPoint2: CGPoint(x: 4, y: 7.61))
            bezierPath.addLine(to: CGPoint(x: 4, y: bubble_height - 11))
            bezierPath.addCurve(to: CGPoint(x: 0, y: bubble_height), controlPoint1: CGPoint(x: 4, y: bubble_height - 1), controlPoint2: CGPoint(x: 0, y: bubble_height))
            bezierPath.addLine(to: CGPoint(x: -0.05, y: bubble_height - 0.01))
            bezierPath.addCurve(to: CGPoint(x: 11.04, y: bubble_height - 4.04), controlPoint1: CGPoint(x: 4.07, y: bubble_height + 0.43), controlPoint2: CGPoint(x: 8.16, y: bubble_height - 1.06))
            bezierPath.addCurve(to: CGPoint(x: 22, y: bubble_height), controlPoint1: CGPoint(x: 16, y: bubble_height), controlPoint2: CGPoint(x: 19, y: bubble_height))
            bezierPath.close()
        }

        let incomingMessageLayer = CAShapeLayer()
        incomingMessageLayer.path = bezierPath.cgPath
        incomingMessageLayer.fillColor = UIColor.init(white: 0.2, alpha: 1).cgColor
        incomingMessageLayer.zPosition = 14
        if hasPrev {
            incomingMessageLayer.frame = CGRect(x: 50, y: 5, width: bubble_width, height: bubble_height)
        }
        else {
            incomingMessageLayer.frame = CGRect(x: 50, y: 35, width: bubble_width, height: bubble_height)
        }

        layer.insertSublayer(incomingMessageLayer, at: 20)
        label.layer.zPosition = 15
        layer.addSublayer(incomingMessageLayer)
        
        
        if hasPrev {
            label.frame = CGRect(x: 65, y: 15, width: ceil(boundingBox.width), height: ceil(boundingBox.height))
        }
        else {
            label.frame = CGRect(x: 65, y: 45, width: ceil(boundingBox.width), height: ceil(boundingBox.height))
        }
        insertSubview(label, at: 21)
//        insertSubview(label, at: 21)
        
        addedLayers.append(incomingMessageLayer)
        addedViews.append(label)
    }
    
    func showOutgoingMessage(text: String) {
        guard let hasPrev = hasPrev else { return }
        guard let hasNext = hasNext else { return }
        
        let label =  UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
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

        let bubble_width = bubbleSize.width
        let bubble_height = bubbleSize.height
        self.bubble_height = bubble_height

        let bezierPath = UIBezierPath()
        if hasNext {
            bezierPath.move(to: CGPoint(x: bubble_width - 22, y: bubble_height))
            bezierPath.addLine(to: CGPoint(x: 17, y: bubble_height))
            bezierPath.addCurve(to: CGPoint(x: 0, y: bubble_height - 17), controlPoint1: CGPoint(x: 7.61, y: bubble_height), controlPoint2: CGPoint(x: 0, y: bubble_height - 7.61))
            bezierPath.addLine(to: CGPoint(x: 0, y: 17))
            bezierPath.addCurve(to: CGPoint(x: 17, y: 0), controlPoint1: CGPoint(x: 0, y: 7.61), controlPoint2: CGPoint(x: 7.61, y: 0))
            bezierPath.addLine(to: CGPoint(x: bubble_width - 22, y: 0))
            bezierPath.addCurve(to: CGPoint(x: bubble_width - 4, y: 22), controlPoint1: CGPoint(x: bubble_width - 11.61, y: 0), controlPoint2: CGPoint(x: bubble_width - 4, y: 7.61))
            bezierPath.addLine(to: CGPoint(x: bubble_width - 4, y: bubble_height - 22))
            bezierPath.addCurve(to: CGPoint(x: bubble_width - 22, y: bubble_height), controlPoint1: CGPoint(x: bubble_width - 4, y: bubble_height - 7.61), controlPoint2: CGPoint(x: bubble_width - 11.61, y: bubble_height))
            bezierPath.close()
        }
        else {
            bezierPath.move(to: CGPoint(x: bubble_width - 22, y: bubble_height))
            bezierPath.addLine(to: CGPoint(x: 17, y: bubble_height))
            bezierPath.addCurve(to: CGPoint(x: 0, y: bubble_height - 17), controlPoint1: CGPoint(x: 7.61, y: bubble_height), controlPoint2: CGPoint(x: 0, y: bubble_height - 7.61))
            bezierPath.addLine(to: CGPoint(x: 0, y: 17))
            bezierPath.addCurve(to: CGPoint(x: 17, y: 0), controlPoint1: CGPoint(x: 0, y: 7.61), controlPoint2: CGPoint(x: 7.61, y: 0))
            bezierPath.addLine(to: CGPoint(x: bubble_width - 21, y: 0))
            bezierPath.addCurve(to: CGPoint(x: bubble_width - 4, y: 17), controlPoint1: CGPoint(x: bubble_width - 11.61, y: 0), controlPoint2: CGPoint(x: bubble_width - 4, y: 7.61))
            bezierPath.addLine(to: CGPoint(x: bubble_width - 4, y: bubble_height - 11))
            bezierPath.addCurve(to: CGPoint(x: bubble_width, y: bubble_height), controlPoint1: CGPoint(x: bubble_width - 4, y: bubble_height - 1), controlPoint2: CGPoint(x: bubble_width, y: bubble_height))
            bezierPath.addLine(to: CGPoint(x: bubble_width + 0.05, y: bubble_height - 0.01))
            bezierPath.addCurve(to: CGPoint(x: bubble_width - 11.04, y: bubble_height - 4.04), controlPoint1: CGPoint(x: bubble_width - 4.07, y: bubble_height + 0.43), controlPoint2: CGPoint(x: bubble_width - 8.16, y: bubble_height - 1.06))
            bezierPath.addCurve(to: CGPoint(x: bubble_width - 22, y: bubble_height), controlPoint1: CGPoint(x: bubble_width - 16, y: bubble_height), controlPoint2: CGPoint(x: bubble_width - 19, y: bubble_height))
            bezierPath.close()
        }


        let outgoingMessageLayer = CAShapeLayer()
        outgoingMessageLayer.path = bezierPath.cgPath
        outgoingMessageLayer.fillColor = UIColor(red: 38/255, green: 118/255, blue: 255/255, alpha: 1).cgColor
        outgoingMessageLayer.zPosition = 14
        
        if hasPrev {
            outgoingMessageLayer.frame = CGRect(x: frame.width - bubble_width - 20 + 5, y: 5, width: bubble_width, height: bubble_height)
        }
        else {
            outgoingMessageLayer.frame = CGRect(x: frame.width - bubble_width - 20 + 5, y: 35, width: bubble_width, height: bubble_height)
        }

        layer.insertSublayer(outgoingMessageLayer, at: 20)
        label.layer.zPosition = 15
        layer.addSublayer(outgoingMessageLayer)
        
        if hasPrev {
            label.frame = CGRect(x: frame.width - bubble_width - 9 + 5, y: 15, width: ceil(boundingBox.width), height: ceil(boundingBox.height))
        }
        else {
            label.frame = CGRect(x: frame.width - bubble_width - 9 + 5, y: 45, width: ceil(boundingBox.width), height: ceil(boundingBox.height))
        }
        insertSubview(label, at: 21)
//        insertSubview(label, at: 21)
        
        addedLayers.append(outgoingMessageLayer)
        addedViews.append(label)
    }
    
    private func configureComment() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let comment = comment else { return }
        guard let hasPrev = hasPrev else { return }
        guard let hasNext = hasNext else { return }
        
        self.clearMessage()
        
        incomingUsernameButton.setTitle(comment.user.username, for: .normal)
        usernameButton.setTitle(comment.user.username, for: .normal)
        
        let timeAgoDisplay = comment.creationDate.timeAgoDisplayShort()
        outgoingTimeButton.setTitle(timeAgoDisplay, for: .normal)
        incomingTimeButton.setTitle(timeAgoDisplay, for: .normal)
        
        if comment.user.uid == currentLoggedInUserId {
            self.showOutgoingMessage(text: comment.text)
            
            if !hasNext {
//                self.outgoingProfileImageView.isHidden = false
            }
            if !hasPrev {
                self.outgoingTimeButton.isHidden = false
            }
            
        }
        else {
            self.showIncomingMessage(text: comment.text)
            
            if !hasNext {
                self.incomingProfileImageView.isHidden = false
            }
            
            if !hasPrev {
                self.incomingUsernameButton.isHidden = false
                self.incomingTimeButton.isHidden = false
            }
        }
        
        if comment.user.uid == "bot" {
            incomingProfileImageView.image = #imageLiteral(resourceName: "bot_icon")
        }
        else {
            if let profileImageUrl = comment.user.profileImageUrl {
                self.incomingProfileImageView.loadImage(urlString: profileImageUrl)
            } else {
                self.incomingProfileImageView.image = #imageLiteral(resourceName: "user")
            }
        }
    }
    
    @objc private func handleTap() {
        guard let user = comment?.user else { return }
        if user.uid != "bot" {
            delegate?.didTapUser(user: user)
        }
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL_Interacted: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        // first detect a URL
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let word = URL_Interacted.absoluteString
        let matches = detector.matches(in: word, options: [], range: NSRange(location: 0, length: word.utf16.count))
        if matches.count > 0 {
            return true
        }
        else {
            // check if reply string
            if URL_Interacted.absoluteString.contains("reply_") {
                let username = URL_Interacted.absoluteString.replacingOccurrences(of: "reply_", with: "")
                self.delegate?.didTapReply(username: username)
            }
            
            let data_string = URL_Interacted.absoluteString.fromBase64()
            let data = data_string?.data(using: .utf8)
            if data == nil { return false }
            let decoder = JSONDecoder()
            do {
                let user = try decoder.decode(User.self, from: data!)
                self.delegate?.didTapUser(user: user)
            }
            catch {
                print("there was an error")
            }
        }
        return false
    }
}


extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}
