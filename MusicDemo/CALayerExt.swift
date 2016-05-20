//
//  CALayer.swift
//  MusicDemo
//
//  Created by Tuan Le on 1/29/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import Foundation
import UIKit

class CALayerExt {
    static func pauseLayer(layer: CALayer) {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        layer.speed = 0
        layer.timeOffset = pausedTime
    }
    
    static func resumeLayer(layer: CALayer) {
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0
        layer.beginTime = 0
        let timeSinceTime = layer.convertTime(CACurrentMediaTime(), fromLayer: nil) - pausedTime
        layer.beginTime = timeSinceTime
    }
    
    static func showHint(hint: String!, view: UIView!) {
        let hud = MBProgressHUD(view: view!)
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(true)
        hud.userInteractionEnabled = false
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = hint!
        hud.labelFont = UIFont.systemFontOfSize(15)
        hud.margin = 10
        hud.yOffset = 0
        hud.removeFromSuperViewOnHide = true
        hud.hide(true, afterDelay: 2)
    }
}