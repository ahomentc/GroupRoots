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
