//
//  DiaryTableViewCell.swift
//  TradingDiary
//
//  Created by Dawei Ma on 16/5/13.
//  Copyright © 2016年 i365.tech. All rights reserved.
//

import UIKit

class DiaryTableViewCell: UITableViewCell {

    @IBOutlet weak var positionRatioLabel: UILabel!
    @IBOutlet weak var positionCodeLabel: UILabel!
    @IBOutlet weak var positionProfitOrLessRatioLabel: UILabel!
    @IBOutlet weak var positionNameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
