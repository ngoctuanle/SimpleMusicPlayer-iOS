//
//  SearchResultTableViewCell.swift
//  MusicDemo
//
//  Created by Tuan Le on 3/20/16.
//  Copyright © 2016 Tuan Le. All rights reserved.
//

import UIKit

class SearchResultTableViewCell: UITableViewCell {

    @IBOutlet weak var art_work: UIImageView!
    @IBOutlet weak var songTitle: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
