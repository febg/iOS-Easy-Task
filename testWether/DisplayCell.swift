//
//  DisplayCell.swift
//  
//
//  Created by Felipe Ballesteros on 2017-08-24.
//
//

import UIKit

class DisplayCell: UITableViewCell {

    @IBOutlet weak var wetherDesciptionText: UILabel!
    @IBOutlet weak var descriptionText: UILabel!
    
    @IBOutlet weak var tempText: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
