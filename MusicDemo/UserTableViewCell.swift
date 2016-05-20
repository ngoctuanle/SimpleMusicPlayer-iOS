//
//  UserTableViewCell.swift
//  MusicDemo
//
//  Created by Tuan Le on 2/1/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var duration: UILabel!
    @IBOutlet weak var title_song: UILabel!
    @IBOutlet weak var playback_count: UILabel!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var btnMore: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
