//
//  InstaPromoController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 12/28/20.
//  Copyright © 2020 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import Photos
import NVActivityIndicatorView

// database architecture:
// - Recieve insta dm with picture
// - Update "/promos/{school}/postedToInsta with value = { username: 50 }
// - Update "/promos/{school}/currentInstaPayout" based on size of completedInstaPromo... cloud function. Starts at 50

// Extra:
// - Allowed Schools: "/ActivePromos/{school}/[true or false]

class InstaPromoController: UIViewController {
    
    var group: Group? {
        didSet {
            // not very good but here is how this works
            // instead of calling setupPromo here too, we just assume that
            // group will be set by the time its used
            // This is because sometimes group won't be set since we can get groups[0] of user's groups
        }
    }
    
    var school: String? {
        didSet {
            self.setupPromo()
        }
    }
    
    var isJoin: Bool? {
        didSet {
            self.setupPromo()
        }
    }
    
    var wasNavPushed: Bool? {
        didSet{
            guard let wasNavPushed = wasNavPushed else { return }
            if wasNavPushed {
                NotificationCenter.default.post(name: NSNotification.Name("tabBarClear"), object: nil)
            }
        }
    }
    
    let activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width/2 - 35, y: UIScreen.main.bounds.height/2 - 35, width: 70, height: 70), type: NVActivityIndicatorType.circleStrokeSpin)
    
    private lazy var explainPromoLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.textAlignment = .center
//        let attributedText = NSMutableAttributedString(string: "Share this picture on your Instagram\nStory and tag @srvhs_grouproots", attributes: [NSAttributedString.Key.foregroundColor:UIColor.white, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
//        attributedText.append(NSMutableAttributedString(string: "\n\n(If your Instagram is private, also send a DM to @srvhs_grouproots with a screenshot of your story)", attributes: [NSAttributedString.Key.foregroundColor:UIColor.lightGray, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)]))
//        label.attributedText = attributedText
        return label
    }()
    
    private lazy var savedLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.textAlignment = .center
        let attributedText = NSMutableAttributedString(string: "Saved!", attributes: [NSAttributedString.Key.foregroundColor:UIColor.lightGray, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
        label.attributedText = attributedText
        label.isHidden = true
        return label
    }()
    
    public let promoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = #imageLiteral(resourceName: "story5")
        iv.backgroundColor = UIColor(white: 0, alpha: 1)
        iv.layer.zPosition = 4
        return iv
    }()
    
    private lazy var saveImageButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(saveImage), for: .touchUpInside)
        button.layer.zPosition = 4;
//        button.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        button.backgroundColor = .black
        button.layer.borderWidth = 0
//        button.layer.borderColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1).cgColor
        button.layer.borderColor = UIColor.white.cgColor
//        button.setTitleColor(UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Save Image", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        self.view.backgroundColor = .black
        
        
//        navigationItem.title = "Amazon Code Promo"
        let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18)]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneSelected))
        navigationItem.rightBarButtonItem?.tintColor = .lightGray
        navigationController?.navigationBar.barTintColor = UIColor.init(white: 0.05, alpha: 1)
        
        explainPromoLabel.frame = CGRect(x: 20, y: UIScreen.main.bounds.height/11, width: UIScreen.main.bounds.width - 40, height: 140)
        self.view.insertSubview(explainPromoLabel, at: 4)
        
        promoImageView.layer.cornerRadius = 5
        promoImageView.frame = CGRect(x: UIScreen.main.bounds.width * 0.2, y: UIScreen.main.bounds.height/11 + 140, width: UIScreen.main.bounds.width * 0.6, height: UIScreen.main.bounds.height * 0.6)
        promoImageView.contentMode = .scaleAspectFit
        self.view.insertSubview(promoImageView, at: 2)
        
        saveImageButton.layer.cornerRadius = 12
        self.view.insertSubview(saveImageButton, at: 4)
        saveImageButton.anchor(top: promoImageView.bottomAnchor, left: view.leftAnchor, paddingTop: 5, paddingLeft: UIScreen.main.bounds.width/2-75, width: 150, height: 40)
        
        self.view.insertSubview(savedLabel, at: 4)
        savedLabel.anchor(top: promoImageView.bottomAnchor, left: view.leftAnchor, paddingTop: 5, paddingLeft: UIScreen.main.bounds.width/2-75, width: 150, height: 40)
        
        self.promoImageView.isHidden = true
        activityIndicatorView.isHidden = false
        activityIndicatorView.color = .white
        self.view.insertSubview(activityIndicatorView, at: 20)
        activityIndicatorView.startAnimating()
        
    }
    
    func setupPromo() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let school = school else { return }
        guard let isJoin = isJoin else { return } // is join promo
        
        Database.database().isPromoActive(school: school, completion: { (isActive) in
            
            Database.database().userHasSeenPromoPage(school: school, uid: currentLoggedInUserId) { (err) in }
            
            if isActive {
                if isJoin {
                    let navLabel = UILabel()
                    navLabel.text = "$10 Amazon Code Promo"
                    navLabel.font = UIFont.boldSystemFont(ofSize: 18)
                    navLabel.textColor = .white
                    self.navigationItem.titleView = navLabel
                }
                else {
                    Database.database().fetchSchoolPromoPayout(school: school, completion: { (payout) in
                        let navLabel = UILabel()
                        navLabel.text = "$" + String(payout) + " Amazon Code Promo"
                        navLabel.font = UIFont.boldSystemFont(ofSize: 18)
                        navLabel.textColor = .white
                        self.navigationItem.titleView = navLabel
                    }) { (_) in}
                }
            }
            
            if !isActive {
                self.explainPromoLabel.frame = CGRect(x: 20, y: UIScreen.main.bounds.height/14, width: UIScreen.main.bounds.width - 40, height: 140)
                self.view.insertSubview(self.explainPromoLabel, at: 4)
                
                self.promoImageView.frame = CGRect(x: UIScreen.main.bounds.width * 0.2, y: UIScreen.main.bounds.height/11 + 100, width: UIScreen.main.bounds.width * 0.6, height: UIScreen.main.bounds.height * 0.6)
            }
            
            let school_name = school.replacingOccurrences(of: "_-a-_", with: " ").components(separatedBy: ",")[0]
            let acronym = self.getAcronymFromSchool(name: school_name)
            
            if isActive {
                let attributedText = NSMutableAttributedString(string: "Share this picture on your Instagram\nStory and tag @" + acronym, attributes: [NSAttributedString.Key.foregroundColor:UIColor.white, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
                attributedText.append(NSMutableAttributedString(string: "\n\n(If your Instagram is private, also send a DM to @" + acronym + " with a screenshot of your story)", attributes: [NSAttributedString.Key.foregroundColor:UIColor.lightGray, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)]))
                self.explainPromoLabel.attributedText = attributedText
            }
            else {
                let attributedText = NSMutableAttributedString(string: "Group Reservation Complete!", attributes: [NSAttributedString.Key.foregroundColor:UIColor.white, NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
                self.explainPromoLabel.attributedText = attributedText
            }
            
            let school_lines = self.getLines(text: school_name, maxCharsInLine: 30)
            let school_text = self.convertLinesToString(lines: school_lines)
            let imageWithSchool = self.textToImage(drawText: "Your group is reserved\non GroupRoots for\n" + school_text as NSString, inImage: #imageLiteral(resourceName: "story5"), atPoint: CGPoint(x: 0, y: 150), fontSize: 42, fontColor: .white, shouldCenter: true)
            
            var yForReservedFor = 350
            if school_lines.count > 1 {
                yForReservedFor = 380
            }
            
            let currentLoggedInUserId = Auth.auth().currentUser?.uid ?? ""
            Database.database().fetchAllGroups(withUID: currentLoggedInUserId, completion: { (groups) in
                if groups.count > 0 {
                    var group = groups[0]
                    
                    if self.group != nil {
                        group = self.group!
                    }
                    
                    var names = [String]()
                    Database.database().fetchGroupMembers(groupId: group.groupId, completion: { (members) in
                        members.forEach({ (member) in
                            if member.name != "" {
                                names.append(member.name.capitalized)
                            }
                            else {
                                names.append(member.username)
                            }
                        })
                        let namesInString = self.convertNamesToString(names: names)
                        let reserved_for_lines = self.getLines(text: namesInString, maxCharsInLine: 40)
                        let reserved_for_text = self.convertLinesToString(lines: reserved_for_lines)
                        
                        let imageWithMembers = self.textToImage(drawText: "Reserved for:\n" + reserved_for_text as NSString, inImage: imageWithSchool, atPoint: CGPoint(x: 0, y: yForReservedFor), fontSize: 30, fontColor: .lightGray, shouldCenter: true)
                        
                        Database.database().fetchUser(withUID: currentLoggedInUserId) { (user) in
                            var identifier_text = ""
                            if isJoin {
                                identifier_text = user.username + " join " + school
                            }
                            else {
                                identifier_text = user.username + " " + school
                            }
                            let imageWithUserCode = self.textToImage(drawText: identifier_text as NSString, inImage: imageWithMembers, atPoint: CGPoint(x: 0, y: 1540), fontSize: 12, fontColor: .darkGray, shouldCenter: true)
                            if isActive {
                                self.promoImageView.image = imageWithUserCode
                            }
                            else {
                                self.promoImageView.image = imageWithMembers
                            }
                            self.promoImageView.isHidden = false
                            self.activityIndicatorView.isHidden = true
                        }
                    }) { (_) in}
                }
            }) { (_) in }
        }) { (_) in}
    }
    
    @objc private func doneSelected(){
        if self.wasNavPushed != nil && self.wasNavPushed! == true {
            NotificationCenter.default.post(name: NSNotification.Name("tabBarColor"), object: nil)
            self.navigationController?.popViewController(animated: true)
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func saveImage(){
        UIImageWriteToSavedPhotosAlbum(self.promoImageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
//            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
//            ac.addAction(UIAlertAction(title: "OK", style: .default))
//            present(ac, animated: true)
            self.savedLabel.isHidden = false
            self.saveImageButton.isHidden = true
        }
    }
    
    func showAlertWith(title: String, message: String){
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    func getLines(text: String, maxCharsInLine: Int) -> [String] {
        let words = text.components(separatedBy: " ")
        var lines = [String]()
        
        var currentLine = ""
        
        for word in words {
            let numChars = (currentLine + word).count
            if numChars < maxCharsInLine {
                currentLine += " " + word
            }
            else {
                lines.append(currentLine)
                currentLine = word
            }
        }
        lines.append(currentLine)
        return lines
    }
    
    func convertLinesToString(lines: [String]) -> String {
        var text = ""
        for line in lines {
            text += line + "\n"
        }
        return text
    }
    
    func convertNamesToString(names: [String]) -> String {
        var text = ""
        for name in names {
            text += name + ", "
        }
        return String(text.dropLast(2))
    }
    
    func getAcronymFromSchool(name: String) -> String {
        let arr = name.components(separatedBy: " ")
        var acronym = ""
        for word in arr {
            let firstChar = Array(word.lowercased())[0]
            acronym = acronym + String(firstChar)
        }
        return acronym + "_grouproots"
    }

    func textToImage(drawText: NSString, inImage: UIImage, atPoint: CGPoint, fontSize: Int, fontColor: UIColor, shouldCenter: Bool) -> UIImage{

        // Setup the font specific variables
        let textFont = UIFont(name: "TrebuchetMS-Bold", size: CGFloat(fontSize))!

        // Setup the image context using the passed image
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(inImage.size, false, scale)

        // Setup the font attributes that will be later used to dictate how the text should be drawn
        let style = NSMutableParagraphStyle()
        if shouldCenter {
            style.alignment = .center
        }
        else {
            style.alignment = .left
        }

        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: fontColor,
            NSAttributedString.Key.paragraphStyle: style
        ]

        // Put the image into a rectangle as large as the original image
        inImage.draw(in: CGRect(x: 0, y: 0, width: inImage.size.width, height: inImage.size.height))

        // Create a point within the space that is as bit as the image
        let rect = CGRect(x: atPoint.x, y: atPoint.y, width: inImage.size.width, height: inImage.size.height)

        // Draw the text into an image
        drawText.draw(in: rect, withAttributes: textFontAttributes)

        // Create a new image out of the images we have created
        let newImage = UIGraphicsGetImageFromCurrentImageContext()

        // End the context now that we have the image we need
        UIGraphicsEndImageContext()

        //Pass the image back up to the caller
        return newImage ?? inImage

    }
}
