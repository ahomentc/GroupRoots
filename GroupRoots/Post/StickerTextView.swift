//
//  StickerTextView.swift
//  GroupRoots
//
//  Created by Andrei Homentcovschi on 2/24/21.
//  Copyright © 2021 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit

class StickerTextView: UITextView {

  lazy var placeholderLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor(white: 0.5, alpha: 0.85)
    label.backgroundColor = .clear
    return label
  }()
    

  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }


  override func layoutSubviews() {
    super.layoutSubviews()

//    if text.isEmpty {
//      placeholderLabel.copyProperties(from: self)
//      addSubview(placeholderLabel)
//      bringSubviewToFront(placeholderLabel)
//    } else {
//      placeholderLabel.removeFromSuperview()
//    }
    
  }

//  @objc func textDidChangeHandler(notification: Notification) {
//    setNeedsLayout()
//  }
}

private extension UILabel {
  /// Copies common properties from UITextView. You can add more.
  func copyProperties(from textView: UITextView) {
    frame = textView.bounds.inset(by: textView.textContainerInset)
    lineBreakMode = textView.textContainer.lineBreakMode
    textAlignment = textView.textAlignment
    numberOfLines = textView.textContainer.maximumNumberOfLines
  }
}
