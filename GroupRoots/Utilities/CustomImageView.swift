import UIKit
import SGImageCache

var imageCache = [String: UIImage]()
var colorCache = [String: UIColor]()

class CustomImageView: UIImageView {
    
    private var lastURLUsedToLoadImage: String?
    
//    func loadImage(urlString: String) {
//        lastURLUsedToLoadImage = urlString
//        image = nil
//
//        if let cachedImage = imageCache[urlString] {
//            image = cachedImage
//            return
//        }
//
//        guard let url = URL(string: urlString) else { return }
//        URLSession.shared.dataTask(with: url) { (data, response, err) in
//            if let err = err {
//                print("Failed to fetch post image:", err)
//                return
//            }
//
//            if url.absoluteString != self.lastURLUsedToLoadImage { return }
//
//            guard let imageData = data else { return }
//            let photoImage = UIImage(data: imageData)
//            imageCache[url.absoluteString] = photoImage
//
//            DispatchQueue.main.async {
//                self.image = photoImage
//            }
//        }.resume()
//    }
    
//    func loadImageWithCompletion(urlString: String, completion: @escaping () -> ()) {
//        lastURLUsedToLoadImage = urlString
//        image = nil
//
//        if let cachedImage = imageCache[urlString] {
//            image = cachedImage
//            completion()
//            return
//        }
//
//        guard let url = URL(string: urlString) else { return }
//        URLSession.shared.dataTask(with: url) { (data, response, err) in
//            if let err = err {
//                print("Failed to fetch post image:", err)
//                return
//            }
//
//            if url.absoluteString != self.lastURLUsedToLoadImage { return }
//
//            guard let imageData = data else { return }
//            let photoImage = UIImage(data: imageData)
//            imageCache[url.absoluteString] = photoImage
//
//            DispatchQueue.main.async {
//                self.image = photoImage
//                completion()
//            }
//        }.resume()
//    }
    
    func loadImage(urlString: String) {
        if let image = SGImageCache.image(forURL: urlString) {
            DispatchQueue.main.async {
                self.image = image   // image loaded immediately from cache
            }
        } else {
            SGImageCache.slowGetImage(url: urlString) { [weak self] image in
                DispatchQueue.main.async {
                    self?.image = image   // image loaded immediately from cache
                }
            }
        }
    }
    
    // use this to load images on screen (fast)
    func loadImageWithCompletion(urlString: String, completion: @escaping () -> ()) {
        if let image = SGImageCache.image(forURL: urlString) {
            self.image = image   // image loaded immediately from cache
            completion()
        } else {
            SGImageCache.getImage(url: urlString) { [weak self] image in
                self?.image = image   // image loaded async
                completion()
            }
        }
    }
    
    // use this to load image that are off screen
    func loadImageWithCompletionSlow(urlString: String, completion: @escaping () -> ()) {
        if let image = SGImageCache.image(forURL: urlString) {
            self.image = image   // image loaded immediately from cache
            completion()
        } else {
            SGImageCache.slowGetImage(url: urlString) { [weak self] image in
                self?.image = image   // image loaded async
                completion()
            }
        }
    }
  
// --- could use this somewhere if getting image fails
//    let promise = SGImageCache.getImageForURL(url)
//    promise.swiftThen({object in
//      if let image = object as? UIImage {
//          self.imageView.image = image
//      }
//      return nil
//    })
//    promise.onRetry = {
//      self.showLoadingSpinner()
//    }
//    promise.onFail = { (error: NSError?, wasFatal: Bool) -> () in
//      self.displayError(error)
//    }
}

extension CustomImageView {
    
    func getAvgColor(imageUrl: String, completion: @escaping (UIColor) -> ()) {
        let cacheString = "color_" + imageUrl
        if let cachedColorVal = colorCache[cacheString] {
            completion(cachedColorVal)
            return
        }
        
        let imgColor = self.averageColor
        colorCache[cacheString] = imgColor
        completion(imgColor ?? UIColor.black)
    }
    
    var averageColor: UIColor? {
        
        guard let image = self.image else { return nil }
        guard let inputImage = CIImage(image: image) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
    
    class func imageWithColor(color: UIColor) -> UIImage {
        let rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}
