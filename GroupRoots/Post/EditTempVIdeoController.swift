//
//  EditTempVIdeoController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/23/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Player

class EditTempVideoController: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var videoUrl: URL? {
        didSet {
            guard let videoUrl = videoUrl else { return }
            self.setVideoDimensions()
            self.player.url = videoUrl
            self.player.playFromBeginning()
        }
    }

    var player = Player()
    
    let closeButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "arrow_left"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(goToShare), for: .touchUpInside)
        button.layer.zPosition = 4;
        button.backgroundColor = UIColor(white: 1, alpha: 1)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitle("Next", for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        self.view.insertSubview(nextButton, at: 4)
        
        closeButton.frame = CGRect(x: 10, y: 15, width: 40, height: 40)
        self.view.insertSubview(closeButton, at: 12)
        
        self.nextButton.addTarget(self, action: #selector(self.nextButtonDown), for: .touchDown)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonDown), for: .touchDragInside)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonUp), for: .touchDragExit)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonUp), for: .touchCancel)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonUp), for: .touchUpInside)
    }
    
    @objc private func goToShare() {
        guard let videoUrl = videoUrl else { return }
        self.player.pause()
        let sharePhotoController = SharePhotoController()
        sharePhotoController.selectedVideoURL = videoUrl
        sharePhotoController.isTempPost = true
        sharePhotoController.selectedImage = imageFromVideo(url: videoUrl, at: 0)
        navigationController?.pushViewController(sharePhotoController, animated: true)
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

