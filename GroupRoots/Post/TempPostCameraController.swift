//
//  TempPostCameraController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/21/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftyCam
import GradientProgressBar

class TempPostCameraController: SwiftyCamViewController, SwiftyCamViewControllerDelegate {
        
    lazy var captureButton: UIImageView = {
        let button = UIImageView()
        button.image = #imageLiteral(resourceName: "camera_capture")
        button.isUserInteractionEnabled = true
        return button
    }()
    
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "cancel_shadow"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    let gradientProgressView: GradientProgressBar = {
        let progress = GradientProgressBar()
        progress.isHidden = true
//        progress.gradientColors = [UIColor(red: 0/255, green: 191/255, blue: 124/255, alpha: 1), UIColor(red: 0/255, green: 120/255, blue: 78/255, alpha: 1), UIColor(red: 0/255, green: 92/255, blue: 68/255, alpha: 1)]
        progress.gradientColors = [UIColor(red: 0/255, green: 191/255, blue: 124/255, alpha: 1), UIColor(red: 53/255, green: 186/255, blue: 219/255, alpha: 1)]
        progress.backgroundColor = .clear
        return progress
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraDelegate = self
        
        configureNavBar()
        
        captureButton.frame = CGRect(x: UIScreen.main.bounds.width/2-50, y: UIScreen.main.bounds.height-150, width: 100, height: 100)
        self.view.insertSubview(captureButton, at: 12)
        
        // photo
        captureButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
        
        // video
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPressGestureRecognizer.minimumPressDuration = 0.4
        captureButton.addGestureRecognizer(longPressGestureRecognizer)
        
        gradientProgressView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 10)
        self.view.insertSubview(gradientProgressView, at: 12)
        
        closeButton.frame = CGRect(x: 15, y: 15, width: 40, height: 40)
        self.view.insertSubview(closeButton, at: 12)
        
        self.maximumVideoDuration = 59
        self.swipeToZoomInverted = true
    }
    
    func configureNavBar() {
        self.navigationController?.navigationBar.height(CGFloat(0))
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = .clear
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var captureButtonDown = false
    
    @objc private func close() {
        self.dismiss(animated: true, completion: {})
    }
    
    @objc private func tap(tapGestureRecognizer: UITapGestureRecognizer) {
        cameraTapAnimation()
        takePhoto()
    }
    
    @objc private func longPress (longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == .began {
            startVideoRecording()
            startCameraVideoAnim()
            self.captureButtonDown = true
            self.gradientProgressView.progress = 0.0
            self.gradientProgressView.isHidden = false
            self.gradientProgressView.animationDuration = 1
            self.gradientProgressView.setProgress(0.0, animated: true)
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
                self.gradientProgressView.animationDuration = 59
                self.gradientProgressView.setProgress(1.0, animated: true)
            })
        }
        if longPressGestureRecognizer.state == .ended {
            stopVideoRecording()
            endCameraVideoAnim()
            self.gradientProgressView.isHidden = true
        }
    }
    
    func cameraTapAnimation() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
            self.captureButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: nil)
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseOut], animations: {
                self.captureButton.transform = CGAffineTransform.identity
            }, completion: nil)
        })
    }
    
    var videoTimer: Timer?
    
    func startCameraVideoAnim() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
            self.captureButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: nil)
        
        videoTimer = Timer.scheduledTimer(withTimeInterval: 59, repeats: false, block: { timer in
            self.gradientProgressView.isHidden = true
            self.endCameraVideoAnim()
        })
    }
    
    func endCameraVideoAnim() {
        if captureButtonDown {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseOut], animations: {
                self.captureButton.transform = CGAffineTransform.identity
            }, completion: nil)
            captureButtonDown = false
            if videoTimer != nil {
                videoTimer?.invalidate()
            }
        }
        
    }
    
    func swiftyCamSessionDidStartRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did start running")
//        captureButton.buttonEnabled = true
    }
    
    func swiftyCamSessionDidStopRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did stop running")
//        captureButton.buttonEnabled = false
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        // take you to filters page or page where you can add text to image
        let photoViewController = EditTempPhotoController()
        photoViewController.backgroundImage = photo
        navigationController?.pushViewController(photoViewController, animated: false)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        // take you to filters page
        let editTempVideoController = EditTempVideoController()
        editTempVideoController.videoUrl = url
        navigationController?.pushViewController(editTempVideoController, animated: false)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
//        captureButton.growButton()
//        hideButtons()
        print("started recording video")
    }

    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
//        captureButton.shrinkButton()
//        showButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        print("Did focus at point: \(point)")
//        focusAnimationAt(point)
    }
    
    func swiftyCamDidFailToConfigure(_ swiftyCam: SwiftyCamViewController) {
        let message = NSLocalizedString("Unable to capture media", comment: "Something went wrong during capture session")
        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
