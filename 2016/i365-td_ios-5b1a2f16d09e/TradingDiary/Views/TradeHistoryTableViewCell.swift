//
//  TradeHistoryTableViewCell.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/5/13.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class TradeHistoryTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var buyDateLabel: UILabel!
    @IBOutlet weak var saleDateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
