//
//  UIView.swift
//  MusicDemo
//
//  Created by Tuan Le on 1/15/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import UIKit

extension UIView {
    class func loadNib<T: UIView>(viewType: T.Type) -> T {
        let className = String.className(viewType)
        return NSBundle(forClass: viewType).loadNibNamed(className, owner: nil, options: nil).first as! T
    }
    
    class func loadNib() -> Self {
        return loadNib(self)
    }
    
    func startTransitionAnimation() {
        let transition:CATransition = CATransition()
        transition.duration = 1
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionFade
        self.layer.addAnimation(transition, forKey: nil)
    }
}
