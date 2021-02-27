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
import LocationPicker
import MapKit

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

class EditTempPhotoController: UIViewController, UIGestureRecognizerDelegate, UITextViewDelegate, ModifyTextViewDelegate, UIColorPickerViewControllerDelegate, UIFontPickerViewControllerDelegate {
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var isTempPost = true

    var backgroundImage: UIImage?
    
    var suggestedLocation: CLLocation?
    
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
    
    let hourglassButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "hourglass_24"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(toggleTempPost), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    let locationButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "location_icon"), for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(pickLocation), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        return button
    }()
    
    private let textEditBackground: UIView = {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 250))
        backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
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
        return button
    }()
    
    let doneTextButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
        button.backgroundColor = .clear
        button.isUserInteractionEnabled = false
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.isHidden = true
        return button
    }()
    
    var textViews = [UITextView]()
    var activeTextView = UITextView()
    
    override func viewWillAppear(_ animated: Bool) {
        self.nextButton.isHidden = false
        self.textButton.isHidden = false
        self.hourglassButton.isHidden = false
        self.closeButton.isHidden = false
        self.upperCoverView.isHidden = false
        self.coverView.isHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureReconizer = UITapGestureRecognizer(target: self, action: #selector(closeTextViewKeyboard))
        tapGestureReconizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureReconizer)
        
        self.view.backgroundColor = UIColor.black
        let backgroundImageView = UIImageView(frame: view.frame)
        backgroundImageView.contentMode = UIView.ContentMode.scaleAspectFit
        backgroundImageView.image = backgroundImage
        view.addSubview(backgroundImageView)
        
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
        
        nextButton.frame = CGRect(x: UIScreen.main.bounds.width-120, y: UIScreen.main.bounds.height - 70, width: 100, height: 50)
        nextButton.layer.cornerRadius = 20
        self.view.insertSubview(nextButton, at: 4)
        
        closeButton.frame = CGRect(x: 10, y: 15, width: 40, height: 40)
        closeButton.layer.zPosition = 20
        self.view.insertSubview(closeButton, at: 12)
        
        hourglassButton.frame = CGRect(x: UIScreen.main.bounds.width - 200, y: UIScreen.main.bounds.height - 75, width: 55, height: 55)
        self.view.insertSubview(hourglassButton, at: 12)
        
        textButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 15, width: 45, height: 45)
        self.view.insertSubview(textButton, at: 12)
        
        doneTextButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: 15, width: 40, height: 40)
        self.view.insertSubview(doneTextButton, at: 12)
        
        locationButton.frame = CGRect(x: UIScreen.main.bounds.width - 65, y: 75, width: 60, height: 60)
        self.view.insertSubview(locationButton, at: 12)
        
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
        
        UITextView.appearance().tintColor = UIColor.white
        
        self.nextButton.addTarget(self, action: #selector(self.nextButtonDown), for: .touchDown)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonDown), for: .touchDragInside)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonUp), for: .touchDragExit)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonUp), for: .touchCancel)
        self.nextButton.addTarget(self, action: #selector(self.nextButtonUp), for: .touchUpInside)
    }
    
    @objc func panHandler(gestureRecognizer: UIPanGestureRecognizer){
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            let translation = gestureRecognizer.translation(in: self.view)
            gestureRecognizer.view!.center = CGPoint(x: gestureRecognizer.view!.center.x + translation.x, y: gestureRecognizer.view!.center.y + translation.y)
            gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
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
    
    @objc private func goToShare() {
        let sharePhotoController = SharePhotoController()
        
        // only modify if there is a textView
        if self.textViews.count > 0 {
            self.nextButton.isHidden = true
            self.textButton.isHidden = true
            self.hourglassButton.isHidden = true
            self.closeButton.isHidden = true
            self.locationButton.isHidden = true
            self.upperCoverView.isHidden = true
            self.coverView.isHidden = true

            let areaSize = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) //Your view size from where you want to make UIImage
            UIGraphicsBeginImageContext(areaSize.size);
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
            })
            
        }

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

        locationPicker.completion = { location in
//            self.locationLabel.text = location?.name
//            if location?.name == nil || location?.name == "" {
//                self.locationLabel.text = location?.address
//            }
//            self.selectedLocation = PostLocation(name: location?.name, longitude: "\(location?.coordinate.longitude ?? 0)", latitude: "\(location?.coordinate.latitude ?? 0)", address: location?.address)
        }
        
        locationPicker.title = "Add Location"

        let navController = UINavigationController(rootViewController: locationPicker)
        navController.modalPresentationStyle = .popover
        present(navController, animated: true, completion: nil)
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
    
    @objc private func toggleTempPost() {
        isTempPost = !isTempPost
        if isTempPost {
            hourglassButton.setImage(#imageLiteral(resourceName: "hourglass_24"), for: .normal)
        }
        else {
            hourglassButton.setImage(#imageLiteral(resourceName: "hourglass_infinity"), for: .normal)
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
        backgroundColor = .clear
        
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
