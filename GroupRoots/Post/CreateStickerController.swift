//
//  CreateStickerController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 3/12/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import EasyPeasy
import FirebaseAuth
import FirebaseDatabase
import YPImagePicker
import AVFoundation
import SwiftyDraw
import NVActivityIndicatorView

// create sticker from:
// 1. Photo taken
// 2. Gallery

class CreateStickerController: UIViewController, UIGestureRecognizerDelegate, SwiftyDrawViewDelegate {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var backgroundImage: UIImage?
    
    var group: Group?
    
    let activityIndicatorView: NVActivityIndicatorView = {
        let activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: UIScreen.main.bounds.width - 30, y: UIScreen.main.bounds.height - 30, width: 20, height: 20), type: NVActivityIndicatorType.circleStrokeSpin)
        activityIndicatorView.layer.backgroundColor = UIColor.clear.cgColor
        activityIndicatorView.layer.shadowColor = UIColor.black.cgColor
        activityIndicatorView.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        activityIndicatorView.layer.shadowOpacity = 0.2
        activityIndicatorView.layer.shadowRadius = 2.0
        activityIndicatorView.isHidden = true
        activityIndicatorView.layer.zPosition = 22
        return activityIndicatorView
    }()
    
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "arrow_left"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 10
        button.alpha = 0
        
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
    
    let keepPhotoButton: UIButton = {
        let button = UIButton()
        button.setTitle("Use Current\nPhoto", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 15
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(useCurrentPhoto), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 15
        button.alpha = 0
        return button
    }()
    
    let useOtherPhotoButton: UIButton = {
        let button = UIButton()
        button.setTitle("Choose Other\nPhoto", for: .normal)
        button.backgroundColor = .white
        button.setTitleColor(UIColor.black, for: .normal)
        button.layer.cornerRadius = 15
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(selectImageFromGallery), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.layer.zPosition = 15
        button.alpha = 0
        return button
    }()
    
    let drawView = SwiftyDrawView()
    
    var textViews = [UITextView]()
    var activeTextView = UITextView()
    var imageViews = [UIImageView]()
    
    var photoModified = false
    
    private var path: UIBezierPath?
    private var strokeLayer: CAShapeLayer?
    
    private var _didFinishPicking: ((Sticker, Bool) -> Void)?
    public func didFinishPicking(completion: @escaping (_ items: Sticker, _ cancelled: Bool) -> Void) {
        _didFinishPicking = completion
    }
    
    let backgroundImageView: UIImageView = {
        let img = UIImageView()
        img.contentMode = UIView.ContentMode.scaleAspectFit
        img.layer.zPosition = 2
        img.layer.cornerRadius = 5
        img.clipsToBounds = true
        return img
    }()
    
    let cutImageView: UIImageView = {
        let img = UIImageView()
        img.contentMode = UIView.ContentMode.scaleAspectFit
        img.layer.zPosition = 7
        img.layer.cornerRadius = 5
        img.clipsToBounds = true
        return img
    }()
    
    private let coverView: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        backgroundView.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        backgroundView.layer.zPosition = 4
        return backgroundView
    }()
    
    let blurredEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.isUserInteractionEnabled = false
        blurredEffectView.layer.zPosition = 5
        blurredEffectView.isHidden = true
        return blurredEffectView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        self.closeButton.isHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavBar()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panHandler))
        panGesture.delegate = self
        self.view.addGestureRecognizer(panGesture)
        
        self.view.backgroundColor = UIColor.black

        backgroundImageView.frame = view.frame
        backgroundImageView.image = backgroundImage
        view.insertSubview(backgroundImageView, at: 2)
        
        coverView.frame = view.frame
        view.insertSubview(coverView, at: 4)
        
        blurredEffectView.frame = view.frame
        view.insertSubview(blurredEffectView, at: 5)
        
        cutImageView.frame = CGRect(x: UIScreen.main.bounds.width/2-150, y: UIScreen.main.bounds.height/2-150, width: 300, height: 300)
        view.insertSubview(cutImageView, at: 7)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
            self.closeButton.alpha = 1
            self.keepPhotoButton.alpha = 1
            self.useOtherPhotoButton.alpha = 1
        }, completion: nil)
        
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
        
        doneDrawingButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 15, width: 40, height: 40)
        self.view.insertSubview(doneDrawingButton, at: 15)
        
        undoDrawingButton.frame = CGRect(x: UIScreen.main.bounds.width - 125, y: 12, width: 50, height: 50)
        self.view.insertSubview(undoDrawingButton, at: 12)
        
        keepPhotoButton.frame = CGRect(x: UIScreen.main.bounds.width/2 - 150 - 7, y:  UIScreen.main.bounds.height/2-50, width: 150, height: 100)
        self.view.insertSubview(keepPhotoButton, at: 15)
        
        useOtherPhotoButton.frame = CGRect(x: UIScreen.main.bounds.width/2 + 7, y:  UIScreen.main.bounds.height/2-50, width: 150, height: 100)
        self.view.insertSubview(useOtherPhotoButton, at: 15)
    
        self.view.insertSubview(activityIndicatorView, at: 20)
        
        self.keepPhotoButton.addTarget(self, action: #selector(self.keepPhotoButtonDown), for: .touchDown)
        self.keepPhotoButton.addTarget(self, action: #selector(self.keepPhotoButtonDown), for: .touchDragInside)
        self.keepPhotoButton.addTarget(self, action: #selector(self.keepPhotoButtonUp), for: .touchDragExit)
        self.keepPhotoButton.addTarget(self, action: #selector(self.keepPhotoButtonUp), for: .touchCancel)
        self.keepPhotoButton.addTarget(self, action: #selector(self.keepPhotoButtonUp), for: .touchUpInside)
        
        self.useOtherPhotoButton.addTarget(self, action: #selector(self.useOtherPhotoButtonDown), for: .touchDown)
        self.useOtherPhotoButton.addTarget(self, action: #selector(self.useOtherPhotoButtonDown), for: .touchDragInside)
        self.useOtherPhotoButton.addTarget(self, action: #selector(self.useOtherPhotoButtonUp), for: .touchDragExit)
        self.useOtherPhotoButton.addTarget(self, action: #selector(self.useOtherPhotoButtonUp), for: .touchCancel)
        self.useOtherPhotoButton.addTarget(self, action: #selector(self.useOtherPhotoButtonUp), for: .touchUpInside)
    }
    
    // when ends drawing the undo button appears and drawing is disabled
    // drawing is enabled only after the undo button is pressed
    
    func swiftyDraw(shouldBeginDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) -> Bool {
        return true
    }
    
    func swiftyDraw(didBeginDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
        // do nothing here
    }
    
    func swiftyDraw(isDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
        // do nothing here
    }
    
    func swiftyDraw(didFinishDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
        self.undoDrawingButton.isHidden = false
        self.drawView.isEnabled = false
        self.doneDrawingButton.isHidden = false
    }
    
    func swiftyDraw(didCancelDrawingIn drawingView: SwiftyDrawView, using touch: UITouch) {
        // do nothing here
    }
    
    func configureNavBar() {
        self.navigationController?.navigationBar.height(CGFloat(0))
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = .clear
    }
        
    @objc private func selectImageFromGallery() {
        self.keepPhotoButton.isHidden = true
        self.useOtherPhotoButton.isHidden = true
        
        var config = YPImagePickerConfiguration()
        config.library.isSquareByDefault = false
        config.shouldSaveNewPicturesToAlbum = false
        config.library.mediaType = .photo
        config.showsPhotoFilters = false
        config.hidesStatusBar = false
        config.startOnScreen = YPPickerScreen.library
        config.targetImageSize = .cappedTo(size: 600)
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
                        self.backgroundImageView.image = photo.image
                        self.backgroundImage = photo.image
                    })
                case .video( _):
                    break
                }
            }
        }
        present(picker, animated: true, completion: nil)
    }
    
    @objc func keepPhotoButtonDown() {
        self.keepPhotoButton.animateButtonDown()
    }
    
    @objc func keepPhotoButtonUp() {
        self.keepPhotoButton.animateButtonUp()
    }
    
    @objc func useOtherPhotoButtonDown() {
        self.useOtherPhotoButton.animateButtonDown()
    }
    
    @objc func useOtherPhotoButtonUp() {
        self.useOtherPhotoButton.animateButtonUp()
    }

    @objc private func close() {
        self.dismiss(animated: false, completion: {
            self._didFinishPicking?(Sticker(dictionary: Dictionary()), true)
        })
    }
    
    @objc func useCurrentPhoto() {
        self.keepPhotoButton.isHidden = true
        self.useOtherPhotoButton.isHidden = true
    }
    
    @objc func undoDrawing() {
        self.undoDrawingButton.isHidden = true
        self.doneDrawingButton.isHidden = true
        self.cutImageView.isHidden = true
        self.blurredEffectView.isHidden = true
    }
    
    @objc func doneDrawing() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        self.doneDrawingButton.isHidden = true
        self.undoDrawingButton.isHidden = true
        
        if self.group == nil {
            Database.database().createSticker(withImage: cutImageView.image, completion: { (stickerId) in
                self.dismiss(animated: false, completion: {
                    Database.database().fetchSticker(stickerId: stickerId, withUID: currentLoggedInUserId, completion: { (sticker) in
                        self._didFinishPicking?(sticker, false)
                    })
                })
            })
        }
        else {
            Database.database().createSticker(withImage: cutImageView.image, groupId: self.group!.groupId, completion: { (stickerId) in
                self.dismiss(animated: false, completion: {
                    Database.database().fetchSticker(stickerId: stickerId, withUID: currentLoggedInUserId, completion: { (sticker) in
                        self._didFinishPicking?(sticker, false)
                    })
                })
            })
        }
    }
    
    @objc func panHandler(gestureRecognizer: UIPanGestureRecognizer){
        let location = gestureRecognizer.location(in: self.backgroundImageView)
        switch gestureRecognizer.state {
            case .began:
                path = UIBezierPath()
                path?.move(to: location)
                strokeLayer = CAShapeLayer()
                self.backgroundImageView.layer.addSublayer(strokeLayer!)
                strokeLayer?.strokeColor = UIColor.init(white: 1, alpha: 1).cgColor
                strokeLayer?.fillColor = UIColor.init(white: 0.8, alpha: 0.6).cgColor
                strokeLayer?.lineWidth = 15
                strokeLayer?.path = path?.cgPath
                
            case .changed:
                path?.addLine(to: location)
                strokeLayer?.path = path?.cgPath
                
            case .cancelled, .ended:
                // remove stroke from image view
                
                strokeLayer?.removeFromSuperlayer()
                strokeLayer = nil
                
                let areaSize = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 35)
                UIGraphicsBeginImageContextWithOptions(areaSize.size, false, 0)
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
//                let cutImage = backgroundImage?.imageByApplyingClippingBezierPath(path!)
                let cutImage = newImage!.imageByApplyingClippingBezierPath(path!)

                self.blurredEffectView.isHidden = false
                self.cutImageView.isHidden = false
                self.cutImageView.image = cutImage
                
                self.doneDrawingButton.isHidden = false
                self.undoDrawingButton.isHidden = false
                
                // cutImage is the one that is going to be saved

//                // mask the image view
//                let mask = CAShapeLayer()
//                mask.fillColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).cgColor
//                mask.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0).cgColor
//                mask.lineWidth = 0
//                mask.path = path?.cgPath
//                self.backgroundImageView.layer.mask = mask
//                let image = self.backgroundImageView.snapshot
//                self.backgroundImageView.layer.mask = nil
//                self.backgroundImageView.image = image

            default: break
        }
    }
}

extension UIView {
    var snapshot: UIImage {
        UIGraphicsImageRenderer(bounds: bounds).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}

extension UIImage {

    func imageByApplyingClippingBezierPath(_ path: UIBezierPath) -> UIImage {
        // Mask image using path
        let maskedImage = imageByApplyingMaskingBezierPath(path)
        
        guard let cgImage = maskedImage.cgImage else { return UIImage() }

        // Crop image to frame of path
        let croppedImage = UIImage(cgImage: cgImage.cropping(to: path.bounds)!)
        return croppedImage
    }

    func imageByApplyingMaskingBezierPath(_ path: UIBezierPath) -> UIImage {
        
        // Define graphic context (canvas) to paint on
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()

        // Set the clipping mask
        path.addClip()
        draw(in: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))

        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()!

        // Restore previous drawing context
        context.restoreGState()
        UIGraphicsEndImageContext()

        return maskedImage
    }
}
