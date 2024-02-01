//
//  PortfolioTableViewCell.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/5/13.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class PortfolioTableViewCell: UITableViewCell {

    @IBOutlet weak var portfolioNameLabel: UILabel!
    @IBOutlet weak var portfolioCreatedDateLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
