//
//  TrackDetailTableViewCell.swift
//  MusicDemo
//
//  Created by Tuan Le on 1/21/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import UIKit

class TrackDetailTableViewCell: UITableViewCell {
    @IBOutlet var img: UIImageView!
    @IBOutlet var username: UILabel!
    @IBOutlet var duration: UILabel!
    @IBOutlet var title_song: UILabel!
    @IBOutlet var playback: UILabel!
    @IBOutlet var btnMor: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
