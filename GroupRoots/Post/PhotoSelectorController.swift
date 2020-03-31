//
//  PhotoSelectorController.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 7/27/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Photos
import BSImagePicker

class PhotoSelectorController: UICollectionViewController {
    

    override var prefersStatusBarHidden: Bool { return true }
    private var selectedImage : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(handleNext))
        
        collectionView?.backgroundColor = .white
        navigationController?.navigationBar.tintColor = .black
        
        let vc = BSImagePickerViewController()
        let targetSize = CGSize(width: 200, height: 200)
        bs_presentImagePickerController(vc, animated: true,
            select: { (asset: PHAsset) -> Void in
              // User selected an asset.
              // Do something with it, start upload perhaps?
            }, deselect: { (asset: PHAsset) -> Void in
              // User deselected an assets.
              // Do something, cancel upload?
            }, cancel: { (assets: [PHAsset]) -> Void in
                self.dismiss(animated: true, completion: nil)
            }, finish: { (assets: [PHAsset]) -> Void in
                PHImageManager.default().requestImage(for: assets[0], targetSize: targetSize, contentMode: .aspectFit, options: nil) { (image, info) in
                    self.selectedImage = image
                }
              // User finished with these assets
        }, completion: nil)
    }
    
    @objc private func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleNext() {
        let sharePhotoController = SharePhotoController()
        sharePhotoController.selectedImage = self.selectedImage
        navigationController?.pushViewController(sharePhotoController, animated: true)
    }
}
