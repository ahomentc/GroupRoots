//
//  CommentInputAccessoryView.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 8/4/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import FirebaseDatabase

protocol CommentInputAccessoryViewDelegate {
    func didSubmit(comment: String)
    func didChangeAtStatus(isInAt: Bool)
    func displaySearchUsers(users: [User])
    func submitAtUsers(users: [User])
}

class CommentInputAccessoryView: UIView, UITextViewDelegate {
    
    var delegate: CommentInputAccessoryViewDelegate?

    private let commentTextView: PlaceholderTextView = {
        let tv = PlaceholderTextView()
        tv.placeholderLabel.text = "Add a comment..."
        tv.isScrollEnabled = false
        tv.font = UIFont.systemFont(ofSize: 18)
        tv.keyboardType = .twitter
//        tv.autocorrectionType = .no
        return tv
    }()
    
    private let submitButton: UIButton = {
        let sb = UIButton(type: .system)
        sb.setTitle("Submit", for: .normal)
        sb.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        sb.setTitleColor(.lightGray, for: .normal)
        sb.addTarget(self, action: #selector(handleSubmit), for: .touchUpInside)
        sb.isEnabled = false
        return sb
    }()
    
    override var intrinsicContentSize: CGSize { return .zero }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        backgroundColor = .white
        autoresizingMask = .flexibleHeight
        
        addSubview(submitButton)
        submitButton.anchor(top: safeAreaLayoutGuide.topAnchor, right: rightAnchor, paddingRight: 12, width: 50, height: 50)
        
        addSubview(commentTextView)
        commentTextView.anchor(top: safeAreaLayoutGuide.topAnchor, left: safeAreaLayoutGuide.leftAnchor, bottom: safeAreaLayoutGuide.bottomAnchor, right: submitButton.leftAnchor, paddingTop: 8, paddingLeft: 12, paddingBottom: 8)
        
        let lineSeparatorView = UIView()
        lineSeparatorView.backgroundColor = UIColor.init(white: 0.7, alpha: 1)
        addSubview(lineSeparatorView)
        lineSeparatorView.anchor(top: topAnchor, left: leftAnchor, right: rightAnchor, height: 0.5)
                
        NotificationCenter.default.addObserver(self, selector: #selector(handleTextChange), name: UITextView.textDidChangeNotification, object: nil)
    }
    
    public func addAtUser(username: String){
        DispatchQueue.main.async {
            self.commentTextView.becomeFirstResponder()
            if username != "" && !username.contains(".") && !username.contains("#") {
                Database.database().fetchUserFromUsername(username: username, completion: { (user) in
                    if !self.atUsers.contains(user) {
                        self.atUsers.append(user)
                    }
                })
            }
            self.commentTextView.placeholderLabel.isHidden = true
            self.commentTextView.text = "@" + username + " "
        }
    }
    
    func clearCommentTextField() {
        commentTextView.text = nil
        commentTextView.showPlaceholderLabel()
        submitButton.isEnabled = false
        submitButton.setTitleColor(.lightGray, for: .normal)
    }
    
    func replaceWithUsername(username: String) {
        guard let text = commentTextView.text else { return }
        var seperatedTextArr = text.components(separatedBy: " ")
        let lastWord = seperatedTextArr.last
        if lastWord != nil && lastWord?.first == "@" {
            seperatedTextArr.removeLast()
            seperatedTextArr.append("@" + username + " ")
            let to_replace = seperatedTextArr.joined(separator: " ")
            commentTextView.text = to_replace
            commentTextView.text = to_replace // need to do this again because autocorrect will mess it up the first time if it appears
            delegate?.didChangeAtStatus(isInAt: false)
            self.commentTextView.becomeFirstResponder()
            if username != "" && !username.contains(".") && !username.contains("#") {
                Database.database().fetchUserFromUsername(username: username, completion: { (user) in
                    if !self.atUsers.contains(user) {
                        self.atUsers.append(user)
                    }
                })
            }
        }
    }
    
    @objc private func handleSubmit() {
        guard let commentText = commentTextView.text else { return }
        checkForAtInput(text: commentText + " ", submitAfterCheck: true)
        commentTextView.resignFirstResponder()
        delegate?.didSubmit(comment: commentText)
    }
    

    var atUsers = [User]()
    func checkForAtInput(text: String, submitAfterCheck: Bool){
        if text.last != nil {
            let lastChar = text.last!
            if lastChar == " " {
                // user has entered the full username without search
                delegate?.didChangeAtStatus(isInAt: false)
                var seperatedTextArr = text.components(separatedBy: " ")
                seperatedTextArr.removeLast()
                let lastWord = seperatedTextArr.last
                if lastWord == nil || lastWord?.first != "@" {
                    if submitAfterCheck {
                        self.submitAts()
                    }
                    return
                }
                let username = lastWord!.trimmingCharacters(in: .whitespaces).removeCharacters(from: "@")
                if username != "" && !username.contains(".") && !username.contains("#") {
                    Database.database().fetchUserFromUsername(username: username, completion: { (user) in
                        if !self.atUsers.contains(user) {
                            self.atUsers.append(user)
                        }
                        
                        if submitAfterCheck {
                            self.submitAts()
                        }
                    })
                }
                else if submitAfterCheck {
                    self.submitAts()
                }
            }
            else {
                // user is still typing the @
                // implement search for user here
                
                // when doing search, do a search through the users that you follow first
                // and then add the rest of regular search
                // for now can just do regular search only
                
                let seperatedTextArr = text.components(separatedBy: " ")
                let lastWord = seperatedTextArr.last
                if lastWord == nil || lastWord?.first != "@"{
                    delegate?.didChangeAtStatus(isInAt: false)
                    return
                }
                delegate?.didChangeAtStatus(isInAt: true)
                let searchTerm = lastWord!.trimmingCharacters(in: .whitespaces).removeCharacters(from: "@")
                searchForUser(username: searchTerm)
            }
        }
        else {
            delegate?.didChangeAtStatus(isInAt: false)
        }
    }
    
    private func searchForUser(username: String){
        if username.range(of: #"^[a-zA-Z0-9_-]*$"#, options: .regularExpression) == nil || username == "" {
            return
        }
        if username != "" && !username.contains(".") && !username.contains("#") {
            var filteredUsers = [User]()
            Database.database().searchForUsers(username: username, completion: { (users) in
                filteredUsers = users
                Database.database().searchForUsers(username: username.lowercased(), completion: { (lowercase_users) in
                    for user in lowercase_users {
                        if !filteredUsers.contains(user) {
                            filteredUsers.append(user)
                        }
                    }
                    Database.database().searchForUsers(username: username.capitalizingFirstLetter(), completion: { (first_capitalized_users) in
                        for user in first_capitalized_users {
                            if !filteredUsers.contains(user) {
                                filteredUsers.append(user)
                            }
                        }
                        self.delegate?.displaySearchUsers(users: filteredUsers)
                    })
                })
            })
        }
    }
    
    func submitAts() {
        var filteredAtUsers = [User]()
        for user in atUsers {
            // this checks to see if any atUsers were deleted while
            // typing the comment
            if !commentTextView.text.contains(user.username) {
                // create a notification for the user
                filteredAtUsers.append(user)
            }
        }
        self.delegate?.submitAtUsers(users: filteredAtUsers)
    }
    
    
    @objc private func handleTextChange() {
        guard let text = commentTextView.text else { return }
        checkForAtInput(text: text, submitAfterCheck: false)
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            submitButton.isEnabled = false
            submitButton.setTitleColor(.lightGray, for: .normal)
        } else {
            submitButton.isEnabled = true
            submitButton.setTitleColor(.black, for: .normal)
        }
    }
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    func removeCharacters(from forbiddenChars: CharacterSet) -> String {
        let passed = self.unicodeScalars.filter { !forbiddenChars.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }

    func removeCharacters(from: String) -> String {
        return removeCharacters(from: CharacterSet(charactersIn: from))
    }
}
