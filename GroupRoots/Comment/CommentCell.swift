//
//  CommentCell.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 8/3/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol CommentCellDelegate {
    func didTapUser(user: User)
}

class CommentCell: UICollectionViewCell, UITextViewDelegate {
    
    var comment: Comment? {
        didSet {
            configureComment()
        }
    }
    
    var delegate: CommentCellDelegate?
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = UIColor.clear
        return textView
    }()
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.isUserInteractionEnabled = true
        iv.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        iv.layer.borderWidth = 0.5
        iv.image = #imageLiteral(resourceName: "user")
        return iv
    }()
    
    static var cellId = "commentCellId"
    
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
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 8, paddingLeft: 8, width: 40, height: 40)
        profileImageView.layer.cornerRadius = 40 / 2
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))

//        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
//            self.addSubview(self.textView)
//            self.textView.anchor(top: self.topAnchor, left: self.profileImageView.rightAnchor, bottom: self.bottomAnchor, right: self.rightAnchor, paddingTop: 4, paddingLeft: 4, paddingBottom: 04, paddingRight: 4)
//        }
        
        self.addSubview(self.textView)
        self.textView.anchor(top: self.topAnchor, left: self.profileImageView.rightAnchor, bottom: self.bottomAnchor, right: self.rightAnchor, paddingTop: 4, paddingLeft: 4, paddingBottom: 4, paddingRight: 4)
        
    }
    
    private func configureComment() {

        guard let comment = comment else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        let usernameText = NSMutableAttributedString(string: comment.user.username, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.black, .paragraphStyle: paragraphStyle])
        usernameText.addAttribute(NSAttributedString.Key.underlineStyle, value: 0, range: NSMakeRange(0,usernameText.length))
        usernameText.addAttribute(NSAttributedString.Key.underlineColor, value: UIColor.black, range: NSMakeRange(0, usernameText.length))
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(comment.user)
            let data_string = String(data: data, encoding: .utf8)
            usernameText.addAttribute(NSAttributedString.Key.link, value: data_string?.toBase64() ?? "", range: NSMakeRange(0,usernameText.length))
        } catch {
            print("Whoops, an error occured: \(error)")
        }
        
        let attributedText = usernameText
        
        let seperatedTextArr = comment.text.components(separatedBy: " ")
        var wordOrderDict = [Int: NSMutableAttributedString]()
        let sync = DispatchGroup()
        sync.enter()
        for (i, word) in seperatedTextArr.enumerated() {
            if word.count > 0 {
                sync.enter()
                
                let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                let matches = detector.matches(in: word, options: [], range: NSRange(location: 0, length: word.utf16.count))
                var url = ""
                for match in matches {
                    guard let range = Range(match.range, in: word) else { continue }
                    url = String(word[range])
                    break
                }
                
                if url != "" {
                    let selectablePart = NSMutableAttributedString(string: " " + word)
                    selectablePart.addAttribute(NSAttributedString.Key.font, value: UIFont.boldSystemFont(ofSize: 14), range: NSMakeRange(0, selectablePart.length))
                    // Add an underline to indicate this portion of text is selectable (optional)
                    selectablePart.addAttribute(NSAttributedString.Key.underlineStyle, value: 0, range: NSMakeRange(0,selectablePart.length))
                    selectablePart.addAttribute(NSAttributedString.Key.underlineColor, value: UIColor.black, range: NSMakeRange(0, selectablePart.length))
                    selectablePart.addAttribute(NSAttributedString.Key.link, value: url, range: NSMakeRange(0,selectablePart.length))
                    wordOrderDict[i] = selectablePart
                    sync.leave()
                }
                else if word[word.startIndex] == "@" {
                    let username = word.trimmingCharacters(in: .whitespaces).removeCharacters(from: "@")
                    if username.range(of: #"^[a-zA-Z0-9_-]*$"#, options: .regularExpression) != nil && username != "" && !username.contains(".") && !username.contains("#") {
                        Database.database().usernameExists(username: username, completion: { (exists) in
                            if exists{
                                Database.database().fetchUserFromUsername(username: username, completion: { (user) in
                                    do {
                                        let encoder = JSONEncoder()
                                        let data = try encoder.encode(user)
                                        let data_string = String(data: data, encoding: .utf8)
                                        let selectablePart = NSMutableAttributedString(string: " " + word)
                                        selectablePart.addAttribute(NSAttributedString.Key.font, value: UIFont.boldSystemFont(ofSize: 14), range: NSMakeRange(0, selectablePart.length))
                                        // Add an underline to indicate this portion of text is selectable (optional)
                                        selectablePart.addAttribute(NSAttributedString.Key.underlineStyle, value: 0, range: NSMakeRange(0,selectablePart.length))
                                        selectablePart.addAttribute(NSAttributedString.Key.underlineColor, value: UIColor.black, range: NSMakeRange(0, selectablePart.length))
                                        selectablePart.addAttribute(NSAttributedString.Key.link, value: data_string?.toBase64() ?? "", range: NSMakeRange(0,selectablePart.length))
                                        wordOrderDict[i] = selectablePart
                                        sync.leave()
                                    } catch {
                                        sync.leave()
                                        print("Whoops, an error occured: \(error)")
                                    }
                                })
                            }
                            else {
                                let selectablePart = NSMutableAttributedString(string: " " + word)
                                selectablePart.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14), range: NSMakeRange(0, selectablePart.length))
                                wordOrderDict[i] = selectablePart
                                sync.leave()
                            }
                        })
                    }
                    else {
                        sync.leave()
                    }
                }
                else { //regular
                    let attributed_text = NSMutableAttributedString(string: " " + word, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.black])
                    wordOrderDict[i] = attributed_text
                    sync.leave()
                }
                // also add something for actual link
            }
        }
        sync.leave()
        
        sync.notify(queue: .main) {
            for (i, _) in seperatedTextArr.enumerated(){
                attributedText.append(wordOrderDict[i] ?? NSMutableAttributedString(string: ""))
            }
            attributedText.append(NSMutableAttributedString(string: "\n\n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 4), NSAttributedString.Key.foregroundColor: UIColor.black]))
            
            let timeAgoDisplay = comment.creationDate.timeAgoDisplayShort()
            attributedText.append(NSMutableAttributedString(string: timeAgoDisplay, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.gray]))
            
            self.textView.attributedText = attributedText
        }
        self.textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        self.textView.isUserInteractionEnabled = true
        self.textView.isEditable = false
        self.textView.isSelectable = true
        self.textView.delegate = self
        
        let attributedText2 = NSMutableAttributedString(string: comment.user.username, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.black])
        attributedText2.append(NSAttributedString(string: " " + comment.text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.black]))
        attributedText2.append(NSAttributedString(string: "\n\n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 4), NSAttributedString.Key.foregroundColor: UIColor.black]))
        let timeAgoDisplay2 = comment.creationDate.timeAgoDisplayShort()
        attributedText2.append(NSAttributedString(string: timeAgoDisplay2, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.gray]))
        self.textView.attributedText = attributedText2
        
        if let profileImageUrl = comment.user.profileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        } else {
            profileImageView.image = #imageLiteral(resourceName: "user")
        }
    }
    
    @objc private func handleTap() {
        guard let user = comment?.user else { return }
        delegate?.didTapUser(user: user)
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
