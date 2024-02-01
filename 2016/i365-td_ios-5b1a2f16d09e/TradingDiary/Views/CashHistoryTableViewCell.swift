//
//  CashHistoryTableViewCell.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/5/14.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class CashHistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var inOrOutLabel: UILabel!
    @IBOutlet weak var moneyLabel: UILabel!
    @IBOutlet weak var cashDateLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
