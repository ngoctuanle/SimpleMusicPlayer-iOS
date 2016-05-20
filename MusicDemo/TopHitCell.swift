//
//  TopHitCell.swift
//  MusicDemo
//
//  Created by Tuan Le on 2/2/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import UIKit

class TopHitCell: UITableViewCell {
    @IBOutlet weak var label: CBAutoScrollLabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        label.textColor = UIColor.whiteColor()
        label.labelSpacing = 30
        label.pauseInterval = 2.0
        label.font = UIFont.systemFontOfSize(17)
        label.scrollSpeed = 30
        label.textAlignment = NSTextAlignment.Center
        label.fadeLength = 15
        label.scrollDirection = .Left
        label.observeApplicationNotifications()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
