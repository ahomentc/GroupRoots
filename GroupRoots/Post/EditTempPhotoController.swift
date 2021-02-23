//
//  EditTempPhotoController.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/22/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit

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

class EditTempPhotoController: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    var backgroundImage: UIImage?
    
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
        self.view.backgroundColor = UIColor.gray
        let backgroundImageView = UIImageView(frame: view.frame)
        backgroundImageView.contentMode = UIView.ContentMode.scaleAspectFit
//        backgroundImageView.image = backgroundImage!.addFilter(filter: .Mono).rotate(radians: .pi/2)
        backgroundImageView.image = backgroundImage
        view.addSubview(backgroundImageView)
        
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
        let sharePhotoController = SharePhotoController()
        sharePhotoController.selectedImage = self.backgroundImage
        sharePhotoController.isTempPost = true
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
