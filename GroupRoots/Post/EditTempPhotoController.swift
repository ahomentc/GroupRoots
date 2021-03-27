//
//  EditTempPhotoController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/22/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import EasyPeasy
import FirebaseAuth
import LocationPicker
import SGImageCache
import MapKit
import FirebaseDatabase
import YPImagePicker
import AVFoundation
import SwiftyDraw
import NVActivityIndicatorView

enum FilterType : String {
    case Chrome = "CIPhotoEffectChrome"
    case Fade = "CIPhotoEffectFade"
    case Instant = "CIPhotoEffectInstant"
    case Mono = "CIPhotoEffectMono"
    case Noir = "CIPhotoEffectNoir"
    case Process = "CIPhotoEffectProcess"
    case Tonal = "CIPhotoEffectTonal"
    case Transfer =  "CIPhotoEffectTransfer"
}

class EditTempPhotoController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate, ModifyTextViewDelegate, UIColorPickerViewControllerDelegate, UIFontPickerViewControllerDelegate, CaptionTextDelegate {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var isTempPost = true
    
    var backgroundImage: UIImage?
    
    var suggestedLocation: CLLocation?
    var pickedLocation: PostLocation?
    
    var selectedVideoURL: URL?
    
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
                    self.downloadButton.frame = CGRect(x: 20, y: UIScreen.main.bounds.height - 140, width: 50, height: 50)
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
                self.downloadButton.frame = CGRect(x: 20, y: UIScreen.main.bounds.height - 140, width: 50, height: 50)
                self.showSelectedGroup()
                self.hourglassButton.isHidden = false
                self.postButton.isHidden = false
                self.nextButton.isHidden = true
            }
        }
    }
        
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
        label.layer.zPosition = 22
        return label
    }()
    
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "arrow_left"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 10
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
        button.backgroundColor = UIColor(white: 1, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Send", for: .normal)
        button.layer.zPosition = 22
        return button
    }()
    
    let hourglassButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "hourglass_24"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(toggleTempPost), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.isHidden = true
        button.layer.zPosition = 22
        return button
    }()
    
    let captionButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "caption"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(showCaptionTextView), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 10
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let captionTextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Caption", for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.addTarget(self, action: #selector(showCaptionTextView), for: .touchUpInside)
        button.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        button.layer.zPosition = 12
        
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
        button.layer.zPosition = 10
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let locationTextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Location", for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.addTarget(self, action: #selector(pickLocation), for: .touchUpInside)
        button.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        button.layer.zPosition = 12
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let drawButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "draw_icon"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(startDrawing), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 10
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let drawTextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Draw", for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.addTarget(self, action: #selector(startDrawing), for: .touchUpInside)
        button.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        button.layer.zPosition = 12
        
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
        button.layer.zPosition = 10
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let textTextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Text", for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.addTarget(self, action: #selector(addText), for: .touchUpInside)
        button.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        button.layer.zPosition = 12
        
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
        button.layer.zPosition = 10
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let colorButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "color_circle"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(changeBackgroundColor), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 10
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let colorTextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Background", for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.addTarget(self, action: #selector(changeBackgroundColor), for: .touchUpInside)
        button.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        button.layer.zPosition = 12
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let doneDrawingButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
        button.backgroundColor = .clear
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.isHidden = true
        button.layer.zPosition = 20
        button.addTarget(self, action: #selector(doneDrawing), for: .touchUpInside)
        return button
    }()
    
    let colorDrawingButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "color_circle"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(changeDrawingColor), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 10
        button.isHidden = true
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let undoDrawingButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "undo_icon"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(undoDrawing), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 10
        button.isHidden = true
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let galleryPlusButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "gallery_plus"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(addImageFromGallery), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 10
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let galleryPlusTextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Add Photo", for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.addTarget(self, action: #selector(addImageFromGallery), for: .touchUpInside)
        button.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        button.layer.zPosition = 12
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
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
    
    let downloadButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "download_icon"), for: .normal)
        button.backgroundColor = .clear
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 20
        button.addTarget(self, action: #selector(handleDownload), for: .touchUpInside)
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
        textView.textColor = .black
        textView.tag = 1
        textView.layer.zPosition = 25
        return textView
    }()
    
    let stickerButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "sticker_icon_2"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(selectSticker), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 10
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let stickerTextButton: UIButton = {
        let button = UIButton()
        button.setTitle("Group Stickers", for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.addTarget(self, action: #selector(selectSticker), for: .touchUpInside)
        button.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right
        button.layer.zPosition = 12
        
        button.layer.backgroundColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        button.layer.shadowOpacity = 0.2
        button.layer.shadowRadius = 2.0
        return button
    }()
    
    let savedLabel: UILabel = {
        let label = UILabel()
        label.text = "Saved"
        label.textColor = UIColor.white
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        label.layer.zPosition = 12
        label.isHidden = true
        
        label.layer.backgroundColor = UIColor.clear.cgColor
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        label.layer.shadowOpacity = 0.2
        label.layer.shadowRadius = 2.0
        return label
    }()
    
    let drawView = SwiftyDrawView()
    
    var textViews = [UITextView]()
    var activeTextView = UITextView()
    var imageViews = [UIImageView]()
    var locationViews = [UILabel]()
    
    var photoModified = false
    
    override func viewWillAppear(_ animated: Bool) {
//        self.nextButton.isHidden = false
//        self.postButton.isHidden = true
        self.textButton.isHidden = false
//        self.hourglassButton.isHidden = true
        self.closeButton.isHidden = false
        self.upperCoverView.isHidden = false
        self.coverView.isHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureReconizer = UITapGestureRecognizer(target: self, action: #selector(closeTextViewKeyboard))
        tapGestureReconizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureReconizer)
        
        let backgroundImageBlurView = UIImageView(frame: view.frame)
        backgroundImageBlurView.contentMode = UIView.ContentMode.scaleAspectFill
        backgroundImageBlurView.image = backgroundImage
        backgroundImageBlurView.layer.zPosition = 0
        view.insertSubview(backgroundImageBlurView, at: 0)
        
        let blurEffect = UIBlurEffect(style: .regular)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.frame = view.frame
        blurredEffectView.isUserInteractionEnabled = false
        blurredEffectView.layer.zPosition = 1
        view.insertSubview(blurredEffectView, at: 1)
        
        self.view.backgroundColor = UIColor.black
        let backgroundImageView = UIImageView(frame: view.frame)
        backgroundImageView.contentMode = UIView.ContentMode.scaleAspectFit
        backgroundImageView.image = backgroundImage
        backgroundImageView.layer.zPosition = 2
        backgroundImageView.layer.cornerRadius = 5
        backgroundImageView.clipsToBounds = true
        view.insertSubview(backgroundImageView, at: 2)
        
        drawView.frame = self.view.frame
        drawView.layer.zPosition = 20
        drawView.isEnabled = false
        drawView.brush.color = Color(.white)
        drawView.brush.width = 5.0
        self.view.insertSubview(drawView, at: 20)
        
        // get the average color of the image
        if backgroundImage != nil {
            guard let inputImage = CIImage(image: backgroundImage!) else { return }
            let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
            guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return }
            guard let outputImage = filter.outputImage else { return }
            var bitmap = [UInt8](repeating: 0, count: 4)
            let context = CIContext(options: [.workingColorSpace: kCFNull])
            context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
            let avgRed = CGFloat(bitmap[0]) / 255
            let avgGreen = CGFloat(bitmap[1]) / 255
            let avgBlue = CGFloat(bitmap[2]) / 255
            let avgAlpha = CGFloat(bitmap[3]) / 255
            self.view.backgroundColor = UIColor.init(red: avgRed, green: avgGreen, blue: avgBlue, alpha: avgAlpha)
        }
        
        closeButton.frame = CGRect(x: 10, y: 15, width: 40, height: 40)
        closeButton.layer.zPosition = 20
        self.view.insertSubview(closeButton, at: 12)
        
//        hourglassButton.frame = CGRect(x: UIScreen.main.bounds.width - 70, y: UIScreen.main.bounds.height - 140, width: 55, height: 55)
//        self.view.insertSubview(hourglassButton, at: 12)
        
        hourglassButton.frame = CGRect(x: 20, y: UIScreen.main.bounds.height - 72, width: 50, height: 50)
        self.view.insertSubview(hourglassButton, at: 12)
        
        textButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 15, width: 45, height: 45)
        self.view.insertSubview(textButton, at: 12)
        
        textTextButton.frame = CGRect(x: UIScreen.main.bounds.width - 175, y: 17, width: 100, height: 40)
        self.view.insertSubview(textTextButton, at: 12)
        
        doneTextButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 15, width: 40, height: 40)
        self.view.insertSubview(doneTextButton, at: 12)
        
        doneDrawingButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 35, width: 40, height: 40)
        self.view.insertSubview(doneDrawingButton, at: 15)
        
        captionButton.frame = CGRect(x: UIScreen.main.bounds.width - 55, y: 80, width: 35, height: 35)
        self.view.insertSubview(captionButton, at: 12)
        
        captionTextButton.frame = CGRect(x: UIScreen.main.bounds.width - 175, y: 77, width: 100, height: 40)
        self.view.insertSubview(captionTextButton, at: 12)
        
        locationButton.frame = CGRect(x: UIScreen.main.bounds.width - 67, y: 125, width: 60, height: 60)
        self.view.insertSubview(locationButton, at: 12)
        
        locationTextButton.frame = CGRect(x: UIScreen.main.bounds.width - 175, y: 137, width: 100, height: 40)
        self.view.insertSubview(locationTextButton, at: 12)
        
        galleryPlusButton.frame = CGRect(x: UIScreen.main.bounds.width - 58, y: 190, width: 50, height: 50)
        self.view.insertSubview(galleryPlusButton, at: 12)
        
        galleryPlusTextButton.frame = CGRect(x: UIScreen.main.bounds.width - 175, y: 197, width: 100, height: 40)
        self.view.insertSubview(galleryPlusTextButton, at: 12)
        
        drawButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 255, width: 50, height: 50)
        self.view.insertSubview(drawButton, at: 12)
        
        drawTextButton.frame = CGRect(x: UIScreen.main.bounds.width - 175, y: 257, width: 100, height: 40)
        self.view.insertSubview(drawTextButton, at: 12)
        
        colorButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 312, width: 50, height: 50)
        self.view.insertSubview(colorButton, at: 12)
        
        colorTextButton.frame = CGRect(x: UIScreen.main.bounds.width - 175, y: 317, width: 100, height: 40)
        self.view.insertSubview(colorTextButton, at: 12)
        
        colorDrawingButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 100, width: 50, height: 50)
        self.view.insertSubview(colorDrawingButton, at: 12)
        
        undoDrawingButton.frame = CGRect(x: UIScreen.main.bounds.width - 125, y: 32, width: 50, height: 50)
        self.view.insertSubview(undoDrawingButton, at: 12)
        
        trashIcon.frame = CGRect(x: UIScreen.main.bounds.width/2 - 25, y: UIScreen.main.bounds.height - 70, width: 50, height: 50)
        self.view.insertSubview(trashIcon, at: 12)
        
        stickerButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 372, width: 50, height: 50)
        self.view.insertSubview(stickerButton, at: 12)
        
        stickerTextButton.frame = CGRect(x: UIScreen.main.bounds.width - 175, y: 377, width: 100, height: 40)
        self.view.insertSubview(stickerTextButton, at: 12)
        
        savedLabel.frame = CGRect(x: UIScreen.main.bounds.width/2 - 50, y: UIScreen.main.bounds.height/2 - 50, width: 100, height: 100)
        self.view.insertSubview(savedLabel, at: 12)
        
        if self.selectedGroup != nil {
            self.downloadButton.frame = CGRect(x: 20, y: UIScreen.main.bounds.height - 140, width: 50, height: 50)
            self.view.insertSubview(downloadButton, at: 12)
        }
        else {
            downloadButton.frame = CGRect(x: 20, y: UIScreen.main.bounds.height - 65, width: 50, height: 50)
            self.view.insertSubview(downloadButton, at: 12)
        }
        
        self.view.insertSubview(activityIndicatorView, at: 20)
        
        sharingLabel.frame = CGRect(x: UIScreen.main.bounds.width - 145, y: UIScreen.main.bounds.height - 40, width: 90, height: 30)
        self.view.insertSubview(sharingLabel, at: 20)
        
        postCoverView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        postCoverView.layer.cornerRadius = 0
        postCoverView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 210, width: UIScreen.main.bounds.width, height: 250)
        postCoverView.isUserInteractionEnabled = false
        self.view.insertSubview(postCoverView, at: 3)
        
        coverView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        coverView.layer.cornerRadius = 0
        coverView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 210, width: UIScreen.main.bounds.width, height: 250)
        coverView.isUserInteractionEnabled = false
        self.view.insertSubview(coverView, at: 3)
        
        upperCoverView.heightAnchor.constraint(equalToConstant: 170).isActive = true
        upperCoverView.layer.cornerRadius = 0
        upperCoverView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 170)
        upperCoverView.isUserInteractionEnabled = false
        self.view.insertSubview(upperCoverView, at: 3)
        
        textEditBackground.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        textEditBackground.layer.cornerRadius = 0
        textEditBackground.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        textEditBackground.isUserInteractionEnabled = false
        self.view.insertSubview(textEditBackground, at: 4)
        
        nextButton.frame = CGRect(x: UIScreen.main.bounds.width-120, y: UIScreen.main.bounds.height - 70, width: 100, height: 50)
        nextButton.layer.cornerRadius = 20
        self.view.insertSubview(nextButton, at: 12)
        
        postButton.frame = CGRect(x: UIScreen.main.bounds.width-120, y: UIScreen.main.bounds.height - 70, width: 100, height: 50)
        postButton.layer.cornerRadius = 20
        self.view.insertSubview(postButton, at: 12)
        
        self.view.insertSubview(selectedGroupLabel, at: 12)
        self.selectedGroupLabel.anchor(top: self.postButton.topAnchor, left: self.hourglassButton.rightAnchor, bottom: self.postButton.bottomAnchor, right: self.postButton.leftAnchor, paddingLeft: 10, paddingRight: 20)
        
//        UITextView.appearance().tintColor = UIColor.white
        
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
        
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
            UIView.animate(withDuration: 1) {
                self.textTextButton.alpha = 0
                self.captionTextButton.alpha = 0
                self.locationTextButton.alpha = 0
                self.galleryPlusTextButton.alpha = 0
                self.drawTextButton.alpha = 0
                self.colorTextButton.alpha = 0
                self.stickerTextButton.alpha = 0
            }
        }
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { timer in
            self.textTextButton.isHidden = true
            self.captionTextButton.isHidden = true
            self.locationTextButton.isHidden = true
            self.galleryPlusTextButton.isHidden = true
            self.drawTextButton.isHidden = true
            self.colorTextButton.isHidden = true
            self.stickerTextButton.isHidden = true
        }
    }
    
    @objc func panHandler(gestureRecognizer: UIPanGestureRecognizer){
        if isDrawing {
            return
        }
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
            self.colorButton.isHidden = true
            self.galleryPlusButton.isHidden = true
            self.drawButton.isHidden = true
            self.stickerButton.isHidden = true
            self.downloadButton.isHidden = true
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
            self.colorButton.isHidden = false
            self.galleryPlusButton.isHidden = false
            self.drawButton.isHidden = false
            self.stickerButton.isHidden = false
            self.downloadButton.isHidden = false
        }
    }
    
    @objc func pinchHandler(pinch: UIPinchGestureRecognizer){
        if isDrawing {
            return
        }
        if let view = pinch.view {
            view.transform = view.transform.scaledBy(x: pinch.scale, y: pinch.scale)
            pinch.scale = 1
            if let textView = view as? UITextView {
                textView.centerTextVertically()
            }
        }
    }
    
    @objc func rotateHandler(sender: UIRotationGestureRecognizer){
        if isDrawing {
            return
        }
        if let view = sender.view {
            view.transform = view.transform.rotated(by: sender.rotation)
            sender.rotation = 0
            if let textView = view as? UITextView {
                textView.centerTextVertically()
            }
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
    
    
    var isDrawing = false
    @objc func startDrawing() {
        self.hideHelpTexts()
        
        isDrawing = true
        self.drawView.isEnabled = true
        self.doneDrawingButton.isHidden = false
        self.colorDrawingButton.isHidden = false
        self.undoDrawingButton.isHidden = false
        
        self.nextButton.isHidden = true
        self.postButton.isHidden = true
        self.textButton.isHidden = true
        self.hourglassButton.isHidden = true
        self.closeButton.isHidden = true
        self.locationButton.isHidden = true
        self.selectedGroupLabel.isHidden = true
        self.captionButton.isHidden = true
        self.colorButton.isHidden = true
        self.galleryPlusButton.isHidden = true
        self.drawButton.isHidden = true
        self.stickerButton.isHidden = true
        self.downloadButton.isHidden = true
        
        for view in self.locationViews {
            view.isUserInteractionEnabled = false
        }
        
        for imageView in self.imageViews {
            imageView.isUserInteractionEnabled = false
        }
        
        for textView in self.textViews {
            textView.isUserInteractionEnabled = false
        }
    }
    
    @objc func doneDrawing() {
        isDrawing = false
        self.drawView.isEnabled = false
        self.doneDrawingButton.isHidden = true
        self.colorDrawingButton.isHidden = true
        self.undoDrawingButton.isHidden = true
        
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
        self.colorButton.isHidden = false
        self.galleryPlusButton.isHidden = false
        self.drawButton.isHidden = false
        self.stickerButton.isHidden = false
        self.downloadButton.isHidden = false
        
        for view in self.locationViews {
            view.isUserInteractionEnabled = false
        }
        
        for imageView in self.imageViews {
            imageView.isUserInteractionEnabled = true
        }
        
        for textView in self.textViews {
            textView.isUserInteractionEnabled = true
        }
        
        self.photoModified = true
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
    
    @objc func undoDrawing() {
        drawView.undo()
    }
    
    var isChangingTextColor = true
    var isChangingTextBackgroundColor = false
    var isChangingBackgroundColor = false
    var isChangingDrawingColor = false
    
    @objc func changeDrawingColor() {
        if #available(iOS 14.0, *) {
            isChangingDrawingColor = true
            isChangingTextColor = false
            isChangingBackgroundColor = false
            isChangingTextBackgroundColor = false
            
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
    
    @objc func changeBackgroundColor() {
        self.photoModified = true
        if #available(iOS 14.0, *) {
            isChangingTextColor = false
            isChangingBackgroundColor = true
            isChangingTextBackgroundColor = false
            isChangingDrawingColor = false
            
            let picker = UIColorPickerViewController()
            picker.delegate = self
            picker.selectedColor = .black
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
    
    func changeTextViewColor() {
        if #available(iOS 14.0, *) {
            isChangingTextColor = true
            isChangingBackgroundColor = false
            isChangingTextBackgroundColor = false
            isChangingDrawingColor = false
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
            isChangingBackgroundColor = false
            isChangingTextBackgroundColor = true
            isChangingDrawingColor = false
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
        let color = viewController.selectedColor
        if isChangingTextColor {
            self.activeTextView.textColor = color
        }
        else if isChangingTextBackgroundColor {
            self.activeTextView.backgroundColor = color
        }
        else if isChangingBackgroundColor {
            self.view.backgroundColor = color
        }
        else if isChangingDrawingColor {
            self.drawView.brush.color = Color(color)
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
        
        self.textButton.isHidden = true
        self.closeButton.isHidden = true
        self.locationButton.isHidden = true
        self.captionButton.isHidden = true
        self.colorButton.isHidden = true
        self.galleryPlusButton.isHidden = true
        self.drawButton.isHidden = true
        self.stickerButton.isHidden = true
        self.downloadButton.isHidden = true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        print("stopped editing")
        self.textEditBackground.isHidden = true
        self.doneTextButton.isHidden = true
        self.textButton.isHidden = false
        
        self.textButton.isHidden = false
        self.closeButton.isHidden = false
        self.locationButton.isHidden = false
        self.captionButton.isHidden = false
        self.colorButton.isHidden = false
        self.galleryPlusButton.isHidden = false
        self.drawButton.isHidden = false
        self.stickerButton.isHidden = false
        self.downloadButton.isHidden = false
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
    
    var first = true
    @objc private func addText() {
        self.hideHelpTexts()
        
        self.photoModified = true
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
        textView.layer.zPosition = 10
//        textView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panHandler))
        panGesture.delegate = self
        textView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchHandler))
        pinchGesture.delegate = self
        textView.addGestureRecognizer(pinchGesture)
        
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateHandler))
        rotateGesture.delegate = self
        textView.addGestureRecognizer(rotateGesture)
        
        self.view.insertSubview(textView, at: 10)
//        textView.easy.layout(Left(10), Right(10), Top(200)) // this makes multi line work but weird behavior
        textView.centerTextVertically()
        
        self.textViews.append(textView)
        let modifyTextView = ModifyTextView(frame: CGRect(x: 0, y: 0, width: 10, height: 70))
        modifyTextView.delegate = self
        textView.inputAccessoryView = modifyTextView
                
//        UITextView.appearance().tintColor = UIColor.white
    
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
    
    func hideButtons() {
        self.captionButton.isHidden = true
        self.colorButton.isHidden = true
        self.galleryPlusButton.isHidden = true
        self.drawButton.isHidden = true
        self.stickerButton.isHidden = true
        self.downloadButton.isHidden = true
    }
    
    func hideHelpTexts(){
        self.captionTextButton.alpha = 0
        self.colorTextButton.alpha = 0
        self.galleryPlusTextButton.alpha = 0
        self.drawTextButton.alpha = 0
        self.stickerTextButton.alpha = 0
        self.textTextButton.alpha = 0
        self.locationTextButton.alpha = 0
    }
        
    @objc private func addImageFromGallery() {
        self.photoModified = true
        var config = YPImagePickerConfiguration()
        config.library.isSquareByDefault = false
        config.shouldSaveNewPicturesToAlbum = false
        config.library.mediaType = .photo
        config.showsPhotoFilters = false
        config.hidesStatusBar = false
        config.startOnScreen = YPPickerScreen.library
        config.targetImageSize = .cappedTo(size: 600)
        config.video.compression = AVAssetExportPresetMediumQuality
        let picker = YPImagePicker(configuration: config)
        
        picker.didFinishPicking { [unowned picker] items, cancelled in
            if cancelled {
                print("Picker was canceled")
                picker.dismiss(animated: true, completion: nil)
                return
            }
            _ = items.map { print("🧀 \($0)") }
            if let firstItem = items.first {
                switch firstItem {
                case .photo(let photo):
                    self.dismiss(animated: true, completion: {
                        let imageView = UIImageView(frame: CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-75, width: 300, height: 300))
                        imageView.image = photo.image
                        imageView.isUserInteractionEnabled = true
                        imageView.contentMode = .scaleAspectFit
                        imageView.layer.zPosition = 9
                        
                        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panHandler))
                        panGesture.delegate = self
                        imageView.addGestureRecognizer(panGesture)
                        
                        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchHandler))
                        pinchGesture.delegate = self
                        imageView.addGestureRecognizer(pinchGesture)
                        
                        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(self.rotateHandler))
                        rotateGesture.delegate = self
                        imageView.addGestureRecognizer(rotateGesture)
                        
                        self.imageViews.append(imageView)
                        self.view.insertSubview(imageView, at: 9)
                    })
                case .video(let _):
                    break
                }
            }
        }
        present(picker, animated: true, completion: nil)
    }
    
    @objc private func addLocationSticker(location: String) {
        self.photoModified = true
        
        for view in self.locationViews {
            view.removeFromSuperview()
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
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchHandler))
        pinchGesture.delegate = self
        label.addGestureRecognizer(pinchGesture)
        
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotateHandler))
        rotateGesture.delegate = self
        label.addGestureRecognizer(rotateGesture)
        
        self.view.insertSubview(label, at: 10)
        
        self.locationViews.append(label)
    }
    
    @objc private func showCaptionTextView() {
        self.hideHelpTexts()
        
        self.captionTextView.isHidden = false
//        UITextView.appearance().tintColor = UIColor.black
        self.captionTextView.becomeFirstResponder()
    }
    
    @objc private func selectSticker() {
        self.hideHelpTexts()
        
        let groupStickersController = GroupStickersController()
        groupStickersController.group = self.selectedGroup
        groupStickersController.backgroundImage = self.backgroundImage
        groupStickersController.didFinishPicking { [unowned groupStickersController] sticker, cancelled in
            if !cancelled {
                
                let sync = DispatchGroup()
                sync.enter()
                var sticker_img = CustomImageView.imageWithColor(color: .clear)
                if let image = SGImageCache.image(forURL: sticker.imageUrl) {
                    sticker_img = image
                    sync.leave()
                } else {
                    SGImageCache.getImage(url: sticker.imageUrl) { [weak self] image in
                        sticker_img = image ?? CustomImageView.imageWithColor(color: .clear)
                        sync.leave()
                    }
                }
                
                sync.notify(queue: .main) {
                    self.photoModified = true
                    
                    let imageView = UIImageView(frame: CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-75, width: 300, height: 300))
                    imageView.image = sticker_img
                    imageView.isUserInteractionEnabled = true
                    imageView.contentMode = .scaleAspectFit
                    imageView.layer.zPosition = 12
                    
                    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panHandler))
                    panGesture.delegate = self
                    imageView.addGestureRecognizer(panGesture)
                    
                    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchHandler))
                    pinchGesture.delegate = self
                    imageView.addGestureRecognizer(pinchGesture)
                    
                    let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(self.rotateHandler))
                    rotateGesture.delegate = self
                    imageView.addGestureRecognizer(rotateGesture)
                    
                    self.imageViews.append(imageView)
                    self.view.insertSubview(imageView, at: 12)
                }
            }
        }
        groupStickersController.modalPresentationStyle = .overCurrentContext
        presentPanModal(groupStickersController)
        
//        let navController = UINavigationController(rootViewController: groupStickersController)
//        navController.modalPresentationStyle = .overFullScreen
//        self.present(navController, animated: true, completion: nil)
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
        let sharePhotoController = SharePhotoController()
        
        // only modify if there is a textView
        if self.textViews.count > 0 {
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
            self.colorButton.isHidden = true
            self.galleryPlusButton.isHidden = true
            self.drawButton.isHidden = true
            self.captionButton.isHidden = true
            self.stickerButton.isHidden = true
            self.downloadButton.isHidden = true

            let areaSize = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) //Your view size from where you want to make UIImage
            UIGraphicsBeginImageContext(areaSize.size);
//            UIGraphicsBeginImageContextWithOptions(areaSize.size, view.isOpaque, 0.0)
            let context : CGContext = UIGraphicsGetCurrentContext()!
            self.view.layer.render(in: context)
            let newImage : UIImage  = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext();
            sharePhotoController.selectedImage = newImage
        }
        else {
            sharePhotoController.selectedImage = self.backgroundImage
        }
        
        sharePhotoController.isTempPost = isTempPost
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
    
    @objc private func handleShare() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let selectedGroup = selectedGroup else { return }

        var postLocation = ""
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.pickedLocation)
            postLocation = (String(data: data, encoding: .utf8) ?? "").toBase64()
        }
        catch {}
        
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
        self.colorButton.isHidden = true
        self.galleryPlusButton.isHidden = true
        self.drawButton.isHidden = true
        self.captionButton.isHidden = true
        self.stickerButton.isHidden = true
        self.downloadButton.isHidden = true
        
        var imageToSend: UIImage?
        
        activityIndicatorView.isHidden = false
        activityIndicatorView.color = .white
        activityIndicatorView.startAnimating()
        
        sharingLabel.isHidden = false
        
        if self.textViews.count > 0 || self.photoModified {
            let areaSize = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 45) //Your view size from where you want to make UIImage
//            UIGraphicsBeginImageContext(areaSize.size);
            
//            UIGraphicsBeginImageContextWithOptions(areaSize.size, view.isOpaque, 0.0)
//            let context : CGContext = UIGraphicsGetCurrentContext()!
//            self.view.layer.render(in: context)
//            let newImage : UIImage  = UIGraphicsGetImageFromCurrentImageContext()!
//            UIGraphicsEndImageContext();
            
            UIGraphicsBeginImageContextWithOptions(areaSize.size, false, 0)
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            imageToSend = newImage
            
        }
        else {
            imageToSend = backgroundImage!
        }

        Database.database().createGroupPost(withImage: imageToSend, withVideo: self.selectedVideoURL, caption: self.captionTextView.text ?? "", groupId: selectedGroup.groupId, location: postLocation, isTempPost: isTempPost, completion: { (postId) in
            if postId == "" {
                self.navigationItem.rightBarButtonItem?.isEnabled = true

                NotificationCenter.default.post(name: NSNotification.Name.updateUserProfileFeed, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name.updateGroupProfile, object: nil)
                self.dismiss(animated: true, completion: nil)
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
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    @objc private func handleDownload() {
        self.hideHelpTexts()
        self.hideButtons()
        
        var showPostAndSelected = false
        if postButton.isHidden == false {
            showPostAndSelected = true
        }
        
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
        self.colorButton.isHidden = true
        self.galleryPlusButton.isHidden = true
        self.drawButton.isHidden = true
        self.captionButton.isHidden = true
        self.stickerButton.isHidden = true
        self.downloadButton.isHidden = true

        var imageToDownload: UIImage?
        
        if self.textViews.count > 0 || self.photoModified {
            let areaSize = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 35) //Your view size from
            UIGraphicsBeginImageContextWithOptions(areaSize.size, false, 0)
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            imageToDownload = newImage
            
        }
        else {
            imageToDownload = backgroundImage!
        }
        
        if showPostAndSelected {
            self.postButton.isHidden = false
            self.hourglassButton.isHidden = false
            self.selectedGroupLabel.isHidden = false
        }
        else {
            self.nextButton.isHidden = false
        }
        self.textButton.isHidden = false
        self.closeButton.isHidden = false
        self.locationButton.isHidden = false
        self.upperCoverView.isHidden = false
        self.postCoverView.isHidden = false
        self.coverView.isHidden = false
        self.colorButton.isHidden = false
        self.galleryPlusButton.isHidden = false
        self.drawButton.isHidden = false
        self.captionButton.isHidden = false
        self.stickerButton.isHidden = false
        self.downloadButton.isHidden = false
        
        UIImageWriteToSavedPhotosAlbum(imageToDownload!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        else {
            self.savedLabel.transform = CGAffineTransform(scaleX: 0, y: 0)
            self.savedLabel.isHidden = false
            self.savedLabel.alpha = 1
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
                self.savedLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }, completion: nil)
            UIView.animate(withDuration: 0.2, delay: 0.3, options: [.allowUserInteraction, .curveEaseIn], animations: {
                self.savedLabel.transform = CGAffineTransform.identity
            }, completion: nil)
            UIView.animate(withDuration: 0.3, delay: 1, options: [.allowUserInteraction, .curveEaseIn], animations: {
                self.savedLabel.alpha = 0
            }, completion: nil)
            Timer.scheduledTimer(withTimeInterval: 1.3, repeats: false) { timer in
                self.savedLabel.isHidden = true
            }
        }
    }
}

extension UIImage {
    func addFilter(filter : FilterType) -> UIImage {
        let filter = CIFilter(name: filter.rawValue)
        // convert UIImage to CIImage and set as input
        let ciInput = CIImage(image: self)
        filter?.setValue(ciInput, forKey: "inputImage")
        // get output CIImage, render as CGImage first to retain proper UIImage scale
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        //Return the image
        return UIImage(cgImage: cgImage!)
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

extension UITextView {
    func centerTextVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}

protocol ModifyTextViewDelegate {
    func changeTextViewColor()
    func changeTextViewFont()
    func changeTextAlignment(alignment: NSTextAlignment)
    func changeTextBackgroundColor()
}

class ModifyTextView: UIView, UIColorPickerViewControllerDelegate {
    
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "cancel_shadow"), for: .normal)
        button.backgroundColor = .clear
//        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    let colorButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "color_circle"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(changeColor), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    let fontButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "font"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(changeFont), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    let alignButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "align_center"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(changeAlignment), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    let backgroundButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "background"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(changeBackgroundColor), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    var textAlignment = NSTextAlignment.center
    var delegate: ModifyTextViewDelegate?
    
    //initWithFrame to init view from code
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
  
    //initWithCode to init view from xib or storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    @objc private func changeAlignment() {
        if self.textAlignment == NSTextAlignment.left {
            self.textAlignment = NSTextAlignment.right
            self.alignButton.setImage(#imageLiteral(resourceName: "align_right"), for: .normal)
            self.delegate?.changeTextAlignment(alignment: .right)
        }
        else if self.textAlignment == NSTextAlignment.center {
            self.textAlignment = NSTextAlignment.left
            self.alignButton.setImage(#imageLiteral(resourceName: "align_left"), for: .normal)
            self.delegate?.changeTextAlignment(alignment: .left)
        }
        else if self.textAlignment == NSTextAlignment.right {
            self.textAlignment = NSTextAlignment.center
            self.alignButton.setImage(#imageLiteral(resourceName: "align_center"), for: .normal)
            self.delegate?.changeTextAlignment(alignment: .center)
        }
    }
    
    @objc private func changeColor() {
        self.delegate?.changeTextViewColor()
    }
    
    @objc private func changeFont() {
        self.delegate?.changeTextViewFont()
    }
    
    @objc private func changeBackgroundColor() {
        self.delegate?.changeTextBackgroundColor()
    }
  
    private func setupView() {
        backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        
        alignButton.frame = CGRect(x: UIScreen.main.bounds.width/2 - 105, y: 17, width: 36, height: 36)
        self.insertSubview(alignButton, at: 12)
        
        colorButton.frame = CGRect(x: UIScreen.main.bounds.width/2 - 47, y: 17, width: 36, height: 36)
        self.insertSubview(colorButton, at: 12)

        fontButton.frame = CGRect(x: UIScreen.main.bounds.width/2 + 11, y: 17, width: 36, height: 36)
        self.insertSubview(fontButton, at: 12)
        
        backgroundButton.frame = CGRect(x: UIScreen.main.bounds.width/2 + 69, y: 17, width: 36, height: 36)
        self.insertSubview(backgroundButton, at: 12)
        
    }
}

extension UIImageView {
    static func fromGif(frame: CGRect, resourceName: String) -> UIImageView? {
        guard let path = Bundle.main.path(forResource: resourceName, ofType: "gif") else {
            print("Gif does not exist at that path")
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: url),
            let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else { return nil }
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
        let gifImageView = UIImageView(frame: frame)
        gifImageView.animationImages = images
        return gifImageView
    }
}

// to use:
//guard let confettiImageView = UIImageView.fromGif(frame: view.frame, resourceName: "confetti") else { return }
//view.addSubview(confettiImageView)
//confettiImageView.startAnimating()

//confettiImageView.animationDuration = 3
//confettiImageView.animationRepeatCount = 1

// When you are done animating the gif and want to release the memory. (important)
// confettiImageView.animationImages = nil

protocol CaptionTextDelegate {
    func didFillCaption()
    func didEmtpyCaption()
}

class CaptionTextView: UITextView {
    
    var caption_delegate: CaptionTextDelegate?
    
    let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.lightGray
        return label
    }()
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleTextChange), name: UITextView.textDidChangeNotification, object: nil)
        addSubview(placeholderLabel)
        placeholderLabel.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 12, paddingLeft: 20)        
    }
    
    func showPlaceholderLabel() {
        placeholderLabel.isHidden = false
    }
    
    @objc private func handleTextChange() {
        placeholderLabel.isHidden = !self.text.isEmpty
        if self.text.isEmpty {
            caption_delegate?.didEmtpyCaption()
        }
        else {
            caption_delegate?.didFillCaption()
        }
    }
}
