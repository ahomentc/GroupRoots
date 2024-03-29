//
//  IntroDescriptionController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/17/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class IntroDescriptionController: UIViewController {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    var isInvited: Bool?
    
    let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "A message from our founder:"
        label.font = UIFont(name: "Avenir", size: 16)!
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = false
        return label
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Why we built GroupRoots"
        label.font = UIFont(name: "AvenirNext-Bold", size: 14)!
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = false
        return label
    }()
    
    private let messageOneLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.layer.zPosition = 5
        label.numberOfLines = 0
        label.textAlignment = .left
        let attributedText = NSMutableAttributedString(string: "We built GroupRoots because we got frustrated by how we couldn’t be authentic on social networks. And while we could be on group chats, they’re messy and built for text... not photos.", attributes: [NSAttributedString.Key.font : UIFont(name: "Avenir", size: 14)!])
        attributedText.append(NSMutableAttributedString(string: "\n\nSo we built a social network for groups with friends, with a focus on photos, videos, and memes. Here’s how:", attributes: [NSAttributedString.Key.font : UIFont(name: "Avenir", size: 14)!]))
        attributedText.append(NSMutableAttributedString(string: "\n\nShare authentically. ", attributes: [NSAttributedString.Key.font : UIFont(name: "AvenirNext-Bold", size: 14)!]))
        attributedText.append(NSMutableAttributedString(string: "On GroupRoots, we can let loose with our friends instead of worrying about having a perfect profile.", attributes: [NSAttributedString.Key.font : UIFont(name: "Avenir", size: 14)!]))
        attributedText.append(NSMutableAttributedString(string: "\n\nExpress yourself. ", attributes: [NSAttributedString.Key.font : UIFont(name: "AvenirNext-Bold", size: 14)!]))
        attributedText.append(NSMutableAttributedString(string: "With meme templates built into the app, we can easily find the perfect meme to express our thoughts.", attributes: [NSAttributedString.Key.font : UIFont(name: "Avenir", size: 14)!]))
        attributedText.append(NSMutableAttributedString(string: "\n\nAvoid confusion. ", attributes: [NSAttributedString.Key.font : UIFont(name: "AvenirNext-Bold", size: 14)!]))
        attributedText.append(NSMutableAttributedString(string: "With one message thread per photo, it has 100x better organization than group chats.", attributes: [NSAttributedString.Key.font : UIFont(name: "Avenir", size: 14)!]))
        attributedText.append(NSMutableAttributedString(string: "\n\nWe hope your group's profile will be a fun and organized place for its ever changing story.\n\n - Andrei", attributes: [NSAttributedString.Key.font : UIFont(name: "Avenir", size: 14)!]))
        label.attributedText = attributedText
        label.isHidden = false
        return label
    }()
    
    private lazy var noteNextButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(closeNote), for: .touchUpInside)
        button.layer.zPosition = 5;
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Next", for: .normal)
        button.isHidden = false
        return button
    }()
    
    private lazy var profileNextButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(finishIntro), for: .touchUpInside)
        button.layer.zPosition = 5;
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Next", for: .normal)
        button.isHidden = true
        return button
    }()
    
    //MARK: Explain Group Profile
    let GroupProfileTitle: UILabel = {
        let label = UILabel()
//        label.text = "Group Profiles:\nFor your favorite or funniest photos"
//        label.font = UIFont(name: "AvenirNext-Bold", size: 16)!
        label.textColor = UIColor.black
        label.layer.zPosition = 5
        let attributedText = NSMutableAttributedString(string: "Your group is a shared space", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 18)])
//        attributedText.append(NSMutableAttributedString(string: "\nFor your favorite or funniest photos", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.init(white: 0.3, alpha: 1)]))
        label.attributedText = attributedText
        label.isHidden = true
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let profileExplanationLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.init(white: 0.4, alpha: 1)
        label.layer.zPosition = 5
        label.numberOfLines = 0
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        paragraphStyle.alignment = .center
//        let attributedText = NSMutableAttributedString(string: "Your group's profile is a shared space.\nOnly members who join it can post to it.\nFollowers will see it's posts in the feed.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.paragraphStyle : paragraphStyle])
        let attributedText = NSMutableAttributedString(string: "Add photos to its ongoing story.\nOr post for 24 hours to keep it\ncasual and fun.", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16), NSAttributedString.Key.paragraphStyle : paragraphStyle])
        label.attributedText = attributedText
        
        label.isHidden = true
        return label
    }()
    
    let groupProfileView: UIImageView = {
        let img = UIImageView(image: #imageLiteral(resourceName: "profile"))
        img.isHidden = true
        return img
    }()
        
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        navigationController?.isNavigationBarHidden = true
        view.backgroundColor = .white
        
        self.welcomeLabel.alpha = 0
        self.titleLabel.alpha = 0
        self.messageOneLabel.alpha = 0
        self.noteNextButton.alpha = 0
    
//        self.view.insertSubview(welcomeLabel, at: 5)
//        welcomeLabel.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 20, paddingRight: 20,  height: 30)
        
        self.view.insertSubview(titleLabel, at: 5)
        titleLabel.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, height: 40)
        
        self.view.insertSubview(messageOneLabel, at: 5)
        messageOneLabel.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 15, paddingLeft: 20, paddingRight: 20)
        
        self.view.insertSubview(noteNextButton, at: 4)
        noteNextButton.layer.cornerRadius = 18
        noteNextButton.anchor(bottom: view.bottomAnchor, right: view.rightAnchor, paddingBottom: 25, paddingRight: 20, width: 100, height: 50)
        
        self.view.insertSubview(profileNextButton, at: 4)
        profileNextButton.layer.cornerRadius = 18
        profileNextButton.anchor(bottom: view.bottomAnchor, right: view.rightAnchor, paddingBottom: 25, paddingRight: 20, width: 100, height: 50)
        
        self.view.insertSubview(GroupProfileTitle, at: 5)
        GroupProfileTitle.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 80, paddingLeft: 20, paddingRight: 20)
        
        self.view.insertSubview(profileExplanationLabel, at: 5)
        profileExplanationLabel.anchor(top: GroupProfileTitle.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 10, paddingLeft: view.frame.width/2 - (view.frame.width - 50)/2, paddingRight: view.frame.width/2 - (view.frame.width - 50)/2)
        
        view.addSubview(groupProfileView)
        groupProfileView.frame = CGRect(x: view.frame.width/2 - (view.frame.width - 80)/2, y: view.frame.width - (view.frame.width - 80)/2, width: view.frame.width - 80, height: view.frame.width - 80)
        
        UIView.animate(withDuration: 1) {
            self.welcomeLabel.alpha = 1
            self.titleLabel.alpha = 1
            self.messageOneLabel.alpha = 1
            self.noteNextButton.alpha = 1
        }
    }
    
    @objc private func closeNote() {
        self.GroupProfileTitle.alpha = 0
        self.profileExplanationLabel.alpha = 0
        self.profileNextButton.alpha = 0
        self.groupProfileView.alpha = 0
        self.GroupProfileTitle.isHidden = false
        self.profileExplanationLabel.isHidden = false
        self.profileNextButton.isHidden = false
        self.groupProfileView.isHidden = false
        
        UIView.animate(withDuration: 0.5) {
            self.welcomeLabel.alpha = 0
            self.titleLabel.alpha = 0
            self.messageOneLabel.alpha = 0
            self.noteNextButton.alpha = 0
        }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            self.welcomeLabel.isHidden = true
            self.titleLabel.isHidden = true
            self.messageOneLabel.isHidden = true
            self.noteNextButton.isHidden = true
            
            UIView.animate(withDuration: 0.5) {
                self.GroupProfileTitle.alpha = 1
                self.profileExplanationLabel.alpha = 1
                self.profileNextButton.alpha = 1
                self.groupProfileView.alpha = 1
            }
        }
    }
    
    @objc private func finishIntro(){
        
        // for now have it that all people, invited to group or not,
        // are prompted to create a new group anyways
        self.GroupProfileTitle.alpha = 1
        self.profileExplanationLabel.alpha = 1
        self.profileNextButton.alpha = 1
        self.groupProfileView.alpha = 1
        
        UIView.animate(withDuration: 0.5) {
            self.GroupProfileTitle.alpha = 0
            self.profileExplanationLabel.alpha = 0
            self.profileNextButton.alpha = 0
            self.groupProfileView.alpha = 0
        }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
            let introGroupStepController = IntroGroupStepController()
            self.navigationController?.pushViewController(introGroupStepController, animated: false)
        }
        
        
//        guard let isInvited = isInvited else { return }
        
//        if isInvited {
//            if let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController {
//                mainTabBarController.setupViewControllers()
//                mainTabBarController.selectedIndex = 0
//                self.dismiss(animated: true, completion: nil)
//            }
//        }
//        else {
//            self.GroupProfileTitle.alpha = 1
//            self.profileExplanationLabel.alpha = 1
//            self.profileNextButton.alpha = 1
//            self.groupProfileView.alpha = 1
//
//            UIView.animate(withDuration: 0.5) {
//                self.GroupProfileTitle.alpha = 0
//                self.profileExplanationLabel.alpha = 0
//                self.profileNextButton.alpha = 0
//                self.groupProfileView.alpha = 0
//            }
//            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { timer in
//                let introGroupStepController = IntroGroupStepController()
//                self.navigationController?.pushViewController(introGroupStepController, animated: false)
//            }
//        }
    }
}




