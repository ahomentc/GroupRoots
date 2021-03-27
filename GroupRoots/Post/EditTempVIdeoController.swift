//
//  EditTempVIdeoController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/23/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//


import AVFoundation
import Player
import Foundation
import UIKit
import SwiftUI
import EasyPeasy
import FirebaseAuth
import LocationPicker
import MapKit
import FirebaseDatabase
import NVActivityIndicatorView
import AVKit
import MobileCoreServices
import CenterTextLayer


class EditTempVideoController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate, ModifyTextViewDelegate, UIColorPickerViewControllerDelegate, UIFontPickerViewControllerDelegate, CaptionTextDelegate {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var videoUrl: URL? {
        didSet {
            guard let videoUrl = videoUrl else { return }
            self.setVideoDimensions()
            self.setOverlaySize(fromVideoAt: videoUrl)
            self.player.url = videoUrl
            self.player.playFromBeginning()
        }
    }
    
    var notFromCamera: Bool?
    
//    var videoUrl: URL? {
//        didSet {
//            guard let videoUrl = videoUrl else { return }
//            print("1")
//            self.makeVideo(fromVideoAt: videoUrl, forName: "Stefan") { exportedURL in
//              guard let exportedURL = exportedURL else {
//                return
//              }
//                self.setVideoDimensions()
//                self.player.url = exportedURL
//                self.player.playFromBeginning()
//            }
//        }
//    }
    
    
    
    var isTempPost = true

    var player = Player()
    
    var suggestedLocation: CLLocation?
    var pickedLocation: PostLocation?
    
    let overlayLayer = CALayer()
    
    var selectedGroup: Group? {
        didSet {
            if selectedGroup == nil {
                self.nextButton.isHidden = false
                self.postButton.isHidden = true
                self.hourglassButton.isHidden = true
            }
        }
    }
    
    var setupWithSelectedGroupWithAnim: Bool? {
        didSet {
            guard let setupWithSelectedGroupWithAnim = setupWithSelectedGroupWithAnim else { return }
            if setupWithSelectedGroupWithAnim {
                self.coverView.isHidden = true
                self.postCoverView.isHidden = false
                self.hourglassButton.isHidden = false
                self.showSelectedGroup()
                
                self.hourglassButton.alpha = 0
                UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                    self.hourglassButton.alpha = 1
                }, completion: nil)
                
                //nextButton postButton
                self.postButton.transform = CGAffineTransform(scaleX: 0, y: 0)
                self.postButton.isHidden = false
                UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                    self.nextButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                }, completion: nil)
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                    self.nextButton.isHidden = true
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                        self.postButton.transform = CGAffineTransform.identity
                    }, completion: nil)
                }
            }
            else {
                self.coverView.isHidden = true
                self.postCoverView.isHidden = false
                self.hourglassButton.isHidden = false
                self.showSelectedGroup()
                self.hourglassButton.isHidden = false
                self.postButton.isHidden = false
                self.nextButton.isHidden = true
            }
        }
    }
    
    lazy var selectedGroupLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .right
        label.backgroundColor = UIColor.clear
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectGroup))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tap)
        label.isHidden = true
        
        label.layer.backgroundColor = UIColor.clear.cgColor
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        label.layer.shadowOpacity = 0.2
        label.layer.shadowRadius = 2.0
        
        label.layer.zPosition = 22
        return label
    }()
    
    let trashIcon: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "trash_icon"), for: .normal)
        button.backgroundColor = .clear
        button.isUserInteractionEnabled = false
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 21
        button.alpha = 0
        return button
    }()
    
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "arrow_left"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(selectGroup), for: .touchUpInside)
        button.layer.zPosition = 22;
        button.backgroundColor = UIColor(white: 1, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Share to", for: .normal)
        return button
    }()
    
    private lazy var postButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleShare), for: .touchUpInside)
        button.layer.zPosition = 22;
        button.backgroundColor = UIColor(white: 1, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Post", for: .normal)
        return button
    }()
    
    let hourglassButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "hourglass_24"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(toggleTempPost), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        button.layer.zPosition = 22
        return button
    }()
    
    let captionButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "caption"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(showCaptionTextView), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let locationButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "location_icon"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(pickLocation), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    private let textEditBackground: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 250))
        backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        backgroundView.isHidden = true
        return backgroundView
    }()
    
    private let postCoverView: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 250))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 3)
        backgroundView.isHidden = true
        return backgroundView
    }()
    
    private let coverView: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 250))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 3)
        return backgroundView
    }()
    
    private let upperCoverView: UIView = {
//        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 300))
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 170))
        let gradient = CAGradientLayer()
        gradient.frame = backgroundView.bounds
        let startColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor
        let endColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        gradient.colors = [startColor, endColor]
        backgroundView.layer.insertSublayer(gradient, at: 3)
//        backgroundView.backgroundColor = .blue
        return backgroundView
    }()
    
    let textButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "text_icon"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(addText), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.isHidden = false
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let doneTextButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
        button.backgroundColor = .clear
        button.isUserInteractionEnabled = false
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.isHidden = true
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    private let captionTextView: CaptionTextView = {
        let textView = CaptionTextView(frame: CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-75, width: 300, height: 100))
        textView.placeholderLabel.text = "Enter a caption..."
//        textView.isScrollEnabled = false
//        textView.textContainer.maximumNumberOfLines = 3;
        textView.isUserInteractionEnabled = true
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.autocorrectionType = .yes
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.backgroundColor = UIColor.init(white: 1, alpha: 1)
        textView.textAlignment = .left
        textView.layer.cornerRadius = 5
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.isHidden = true
        return textView
    }()
    
    let activityIndicatorView: NVActivityIndicatorView = {
        let activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width - 40, y: UIScreen.main.bounds.height - 40, width: 20, height: 20), type: NVActivityIndicatorType.circleStrokeSpin)
        activityIndicatorView.layer.backgroundColor = UIColor.clear.cgColor
        activityIndicatorView.layer.shadowColor = UIColor.black.cgColor
        activityIndicatorView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        activityIndicatorView.layer.shadowOpacity = 0.2
        activityIndicatorView.layer.shadowRadius = 2.0
        activityIndicatorView.isHidden = true
        activityIndicatorView.layer.zPosition = 22
        return activityIndicatorView
    }()
    
    let sharingLabel: UILabel = {
        let label = UILabel()
        label.text = "Sharing"
        label.textAlignment = .right
        label.backgroundColor = UIColor.clear
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.isHidden = true
        label.layer.zPosition = 22
        
        label.layer.backgroundColor = UIColor.clear.cgColor
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        label.layer.shadowOpacity = 0.2
        label.layer.shadowRadius = 2.0
        return label
    }()
    
    var textViews = [UITextView]()
    var activeTextView = UITextView()
    var locationViews = [UILabel]()
        
    override func viewWillAppear(_ animated: Bool) {
//        self.nextButton.isHidden = false
//        self.postButton.isHidden = true
//        self.textButton.isHidden = false
//        self.hourglassButton.isHidden = true
        self.closeButton.isHidden = false
        self.upperCoverView.isHidden = false
        self.coverView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.player.stop()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.player.stop()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureReconizer = UITapGestureRecognizer(target: self, action: #selector(closeTextViewKeyboard))
        tapGestureReconizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureReconizer)
        
        self.view.insertSubview(player.view, at: 0)
        self.player.autoplay = true
        self.player.playbackResumesWhenBecameActive = true
        self.player.playbackResumesWhenEnteringForeground = true
        self.player.playerDelegate = self
        
        self.player.playbackLoops = true
        self.player.muted = false
        self.player.playerView.playerBackgroundColor = .black
//        self.player.fillMode = .resizeAspectFill
        
        nextButton.frame = CGRect(x: UIScreen.main.bounds.width-120, y: UIScreen.main.bounds.height - 70, width: 100, height: 50)
        nextButton.layer.cornerRadius = 20
        self.view.insertSubview(nextButton, at: 22)
        
        postButton.frame = CGRect(x: UIScreen.main.bounds.width-120, y: UIScreen.main.bounds.height - 70, width: 100, height: 50)
        postButton.layer.cornerRadius = 20
        self.view.insertSubview(postButton, at: 22)
        
        closeButton.frame = CGRect(x: 10, y: 15, width: 40, height: 40)
        closeButton.layer.zPosition = 20
        self.view.insertSubview(closeButton, at: 12)
        
//        hourglassButton.frame = CGRect(x: UIScreen.main.bounds.width - 200, y: UIScreen.main.bounds.height - 75, width: 55, height: 55)
//        self.view.insertSubview(hourglassButton, at: 12)
        
        hourglassButton.frame = CGRect(x: 20, y: UIScreen.main.bounds.height - 72, width: 50, height: 50)
        self.view.insertSubview(hourglassButton, at: 12)
        
        textButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 15, width: 45, height: 45)
        self.view.insertSubview(textButton, at: 12)
        
        doneTextButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 15, width: 40, height: 40)
        self.view.insertSubview(doneTextButton, at: 12)
        
        captionButton.frame = CGRect(x: UIScreen.main.bounds.width - 55, y: 80, width: 35, height: 35)
        self.view.insertSubview(captionButton, at: 12)
        
        locationButton.frame = CGRect(x: UIScreen.main.bounds.width - 67, y: 130, width: 60, height: 60)
        self.view.insertSubview(locationButton, at: 12)
        
        trashIcon.frame = CGRect(x: UIScreen.main.bounds.width/2 - 25, y: UIScreen.main.bounds.height - 70, width: 50, height: 50)
        self.view.insertSubview(trashIcon, at: 12)
        
        self.view.addSubview(selectedGroupLabel)
        self.selectedGroupLabel.anchor(top: self.postButton.topAnchor, left: self.hourglassButton.rightAnchor, bottom: self.postButton.bottomAnchor, right: self.postButton.leftAnchor, paddingLeft: 10, paddingRight: 20)
        
        postCoverView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        postCoverView.layer.cornerRadius = 0
        postCoverView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 210, width: UIScreen.main.bounds.width, height: 250)
        postCoverView.isUserInteractionEnabled = false
        self.view.insertSubview(postCoverView, at: 3)
        
        self.view.insertSubview(activityIndicatorView, at: 20)

        sharingLabel.frame = CGRect(x: UIScreen.main.bounds.width - 145, y: UIScreen.main.bounds.height - 30, width: 90, height: 30)
        self.view.insertSubview(sharingLabel, at: 20)
        
        coverView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        coverView.layer.cornerRadius = 0
        coverView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 210, width: UIScreen.main.bounds.width, height: 250)
        coverView.isUserInteractionEnabled = false
        self.view.insertSubview(coverView, at: 3)
        
//        upperCoverView.heightAnchor.constraint(equalToConstant: 170).isActive = true
//        upperCoverView.layer.cornerRadius = 0
//        upperCoverView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 170)
//        upperCoverView.isUserInteractionEnabled = false
//        self.view.insertSubview(upperCoverView, at: 3)
        
        textEditBackground.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        textEditBackground.layer.cornerRadius = 0
        textEditBackground.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        textEditBackground.isUserInteractionEnabled = false
        self.view.insertSubview(textEditBackground, at: 4)
        
        self.nextButton.addTarget(self, action: #selector(self.nextButtonDown), for: .touchDown)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonDown), for: .touchDragInside)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonUp), for: .touchDragExit)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonUp), for: .touchCancel)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonUp), for: .touchUpInside)
        
        self.postButton.addTarget(self, action: #selector(self.postButtonDown), for: .touchDown)
        self.postButton.addTarget(self, action: #selector(self.postButtonDown), for: .touchDragInside)
        self.postButton.addTarget(self, action: #selector(self.postButtonUp), for: .touchDragExit)
        self.postButton.addTarget(self, action: #selector(self.postButtonUp), for: .touchCancel)
        self.postButton.addTarget(self, action: #selector(self.postButtonUp), for: .touchUpInside)
        
        self.captionTextView.caption_delegate = self
        self.view.insertSubview(captionTextView, at: 15)
        
        if notFromCamera != nil && notFromCamera! == true {
            locationButton.isHidden = true
            textButton.isHidden = true
            captionButton.frame = CGRect(x: UIScreen.main.bounds.width - 55, y: 15, width: 35, height: 35)
        }
    }
    
    @objc func panHandler(gestureRecognizer: UIPanGestureRecognizer){
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: self.view)
            gestureRecognizer.view!.center = CGPoint(x: gestureRecognizer.view!.center.x + translation.x, y: gestureRecognizer.view!.center.y + translation.y)
            gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
            
            let newX = gestureRecognizer.location(in: view).x
            let newY = gestureRecognizer.location(in: view).y
            
            let trashX = self.trashIcon.center.x
            let trashY = self.trashIcon.center.y
            
            self.trashIcon.alpha = 0.8
            
            let distance = (newX - trashX) * (newX - trashX) + (newY - trashY) * (newY - trashY)
            if distance < 3000 {
                gestureRecognizer.view?.alpha = 0.7
            }
            else {
                gestureRecognizer.view?.alpha = 1
            }
            
            self.nextButton.isHidden = true
            self.postButton.isHidden = true
            self.textButton.isHidden = true
            self.hourglassButton.isHidden = true
            self.closeButton.isHidden = true
            self.locationButton.isHidden = true
            self.selectedGroupLabel.isHidden = true
            self.captionButton.isHidden = true
        }
        if gestureRecognizer.state == .ended {
            self.trashIcon.alpha = 0
            gestureRecognizer.view?.alpha = 1
            
            let translation = gestureRecognizer.translation(in: self.view)
            let newX = gestureRecognizer.location(in: view).x
            let newY = gestureRecognizer.location(in: view).y
            
            let trashX = self.trashIcon.center.x
            let trashY = self.trashIcon.center.y
            
            let distance = (newX - trashX) * (newX - trashX) + (newY - trashY) * (newY - trashY)
            if distance < 3000 {
                gestureRecognizer.view?.removeFromSuperview()
                gestureRecognizer.view?.tag = -1 // set tag so we know what which views to remove
                
                // if is the location label:
                if gestureRecognizer.view is UILabel {
                    let locationLabel = gestureRecognizer.view as! UILabel
                    if locationLabel.tag == 12 { // check to see if it's actually locationLabel
                        // remove the location
                        self.didEmtpyLocation()
                    }
                }
            }
            
            if self.selectedGroup == nil {
                self.nextButton.isHidden = false
                self.postButton.isHidden = true
            }
            else {
                self.postButton.isHidden = false
                self.nextButton.isHidden = true
                self.selectedGroupLabel.isHidden = false
                self.hourglassButton.isHidden = false
            }
            self.textButton.isHidden = false
            self.closeButton.isHidden = false
            self.locationButton.isHidden = false
            self.upperCoverView.isHidden = false
            self.coverView.isHidden = false
            self.captionButton.isHidden = false
        }
    }
    
    @objc func pinchHandler(pinch: UIPinchGestureRecognizer){
        if let view = pinch.view {
            view.transform = view.transform.scaledBy(x: pinch.scale, y: pinch.scale)
            pinch.scale = 1
            (view as! UITextView).centerTextVertically()

            //            textView.centerTextVertically()
//            resizeFont(self.textView)
        }
    }
    
    @objc func rotateHandler(sender: UIRotationGestureRecognizer){
        if let view = sender.view {
            view.transform = view.transform.rotated(by: sender.rotation)
            sender.rotation = 0
            (view as! UITextView).centerTextVertically()
        }
    }
    
    @objc func closeTextViewKeyboard(sender: UITapGestureRecognizer) {
//        self.textView.resignFirstResponder()
        for textView in self.textViews {
            textView.resignFirstResponder()
        }
        self.captionTextView.resignFirstResponder()
        self.captionTextView.isHidden = true
    }
    
    func showSelectedGroup() {
        guard let selectedGroup = self.selectedGroup else { return }
        Database.database().fetchFirstNGroupMembers(groupId: selectedGroup.groupId, n: 3, completion: { (first_n_users) in
            if selectedGroup.groupname == "" {
                var usernames = ""
                if first_n_users.count > 2 {
                    usernames = first_n_users[0].username + " & " + first_n_users[1].username + " & " + first_n_users[2].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                }
                else if first_n_users.count == 2 {
                    usernames = first_n_users[0].username + " & " + first_n_users[1].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                }
                else if first_n_users.count == 1 {
                    usernames = first_n_users[0].username
                    if usernames.count > 21 {
                        usernames = String(usernames.prefix(21)) // keep only the first 21 characters
                        usernames = usernames + "..."
                    }
                }
                let name = usernames
                self.selectedGroupLabel.text = name
                self.selectedGroupLabel.isHidden = false
                self.selectedGroupLabel.alpha = 0
                UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                    self.selectedGroupLabel.alpha = 1
                }, completion: nil)
            }
            else {
                let name = selectedGroup.groupname.replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-a-_", with: " ").replacingOccurrences(of: "_-b-_", with: "‘")
                self.selectedGroupLabel.text = name
                self.selectedGroupLabel.isHidden = false
                self.selectedGroupLabel.alpha = 0
                UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                    self.selectedGroupLabel.alpha = 1
                }, completion: nil)
            }
        }) { (_) in }
    }
    
    var isChangingTextColor = true
    
    func changeTextViewColor() {
        if #available(iOS 14.0, *) {
            isChangingTextColor = true
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.selectedColor = .white
            present(picker, animated: true, completion: nil)
        } else {
            if self.activeTextView.textColor == .white {
                self.activeTextView.textColor = .black
            }
            else {
                self.activeTextView.textColor = .white
            }
        }
    }
    
    func changeTextBackgroundColor() {
        if #available(iOS 14.0, *) {
            isChangingTextColor = false
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.selectedColor = .clear
            present(picker, animated: true, completion: nil)
        } else {
            if self.activeTextView.backgroundColor == .clear {
                self.activeTextView.backgroundColor = .black
            }
            else {
                self.activeTextView.backgroundColor = .clear
            }
        }
    }
    
    func changeTextViewFont() {
        if #available(iOS 13.0, *) {
            let fontConfig = UIFontPickerViewController.Configuration()
            fontConfig.includeFaces = true
            let fontPicker = UIFontPickerViewController(configuration: fontConfig)
            fontPicker.delegate = self
            self.present(fontPicker, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 14.0, *)
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        if isChangingTextColor {
            let color = viewController.selectedColor
            self.activeTextView.textColor = color
        }
        else {
            let color = viewController.selectedColor
            self.activeTextView.backgroundColor = color
        }
    }
    
    @available(iOS 13.0, *)
    func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        guard let descriptor = viewController.selectedFontDescriptor else { return }
        let font = UIFont(descriptor: descriptor, size: 20)
        self.activeTextView.font = font
    }
    
    func changeTextAlignment(alignment: NSTextAlignment) {
        self.activeTextView.textAlignment = alignment
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("started editing")
        self.activeTextView = textView
        self.textEditBackground.isHidden = false
        self.doneTextButton.isHidden = false
        self.textButton.isHidden = true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        print("stopped editing")
        self.textEditBackground.isHidden = true
        self.doneTextButton.isHidden = true
        self.textButton.isHidden = false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        print("text view changed")
        if textView.text == "" {
            textView.removeFromSuperview()
            return
        }
        
        let numberOfLines = getNumberOfLines(in: textView)
        if numberOfLines == 1 {
            textView.font = UIFont.boldSystemFont(ofSize: 21)
            textView.centerTextVertically()
        }
        else if numberOfLines == 2 {
            textView.font = UIFont.boldSystemFont(ofSize: 20)
            textView.centerTextVertically()
        }
        else {
            textView.font = UIFont.boldSystemFont(ofSize: 19)
            textView.centerTextVertically()
        }
        
//        let transform = textView.transform
        
//        let non_rotated_line_height = 50 * numberOfLines
//        let non_rotated_line_width = 250
        
        // take the width of 250
        // take the height of 50, multiply it by number of lines
        // imagine its a rectangle of this size
        // scale it by how much this has been scaled
        // rotate it by how much this has been rotated
        // now you have the new width and height
        
        // get the original width and height by taking out rotation
        
//        let angle = atan2(-transform.c, transform.a) // Find the angle, print it in degrees
//        print(angle * 180.0 / .pi) // 44.99999999999999
//        let scaleX = transform.a * cos(angle) - transform.c * sin(angle)
//        let scaleY = transform.d * cos(angle) + transform.b * sin(angle)
//        let adjustedSize = CGSize(width: textView.bounds.size.width * scaleX, height: textView.bounds.size.height * scaleY)
//
//        let scale = adjustedSize.width / 250
//        let original_width = adjustedSize.width/scale
//        let original_height = adjustedSize.height/scale
        
        
        
        
//        let original_center = textView.center
//        textView.frame = CGRect(x: textView.frame.origin.x, y: textView.frame.origin.y, width: textView.frame.width, height: CGFloat(50 * numberOfLines))
//        textView.transform.rotated(by: angle)
//        textView.center = original_center
    }
    
    func resizeFont(_ textView: UITextView) {
        if (textView.text.isEmpty || textView.bounds.size.equalTo(CGSize.zero)) {
            return;
        }

        let textViewSize = textView.frame.size;
        let fixedWidth = textViewSize.width;
        let expectSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT)));

        var expectFont = textView.font;
        if (expectSize.height > textViewSize.height) {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height > textViewSize.height) {
                expectFont = textView.font!.withSize(textView.font!.pointSize - 1)
                    textView.font = expectFont
            }
        }
        else {
            while (textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat(MAXFLOAT))).height < textViewSize.height) {
                expectFont = textView.font;
                textView.font = textView.font!.withSize(textView.font!.pointSize + 1)
            }
            textView.font = expectFont;
        }
      }
    
    func gestureRecognizer(_: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc private func addLocationSticker(location: String) {
        for view in self.locationViews {
            view.removeFromSuperview()
            view.tag = -1
        }
        
        let width = 12 * location.count + 15
        
        let label = UILabel(frame: CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-75, width: CGFloat(width), height: 50))
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = .white
        label.isUserInteractionEnabled = true
        label.backgroundColor = UIColor(red: 0/255, green: 166/255, blue: 107/255, alpha: 1)
        label.textAlignment = .center
        label.text = location
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.layer.zPosition = 10
        label.tag = 12
        label.alpha = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { timer in
            UIView.animate(withDuration: 0.5) {
                label.alpha = 1
            }
        }
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panHandler))
        panGesture.delegate = self
        label.addGestureRecognizer(panGesture)
        
//        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchHandler))
//        pinchGesture.delegate = self
//        label.addGestureRecognizer(pinchGesture)
//
//        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateHandler))
//        rotateGesture.delegate = self
//        label.addGestureRecognizer(rotateGesture)
        
        self.view.insertSubview(label, at: 10)
        
        self.locationViews.append(label)
    }
    
    var first = true
    @objc private func addText() {
        let textView = UITextView(frame: CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-75, width: 300, height: 100))
        textView.font = UIFont.boldSystemFont(ofSize: 20)
        textView.textColor = .white
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = UIColor.clear
        textView.textAlignment = .center
        textView.text = ""
        textView.delegate = self
        textView.autocorrectionType = .no
        textView.textContainer.maximumNumberOfLines = 3;
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panHandler))
        panGesture.delegate = self
        textView.addGestureRecognizer(panGesture)
        
//        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchHandler))
//        pinchGesture.delegate = self
//        textView.addGestureRecognizer(pinchGesture)

//        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateHandler))
//        rotateGesture.delegate = self
//        textView.addGestureRecognizer(rotateGesture)
        
        self.view.insertSubview(textView, at: 10)
        textView.centerTextVertically()
        
        self.textViews.append(textView)
        let modifyTextView = ModifyTextView(frame: CGRect(x: 0, y: 0, width: 10, height: 70))
        modifyTextView.delegate = self
        textView.inputAccessoryView = modifyTextView
                        
        textView.becomeFirstResponder()
    }
    
    func getNumberOfLines(in textView: UITextView) -> Int {
        let numberOfGlyphs = textView.layoutManager.numberOfGlyphs
        var index = 0, numberOfLines = 0
        var lineRange = NSRange(location: NSNotFound, length: 0)
        while index < numberOfGlyphs {
            textView.layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            numberOfLines += 1
        }
        return numberOfLines
    }
    
    @objc private func showCaptionTextView() {
        self.captionTextView.isHidden = false
//        UITextView.appearance().tintColor = UIColor.black
        self.captionTextView.becomeFirstResponder()
    }
    
    
    var isCaptionFilled = false
    
    func didFillCaption() {
        if !isCaptionFilled {
            self.captionButton.animateButtonDown()
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                self.captionButton.setImage(#imageLiteral(resourceName: "caption_filled"), for: .normal)
                self.captionButton.animateButtonDownBig()
            }
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in
                self.captionButton.animateButtonUp()
            }
            isCaptionFilled = true
        }
    }
    
    func didEmtpyCaption() {
        if isCaptionFilled {
            self.captionButton.animateButtonDown()
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                self.captionButton.setImage(#imageLiteral(resourceName: "caption"), for: .normal)
                self.captionButton.animateButtonDownBig()
            }
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in
                self.captionButton.animateButtonUp()
            }
            isCaptionFilled = false
        }
    }
    
    var isLocationFilled = false
    
    func didFillLocation() {
        if !isLocationFilled {
            self.locationButton.animateButtonDown()
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                self.locationButton.setImage(#imageLiteral(resourceName: "location_icon_filled"), for: .normal)
                self.locationButton.animateButtonDownBig()
            }
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in
                self.locationButton.animateButtonUp()
            }
            isLocationFilled = true
        }
    }
    
    func didEmtpyLocation() {
        if isLocationFilled {
            self.locationButton.animateButtonDown()
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                self.locationButton.setImage(#imageLiteral(resourceName: "location_icon"), for: .normal)
                self.locationButton.animateButtonDownBig()
            }
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in
                self.locationButton.animateButtonUp()
            }
            isLocationFilled = false
        }
    }
    
    @objc private func selectGroup() {
        let selectGroupController = SelectGroupController()
        selectGroupController.didFinishPicking { [unowned selectGroupController] group, cancelled in
            if cancelled {
                print("Picker was canceled")
                return
            }
            self.selectedGroup = group
            self.setupWithSelectedGroupWithAnim = true
        }
        let navController = UINavigationController(rootViewController: selectGroupController)
        navController.modalPresentationStyle = .overFullScreen
        self.present(navController, animated: true, completion: nil)
    }
    
    @objc private func goToShare() {
        guard let videoUrl = videoUrl else { return }
        self.player.stop()
        let sharePhotoController = SharePhotoController()
        sharePhotoController.selectedVideoURL = videoUrl
        sharePhotoController.isTempPost = isTempPost
        sharePhotoController.selectedImage = imageFromVideo(url: videoUrl, at: 0)
        navigationController?.pushViewController(sharePhotoController, animated: true)
    }
    
    @objc private func pickLocation(){
        let locationPicker = LocationPickerViewController()
        
        // button placed on right bottom corner
        locationPicker.showCurrentLocationButton = true // default: true

        // default: navigation bar's `barTintColor` or `UIColor.white`
        locationPicker.currentLocationButtonBackground = .white

        // ignored if initial location is given, shows that location instead
        locationPicker.showCurrentLocationInitially = true // default: true

        locationPicker.mapType = .standard // default: .Hybrid

        // for searching, see `MKLocalSearchRequest`'s `region` property
        locationPicker.useCurrentLocationAsHint = true // default: false

        locationPicker.searchBarPlaceholder = "Search places" // default: "Search or enter an address"

        locationPicker.searchHistoryLabel = "Previously searched" // default: "Search History"

        // optional region distance to be used for creation region when user selects place from search results
        locationPicker.resultRegionDistance = 500 // default: 600
        
        locationPicker.title = "Add Location"
        
        locationPicker.completion = { location in
            Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { timer in
                self.didFillLocation()
            }
            self.pickedLocation = PostLocation(name: location?.name, longitude: "\(location?.coordinate.longitude ?? 0)", latitude: "\(location?.coordinate.latitude ?? 0)", address: location?.address)
            self.addLocationSticker(location: self.pickedLocation?.name ?? "")
        }
        
        let navController = UINavigationController(rootViewController: locationPicker)
        navController.modalPresentationStyle = .popover
        

        if suggestedLocation != nil {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(suggestedLocation!, completionHandler: {(placemarks, error)->Void in
                if placemarks != nil && placemarks!.count > 0 {
                    let placemark = placemarks![0]
                    var name = placemark.name
                    if placemark.areasOfInterest != nil && placemark.areasOfInterest!.count > 0 {
                        name = placemark.areasOfInterest![0]
                    }
                    locationPicker.location = Location(name: name, location: self.suggestedLocation!, placemark: placemark)
                }
                else {
                    let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: self.suggestedLocation!.coordinate.latitude, longitude: self.suggestedLocation!.coordinate.longitude), addressDictionary: nil)
                    locationPicker.location = Location(name: "", location: self.suggestedLocation!, placemark: placemark)
                }
                self.present(navController, animated: true, completion: nil)
            })
        }
        else {
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    @objc private func close() {
        self.player.pause()
        _ = navigationController?.popViewController(animated: false)
    }
    
    @objc private func nextButtonDown(){
        self.nextButton.animateButtonDown()
    }
    
    @objc private func nextButtonUp(){
        self.nextButton.animateButtonUp()
    }
    
    @objc private func postButtonDown(){
        self.postButton.animateButtonDown()
    }
    
    @objc private func postButtonUp(){
        self.postButton.animateButtonUp()
    }
    
    @objc private func toggleTempPost() {
        isTempPost = !isTempPost
        if isTempPost {
            hourglassButton.setImage(#imageLiteral(resourceName: "hourglass_24"), for: .normal)
        }
        else {
            hourglassButton.setImage(#imageLiteral(resourceName: "hourglass_infinity"), for: .normal)
        }
    }
    
    func imageFromVideo(url: URL, at time: TimeInterval) -> UIImage? {
        let asset = AVURLAsset(url: url)

        let assetIG = AVAssetImageGenerator(asset: asset)
        assetIG.appliesPreferredTrackTransform = true
        assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels

        let cmTime = CMTime(seconds: time, preferredTimescale: 60)
        let thumbnailImageRef: CGImage
        do {
            thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
        } catch let error {
            print("Error: \(error)")
            return nil
        }

        return UIImage(cgImage: thumbnailImageRef)
    }
    
    private func setVideoDimensions(){
        guard let videoUrl = videoUrl else { return }
        let img = imageFromVideo(url: videoUrl, at: 0)
        let width = img?.size.width
        let height = img?.size.height
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
    
    func scale(from transform: CGAffineTransform) -> Double {
        return sqrt(Double(transform.a * transform.a + transform.c * transform.c));
    }
    
    @objc private func handleShare() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let selectedGroup = selectedGroup else { return }
        guard let videoUrl = videoUrl else { return }
        
        textViews.removeAll { $0.tag == -1 }
        locationViews.removeAll { $0.tag == -1 }

        for view in textViews {
            var scaledBy = CGFloat(scale(from: view.transform))
            let ratio = self.overlayLayer.frame.width / UIScreen.main.bounds.width

            let textLayer = CenterTextLayer()
            
            var scaleTranslation = scaledBy
            if scaledBy > 1 {
                scaleTranslation = -1 * scaledBy
            }
//            textLayer.frame = CGRect(x: view.frame.origin.x * ratio * scaleTranslation, y: self.overlayLayer.frame.height - view.frame.origin.y * ratio - ratio * 100, width: ratio * 300, height: ratio * 100)
            textLayer.frame = CGRect(x: view.frame.origin.x * ratio, y: self.overlayLayer.frame.height - view.frame.origin.y * ratio - ratio * 100, width: ratio * 300, height: ratio * 110)
            textLayer.string = view.text
            textLayer.fontSize = view.font!.pointSize * ratio
            textLayer.font = view.font
            textLayer.isWrapped = true
            textLayer.foregroundColor = view.textColor?.cgColor
            textLayer.shouldRasterize = true
            textLayer.rasterizationScale = UIScreen.main.scale
            textLayer.backgroundColor = view.backgroundColor?.cgColor
            
            if view.textAlignment == .center {
                textLayer.alignmentMode = .center
            }
            else if view.textAlignment == .left {
                textLayer.alignmentMode = .left
            }
            else if view.textAlignment == .right {
                textLayer.alignmentMode = .right
            }
            
            textLayer.transform = CATransform3DMakeScale(CGFloat(scaledBy), CGFloat(scaledBy), 1);

            let radians = atan2(view.transform.b, view.transform.a)
            textLayer.transform = CATransform3DMakeRotation(-radians, 0.0, 0.0, 1.0)
            
            overlayLayer.addSublayer(textLayer)
        }
        
        for view in locationViews {
            var scaledBy = CGFloat(scale(from: view.transform))
            let ratio = self.overlayLayer.frame.width / UIScreen.main.bounds.width

            let textLayer = CenterTextLayer()
            
            var scaleTranslation = scaledBy
            if scaledBy > 1 {
                scaleTranslation = -1 * scaledBy
            }
            
            if view.text == nil {
                return
            }
            
            let variable_width = 12 * view.text!.count + 15
            textLayer.frame = CGRect(x: view.frame.origin.x * ratio, y: self.overlayLayer.frame.height - view.frame.origin.y * ratio - ratio * 50, width: ratio * CGFloat(variable_width), height: ratio * 50)
            textLayer.string = view.text
            textLayer.fontSize = view.font!.pointSize * ratio
            textLayer.font = view.font
            textLayer.isWrapped = true
            textLayer.foregroundColor = view.textColor?.cgColor
            textLayer.shouldRasterize = true
            textLayer.cornerRadius = 20
            textLayer.rasterizationScale = UIScreen.main.scale
            textLayer.backgroundColor = view.backgroundColor?.cgColor
            
            if view.textAlignment == .center {
                textLayer.alignmentMode = .center
            }
            else if view.textAlignment == .left {
                textLayer.alignmentMode = .left
            }
            else if view.textAlignment == .right {
                textLayer.alignmentMode = .right
            }
            
            textLayer.transform = CATransform3DMakeScale(CGFloat(scaledBy), CGFloat(scaledBy), 1);

            let radians = atan2(view.transform.b, view.transform.a)
            textLayer.transform = CATransform3DMakeRotation(-radians, 0.0, 0.0, 1.0)
            
            overlayLayer.addSublayer(textLayer)
        }
        self.postButton.isHidden = true
        
        self.nextButton.isHidden = true
        self.postButton.isHidden = true
        self.textButton.isHidden = true
        self.hourglassButton.isHidden = true
        self.closeButton.isHidden = true
        self.locationButton.isHidden = true
        self.upperCoverView.isHidden = true
        self.selectedGroupLabel.isHidden = true
        self.postCoverView.isHidden = true
        self.coverView.isHidden = true
        self.captionButton.isHidden = true
        
        self.activityIndicatorView.isHidden = false
        self.activityIndicatorView.color = .white
        self.activityIndicatorView.startAnimating()
        self.sharingLabel.isHidden = false
        
        self.makeVideo(fromVideoAt: videoUrl) { exportedURL in
          guard let exportedURL = exportedURL else {
            return
          }
//            This is to test
//            self.setVideoDimensions()
//            self.player.url = exportedURL
//            self.player.playFromBeginning()
            
            var postLocation = ""
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(self.pickedLocation)
                postLocation = (String(data: data, encoding: .utf8) ?? "").toBase64()
            }
            catch {}

            Database.database().createGroupPost(withImage: self.imageFromVideo(url: exportedURL, at: 0), withVideo: exportedURL, caption: self.captionTextView.text ?? "", groupId: selectedGroup.groupId, location: postLocation, isTempPost: self.isTempPost, completion: { (postId) in
                if postId == "" {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true

                    NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                    self.dismiss(animated: true, completion: {
                        self.player.pause()
                    })
                    return
                }
                Database.database().userPosted(completion: { _ in })
                Database.database().groupExists(groupId: selectedGroup.groupId, completion: { (exists) in
                    if exists {
                        Database.database().fetchGroupPost(groupId: selectedGroup.groupId, postId: postId, completion: { (post) in
                            // send the notification each each user in the group
                            Database.database().fetchGroupMembers(groupId: selectedGroup.groupId, completion: { (members) in
                                members.forEach({ (member) in
                                    if member.uid != currentLoggedInUserId{
                                        Database.database().createNotification(to: member, notificationType: NotificationType.newGroupPost, group: selectedGroup, groupPost: post) { (err) in
                                            if err != nil {
                                                return
                                            }
                                        }
                                    }
                                })
                            }) { (_) in}
                        })
                    }
                    else {
                        return
                    }
                })
                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("updatedUser"), object: nil)
                self.dismiss(animated: true, completion: {
                    self.player.stop()
                })
            })
        }
    }
    
    // -------------------------------------------------------
    // MARK: VIDEO EDITOR
    
    func setOverlaySize(fromVideoAt videoURL: URL){
        let asset = AVURLAsset(url: videoURL)
        guard let assetTrack = asset.tracks(withMediaType: .video).first else { return }
        let videoInfo = orientation(from: assetTrack.preferredTransform)
        
        let videoSize: CGSize
        if videoInfo.isPortrait {
          videoSize = CGSize(
            width: assetTrack.naturalSize.height,
            height: assetTrack.naturalSize.width)
        } else {
          videoSize = assetTrack.naturalSize
        }
        
        self.overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
    }
    
    func makeVideo(fromVideoAt videoURL: URL, onComplete: @escaping (URL?) -> Void) {
      let asset = AVURLAsset(url: videoURL)
      let composition = AVMutableComposition()
      
      guard
        let compositionTrack = composition.addMutableTrack(
          withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
        let assetTrack = asset.tracks(withMediaType: .video).first
        else {
          print("Something is wrong with the asset.")
          onComplete(nil)
          return
      }
      
      do {
        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
        
        if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
          let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid) {
          try compositionAudioTrack.insertTimeRange(
            timeRange,
            of: audioAssetTrack,
            at: .zero)
        }
      } catch {
        print(error)
        onComplete(nil)
        return
      }
      
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        let videoInfo = orientation(from: assetTrack.preferredTransform)
      
        let videoSize: CGSize
            if videoInfo.isPortrait {
                videoSize = CGSize(
                    width: assetTrack.naturalSize.height,
                    height: assetTrack.naturalSize.width
                )
            } else {
                videoSize = assetTrack.naturalSize
        }
      
        
        let backgroundLayer = CALayer()
        backgroundLayer.frame = CGRect(origin: .zero, size: videoSize)
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        overlayLayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: videoSize)
        videoLayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: videoSize)
        
      
      let outputLayer = CALayer()
      outputLayer.frame = CGRect(origin: .zero, size: videoSize)
//      outputLayer.addSublayer(backgroundLayer)
      outputLayer.addSublayer(videoLayer)
      outputLayer.addSublayer(overlayLayer)
        
      let videoComposition = AVMutableVideoComposition()
      videoComposition.renderSize = videoSize
      videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderScale = 1.0
      videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
        postProcessingAsVideoLayer: videoLayer,
        in: outputLayer)
      
      let instruction = AVMutableVideoCompositionInstruction()
      instruction.timeRange = CMTimeRange(
        start: .zero,
        duration: composition.duration)
      videoComposition.instructions = [instruction]
      let layerInstruction = compositionLayerInstruction(
        for: compositionTrack,
        assetTrack: assetTrack)
      instruction.layerInstructions = [layerInstruction]
      
      guard let export = AVAssetExportSession(
        asset: composition,
        presetName: AVAssetExportPresetHighestQuality)
        else {
          print("Cannot create export session.")
          onComplete(nil)
          return
      }
      
      let videoName = UUID().uuidString
      let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(videoName)
        .appendingPathExtension("mov")
      
      export.videoComposition = videoComposition
      export.outputFileType = .mov
      export.outputURL = exportURL
      
      export.exportAsynchronously {
        DispatchQueue.main.async {
          switch export.status {
          case .completed:
            onComplete(exportURL)
          default:
            print("Something went wrong during export.")
            print(export.error ?? "unknown error")
            onComplete(nil)
            break
          }
        }
      }
    }
    
    private func addImage(to layer: CALayer, videoSize: CGSize) {
      let image = #imageLiteral(resourceName: "arrow_left")
      let imageLayer = CALayer()
      
      let aspect: CGFloat = image.size.width / image.size.height
      let width = videoSize.width
      let height = width / aspect
      imageLayer.frame = CGRect(
        x: 0,
        y: -height * 0.15,
        width: width,
        height: height)
      
      imageLayer.contents = image.cgImage
      layer.addSublayer(imageLayer)
    }
    
    private func add(text: String, to layer: CALayer, videoSize: CGSize) {
      let attributedText = NSAttributedString(
        string: text,
        attributes: [
          .font: UIFont(name: "ArialRoundedMTBold", size: 60) as Any,
            .foregroundColor: UIColor.green,
          .strokeColor: UIColor.white,
          .strokeWidth: -3])
      
      let textLayer = CATextLayer()
      textLayer.string = attributedText
      textLayer.shouldRasterize = true
      textLayer.rasterizationScale = UIScreen.main.scale
      textLayer.backgroundColor = UIColor.clear.cgColor
      textLayer.alignmentMode = .center
      
      textLayer.frame = CGRect(
        x: 0,
        y: videoSize.height * 0.66,
        width: videoSize.width,
        height: 150)
      textLayer.displayIfNeeded()
      
      let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
      scaleAnimation.fromValue = 0.8
      scaleAnimation.toValue = 1.2
      scaleAnimation.duration = 0.5
      scaleAnimation.repeatCount = .greatestFiniteMagnitude
      scaleAnimation.autoreverses = true
      scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      
      scaleAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
      scaleAnimation.isRemovedOnCompletion = false
      textLayer.add(scaleAnimation, forKey: "scale")
      
      layer.addSublayer(textLayer)
    }
    
    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
      var assetOrientation = UIImage.Orientation.up
      var isPortrait = false
      if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
        assetOrientation = .right
        isPortrait = true
      } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
        assetOrientation = .left
        isPortrait = true
      } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
        assetOrientation = .up
      } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
        assetOrientation = .down
      }
      
      return (assetOrientation, isPortrait)
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
      let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
      let transform = assetTrack.preferredTransform
      
      instruction.setTransform(transform, at: .zero)
      
      return instruction
    }
}


extension EditTempVideoController: PlayerDelegate {
    func playerReady(_ player: Player) {
        
    }
    
    func playerPlaybackStateDidChange(_ player: Player) {
        
    }
    
    func playerBufferingStateDidChange(_ player: Player) {
        player.playFromCurrentTime()
    }
    
    func playerBufferTimeDidChange(_ bufferTime: Double) {
        
    }
    
    func player(_ player: Player, didFailWithError error: Error?) {
        
    }
}



extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    
    func toImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
        let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImageFromMyView!
    }
    
 
    
    @objc func toImageView() -> UIImageView {
        let tempImageView = UIImageView()
        tempImageView.image = toImage()
        tempImageView.frame = frame
        tempImageView.contentMode = .scaleAspectFit
        return tempImageView
    }
    
   
}
